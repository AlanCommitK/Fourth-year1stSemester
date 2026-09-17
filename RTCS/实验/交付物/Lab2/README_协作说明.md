# Lab 2 上机操作说明（给动手跑板子的同学）

**报告截止：2026 年 9 月 30 日（周三）23:59。** 图和数据请在 **9 月 26 日**前发我。

四个任务，每个 25 分：UART 计算器 / I2C 控制 Arduino / SPI 调 PWM / SPI 驱动舵机。
所有 STM32 代码在同目录 `代码/` 下，每段都标好了粘到 `main.c` 的哪一对 `USER CODE BEGIN/END` 之间。

---

## 0. 先确认三件事（这一步最急，缺件要买）

> [!important] 请先回我这三个问题，别的都可以慢慢来
>
> 1. **你手上的 Arduino 是「Nano Every」还是普通的「Nano」？**
>    板子背面 / 正面丝印会写。**Task 3 和 Task 4 必须是 Nano Every**——老师给的
>    `SPI_ArduinoNanoEvery_Slave.ino` 里用的 `SPI0.CTRLA`、`ISR(SPI0_INT_vect)` 是
>    ATmega4809（Nano Every 的芯片）独有的，普通 Nano（ATmega328P）**编译都过不了**。
>    Task 2 的 I2C 两种板子都能跑。
> 2. **有没有舵机？** Task 4 要一个普通的 SG90／MG90S 之类的小舵机。手册从头到尾没提要准备它。
> 3. **有没有这些小件**：电位器 ×1、LED ×2、220～330 Ω 电阻 ×2、1 kΩ 电阻 ×1、面包板、杜邦线若干。

### 四个任务的硬件需求，按「好做」排序

| 任务 | 需要什么 | 说明 |
| --- | --- | --- |
| **Task 1** | **只要 Nucleo + 一根 USB 线** | 不用 Arduino、不用面包板。**先把这个做了**，五分钟就能出图 |
| **Task 2** | Nucleo + 任意 Nano + 电位器 + 4 根线 | 接线最简单 |
| **Task 3** | 上面 + **Nano Every** + LED×2 + 电阻 | 接线要按下面的表，**别按手册** |
| **Task 4** | 上面 + 舵机 + 独立 5 V 电源 | 舵机吃电流，别从 Nucleo 取 |

> Task 3、Task 4 按手册原文**不要求截图**（只要代码 + 计算 + 讨论），所以万一硬件凑不齐，
> 这两个任务我也能靠软件把分拿到大半。Task 1、Task 2 是**明确要截图的**，优先保证。

---

## 1. 接线卡：照这张接，不要照手册

手册的接线表有三处错，照它接轻则不通、重则两个输出对推。逐条核对过的正确接法：

### I2C（Task 2）

```
Nucleo 排针 SCL (PB8)  ──►  Nano A5
Nucleo 排针 SDA (PB9)  ──►  Nano A4      ← 手册图 9 画到了 A6，A6 没有 I2C 功能
Nucleo GND             ──►  Nano GND     ← 手册文字表漏了，但必须接
Nucleo 5V              ──►  Nano VIN     （或者 Nano 自己插 USB 供电）

电位器：两个外侧脚 → Nano 5V 和 GND，中间脚 → Nano A1
```

不稳的话在 SDA、SCL 上各加一个 **4.7 kΩ 上拉到 5 V**。PB8/PB9 是 5 V 容忍脚，安全。

### SPI（Task 3、Task 4）

| 信号 | Nucleo 排针（STM32 脚） | 方向 | Nano Every | 手册写的 |
| --- | --- | --- | --- | --- |
| SCK | **D13** (PA5) | → | **D13** | D13 ✓ |
| MOSI | **D11** (PA7) | → | **D11** | D12 ✗ |
| MISO | **D12** (PA6) | ← | **D12** | D11 ✗ |
| CS | **D9** (PC7) | → | **D8** | D10 ✗ |
| GND | 任一 GND | — | GND | 漏写 |

三件事解释一下，免得你觉得我在瞎改：

- **MOSI 和 MISO 不交叉。** 这点和串口相反（串口 TX 接 RX）。SPI 的线是按功能命名的，
  主机的「主出」线和从机的「主出」线是同一根。按手册交叉接，会让 STM32 的输出顶住
  Arduino 设成输出的脚，**两个输出对推**。
- **CS 接 Nano 的 D8，不是 D10。** Nano Every 的 SPI 走的是 PORTE，硬件片选脚是 PE3 = **D8**。
  Arduino 官方的 `pins_arduino.h` 里写的就是 `PIN_SPI_SS (8)`。D10 跟 SPI 没关系。
- **CS 在 Nucleo 这边用 D9（PC7），不用手册说的 D10（PB6）。**
  因为 PB6 同时是 TIM4 通道 1 的 PWM 输出脚，而 Task 3/4 要同时用 SPI 和 PWM，
  一个引脚不可能既当普通输出又当定时器输出。**手册这里是自相矛盾的**，PB6 留给 PWM。

再加三个小件：

```
MISO 线上串一个 1 kΩ         ← PA6 不是 5V 容忍脚，Arduino 是 5V 输出
Nano D2  → 330Ω → LED → GND  ← Arduino 自己闪的灯
Nucleo D10 (PB6) → 330Ω → LED → GND   ← Task 3 要看的 PWM 调光灯
舵机信号线 → Nucleo D10 (PB6)          ← Task 4，此时把上面那个 LED 拆掉
```

---

## 2. Arduino 端：有一行必须改，不然 SPI 完全不动

打开 `SPI_ArduinoNanoEvery_Slave.ino`，**第 17 行**是：

```c
SPI0.CTRLA = (SPI_DORD_bm & (SPI_ENABLE_bm & (~SPI_MASTER_bm)));
```

`DORD`、`ENABLE`、`MASTER` 是**三个不同的单比特掩码**，而两个不同的单比特相与结果是 0。
所以这一行等于 `SPI0.CTRLA = 0`，把 SPI 外设直接关掉了，中断永远不会触发。
换成：

```c
SPI0.CTRLA = (SPI0.CTRLA | SPI_ENABLE_bm) & ~(SPI_MASTER_bm | SPI_DORD_bm);
```

（使能 = 1、主机位 = 0 表示从机、DORD = 0 表示高位先发，和 CubeMX 里的 MSB First 对上。
顺带一提，那行上面的注释写「set MSB first」，但置 DORD 恰恰是低位先发，注释也是错的。）

`i2c_arduino.ino` 不用改。但如果 Task 2 通信不稳，**先把第 20 行 `Serial.println(RxByte);` 注释掉**
——它在 I2C 接收中断里做串口输出，会拖长中断、干扰时序。

---

## 3. 四个任务怎么做

每个任务建一个独立的 CubeMX 工程（`Lab2_Task1` … `Lab2_Task4`），
建工程时「Initialize all peripherals with their default Mode?」选 **Yes**。
每个 `.c` 文件开头都写了该任务要在 CubeMX 里点哪些、粘哪几段，**照着文件里的清单做**，
这里只列要验证什么、要拍什么。

### Task 1 — 串口计算器（25 分，只要 Nucleo）

代码：`代码/Task1_uart_calculator.c`

**串口终端波特率要改成 9600**，和 CubeMX 里一致。板子出厂的虚拟串口是 115200，不改就是乱码。

验证：输入三个两位数、再输 `a` 或 `m`，看结果对不对。

**要拍 2 张**：
- **图 1.1**：做加法的完整串口输出（三个数 + `a` + 结果）
- **图 1.2**：做乘法的完整串口输出（同样三个数 + `m` + 结果）

> 终端里开一下「local echo（本地回显）」截图更好看；不开也行，程序会把收到的内容回显一遍。

### Task 2 — I2C 控制 Arduino（25 分）

代码：`代码/Task2_i2c_uart.c`。先把 `i2c_arduino.ino` 烧进 Nano。

程序会先问闪烁速度（1–4），再问要读哪种数据（0 或 1）。

验证：
1. 选速度 3，Nano 板载 LED（D13 那个）应当 **1 秒一个周期**（亮 0.5 s、灭 0.5 s）。
2. 选数据 0，打印出电位器的值；**转动电位器再读一次，数字应当跟着变**。
3. 选数据 1，应当打印出 `RTCA` 四个字符。

**要拍 2 张**：
- **图 2.1**：命令 `0x00`，收到 2 字节模拟值的串口输出（最好转两次电位器截两次，选清楚的一张）
- **图 2.2**：命令 `0x01`，收到 4 字节 `RTCA` 的串口输出

> 速度选项 1（命令 `0x80`）在源码里是 `time = 0`，也就是**完全不延时**，
> 灯会以主循环速度翻转、看着是「半亮」而不是手册 Table 1 说的「常亮」。这是手册的表抄错了，不是你接错了。

### Task 3 — SPI 读电位器、PWM 调光（25 分，要 Nano Every）

代码：`代码/Task3_spi_pwm.c`。先按第 2 节改好 `.ino` 再烧进 Nano Every。

验证：转电位器，**Nucleo D10 上那个 LED 应当从全灭平滑变到全亮**，串口同时打印数值和占空比。

手册不要求截图，但如果方便，拍一张串口输出（能看到数值随电位器变化）对报告很有帮助。

### Task 4 — SPI 驱动舵机（25 分，要舵机）

代码：`代码/Task4_spi_servo.c`。把 D10 上的 LED 拆掉，换成舵机信号线。

> [!warning] 舵机**不要**从 Nucleo 的 5V 取电
> 小舵机动起来就是几百毫安，堵转能超过 1 A，Nucleo 的 5V 是 ST-LINK 那路 USB 供的，
> 会把板子拉到复位。用单独的 5 V（充电宝 + 破皮的 USB 线就行），
> **但一定要把这个电源的 GND 和 Nucleo 的 GND 接在一起**，否则舵机收不到有效的脉冲。

验证：转电位器，舵机角度跟着走；松手不动，舵机也停在原地不抖。

**要回我**：舵机实际能用的脉宽范围（如果 1.0–2.0 ms 转不满或转过头，告诉我它的实际范围）。

---

## 4. 做完请回我这些

1. 第 0 节那**三个硬件问题**（Nano 型号 / 有没有舵机 / 小件齐不齐）——**这个最急，先回**
2. **图 1.1、1.2、2.1、2.2** 四张串口截图
3. CubeMX 里 **Clock Configuration** 的截图一张（要能看清 APB1 timer clocks 和 APB2 的数字）
4. Task 3：LED 调光有没有成功？串口打印的数值转电位器时是不是跟着变？
5. Task 4：舵机能不能转？实际脉宽范围是多少？
6. SPI 的片选：我写的是「四次传输全程拉低」。如果你改成了「每字节拉一次」才通，告诉我
7. 任何一处你改了我的代码/接线，都告诉我改了哪

中间任何一步对不上，**不要自己改逻辑**，把现象、接线照片和串口输出发我。

---

## 5. 常见报错对照

| 现象 | 原因 | 处理 |
| --- | --- | --- |
| 串口全是乱码 | 终端波特率不是 9600 | 终端改 9600，和 CubeMX 一致 |
| 串口只收到第一个字符 | 回调末尾的 `HAL_UART_Receive_IT()` 没粘 | 补上，见 `USER CODE BEGIN 4` |
| `unknown type name 'bool'` | `#include <stdbool.h>` 没粘 | 粘到 `USER CODE BEGIN Includes` |
| I2C 每次都 `no ACK` | SDA/SCL 接反、SDA 接到 A6、没共地、地址没左移 | 按第 1 节重接；地址必须是 `0x55<<1` |
| SPI 读回来永远是 0x00 或 0xFF | `.ino` 第 17 行没改 / MOSI-MISO 接反 / CS 接了 D10 | 第 2 节 + 第 1 节 |
| Nano Every 编译报 `SPI0` 未定义 | 板子选成了普通 Nano | 开发板选 **Arduino Nano Every** |
| 普通 Nano 编译不过 SPI 代码 | 芯片不对，这份代码只能跑在 Nano Every | 见第 0 节问题 1 |
| PWM 灯肉眼可见闪烁 | Prescaler/Counter Period 填成手册的 10 Hz 那组 | 按 `.c` 文件里的 63 / 999 |
| 舵机一动板子就重启 | 舵机从 Nucleo 5V 取电 | 换独立电源，共地 |
