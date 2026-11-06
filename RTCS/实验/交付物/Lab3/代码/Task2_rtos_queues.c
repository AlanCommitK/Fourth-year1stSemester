/* ============================================================================
 *  Lab 3 / Task 2  (65 marks)  -- Queues, and the memory a task needs
 *  UESTC4019 Real-Time Computing Systems & Architecture
 *
 *  WHAT IT DOES
 *    Two tasks talking through three queues.
 *
 *      task_comm (higher)   receives 11 characters over the UART by interrupt,
 *                           echoes them back unchanged, and if characters
 *                           2..6 spell DELAY it reads characters 8..11 as a
 *                           number and posts it to queue 1.
 *                           It also prints whatever turns up in queues 2 and 3.
 *
 *      task_led  (lower)    toggles the on-board LED at whatever period
 *                           queue 1 last told it.  Every ten toggles it posts
 *                           an incrementing counter to queue 2.  Every time a
 *                           new value arrives on queue 1 it fills a 150-element
 *                           int array with random numbers and posts the largest
 *                           of them to queue 3.
 *
 *    Example: send  -DELAY 1000  and the LED starts toggling once a second.
 *
 *  BOARD
 *    NUCLEO-F103RB.  Nothing to wire up.
 *      LD2    = PA5,  HIGH = lit
 *      USART2 = PA2 (TX) / PA3 (RX), via the ST-LINK virtual COM port
 *
 *  CUBEMX RECIPE
 *     1. New project -> Board Selector -> NUCLEO-F103RB -> initialise all
 *        peripherals: Yes.
 *     2. System Core > SYS > Timebase Source  ->  TIM4        (see Task 1)
 *     3. Middleware and Software Packs > FREERTOS > Interface -> CMSIS_V2
 *     4. Connectivity > USART2 > NVIC Settings
 *              tick "USART2 global interrupt"
 *        Without this HAL_UART_Receive_IT() never calls back, and the manual
 *        explicitly requires the UART data to arrive by interrupt.
 *     5. FREERTOS > Tasks and Queues > Tasks:
 *              rename defaultTask -> task_comm / start_task_comm
 *                                    Priority  osPriorityNormal
 *                                    Stack     256  (words)
 *              Add                -> task_led  / start_task_led
 *                                    Priority  osPriorityBelowNormal
 *                                    Stack     256  (words)   <-- NOT the
 *                                    default 128.  See the note on memory at
 *                                    the bottom of this file; with 128 the
 *                                    board prints one line and then hangs.
 *        FREERTOS > Tasks and Queues > Queues > Add:
 *              q1   Queue Size 2   Item Size 2    (uint16_t, delay in ms)
 *              q2   Queue Size 8   Item Size 2    (uint16_t, toggle counter)
 *              q3   Queue Size 4   Item Size 4    (uint32_t, max of randoms)
 *        Item Size 4 on q3 is not optional -- see the note on queue sizing.
 *
 *  WHERE EACH BLOCK GOES
 *    Each block is labelled with the USER CODE section it belongs in.  Write
 *    only between those markers; anything outside is lost when CubeMX
 *    regenerates the project.
 * ==========================================================================*/


/* -------------------------------------------------------------------------
 *  USER CODE BEGIN Includes
 * -----------------------------------------------------------------------*/
#include <string.h>
#include <stdlib.h>          /* rand(), srand(), RAND_MAX */
/* USER CODE END Includes */


/* -------------------------------------------------------------------------
 *  USER CODE BEGIN PD        (defines)
 * -----------------------------------------------------------------------*/
#define LED_PORT        GPIOA
#define LED_PIN         GPIO_PIN_5

#define FRAME_LEN       11u          /* the manual fixes the frame at 11 chars */
#define SAMPLE_COUNT    150          /* the array the manual asks for          */

#define DELAY_DEFAULT   500u         /* before any command has arrived */
#define DELAY_MIN       1u           /* a period of 0 would spin the CPU */
#define DELAY_MAX       9999u        /* four digits is all the frame carries */
/* USER CODE END PD */


/* -------------------------------------------------------------------------
 *  USER CODE BEGIN PV        (private variables)
 * -----------------------------------------------------------------------*/
/* Double buffer between the UART interrupt and task_comm.
 *
 * rx_dma is the buffer HAL fills.  When a frame completes the callback copies
 * it into rx_frame and raises rx_ready; task_comm consumes rx_frame.
 *
 * Why a flag here and a queue everywhere else: the exercise fixes the number
 * of queues at three, so the ISR-to-task handover has to use something else.
 * A flag is safe in this particular shape -- exactly one writer (the ISR),
 * exactly one reader (the task), the flag is a single byte written
 * atomically, and the payload is fully copied *before* the flag is raised.
 * Neither of the races in the manual's Figure 7 can occur: there is no second
 * writer to overwrite the value, and no reader can see a half-written frame. */
static uint8_t           rx_dma[FRAME_LEN];
static uint8_t           rx_frame[FRAME_LEN];
static volatile uint8_t  rx_ready = 0u;
/* USER CODE END PV */


/* -------------------------------------------------------------------------
 *  USER CODE BEGIN 0         (helper functions and the UART callback)
 * -----------------------------------------------------------------------*/

/* Blocking UART print.  Called only from task_comm, so there is exactly one
 * user of the transmitter and no need to guard it. */
static void uart_print(const char *s)
{
    HAL_UART_Transmit(&huart2, (uint8_t *)s, (uint16_t)strlen(s), HAL_MAX_DELAY);
}

static void uart_write(const uint8_t *p, uint16_t n)
{
    HAL_UART_Transmit(&huart2, (uint8_t *)p, n, HAL_MAX_DELAY);
}

/* Unsigned decimal to string, without pulling in printf.
 *
 * printf and friends are avoided deliberately: newlib's formatted output can
 * use several hundred bytes of stack, which on a task sized in hundreds of
 * bytes is a good way to reproduce the crash this lab is teaching about.
 * Buffer must be at least 11 bytes for a 32-bit value plus the terminator. */
static void u32_to_str(uint32_t v, char *out)
{
    char tmp[11];
    int  n = 0;

    if (v == 0u) {
        out[0] = '0';
        out[1] = '\0';
        return;
    }
    while (v > 0u) {
        tmp[n++] = (char)('0' + (v % 10u));
        v /= 10u;
    }
    for (int i = 0; i < n; ++i) {
        out[i] = tmp[n - 1 - i];        /* reverse */
    }
    out[n] = '\0';
}

/* Print "<label><number><CRLF>". */
static void uart_print_num(const char *label, uint32_t v)
{
    char num[12];
    u32_to_str(v, num);
    uart_print(label);
    uart_print(num);
    uart_print("\r\n");
}

/* Is this frame a DELAY command, and if so what number does it carry?
 *
 * The manual counts characters from 1, C counts from 0.  For "-DELAY 1000":
 *      manual 1      '-'        b[0]
 *      manual 2..6   "DELAY"    b[1]..b[5]
 *      manual 7      ' '        b[6]
 *      manual 8..11  "1000"     b[7]..b[10]
 *
 * Spaces inside the number field are skipped, so "-DELAY  200" also works.
 * Returns 1 and writes *out on success, 0 if this is not a DELAY command or
 * the digits are not digits. */
static int parse_delay(const uint8_t *b, uint16_t *out)
{
    if (memcmp(&b[1], "DELAY", 5) != 0) {
        return 0;
    }

    uint32_t v      = 0u;
    int      digits = 0;

    for (int i = 7; i <= 10; ++i) {
        if (b[i] == ' ') {
            continue;
        }
        if (b[i] < '0' || b[i] > '9') {
            return 0;
        }
        v = v * 10u + (uint32_t)(b[i] - '0');
        ++digits;
    }

    if (digits == 0 || v > DELAY_MAX) {
        return 0;
    }
    *out = (uint16_t)v;
    return 1;
}

/* UART receive-complete callback: HAL has collected FRAME_LEN characters.
 *
 * Two things only, and then re-arm.  No printing and no parsing here -- the
 * transmitter belongs to task_comm, and calling it from an ISR would collide
 * with whatever the task is in the middle of sending.
 *
 * Re-arming is mandatory.  HAL_UART_Receive_IT() is a one-shot request; forget
 * this line and the board accepts exactly one command and then goes deaf. */
void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart)
{
    if (huart->Instance != USART2) {
        return;
    }

    memcpy(rx_frame, rx_dma, FRAME_LEN);
    rx_ready = 1u;                                   /* raised only after the copy */

    (void)HAL_UART_Receive_IT(&huart2, rx_dma, FRAME_LEN);
}
/* USER CODE END 0 */


/* -------------------------------------------------------------------------
 *  HIGHER PRIORITY.  Replace the generated body of start_task_comm with this.
 * -----------------------------------------------------------------------*/
void start_task_comm(void *argument)
{
    /* USER CODE BEGIN start_task_comm */
    uart_print("\r\n[Lab3 Task2] ready. Send 11 characters, e.g. -DELAY 1000\r\n\r\n");

    /* Arm the first receive.  Everything after this is kept going by the
     * re-arm at the end of the callback. */
    (void)HAL_UART_Receive_IT(&huart2, rx_dma, FRAME_LEN);

    for (;;)
    {
        /* ---- a frame arrived ------------------------------------------- */
        if (rx_ready) {
            rx_ready = 0u;

            /* Echo it back exactly as received, then a CRLF of our own so the
             * terminal stays readable.  The 11 characters themselves are
             * untouched. */
            uart_print("echo: ");
            uart_write(rx_frame, FRAME_LEN);
            uart_print("\r\n");

            uint16_t ms;
            if (parse_delay(rx_frame, &ms)) {
                if (osMessageQueuePut(q1Handle, &ms, 0u, 0u) == osOK) {
                    uart_print_num("  -> queue1 delay = ", ms);
                } else {
                    /* q1 is deliberately shallow; a full queue means commands
                     * are arriving faster than the LED task consumes them, and
                     * the newest one is the only one that matters anyway. */
                    uart_print("  -> queue1 full, command dropped\r\n");
                }
            }
        }

        /* ---- anything new on queue 2? ---------------------------------- */
        uint16_t count;
        while (osMessageQueueGet(q2Handle, &count, NULL, 0u) == osOK) {
            uart_print_num("queue2 toggle-group count = ", count);
        }

        /* ---- anything new on queue 3? ---------------------------------- */
        uint32_t biggest;
        while (osMessageQueueGet(q3Handle, &biggest, NULL, 0u) == osOK) {
            uart_print_num("queue3 largest of 150 randoms = ", biggest);
        }

        /* Timeout 0 above means "look, do not wait", so this task would spin
         * without a yield.  10 ms is short enough to feel instant on a serial
         * link and long enough to leave the CPU to task_led. */
        osDelay(10);
    }
    osThreadTerminate(NULL);
    /* USER CODE END start_task_comm */
}


/* -------------------------------------------------------------------------
 *  LOWER PRIORITY.  Replace the generated body of start_task_led with this.
 *
 *  STACK: 256 words.  Not 128.  The array below is 600 bytes on its own.
 * -----------------------------------------------------------------------*/
void start_task_led(void *argument)
{
    /* USER CODE BEGIN start_task_led */
    uint32_t delay_ms = DELAY_DEFAULT;
    uint16_t toggles  = 0u;
    uint16_t counter  = 0u;

    /* Without a seed rand() produces the same sequence after every reset,
     * which makes the queue-3 numbers suspiciously identical across runs.
     * The tick count at start-up is not a good random seed in general, but it
     * is enough to make the demo look like what it is. */
    srand((unsigned int)osKernelGetTickCount());

    for (;;)
    {
        uint16_t   cmd;
        osStatus_t st;

        /* Wait for a new speed command, but no longer than the current
         * half-period.  Using the queue's own timeout as the delay is what
         * makes the LED react to a command immediately instead of after the
         * current period has run out.  A plain osDelay() followed by a
         * zero-timeout get would work too, but would lag by up to delay_ms. */
        st = osMessageQueueGet(q1Handle, &cmd, NULL, delay_ms);

        if (st == osOK) {
            /* --- a new delay arrived --------------------------------- */
            delay_ms = (cmd < DELAY_MIN) ? DELAY_MIN : cmd;

            /* The manual's memory exercise, in its intended place: 150 ints
             * live on this task's stack for the duration of this block.
             *      150 x 4 = 600 bytes
             * The CubeMX default of 128 words is 512 bytes, so this array
             * alone overflows it.  The task stack is set to 256 words. */
            int samples[SAMPLE_COUNT];

            for (int i = 0; i < SAMPLE_COUNT; ++i) {
                samples[i] = rand();
            }

            int largest = samples[0];
            for (int i = 1; i < SAMPLE_COUNT; ++i) {
                if (samples[i] > largest) {
                    largest = samples[i];
                }
            }

            /* 4 bytes wide, because RAND_MAX here is 0x7FFFFFFF -- a 16-bit
             * queue element would silently chop this value in half. */
            uint32_t biggest = (uint32_t)largest;
            (void)osMessageQueuePut(q3Handle, &biggest, 0u, 0u);
        }

        /* --- toggle, whether or not a command just arrived ------------- */
        HAL_GPIO_TogglePin(LED_PORT, LED_PIN);

        if (++toggles >= 10u) {
            toggles = 0u;
            ++counter;
            (void)osMessageQueuePut(q2Handle, &counter, 0u, 0u);
            /* Dropping a counter if q2 is full is harmless: it is a progress
             * indicator, not control data. */
        }
    }
    osThreadTerminate(NULL);
    /* USER CODE END start_task_led */
}


/* ============================================================================
 *  NOTES FOR THE REPORT
 *
 *  --- Size and width of each queue, and why -------------------------------
 *
 *    queue 1   width 2 bytes   depth 2
 *        Carries the delay in milliseconds.  The frame holds four digits, so
 *        the value cannot exceed 9999 and uint16_t is the smallest type that
 *        fits.  The depth is deliberately shallow: this is a command, not a
 *        data stream, and only the most recent one has any meaning.  A deep
 *        queue would make the LED work its way through stale commands while
 *        the user waits.  Two slots allow one command to be in flight while
 *        another is accepted; beyond that, dropping is the correct response
 *        and the code says so on the UART.
 *
 *    queue 2   width 2 bytes   depth 8
 *        Carries a counter that increments once per ten toggles.  Two bytes
 *        covers 65535 groups, which at the shortest useful period is many
 *        hours.  The depth is larger than queue 1's because the producer is
 *        periodic and the consumer is not: task_comm may be in the middle of
 *        a blocking UART write when a counter is posted, so a few slots
 *        absorb that jitter.  Overflow here loses a progress number and
 *        nothing else.
 *
 *    queue 3   width 4 bytes   depth 4
 *        Carries the largest of 150 values from rand().  The width is the
 *        one genuinely forced choice in this table: on this toolchain
 *        RAND_MAX is 0x7FFFFFFF, so values run to about 2.1 billion and a
 *        two-byte element would truncate them to nonsense.  Four bytes it is.
 *        The depth can be small because one value is produced per DELAY
 *        command, which is a human-speed event.
 *
 *    The pattern worth stating in the report: width is decided by the range
 *    of the value, depth by the ratio between how fast it is produced and how
 *    fast it is consumed -- plus what should happen when it overflows.
 *
 *  --- How the 150-element array was accommodated --------------------------
 *
 *        150 ints x 4 bytes = 600 bytes
 *        CubeMX default task stack = 128 words = 512 bytes
 *
 *    600 > 512, so with the default the array does not fit and the task
 *    corrupts whatever is past the end of its stack -- in practice the board
 *    prints its first line and then hangs or resets, exactly the failure the
 *    manual describes in section 3.
 *
 *    The fix used here is to raise task_led's stack to 256 words (1024 bytes)
 *    in the CubeMX task dialog.  Not 150 words: the stack also has to hold
 *    the loop variables, the return addresses of the calls made from inside
 *    the block, and the register context pushed when an interrupt arrives
 *    while this task is running.  Sizing it to exactly the array is a crash
 *    waiting for the first interrupt; a power of two with roughly 400 bytes
 *    of headroom is the usual engineering answer.
 *
 *    The alternative the manual offers is malloc()/free(), which are
 *    thread-safe under CMSIS-RTOS v2, taking the 600 bytes from the FreeRTOS
 *    heap instead of the task stack.  That was not chosen here: the stack
 *    size is fixed at build time and cannot fail at run time, whereas a heap
 *    allocation can fail and, repeated, fragments the heap -- the exact
 *    problem section 3 of the manual warns about.  For a real-time system the
 *    statically bounded option is preferable, which is the same reasoning
 *    behind the manual's remark that heap 1 is used where dynamic allocation
 *    is prohibited.
 *
 *  --- Which task got which priority, and why ------------------------------
 *
 *    task_comm is osPriorityNormal, task_led is osPriorityBelowNormal.
 *
 *    For most of their lives both tasks are blocked -- one on osDelay, the
 *    other on a queue -- and the priorities never come into play.  The one
 *    moment they do is the block that fills and scans the 150-element array:
 *    that is several hundred microseconds of straight computation with no
 *    blocking call in it.  Had task_led been the higher of the two, that
 *    burst would hold off the UART work every time a command arrived.  LED
 *    toggling tolerates a few milliseconds of jitter; a terminal that stops
 *    responding does not look like it is working.  So the computational task
 *    goes below the responsive one.
 *
 *  --- Why the ISR hands over with a flag rather than a queue --------------
 *
 *    The exercise fixes the number of queues at three, so the UART interrupt
 *    cannot have one of its own.  The double-buffer-and-flag used instead is
 *    safe in this specific shape: one writer, one reader, a one-byte flag
 *    written atomically, and the frame copied before the flag goes up.  The
 *    two failure modes in the manual's Figure 7 need either a second writer
 *    or a reader that can observe a partial write, and neither exists here.
 *
 *    The more idiomatic solution is a CMSIS-RTOS v2 thread flag --
 *    osThreadFlagsSet() is callable from an ISR and the task blocks in
 *    osThreadFlagsWait() instead of polling every 10 ms.  That is outside
 *    what this lab covers, so it is mentioned rather than used.
 * ==========================================================================*/
