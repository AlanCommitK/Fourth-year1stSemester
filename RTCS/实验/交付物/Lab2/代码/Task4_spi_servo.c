/*==============================================================================
 * Lab 2 - Task 4        SPI reads the potentiometer, PWM drives a servo
 *
 * Everything about the SPI side is identical to Task 3 - same wiring, same
 * chip-select pin, same fix to the Arduino sketch, same four-transfer read.
 * Only the timer numbers change, and they change a lot, because a servo is not
 * an LED: it does not care about the duty cycle, it measures the WIDTH of the
 * pulse.
 *
 * ┌──────────────────────────────────────────────────────────────────────────┐
 * │ 1. WHAT A HOBBY SERVO ACTUALLY LISTENS TO                                │
 * └──────────────────────────────────────────────────────────────────────────┘
 *   A standard RC servo expects a pulse repeated every 20 ms, i.e. at 50 Hz,
 *   and reads the commanded angle from how long that pulse stays high:
 *
 *        1.0 ms  ->  one end of the travel
 *        1.5 ms  ->  the middle
 *        2.0 ms  ->  the other end
 *
 *   The frame rate itself carries no information; only the width does. That is
 *   why the duty cycle here is always between 5 % and 10 % and never sweeps the
 *   whole range as it did in Task 3.
 *
 *   The 10 Hz configuration used in section 3 of the handout is unusable for
 *   this: its counter ticks once per millisecond, so the entire 1 ms to 2 ms
 *   command range would be two counter steps wide, and its frame would be
 *   100 ms instead of 20 ms. New numbers are needed, and deriving them is what
 *   the task means by "show the calculations".
 *
 * ┌──────────────────────────────────────────────────────────────────────────┐
 * │ 2. THE CALCULATIONS                                                      │
 * └──────────────────────────────────────────────────────────────────────────┘
 *   Start from the resolution we want rather than from the period: one count
 *   per microsecond makes every number below readable directly in microseconds.
 *
 *       counter clock = 1 MHz  =>  PSC + 1 = f_TIM4 / 1 MHz
 *                                     ( = 8 on an 8 MHz project, 64 on a 64 MHz one )
 *
 *   Then choose the frame:
 *
 *       20 ms at 1 us per tick  =>  ARR + 1 = 20 000  =>  ARR = 19 999
 *       check: 1 MHz / 20 000 = 50.00 Hz exactly, whatever the system clock is
 *       both factors are below 65 536, so both registers fit in 16 bits
 *
 *   The compare register is now simply the pulse width in microseconds:
 *
 *       CCR1 = 1000  ->  1.000 ms
 *       CCR1 = 1500  ->  1.500 ms
 *       CCR1 = 2000  ->  2.000 ms
 *
 *   and the potentiometer maps onto it linearly:
 *
 *       CCR1 = 1000 + adc * 1000 / 1023          adc = 0 .. 1023
 *
 *   which is 1000 at one end, 1500 near the middle and 2000 at the other.
 *   The corresponding angle, for a 180-degree servo, is adc * 180 / 1023.
 *
 * ┌──────────────────────────────────────────────────────────────────────────┐
 * │ 3. WIRING - THE SPI PART IS EXACTLY AS IN TASK 3                         │
 * └──────────────────────────────────────────────────────────────────────────┘
 *   signal | Nucleo header (STM32 pin) |    | Nano Every
 *   -------+---------------------------+----+-----------
 *   SCK    | D13  (PA5)                | -> | D13
 *   MOSI   | D11  (PA7)                | -> | D11        (handout says D12: wrong)
 *   MISO   | D12  (PA6)                | <- | D12        (handout says D11: wrong)
 *   CS     | D9   (PC7)                | -> | D8         (handout says D10: wrong)
 *   GND    | any GND                   | -- | GND
 *   1 kohm in series on MISO: PA6 is an ADC pin and is not 5 V tolerant.
 *   Potentiometer: outer legs to Nano 5V and GND, wiper to Nano A1.
 *
 *   Servo, three wires:
 *     signal (usually orange or white) -> Nucleo D10 = PB6 = TIM4_CH1
 *     +5 V   (usually red)             -> see the warning below
 *     GND    (usually brown or black)  -> common ground with the Nucleo
 *
 *   POWER. A small servo draws a few hundred milliamps while moving and can
 *   pull over an ampere if it is held against a stop. The 5 V pin of the
 *   Nucleo comes from the ST-LINK USB supply and shares its budget with the
 *   board itself, so feeding a servo from it can brown out the MCU and reset
 *   it in the middle of the demonstration. Use a separate 5 V source (a USB
 *   power bank with a broken-out cable, or a bench supply) and TIE ITS GROUND
 *   TO THE NUCLEO GROUND - without the common ground the pulse has no
 *   reference and the servo will twitch or ignore it.
 *
 *   The signal line is driven at 3.3 V. Almost every hobby servo accepts that
 *   as a logic high while running on 5 V. If yours does not respond at all,
 *   that is the first thing to suspect.
 *
 * ┌──────────────────────────────────────────────────────────────────────────┐
 * │ 4. CUBEMX SETUP (project "Lab2_Task4")                                   │
 * └──────────────────────────────────────────────────────────────────────────┘
 *   Same as Task 3 except for the two timer numbers:
 *   1. USART2: Asynchronous, 9600 8N1, global interrupt enabled
 *   2. SPI1: Full-Duplex Master, 8 bits, MSB first, prescaler 128,
 *      CPOL Low, CPHA 1 Edge, hardware NSS disabled
 *   3. PC7 -> GPIO_Output, label SPI_CS, initial level HIGH
 *   4. TIM4: Internal Clock, Channel1 = PWM Generation CH1
 *   5. TIM4 Parameter Settings:  Prescaler = f_TIM4 / 1 MHz - 1  (7 for an
 *      8 MHz project, 63 for a 64 MHz one),  Counter Period = 19999,
 *      Counter Mode = Up, PWM mode 1, Pulse = 1500, CH Polarity = High
 *      (Pulse 1500 means the servo sits in the middle at power-up.)
 *      The code re-asserts both values, so what really matters is TIMCLK_HZ.
 *   5b. Check PA5: if CubeMX assigned it to the on-board LED LD2 at project
 *      creation, change it to SPI1_SCK.
 *   6. Ctrl+S.
 *
 * ┌──────────────────────────────────────────────────────────────────────────┐
 * │ 5. THE SAME FIX TO THE ARDUINO SKETCH IS STILL REQUIRED                  │
 * └──────────────────────────────────────────────────────────────────────────┘
 *       SPI0.CTRLA = (SPI0.CTRLA | SPI_ENABLE_bm)
 *                    & ~(SPI_MASTER_bm | SPI_DORD_bm);
 *   replacing line 17, whose AND of three different single-bit masks evaluates
 *   to zero and leaves the peripheral disabled. See Task 3 for the reasoning.
 *
 * This file is a set of snippets, not a compilable translation unit.
 *============================================================================*/


/* USER CODE BEGIN Includes */
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
/* USER CODE END Includes */


/* USER CODE BEGIN PD */
#define CS_PORT        GPIOC
#define CS_PIN         GPIO_PIN_7          /* PC7 = Arduino header D9        */

#define SPI_TIMEOUT    100U
#define CMD_LOW_BYTE   0x00U
#define CMD_HIGH_BYTE  0x01U
#define CMD_DUMMY      0x00U

/* ---- the live blank: read "APB1 timer clocks (MHz)" in CubeMX ------------- */
/* A project created WITHOUT the board defaults sits on the internal 8 MHz
 * oscillator. With the 64 MHz PLL setup, write 64000000UL here instead.
 * Everything below is derived from this one number.                          */
#define TIMCLK_HZ      8000000UL
#define TICK_HZ        1000000UL           /* 1 us per counter tick          */
#define TIM_PSC        ((TIMCLK_HZ / TICK_HZ) - 1UL)   /* 7 at 8 MHz, 63 at 64 */
#define SERVO_FRAME_US 20000UL             /* 20 ms frame = 50 Hz            */
#define TIM_ARR        (SERVO_FRAME_US - 1UL)          /* 19999              */

#define ADC_MAX        1023U               /* 10-bit ADC, largest value      */
#define SERVO_MIN_US   1000U               /* one end of the travel          */
#define SERVO_MAX_US   2000U               /* the other end                  */
#define SERVO_SPAN_US  (SERVO_MAX_US - SERVO_MIN_US)
/* USER CODE END PD */


/* USER CODE BEGIN PV */
static char out[96];
/* USER CODE END PV */


/* USER CODE BEGIN 0 */

static void uart_print(const char *s)
{
    HAL_UART_Transmit(&huart2, (uint8_t *)s, (uint16_t)strlen(s), HAL_MAX_DELAY);
}

/* The AVR interrupt needs a few microseconds to load its answer. A short busy
 * wait is used rather than HAL_Delay(1), which would idle for one to two
 * milliseconds and widen the window in which the slave's loop() can refresh
 * the value between the two halves of one reading.                          */
static void slave_settle(void)
{
    for (volatile uint32_t i = 0U; i < 300U; i++) { __NOP(); }
}

static uint8_t spi_swap(uint8_t tx)
{
    uint8_t rx = 0U;
    if (HAL_SPI_TransmitReceive(&hspi1, &tx, &rx, 1U, SPI_TIMEOUT) != HAL_OK)
    {
        uart_print("  SPI transfer failed (timeout).\r\n");
    }
    return rx;
}

/* Identical to Task 3: the slave answers one transfer late, so each byte of
 * the reading costs one command exchange plus one dummy exchange.           */
static uint16_t nano_read_analog(void)
{
    uint8_t lo, hi;

    HAL_GPIO_WritePin(CS_PORT, CS_PIN, GPIO_PIN_RESET);

    (void)spi_swap(CMD_LOW_BYTE);
    slave_settle();
    lo = spi_swap(CMD_DUMMY);

    (void)spi_swap(CMD_HIGH_BYTE);
    slave_settle();
    hi = spi_swap(CMD_DUMMY);

    HAL_GPIO_WritePin(CS_PORT, CS_PIN, GPIO_PIN_SET);

    uint16_t v = ((uint16_t)hi << 8) | lo;
    return (v > ADC_MAX) ? ADC_MAX : v;
}

/* USER CODE END 0 */


/* USER CODE BEGIN 2 */

    uart_print("\r\n=== UESTC 4014 RTCSA - Lab 2 Task 4 ===\r\n"
               "SPI reads the potentiometer, the servo on PB6 follows it.\r\n"
               "Frame 50 Hz, pulse 1.000 to 2.000 ms, 1 us per counter tick.\r\n");

    HAL_GPIO_WritePin(CS_PORT, CS_PIN, GPIO_PIN_SET);

    /* Re-assert the timing in software. PSC is buffered (the shadow-register
     * behaviour met in Lab 1), so force an update event to load it.        */
    __HAL_TIM_SET_PRESCALER(&htim4, TIM_PSC);
    __HAL_TIM_SET_AUTORELOAD(&htim4, TIM_ARR);
    htim4.Instance->EGR = TIM_EGR_UG;
    __HAL_TIM_CLEAR_FLAG(&htim4, TIM_FLAG_UPDATE);

    __HAL_TIM_SET_COMPARE(&htim4, TIM_CHANNEL_1, 1500U);   /* start centred */
    HAL_TIM_PWM_Start(&htim4, TIM_CHANNEL_1);
    HAL_Delay(500U);                                       /* let it get there */

/* USER CODE END 2 */


/* USER CODE BEGIN 3 */

    {
        uint16_t adc = nano_read_analog();

        /* Pulse width in microseconds; with a 1 MHz counter the compare
         * register IS the width in microseconds, so no further scaling.
         * The product reaches 1 023 000, hence the 32-bit intermediate.   */
        uint16_t pulse_us = (uint16_t)(SERVO_MIN_US
                          + ((uint32_t)adc * SERVO_SPAN_US) / ADC_MAX);

        __HAL_TIM_SET_COMPARE(&htim4, TIM_CHANNEL_1, pulse_us);

        uint16_t angle = (uint16_t)(((uint32_t)adc * 180U) / ADC_MAX);

        sprintf(out, "A1 = %4u / 1023  ->  pulse = %u.%03u ms  (~%3u deg)\r\n",
                (unsigned)adc,
                (unsigned)(pulse_us / 1000U), (unsigned)(pulse_us % 1000U),
                (unsigned)angle);
        uart_print(out);

        HAL_Delay(100U);     /* 10 updates per second: smooth, not twitchy */
    }

/* USER CODE END 3 */


/*==============================================================================
 * WHAT TO OBSERVE
 *   Turning the potentiometer sweeps the servo horn from one end of its travel
 *   to the other, and the console prints the pulse width that produced it.
 *   Holding the knob still holds the horn still - the servo keeps position
 *   because the pulse keeps arriving every 20 ms.
 *
 * IF THE SERVO BUZZES BUT DOES NOT MOVE, OR MOVES AND RESETS THE BOARD
 *   Power. It is drawing more than the Nucleo's 5 V rail can give. Move it to
 *   its own supply and keep the grounds joined.
 *
 * IF THE SERVO ONLY USES PART OF ITS TRAVEL
 *   1.0 to 2.0 ms is the classic specification, but many servos accept a wider
 *   range, often 0.5 to 2.5 ms, and some reach their mechanical stop before
 *   2.0 ms. Widen or narrow the range by editing two numbers only:
 *       #define SERVO_MIN_US   500
 *       #define SERVO_MAX_US   2500
 *   Everything else follows from them. Note in the report which values the
 *   servo actually needed.
 *
 * IF NOTHING MOVES AT ALL
 *   Check the SPI side first with Task 3, where an LED shows immediately
 *   whether the analog value is arriving. Only once that works is it worth
 *   debugging the servo.
 *
 * DO NOT TOGGLE THE CHIP SELECT PER BYTE
 *   The megaAVR-0 data sheet says the client-mode SPI state machine is reset
 *   when SS is driven high, and data in flight is lost. This slave's protocol
 *   depends on the byte loaded by one interrupt surviving until the next
 *   transfer, so SS has to stay low across all four.
 *============================================================================*/
