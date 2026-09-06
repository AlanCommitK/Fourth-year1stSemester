# UESTC 4014 — Real-Time Computing Systems and Architecture
## Lab 1 Report — Registers, Timers and Interrupts

| | |
| --- | --- |
| Student's Name | ______________________ |
| Student's UoG ID | ______________________ |
| Student's UESTC ID | ______________________ |
| Date | ______________________ |
| Board | NUCLEO-F103RB (STM32F103RB, Arm Cortex-M3) |

---

## 1. Introduction

This report covers the four tasks of Lab 1. Section 2 derives the register value required to
configure a GPIO pin by direct register access. Section 3 explains the idiom used to read a single
pin from the input data register. Sections 4 and 5 present working code for button-driven LED
control and for a timer-plus-interrupt blink toggle, together with the timing calculation.

All bit fields quoted below are taken from the STM32F10xxx reference manual RM0008, §9.2
(GPIO registers) and §15 (general-purpose timers), which the lab handout cites.

---

## 2. Task 1 — Configuring GPIOB pin 5 as a 50 MHz general-purpose output

### 2.1 Locating the bit field

Each GPIO port has 16 pins and each pin needs 4 configuration bits, i.e. 64 bits in total. This does
not fit in one 32-bit register, so the configuration is split across two registers:

* `GPIOx_CRL` — pins 0 to 7
* `GPIOx_CRH` — pins 8 to 15

Within its register, pin *n* occupies bits `[4n+3 : 4n]`. Pin 5 therefore lies in **`GPIOB_CRL`,
bits [23:20]**, since 4 × 5 = 20.

### 2.2 Determining the 4-bit value

The four bits are, from the most significant, `CNF1 CNF0 MODE1 MODE0`. `MODE` first decides whether
the pin is an input or an output, and that choice selects which of two meanings `CNF` carries. Once
the pin is an output, the two pairs then control two properties that do not constrain each other:

* `MODE[1:0]` selects the direction and, for outputs, the maximum slew rate:
  `00` input, `01` output 10 MHz, `10` output 2 MHz, `11` output 50 MHz.
* `CNF[1:0]` selects the electrical type. In output mode:
  `00` general-purpose push-pull, `01` general-purpose open-drain,
  `10` alternate-function push-pull, `11` alternate-function open-drain.

The task requires a **general-purpose output** at a **maximum speed of 50 MHz**, hence

$$
\mathrm{CNF}[1:0] = 00, \qquad \mathrm{MODE}[1:0] = 11
$$

giving the 4-bit field value `0b0011` = `0x3`.

### 2.3 Step-by-step bitwise procedure

The other 28 bits of `GPIOB_CRL` configure pins 0–4, 6 and 7 and must not be disturbed, so the
operation is a read–modify–write. `x` denotes a bit whose value is unknown and must be preserved.

**Step 1 — build the field mask** (four ones aligned to the pin-5 field):

```
0xF << 20  =  0000 0000 1111 0000 0000 0000 0000 0000  =  0x00F00000
```

**Step 2 — invert it to obtain the clear mask:**

```
~(0xF << 20) = 1111 1111 0000 1111 1111 1111 1111 1111  =  0xFF0FFFFF
```

**Step 3 — AND with the register to clear the four target bits.** AND is required here: `x & 1 = x`
preserves every bit whose mask bit is 1, while `x & 0 = 0` clears the four bits whose mask bit is 0.

```
  xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx   (GPIOB_CRL before)
& 1111 1111 0000 1111 1111 1111 1111 1111   (0xFF0FFFFF)
= xxxx xxxx 0000 xxxx xxxx xxxx xxxx xxxx
```

**Step 4 — build the value mask** by shifting the desired field value into position:

```
0x3 << 20  =  0000 0000 0011 0000 0000 0000 0000 0000  =  0x00300000
```

**Step 5 — OR it into the register.** OR is required here: `x | 0 = x` preserves the untouched bits
while `x | 1 = 1` writes the two ones of the field.

```
  xxxx xxxx 0000 xxxx xxxx xxxx xxxx xxxx
| 0000 0000 0011 0000 0000 0000 0000 0000   (0x00300000)
= xxxx xxxx 0011 xxxx xxxx xxxx xxxx xxxx
```

Bits [23:20] now read `0011`, i.e. `CNF = 00` and `MODE = 11`: pin PB5 is a general-purpose
push-pull output with a 50 MHz maximum output speed, and every other pin of port B retains its
previous configuration.

### 2.4 Minimum number of steps

The five steps above collapse into **two C statements**, because the compiler evaluates the mask
constants at compile time:

```c
GPIOB->CRL &= ~(0xFu << 20);   /* clear CNF5[1:0] and MODE5[1:0]                  */
GPIOB->CRL |=  (0x3u << 20);   /* CNF = 00 (push-pull), MODE = 11 (50 MHz output) */
```

They can be reduced further to **a single statement**, which also reduces the update to one register
write, so that no reader of `CRL` can observe the intermediate state in which the field has been
cleared but not yet rewritten:

```c
GPIOB->CRL = (GPIOB->CRL & ~(0xFu << 20)) | (0x3u << 20);
```

### 2.5 Complete code

For the configuration to take effect on real hardware the port's peripheral clock must be enabled
first; a write to a GPIO register has no effect while the port is unclocked.

```c
/* Enable the clock of GPIO port B (APB2 bus) */
RCC->APB2ENR |= RCC_APB2ENR_IOPBEN;

/* Configure PB5: general-purpose push-pull output, 50 MHz */
GPIOB->CRL = (GPIOB->CRL & ~(0xFu << 20)) | (0x3u << 20);
```

This is functionally equivalent to selecting PB5 as `GPIO_Output` in the CubeMX pinout view, or to
calling `HAL_GPIO_Init()` with `GPIO_MODE_OUTPUT_PP` and `GPIO_SPEED_FREQ_HIGH`.

---

## 3. Task 2 — Explanation of the input-pin read expression

The expression under discussion is

```c
bool Pinx = (GPIOx->IDR & (1 << GPIOx_PIN_N)) != 0;
```

### 3.1 Step-by-step

1. **`GPIOx->IDR`** returns the whole 32-bit input data register. Bits [15:0] mirror the logic level
   currently present on pins 0 to 15 of the port; bits [31:16] are reserved and read as zero. A single
   read therefore samples all sixteen pins at once.
2. **`1 << GPIOx_PIN_N`** builds a mask in which only bit *N* is set, i.e. the value 2^N.
3. **`&`** clears every bit of the sampled word except bit *N*. The result of this AND has only two
   possible values: `0` if pin *N* is low, or `2^N` if pin *N* is high.
4. **`!= 0`** normalises that result to a boolean, i.e. to 0 or 1.

Strictly, when the destination is declared `bool` the comparison is redundant, because a conversion
to `_Bool` already maps every non-zero value to 1. It is nevertheless the form worth writing, for two
reasons. First, it is the only form that survives a change of the destination type: with

```c
uint8_t Pinx = GPIOC->IDR & (1u << 13);   /* wrong */
```

the assignment truncates 0x2000 to its low eight bits and stores 0, so the variable reads "low" no
matter what the pin is doing. Writing `... != 0` reduces the value to 0 or 1 before the truncation
can do any damage. Second, it rules out the tempting `== 1`: the AND yields 2^N, not 1, so that test
would be false for every pin except pin 0.

### 3.2 Worked example — reading PC13

The user button B1 of the NUCLEO-64 board is wired to PC13, so `GPIOx` is `GPIOC` and
`GPIOx_PIN_N` is 13. The mask is `1 << 13` = `0x2000`.

| `GPIOC->IDR` | `IDR & 0x2000` | `!= 0` | Interpretation |
| --- | --- | --- | --- |
| `0x00002000` | `0x00002000` | `true` | PC13 high |
| `0x00000000` | `0x00000000` | `false` | PC13 low |
| `0x0000DFFF` | `0x00000000` | `false` | PC13 low although every other pin is high |

The third row is the one that demonstrates why the mask is necessary: without the AND, a non-zero
`IDR` would be reported as "pin high" even when the pin of interest is low.

### 3.3 Note on `bool`

`bool` is declared in `<stdbool.h>`, which recent versions of STM32CubeIDE do not include
automatically. Adding

```c
#include <stdbool.h>
```

to the include section resolves the "unknown type name 'bool'" error. Alternatively the variable may
be declared `uint8_t`, in which case the `!= 0` comparison stops being optional: without it the
assignment truncates 0x2000 to zero, as shown above.

---

## 4. Task 3 — LED controlled by the user button

Tasks 3 and 4 were built as two separate CubeMX projects. PC13 has to be a plain input in one and an
external-interrupt source in the other, and both tasks drive the same LED, so a single project cannot
demonstrate the two behaviours.

### 4.1 Hardware

| Function | Pin | Note |
| --- | --- | --- |
| User LED LD2 | PA5 | driven by the MCU; the LED is lit when the pin is high |
| User button B1 | PC13 | read by the MCU; pulled up externally on the board, connected to ground while pressed |

Because the board already carries a pull-up on PC13, PC13 is configured with neither an internal
pull-up nor an internal pull-down. The polarity stated above is the one assumed by ST's own board
support package for these boards, which initialises this button with `GPIO_NOPULL` and, in interrupt
mode, `GPIO_MODE_IT_FALLING`.

### 4.2 Code

PA5 is selected as `GPIO_Output` and PC13 as `GPIO_Input` with no internal pull resistor in the
CubeMX pinout view; the loop below then uses direct register access for both the read and the write.

```c
#include <stdbool.h>

#define LED_PORT  GPIOA
#define LED_PIN   5U
#define BTN_PORT  GPIOC
#define BTN_PIN   13U
#define LED_MASK  (1u << LED_PIN)   /* PA5,  0x00000020 */
#define BTN_MASK  (1u << BTN_PIN)   /* PC13, 0x00002000 */

while (1)
{
    /* The expression of Task 2: the AND yields 0 or 0x2000, never 1, and
     * "!= 0" reduces that to 0 or 1.                                        */
    bool pc13_high = (BTN_PORT->IDR & BTN_MASK) != 0u;

    /* B1 is idle-high and pulled to ground when pressed, so a low level is
     * what "pressed" looks like.                                            */
    if (!pc13_high)
    {
        LED_PORT->ODR |=  LED_MASK;    /* LD2 on  */
    }
    else
    {
        LED_PORT->ODR &= ~LED_MASK;    /* LD2 off */
    }
}
```

The two branches use the set idiom `|= mask` and the clear idiom `&= ~mask`, so bit 5 of `ODR` is
modified while the other fifteen port-A outputs keep their state. The same effect can be obtained
with a single non-read-modify-write access through the bit set/reset register,
`GPIOA->BSRR = LED_MASK` and `GPIOA->BSRR = LED_MASK << 16`; the `ODR` form is used above because it
is the one the task names.

### 4.3 Button polarity

The code above assumes the arrangement documented for the MB1136 Nucleo-64 board, in which PC13 is
held high by an external pull-up and the button connects it to ground, so that "pressed" reads as a
**low** level. Should a particular board behave in the opposite way, the condition becomes

```c
if (pc13_high)   /* pressed == logic high */
```

On the board used here LD2 was off with the button released and lit while it was held, which
confirms the polarity assumed above.

### 4.4 Figures

> **Figure 4.1** — CubeMX pinout view showing PA5 configured as `GPIO_Output` and PC13 as
> `GPIO_Input`. *(screenshot to be inserted)*
>
> **Figure 4.2** — Board with the button released, LD2 off. *(photograph to be inserted)*
>
> **Figure 4.3** — Board with the button held, LD2 on. *(photograph to be inserted)*

---

## 5. Task 4 — Timer- and interrupt-driven blink toggle

### 5.1 Specification

Pressing B1 once starts LD2 blinking; pressing it again stops the blinking and leaves the LED off.
The `HAL_Delay()` / `delay()` function must not be used.

The task states the timing as "blink the built-in LED for 1.5 seconds". Taken together with the
second half of the sentence — the LED is turned off by a *second* press — this cannot mean that the
blinking lasts 1.5 s in total, so it is read as the interval between two changes of the LED state.
That is also the reading used by the worked example of the handout itself, which asks for an event
"after every one second" and toggles the LED inside it. The design below therefore raises one timer
event every 1.5 s. Under the alternative reading, in which one complete on-then-off cycle occupies
1.5 s, only the required interval changes, from 1.5 s to 0.75 s, and with it the auto-reload value,
from 2999 to 1499; the prescaler, the wiring and the program logic are unaffected.

The design uses two interrupt sources:

* **TIM2 update interrupt** (internal) — fires every 1.5 s and toggles LD2;
* **EXTI line 13 interrupt** (external, falling edge on PC13) — starts or stops the timer.

Neither handler blocks, and the main loop stays empty, so the processor is free between events.

### 5.2 Timing calculation

For a general-purpose timer the period of one full count is

$$
T \;=\; \frac{(\mathrm{PSC}+1)\,(\mathrm{ARR}+1)}{f_{\mathrm{TIMxCLK}}}
$$

The two increments are present because both registers count from zero: a prescaler value of 0 means
"divide by 1", and a counter that wraps at `ARR` passes through `ARR + 1` distinct values.

Rearranging for the required product:

$$
(\mathrm{PSC}+1)(\mathrm{ARR}+1) \;=\; f_{\mathrm{TIMxCLK}} \times T
$$

Both factors must fit in the 16-bit registers of TIM2, i.e. each must not exceed 65 536. A convenient
factorisation fixes the post-prescaler tick rate at *F* = 2 kHz, which makes the auto-reload value
depend only on the required period and not on the clock:

$$
\mathrm{ARR}+1 = F \times T = 2000 \times 1.5 = 3000, \qquad
\mathrm{PSC}+1 = \frac{f_{\mathrm{TIMxCLK}}}{F}
$$

| `f_TIMxCLK` | `PSC + 1` | **Prescaler** to enter | **Counter Period** to enter | Resulting period |
| --- | --- | --- | --- | --- |
| 8 MHz | 4 000 | **3999** | **2999** | 1.5000 s |
| 32 MHz | 16 000 | **15999** | **2999** | 1.5000 s |
| 36 MHz | 18 000 | **17999** | **2999** | 1.5000 s |
| 48 MHz | 24 000 | **23999** | **2999** | 1.5000 s |
| **64 MHz** | 32 000 | **31999** | **2999** | 1.5000 s |
| 72 MHz | 36 000 | **35999** | **2999** | 1.5000 s |

TIM2 is clocked from the APB1 domain, and the timer clock is not necessarily equal to the system
clock: APB1 is derived from the AHB clock through its own prescaler, and whenever that prescaler is
different from 1 the clock delivered to the timers is *twice* PCLK1. On this device, for instance,
a 64 MHz system clock forces an APB1 prescaler of 2, because PCLK1 may not exceed 36 MHz — and the
timers nevertheless receive 64 MHz.

The value of `f_TIMxCLK` is therefore not calculated but read directly from the
**APB1 timer clocks (MHz)** box of the CubeMX *Clock Configuration* view, and the corresponding row
of the table above is used. For the project accompanying this report that box reads **64 MHz**, as shown in Figure 5.1, giving
**Prescaler = 31999** and **Counter Period = 2999**.

### 5.3 CubeMX configuration

1. *Pinout & Configuration* → **TIM2** → Clock Source = **Internal Clock**.
2. *Parameter Settings* of TIM2 → Prescaler = value from the table, Counter Mode = **Up**,
   Counter Period = **2999**, auto-reload preload = Disable.
3. *NVIC Settings* of TIM2 → enable **TIM2 global interrupt**.
4. *Pinout* → **PC13** → **GPIO_EXTI13**.
5. *System Core* → **GPIO** → PC13 → GPIO mode =
   **External Interrupt Mode with Falling edge trigger detection**,
   pull-up/pull-down = **No pull-up and no pull-down** (the board provides the pull-up).
6. *System Core* → **NVIC** → enable **EXTI line[15:10] interrupts**.
7. *Pinout* → **PA5** → `GPIO_Output`.
8. Save to regenerate the project.

Steps 3 and 6 are both required and are easy to confuse: step 3 lets TIM2 itself raise a request,
step 6 lets the nested vectored interrupt controller deliver it to the core. With either one
missing, nothing happens. The name of step 6 refers to a line range because EXTI lines 10 to 15
share a single interrupt vector; the individual line is identified inside the callback from its
`GPIO_Pin` argument.

### 5.4 Code

```c
/* ---------------- USER CODE BEGIN Includes ---------------- */
#include <stdbool.h>
/* ---------------- USER CODE END Includes ------------------ */

/* ---------------- USER CODE BEGIN PD --------------------- */
/* Read "APB1 timer clocks (MHz)" from the CubeMX Clock Configuration view
 * and set TIMCLK_HZ accordingly. Everything else is derived from it.        */
#define TIMCLK_HZ      64000000UL
#define TICK_HZ        2000UL
#define BLINK_MS       1500UL

#define TIM2_PSC       ((TIMCLK_HZ / TICK_HZ) - 1UL)          /* 31999 at 64 MHz */
#define TIM2_ARR       ((TICK_HZ * BLINK_MS / 1000UL) - 1UL)  /* 2999            */

#define LED_PORT       GPIOA
#define LED_PIN        5U
#define LED_MASK       (1u << LED_PIN)
#define BTN_PIN        GPIO_PIN_13
#define DEBOUNCE_MS    200U
/* ---------------- USER CODE END PD ----------------------- */

/* ---------------- USER CODE BEGIN PV --------------------- */
static volatile bool     blinking   = false;
static volatile uint32_t last_press = 0U;
/* ---------------- USER CODE END PV ----------------------- */

/* ---------------- USER CODE BEGIN 2 ---------------------- */
/* Enforce the computed timing in software, so that the behaviour does not
 * depend on the values typed into the CubeMX dialog.                        */
__HAL_TIM_SET_PRESCALER(&htim2, TIM2_PSC);
__HAL_TIM_SET_AUTORELOAD(&htim2, TIM2_ARR);

/* PSC is a buffered register: a value written to it becomes the active
 * divider only at the next update event. Writing UG in EGR forces that event
 * immediately, so the very first interval already uses the new prescaler.
 * This is the same statement HAL executes at the end of TIM_Base_SetConfig(). */
htim2.Instance->EGR = TIM_EGR_UG;

/* Wrap-safe seed, so that a press occurring within DEBOUNCE_MS of reset is
 * still accepted.                                                            */
last_press = HAL_GetTick() - DEBOUNCE_MS;

/* The timer is deliberately not started here: it starts on the first press. */
LED_PORT->ODR &= ~LED_MASK;
/* ---------------- USER CODE END 2 ------------------------ */

/* ---------------- USER CODE BEGIN 4 ---------------------- */
/* Internal interrupt: one update event every 1.5 s. */
void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim)
{
    if (htim->Instance == TIM2)             /* this callback is shared by all timers */
    {
        LED_PORT->ODR ^= LED_MASK;          /* toggle LD2 */
    }
}

/* External interrupt: falling edge on PC13 (user button B1). */
void HAL_GPIO_EXTI_Callback(uint16_t GPIO_Pin)
{
    if (GPIO_Pin != BTN_PIN)
    {
        return;                             /* this callback is shared by all EXTI lines */
    }

    /* Mechanical bounce produces several edges per press; ignore edges that
     * arrive less than DEBOUNCE_MS after the accepted one. HAL_GetTick() only
     * reads the SysTick counter and does not block.                          */
    uint32_t now = HAL_GetTick();
    if ((now - last_press) < DEBOUNCE_MS)
    {
        return;
    }
    last_press = now;

    if (!blinking)
    {
        blinking = true;
        __HAL_TIM_SET_COUNTER(&htim2, 0U);              /* full first interval  */
        __HAL_TIM_CLEAR_FLAG(&htim2, TIM_FLAG_UPDATE);  /* discard a stale UIF  */
        HAL_TIM_Base_Start_IT(&htim2);
    }
    else
    {
        blinking = false;
        HAL_TIM_Base_Stop_IT(&htim2);
        LED_PORT->ODR &= ~LED_MASK;         /* leave the LED off */
    }
}
/* ---------------- USER CODE END 4 ------------------------ */
```

The `while (1)` loop of `main()` remains empty: all behaviour is driven by the two interrupt service
routines, and both of them execute in a bounded, very short time — one XOR on a register, or one
comparison plus a timer start/stop. No blocking delay is used anywhere.

Two details deserve a note. First, the update event forced in the `USER CODE BEGIN 2` block above
also raises the update flag UIF; the flag is therefore cleared in the button handler immediately
before the timer is started,
which prevents a spurious toggle at the instant of the first press and, at the same time, discards
any flag left behind by `MX_TIM2_Init()`. Second, `HAL_TIM_PeriodElapsedCallback()` and
`HAL_GPIO_EXTI_Callback()` are each shared by every timer and every external line of the project;
the guard at the top of each one identifies the source, and omitting it would make the code respond
to interrupts it does not own.

### 5.5 Answers required by the task

| Item | Value |
| --- | --- |
| Timer | **TIM2**, internal clock source, up-counting, update interrupt enabled |
| Prescaler | **31999** — the row of §5.2 selected by the measured `f_TIMxCLK` of 64 MHz |
| Counter period (ARR) | **2999** |
| Resulting period | (32 000 × 3 000) / (64 × 10⁶) = **1.5000 s** |
| Code | §5.4 |

The calculated period was checked against the board: ten complete on-off cycles were timed with a
stopwatch and took approximately 30 s, i.e. 2 × 1.5 s per cycle as intended.

### 5.6 Figures

> **Figure 5.1** — CubeMX *Clock Configuration* view, with the **APB1 timer clocks** value visible.
> *(screenshot to be inserted)*
>
> **Figure 5.2** — TIM2 *Parameter Settings* showing Prescaler and Counter Period.
> *(screenshot to be inserted)*
>
> **Figure 5.3** — TIM2 *NVIC Settings* with the global interrupt enabled, and the NVIC view with
> EXTI line[15:10] enabled. *(screenshot to be inserted)*
>
> **Figure 5.4** — PC13 configured as External Interrupt Mode with falling-edge trigger.
> *(screenshot to be inserted)*
>
> **Figure 5.5** — Board during operation: LD2 blinking after the first press, and off after the
> second press. *(photographs to be inserted)*

---

## 6. Conclusion

The four tasks cover the three mechanisms by which bare-metal software controls peripherals on an
STM32: bit-masked read–modify–write access to memory-mapped configuration registers, a prescaler
and counter pair that converts a clock into countable time, and interrupts that transfer control at
the instant an event occurs rather than when software next happens to check. The blink toggle of
Task 4 combines all three, and does so without any blocking delay, so the processor remains
available between events — the property that a real-time system depends on.

---

## Appendix A — Corrections applied to the worked examples of the lab handout

Several worked examples in the handout are internally inconsistent. The derivations in this report
follow the corrected arithmetic; the discrepancies are recorded here for completeness.

**A.1 §2.1, register masking example.** The example sets bit 3 and clears bit 5 of an 8-bit register.
Three points do not hold.

*Step 4* is written as `xxxxxxxx | 11010111 = xx0x0xxx`, but OR cannot clear a bit: since
`x | 1 = 1`, that operation yields `11x1x111`. The stated result is the one AND produces, so the
operator, not the result, is what is wrong.

*Step 5* gives `001<<3 = 00000100`, whereas `1 << 3` is `00001000`; `00000100` is `1 << 2`. The
result quoted in step 6, `xx0x1xxx`, again corresponds to the correct mask rather than to the one
printed.

*The two C statements* at the end of the section, `Register &= ~(101<<3)` and
`Register |= (001<<3)`, express the right idea but not in C. `101` and `001` are read by the
compiler as an ordinary decimal constant and an octal constant, not as binary literals, so
`101 << 3` evaluates to 808 — a mask that clears bits 3, 5, 8 and 9 instead of bits 3 and 5.
(`001 << 3` happens to give 8, the intended value, only because octal 001 equals 1.) Written so
that a compiler agrees with the intent, the two lines are

```c
Register &= ~(0x5u << 3);   /* clear bits 5 and 3 */
Register |=  (0x1u << 3);   /* set bit 3          */
```

The section also numbers its steps 1, 2, 4, 5, 6, omitting step 3, and then refers to "6 cycles"
for the five operations actually listed.

**A.2 §3.2, output data register example.** The section demonstrates `ODR` with three statements:
`GPIOA->ODR &= ~(0b1<<5)` to clear the bit, `GPIOA->ODR |= (0b1<<5)` to set it, and
`GPIOA->ODR |= (0b0<<5)` described as the way to clear it again. The third has no effect at all:
`0b0<<5` is zero and `x | 0 = x`, so OR cannot clear a bit — which is the same point already made in
A.1. The correct statement is the first one. (The binary literals `0b1` and `0b0` are also a GCC
extension rather than standard C before C23; `1u` and the shift are enough.)

**A.3 §4.1, timer example (80 MHz, 2.5 s).** The text selects a prescaler of 80, computes
80 MHz / 8000 = 10 kHz, and concludes with a prescaler of 16. Only one of these can be right. The
self-consistent solution is a division ratio of 8 000 and a counter value of 25 000, since
8 000 × 25 000 / (80 × 10⁶) = 2.5 s. The intermediate sentence also refers to 5.5 s rather than 2.5 s.

**A.4 §4.2, timer example (64 MHz, 1 s).** The stated clock is 64 MHz but the arithmetic uses
65 MHz. The division ratio is also quoted twice with different values: the text says "we select the
prescaler to be 65 and put 64 in the configuration", while the configuration list that follows says
`Prescaler = 65000 − 1`. Taking that list at face value on a 64 MHz timer clock,
65 000 × 1 000 / (64 × 10⁶) = 1.0156 s rather than 1 s. A division ratio of 64 000 with a counter
of 1 000 gives exactly 1 s, i.e. `Prescaler = 64000 − 1` and `Counter Period = 1000 − 1`.

**A.5 Table 2, port bit configuration.** The table associates specific `MODE` values with the
push-pull and open-drain rows of the output modes, which would imply that the choice of output type
constrains the output speed. Within output mode the two fields do not constrain each other: `CNF`
selects the electrical type and `MODE` selects the slew rate, in any combination, as Table 3 of the
same handout states. (`MODE` does govern `CNF` in one respect — it decides whether `CNF` is read
against the input table or the output table — but that is a different statement from binding
push-pull to 10 MHz.) In addition, the
input-mode rows of Table 2 give `CNF = 00` for both analog and floating input and `CNF = 11` for
pull-down; RM0008 §9.2.1 specifies `00` analog, `01` floating, `10` input with pull-up/pull-down
(the direction being selected by the corresponding `ODR` bit) and `11` reserved. The configuration
derived in Task 1 uses only the output rows, which are unaffected.
