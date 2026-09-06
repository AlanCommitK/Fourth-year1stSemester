/*==============================================================================
 * Lab 1 - Task 4
 * One press of the user button starts LD2 blinking; the next press stops it and
 * leaves the LED off. No delay() and no HAL_Delay() anywhere.
 *
 * Board : NUCLEO-F103RB (STM32F103RB, Cortex-M3)
 *   LD2  = PA5   output, LED lit when the pin is HIGH
 *   B1   = PC13  external interrupt, falling edge = button pressed
 *
 * Two interrupt sources, no polling and no busy waiting:
 *   TIM2 update interrupt  (internal) -> toggles LD2 every 1.5 s
 *   EXTI line 13           (external) -> starts / stops the timer
 * The while(1) loop of main() stays completely empty.
 *
 * ---------------------------------------------------------------------------
 * CUBEMX SETUP (project "Lab1_Task4") - do this before pasting anything
 *
 *  1. Pinout & Configuration > Timers > TIM2
 *        Clock Source = Internal Clock
 *  2. TIM2 > Parameter Settings
 *        Prescaler        = see table below   (31999 if APB1 timer clk = 64 MHz)
 *        Counter Mode     = Up
 *        Counter Period   = 2999
 *        auto-reload preload = Disable
 *  3. TIM2 > NVIC Settings
 *        TIM2 global interrupt = enabled
 *  4. Pinout view: click PC13 -> GPIO_EXTI13
 *  5. System Core > GPIO > PC13
 *        GPIO mode  = External Interrupt Mode with Falling edge trigger detection
 *        Pull-up/Pull-down = No pull-up and no pull-down
 *        (the Nucleo board already has an external pull-up on PC13)
 *  6. System Core > NVIC
 *        EXTI line[15:10] interrupts = enabled
 *  7. Pinout view: click PA5 -> GPIO_Output
 *  8. Ctrl+S to regenerate the project, then paste the blocks below.
 *
 * ---------------------------------------------------------------------------
 * THE ONE NUMBER THAT MUST BE READ OFF THE BOARD'S CLOCK TREE
 *
 * TIM2 sits on the APB1 domain, and the APB1 timer clock is NOT necessarily the
 * system clock. Open Clock Configuration in CubeMX and read the box labelled
 * "APB1 timer clocks (MHz)". Put that number into TIMCLK_HZ below; everything
 * else is derived from it by the preprocessor.
 *
 *      T = (PSC + 1) * (ARR + 1) / f_TIMxCLK
 *
 * Both registers are 16 bit, so each of (PSC+1) and (ARR+1) must stay <= 65536.
 * Fixing the post-prescaler tick rate at F = 2 kHz makes ARR independent of the
 * clock:   ARR + 1 = F * T = 2000 * 1.5 = 3000,   PSC + 1 = f_TIMxCLK / F
 *
 *    f_TIMxCLK | PSC+1  | Prescaler field | Counter Period field | period
 *    ----------+--------+-----------------+----------------------+---------
 *      8 MHz   |  4 000 |      3999       |        2999          | 1.5000 s
 *     32 MHz   | 16 000 |     15999       |        2999          | 1.5000 s
 *     36 MHz   | 18 000 |     17999       |        2999          | 1.5000 s
 *     48 MHz   | 24 000 |     23999       |        2999          | 1.5000 s
 *     64 MHz   | 32 000 |     31999       |        2999          | 1.5000 s   <-- default
 *     72 MHz   | 36 000 |     35999       |        2999          | 1.5000 s
 *
 * This file is a set of snippets, not a compilable translation unit. Each block
 * is bracketed by the CubeMX markers that say where it goes in main.c; code
 * between those markers survives regeneration of the project.
 *============================================================================*/


/* USER CODE BEGIN Includes */
#include <stdbool.h>
/* USER CODE END Includes */


/* USER CODE BEGIN PD */
/* ---- the live blank: read "APB1 timer clocks (MHz)" in CubeMX ------------- */
#define TIMCLK_HZ    64000000UL      /* <== CHANGE THIS IF THE BOX SAYS OTHERWISE */

#define TICK_HZ      2000UL          /* post-prescaler tick rate, chosen so that
                                        both registers stay inside 16 bits      */
#define BLINK_MS     1500UL          /* time between two LED state changes      */

#define TIM2_PSC     ((TIMCLK_HZ / TICK_HZ) - 1UL)              /* 31999 @64MHz */
#define TIM2_ARR     ((TICK_HZ * BLINK_MS / 1000UL) - 1UL)      /* 2999         */

#define LED_PORT     GPIOA
#define LED_PIN      5U
#define LED_MASK     (1u << LED_PIN)      /* 0x00000020 */

#define BTN_PIN      GPIO_PIN_13          /* HAL pin mask 0x2000, for the callback */
#define DEBOUNCE_MS  200U                 /* ignore edges closer together than this */
/* USER CODE END PD */


/* USER CODE BEGIN PV */
static volatile bool     blinking   = false;   /* current state of the toggle   */
static volatile uint32_t last_press = 0U;      /* timestamp of the accepted edge */
/* USER CODE END PV */


/* -----------------------------------------------------------------------------
 * Section 2 runs once, after every MX_xxx_Init() and before while(1).
 * ---------------------------------------------------------------------------*/

/* USER CODE BEGIN 2 */

    /* Re-assert the computed timing in software, so the behaviour no longer
     * depends on what was typed into the CubeMX dialog.                       */
    __HAL_TIM_SET_PRESCALER(&htim2, TIM2_PSC);
    __HAL_TIM_SET_AUTORELOAD(&htim2, TIM2_ARR);

    /* PSC is a buffered (shadow) register: the value written above only becomes
     * the active divider at the next update event, so without the line below
     * the FIRST interval would still run at the old prescaler. Writing UG in
     * EGR forces that update event immediately. It is the same line HAL itself
     * uses at the end of TIM_Base_SetConfig().                                */
    htim2.Instance->EGR = TIM_EGR_UG;

    /* Side effect of UG: it raises the update flag UIF. The flag is cleared
     * later, immediately before the timer is started, which also protects
     * against a stale flag left over by MX_TIM2_Init().                       */

    /* Wrap-safe seed for the debounce timestamp: makes the very first press
     * acceptable even if it happens within DEBOUNCE_MS of reset.              */
    last_press = HAL_GetTick() - DEBOUNCE_MS;

    /* Start with the LED off and the timer stopped. The timer is deliberately
     * NOT started here - it starts on the first button press.                 */
    LED_PORT->ODR &= ~LED_MASK;

/* USER CODE END 2 */


/* -----------------------------------------------------------------------------
 * The main loop stays empty. Everything happens in the two ISRs below.
 *
 *     while (1)
 *     {
 *       // USER CODE END WHILE
 *
 *       // USER CODE BEGIN 3
 *     }
 *     // USER CODE END 3
 * ---------------------------------------------------------------------------*/


/* -----------------------------------------------------------------------------
 * Section 4 sits at the end of main.c, after main(). Both callbacks are declared
 * __weak inside the HAL, so defining them here overrides the empty versions.
 * ---------------------------------------------------------------------------*/

/* USER CODE BEGIN 4 */

/* Internal interrupt: TIM2 raised an update event, i.e. the counter wrapped
 * after (ARR+1) ticks. With the values above that is exactly every 1.5 s.     */
void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim)
{
    /* One callback is shared by every timer in the project, so the source has
     * to be identified before acting on it.                                   */
    if (htim->Instance == TIM2)
    {
        LED_PORT->ODR ^= LED_MASK;   /* x ^ 1 flips, x ^ 0 keeps: bit 5 toggles,
                                        the other fifteen outputs are untouched */
    }
}

/* External interrupt: falling edge on PC13, i.e. the user button was pressed. */
void HAL_GPIO_EXTI_Callback(uint16_t GPIO_Pin)
{
    /* Shared by all sixteen EXTI lines - check which one fired.               */
    if (GPIO_Pin != BTN_PIN)
    {
        return;
    }

    /* A mechanical switch bounces: one physical press produces a burst of
     * edges over a few milliseconds, and each of them would toggle the state.
     * Accept an edge only if it is at least DEBOUNCE_MS after the last accepted
     * one. HAL_GetTick() merely reads the SysTick millisecond counter - it does
     * not block, so it is legal inside an ISR.                                */
    uint32_t now = HAL_GetTick();
    if ((now - last_press) < DEBOUNCE_MS)
    {
        return;
    }
    last_press = now;

    if (!blinking)
    {
        blinking = true;
        __HAL_TIM_SET_COUNTER(&htim2, 0U);                  /* full first interval */
        __HAL_TIM_CLEAR_FLAG(&htim2, TIM_FLAG_UPDATE);      /* drop any stale UIF  */
        HAL_TIM_Base_Start_IT(&htim2);
    }
    else
    {
        blinking = false;
        HAL_TIM_Base_Stop_IT(&htim2);
        LED_PORT->ODR &= ~LED_MASK;                         /* leave the LED off   */
    }
}

/* USER CODE END 4 */


/*==============================================================================
 * ANSWERS THE TASK ASKS FOR
 *
 *   Timer           TIM2, internal clock source, up-counting, update interrupt
 *   Prescaler       31999   (for f_TIMxCLK = 64 MHz; other clocks in the table)
 *   Counter period  2999
 *   Period          32000 x 3000 / 64e6 = 1.5000 s
 *   Code            the five blocks above
 *
 * ------------------------------------------------------------------------------
 * TWO READINGS OF "BLINK FOR 1.5 SECONDS", AND HOW TO SWITCH BETWEEN THEM
 *
 *   Reading A (implemented): the LED changes state every 1.5 s, so it is on for
 *     1.5 s and off for the next 1.5 s. This matches the handout's own worked
 *     example, which asks for an event "after every one second" and toggles the
 *     LED in that event.               ->  BLINK_MS 1500, ARR 2999
 *
 *   Reading B: one complete on-then-off cycle lasts 1.5 s, so each half lasts
 *     0.75 s.                          ->  BLINK_MS 750,  ARR 1499
 *
 *   Only the one #define changes; PSC, the wiring and the logic stay identical.
 *
 * ------------------------------------------------------------------------------
 * IF THE BUTTON DOES NOTHING
 *
 *   The trigger edge and the button polarity are two statements of one fact. The
 *   Nucleo board pulls PC13 up externally and the press connects it to ground,
 *   which is why step 5 selects "falling edge" - the setting ST's own board
 *   support package uses for this button. If pressing has no effect at all,
 *   switch the GPIO mode of PC13 to "External Interrupt Mode with Rising edge
 *   trigger detection", regenerate, and try again. Record which of the two was
 *   used, because the report has to state it.
 *
 * ------------------------------------------------------------------------------
 * VERIFICATION (do this before taking the photographs)
 *   1. Flash, do not touch the board: LD2 stays off indefinitely.
 *   2. Press once: LD2 starts blinking. Time ten full on-off cycles with a
 *      phone stopwatch - it should take about 30 s (10 x 2 x 1.5 s). Anything
 *      near 15 s or 60 s means TIMCLK_HZ does not match the board.
 *   3. Press again: the blinking stops and LD2 stays off.
 *   4. Repeat step 2 and 3 a few times: every press must flip the state exactly
 *      once. If one press sometimes flips it twice, raise DEBOUNCE_MS.
 *============================================================================*/
