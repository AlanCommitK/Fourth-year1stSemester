# Lab 1 上机操作说明（给动手跑板子的同学）

板子：**NUCLEO-F103RB**（STM32F103RB，Cortex-M3）。软件：**STM32CubeIDE**。

这份文件只有两件事：**照着点、照着粘**，然后**把清单里的图发回来**。
所有代码都在同目录 `代码/` 下，里面每一段都标好了该粘到 `main.c` 的哪一对
`USER CODE BEGIN/END` 标记之间——只有这两个标记之间的代码在 CubeMX 重新生成工程时不会被覆盖。

预计用时：Task 3 约 15 分钟，Task 4 约 25 分钟。

---

## 0. 一共要建几个工程

**两个**，互不干扰：

| 工程名 | 对应 | 为什么要分开 |
| --- | --- | --- |
| `Lab1_Task3` | Task 3（按住按钮亮灯） | PC13 在这里是**普通输入** |
| `Lab1_Task4` | Task 4（按一下开始闪、再按一下停） | PC13 在这里是**外部中断**，而且两个程序都要抢 LD2，同一个工程里会打架 |

Task 1 和 Task 2 是纸面题，不用建工程、不用上板。
`代码/Task1_config_PB5.c` 要是想顺手验证一下能不能编译：把文件里**三行 `#define`** 粘到 Task 3 工程的
`USER CODE BEGIN PD`，再把 `gpiob_pin5_init()` **函数体里那两句**粘到 `USER CODE BEGIN 2`。
只粘那两句会报 `'PB5_FIELD_MASK' undeclared`——宏也得带上。编译过了就行，板子上看不到现象（PB5 没接东西）。

建工程的路径是 `File > New > STM32 Project`，在 Board Selector 里搜 `NUCLEO-F103RB` 选中，
下一步给工程起名，最后问「Initialize all peripherals with their default Mode?」时选 **Yes**。

> [!important] 为什么选 Yes
> 选 Yes 时 CubeMX 会连**时钟树**一起按板子的默认值配好（手册 §4.2 图 8 里那个 64 MHz 就是这么来的），
> 还会顺手把 LD2(PA5)、B1(PC13) 标好名字。选 No 则时钟停在复位默认值（HSI 8 MHz），
> Task 4 的定时器参数会完全不同。
> **但无论选哪个，都以 §2.1 里实际读到的数字为准**——下面的参数表把两种情况都覆盖了，
> 读到 8 就用 8 那一行，不用回头改工程。
> 选 Yes 的副作用是 PC13 会被预先配成 `GPIO_EXTI13`，Task 3 里要手动改回 `GPIO_Input`（见 1.1 第 2 步），
> 其余多配出来的外设（USART2 之类）不影响本实验。

---

## 1. Task 3：按住蓝色按钮，绿灯亮

### 1.1 CubeMX 里点这些

1. 在引脚图上点 **PA5** → 选 `GPIO_Output`
2. 在引脚图上点 **PC13** → 选 `GPIO_Input`
3. 左栏 `System Core > GPIO` → 点列表里的 **PC13** → 把
   `GPIO Pull-up/Pull-down` 设成 **No pull-up and no pull-down**
   （板子上 PC13 已经有一个外部上拉电阻了，不用再开片内的）
4. `Ctrl+S` 保存，让它重新生成代码

> 除此之外**什么都不要动**。不需要定时器，不需要中断。

### 1.2 粘代码

打开 `代码/Task3_button_led.c`，把里面三段分别粘到 `main.c` 的对应位置：

| 这一段 | 粘到 main.c 的 |
| --- | --- |
| `#include <stdbool.h>` | `USER CODE BEGIN Includes` 下面 |
| 一堆 `#define` | `USER CODE BEGIN PD` 下面 |
| `if ((BTN_PORT->IDR ...` 那一段 | `USER CODE BEGIN 3` 下面（它在 `while(1)` **里面**） |

### 1.3 编译、烧录、验证

按顺序做，**每一步都要对**：

1. 编译（锤子图标）→ 应该 0 error。若报 `unknown type name 'bool'`，说明第一段（`#include <stdbool.h>`）没粘进去。
2. 烧录（Run 三角）。
3. **手不要碰板子**：绿灯 LD2 应当是**灭**的。
4. **按住蓝色按钮 B1**：LD2 应当**亮**，松手立刻灭。

> [!WARNING] 如果第 3 步灯就是亮的（按下反而灭）
> 说明这块板子的按键极性和预期相反。改法是**把 `if (!pc13_high)` 的感叹号去掉**，变成
> ```c
> if (pc13_high)
> ```
> 重新编译烧录即可，其余一个字都不用动。
> **改了的话请告诉我**，报告里要写明用的是哪一版。

### 1.4 要拍的图（图号 3 个，共 4 张）

- **图 4.1**：两张——(a) CubeMX 引脚图，能看清 PA5 是 `GPIO_Output`、PC13 是 `GPIO_Input`；
  (b) `System Core > GPIO` 里 PC13 那一行，能看清 pull 是 `No pull-up and no pull-down`
- **图 4.2**：板子照片，**没按按钮**，LD2 灭
- **图 4.3**：板子照片，**按住按钮**，LD2 亮

---

## 2. Task 4：按一下开始闪（1.5 秒一次），再按一下停

### 2.1 先读一个数（这一步最重要，别跳）

新建工程 `Lab1_Task4` 之后，先点上方标签 **Clock Configuration**，
找到右边那个写着 **`APB1 timer clocks (MHz)`** 的方框，**把里面的数字记下来**。

按 §0 的方式建工程（默认外设初始化选 Yes）一般会读到 **64**；
若建工程时选了 No、或有人动过时钟树，可能读到 **8**（HSI 复位默认值）。
两种都行，**不用回去改工程**，照下表取对应那一行就是：

| `APB1 timer clocks` | Prescaler 填 | Counter Period 填 |
| --- | --- | --- |
| 8 MHz | `3999` | `2999` |
| 32 MHz | `15999` | `2999` |
| 36 MHz | `17999` | `2999` |
| 48 MHz | `23999` | `2999` |
| **64 MHz（默认）** | **`31999`** | **`2999`** |
| 72 MHz | `35999` | `2999` |

> [!NOTE] 为什么 Counter Period 一直是 2999
> 我特意让分频后的计数节拍固定在 2 kHz，这样"数 3000 个节拍 = 1.5 秒"就与主频无关，
> 只有 Prescaler 随主频变。少一个会填错的地方。

**请把 `APB1 timer clocks` 的数字和它旁边那一片的截图发给我。**

### 2.2 CubeMX 里点这些

1. `Pinout & Configuration > Timers > TIM2` → `Clock Source` 选 **Internal Clock**
2. 同一页下方 `Parameter Settings`：
   - `Prescaler` = 上表对应的值（默认 `31999`）
   - `Counter Mode` = **Up**
   - `Counter Period (AutoReload Register)` = `2999`
   - `auto-reload preload` = **Disable**
3. 同一页的 `NVIC Settings` 标签 → 勾上 **TIM2 global interrupt**
4. 回引脚图，点 **PC13** → 选 **`GPIO_EXTI13`**
5. 左栏 `System Core > GPIO` → 点 **PC13** →
   `GPIO mode` 选 **External Interrupt Mode with Falling edge trigger detection**，
   `Pull-up/Pull-down` 选 **No pull-up and no pull-down**
6. 左栏 `System Core > NVIC` → 勾上 **EXTI line[15:10] interrupts**
7. 回引脚图，点 **PA5** → 选 `GPIO_Output`
8. `Ctrl+S` 保存生成代码

### 2.3 粘代码

打开 `代码/Task4_timer_blink.c`。**先改一个数**：把文件开头

```c
#define TIMCLK_HZ    64000000UL
```

改成 2.1 里读到的值（比如读到 36 MHz 就写 `36000000UL`，注意是 Hz，六个零）。
读到的就是 64 就不用改。

然后把**五段**粘到 `main.c`：

| 这一段 | 粘到 main.c 的 |
| --- | --- |
| `#include <stdbool.h>` | `USER CODE BEGIN Includes` |
| 一堆 `#define` | `USER CODE BEGIN PD` |
| 两个 `static volatile` 变量 | `USER CODE BEGIN PV` |
| `__HAL_TIM_SET_PRESCALER(...)` 那一段 | `USER CODE BEGIN 2` |
| 两个 `Callback` 函数 | `USER CODE BEGIN 4`（在文件最后、`main()` 之后） |

`while(1)` 里**一行都不用写**，保持空的就对了——所有动作都在中断里。

### 2.4 编译、烧录、验证

1. 编译 → 0 error。
2. 烧录，**手不要碰板子**：LD2 应当一直灭着，不动。
3. **按一下**按钮：LD2 开始闪。
   **用手机秒表掐 10 个完整的亮灭周期**，应该是 **30 秒左右**（10 × 2 × 1.5 s）。
   - 掐出来约 15 秒 → `TIMCLK_HZ` 填小了一半
   - 掐出来约 60 秒 → 填大了一倍
   - 掐出来约 **240 秒**（4 分钟，肉眼就是"半天才闪一下"）→ 填成了实际值的 8 倍，
     多半是工程实际跑在 8 MHz 而 `TIMCLK_HZ` 还写着 64000000
   - 都不是 → 把 2.1 的截图发我，我来算
4. **再按一下**：闪烁停止，LD2 停在**灭**的状态。
5. 反复按 5～6 次：**每按一次只能翻转一次**。如果偶尔一按就翻两次（按了没反应），
   把 `#define DEBOUNCE_MS 200U` 改大到 `300U` 再试。

> [!WARNING] 如果按按钮完全没反应
> 说明触发边沿选反了。回到 2.2 的第 5 步，把 `Falling edge` 改成
> **Rising edge trigger detection**，保存重新生成、重新烧录。
> **改了的话请告诉我**，报告里要写明。
> （按理不该发生：板子上 PC13 是外部上拉、按下接地，ST 官方的板级支持包对这颗按键
> 用的也是下降沿。）

### 2.5 要拍的图（图号 5 个，共 6 张）

- **图 5.1**：Clock Configuration 截图，**`APB1 timer clocks (MHz)` 那个框要清晰可读**
- **图 5.2**：TIM2 的 `Parameter Settings`，能看清 Prescaler 和 Counter Period
- **图 5.3**：TIM2 的 `NVIC Settings`（TIM2 global interrupt 打勾）+ `System Core > NVIC` 里
  EXTI line[15:10] 打勾，两张或拼一张都行
- **图 5.4**：`System Core > GPIO` 里 PC13 的配置，能看清 `External Interrupt Mode with
  Falling edge trigger detection`
- **图 5.5**：板子照片两张——按第一下之后 LD2 亮着（闪烁中）、按第二下之后 LD2 灭

---

## 3. 做完请回我这七件事

1. `APB1 timer clocks (MHz)` 读到的是多少
2. Task 3 里最后用的是 `if (!pc13_high)` 还是 `if (pc13_high)`
3. Task 4 里 PC13 用的是 **Falling** 还是 **Rising** 边沿
4. §2.4 第 3 步**掐表读数**：10 个完整亮灭周期实际用了多少秒
5. `DEBOUNCE_MS` 有没有从 `200U` 改过？改成了多少？
6. `htim2.Instance->EGR = TIM_EGR_UG;` 那一行有没有删过？
7. 上面 **8 个图号、共 10 张**图（4.1 两张、4.2、4.3、5.1、5.2、5.3 两张、5.4、5.5 两张）

第 5、6 条看着琐碎，但报告里专门有段落在解释这两处，你改了而我不知道，报告就写错了。

有这七样我就能把报告收尾。中间任何一步对不上，**不要自己改逻辑**，直接把现象和截图发我。

**回图截止**：报告 9 月 18 日（周五）交，请在 **9 月 15 日**前发我，留出改稿时间。

---

## 4. 常见报错对照

| 现象 | 原因 | 处理 |
| --- | --- | --- |
| `unknown type name 'bool'` | `#include <stdbool.h>` 没粘 | 粘到 `USER CODE BEGIN Includes` |
| `'htim2' undeclared` | TIM2 没在 CubeMX 里启用 | 回 2.2 第 1 步 |
| `'TIM_EGR_UG' undeclared` | 极少见，工程头文件没引全 | 把那一行整句删掉，改在 CubeMX 里手填 Prescaler 即可 |
| 编译过了但一按就跑飞 / 死机 | 回调函数粘进了 `USER CODE BEGIN 2` 而不是 `4` | 函数定义必须在 `main()` 外面，即 `USER CODE BEGIN 4` |
| 保存后代码没了 | 粘到了 `USER CODE` 标记**外面** | 只能粘在 `BEGIN`/`END` 这一对之间 |
| 按一下之后 LD2 一直**灭**着不闪 | 定时器没起来 / TIM2 中断没使能 | 检查 2.2 第 3 步和第 6 步的两个勾 |
| LD2 看着像常亮或发暗、看不出闪 | 闪太快了，`TIMCLK_HZ` 比实际值小很多 | 回 2.1 重读 `APB1 timer clocks` |
