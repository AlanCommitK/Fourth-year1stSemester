/* ============================================================================
 *  Lab 4 / Task 1  (25 marks)  --  Three tasks sharing one counter
 *  UESTC4014 Real-Time Computing Systems & Architecture
 *
 *  WHAT IT DOES
 *    Three identical tasks each increment one shared counter and print the
 *    new value on the UART.  A mutex makes the read-modify-write
 *    indivisible, so no increment is ever lost.
 *
 *    The handout demonstrates this with two tasks; the exercise is to do
 *    it with three.
 *
 *    Correct output looks like this -- the counter advances by exactly one
 *    on every line, and never repeats:
 *
 *        Task 3: counter = 69
 *        Task 1: counter = 70
 *        Task 2: counter = 71
 *        Task 3: counter = 72
 *
 *    A repeated value means two increments collapsed into one.  A skipped
 *    value means an increment was abandoned.  Both are the failure the
 *    mutex exists to prevent, and neither announces itself any other way.
 *
 *  BOARD
 *    NUCLEO-F103RB.  Nothing to wire up.
 *      USART2 = PA2 (TX) / PA3 (RX), via the ST-LINK virtual COM port
 *      115200-8-N-1.  Transmit only; no receive interrupt is needed.
 *
 *  CUBEMX RECIPE
 *     1. New project -> Board Selector -> NUCLEO-F103RB -> initialise all
 *        peripherals: Yes.
 *     2. System Core > SYS > Timebase Source  ->  TIM4
 *          FreeRTOS takes SysTick for itself.  If HAL keeps SysTick too,
 *          the two fight and the board does nothing at all.
 *     3. Middleware and Software Packs > FREERTOS > Interface -> CMSIS_V2
 *     4. FREERTOS > Config parameters > TOTAL_HEAP_SIZE  ->  8192
 *          Three 256-word stacks are 3072 bytes on their own, before the
 *          three TCBs, the idle task and the timer service task.  The
 *          3072-byte default cannot hold them, and when it runs out
 *          osThreadNew() returns NULL and that task simply never exists:
 *          one task is silent from the first second while the others look
 *          perfectly normal.  See the NULL check further down.
 *     5. FREERTOS > Tasks and Queues > Tasks:
 *              rename defaultTask -> counterTask1 / StartCounterTask1
 *              Add                -> counterTask2 / StartCounterTask2
 *              Add                -> counterTask3 / StartCounterTask3
 *          All three:  Priority  osPriorityNormal
 *                      Stack     256  (words)
 *
 *          The three priorities are deliberately EQUAL.  This exercise is
 *          about mutual exclusion, not about scheduling: equal priorities
 *          keep the three tasks symmetric, so none of them can monopolise
 *          the mutex by always being chosen first.
 *
 *     6. FREERTOS > Mutexes > Add:
 *              myMutex01        (dynamic allocation)
 *          This is the page shown as Figure 1 in the handout.
 *
 *  WHERE EACH BLOCK GOES
 *    Everything below is marked with the USER CODE section it belongs in.
 *    Write only inside those markers -- anything outside them is thrown
 *    away the next time CubeMX regenerates the project.
 * ==========================================================================*/


/* -------------------------------------------------------------------------
 *  USER CODE BEGIN Includes
 * -----------------------------------------------------------------------*/
#include <stdio.h>
/* USER CODE END Includes */


/* -------------------------------------------------------------------------
 *  USER CODE BEGIN PV        (private variables)
 * -----------------------------------------------------------------------*/
/* The one piece of state all three tasks share.  Every access to it
 * happens with myMutex01 held. */
static uint32_t sharedCounter;
/* USER CODE END PV */


/* -------------------------------------------------------------------------
 *  USER CODE BEGIN RTOS_THREADS
 *
 *  Goes in MX_FREERTOS_Init(), after the generated creation calls.
 *
 *  Why bother: when the heap is exhausted, osMutexNew() and osThreadNew()
 *  do not crash and do not warn.  They return NULL, and the object simply
 *  does not exist.  Three lines here turn an evening of confusion into an
 *  explicit stop.
 * -----------------------------------------------------------------------*/
  if (myMutex01Handle      == NULL ||
      counterTask1Handle   == NULL ||
      counterTask2Handle   == NULL ||
      counterTask3Handle   == NULL)
  {
    Error_Handler();
  }
/* USER CODE END RTOS_THREADS */


/* -------------------------------------------------------------------------
 *  USER CODE BEGIN 4         (the shared task body)
 *
 *  The three tasks are identical apart from the number they report and the
 *  offset they start at, so the body is written once and parameterised.
 *  Copying it three times is how one of the three ends up subtly different
 *  after an edit.
 * -----------------------------------------------------------------------*/
static void RunCounterTask(unsigned int taskNumber, uint32_t initialDelay)
{
  /* Stagger the three tasks so they do not all arrive at the mutex at the
   * same instant on the first pass.  With a 750 ms period and offsets of
   * 0 / 250 / 500 ms, one task reaches the mutex every 250 ms in steady
   * state and normally finds it free.
   *
   * NOTE for the report: the stagger only makes the OUTPUT tidy.  The
   * correctness guarantee comes from the mutex, not from the timing. */
  if (initialDelay != 0U)
  {
    osDelay(initialDelay);
  }

  for (;;)
  {
    /* Wait for the mutex rather than testing for it.
     *
     * The handout's own example passes a timeout of 0 and increments only
     * if the call succeeded -- "it simply skips" otherwise.  That silently
     * abandons work: the task was supposed to increment and did not, which
     * is the same lost-update symptom the mutex was introduced to prevent.
     * Waiting costs nothing, because a task blocked on a mutex is off the
     * ready list and consumes no processor time. */
    if (osMutexAcquire(myMutex01Handle, osWaitForever) != osOK)
    {
      Error_Handler();
    }

    /* ---- critical section begins ------------------------------------ */

    /* This is the operation that must not be split.  It is a read, an
     * addition and a write; without the mutex a task switch between the
     * read and the write lets another task's increment be overwritten. */
    ++sharedCounter;

    char line[48];
    int  length = snprintf(line, sizeof line, "Task %u: counter = %lu\r\n",
                           taskNumber, (unsigned long)sharedCounter);

    HAL_StatusTypeDef uartStatus = HAL_ERROR;

    /* The transmit is kept INSIDE the lock.  This is a trade, and both
     * sides are worth knowing:
     *   - against: the lock is held across a blocking send, roughly 2 ms
     *     for a 23-character line at 115200 baud, during which neither of
     *     the other two tasks can enter.
     *   - for: the counter value and the line reporting it cannot be
     *     separated.  Release immediately after the increment and another
     *     task may print first, so the output shows values out of order
     *     even though the counter itself was never corrupted.
     * Since the output is the evidence for this exercise, ordering wins.
     * On a real deadline the answer would be the opposite: format under
     * the lock, release, then transmit. */
    if (length > 0 && (size_t)length < sizeof line)
    {
      uartStatus = HAL_UART_Transmit(&huart2, (uint8_t *)line,
                                     (uint16_t)length, 20U);
    }

    /* Single exit point.  There is no early return anywhere above, so the
     * mutex is always released exactly once on every path through the
     * loop -- the usual way to deadlock this kind of code is a `return`
     * or `break` that skips the release. */
    if (osMutexRelease(myMutex01Handle) != osOK || uartStatus != HAL_OK)
    {
      Error_Handler();
    }

    /* ---- critical section ends -------------------------------------- */

    /* Yield OUTSIDE the critical section.  Delaying while holding the
     * mutex would block the other two tasks for the full 750 ms and
     * defeat the point of the exercise. */
    osDelay(750U);
  }
}
/* USER CODE END 4 */


/* -------------------------------------------------------------------------
 *  The three entry functions.  Replace the generated bodies with these.
 * -----------------------------------------------------------------------*/
void StartCounterTask1(void *argument)
{
  /* USER CODE BEGIN 5 */
  (void)argument;
  RunCounterTask(1U, 0U);      /* no offset   */
  /* USER CODE END 5 */
}

void StartCounterTask2(void *argument)
{
  /* USER CODE BEGIN StartCounterTask2 */
  (void)argument;
  RunCounterTask(2U, 250U);    /* 250 ms late */
  /* USER CODE END StartCounterTask2 */
}

void StartCounterTask3(void *argument)
{
  /* USER CODE BEGIN StartCounterTask3 */
  (void)argument;
  RunCounterTask(3U, 500U);    /* 500 ms late */
  /* USER CODE END StartCounterTask3 */
}


/* ============================================================================
 *  NOTES FOR THE REPORT
 *
 *  What the output proves, and what it does not
 *      Two separate claims, and they should be made separately:
 *        - "the counter advances by exactly one per line, with nothing
 *          skipped and nothing repeated" is the evidence that no increment
 *          was lost.  This is what the mutex provides.
 *        - "the task numbers rotate in a fixed order" follows from the
 *          250 ms stagger and the equal 750 ms periods.  It is a property
 *          of the timing and would change if the delays changed; the first
 *          claim would not.
 *
 *  The control experiment
 *      Removing the osMutexAcquire / osMutexRelease pair and rebuilding is
 *      the natural comparison.  The counter still advances and the output
 *      still looks plausible; what changes is that gaps appear under
 *      contention.  That is the whole argument for the mutex -- the
 *      failure it prevents is one that does not announce itself.
 *
 *  Why all three tasks are at the same priority
 *      The exercise is about mutual exclusion, not scheduling.  Equal
 *      priorities make the three genuinely symmetric and let the output
 *      settle into a readable rotation.  Unequal priorities would have the
 *      highest task take the mutex first almost every time, which hides
 *      the behaviour being demonstrated rather than showing it.
 *
 *  Why osWaitForever and not a zero timeout
 *      See the comment at the acquire.  A zero timeout converts the call
 *      into a test, and the natural thing to write next is an `if` that
 *      skips the increment -- which loses work.  The protection against
 *      corruption survives either way; the protection against lost work
 *      does not.
 * ==========================================================================*/
