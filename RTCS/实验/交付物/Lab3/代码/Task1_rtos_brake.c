/* ============================================================================
 *  Lab 3 / Task 1  (35 marks)  -- Tasks and task priorities
 *  UESTC4019 Real-Time Computing Systems & Architecture
 *
 *  WHAT IT DOES
 *    The blue user button is the "slow down" signal from the collision
 *    predictor.  Pressing it applies the brake: the on-board LED (the brake
 *    light) comes on for 1.5 s, and a message is printed on the UART saying
 *    the car is slowing down.
 *
 *    Two tasks, as the manual requires:
 *      task_brake    osPriorityAboveNormal   drives the brake light
 *      task_message  osPriorityNormal        prints the message
 *
 *    The braking task is the higher of the two.  The reason is the severity
 *    of being late, not the amount of work: a late brake can kill someone,
 *    a late status message cannot.
 *
 *  BOARD
 *    NUCLEO-F103RB.  Nothing to wire up -- everything used here is on board.
 *      B1  (user button) = PC13, externally pulled up, pressed = LOW
 *      LD2 (user LED)    = PA5,  HIGH = lit
 *      USART2            = PA2 (TX) / PA3 (RX), via the ST-LINK virtual COM port
 *
 *  CUBEMX RECIPE
 *     1. New project -> Board Selector -> NUCLEO-F103RB -> initialise all
 *        peripherals: Yes.
 *     2. System Core > SYS > Timebase Source  ->  TIM4
 *          FreeRTOS takes SysTick for itself.  If HAL keeps SysTick too, the
 *          two fight and the board does nothing at all.  This is the single
 *          most common way to lose an afternoon on this lab.
 *     3. Middleware and Software Packs > FREERTOS > Interface -> CMSIS_V2
 *     4. Pinout view: PC13 -> GPIO_EXTI13
 *        System Core > GPIO > PC13:
 *              GPIO mode : External Interrupt Mode with Falling edge trigger
 *              Pull      : No pull-up and no pull-down
 *                          (the Nucleo board already has an external pull-up)
 *        System Core > NVIC: tick "EXTI line[15:10] interrupts"
 *              Lines 10..15 share one vector, which is why the entry is named
 *              for a range rather than for EXTI13 alone.
 *     5. FREERTOS > Tasks and Queues > Tasks:
 *              rename defaultTask  -> task_brake    / start_task_brake
 *                                     Priority  osPriorityAboveNormal
 *                                     Stack     128  (words)
 *              Add                 -> task_message  / start_task_message
 *                                     Priority  osPriorityNormal
 *                                     Stack     256  (words)
 *        FREERTOS > Tasks and Queues > Queues > Add:
 *              brakeQ   Queue Size 2   Item Size 1   (uint8_t)
 *              msgQ     Queue Size 4   Item Size 1   (uint8_t)
 *
 *  WHERE EACH BLOCK GOES
 *    Everything below is marked with the USER CODE section it belongs in.
 *    Write only inside those markers -- anything outside them is thrown away
 *    the next time CubeMX regenerates the project.
 * ==========================================================================*/


/* -------------------------------------------------------------------------
 *  USER CODE BEGIN Includes
 * -----------------------------------------------------------------------*/
#include <string.h>
/* USER CODE END Includes */


/* -------------------------------------------------------------------------
 *  USER CODE BEGIN PD        (defines)
 * -----------------------------------------------------------------------*/
#define LED_PORT        GPIOA
#define LED_PIN         GPIO_PIN_5
#define BTN_PIN         GPIO_PIN_13      /* PC13, as seen by the EXTI callback */

#define BRAKE_HOLD_MS   1500u            /* how long the brake light stays on */
#define DEBOUNCE_MS     200u             /* ignore edges closer than this     */
/* USER CODE END PD */


/* -------------------------------------------------------------------------
 *  USER CODE BEGIN PV        (private variables)
 * -----------------------------------------------------------------------*/
/* Last accepted button edge, in RTOS ticks (1 tick = 1 ms by default).
 * Written only by the EXTI callback, read only by the EXTI callback. */
static volatile uint32_t last_edge_tick = 0u;
/* USER CODE END PV */


/* -------------------------------------------------------------------------
 *  USER CODE BEGIN 0         (helper functions)
 * -----------------------------------------------------------------------*/

/* Blocking UART print.  Only ever called from task_message, so there is no
 * contention on the peripheral.  HAL_MAX_DELAY is fine here: the UART is the
 * low-priority task's own business, and blocking it is exactly what we want
 * -- a blocked task costs nothing, and the brake task can preempt it. */
static void uart_print(const char *s)
{
    HAL_UART_Transmit(&huart2, (uint8_t *)s, (uint16_t)strlen(s), HAL_MAX_DELAY);
}

/* External interrupt: falling edge on PC13, i.e. the user button was pressed.
 *
 * The handler does as little as possible -- debounce, then hand the event to
 * a task.  Two reasons:
 *   - the usual one: an ISR runs with interrupts disabled or at high priority,
 *     so long ISRs wreck the timing of everything else;
 *   - the one specific to this exercise: if the LED and the printing were both
 *     done here, there would be no "two tasks" to speak of and nothing for the
 *     priorities to demonstrate.
 *
 * osMessageQueuePut() is callable from an ISR *only* with timeout == 0.
 * A non-zero timeout would mean "block", and an ISR has nothing to block on. */
void HAL_GPIO_EXTI_Callback(uint16_t GPIO_Pin)
{
    if (GPIO_Pin != BTN_PIN) {
        return;                          /* some other line on this vector */
    }

    uint32_t now = osKernelGetTickCount();

    /* Contact bounce produces a burst of edges over ~10 ms.  Anything closer
     * than DEBOUNCE_MS to the previous accepted edge is the same press. */
    if ((now - last_edge_tick) < DEBOUNCE_MS) {
        return;
    }
    last_edge_tick = now;

    uint8_t ev = 1u;
    (void)osMessageQueuePut(brakeQHandle, &ev, 0u, 0u);
    /* Return value ignored on purpose: if the queue is full the driver is
     * pressing faster than the car can brake, and dropping the extra press
     * is the right behaviour. */
}
/* USER CODE END 0 */


/* -------------------------------------------------------------------------
 *  USER CODE BEGIN Header_start_task_brake   /   the task body itself
 *
 *  HIGH PRIORITY.  Replace the generated body of start_task_brake with this.
 * -----------------------------------------------------------------------*/
void start_task_brake(void *argument)
{
    /* USER CODE BEGIN start_task_brake */
    uint8_t ev;

    for (;;)
    {
        /* Block until the ISR reports a press.  While blocked this task is
         * not on the ready list at all, so being the highest-priority task
         * costs the system nothing. */
        if (osMessageQueueGet(brakeQHandle, &ev, NULL, osWaitForever) == osOK)
        {
            /* Brake light on.  This is the time-critical action, and it
             * happens before anything is printed. */
            HAL_GPIO_WritePin(LED_PORT, LED_PIN, GPIO_PIN_SET);

            /* Tell the message task.  Non-blocking: if its queue is backed up
             * we would rather drop a message than delay the brake. */
            uint8_t msg = 1u;
            (void)osMessageQueuePut(msgQHandle, &msg, 0u, 0u);

            /* Hold the brake, then release.  osDelay() blocks this task and
             * hands the CPU to task_message -- which is how the message gets
             * printed while the light is on. */
            osDelay(BRAKE_HOLD_MS);
            HAL_GPIO_WritePin(LED_PORT, LED_PIN, GPIO_PIN_RESET);
        }
    }
    /* Never reached, but the manual asks for a graceful exit in case the
     * forever loop is ever broken by accident. */
    osThreadTerminate(NULL);
    /* USER CODE END start_task_brake */
}


/* -------------------------------------------------------------------------
 *  LOW PRIORITY.  Replace the generated body of start_task_message with this.
 * -----------------------------------------------------------------------*/
void start_task_message(void *argument)
{
    /* USER CODE BEGIN start_task_message */
    uint8_t msg;

    uart_print("\r\n[Lab3 Task1] brake-by-wire demo ready.\r\n"
               "Press the blue button (B1) to send the slow-down signal.\r\n\r\n");

    for (;;)
    {
        if (osMessageQueueGet(msgQHandle, &msg, NULL, osWaitForever) == osOK)
        {
            /* Deliberately long, so that the preemption is visible: press the
             * button again while this is still going out at 115200 baud and
             * the LED lights immediately, in the middle of the line. */
            uart_print("*** COLLISION PREDICTED -- the car is slowing down, "
                       "brake applied, brake light ON ***\r\n");
        }
    }
    osThreadTerminate(NULL);
    /* USER CODE END start_task_message */
}


/* ============================================================================
 *  NOTES FOR THE REPORT
 *
 *  Which priority went to which task, and why
 *      task_brake is osPriorityAboveNormal, task_message is osPriorityNormal.
 *      The ordering follows the consequence of being late, not the size of
 *      the job.  Applying the brake is the action that prevents the crash;
 *      the UART line only tells a human what already happened.  If the
 *      system is ever loaded enough that one of them has to wait, it must be
 *      the message.
 *
 *      This is observable rather than theoretical.  HAL_UART_Transmit() is
 *      blocking, and the banner above takes roughly
 *          85 characters x 10 bits / 115200 baud  ~=  7.4 ms
 *      to go out.  Press the button during that window: because preemption is
 *      enabled (CubeMX default) and task_brake is higher, the scheduler stops
 *      task_message mid-line, runs task_brake, and the LED comes on before the
 *      rest of the line is sent.  With the priorities swapped, the brake would
 *      have to wait those 7.4 ms.
 *
 *  Why osDelay() and not HAL_Delay()
 *      HAL_Delay() spins on the HAL tick.  The task stays in the ready state
 *      the whole time, so every task of equal or lower priority is starved for
 *      the full delay -- here, that would mean the message never printed while
 *      the brake light was on.  osDelay() moves the task to the blocked state
 *      and the scheduler runs somebody else.  The manual makes the same point
 *      in section 2.
 *
 *  Why a queue rather than a global flag
 *      For a single-bit event with one writer and one reader, a volatile flag
 *      would also be correct -- none of the races in the manual's Figure 7
 *      apply.  The queue is better for a different reason: it lets the
 *      consumer block with osWaitForever instead of polling.  A polling task
 *      has to be scheduled over and over to find nothing; a blocked task is
 *      not on the ready list at all and costs zero CPU.
 *
 *  Why the ISR only posts
 *      Debounce and one queue post, nothing else.  Beyond the usual rule that
 *      ISRs must be short, doing the work in the handler would collapse the
 *      two tasks into one and leave nothing for the priorities to act on.
 *      Note the timeout of 0 in the ISR -- osMessageQueuePut() may be called
 *      from interrupt context only when it is not allowed to block.
 * ==========================================================================*/
