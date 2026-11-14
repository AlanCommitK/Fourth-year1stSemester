/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2026 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */
/* Includes ------------------------------------------------------------------*/
#include "main.h"
#include "cmsis_os.h"
/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */

#include "FreeRTOS.h"
#include "task.h"

#include <stdint.h>
#include <stdio.h>
#include <string.h>

/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */

#define FRAME_LENGTH  11U
#define RX_FRAME_SLOTS 4U

/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
UART_HandleTypeDef huart2;

/* Definitions for uartTask */
osThreadId_t uartTaskHandle;
const osThreadAttr_t uartTask_attributes = {
  .name = "uartTask",
  .stack_size = 512 * 4,
  .priority = (osPriority_t) osPriorityNormal,
};
/* Definitions for ledTask */
osThreadId_t ledTaskHandle;
const osThreadAttr_t ledTask_attributes = {
  .name = "ledTask",
  .stack_size = 512 * 4,
  .priority = (osPriority_t) osPriorityAboveNormal,
};
/* Definitions for commandQueue */
osMessageQueueId_t commandQueueHandle;
const osMessageQueueAttr_t commandQueue_attributes = {
  .name = "commandQueue"
};
/* Definitions for countQueue */
osMessageQueueId_t countQueueHandle;
const osMessageQueueAttr_t countQueue_attributes = {
  .name = "countQueue"
};
/* Definitions for maxQueue */
osMessageQueueId_t maxQueueHandle;
const osMessageQueueAttr_t maxQueue_attributes = {
  .name = "maxQueue"
};
/* USER CODE BEGIN PV */

/* HAL 中断接收缓冲区。 */
static uint8_t irqRxFrame[FRAME_LENGTH];

/* 缓存最多 4 帧完整命令。 */
static uint8_t rxFrames[RX_FRAME_SLOTS][FRAME_LENGTH];

/* 接收缓存的读位置、写位置和已有帧数。 */
static volatile uint32_t rxRead = 0U;
static volatile uint32_t rxWrite = 0U;
static volatile uint32_t rxCount = 0U;

/* 诊断计数。 */
static volatile uint32_t rxDropped = 0U;
static volatile uint32_t rxRearmErrors = 0U;

static volatile uint32_t countQueueDropped = 0U;
static volatile uint32_t maxQueueDropped = 0U;

/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_USART2_UART_Init(void);
void StartUartTask(void *argument);
void StartLedTask(void *argument);

/* USER CODE BEGIN PFP */

/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */

/* 毫秒换算为 RTOS tick，至少返回 1 tick。 */
static uint32_t MsToTicks(uint32_t ms)
{
    uint32_t ticks =
        (ms * osKernelGetTickFreq() + 999U) / 1000U;

    return (ticks > 0U) ? ticks : 1U;
}

/* 通过 USART2 发送字符串。 */
static void UART_Print(const char *text)
{
    HAL_UART_Transmit(&huart2,
                      (uint8_t *)text,
                      (uint16_t)strlen(text),
                      100U);
}

/* 从接收缓存中取出一帧。 */
static uint8_t PopRxFrame(uint8_t *destination)
{
    uint8_t available = 0U;

    taskENTER_CRITICAL();

    if (rxCount > 0U)
    {
        memcpy(destination,
               rxFrames[rxRead],
               FRAME_LENGTH);

        rxRead = (rxRead + 1U) % RX_FRAME_SLOTS;
        rxCount--;

        available = 1U;
    }

    taskEXIT_CRITICAL();

    return available;
}


/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{

  /* USER CODE BEGIN 1 */

  /* USER CODE END 1 */

  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_USART2_UART_Init();
  /* USER CODE BEGIN 2 */

  /* USER CODE END 2 */

  /* Init scheduler */
  osKernelInitialize();

  /* USER CODE BEGIN RTOS_MUTEX */
  /* add mutexes, ... */
  /* USER CODE END RTOS_MUTEX */

  /* USER CODE BEGIN RTOS_SEMAPHORES */
  /* add semaphores, ... */
  /* USER CODE END RTOS_SEMAPHORES */

  /* USER CODE BEGIN RTOS_TIMERS */
  /* start timers, add new ones, ... */
  /* USER CODE END RTOS_TIMERS */

  /* Create the queue(s) */
  /* creation of commandQueue */
  commandQueueHandle = osMessageQueueNew (8, sizeof(uint16_t), &commandQueue_attributes);

  /* creation of countQueue */
  countQueueHandle = osMessageQueueNew (8, sizeof(uint32_t), &countQueue_attributes);

  /* creation of maxQueue */
  maxQueueHandle = osMessageQueueNew (8, sizeof(int32_t), &maxQueue_attributes);

  /* USER CODE BEGIN RTOS_QUEUES */
  /* add queues, ... */
  /* USER CODE END RTOS_QUEUES */

  /* Create the thread(s) */
  /* creation of uartTask */
  uartTaskHandle = osThreadNew(StartUartTask, NULL, &uartTask_attributes);

  /* creation of ledTask */
  ledTaskHandle = osThreadNew(StartLedTask, NULL, &ledTask_attributes);

  /* USER CODE BEGIN RTOS_THREADS */
  /* add threads, ... */
  /* USER CODE END RTOS_THREADS */

  /* USER CODE BEGIN RTOS_EVENTS */
  /* add events, ... */
  /* USER CODE END RTOS_EVENTS */

  /* Start scheduler */
  osKernelStart();

  /* We should never get here as control is now taken by the scheduler */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1)
  {
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
  }
  /* USER CODE END 3 */
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
  RCC_OscInitStruct.HSIState = RCC_HSI_ON;
  RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSI_DIV2;
  RCC_OscInitStruct.PLL.PLLMUL = RCC_PLL_MUL16;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV2;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_2) != HAL_OK)
  {
    Error_Handler();
  }
}

/**
  * @brief USART2 Initialization Function
  * @param None
  * @retval None
  */
static void MX_USART2_UART_Init(void)
{

  /* USER CODE BEGIN USART2_Init 0 */

  /* USER CODE END USART2_Init 0 */

  /* USER CODE BEGIN USART2_Init 1 */

  /* USER CODE END USART2_Init 1 */
  huart2.Instance = USART2;
  huart2.Init.BaudRate = 115200;
  huart2.Init.WordLength = UART_WORDLENGTH_8B;
  huart2.Init.StopBits = UART_STOPBITS_1;
  huart2.Init.Parity = UART_PARITY_NONE;
  huart2.Init.Mode = UART_MODE_TX_RX;
  huart2.Init.HwFlowCtl = UART_HWCONTROL_NONE;
  huart2.Init.OverSampling = UART_OVERSAMPLING_16;
  if (HAL_UART_Init(&huart2) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN USART2_Init 2 */

  /* USER CODE END USART2_Init 2 */

}

/**
  * @brief GPIO Initialization Function
  * @param None
  * @retval None
  */
static void MX_GPIO_Init(void)
{
  GPIO_InitTypeDef GPIO_InitStruct = {0};
  /* USER CODE BEGIN MX_GPIO_Init_1 */

  /* USER CODE END MX_GPIO_Init_1 */

  /* GPIO Ports Clock Enable */
  __HAL_RCC_GPIOC_CLK_ENABLE();
  __HAL_RCC_GPIOD_CLK_ENABLE();
  __HAL_RCC_GPIOA_CLK_ENABLE();
  __HAL_RCC_GPIOB_CLK_ENABLE();

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(Led_GPIO_Port, Led_Pin, GPIO_PIN_RESET);

  /*Configure GPIO pin : B1_Pin */
  GPIO_InitStruct.Pin = B1_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_IT_RISING;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  HAL_GPIO_Init(B1_GPIO_Port, &GPIO_InitStruct);

  /*Configure GPIO pin : Led_Pin */
  GPIO_InitStruct.Pin = Led_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(Led_GPIO_Port, &GPIO_InitStruct);

  /* EXTI interrupt init*/
  HAL_NVIC_SetPriority(EXTI15_10_IRQn, 5, 0);
  HAL_NVIC_EnableIRQ(EXTI15_10_IRQn);

  /* USER CODE BEGIN MX_GPIO_Init_2 */

  /* USER CODE END MX_GPIO_Init_2 */
}

/* USER CODE BEGIN 4 */

void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart)
{
    if (huart->Instance == USART2)
    {
        if (rxCount < RX_FRAME_SLOTS)
        {
            memcpy(rxFrames[rxWrite],
                   irqRxFrame,
                   FRAME_LENGTH);

            rxWrite = (rxWrite + 1U) % RX_FRAME_SLOTS;
            rxCount++;
        }
        else
        {
            /* 缓存满时记录丢帧。 */
            rxDropped++;
        }

        /* 启动下一帧的中断接收。 */
        if (HAL_UART_Receive_IT(&huart2,
                               irqRxFrame,
                               FRAME_LENGTH) != HAL_OK)
        {
            rxRearmErrors++;
        }
    }
}

/* USER CODE END 4 */

/* USER CODE BEGIN Header_StartUartTask */
/**
  * @brief  Function implementing the uartTask thread.
  * @param  argument: Not used
  * @retval None
  */
/* USER CODE END Header_StartUartTask */
void StartUartTask(void *argument)
{
  /* USER CODE BEGIN 5 */

  uint8_t frame[FRAME_LENGTH];

    uint32_t groupCount;
    int32_t maximum;

    char text[96];

    uint32_t lastRxDropped = 0U;
    uint32_t lastCountDropped = 0U;
    uint32_t lastMaxDropped = 0U;

    if (HAL_UART_Receive_IT(&huart2,
                           irqRxFrame,
                           FRAME_LENGTH) != HAL_OK)
    {
        Error_Handler();
    }

    UART_Print("Task 2 ready. Send 11 characters, no CR/LF.\r\n");

  /* Infinite loop */
  for(;;)
  {
    /* 处理缓存中的完整 11 字符帧。 */
        while (PopRxFrame(frame) != 0U)
        {
            /* 按固定长度原样回显，不依赖字符串结束符。 */
            HAL_UART_Transmit(&huart2,
                              frame,
                              FRAME_LENGTH,
                              100U);

            UART_Print("\r\n");

            /* 按讲义要求检查第 2～6 个字符。 */
            if (memcmp(&frame[1], "DELAY", 5U) == 0)
            {
                uint16_t delayMs = 0U;
                uint8_t valid = 1U;

                /* 第 8～11 个字符必须全部是数字。 */
                for (uint32_t i = 7U; i < 11U; i++)
                {
                    if ((frame[i] < '0') || (frame[i] > '9'))
                    {
                        valid = 0U;
                        break;
                    }

                    delayMs =
                        (uint16_t)(delayMs * 10U
                                   + (uint16_t)(frame[i] - '0'));
                }

                if ((valid != 0U) && (delayMs > 0U))
                {
                    osStatus_t status =
                        osMessageQueuePut(commandQueueHandle,
                                          &delayMs,
                                          0U,
                                          0U);

                    if (status == osOK)
                    {
                        snprintf(text,
                                 sizeof(text),
                                 "Accepted: %u ms\r\n",
                                 (unsigned int)delayMs);

                        UART_Print(text);
                    }
                    else
                    {
                        UART_Print("Command queue full.\r\n");
                    }
                }
                else
                {
                    UART_Print("Invalid delay. Use 0001-9999.\r\n");
                }
            }
        }

        /* 打印每一条已收到的计数更新。 */
        while (osMessageQueueGet(countQueueHandle,
                                 &groupCount,
                                 NULL,
                                 0U) == osOK)
        {
            snprintf(text,
                     sizeof(text),
                     "Queue 2: groups of 10 toggles = %lu\r\n",
                     (unsigned long)groupCount);

            UART_Print(text);
        }

        /* 打印每一条已收到的最大值更新。 */
        while (osMessageQueueGet(maxQueueHandle,
                                 &maximum,
                                 NULL,
                                 0U) == osOK)
        {
            snprintf(text,
                     sizeof(text),
                     "Queue 3: maximum = %ld\r\n",
                     (long)maximum);

            UART_Print(text);
        }

        /* 仅在诊断计数变化时提示，避免不断刷屏。 */
        if ((rxDropped != lastRxDropped) ||
            (countQueueDropped != lastCountDropped) ||
            (maxQueueDropped != lastMaxDropped))
        {
            lastRxDropped = rxDropped;
            lastCountDropped = countQueueDropped;
            lastMaxDropped = maxQueueDropped;

            snprintf(text,
                     sizeof(text),
                     "Dropped: RX=%lu Q2=%lu Q3=%lu\r\n",
                     (unsigned long)lastRxDropped,
                     (unsigned long)lastCountDropped,
                     (unsigned long)lastMaxDropped);

            UART_Print(text);
        }

        osDelay(MsToTicks(5U));
  }
  /* USER CODE END 5 */
}

/* USER CODE BEGIN Header_StartLedTask */
/**
* @brief Function implementing the ledTask thread.
* @param argument: Not used
* @retval None
*/
/* USER CODE END Header_StartLedTask */
void StartLedTask(void *argument)
{
  /* USER CODE BEGIN StartLedTask */

  uint16_t receivedDelay;

    /* 默认每 1000 ms 翻转一次。 */
    uint32_t periodTicks = MsToTicks(1000U);
    uint32_t nextToggle =
        osKernelGetTickCount() + periodTicks;

    uint32_t toggleCount = 0U;
    uint32_t groupCount = 0U;

    /* 可重复的伪随机序列，方便调试。 */
    uint32_t randomState = 0x12345678U;

    /* volatile 使本实验确实保留完整数组的读写。 */
    volatile int numbers[150];

  /* Infinite loop */
  for(;;)
  {
    uint32_t now = osKernelGetTickCount();

        int32_t remaining =
            (int32_t)(nextToggle - now);

        uint32_t waitTicks =
            (remaining > 0) ? (uint32_t)remaining : 0U;

        /* 等待新命令，最多等到下一次 LED 翻转时刻。 */
        osStatus_t status =
            osMessageQueueGet(commandQueueHandle,
                              &receivedDelay,
                              NULL,
                              waitTicks);

        if (status == osOK)
        {
            periodTicks = MsToTicks(receivedDelay);

            /* 每收到一个新间隔，重新填充全部 150 个元素。 */
            for (uint32_t i = 0U; i < 150U; i++)
            {
                randomState =
                    randomState * 1664525U + 1013904223U;

                numbers[i] =
                    (int)((randomState >> 16U) & 0x7FFFU);
            }

            /* 再扫描数组，找出最大值。 */
            int32_t maximum = numbers[0];

            for (uint32_t i = 1U; i < 150U; i++)
            {
                if (numbers[i] > maximum)
                {
                    maximum = numbers[i];
                }
            }

            if (osMessageQueuePut(maxQueueHandle,
                                  &maximum,
                                  0U,
                                  0U) != osOK)
            {
                maxQueueDropped++;
            }

            /* 新命令到达后，从当前时间重新开始计时。 */
            nextToggle =
                osKernelGetTickCount() + periodTicks;
        }

        now = osKernelGetTickCount();

        if ((int32_t)(now - nextToggle) >= 0)
        {
            HAL_GPIO_TogglePin(Led_GPIO_Port, Led_Pin);

            toggleCount++;

            if (toggleCount >= 10U)
            {
                toggleCount = 0U;
                groupCount++;

                if (osMessageQueuePut(countQueueHandle,
                                      &groupCount,
                                      0U,
                                      0U) != osOK)
                {
                    countQueueDropped++;
                }
            }

            nextToggle = now + periodTicks;
        }
  }
  /* USER CODE END StartLedTask */
}

/**
  * @brief  Period elapsed callback in non blocking mode
  * @note   This function is called  when TIM4 interrupt took place, inside
  * HAL_TIM_IRQHandler(). It makes a direct call to HAL_IncTick() to increment
  * a global variable "uwTick" used as application time base.
  * @param  htim : TIM handle
  * @retval None
  */
void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim)
{
  /* USER CODE BEGIN Callback 0 */

  /* USER CODE END Callback 0 */
  if (htim->Instance == TIM4)
  {
    HAL_IncTick();
  }
  /* USER CODE BEGIN Callback 1 */

  /* USER CODE END Callback 1 */
}

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */
  __disable_irq();
  while (1)
  {
  }
  /* USER CODE END Error_Handler_Debug */
}
#ifdef USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */
