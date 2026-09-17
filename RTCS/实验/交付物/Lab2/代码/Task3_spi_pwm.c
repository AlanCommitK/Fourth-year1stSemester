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
 *   are not). MISO is the only wire the 5 V Arduino drives INTO the Nucleo, so
 *   it needs attention. Preferred: a divider - Nano D12 -> 10 kohm -> PA6, and
 *   20 kohm from PA6 to GND, giving 5 x 20/30 = 3.33 V. A single 1 kohm in
 *   series is the common shortcut, but it does not actually limit the voltage;
 *   it only keeps the current into the pin's protection diode near 1 mA, and
 *   injecting current into what is also an ADC input can disturb conversions.
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
 *   6. TIM4 > Parameter Settings: Prescaler = TIMCLK / 1 MHz - 1
 *      (7 for an 8 MHz project, 63 for a 64 MHz one), Counter Mode = Up,
 *      Counter Period = 999, and in PWM Generation Channel 1:
 *      Mode = PWM mode 1, Pulse = 0, CH Polarity = High
 *      The code re-asserts both values anyway, so the important one to get
 *      right is TIMCLK_HZ below.
 *   6b. Also check PA5: with "initialize all peripherals" chosen at project
 *      creation CubeMX assigns it to the on-board LED LD2. It has to become
 *      SPI1_SCK here. LD2 then flickers during transfers - that is normal.
 *   7. Ctrl+S.
 *
 * ┌──────────────────────────────────────────────────────────────────────────┐
 * │ 5. THE CALCULATIONS THE TASK ASKS FOR                                    │
 * └──────────────────────────────────────────────────────────────────────────┘
 *   SPI bit rate.  SPI1 hangs off APB2, which runs at the system clock, so the
 *   prescaler of 128 gives 64 MHz / 128 = 500 kbit/s on a 64 MHz project (one
 *   byte = 16 us) and 8 MHz / 128 = 62.5 kbit/s on an 8 MHz one (128 us). Both
 *   work; only the throughput differs. State in the report which one applies.
 *
 *   PWM frequency.  f_pwm = f_TIM4 / ((PSC + 1) * (ARR + 1)).
 *       PSC + 1 = f_TIM4 / 1 MHz  -> the counter ticks once per microsecond
 *                                    (8 at 8 MHz, 64 at 64 MHz)
 *       ARR + 1 = 1000            -> one PWM period is 1000 us
 *       f_pwm   = 1 MHz / 1000    = 1000 Hz, whatever the system clock is
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

/* ---- the live blank: read "APB1 timer clocks (MHz)" in CubeMX ------------- */
/* A project created WITHOUT the board defaults sits on the internal 8 MHz
 * oscillator, and that is what the Lab 1 projects of this course read. With
 * the 64 MHz PLL setup, write 64000000UL here instead. Everything below is
 * derived from this one number, so nothing else has to change.               */
#define TIMCLK_HZ      8000000UL
#define TICK_HZ        1000000UL            /* aim for 1 us per counter tick  */
#define TIM_PSC        ((TIMCLK_HZ / TICK_HZ) - 1UL)   /* 7 at 8 MHz, 63 at 64 */

#define PWM_HZ         1000UL              /* 1 kHz: well above eye flicker  */
#define PWM_TOP        (TICK_HZ / PWM_HZ)  /* ARR + 1 = 1000 counts / period */
#define TIM_ARR        (PWM_TOP - 1UL)     /* 999                            */

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
/* Roughly 20 us at 72 MHz, less at slower clocks - the AVR interrupt needs
 * only a few microseconds, so this has margin either way.                   */
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

    /* The slave's interrupt needs a few microseconds to write the answer into
     * SPI0.DATA. A short busy wait is used rather than HAL_Delay(1), which
     * would idle for one to two milliseconds and widen the window in which
     * loop() can refresh the value between our two halves.                 */
    (void)spi_swap(CMD_LOW_BYTE);
    slave_settle();
    lo = spi_swap(CMD_DUMMY);

    (void)spi_swap(CMD_HIGH_BYTE);
    slave_settle();
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

    /* Re-assert the timing in software, so it does not depend on what was
     * typed into the CubeMX dialog. PSC is a buffered register (the same
     * shadow-register behaviour met in Lab 1), so an update event is forced
     * to load it before the timer runs.                                   */
    __HAL_TIM_SET_PRESCALER(&htim4, TIM_PSC);
    __HAL_TIM_SET_AUTORELOAD(&htim4, TIM_ARR);
    htim4.Instance->EGR = TIM_EGR_UG;
    __HAL_TIM_CLEAR_FLAG(&htim4, TIM_FLAG_UPDATE);

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
 *   the raw value and the duty cycle. The LED on Nano D2 is a separate matter:
 *   this task never sends 0x80..0x83, so the sketch keeps time = 0 and toggles
 *   D2 with no delay at all, which looks almost dark rather than blinking.
 *
 * IF EVERY READING IS 0x00 OR 0xFF
 *   - the fix of section 3 above was not applied to the sketch, so its SPI
 *     peripheral is switched off;
 *   - MOSI and MISO are crossed (follow the table of section 1, not the
 *     handout);
 *   - CS is on Nano D10 instead of D8;
 *   - no common ground.
 *
 * DO NOT TOGGLE THE CHIP SELECT PER BYTE
 *   Keeping it low across all four transfers is not a preference, it is
 *   required. The megaAVR-0 data sheet states that in client mode the SPI
 *   state machine is RESET when SS is driven high, and that data being sent or
 *   received at that moment must be considered lost. The whole protocol of
 *   this slave depends on state surviving from one transfer to the next - the
 *   byte its interrupt writes into SPI0.DATA is shifted out on the FOLLOWING
 *   transfer - so raising SS in between would throw that byte away.
 *
 * IF THE VALUE JITTERS BUT ROUGHLY FOLLOWS THE KNOB
 *   That is the sketch, not the wiring. Its case 0x0 returns the snapshot
 *   variable lower_val while case 0x1 returns the live analog_val >> 8, and
 *   loop() refreshes them between our transfers, so the two halves can come
 *   from two different conversions. The clamp below hides the worst of it.
 *   A clean fix belongs on the Arduino side: take one snapshot of analog_val
 *   in case 0x0 and serve both bytes from it.
 *============================================================================*/
