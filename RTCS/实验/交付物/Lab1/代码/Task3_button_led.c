/*==============================================================================
 * Lab 1 - Task 3
 * Light the user LED while the user button is held, using direct register
 * access for both the read and the write.
 *
 * Board : NUCLEO-F103RB (STM32F103RB, Cortex-M3)
 *   LD2  = PA5   driven by the MCU, LED lit when the pin is HIGH
 *   B1   = PC13  read by the MCU, externally pulled up on the Nucleo board
 *
 * CUBEMX SETUP (project "Lab1_Task3")
 *   Pinout view : PA5  -> GPIO_Output
 *                 PC13 -> GPIO_Input
 *   System Core > GPIO > PC13 : GPIO Pull-up/Pull-down = "No pull-up and no
 *                 pull-down". The board already carries an external pull-up on
 *                 PC13, so no internal one is needed.
 *   Nothing else. No timer, no interrupt.
 *
 * This file is a set of snippets, not a compilable translation unit. Each block
 * below is bracketed by the CubeMX markers that say where it goes in main.c;
 * code between those markers survives regeneration of the project.
 *============================================================================*/


/* USER CODE BEGIN Includes */
#include <stdbool.h>   /* needed by the bool variable below. Recent CubeIDE
                          versions do not include this header for you; without
                          it the compiler reports
                          "unknown type name 'bool'"                          */
/* USER CODE END Includes */


/* USER CODE BEGIN PD */
#define LED_PORT   GPIOA
#define LED_PIN    5U        /* LD2 on PA5  */
#define BTN_PORT   GPIOC
#define BTN_PIN    13U       /* B1 on PC13  */

#define LED_MASK   (1u << LED_PIN)    /* 0x00000020 */
#define BTN_MASK   (1u << BTN_PIN)    /* 0x00002000 */
/* USER CODE END PD */


/* -----------------------------------------------------------------------------
 * The loop body goes in section 3, which CubeMX generates INSIDE while(1):
 *
 *     while (1)
 *     {
 *       // USER CODE END WHILE
 *
 *       // USER CODE BEGIN 3
 *          <- here
 *     }
 *     // USER CODE END 3
 * ---------------------------------------------------------------------------*/

/* USER CODE BEGIN 3 */

    /* Read the button. This is exactly the expression discussed in Task 2:
     *
     *   BTN_PORT->IDR          the whole 32-bit input register; bits [15:0]
     *                          mirror the levels on pins 0..15, bits [31:16]
     *                          read as zero.
     *   & BTN_MASK             keeps bit 13 only. The result is 0 or 0x2000 -
     *                          NEVER 1, which is why the comparison must be
     *                          against 0 and not against 1.
     *   != 0                   reduces that to 0 or 1.
     */
    bool pc13_high = (BTN_PORT->IDR & BTN_MASK) != 0u;

    /* B1 is held high by the board's external pull-up and is connected to
     * ground while pressed, so "pin low" means "button pressed". ST's own board
     * support package configures this button as GPIO_MODE_IT_FALLING, which is
     * the same statement about polarity.                                      */
    if (!pc13_high)                    /* pressed */
    {
        LED_PORT->ODR |=  LED_MASK;    /* set bit 5   -> LD2 on   */
    }
    else
    {
        LED_PORT->ODR &= ~LED_MASK;    /* clear bit 5 -> LD2 off  */
    }

    /* Both branches touch bit 5 only: "|= mask" sets it while leaving the other
     * fifteen outputs of port A alone (x | 0 = x), and "&= ~mask" clears it for
     * the mirror-image reason (x & 1 = x).
     *
     * STM32 also offers a one-write, non-read-modify-write alternative that
     * cannot be interrupted half way:
     *     LED_PORT->BSRR = LED_MASK;          // set   bit 5
     *     LED_PORT->BSRR = LED_MASK << 16;    // reset bit 5   (or BRR = mask)
     * Either form is acceptable here; the ODR form is used above because it is
     * the one the lab handout introduces.
     */

/* USER CODE END 3 */


/*==============================================================================
 * IF THE LED BEHAVES THE OTHER WAY ROUND
 *
 * If, after flashing, LD2 is lit while the button is RELEASED and goes out when
 * the button is pressed, then this particular board pulls PC13 high on press.
 * In that case drop one character - the negation:
 *
 *     if (pc13_high)                  // pressed == logic high
 *
 * Nothing else changes. Note which of the two versions was used, because the
 * report has to state it.
 *
 * VERIFICATION (do this before taking the photographs)
 *   1. Flash, then do not touch the board: LD2 must be OFF.
 *   2. Press and hold B1 (the blue button): LD2 must be ON for as long as it is
 *      held, and must go out immediately on release.
 *   3. If step 1 shows the LED already lit, use the inverted comparison above.
 *============================================================================*/
