/*==============================================================================
 * Lab 1 - Task 1
 * Configure GPIOB pin 5 as a general-purpose output with a maximum speed of
 * 50 MHz, using direct register access only.
 *
 * Board : NUCLEO-F103RB (STM32F103RB, Cortex-M3)
 * Ref   : RM0008 section 9.2.1 (GPIOx_CRL) and 9.2.2 (GPIOx_CRH)
 *
 * WHERE TO PUT THIS (only if you want to check that it compiles - this task is
 * a paper exercise and needs no board)
 *   1. the three #define lines  -> between "USER CODE BEGIN PD" and "END PD"
 *   2. the body of gpiob_pin5_init() -> between "USER CODE BEGIN 2" and "END 2",
 *      i.e. after MX_GPIO_Init() and before the while(1) loop.
 *   Pasting only the two statements without the #define lines gives
 *   "'PB5_FIELD_MASK' undeclared".
 *   Nothing has to be selected in the CubeMX pinout view for this task: the
 *   two statements below do the whole job themselves.
 *============================================================================*/

/*------------------------------------------------------------------------------
 * 1. Which bits?
 *
 *    A port has 16 pins, each pin needs 4 configuration bits -> 64 bits, which
 *    does not fit in one 32-bit register. The configuration is therefore split:
 *
 *        GPIOx_CRL  ->  pins 0..7
 *        GPIOx_CRH  ->  pins 8..15
 *
 *    Inside its own register, pin n occupies bits [4n+3 : 4n].
 *    Pin 5  ->  4 x 5 = 20  ->  GPIOB_CRL bits [23:20].
 *
 * 2. Which value?
 *
 *    The 4-bit field is, from the most significant bit:  CNF1 CNF0 MODE1 MODE0
 *
 *      MODE[1:0]  direction / slew rate
 *                 00 = input          01 = output, max 10 MHz
 *                 10 = output, 2 MHz  11 = output, max 50 MHz
 *
 *      CNF[1:0]   electrical type, in OUTPUT mode
 *                 00 = general purpose push-pull
 *                 01 = general purpose open-drain
 *                 10 = alternate function push-pull
 *                 11 = alternate function open-drain
 *
 *    MODE first decides input vs output, and that choice selects which of the
 *    two meanings above CNF carries. Once the pin is an output, CNF and MODE no
 *    longer constrain each other - any electrical type may be combined with any
 *    slew rate. "General purpose output at 50 MHz" therefore means CNF = 00 and
 *    MODE = 11:
 *
 *        field = 0b0011 = 0x3
 *
 * 3. Which operations?
 *
 *    The other 28 bits of CRL belong to pins 0-4, 6 and 7 and must survive, so
 *    the update is a read-modify-write:
 *
 *      (a) clear the four target bits ..... AND with ~(0xF << 20)
 *            x & 1 = x  keeps every other bit
 *            x & 0 = 0  clears the four bits of the field
 *      (b) write the new value ............ OR  with  (0x3 << 20)
 *            x | 0 = x  keeps every other bit
 *            x | 1 = 1  sets the two ones of the field
 *
 *    OR alone cannot clear a bit and AND alone cannot set one; both steps are
 *    necessary.
 *----------------------------------------------------------------------------*/

#include "main.h"

#define PB5_FIELD_SHIFT   20U          /* 4 x pin number, pin 5 -> bit 20      */
#define PB5_FIELD_MASK    (0xFu << PB5_FIELD_SHIFT)   /* 0x00F00000            */
#define PB5_FIELD_VALUE   (0x3u << PB5_FIELD_SHIFT)   /* 0x00300000            */

void gpiob_pin5_init(void)
{
    /* The port must be clocked first: a write to a GPIO register of an
     * unclocked port is simply lost.                                          */
    RCC->APB2ENR |= RCC_APB2ENR_IOPBEN;

    /* Two statements - the readable form ------------------------------------
     *   GPIOB->CRL &= ~PB5_FIELD_MASK;    clear CNF5[1:0] and MODE5[1:0]
     *   GPIOB->CRL |=  PB5_FIELD_VALUE;   CNF = 00 (push-pull), MODE = 11
     *
     * One statement - the minimum, and atomic with respect to any other reader
     * of CRL, because the register is written exactly once:                   */
    GPIOB->CRL = (GPIOB->CRL & ~PB5_FIELD_MASK) | PB5_FIELD_VALUE;
}

/*------------------------------------------------------------------------------
 * Bit-level trace of the two operations. x = a bit whose value is unknown and
 * must be preserved.
 *
 *   step 1   0xF << 20   = 0000 0000 1111 0000 0000 0000 0000 0000  0x00F00000
 *   step 2  ~(0xF << 20) = 1111 1111 0000 1111 1111 1111 1111 1111  0xFF0FFFFF
 *
 *   step 3     xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx   CRL before
 *            & 1111 1111 0000 1111 1111 1111 1111 1111   0xFF0FFFFF
 *            = xxxx xxxx 0000 xxxx xxxx xxxx xxxx xxxx
 *
 *   step 4   0x3 << 20   = 0000 0000 0011 0000 0000 0000 0000 0000  0x00300000
 *
 *   step 5     xxxx xxxx 0000 xxxx xxxx xxxx xxxx xxxx
 *            | 0000 0000 0011 0000 0000 0000 0000 0000   0x00300000
 *            = xxxx xxxx 0011 xxxx xxxx xxxx xxxx xxxx   CRL after
 *
 * Bits [23:20] now read 0011: PB5 is a push-pull general-purpose output with a
 * 50 MHz maximum output speed, and every other pin of port B is untouched.
 *
 * Equivalent HAL call (for reference only, not required by the task):
 *   GPIO_InitTypeDef g = {0};
 *   g.Pin   = GPIO_PIN_5;
 *   g.Mode  = GPIO_MODE_OUTPUT_PP;      // CNF = 00
 *   g.Speed = GPIO_SPEED_FREQ_HIGH;     // MODE = 11 (50 MHz)
 *   HAL_GPIO_Init(GPIOB, &g);
 *----------------------------------------------------------------------------*/
