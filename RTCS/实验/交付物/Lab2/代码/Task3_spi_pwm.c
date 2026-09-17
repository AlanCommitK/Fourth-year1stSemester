/*==============================================================================
 * Lab 2 - Task 3        SPI master reads the potentiometer, PWM follows it
 *
 * Boards : NUCLEO-F103RB (SPI master) + Arduino Nano EVERY running
 *          SPI_ArduinoNanoEvery_Slave.ino.
 *          A classic Nano will NOT do: that sketch writes SPI0.CTRLA and
 *          uses ISR(SPI0_INT_vect), which only exist on the ATmega4809.
 *
 * ┌──────────────────────────────────────────────────────────────────────────┐
 * │ 1. WIRING  -- THE HANDOUT'S TABLE IS WRONG IN THREE PLACES               │
 * └──────────────────────────────────────────────────────────────────────────┘
 *   signal | Nucleo header (STM32 pin) |    | Nano Every | handout says
 *   -------+---------------------------+----+------------+-----------------
 *   SCK    | D13  (PA5)                | -> | D13        | D13   correct
 *   MOSI   | D11  (PA7)                | -> | D11        | D12   WRONG
 *   MISO   | D12  (PA6)                | <- | D12        | D11   WRONG
 *   CS     | D9   (PC7)   see note 2   | -> | D8         | D10   WRONG
 *   GND    | any GND                   | -- | GND        | missing entirely
 *
 *   MOSI and MISO are NOT crossed over. Unlike a UART, where TX meets RX, SPI
 *   names its wires by function: the master's "master out" wire is the same
 *   wire as the slave's "master out". Wiring them crossed as the handout says
 *   connects two driving outputs face to face.
 *
 *   CS goes to D8 because on the Nano Every the SPI peripheral is routed to
 *   PORTE (PORTMUX_SPI0_ALT2_gc), where the hardware slave-select pin is PE3 =
 *   D8. Arduino's own pins_arduino.h for this board says PIN_SPI_SS = 8. The
 *   sketch leaves hardware SS enabled (it clears SPI_SSD_bm), so D8 is the pin
 *   that actually selects the slave; D10 is not connected to SPI at all.
 *
 *   Also needed:
 *     potentiometer : outer legs to Nano 5V and GND, wiper to Nano A1
 *     Arduino LED   : Nano D2 -> 330 ohm -> LED -> GND    (the sketch blinks it)
 *     Nucleo LED    : Nucleo D10 (PB6) -> 330 ohm -> LED -> GND
 *                     this is the PWM output whose brightness we are changing
 *
 *   NOTE ON 5 V: PA5, PA6 and PA7 of the STM32F103 are ADC inputs and are NOT
 *   5 V tolerant (datasheet DS5319 Table 5 marks the tolerant pins "FT"; these
 *   are not). MISO is the only wire that the 5 V Arduino drives INTO the
 *   Nucleo, so put a 1 kohm resistor in series with it. If you would rather do
 *   it properly, use a divider: Nano D12 -> 10 kohm -> PA6, and 20 kohm from
 *   PA6 to GND, which turns 5 V into 3.3 V.
 *
 * ┌──────────────────────────────────────────────────────────────────────────┐
 * │ 2. WHY CS IS ON PC7 AND NOT ON PB6                                       │
 * └──────────────────────────────────────────────────────────────────────────┘
 *   The handout uses PB6 for the chip select (section 2.3.1) and PB6 for the
 *   PWM output (section 3.2: "the IO pin for channel 1 of timer 4 is PB6").
 *   This task needs both at the same time, and one pin cannot be a plain
 *   output and a timer output at once. PB6 is kept for TIM4_CH1, and the chip
 *   select is moved to PC7, which is free and sits on the same header, right
 *   next to D10..D13, so the four SPI wires stay in one bundle.
 *
 * ┌──────────────────────────────────────────────────────────────────────────┐
 * │ 3. A FIX THE ARDUINO SKETCH NEEDS BEFORE ANY OF THIS WORKS               │
 * └──────────────────────────────────────────────────────────────────────────┘
 *   SPI_ArduinoNanoEvery_Slave.ino line 17 reads
 *
 *       SPI0.CTRLA = (SPI_DORD_bm & (SPI_ENABLE_bm & (~SPI_MASTER_bm)));
 *
 *   DORD, ENABLE and MASTER are three DIFFERENT single-bit masks, and the AND
 *   of two different single bits is zero. The line therefore writes 0x00 into
 *   CTRLA, which clears the ENABLE bit and switches the SPI peripheral off, so
 *   ISR(SPI0_INT_vect) is never entered. Replace that one line with
 *
 *       SPI0.CTRLA = (SPI0.CTRLA | SPI_ENABLE_bm)
 *                    & ~(SPI_MASTER_bm | SPI_DORD_bm);
 *
 *   enable = 1, master = 0 (client), DORD = 0 (MSB first, matching the "MSB
 *   First" set in CubeMX). The comment above that line claims DORD sets MSB
 *   first; it is the other way round - DORD = 1 means LSB first.
 *
 * ┌──────────────────────────────────────────────────────────────────────────┐
 * │ 4. CUBEMX SETUP (project "Lab2_Task3")                                   │
 * └──────────────────────────────────────────────────────────────────────────┘
 *   1. USART2 as in Task 1 (Asynchronous, 9600 8N1, global interrupt on) - the
 *      console is not required by the task but makes the value visible.
 *   2. Connectivity > SPI1 > Mode = Full-Duplex Master, Hardware NSS = Disable
 *   3. SPI1 > Parameter Settings (handout Figure 14):
 *        Frame Format   = Motorola      Data Size      = 8 Bits
 *        First Bit      = MSB First     Prescaler      = 128  -> 500 kbit/s
 *        CPOL           = Low           CPHA           = 1 Edge     (mode 0)
 *   4. Pinout: click PC7 -> GPIO_Output.  Set its user label to SPI_CS and its
 *      initial level to HIGH (chip select is active low, so idle is high).
 *   5. Timers > TIM4 > Clock Source = Internal Clock, Channel1 = PWM
 *      Generation CH1
 *   6. TIM4 > Parameter Settings: Prescaler = 63, Counter Mode = Up,
 *      Counter Period = 999, and in PWM Generation Channel 1:
 *      Mode = PWM mode 1, Pulse = 0, CH Polarity = High
 *   7. Ctrl+S.
 *
 * ┌──────────────────────────────────────────────────────────────────────────┐
 * │ 5. THE CALCULATIONS THE TASK ASKS FOR                                    │
 * └──────────────────────────────────────────────────────────────────────────┘
 *   SPI bit rate.  SPI1 hangs off APB2, which runs at the system clock:
 *       64 MHz / 128 = 500 kbit/s,  so one byte takes 8 / 500 000 = 16 us.
 *
 *   PWM frequency.  f_pwm = f_TIM4 / ((PSC + 1) * (ARR + 1)).
 *       PSC + 1 = 64     -> the counter ticks at 64 MHz / 64 = 1 MHz, 1 us/tick
 *       ARR + 1 = 1000   -> one PWM period is 1000 us
 *       f_pwm   = 64e6 / (64 * 1000) = 1000 Hz
 *   1 kHz is chosen instead of the 10 Hz of the handout because 10 Hz is far
 *   below the flicker-fusion frequency of the eye: the LED would visibly
 *   stutter instead of dimming. (The handout's own 10 Hz is also mis-computed:
 *   with Prescaler 64000-1 and Counter Period 100 the period is ARR+1 = 101
 *   ticks, giving 1000 / 101 = 9.90 Hz. Counter Period has to be 99.)
 *
 *   Duty cycle.  The Arduino ADC is 10 bits, so the value runs 0 to 1023 - not
 *   to 1024, which is the number of levels, not the largest one. Mapping it
 *   onto the 0..1000 counts of one period:
 *       CCR1 = adc * (ARR + 1) / 1023 = adc * 1000 / 1023
 *   adc = 0 -> 0 % , adc = 512 -> 50.0 % , adc = 1023 -> 100 %.
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
#define CMD_LOW_BYTE   0x00U               /* "load the low byte of A1"      */
#define CMD_HIGH_BYTE  0x01U               /* "load the high byte of A1"     */
#define CMD_DUMMY      0x00U               /* harmless byte used to clock    */

#define PWM_TOP        1000U               /* ARR + 1, counts per period     */
#define ADC_MAX        1023U               /* 10-bit ADC, largest value      */
/* USER CODE END PD */


/* USER CODE BEGIN PV */
static char out[96];
/* USER CODE END PV */


/* USER CODE BEGIN 0 */

static void uart_print(const char *s)
{
    HAL_UART_Transmit(&huart2, (uint8_t *)s, (uint16_t)strlen(s), HAL_MAX_DELAY);
}

/* One 8-bit full-duplex exchange. The chip select is left to the caller,
 * because the four bytes of a reading must stay inside one selection.       */
static uint8_t spi_swap(uint8_t tx)
{
    uint8_t rx = 0U;
    HAL_SPI_TransmitReceive(&hspi1, &tx, &rx, 1U, SPI_TIMEOUT);
    return rx;
}

/* Read the 10-bit potentiometer value out of the Arduino.
 *
 * The slave is one transfer behind, and that is not a defect but how an SPI
 * peripheral works: when its interrupt fires, the byte that was being shifted
 * out has already gone. The sketch reacts to a command by loading the answer
 * into SPI0.DATA, and that byte leaves during the NEXT exchange. So every
 * value costs two transfers - one to ask, one to clock the answer out:
 *
 *      master sends   slave shifts out        what we do with it
 *      -----------    --------------------    ------------------
 *      0x00           (whatever was loaded)   discard
 *      0x00 dummy     low byte of A1          keep
 *      0x01           low byte again          discard
 *      0x00 dummy     high byte of A1         keep
 *
 * The dummy byte is deliberately 0x00: the slave interprets everything it
 * receives, and 0x00 simply reloads the low byte, which is harmless. A random
 * dummy such as 0xFF would fall through the switch and do nothing, but a value
 * of 0x80..0x83 would silently change the blink rate.
 */
static uint16_t nano_read_analog(void)
{
    uint8_t lo, hi;

    HAL_GPIO_WritePin(CS_PORT, CS_PIN, GPIO_PIN_RESET);   /* select */

    (void)spi_swap(CMD_LOW_BYTE);
    HAL_Delay(1U);                    /* let the slave ISR load SPI0.DATA */
    lo = spi_swap(CMD_DUMMY);

    (void)spi_swap(CMD_HIGH_BYTE);
    HAL_Delay(1U);
    hi = spi_swap(CMD_DUMMY);

    HAL_GPIO_WritePin(CS_PORT, CS_PIN, GPIO_PIN_SET);     /* deselect */

    uint16_t v = ((uint16_t)hi << 8) | lo;
    return (v > ADC_MAX) ? ADC_MAX : v;   /* clamp, in case of a glitch */
}

/* USER CODE END 0 */


/* USER CODE BEGIN 2 */

    uart_print("\r\n=== UESTC 4014 RTCSA - Lab 2 Task 3 ===\r\n"
               "SPI reads the potentiometer, PWM on PB6 follows it.\r\n");

    HAL_GPIO_WritePin(CS_PORT, CS_PIN, GPIO_PIN_SET);   /* idle high */
    HAL_TIM_PWM_Start(&htim4, TIM_CHANNEL_1);

/* USER CODE END 2 */


/* USER CODE BEGIN 3 */

    {
        uint16_t adc  = nano_read_analog();

        /* 32-bit intermediate: adc * 1000 reaches 1 023 000, which would
         * overflow a 16-bit product.                                      */
        uint16_t duty = (uint16_t)(((uint32_t)adc * PWM_TOP) / ADC_MAX);

        __HAL_TIM_SET_COMPARE(&htim4, TIM_CHANNEL_1, duty);

        sprintf(out, "A1 = %4u / 1023   ->  CCR1 = %4u  (%2u.%01u %% duty)\r\n",
                (unsigned)adc, (unsigned)duty,
                (unsigned)(duty / 10U), (unsigned)(duty % 10U));
        uart_print(out);

        HAL_Delay(200U);        /* 5 updates per second is plenty to watch */
    }

/* USER CODE END 3 */


/*==============================================================================
 * WHAT TO OBSERVE
 *   Turning the potentiometer from one end to the other takes the LED on
 *   Nucleo D10 from fully off to fully on, smoothly, while the console prints
 *   the raw value and the duty cycle. The LED on Nano D2 keeps blinking at
 *   whatever rate was last commanded; this task never changes it.
 *
 * IF EVERY READING IS 0x00 OR 0xFF
 *   - the fix of section 3 above was not applied to the sketch, so its SPI
 *     peripheral is switched off;
 *   - MOSI and MISO are crossed (follow the table of section 1, not the
 *     handout);
 *   - CS is on Nano D10 instead of D8;
 *   - no common ground.
 *
 * IF THE VALUE JITTERS BUT ROUGHLY FOLLOWS THE KNOB
 *   Keeping the chip select low across all four bytes is what the code above
 *   does. Some slaves want it toggled per byte instead. To try that, move the
 *   two HAL_GPIO_WritePin() calls into spi_swap(), around the single transfer.
 *   Note which of the two was used - the report has to state it.
 *============================================================================*/
