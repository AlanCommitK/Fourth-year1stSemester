/*==============================================================================
 * Lab 2 - Task 2        I2C master + UART console
 *
 * Two user inputs typed on the serial terminal:
 *   (1) how fast the Arduino's on-board LED blinks,
 *   (2) which data the Arduino should send back.
 * The reply is printed on the same terminal.
 *
 * Boards : NUCLEO-F103RB (I2C master) + Arduino Nano running i2c_arduino.ino
 *          (this task works on a classic Nano as well as on a Nano Every).
 *
 * WIRING  -- FOLLOW THIS, NOT FIGURE 9 OF THE HANDOUT
 *   Nucleo SCL pin (PB8)  ->  Nano A5
 *   Nucleo SDA pin (PB9)  ->  Nano A4      <-- Figure 9 draws this to A6, which
 *                                              is an analog-only pin with no I2C
 *   Nucleo GND            ->  Nano GND     <-- a common ground is mandatory
 *   Nucleo 5V             ->  Nano VIN     (or power the Nano from its own USB)
 *   Potentiometer: outer legs to Nano 5V and GND, wiper to Nano A1
 *
 *   I2C is open-drain and needs pull-ups. Wire.begin() switches on the AVR's
 *   internal ones (~20-50 kohm), which usually carries a short cable. If the
 *   link is unreliable, add 4.7 kohm from SDA and from SCL to +5 V. PB8 and PB9
 *   are 5 V tolerant, so that is safe.
 *
 * CUBEMX SETUP (project "Lab2_Task2")
 *   1. USART2 exactly as in Task 1 (Asynchronous, 9600 8N1, global interrupt on)
 *   2. Connectivity > I2C1 > Mode = I2C
 *   3. I2C1 > Parameter Settings : Standard Mode, Clock Speed 100000 Hz,
 *      7-bit addressing                                   (handout Figure 10)
 *   4. In the pinout view CubeMX first puts I2C1 on PB6/PB7. Click PB8 and
 *      choose I2C1_SCL, then PB9 and choose I2C1_SDA; CubeMX then enables the
 *      I2C1 remap for you. Check that PB6/PB7 have gone back to being free.
 *   5. Ctrl+S.
 *
 * ADDRESSING
 *   The sketch calls Wire.begin(0x55), i.e. the 7-bit address is 0x55. The HAL
 *   wants that address already shifted into bits [7:1], with bit 0 left for the
 *   read/write flag which the HAL fills in itself:  0x55 << 1 = 0xAA.
 *
 * COMMAND SET  -- taken from i2c_arduino.ino, NOT from Table 1 of the handout,
 * which contradicts both the sketch and Figure 11a:
 *   0x80  time = 0    -> no delay at all; the LED is toggled as fast as loop()
 *                        runs, so it looks dim rather than "permanently on"
 *   0x81  time = 250  -> 250 ms on, 250 ms off  (500 ms period)
 *   0x82  time = 500  -> 1 s period
 *   0x83  time = 1000 -> 2 s period
 *   0x00  the next read returns 2 bytes: low byte then high byte of A1
 *   0x01  the next read returns 4 bytes: the characters "RTCA"
 *
 * This file is a set of snippets, not a compilable translation unit.
 *============================================================================*/


/* USER CODE BEGIN Includes */
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
/* USER CODE END Includes */


/* USER CODE BEGIN PD */
#define NANO_ADDR_7BIT   0x55U
#define NANO_ADDR        (NANO_ADDR_7BIT << 1)      /* 0xAA, what HAL wants  */

#define CMD_BLINK_0      0x80U      /* no delay      */
#define CMD_BLINK_250    0x81U      /* 500 ms period */
#define CMD_BLINK_500    0x82U      /* 1 s period    */
#define CMD_BLINK_1000   0x83U      /* 2 s period    */
#define REG_ANALOG       0x00U      /* 2 bytes back  */
#define REG_STRING       0x01U      /* 4 bytes back  */

#define I2C_TIMEOUT      100U       /* ms */
#define LINE_MAX         16U
#define OUT_MAX          96U
/* USER CODE END PD */


/* USER CODE BEGIN PV */
static volatile uint8_t rx_byte;
static volatile char    line[LINE_MAX];
static volatile uint8_t line_len   = 0U;
static volatile bool    line_ready = false;

static char    out[OUT_MAX];
static uint8_t rx_i2c[4];
/* USER CODE END PV */


/* USER CODE BEGIN 0 */

static void uart_print(const char *s)
{
    HAL_UART_Transmit(&huart2, (uint8_t *)s, (uint16_t)strlen(s), HAL_MAX_DELAY);
}

/* One byte to the Arduino. Returns true if it was acknowledged. */
static bool nano_write(uint8_t cmd)
{
    return HAL_I2C_Master_Transmit(&hi2c1, NANO_ADDR, &cmd, 1U,
                                   I2C_TIMEOUT) == HAL_OK;
}

/* n bytes back from the Arduino. */
static bool nano_read(uint8_t *buf, uint16_t n)
{
    return HAL_I2C_Master_Receive(&hi2c1, NANO_ADDR, buf, n,
                                  I2C_TIMEOUT) == HAL_OK;
}

static void print_menu(void)
{
    uart_print("\r\nInput 1 - LED blink rate:\r\n"
               "   1 = no delay (looks dim)   2 = 500 ms   3 = 1 s   4 = 2 s\r\n"
               "Input 2 - data to read back:\r\n"
               "   0 = analog value of A1 (2 bytes)   1 = the 4-byte message\r\n"
               "\r\nBlink rate (1-4) : ");
}

/* USER CODE END 0 */


/* USER CODE BEGIN 2 */

    uart_print("\r\n=== UESTC 4014 RTCSA - Lab 2 Task 2 ===\r\n");
    print_menu();
    HAL_UART_Receive_IT(&huart2, (uint8_t *)&rx_byte, 1U);

/* USER CODE END 2 */


/* USER CODE BEGIN 3 */

    static uint8_t  step       = 0U;    /* 0 = blink rate, 1 = data choice   */
    static uint8_t  blink_cmd  = CMD_BLINK_250;

    if (line_ready)
    {
        sprintf(out, "%s\r\n", (const char *)line);
        uart_print(out);

        if (step == 0U)                       /* ---- input 1: blink rate --- */
        {
            switch (line[0])
            {
                case '1': blink_cmd = CMD_BLINK_0;    break;
                case '2': blink_cmd = CMD_BLINK_250;  break;
                case '3': blink_cmd = CMD_BLINK_500;  break;
                case '4': blink_cmd = CMD_BLINK_1000; break;
                default:  blink_cmd = 0U;             break;
            }

            if (blink_cmd == 0U || line[1] != '\0')
            {
                uart_print("  type 1, 2, 3 or 4 : ");
            }
            else if (!nano_write(blink_cmd))
            {
                uart_print("  no ACK from the Arduino - check SDA/SCL/GND.\r\n"
                           "Blink rate (1-4) : ");
            }
            else
            {
                sprintf(out, "  sent 0x%02X to the Arduino.\r\n"
                             "Data to read (0 or 1) : ", (unsigned)blink_cmd);
                uart_print(out);
                step = 1U;
            }
        }
        else                                  /* ---- input 2: which data --- */
        {
            if (line[0] == '0' && line[1] == '\0')
            {
                /* Select register 0, then read the two bytes it produces.   */
                if (nano_write(REG_ANALOG) && nano_read(rx_i2c, 2U))
                {
                    /* The sketch sends the low byte first, then the high
                     * byte, so they have to be put back together in that
                     * order. The ADC of the Arduino is 10 bits, 0 to 1023. */
                    uint16_t adc = (uint16_t)rx_i2c[0]
                                 | ((uint16_t)rx_i2c[1] << 8);
                    uint32_t mv  = (uint32_t)adc * 5000U / 1023U;

                    sprintf(out, "  raw bytes : 0x%02X 0x%02X\r\n"
                                 "  analog A1 : %u / 1023  =  %lu.%03lu V\r\n",
                            (unsigned)rx_i2c[0], (unsigned)rx_i2c[1],
                            (unsigned)adc,
                            (unsigned long)(mv / 1000U),
                            (unsigned long)(mv % 1000U));
                    uart_print(out);
                }
                else
                {
                    uart_print("  read failed.\r\n");
                }
                print_menu();
                step = 0U;
            }
            else if (line[0] == '1' && line[1] == '\0')
            {
                if (nano_write(REG_STRING) && nano_read(rx_i2c, 4U))
                {
                    sprintf(out, "  raw bytes : 0x%02X 0x%02X 0x%02X 0x%02X\r\n"
                                 "  as text   : %c%c%c%c\r\n",
                            (unsigned)rx_i2c[0], (unsigned)rx_i2c[1],
                            (unsigned)rx_i2c[2], (unsigned)rx_i2c[3],
                            rx_i2c[0], rx_i2c[1], rx_i2c[2], rx_i2c[3]);
                    uart_print(out);
                }
                else
                {
                    uart_print("  read failed.\r\n");
                }
                print_menu();
                step = 0U;
            }
            else
            {
                uart_print("  type 0 or 1 : ");
            }
        }

        line_len   = 0U;
        line_ready = false;
    }

/* USER CODE END 3 */


/* USER CODE BEGIN 4 */

/* Identical to Task 1 - one character per interrupt, line assembled here. */
void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart)
{
    if (huart->Instance != USART2)
    {
        return;
    }

    char c = (char)rx_byte;

    if (!line_ready)
    {
        if (c == '\r' || c == '\n')
        {
            if (line_len > 0U)
            {
                line[line_len] = '\0';
                line_ready = true;
            }
        }
        else if (c == '\b' || c == 0x7F)
        {
            if (line_len > 0U) { line_len--; }
        }
        else if (line_len < (LINE_MAX - 1U))
        {
            line[line_len++] = c;
        }
    }

    HAL_UART_Receive_IT(huart, (uint8_t *)&rx_byte, 1U);
}

/* USER CODE END 4 */


/*==============================================================================
 * THE TWO SCREENSHOTS THE TASK ASKS FOR
 *
 *   (a) command 0x00 - the 2-byte analog value:
 *         Blink rate (1-4) : 3
 *           sent 0x82 to the Arduino.
 *         Data to read (0 or 1) : 0
 *           raw bytes : 0x2F 0x02
 *           analog A1 : 559 / 1023  =  2.732 V
 *       Turn the potentiometer between two screenshots to show the value moving.
 *
 *   (b) command 0x01 - the 4-byte message:
 *         Data to read (0 or 1) : 1
 *           raw bytes : 0x52 0x54 0x43 0x41
 *           as text   : RTCA
 *
 *   Note that 0x52 0x54 0x43 0x41 is "RTCA" in ASCII. The handout never says
 *   what those four bytes are; the sketch gives them away: Wire.write("RTCA").
 *
 * KNOWN ROUGH EDGES OF THE SUPPLIED SKETCH  (report them, do not hide them)
 *   - Line 20 of i2c_arduino.ino calls Serial.println(RxByte) inside the I2C
 *     receive handler. Printing from inside an interrupt takes milliseconds and
 *     can disturb the bus. If the link is flaky, comment that line out first.
 *   - loop() blocks in delay(time), so lower_val / upper_val are only refreshed
 *     once per blink period. At setting 4 (2 s period) the analog reading can
 *     therefore be up to two seconds old. Choose a fast blink rate while
 *     demonstrating that the potentiometer works.
 *
 * IF EVERY TRANSFER RETURNS "no ACK"
 *   - SDA and SCL swapped, or SDA wired to A6 instead of A4 (Figure 9 is wrong);
 *   - no common ground between the two boards;
 *   - the address: HAL needs 0x55 << 1 = 0xAA, not 0x55;
 *   - the sketch not actually uploaded to the Nano.
 *============================================================================*/
