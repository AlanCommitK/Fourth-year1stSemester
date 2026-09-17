/*==============================================================================
 * Lab 2 - Task 1        UART: three 2-digit numbers, then add or multiply
 *
 * Board : NUCLEO-F103RB.  USART2 is wired to the ST-LINK virtual COM port, so
 *         the only cable needed is the USB cable that already programs the board.
 *
 * CUBEMX SETUP (project "Lab2_Task1")  -- no Arduino, no breadboard
 *   1. Connectivity > USART2 > Mode = Asynchronous
 *   2. USART2 > Parameter Settings : Baud Rate = 9600, Word Length = 8 Bits,
 *      Parity = None, Stop Bits = 1            (handout section 1.3, Figure 5)
 *   3. USART2 > NVIC Settings : enable "USART2 global interrupt"
 *   4. Ctrl+S to regenerate.
 *   Open the serial terminal at the SAME 9600 baud, or everything is garbage.
 *
 * WHY INTERRUPT RECEIVE AND NOT A FIXED-LENGTH READ
 *   The handout demonstrates HAL_UART_Receive_IT(&huart2, rx_data, 9), i.e. it
 *   waits for exactly nine bytes. That cannot express "type a number, press
 *   Enter", because the number of bytes is not known in advance. This program
 *   therefore receives ONE byte per interrupt and assembles a line until the
 *   terminal sends CR or LF. The length of the input then does not matter, and
 *   the same routine serves all four prompts.
 *
 * ISR DISCIPLINE (carried over from Lab 1)
 *   The callback does the minimum: store one character, re-arm the receiver,
 *   raise a flag. Parsing, arithmetic and printing all happen in the main loop,
 *   where they are allowed to take time.
 *
 * This file is a set of snippets, not a compilable translation unit. Each block
 * is bracketed by the CubeMX markers that say where it goes in main.c.
 *============================================================================*/


/* USER CODE BEGIN Includes */
#include <stdio.h>      /* sprintf                      */
#include <string.h>     /* strlen                       */
#include <stdbool.h>    /* bool - not automatic in CubeIDE */
/* USER CODE END Includes */


/* USER CODE BEGIN PD */
#define LINE_MAX   16U          /* longest input line we accept, incl. '\0' */
#define OUT_MAX    96U          /* scratch buffer for sprintf               */
/* USER CODE END PD */


/* USER CODE BEGIN PV */
static volatile uint8_t rx_byte;              /* one byte per interrupt      */
static volatile char    line[LINE_MAX];       /* line being assembled        */
static volatile uint8_t line_len   = 0U;
static volatile bool    line_ready = false;   /* a complete line is waiting  */

static char out[OUT_MAX];                     /* main-loop only, not shared  */
/* USER CODE END PV */


/* -----------------------------------------------------------------------------
 * Section 0 : small helpers, placed before main() so main() can call them.
 * ---------------------------------------------------------------------------*/

/* USER CODE BEGIN 0 */

/* Blocking send of a C string. Blocking is fine here: it runs in the main
 * loop, never in an interrupt.                                              */
static void uart_print(const char *s)
{
    HAL_UART_Transmit(&huart2, (uint8_t *)s, (uint16_t)strlen(s), HAL_MAX_DELAY);
}

/* Accept exactly two decimal digits, i.e. 10 to 99.
 * Returns true and writes *value on success; false on any malformed input.  */
static bool parse_two_digits(const char *s, uint8_t *value)
{
    if (s[0] < '0' || s[0] > '9') { return false; }
    if (s[1] < '0' || s[1] > '9') { return false; }
    if (s[2] != '\0')             { return false; }   /* nothing after them  */

    uint8_t v = (uint8_t)((s[0] - '0') * 10 + (s[1] - '0'));
    if (v < 10U) { return false; }                    /* "05" is not 2-digit */
    *value = v;
    return true;
}

/* USER CODE END 0 */


/* -----------------------------------------------------------------------------
 * Section 2 : runs once, after the MX_xxx_Init() calls.
 * ---------------------------------------------------------------------------*/

/* USER CODE BEGIN 2 */

    uart_print("\r\n=== UESTC 4014 RTCSA - Lab 2 Task 1 ===\r\n");
    uart_print("Enter three 2-digit numbers (10 to 99), then choose the operation.\r\n\r\n");
    uart_print("Number 1 : ");

    /* Arm the receiver for the first character. From here on the callback
     * re-arms it after every byte, so reception never stops.                */
    HAL_UART_Receive_IT(&huart2, (uint8_t *)&rx_byte, 1U);

/* USER CODE END 2 */


/* -----------------------------------------------------------------------------
 * Section 3 : the body of while(1).
 * ---------------------------------------------------------------------------*/

/* USER CODE BEGIN 3 */

    static uint8_t step = 0U;       /* 0,1,2 = numbers ; 3 = operation      */
    static uint8_t num[3] = {0U};

    if (line_ready)
    {
        /* Echo what was received, so the transcript in the screenshot is
         * readable even when the terminal has local echo switched off.     */
        sprintf(out, "%s\r\n", (const char *)line);
        uart_print(out);

        if (step < 3U)                       /* ---- expecting a number ---- */
        {
            uint8_t v;
            if (parse_two_digits((const char *)line, &v))
            {
                num[step] = v;
                step++;
                if (step < 3U)
                {
                    sprintf(out, "Number %u : ", (unsigned)(step + 1U));
                    uart_print(out);
                }
                else
                {
                    uart_print("Add or multiply them? (a / m) : ");
                }
            }
            else
            {
                sprintf(out, "  not a 2-digit number. Number %u : ",
                        (unsigned)(step + 1U));
                uart_print(out);
            }
        }
        else                                 /* ---- expecting the operator - */
        {
            char op = line[0];
            if ((op == 'a' || op == 'A') && line[1] == '\0')
            {
                uint32_t sum = (uint32_t)num[0] + num[1] + num[2];
                sprintf(out, "\r\n  %u + %u + %u = %lu\r\n\r\n",
                        (unsigned)num[0], (unsigned)num[1], (unsigned)num[2],
                        (unsigned long)sum);
                uart_print(out);
            }
            else if ((op == 'm' || op == 'M') && line[1] == '\0')
            {
                uint32_t prod = (uint32_t)num[0] * num[1] * num[2];
                sprintf(out, "\r\n  %u x %u x %u = %lu\r\n\r\n",
                        (unsigned)num[0], (unsigned)num[1], (unsigned)num[2],
                        (unsigned long)prod);
                uart_print(out);
            }
            else
            {
                uart_print("  type 'a' or 'm' : ");
                line_len = 0U;
                line_ready = false;
                continue;               /* stay in this step, ask again     */
            }

            /* Start over so the demonstration can be repeated on camera.   */
            step = 0U;
            uart_print("Number 1 : ");
        }

        /* Release the buffer for the next line. Order matters: clear the
         * length first, then the flag, because the callback only starts
         * writing again once line_ready is false.                          */
        line_len   = 0U;
        line_ready = false;
    }

/* USER CODE END 3 */


/* -----------------------------------------------------------------------------
 * Section 4 : the receive-complete callback, at the end of main.c.
 * ---------------------------------------------------------------------------*/

/* USER CODE BEGIN 4 */

void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart)
{
    /* One callback is shared by every UART of the project. */
    if (huart->Instance != USART2)
    {
        return;
    }

    char c = (char)rx_byte;

    /* While the main loop still owns the previous line, drop what arrives:
     * without this the two sides would write to the buffer at once.        */
    if (!line_ready)
    {
        if (c == '\r' || c == '\n')
        {
            if (line_len > 0U)                 /* ignore an empty Enter     */
            {
                line[line_len] = '\0';
                line_ready = true;
            }
        }
        else if (c == '\b' || c == 0x7F)       /* backspace / delete        */
        {
            if (line_len > 0U) { line_len--; }
        }
        else if (line_len < (LINE_MAX - 1U))
        {
            line[line_len++] = c;
        }
        /* longer than LINE_MAX-1: the extra characters are discarded, which
         * keeps the buffer safe and shows up as a rejected input.          */
    }

    /* Re-arm for the next byte. Forgetting this line is the single most
     * common reason "it only receives one character".                      */
    HAL_UART_Receive_IT(huart, (uint8_t *)&rx_byte, 1U);
}

/* The receive interrupt is switched off by the HAL whenever a UART error is
 * latched - most often OVERRUN, which happens if a byte arrives while the
 * previous one has not been read out. Without this callback the program would
 * simply stop receiving and look as if the board had hung. Clearing the flags
 * and re-arming puts it back to work.                                        */
void HAL_UART_ErrorCallback(UART_HandleTypeDef *huart)
{
    if (huart->Instance != USART2)
    {
        return;
    }

    __HAL_UART_CLEAR_OREFLAG(huart);
    __HAL_UART_CLEAR_NEFLAG(huart);
    __HAL_UART_CLEAR_FEFLAG(huart);
    __HAL_UART_CLEAR_PEFLAG(huart);
    huart->ErrorCode = HAL_UART_ERROR_NONE;

    line_len   = 0U;
    line_ready = false;
    HAL_UART_Receive_IT(huart, (uint8_t *)&rx_byte, 1U);
}

/* USER CODE END 4 */


/*==============================================================================
 * EXPECTED TRANSCRIPT  (this is what the two screenshots should show)
 *
 *   === UESTC 4014 RTCSA - Lab 2 Task 1 ===
 *   Enter three 2-digit numbers (10 to 99), then choose the operation.
 *
 *   Number 1 : 12
 *   Number 2 : 34
 *   Number 3 : 56
 *   Add or multiply them? (a / m) : a
 *
 *     12 + 34 + 56 = 102
 *
 *   Number 1 : 12
 *   Number 2 : 34
 *   Number 3 : 56
 *   Add or multiply them? (a / m) : m
 *
 *     12 x 34 x 56 = 22848
 *
 * Largest values that can occur: 99 + 99 + 99 = 297 and 99 x 99 x 99 = 970 299,
 * both well inside uint32_t, so no overflow check is needed.
 *
 * IF NOTHING APPEARS, OR ONLY GARBAGE
 *   - terminal baud rate must be 9600, the same as CubeMX. The factory setting
 *     of the ST-LINK port is 115200, so it has to be changed by hand.
 *   - the terminal must send CR or LF when Enter is pressed. In PuTTY and in
 *     the CubeIDE console this is the default; in some tools it has to be
 *     switched on ("append CR/LF on send").
 * IF ONLY THE FIRST CHARACTER IS EVER RECEIVED
 *   - HAL_UART_Receive_IT() at the end of the callback was not pasted.
 *============================================================================*/
