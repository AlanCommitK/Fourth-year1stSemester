---
chapter: L16
status: 已完成
---

# L16 区块链共识 II

> [!info] 这一讲在做什么
> 上一讲 [[L15 区块链共识 I]] 讲的 PoW（Proof of Work，工作量证明）与 PoS（Proof of Stake，权益证明）是公有链（任何人都能自由加入的区块链）的做法：谁也不认识谁，就按算力或押上的币来"抽签"决定谁记账。这一讲换一个场景：**参与者是一组事先登记好、彼此知道身份的机器，其中有些可能崩溃，甚至可能撒谎——它们怎样对"下一条记录是什么"达成一致？** 这就是**共识**（consensus）问题：让一组节点对同一件事得出相同的结论。
> 课件讲了三个协议，回答由弱到强：
> - **Paxos**：最经典的共识协议，Leslie Lamport 提出；名字取自希腊的 Paxos 岛，Lamport 在论文里虚构了岛上一个兼职议会的表决规则来讲这个算法。它只防**崩溃**，靠"多数派代表全体"；
> - **RAFT**：为了好懂而重新设计的崩溃容错协议，先选出一个 leader（领导者，负责协调的那个节点），再由它把日志（log，按顺序记下的命令列表）复制给大家；
> - **PBFT**（Practical Byzantine Fault Tolerance，实用拜占庭容错）：连**撒谎的节点**也防，代价是多一轮投票、消息量随节点数平方增长。
>
> 三个协议表面上各有一套角色和阶段，底下是同一条规则：**任意两个法定人数（quorum）必须相交于至少一个诚实节点**。法定人数是协议每一步至少要凑齐的回应者集合；下文 $N$ 表示节点总数，$f$ 表示至多出故障的节点数。课件把这条规则推出的两个数 $2f+1$（p38）和 $3f+1$（p67）分散在 Paxos 和 PBFT 里、只给结论。本笔记把它提到最前面统一推导（[[#3 法定人数交集：2f+1 与 3f+1 从哪里来|第 3 节]]），再逐个讲三个协议，每讲一条规则都回头说明它在守护哪个交集。这是和课件顺序的主要不同；三个协议内部仍按课件的"主思想 → 角色 → 阶段"展开，另补了课件没讲的"每一步为什么必要"。
> 对应课件 `Lecture 16 - Blockchain Consensus-II.pdf`，74 页。p2–p22 原样复习 L15，压缩在[[#1 回顾：L15 的 PoW、PoS 与性能指标|第 1 节]]；p23–25、p43、p62、p73–74 是路线图、教学计划、分节页和小结，没有新知识点（p62 标题误印成 "Outline of Lecture 13"；p74 预告的认知无线电实际在 [[L18 区块链赋能的认知无线电网络]]）。p24 教学计划的目标只有一行 "Three consensus mechanisms PAXOS, RAFT, and PBFT (typical in communication network)"。课件这三个协议部分的措辞和几张时序图、状态图，与 Imran Bashir《Mastering Blockchain》共识算法一章的风格一致，很可能取自该书；本笔记核对用的是三篇原始论文：Lamport 2001、Ongaro 与 Ousterhout 2014、Castro 与 Liskov 1999。
> 下一讲 [[L17 区块链共识 III]] 的课件几乎逐字重放本讲的 RAFT 与 PBFT；**Paxos 的五页细则 p32–34、p40–41 只在本讲出现**，模拟卷的 Paxos 题明说以本讲为准。附读物 `PBFT-Mathematical Proof.pdf` 实为 PBFT 原论文全文，概要见 [[#6.8 附读物：PBFT 原论文|6.8]]。课程总览与考情见 [[00 IS 课程信息与考情]]。

> [!tip] 考点
> 课件没有 "exam""you will be asked" 一类原话。考试信号有两处：
> - 唯一带 "Note" 标记的一页是 p38："Note: … in order to tolerate **f faulty acceptors**, at least a set consisting of **2f + 1** acceptors is required."——它被模拟卷直接考了；
> - RAFT 与 PBFT 的主思想、三种角色、$N\ge3f+1$、三阶段与时序图，在 L17、L18（p3–17）和 L20 Summary（p54–68）里又原样出现了三次，是全课重复最多的内容。
>
> 模拟卷（去年版）有 9 小题、共 30 分落在本讲的页面上（含复习页）。其中 4 小题共 15 分首讲在本讲；另 5 小题共 15 分首讲在 L15，本讲只是复习页，规范答法以 L15 为准：
>
> | 题号 | 分值 | 问什么 | 首讲 | 本笔记 |
> | --- | --- | --- | --- | --- |
> | Q3(b)(i) | 4 | 两类故障并解释 | L15 | [[#1.1 共识、两类节点与两类故障\|1.1]]；[[L15 区块链共识 I#2.2 两类节点，两类故障\|L15 2.2]] |
> | Q3(b)(ii) | 3 | 列三种共识机制 | L15 | [[#7 三个协议的对比\|第 7 节]]；[[L15 区块链共识 I#2.4 常见共识机制一览\|L15 2.4]] |
> | Q3(b)(iii) | 3 | 吞吐量与确认时间（参考答案算错） | L15 | [[#1.3 吞吐量与确认时间\|1.3]]；[[L15 区块链共识 I#5.6 例题：课件 Q2 与模拟卷原题\|L15 5.6]] |
> | Q3(b)(iv) | 3 | 3 个崩溃节点，求最少合法节点，要推导 | **L16** | [[#3.2 崩溃故障：N ≥ 2f+1\|3.2]]、[[#3.5 考场写法\|3.5]] |
> | Q4(a)(i) | 3 | PoW 获胜概率反求算力 | L15 | [[#1.2 PoW 与 PoS\|1.2]]；[[L15 区块链共识 I#3.3 例题：求获胜概率与反求算力\|L15 3.3]] |
> | Q4(a)(ii) | 2 | PoS 相对 PoW 的优点 | L15 | [[#1.2 PoW 与 PoS\|1.2]]；[[L15 区块链共识 I#4.2 相对 PoW 的优点\|L15 4.2]] |
> | **Q4(a)(iii)** | **5** | **Paxos 的节点与阶段**（参考答案："refer to the slides in lecture 16"） | **L16** | [[#4.9 考场答法：Paxos 的节点与阶段\|4.9]] |
> | Q4(a)(iv) | 3 | 3 个拜占庭节点，求最少合法节点，要推导 | **L16** | [[#3.3 拜占庭故障：N ≥ 3f+1\|3.3]]、[[#3.5 考场写法\|3.5]] |
> | Q4(a)(v) | 4 | RAFT 三种角色，能否抗拜占庭 | **L16** | [[#5.6 RAFT 不能抵抗拜占庭故障\|5.6]] |
>
> 模拟卷没出 PBFT 的阶段题。但 PBFT 在四个讲次里重复出现，课件对三个协议又用同一个"主思想 → 角色 → 阶段"模板，按 "Explain the main process of PBFT, including the nodes and phases" 出题的可能性不低，[[#6.4 正常流程的三个阶段|6.4]] 按这个问法写到能直接作答。

## 1 回顾：L15 的 PoW、PoS 与性能指标

课件 p2–p22 逐页重放了 L15 的 21 页，只删了三句话。完整讲解和这几道模拟卷题的规范答法都在 [[L15 区块链共识 I]]；这里只留读懂本讲需要的定义和结论，每道题给一行结果和出处。

### 1.1 共识、两类节点与两类故障

**共识**（consensus）就是"达成共同的约定"（p3 "Consensus means to reach a common agreement."）；约定一旦达成，要通知所有参与方，系统状态随之更新。在区块链里，要约定的是"下一个区块是什么、账本按什么顺序记"。

分布式环境里的节点分两类（p4）：

- **合法节点**（legitimate node）：诚实的节点，按协议办事；
- **恶意节点**（malicious node）：可能做任何违反协议的事。

故障也分两类（p5）。课件按节点身份来分（合法节点出的是崩溃故障，恶意节点出的是拜占庭故障），准确的分法是按**出故障时的行为**：

- **崩溃故障**（crash failure）：节点停止工作——死机、断电、断网、进程退出，表现为**不再收发消息**。它要么正常、要么沉默，崩溃前说的每句话都是真的。
- **拜占庭故障**（Byzantine failure）：节点可以**任意行为**——沉默、**撒谎**、伪造内容、对不同的人说不同的话、和别的故障节点串通。原因可能是作恶，也可能只是软件缺陷让它乱发消息；课件 p5 把它归给恶意节点（"occurs if malicious node causes any failure"）。名字来自 Lamport 等人 1982 年的"拜占庭将军问题"：几位将军靠信使商定进攻或撤退，其中有叛徒会给不同的人送去相反的口信。

模拟卷 Q3(b)(i)（4 分）："List and explain two typical failures occurred in a blockchain system." 考场写法与 [[L15 区块链共识 I#2.2 两类节点，两类故障|L15 2.2]] 相同：

- **Crash failure**: the node cannot work properly (either receiving data or transmitting data), e.g. it crashes or goes offline.
- **Byzantine failure**: the node can arbitrarily send any false information (e.g. conflicting messages to different nodes), typically because it is malicious or compromised.

共识协议的职责（p6）有两条：按顺序、保持原样、防篡改地**维护账本数据**；在有节点作恶时仍让节点之间**达成一致**（课件原话 "to provide Byzantine agreement, even in the presence of misbehaving nodes"）。

### 1.2 PoW 与 PoS

**工作量证明**（Proof of Work，PoW）是比特币的基础，为**公有链**（public blockchain，任何人都能加入的区块链）设计（p7）。节点比赛解一道哈希难题，**哈希率**（hash rate，每秒能算多少次哈希，即算力）越高越可能先解出；先解出的节点把区块加到链上并拿奖励（p8）。在 PoW 里矿工既当提议区块的 leader，又当 validator（验证者：检查新区块是否合法的节点）。

获胜概率（p9）：

$$
P_{w_i}=\frac{\varphi_i}{\sum_{j=1}^{N}\varphi_j}
$$

$\varphi_i$ 是节点 $i$ 的算力，$N$ 是节点总数。每次哈希尝试都是独立的"抽奖"，单位时间里抽的次数和算力成正比，所以先中奖的概率就是算力占比。模拟卷 Q4(a)(i)（3 分）就是把这个式子倒过来用：四个节点算力 3、5、4、$x$，N1 胜率 20%，总算力 $=3/0.2=15$，$x=15-12=3$。规范答法见 [[L15 区块链共识 I#3.3 例题：求获胜概率与反求算力|L15 3.3]]。

PoW 的问题（p10）：存在**双花**（double spending，同一笔钱花两次）的风险；两个节点可能同时解出难题，造成**分叉**（fork，链在某个高度出现两个相互竞争的后继区块），所以 PoW 的**终局性**（finality，一笔交易一旦确认就不会被推翻）只是概率性的（p7 "consensus finality is not guaranteed"）；确认慢；耗电极大。容错性（p11）：会受 **51% 攻击**（掌握过半算力的人可以改写历史）；能容忍拜占庭故障，也能抵抗 **Sybil 攻击**（女巫攻击：恶意节点伪造大量假身份来左右投票，L15 原文的定义 "where malicious blockchain nodes create multiple pseudo identities"）。这两条"能"都以**诚实算力过半**为前提，和同页第一句的 51% 攻击是一回事的两面。

**权益证明**（Proof of Stake，PoS）按节点押上的币——**质押**（stake）——的多少选出记账者，押得越多越可能被选中（p12）。优点（p13）：**耗能少**；**对算力和硬件要求低**；每轮只生成一个区块，确认更快。模拟卷 Q4(a)(ii)（2 分）答前两条，规范答法见 [[L15 区块链共识 I#4.2 相对 PoW 的优点|L15 4.2]]。问题（p14–p16）：消息丢失或延迟会让节点拿不到最新账本；某些 PoS 变体要靠委员会（committee：从质押者中抽出、轮流负责出块和投票的一小组节点）成员之间及时通信，否则性能严重下降；奖励若总给质押最多的节点，就会富者愈富。

p17 是两张网页截图拼成的 PoW/PoS 对比表，要点：

| 方面 | PoW | PoS |
| --- | --- | --- |
| 谁记账 | 算力决定出块概率 | 质押量决定验证概率 |
| 竞争 | 矿工比拼算力解难题 | 由算法按质押大小定胜者 |
| 集中化 | 越来越适合大型矿场，趋于集中 | （原表此格是复制错误，见下） |
| 硬件 | ASIC（application-specific integrated circuit，专用集成电路）、GPU（graphics processing unit，图形处理器） | 普通服务器即可 |
| 作恶门槛 | 51% 算力 | 51% 的币 |
| 效率与可靠性 | 耗能高、花费高，但更可靠 | 省钱省电，可靠性较低 |
| 分叉 | 经济激励天然抑制分叉 | 不会自动抑制分叉 |

> [!note] p17 原表的两处错
> 原表 PoW 的"效率与可靠性"一格写 "less energy-efficient and **less expensive**"，和同行 PoS 的 "far more cost and energy-efficient" 自相矛盾，应为 more expensive，上表已按此改写；"集中化"一行的 PoS 格子原样抄了上一行"竞争"的文字，是截图时的复制错误，PoS 的集中化问题实际是 p16 讲的"质押越多越容易赢"。

### 1.3 吞吐量与确认时间

衡量共识的非功能指标有两类（p18）：**性能**（吞吐量、确认时间）与**可扩展性**。

**交易吞吐量**（transaction throughput）是网络每秒能处理的交易数，单位 Tx/s（Tx 是 transaction 的缩写）（p19–p20）：

$$
\text{Throughput}=\frac{\text{Block Size (Bytes)}}{\text{Transaction Size (Bytes)}\times\text{Block Time (s)}}
$$

拆开读：区块大小 ÷ 每笔交易大小 = 一个块装多少笔；再 ÷ **出块时间**（block time，平均多久出一个块）= 每秒多少笔。

**区块确认时间**（block confirmation time）是一个块从生成到被认为确认所需的时间（p21）：新块后面还要再接若干个块才算安全，所以

$$
\text{Confirmation Time}=\text{需等待的块数}\times\text{Block Time}
$$

**可扩展性**（scalability）指平台承受不断增长的交易量与节点数的能力（p22）；**链下方案**（off-chain solution）把大部分交易放到主链之外处理，如**侧链**（sidechain，与主链相连、可双向转移资产的另一条链）和**支付通道**（payment channel，双方在链下反复记账、最后只把结算结果上链）。

模拟卷 Q3(b)(iii)（3 分）：区块 6 MB、交易 80 B、出块时间 200 s、要等 20 个块确认。吞吐量 $=6\times10^6/(80\times200)=375$ Tx/s（课程把 1 MB 按 $10^6$ B 算），确认时间 $=20\times200=4000$ s。**参考答案写的 37.5 Tx/s 少了一个 0。** 规范答法和这条勘误见 [[L15 区块链共识 I#5.6 例题：课件 Q2 与模拟卷原题|L15 5.6]]。

### 1.4 从 PoW、PoS 到本讲：能不能直接数票

PoW 和 PoS 绕了一个弯：不让节点直接投票，而是按算力或质押"抽签"。原因是公有链里身份不值钱——开一个新节点几乎零成本，若"一节点一票"，攻击者用 Sybil 攻击开一万个假节点就赢了。算力和币伪造不出来，于是拿它们代替人头。（这条因果链课件没写，是把 L15 与本讲接起来的关键。）

本讲的三个协议走另一条路：**直接数票**——"多数同意就算数"。数票的前提是参与者名单固定、身份可确认，所以它们用在成员事先登记的场合：分布式数据库、云服务的配置中心，以及区块链里的**许可链**（permissioned blockchain，需经许可才能加入的私有链和联盟链，见 [[L12 区块链系统概览]]）。课件学习目标里的 "typical in communication network" 也是这个意思。

数票省掉了挖矿的算力浪费，也让终局性变成确定的：一旦决定就不会被推翻。代价是要回答一个 PoW 不必回答的问题——**到底要凑够多少票才算数**。这就是第 3 节的内容；在那之前，先把三个协议共同的目标讲清楚。

## 2 三个协议在解决同一个问题

### 2.1 复制状态机：把"一致"归结为"日志一致"

为了容错，同一份服务要在多台机器上各放一份，每一份叫一个**副本**（replica）。只要每台机器满足三点：

- 是一个**确定性的状态机**（deterministic state machine）：同样的状态、同样的命令，永远得到同样的新状态；
- 从同一个初始状态出发；
- 按**同样的顺序**执行**同样的命令序列**；

那么每个副本执行完同一段命令之后，状态都相同（进度快的副本只是先走到后面）。这种做法叫**复制状态机**（state machine replication，SMR），课件 p44 的 "state machine replication with a persistent log" 说的就是它。

顺序为什么要紧，看一个例子：账户余额 20 元，来了两条命令"存 100"和"取 30"。先存后取得 90；先取后存，取 30 时余额不足被拒，最后是 120。两台机器只是顺序不同，状态就分岔了。

所以问题归结为：大家维护一份按位置编号的**日志**（log，命令的有序列表），对"第 1 个位置放什么命令、第 2 个位置放什么……"逐个达成一致。区块链本身就是这样一份日志，区块的高度就是位置编号。三个协议的分工：

- Paxos 每运行一次，对**一个**值达成一致（p26 "consensus over a value"）；对日志的每个位置各跑一次，就得到整份日志；
- RAFT 直接以日志为中心设计；
- PBFT 给每个请求分配一个**序号**，序号就是日志位置。

每个节点内部因此由三部分组成。课件 p60 画的就是这个结构，下图按 p60 重画：

![[L16 复制状态机结构.png]]

*按课件 p60 重画，3 个节点，Node 1 是 leader；节点之间的 AppendEntries RPC 是 RAFT 的复制消息，见 [[#5.2 三种角色与任期|5.2]]。原图顶部发命令、收结果的电脑标着 "Leader"，按 p55 "The client sends commands/requests to the leader" 和 p58 "returns the result to the client"，它其实是客户端，此图已改正。*

- **共识模块**（consensus module）：和其他节点通信，决定日志的每个位置放什么——三个协议就是三种不同的共识模块；
- **日志**：按位置存命令（图中 "Append to log"）；
- **状态机**：按顺序执行已经达成一致的命令。

### 2.2 故障模型与网络模型

协议能防什么，取决于对"坏节点会做什么"和"网络有多不可靠"的假设。

**故障模型**。[[#1.1 共识、两类节点与两类故障|1.1]] 的崩溃与拜占庭是两头：Paxos 和 RAFT 只防崩溃，而且允许崩溃的节点**重启**后继续参加——这叫 crash-recovery（崩溃–恢复）模型。重启的节点必须记得崩溃前许下的承诺，所以关键状态要写进**稳定存储**（stable storage，断电不丢的硬盘一类存储），不能只放内存。PBFT 防拜占庭，坏节点干什么都行，只是假定它伪造不了别人的数字签名（只有本人能生成、任何人都能验证的电子签名）。

**网络模型**。按"消息多久能送到"分三种：

- **同步**（synchronous）：延迟有一个已知的上界，超过就可以断定对方坏了；
- **异步**（asynchronous）：延迟没有上界，消息可以任意晚到；
- **部分同步**（partially synchronous）：上界存在但事先不知道，或者网络乱一阵子之后才变得守时。

真实的互联网接近异步。异步带来一个根本困难：**收不到某个节点的回复时，分不清它是崩溃了还是只是慢**。这一点是下一节推导的起点。

更强的结论是 **FLP 不可能性定理**（以 Fischer、Lynch、Paterson 三位作者命名，1985）：在纯异步网络里，哪怕只有一个节点可能崩溃，也不存在一个总能在有限时间内做出决定的确定性共识算法。三个协议都不去硬碰这个定理，而是做同一个取舍，见下一小节。

### 2.3 安全性与活性

- **安全性**（safety）："坏事永远不发生"——同一个位置不会决定出两个不同的值，决定的值一定是有人提出过的。
- **活性**（liveness）："好事终究会发生"——协议最终能做出决定，不会永远卡住。

三个协议的共同设计：**安全性任何时候都保证，不依赖网络是否守时；活性只在网络一段时间内足够守时时才保证**，靠超时、重试、换 leader 往前推（Paxos 换一个更大的编号重试，RAFT 超时后重新选 leader，PBFT 换掉出问题的主节点）。网络最坏时，协议可能一直做不出决定，但绝不会做出两个矛盾的决定。下面讲每条规则时，都会说清它守的是安全性还是活性。

## 3 法定人数交集：2f+1 与 3f+1 从哪里来

### 3.1 两条约束

设一共 $N$ 个节点，其中至多 $f$ 个故障。协议每往前走一步，都要向大家发消息、收回应，凑够某个数目 $q$ 才继续。这样一组凑够数的回应者叫**法定人数**（quorum，原意是议会表决所需的最低出席人数），$q$ 是它的大小。后面三个协议里的"多数派""$2f+1$ 条一致的消息"都是 quorum。$q$ 取多少，被两条约束夹住。

**约束 ①（活性：不能等太多人）。** $f$ 个故障节点可能永远不回应；异步网络里又分不清"坏了"和"慢"，所以不能指望等到它们。若 $q>N-f$，故障节点集体沉默就能让协议永远卡住。于是

$$
q\le N-f \tag{1}
$$

**约束 ②（安全：任意两个 quorum 必须相交于至少一个诚实节点）。** 同一个位置上前后有两次决策，比如第一次已经由 quorum $Q_1$ 决定了 $x$，后来另一个提案者通过 quorum $Q_2$ 来问"这里该放什么"。如果 $Q_1$ 和 $Q_2$ 有一个共同的诚实成员，它会如实说出"我参与决定过 $x$"，第二次就不会决定成别的值。如果两者不相交，第二次根本听不到第一次；如果只交在撒谎的节点上，撒谎者可以对 $Q_1$ 说 $x$、对 $Q_2$ 说 $y$，交集形同虚设。两种情况下同一位置都可能出现两个决定，安全性就破了。

两个 quorum 至少相交多少？两个集合的元素总数减去并集的大小就是交集的大小，而并集最多是全体 $N$ 个节点：

$$
\lvert Q_1\cap Q_2\rvert=\lvert Q_1\rvert+\lvert Q_2\rvert-\lvert Q_1\cup Q_2\rvert\ \ge\ 2q-N \tag{2}
$$

这个下界取得到：把节点排成一排，$Q_1$ 取前 $q$ 个、$Q_2$ 取后 $q$ 个，交集正好是 $2q-N$ 个。协议必须对最坏情形也成立，所以只能按 $2q-N$ 算。

$q$ 越大交集越大，所以在约束 (1) 允许的范围内取最大的 $q=N-f$，代入 (2)，**最坏交集**为

$$
2(N-f)-N=N-2f \tag{3}
$$

剩下的问题只有一个：交集里至少要有几个节点，才能保证其中有一个诚实节点？这取决于故障节点会不会撒谎。

![[L16 法定人数交集.png]]

*左：崩溃模型 $N=3$，两个 2 人 quorum 交于节点 2。右：拜占庭模型 $N=4$，两个 3 人 quorum 交于节点 2、3，即使节点 2 是故障节点，节点 3 仍是诚实的。*

### 3.2 崩溃故障：N ≥ 2f+1

崩溃的节点不撒谎。交集里的节点对两次询问都回应过，说明它两次都活着，说的都是真话，并且凭稳定存储记得第一次的事。所以**交集非空就够**：由 (3)

$$
N-2f\ge1\quad\Longrightarrow\quad N\ge 2f+1
$$

此时 quorum 大小 $q=N-f=f+1$，正好是 $2f+1$ 个节点中的**多数**（超过一半）。这就是 Paxos "a majority represents the whole"（p26）和 p38 "to tolerate f faulty acceptors, at least … 2f + 1 acceptors" 的来历：任意两个多数派必然相交，而崩溃模型里相交就足够。

反过来读同一个不等式：$N$ 台机器最多容忍 $f=\lfloor (N-1)/2\rfloor$ 台崩溃（$\lfloor\cdot\rfloor$ 是向下取整）。3 台容 1 台，5 台容 2 台；4 台也只容 1 台，所以实际部署常用奇数台。

模拟卷 Q3(b)(iv)：$f=3$ 个崩溃节点，$N\ge2\times3+1=7$，最少合法节点 $=7-3=4$。

### 3.3 拜占庭故障：N ≥ 3f+1

拜占庭节点会撒谎，而且它们完全可能同时出现在两个 quorum 里（它们乐意回应每一次询问）。最坏情形下 $f$ 个故障节点全落在交集里。要让交集里扣掉它们之后还剩至少一个诚实节点，由 (3)

$$
N-2f-f\ge1\quad\Longrightarrow\quad N\ge 3f+1
$$

此时 quorum 大小 $q=N-f=2f+1$，两个 quorum 的交集 $=N-2f=f+1$，其中至多 $f$ 个故障，至少 1 个诚实。

PBFT 原论文（附读物 §3）用的是另一个说法，结论相同："it must be possible to proceed after communicating with $n-f$ replicas, since $f$ replicas might be faulty and not responding. However, it is possible that the $f$ replicas that did not respond are not faulty and, therefore, $f$ of those that responded might be faulty. Even so, there must still be enough responses that those from non-faulty replicas outnumber those from faulty ones, i.e., $n-2f>f$. Therefore $n>3f$." 逐句对应（论文的 $n$ 即本笔记的 $N$）：

1. 只能等 $N-f$ 个回应——约束 (1)；
2. 没回应的 $f$ 个可能恰好是诚实但慢的节点，于是 $f$ 个故障节点可能全在回应者里；
3. 回应者里的诚实者至少 $(N-f)-f=N-2f$ 个，必须比撒谎者多：$N-2f>f$；
4. $N>3f$，节点数是整数，即 $N\ge3f+1$。

两种推法得到同一个不等式 $N-2f\ge f+1$：交集的写法看"两个 quorum 之间"，论文的写法看"一个 quorum 内部"，背后是同一件事——拜占庭比崩溃多需要的那 $f$ 个节点，专门用来抵消混在回应里的撒谎者。

反过来读：$N$ 台机器最多容忍 $f=\lfloor (N-1)/3\rfloor$ 个拜占庭节点（论文 §1 的写法）。4 台容 1 个，7 台容 2 个，10 台容 3 个。

模拟卷 Q4(a)(iv)：$f=3$ 个拜占庭节点，$N\ge3\times3+1=10$，最少合法节点 $=10-3=7$。

### 3.4 只差一个节点就失败：两个反例

把节点数各减一，协议就能被构造出的情形击破。

![[L16 法定人数不够时的反例.png]]

*左：崩溃模型 $N=2f$。右：拜占庭模型 $N=3f$。都取 $f=1$。*

**崩溃模型，$N=2f$。** 取 $f=1$、$N=2$，quorum $=N-f=1$。A 和 B 之间的网络断了（或消息无限延迟）。A 收不到 B 的消息，分不清 B 是崩溃还是慢，按规则只能凭自己一票往下走，决定 $x$；B 同理决定 $y$。两个 quorum $\{A\}$、$\{B\}$ 不相交，两个诚实节点决定了不同的值。一般地，$N=2f$ 时把节点分成各 $f$ 个的两半，每一半都恰好是一个 quorum，彼此隔开就各决各的。若想避免，就得把 quorum 提到 $f+1$，可那违反约束 (1)：$f$ 个节点一沉默，协议就卡死。

**拜占庭模型，$N=3f$。** 取 $f=1$、$N=3$，quorum $=2$。A、B 诚实，C 是故障节点；A 倾向 $x$，B 倾向 $y$，A、B 之间的消息被拖延。C 对 A 说"我投 $x$"，对 B 说"我投 $y$"。A 看到 $\{A,C\}$ 两票支持 $x$，凑够 quorum，决定 $x$；B 看到 $\{B,C\}$ 两票支持 $y$，决定 $y$。两个 quorum 只交于撒谎的 C，安全性被破坏。一般地，$N=3f$ 时把 $2f$ 个诚实节点分成各 $f$ 个的两组 $H_1$、$H_2$，$f$ 个故障节点记为 $F$：$H_1\cup F$ 和 $H_2\cup F$ 各有 $2f$ 个，都是 quorum，交集正好是 $F$，里面一个诚实节点都没有。

| $f$ | 崩溃：$N_{\min}=2f+1$ | 崩溃 quorum $f+1$ | 拜占庭：$N_{\min}=3f+1$ | 拜占庭 quorum $2f+1$ | 拜占庭：两 quorum 交集（其中诚实 ≥） | 拜占庭只有 $N=3f$ 时：交集中诚实 ≥ |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 3 | 2 | 4 | 3 | 2（1） | 0 |
| 2 | 5 | 3 | 7 | 5 | 3（1） | 0 |
| 3 | 7 | 4 | 10 | 7 | 4（1） | 0 |

（表中交集都是最坏情形，已对 $N\le10$ 枚举全部 quorum 对核对过。）

### 3.5 考场写法

模拟卷两题各 3 分，参考答案只写了一行不等式（2 分）和减法（1 分），题面却要求 "the derivation should be provided"。先看最容易丢分的地方：

> [!warning] 这两题的三个常见错
> - 题目问的是 **legitimate nodes**（合法节点），答成总数 7 或 10 就丢 1 分，要再减去 $f$。
> - 把拜占庭模型的 quorum 也写成"多数"（$f+1$）。多数只够防崩溃；拜占庭要 $2f+1$。
> - 写成 $N>2f+1$ 或 $N>3f+1$。正确是 $N\ge2f+1$、$N\ge3f+1$（等价于 $N>2f$、$N>3f$）。

规范答法是把推导写成四行再给数，英文可以照写：

> [!example]- Q3(b)(iv) 与 Q4(a)(iv) 的规范答法
> **Q3(b)(iv)**："If there are 3 crash-failure nodes participating in a distributed consensus process, calculate the minimum number of legitimate nodes to achieve crash-failure tolerance (the derivation should be provided)."
> 1. Let $N$ be the total number of nodes and $f$ the number of faulty nodes. Since $f$ nodes may never respond, each step can wait for at most $N-f$ replies (quorum $q=N-f$).
> 2. Any two quorums overlap in at least $2(N-f)-N=N-2f$ nodes. Crashed nodes do not lie, so a non-empty overlap is enough: $N-2f\ge1$, i.e. $N\ge2f+1$.
> 3. With $f=3$: $N\ge2\times3+1=7$.
> 4. Minimum number of legitimate nodes $=7-3=4$.
>
> **Q4(a)(iv)**："If there are 3 Byzantine attackers participating in a distributed consensus process, calculate the minimum number of legitimate nodes to achieve Byzantine attack tolerance (derivations should be provided)."
> 1. Each step can wait for at most $N-f$ replies, because $f$ nodes may not respond.
> 2. Among these $N-f$ replies, up to $f$ may come from Byzantine nodes (the silent ones may be honest but slow), so honest replies $\ge N-2f$. Honest replies must outnumber faulty ones: $N-2f>f$, i.e. $N\ge3f+1$. (Equivalently: two quorums of $N-f$ overlap in $N-2f$ nodes, and at least one of them must be honest: $N-2f\ge f+1$.)
> 3. With $f=3$: $N\ge3\times3+1=10$.
> 4. Minimum number of legitimate nodes $=10-3=7$.

## 4 Paxos

### 4.1 主思想与适用场景

Paxos 是"最基础的分布式共识算法，允许在不可靠的通信下对**一个值**达成共识"（p26）。下文的"原文"指 Lamport 2001 年的《Paxos Made Simple》，它用十几页讲完了本讲的 Paxos。核心思想是课件红字的 "**a majority represents the whole** — if more than half of processes choose a value, that value is the consensus"：过半数选定的值就是共识。这句话成立的理由正是 [[#3.2 崩溃故障：N ≥ 2f+1|3.2]]：任意两个多数派必相交，后来的多数派总能从交集里得知先前的决定。

适用场景（p27）：

- 网络里的消息可以**延迟、丢失、乱序、重复，但不会被篡改**（"not corrupted"）；
- 节点按**停止故障**（fail-stop）的方式失效：可以停下、可以重启，但不作恶（"not present Byzantine faults"）。

所以 Paxos 是**崩溃容错**（crash fault tolerant，CFT）的协议。（"fail-stop"在文献里严格指"停下且能被别人察觉"，Paxos 实际用的是可重启的 crash-recovery 模型，课件用得宽松，不影响结论。）

### 4.2 三种角色

运行 Paxos 的节点可以担任三种角色，一个进程可以同时担任全部三种（p28）：

- **提案者**（proposer）：提出待决定的值，处理客户端请求。课件红字："An elected proposer acts as a single leader to propose a new value."——通常选出一个 proposer 当唯一的 leader，原因见 [[#4.8 选一个 leader：为了活性|4.8]]。
- **接受者**（acceptor）：按一组规则评估 proposer 的提案，接受或拒绝。它们就是投票人，quorum 由它们组成。
- **学习者**（learner）：得知最终决定的值（"the agreed-upon value"），比如把它执行、返回给客户端。

每个 acceptor 只需记住两样东西，下面的规则全是围绕它们写的：

- 它**承诺过的最大编号**（还没承诺过时为空）；
- 它**接受过的编号最高的提案** $(n_a,v_a)$（还没接受过时为空；为什么一定是编号最高的那个，见 [[#4.5 Phase 2：accept|4.5]]）。

### 4.3 提案编号

**提案**（proposal）是一对 $(n,v)$：编号 $n$ 加值 $v$。**提案编号**（proposal number）$n$ 的要求（p32 红字）：

- **全局唯一**：任何两个 proposer 都不会用同一个编号；
- **比这个 proposer 以前用过的都大**；
- 课件举例："n can be a timestamp in nanoseconds or some other incrementing value"。

原文只要求各 proposer 从**互不相交**的数集里取号。一种常见做法是：有 $P$ 个 proposer 时，编号 $i$ 的 proposer 只用 $n=kP+i$（$k=0,1,2,\dots$）。比如 3 个 proposer，P0 用 0、3、6…，P1 用 1、4、7…，永不撞号。proposer 还要把用过的最大编号写进稳定存储，重启后不会倒退。

编号的作用是给提案排先后，好让"更新的提案"有一个明确的含义。为什么非唯一不可，见 [[#4.7 每条规则为什么必要：两个提案者的例子|4.7]]。

### 4.4 Phase 1：prepare

协议分两个阶段（p30）。课件对两阶段结束时的状态描述是：

- prepare 阶段结束时："A majority of acceptors have promised a specific **proposal number**."
- accept 阶段结束时："A majority of acceptors have **accepted a proposed value**, and consensus is reached."

第一阶段还**不提值**（p32 "At this stage, no value is proposed for a decision yet"），只做一件事：proposer 用编号 $n$ 向多数 acceptor "占位"，同时打听它们以前接受过什么。

**proposer 一侧**（p31 step 1–2，p32）：

1. 收到客户端请求，要就某个值达成共识。
2. 选一个新编号 $n$，向**多数或全部** acceptor 发 **prepare($n$)**。发给多数就够——前提是多数里的每一个都会回应；如果等不到回应而超时，就**换一个更大的 $n$ 重试**（p32 "If a timeout occurs, then the proposer will retry with a higher n"）。

**acceptor 一侧**（p31 step 3，p33–34）：收到 prepare($n$) 后，按它此前的状态分情况：

| 情况 | 出处 | acceptor 的做法 |
| --- | --- | --- |
| ① 从没承诺过任何编号 | p33 | 承诺"忽略任何编号小于 $n$ 的请求"，记下 $n$，回 **promise($n$)** |
| ② 承诺过更小的编号，还没接受过任何值 | p34 1) | 把记下的编号更新为 $n$，回 promise($n$) |
| ③ 承诺过更小的编号，且已接受过提案 | p34 2) | 更新为 $n$，回 promise($n$)，并把自己接受过的**编号最高的**完整提案 $(n_a,v_a)$ 一并带回（"full proposal"） |
| ④ $n$ 不大于它已承诺的编号 | 课件漏写 | **忽略**（也可以回一个拒绝，让 proposer 早点换更大的编号） |

四种情况合成一条规则（Lamport 原文 Phase 1(b)）：**若 $n$ 大于自己承诺过的所有编号，就承诺不再接受编号小于 $n$ 的提案，并回报自己接受过的编号最高的提案（如果有）；否则不予理会。**

> [!warning] 课件 p33–34 漏了第 ④ 种情况
> 课件只讨论了"没承诺过"和"承诺过**更小**编号"两种前提，没说收到的编号**不大于**已承诺编号时怎么办。答案是忽略：这正是 ① 里许下的承诺"ignore any request less than the proposal number n"的兑现，没有它，承诺就是空话（后果见 [[#4.7 每条规则为什么必要：两个提案者的例子|4.7]] 的第 ④ 步之后）。
> 考场写法：照课件写 ①②③，再补一句 "If $n$ is not greater than the number it has already promised, the acceptor ignores the request (or replies with a rejection)."——不和课件冲突，又补全了规则。

### 4.5 Phase 2：accept

**proposer 一侧**（p35 step 1–2，p36 step 3，p40）：

1. **等多数 acceptor 回 promise($n$)**（p35 "waits until it gets responses from the majority of the acceptors"）。
2. **选值**（p40）：
   - 若收到的 promise 里有一个或多个带回了完整提案，就选其中**编号最高**的那个提案的值；
   - 若没有一个 promise 带回提案，proposer 可以**任意选值**（通常就是客户端请求的值）。
3. 向 acceptor 发 **accept($n$, $v$)**——一个完整提案，$n$ 是刚被承诺的编号，$v$ 是第 2 步选出的值（p36）。

**acceptor 一侧**（p37 step 4，p41）：收到 accept($n$, $v$) 后，

1. 若它承诺过不接受这个编号（即已对比 $n$ 更大的编号回过 promise），就**忽略**；
2. 否则**接受**：把承诺编号提到 $n$，把 $(n,v)$ 记为已接受的提案，回 **accepted($n$, $v$)**；
3. 并把 accepted($n$, $v$) 发给**所有 learner**。

第 2 步"把承诺编号提到 $n$"让 acceptor 接受的编号只增不减：接受 $(n,v)$ 之后，编号比 $n$ 小的 accept 都会被第 1 步挡掉。于是它记下的永远是自己接受过的**编号最高**的提案，Phase 1 回报的也正是这一个。

**决定**（p37 step 5）：只要**多数** acceptor 接受了同一个提案 $(n,v)$，$v$ 就成为协议的决定值，共识达成。注意"被决定"是一个客观事实，发生在第多数个 acceptor 接受的那一刻，那时可能还没有任何人知道；proposer 和 learner 是之后通过 accepted 消息才得知的。

> [!warning] 课件 p41 的接受条件比 Lamport 原文严
> 课件 p41 2) 写的是："if it has responded to the corresponding prepare request with the **same n**, that is, prepare(n), only then it replies with accepted(n, v)"——只有对 prepare($n$) 回过 promise 的 acceptor 才接受。
> Lamport 原文 Phase 2(b)："it accepts the proposal **unless** it has already responded to a prepare request having a number **greater than** n"——只要没对**更大**的编号承诺过就接受，并不要求收到过 prepare($n$)。
> 两者的差别只在一种情形：某个 acceptor 的 prepare($n$) 丢了，却收到了 accept($n$, $v$)。原文接受，课件拒绝。拒绝不会破坏安全性（少一票而已），只是可能让本该成功的一轮失败、多重试一次，所以课件版本是"安全但保守"。
> 用原文规则时，"接受时把承诺编号提到 $n$"这一步不能省（等价的说法：已接受的记录只被编号更高的提案替换）。否则 acceptor 可能先接受 $(2,y)$、再接受迟到的 $(1,x)$，记录退回旧提案。反例，3 个 acceptor A、B、C：
> 1. P1 用编号 1 拿到 B、C 的 promise，发出 accept(1, $x$)，消息还在路上；
> 2. P2 用编号 2 拿到 B、C 的 promise，发 accept(2, $y$)，A、B 接受——**$y$ 已决定**；
> 3. 迟到的 accept(1, $x$) 到达 A。A 从没回过任何 prepare，只看"没对更大编号承诺过"它会接受；若再用 $(1,x)$ 覆盖记录，A 记下的就退回旧提案；
> 4. P3 用编号 3 向 A、C 发 prepare：A 带回 $(1,x)$，C 没接受过任何提案，P3 只能选 $x$；
> 5. A、C 接受 $(3,x)$——**$x$ 也被决定**。
>
> 第 2 步 A 接受 $(2,y)$ 时若把承诺提到 2，第 3 步就会忽略迟到的 accept(1, $x$)，反例不成立。课件的严格版本恰好避开了这个坑：它只接受对 prepare($n$) 回过 promise 的提案，接受时承诺编号已经是 $n$，接受的编号自然只增不减。
> 考场写法："The acceptor accepts $(n,v)$ unless it has already promised a proposal number greater than $n$, and on accepting it raises its promised number to $n$ — in a normal run this is exactly the acceptor that replied promise($n$)." 前半句是原文的规则，后半句点出课件描述的正常情形，两边都不违背。

### 4.6 learn 与时序图

学习是第二阶段的一部分（p39 "The learning is considered part of the second phase"）：acceptor 一接受提案，就通知 learner。p42 的时序图把它画成单独的第三段 "Learn"，课件说明这只是为了直观（"just for visualizing the protocol in a simpler way; learning is in fact part of phase 2"）。

下图按课件的角色重画了一次正常运行，并让 Acceptor 3 中途崩溃，以显示"等多数、不等全部"：

![[L16 Paxos 正常流程.png]]

*$f=1$，3 个 acceptor $=2f+1$，多数 $=f+1=2$。蓝 = proposer 发出的请求，绿 = acceptor 的回应，紫 = 发给 learner 的通知。*

按时间读：

1. 客户端把值 $v$ 交给 proposer。
2. **Phase 1**：proposer 发 prepare($n$) 给三个 acceptor。Acceptor 3 已崩溃，收不到。Acceptor 1、2 都没承诺过更大编号，各自记下 $n$，回 promise($n$)，附上"没接受过任何提案"。
3. proposer 收到 2 个 promise——3 个中的多数——不再等 Acceptor 3，进入 Phase 2。
4. **Phase 2**：两个 promise 都没带回已接受的提案，proposer 用客户端的 $v$，发 accept($n$, $v$)。
5. Acceptor 1、2 都没对比 $n$ 更大的编号承诺过，接受 $(n,v)$。第 2 个 acceptor 接受的瞬间（图中★），$v$ 已被多数接受，**已经决定**。
6. 两个 acceptor 各把 accepted($n$, $v$) 发给 proposer 和两个 learner。每个 learner 收到 2 个 acceptor 对同一提案的 accepted，就知道 $v$ 已被决定。

> [!warning] 课件 p42 图上的 "Wait for majority 2f+1"
> 图上两条虚线旁各标 "Wait for majority 2f+1"，容易读成"要等 $2f+1$ 个回复"。正确的意思是"**在 $2f+1$ 个 acceptor 中等到多数**"，即等 $f+1$ 个回复。若真要等齐 $2f+1$ 个，任何一个 acceptor 崩溃协议就卡死，和 p38 "tolerate f faulty acceptors" 的目的正相反。课件自己的 p35 正文写的也是 "waits until it gets responses from the majority of the acceptors"。原图三个 acceptor 都回应，只是画了没有故障的情形。
> 考场写法："The proposer waits for replies from a majority, i.e. $f+1$ out of the $2f+1$ acceptors."

（课件外：Lamport 还给了一种省消息的做法，acceptor 只通知一个"指定 learner"，由它转告其他 learner；消息少了，但多一跳延迟，而且这个指定 learner 成了单点故障。）

### 4.7 每条规则为什么必要：两个提案者的例子

只有一个 proposer、网络良好时，上面的规则看起来多余。规则的用处在于多个 proposer 并发、消息丢失时仍保证只决定一个值。下面的例子（课件外，自拟）有 3 个 acceptor A1–A3（多数 = 2）和两个 proposer P1、P2：

![[L16 Paxos 两个提案者.png]]

*上方标号 ①–⑥ 与下表的步骤一一对应；× 表示消息丢失，★ 表示该 acceptor 接受 $(2,y)$。*

| 步 | 发生了什么 | 各 acceptor 的状态（承诺编号；已接受提案） |
| --- | --- | --- |
| ① | P1 发 prepare(1)，三个 acceptor 都回 promise(1, 无) | A1、A2、A3：1；无 |
| ② | P1 发 accept(1, $x$)，只有 A1 收到，发给 A2、A3 的丢了 | A1：1；$(1,x)$。A2、A3 不变。$x$ 只有 1 票，**没有被决定** |
| ③ | P2 发 prepare(2) 给 A2、A3，两者回 promise(2, 无) | A2、A3：2；无 |
| ④ | P2 没收到任何已接受提案，可任意选值，选 $y$，发 accept(2, $y$)，A2、A3 都接受 | A2、A3：2；$(2,y)$。**$y$ 被多数接受，已决定** |
| ⑤ | P1 等不到结果，超时，用更大编号发 prepare(3) 给 A1、A2 | A1 回 promise(3, $(1,x)$)；A2 回 promise(3, $(2,y)$)。两者承诺编号都变成 3 |
| ⑥ | P1 必须取编号最高的已接受提案：2 > 1，只能用 $y$，发 accept(3, $y$)，A1、A2 接受 | A1、A2：3；$(3,y)$。A3：2；$(2,y)$。**决定仍是 $y$** |

逐条拿掉规则，看哪一步会出事：

- **拿掉"凑够多数"。** 若一个 acceptor 接受就算决定，第 ② 步 $x$ 就因 A1 一票被决定，第 ④ 步 $y$ 又被决定。多数的意义就是让 ⑤ 的多数派 $\{A1,A2\}$ 与 ④ 的多数派 $\{A2,A3\}$ 必然相交——这里交于 A2，是 A2 把 $y$ 带了回来。这就是 [[#3.1 两条约束|约束 ②]] 在 Paxos 里的样子。
- **拿掉 promise 的"忽略更小编号"。** 设想第 ④ 步之后，P1 在第 ② 步发给 A2 的那条 accept(1, $x$) 其实没丢，只是晚到了。A2 已承诺 2，按规则忽略它。若没有这条承诺，A2 会改为接受 $(1,x)$，于是 $\{A1,A2\}$ 都接受了 $(1,x)$，$x$ 也成了"多数接受"的值，和已决定的 $y$ 冲突。Phase 1 的承诺，就是让旧编号的提案在新的多数派面前作废。
- **拿掉"带回已接受提案、取编号最高的值"。** 第 ⑥ 步 P1 若坚持用自己的 $x$，A1、A2 接受 $(3,x)$，$x$ 被多数接受——在 $y$ 之后又决定了 $x$。
- **为什么是"编号最高"而不是"随便一个"。** 第 ⑤ 步 P1 同时看到 $(1,x)$ 和 $(2,y)$。$x$ 是过时的（从没被决定），$y$ 是可能已被决定的。编号越高的提案越新；能被决定的只可能是最新的那个，理由见下面的折叠块。
- **为什么编号必须全局唯一。** 唯一性保证"编号为 $n$ 的提案"只对应一个值（proposer 对一个编号只发一个值），下面折叠证明的第 5 步就靠这一点。按 [[#4.4 Phase 1：prepare|4.4]] 的严格规则（$n$ 必须**大于**已承诺编号才回 promise），两个 proposer 撞号时，两个多数派的公共 acceptor 只会给其中一个回 promise，单靠撞号还出不了两个决定；但只要实现上对**相等**的编号也回 promise（比如为了容忍重传的 prepare），P1、P2 就能用同一个编号 2 各凑到一个多数派，各自让多数接受 $(2,x)$ 和 $(2,y)$，同一编号决定了两个值。
- **为什么 acceptor 要写稳定存储。** 若 A2 在第 ④ 步后崩溃重启、忘了自己承诺过 2 并接受过 $(2,y)$，第 ⑤ 步它会回"无"，P1 就可能选 $x$。

> [!example]- 为什么"取编号最高的值"保证不会推翻已决定的值（Lamport 论证的梗概，课件外）
> 设值 $v$ 已以编号 $m$ 被决定，即某个多数派 $S$ 都接受了 $(m,v)$。要证：此后任何编号 $n>m$ 的提案，值都是 $v$。对 $n$ 从小到大归纳：
> 1. 编号 $n$ 的提案要发出，proposer 必须先拿到某个多数派 $T$ 的 promise($n$)。
> 2. $S$ 与 $T$ 都是多数派，必相交（[[#3.2 崩溃故障：N ≥ 2f+1|3.2]]），设交点为 A。
> 3. A 接受 $(m,v)$ 发生在回 promise($n$) 之前：否则 A 已承诺 $n>m$，会忽略 accept($m$, $v$)。A 回 promise($n$) 时报告的是它接受过的**编号最高的**提案，而它接受过 $(m,v)$，所以报告的编号至少是 $m$。
> 4. 于是 $T$ 带回的提案里，编号最高的那个编号 $k$ 满足 $m\le k<n$。
> 5. $k=m$ 时，那个提案就是 $(m,v)$（同一编号只对应一个值，因为编号唯一、proposer 对一个编号只发一个值）；$m<k<n$ 时，由归纳假设，编号为 $k$ 的提案值也是 $v$。
> 6. proposer 取编号最高者的值，所以编号 $n$ 的提案值是 $v$。
>
> 这正是 Lamport 所说的不变式 P2c："either no acceptor in $S$ has accepted any proposal numbered less than $n$, or $v$ is the value of the highest-numbered proposal among all proposals numbered less than $n$ accepted by the acceptors in $S$."

### 4.8 选一个 leader：为了活性

上面的规则保证了安全性，却不保证一定能做出决定。两个 proposer 可能这样互相拆台：P1 prepare(1) 成功 → P2 prepare(2) 成功，使 P1 的 accept(1, ·) 被拒 → P1 用 prepare(3) 重试，又使 P2 的 accept(2, ·) 被拒 → P2 用 prepare(4) 重试……永远在抢编号，谁也走不到 accept。这种"大家都在动、却没有进展"的状态叫**活锁**（livelock）。

解决办法就是 p29 的红字："**An elected proposer acts as a single leader**"——选出一个 proposer 作为唯一提案者（Lamport 称为 distinguished proposer）。选 leader 是为了**活性**，不是安全性所必需：就算一时选出了两个 leader，上面的规则仍保证不会决定两个值，最多是慢。选 leader 本身要靠超时判断旧 leader 是否还活着，这就依赖网络"足够守时"——和 [[#2.3 安全性与活性|2.3]] 的取舍一致。

（课件外：leader 稳定时，后续每个日志位置的 Phase 1 可以合并成一次提前做完，每个位置只走 Phase 2，这叫 Multi-Paxos，是 Paxos 的实用形态。RAFT 的"强 leader"思路就是从这里来的。）

### 4.9 考场答法：Paxos 的节点与阶段

模拟卷 Q4(a)(iii) 的规范答法只放在这里，[[L17 区块链共识 III]] 不再另写。

> [!example]- 模拟卷 Q4(a)(iii) 规范答法（5 分）
> 题面："Paxos is a fundamental consensus mechanism in distributed systems to reach an agreement by using a broadcast way. Explain the main process of Paxos, including the nodes and phases."
> 参考答案只写了 "refer to the slides in lecture 16"。按 5 个得分点组织：
> 1. **Setting and idea.** Paxos reaches consensus on a single value over an unreliable network: messages may be delayed, lost, out of order or duplicated, but not corrupted; nodes may crash and restart but are not Byzantine. A majority represents the whole: any two majorities intersect, so to tolerate $f$ faulty acceptors, $2f+1$ acceptors are needed.
> 2. **Nodes (roles).** Proposer: receives client requests and proposes values; usually one elected proposer acts as the leader. Acceptor: promises / accepts or rejects proposals according to the rules. Learner: learns the decided value. One process may play all three roles.
> 3. **Phase 1 (prepare).** The proposer chooses a globally unique proposal number $n$, larger than any it has used, and sends prepare($n$) to a majority (or all) of the acceptors. If $n$ is greater than any number the acceptor has promised, it promises to ignore proposals numbered less than $n$, records $n$ and replies promise($n$), attaching the highest-numbered proposal $(n',v')$ it has accepted, if any; otherwise it ignores the request. If it times out, the proposer retries with a higher $n$.
> 4. **Phase 2 (accept).** After receiving promises from a majority ($f+1$ of the $2f+1$ acceptors), the proposer picks $v$: the value of the highest-numbered proposal reported in the promises, or any value (e.g. the client's) if none was reported. It sends accept($n$, $v$). An acceptor accepts unless it has promised a higher number, raises its promised number to $n$ (normally it is one that replied promise($n$)), and replies accepted($n$, $v$).
> 5. **Decision and learning.** Once a majority of acceptors have accepted $(n,v)$, $v$ is decided. Each acceptor sends accepted($n$, $v$) to all learners; learning is part of phase 2 (drawn as a separate learn phase only for visualisation).
>
> 时间够就画一张 [[#4.6 learn 与时序图|4.6]] 那样的时序图（Proposer、3 个 Acceptor、2 个 Learner，prepare / promise / accept / accepted / learn 五种箭头），图比文字更快拿到"phases"的分。

## 5 RAFT

### 5.1 主思想与运行前提

RAFT 的卖点是"好懂、好实现"（p44 "RAFT is easy to understand and easy to implement"）。原论文的标题就叫《In Search of an Understandable Consensus Algorithm》（Ongaro 与 Ousterhout，2014）：Paxos 以难懂著称，RAFT 把共识拆成几块相对独立的问题来讲。

课件说 RAFT 是 "Replicated And Fault Tolerant" 的缩写。原论文通篇写作 Raft，并没有说它是缩写；作者事后解释过，名字取义于 reliable、replicated、redundant、fault-tolerant，又借了"用日志（log）扎木筏（raft）"和"逃离 Paxos 岛"两层双关。考试若问全称，写课件的说法。

核心思想（p44）：用一份**持久化的日志**实现[[#2.1 复制状态机：把"一致"归结为"日志一致"|复制状态机]]。p45 另提了两个能力：

- **集群成员变更**（cluster reconfiguration）：不停服务就能增删节点。原论文的做法是两阶段切换：过渡期里新旧两套成员配置要各自凑够多数，保证切换期间不会出现两个 leader；
- **日志压缩**（log compaction）：日志越长越占空间、节点崩溃后重放越慢，于是定期把当前状态存成**快照**（snapshot），丢掉快照之前的日志。

运行前提（p46）：

- 没有拜占庭故障（"No Byzantine failures"）；
- 网络通信不可靠（丢包、延迟、乱序、重复都可以）；
- 通信和处理器都是异步的。

第一条决定了 RAFT 也是崩溃容错协议，模拟卷 Q4(a)(v) 后半问就在这里（[[#5.6 RAFT 不能抵抗拜占庭故障|5.6]]）。第三条的"异步"只对安全性成立：RAFT 的安全不靠时钟，但要往前走就得靠超时——收不到 leader 的消息就重新选举。没有超时，leader 一崩溃协议就永远停住，这正是 [[#2.3 安全性与活性|2.3]] 的取舍。

### 5.2 三种角色与任期

节点（更准确地说，节点里的共识模块）在 RAFT **集群**（cluster，一组共同提供服务的服务器）中可处于三种角色之一（p47–48）：

- **Leader**（领导者）：接收客户端请求，管理日志复制，负责与 follower 通信。同一时刻正常情况下只有一个。
- **Follower**（跟随者）：被动的——只回应 **RPC**（Remote Procedure Call，远程过程调用：一台机器像调用本地函数一样请求另一台机器执行某个操作并返回结果），自己从不主动发起通信。客户端若把请求发给了 follower，follower 会告诉它谁是 leader，让它改发过去。
- **Candidate**（候选者）：想当 leader、正在拉票的节点所处的角色。

RAFT 的基本算法只用两种 RPC：**RequestVote**（candidate 拉票）和 **AppendEntries**（leader 追加日志；不带日志条目的 AppendEntries 就是**心跳**（heartbeat），用来告诉大家"leader 还活着"）。日志压缩另有第三种 RPC（InstallSnapshot），给落后太多的节点直接发快照。

时间被划分成一段段**任期**（term），用连续整数编号。每个任期从一次选举开始，**一个任期内至多一个 leader**。任期号充当逻辑时钟：每条 RPC 都带着发送者的任期号，节点一旦看到比自己大的任期号，立刻更新自己的任期并退回 follower；收到任期号比自己小的请求则直接拒绝。（任期的规则课件只在图里提到，详见原论文 §5.1。）

例：leader A 在任期 3 期间网络断开，其余节点选出任期 4 的 leader B。A 恢复后还以为自己是 leader，发出带任期 3 的 AppendEntries，收到的节点一律拒绝，并在回复里带上任期 4；A 一看到更大的任期号就下台成 follower。过期的 leader 一露面就被识破，所以不会出现两个 leader 同时被大家听从的情形。

三种角色之间的转换（p49，与原论文 Figure 4 对应）：

![[L16 RAFT 三种状态的转换.png]]

*课件 p49 原图。*

逐条箭头：

- **启动 → Follower**："Node starts up"，所有节点都以 follower 身份启动。
- **Follower → Candidate**：一段时间没有收到 leader 的消息（选举超时），认为 leader 已失效，发起新选举。
- **Candidate 自环**：本轮选举超时还没结果，开始新任期，再给自己投一票。
- **Candidate → Leader**：收到多数票。
- **Candidate → Follower**：发现了当前任期的合法 leader，或者看到了更大的任期号。
- **Leader → Follower**：发现任期号更大的节点，退位。原图写 "If a leader with higher term number discovered"，原论文是 "discovers **server** with higher term"——收到任何带更大任期号的请求或回复都要退位，不一定来自另一个 leader。

图里**没有** Follower 直接到 Leader 的箭头：想当 leader 必须先当 candidate 拉票。

### 5.3 选主

课件说 RAFT 由两个阶段组成（p50）：第一个是**选主**（leader election），第二个是**日志复制**（log replication）。原论文另把"安全性"列为第三个子问题，即 [[#5.5 为什么按本任期多数提交就安全（课件外）|5.5]] 的选举限制。

课件说选主"用心跳机制触发"（p51 "a heartbeat mechanism is used to trigger a leader election process"）。准确的因果是：leader 定期发心跳**压住**选举，follower 收不到心跳才发起选举。课件的四步（p51–53）：

1. 所有节点以 follower 身份启动。
2. 只要持续收到 leader 或 candidate 的有效 RPC，follower 就一直当 follower。
3. 若 follower 一段时间收不到心跳，就发生**选举超时**（election timeout），它认为 leader 已失效，转为 candidate，发起选举。（L17 把 "heartbeats" 改成了 "AppendEntries RPC"，两种写法是一回事。）
4. 拿到**多数节点**的票，就成为 leader，其余节点为 follower。若没人胜出、选举又超时，就以新任期重新选举。

p54 的流程图是 candidate 一侧的循环：

![[L16 RAFT 选举流程.png]]

*课件 p54 原图。*

从上往下读：转为 candidate → 当前任期号加 1、给自己投一票 → 向其他节点发 RequestVote 拉票 → 判断：拿到多数票（Yes）则成为 leader 并开始发心跳；超时（Timeout）则回到"任期号加 1、自投一票"；收到某个 leader 的心跳则变回 follower。

下图是一次完整的换届（5 台服务器，多数 = 3）：

![[L16 RAFT 选主过程.png]]

*5 台服务器，多数 = 3。灰 = 心跳，蓝 = RequestVote，绿 = 投票。S2、S4 判断"S3 的日志不比自己旧"用的是选举限制，见 [[#5.5 为什么按本任期多数提交就安全（课件外）|5.5]]。*

1. 任期 1 里 S1 是 leader，定期发心跳；收到心跳的 follower 重置计时器。
2. S1 崩溃，心跳停止，每个 follower 的选举计时器都在走。
3. S3 的计时器最短，最先超时：转为 candidate，任期号 1 → 2，先投自己一票，向其余 4 台发 RequestVote(term = 2, …)。
4. S2、S4 在任期 2 里还没投过票，同意投给 S3。加上自投的一票共 3 票，达到 5 台的多数，S3 当选。S5 的票晚到，已经不需要。
5. S3 立刻向所有节点发心跳，宣告自己是任期 2 的 leader，压住其他人的计时器。

每一步为什么必要：

- **每台服务器每个任期最多投一票**（先到先得）。两个 candidate 若在同一任期都拿到多数票，两个多数派必有一个公共投票者，它就投了两次——不可能。所以**一个任期至多一个 leader**。这又是 [[#3.2 崩溃故障：N ≥ 2f+1|多数派交集]]。
- **选举超时取随机值**（原论文示例 150–300 ms）。若大家的超时都一样，就会同时变成 candidate、各投自己、平票，下一轮又同时超时……随机化让总有一个最先醒来，在别人醒来前拿到多数。
- **任期号加 1**：新 leader 的任期比旧 leader 大，旧 leader 恢复后一收到新任期的消息就会退位，不会出现两个 leader 各管各的。
- **心跳**：让 follower 知道 leader 还在，防止无谓的选举。

candidate 的三种结局（原论文 §5.2）：拿到多数票当选；收到任期不小于自己的 leader 的 AppendEntries，退回 follower；平票无人当选，超时后任期加 1 重选。课件文字讲了第一和第三种，第二种在 p49、p54 的图里。

### 5.4 日志复制

日志复制按课件 p55–58 进行。p55 的第 1 条 "The log replication phase of RAFT is straightforward" 只是引子，实际步骤是后五条（编号沿用课件）：

2. 客户端把要由复制状态机执行的命令发给 leader。
3. leader 给命令分配**任期号和索引**（term and index），使它在所有节点的日志里能被唯一识别，并追加到自己的日志。**日志索引**（log index）就是日志里的位置编号。
4. leader 一有新条目，就同时通过 AppendEntries RPC 发给各 follower，请它们复制这条命令。
5. 当命令被复制到多数节点并得到确认，这个条目就被认为在集群上**已提交**（committed）。准确的条件是：由**创建它的 leader 在本任期内**复制到全体服务器的多数（leader 自己算一份）；更早任期留下的条目随之一并提交，理由见 [[#5.5 为什么按本任期多数提交就安全（课件外）|5.5]]。
6. leader 在自己的状态机里**执行**命令，把结果**返回客户端**；再通过 AppendEntries 通知 follower 这个条目已提交，follower 随即在各自的状态机里执行已提交的命令。

![[L16 RAFT 日志复制过程.png]]

*5 台服务器，S1 是任期 3 的 leader，新命令 inc 放在索引 7。*

图里几处细节：

- AppendEntries 里除了新条目，还带着**前一个条目的任期和索引**（图中 prev = (3, 6)）。follower 只有在自己日志的那个位置有条目、且任期也对得上时才接受；那个位置还没有条目，或任期不同，就拒绝。leader 于是往前退一格再试，直到找到两者一致的位置，再用 leader 的日志覆盖 follower 后面不一致的部分（原论文 §5.3，课件未讲）。这样维持的是**日志匹配性质**（Log Matching）：两份日志只要在某个索引上的任期号相同，这一条以及之前的内容就完全相同。
- S1 自己 + S2 + S3 = 3 台已有索引 7，达到 5 台的多数，而且索引 7 是 S1 在本任期（任期 3）创建的条目，所以**已提交**。S4 慢、S5 失联都不影响。
- leader 执行后回复客户端。follower 并不是马上执行，而是在下一次 AppendEntries（可以只是心跳）里看到 leader 告知的"已提交到哪个索引"（字段名 leaderCommit），才按顺序执行到那里。
- S5 恢复后，leader 会不断重发，直到它的日志追上。

> [!warning] 课件 p57："majority of the follower nodes" 应为全体服务器的多数
> 课件原话："When the leader is able to replicate the command to the majority of the **follower** nodes … the entry is considered committed." 原论文 §5.3 的原句是 "A log entry is committed once **the leader that created the entry** has replicated it on a majority of the **servers**"。两处要紧：多数按**全体服务器**算，leader 自己也算一份；而且必须是**创建这条条目的 leader**，也就是在它自己的任期内完成复制。
> 第一处用数字看：5 台时，原文是 leader + 2 个 follower = 3 台即可；课件字面"4 个 follower 的多数"要 3 个 follower，共 4 台，在 2 台故障时就提交不了。3 台时差得更明显：课件字面要 2 个 follower 全部确认，坏 1 台就再也提交不了，和 RAFT 能容 1 台故障直接矛盾。课件自己的 p59 图注 "replicated on a majority of servers" 也和 p57 矛盾：那张图的索引 5、6 只在 Leader、Follower 2、Follower 4 上，按"follower 的多数"（3 个 follower）不算提交，图注却说提交到索引 6。以 p59 为准。
> 第二处（本任期）的理由见 [[#5.5 为什么按本任期多数提交就安全（课件外）|5.5]]。
> 考场写法："An entry is committed once the leader that created it (i.e. in the leader's current term) has replicated it on a majority of the servers (the leader included); earlier entries are then committed with it."

课件 p59 给了 5 个节点的日志快照，每格上面是任期号、下面是命令：

![[L16 RAFT 五节点日志.png]]

*课件 p59 原图，改编自原论文 Figure 6。*

逐个索引数一数有几台持有（多数 = 3）：

| 索引 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 条目的任期 | 1 | 1 | 2 | 3 | 3 | 3 | 3 |
| 持有台数 | 5 | 5 | 4 | 4 | 3 | 3 | 2 |
| 已提交？ | 是 | 是 | 是 | 是 | 是 | 是 | 否 |

判断时要用上"本任期"的条件。假定当前任期是 3：索引 4–6 都是任期 3 的条目、持有台数够多数，按计数直接提交；索引 1–3 属于任期 1、2，是之前任期留下的，不能单凭计数判定，它们随索引 4–6 一并提交。索引 7 只有 Leader 和 Follower 2 两台，还没提交。结论与图下 "Committed entries … up to log index number 6" 一致。

表里也看得出日志匹配性质：所有节点在同一索引上只要都有条目，任期和命令就完全相同。follower 的日志长短不一是正常的：有的网络慢、有的刚重启，leader 会通过一致性检查把它们补齐。

p60 画的是复制状态机的内部结构，已放在 [[#2.1 复制状态机：把"一致"归结为"日志一致"|2.1]]。p61 给了一个公认的 Raft 交互动画链接 http://thesecretlivesofdata.com/raft/ ，几分钟就能看完选主和复制的全过程。

### 5.5 为什么按本任期多数提交就安全（课件外）

日志复制的提交规则看似只是"多数确认"，要真正闭环还需要选举一侧的规则配合：已提交的条目，以后的每一任 leader 都必须持有，否则新 leader 会用自己的日志把它覆盖掉。

**提交的准确定义**（原论文 §5.4.2）：leader 只对**自己当前任期**产生的条目用"数够多数"判定提交；更早任期的条目，等到当前任期的某条条目提交时，按日志顺序一并提交。

**选举的三条规则**。课件只写了"拿到多数票就当选"；下面三条前两条在 [[#5.3 选主|5.3]] 已讲，这里集中列一次（原论文 §5.2、§5.4.1）：

1. 每台服务器每个任期最多投一票，先到先得 ⇒ 每个任期至多一个 leader；
2. 选举超时取随机值 ⇒ 避免反复平票；
3. **选举限制**（election restriction）：RequestVote 里带着 candidate 最后一条日志的任期和索引，投票者若发现自己的日志比 candidate 的**更新**，就拒绝投票。"更新"先比最后一条的任期，任期大者新；任期相同再比长度，长者新。

考场若要补充，先按课件写选主步骤，再加一句："In addition, each node votes for at most one candidate per term, election timeouts are randomised to avoid split votes, and a node only votes for a candidate whose log is at least as up-to-date as its own."

**用 p59 的日志看选举限制**。假设图中 leader 此时崩溃，剩下 4 个 follower 的最后一条日志分别是：F1 任期 3、索引 4；F2 任期 3、索引 7；F3 任期 1、索引 2；F4 任期 3、索引 6。当选要 3 票。

- F3 参选：其他三台的日志都比它新，没人投它，只有自己 1 票，选不上。
- F1 参选：F3 投它，F2、F4 比它新而拒绝，共 2 票，选不上。
- F4 参选：F1、F3 投它，F2 比它新而拒绝，加自己共 3 票，**能当选**。
- F2 参选：其余三台都不比它新，共 4 票，能当选。

能当选的只有 F2、F4，它们恰好都持有已提交的索引 1–6。索引 7 只在两台上、尚未提交，F4 当选后会把它覆盖——这是允许的，客户端从没收到过它执行成功的答复。

> [!example]- 推理链：本任期提交的条目不会丢，以及"旧任期条目数够多数"为什么不算提交
> **命题**：条目 $e$ 由任期 $T$ 的 leader 在本任期复制到多数服务器（集合 $S$），即已提交；那么任期大于 $T$ 的每一任 leader 都持有 $e$。
> 对任期 $U>T$ 归纳，假设任期在 $T$ 与 $U$ 之间的 leader 都持有 $e$：
> 1. 任期 $U$ 的 leader（记为 C）当选时拿到多数票（集合 $V$）。
> 2. $S$ 与 $V$ 都是多数，必相交，设交点为 X。
> 3. X 是先接受 $e$、后给 C 投票的：若它先投票，任期已升到 $U>T$，会拒绝任期 $T$ 的 AppendEntries，就不会在 $S$ 里。所以 X 投票时持有 $e$，它最后一条日志的任期至少是 $T$。
> 4. 由选举限制，C 的日志不比 X 旧。分两种情况：
>    - C 最后一条的任期**等于** X 的：同一任期的条目都出自同一个 leader、按顺序追加，C 的日志又不比 X 短，所以 C 包含 X 的全部日志，持有 $e$；
>    - C 最后一条的任期**大于** X 的，因而大于 $T$：这一条出自某个任期 $P$（$T<P<U$）的 leader，由归纳假设那个 leader 持有 $e$；再由日志匹配性质，C 的日志在这一条之前与那个 leader 的完全相同，所以也持有 $e$。
> 5. 所以 C 持有 $e$，不会覆盖它。RAFT 把这条性质叫 Leader Completeness（领导者完整性）。
>
> 第 3 步用到了"$e$ 是任期 $T$ 的 leader 在任期 $T$ 内复制到多数的"。只数副本、不管任期，这一步就断了。原论文 Figure 8 的反例（5 台 S1–S5）：
> 1. 任期 2，S1 是 leader，把索引 2 的条目复制到 S1、S2 后崩溃；
> 2. 任期 3，S5 凭 S3、S4、S5 的票当选，在索引 2 写了另一条条目，没来得及复制就崩溃；
> 3. 任期 4，S1 恢复并当选，继续复制，把任期 2 的那条复制到 S3——它已在 S1、S2、S3 三台上，是多数；
> 4. 若此时就算它已提交，而 S1 又崩溃：S5 最后一条的任期是 3，比 S2、S3、S4 的最后一条（任期 2 或 1）都新，能拿到它们的票当选，把索引 2 覆盖成自己的条目。"已提交"的条目就丢了。
>
> 按本任期的规则，S1 必须等任期 4 的某条新条目也复制到多数，任期 2 那条才随之提交；那之后多数服务器的最后一条任期是 4，S5 的任期 3 不再"更新"，选不上。

### 5.6 RAFT 不能抵抗拜占庭故障

模拟卷 Q4(a)(v)："List the three roles that the nodes can take in the RAFT consensus mechanism and indicate if the RAFT can resist Byzantine attacks/failures."（4 分）

答：**Leader、Follower、Candidate**（各 1 分）；**RAFT cannot resist Byzantine attacks/failures**（1 分）。

理由（参考答案没要求，但能写一句更稳）：课件 p46 写明 RAFT 的前提是 "No Byzantine failures"。机制上有三个漏洞：

- follower 对 leader 发来的 AppendEntries 照单全收，消息没有签名，follower 之间也不互相核对。一个作恶的 leader 可以给 F1 发"第 5 条是转账给 A"、给 F2 发"第 5 条是转账给 B"，两边都以为自己和多数一致，状态机从此分叉；
- 一个作恶的节点可以谎报一个极大的任期号，让 leader 下台、反复打断选举；
- 也可以谎称自己的日志很新来骗票，绕过选举限制。

根本原因是：RAFT 的安全论证（[[#5.5 为什么按本任期多数提交就安全（课件外）|5.5]]）只用到"两个多数必相交"，并默认交集里的节点说真话。节点会撒谎时，交集里那个节点的话不可信，论证就断了。要对付撒谎，quorum 要提到 $2f+1$、节点数要提到 $3f+1$（[[#3.3 拜占庭故障：N ≥ 3f+1|3.3]]），每条消息还要可验证——那就是 PBFT。

英文理由可以写一句："Followers accept the leader's AppendEntries without verification (no signatures, no cross-checking), so a malicious leader could send different logs to different followers; RAFT only tolerates crash failures ($N\ge2f+1$)."

## 6 PBFT

记号：本节 $N$ 表示副本总数，$n$ 只表示请求的序号。课件 p67 用 $n$ 表示节点数，引用课件原话时照录。

### 6.1 主思想：三个子协议

**实用拜占庭容错**（Practical Byzantine Fault Tolerance，PBFT）"顾名思义，是为在存在拜占庭故障时提供共识而设计的协议"（p63），由 Castro 与 Liskov 在 1999 年提出。"实用"是相对于此前的拜占庭容错算法而言：它们要么假定网络同步，要么慢到不能用；PBFT 在异步网络里也保证安全性，而且实际跑得够快。

PBFT 由三个**子协议**（subprotocol）组成（p63–64）：

- **正常运行**（normal operation）：一切正常时执行的流程；
- **视图切换**（view change）：检测到 primary（主节点：负责给请求排序、与客户端通信的那个副本，见 [[#6.2 角色：primary 与 backup|6.2]]）有故障时运行，换一个 primary；
- **检查点**（checkpointing）：定期确认一个大家公认的状态，把那之前的旧数据丢掉。

> [!warning] 课件 p64 "the system is error-free"
> 课件原话："The normal operation subprotocol refers to a mechanism executed when everything is running normally, and the system is error-free."
> 误：正常运行子协议只在系统完全无错时执行。
> 正：只要求 **primary 没坏**；至多 $f$ 个 backup（primary 以外的副本）出故障甚至作恶时，正常运行照样完成——原论文的正常流程示意图里恰好有一个 backup 是坏的。若真要整个系统无错才能运行，就根本用不着拜占庭容错。
> 考场写法："Normal operation runs while the primary is non-faulty (up to $f$ backups may still be faulty)."

正常流程是重点，在 [[#6.4 正常流程的三个阶段|6.4]] 展开；后两个在 [[#6.6 view change 与 checkpoint|6.6]]。

### 6.2 角色：primary 与 backup

p66 的三个名词：

- **Replica**（副本）：PBFT 的每一个参与者。
- **Leader**：由一个 leader 负责和客户端通信，它也叫 **primary**（主节点）。
- **Backup**（备份节点）：除 leader 外的其余节点。

真正的角色只有 primary 和 backup 两种，replica 是二者的总称（p65 图把 Replicas 画在上方、下方分出 leader 与 backup，就是这个"总–分"关系）。

**视图**（view）：PBFT 里"由谁当 primary"的一个时期，用编号 $v=0,1,2,\dots$ 表示，作用相当于 RAFT 的任期。primary 不靠选举产生，而是按编号轮流：$N$ 个副本编号 $0\sim N-1$，view $v$ 的 primary 是第 $v\bmod N$ 号副本。同一个 view 里，成千上万个请求都由同一个 primary 排序；只有它被怀疑出故障、触发 view change 时，才换成下一个 view 的 primary。后面每条消息里的 $v$ 就是 view 编号。

> [!warning] 课件 p65 "three roles … in a RAFT cluster" 与 p66 "In each round"
> **p65**："There are three roles that nodes (more precisely the consensus module within nodes) can assume in a **RAFT** cluster"——整句从 RAFT 那页（p47）复制过来：RAFT cluster 应为 PBFT cluster（L17 已改），"three roles"也不准，角色只有 primary 和 backup 两种，replica 是统称。
> **p66**："In each **round**, a leader node, called the primary node" 应为每个 **view** 一个 primary，不是每轮一换。
> 考场写法："Replicas are either the primary (leader) or backups; the primary is fixed within a view ($p=v\bmod N$) and changes only through a view change." 若题目按课件问 "three roles"，就答 replica / primary (leader) / backup，并补半句 "replica is the collective name for both"。

### 6.3 节点下限：3f+1

p67："to tolerate Byzantine faults, the minimum number of nodes required is **n = 3f + 1** in a partially synchronous environment"；"PBFT ensures Byzantine fault tolerance as long as the number of nodes in a system stays **n ≥ 3f + 1**." 这里的 $n$ 是节点数，即本笔记的 $N$。

课件只给结论。推导见 [[#3.3 拜占庭故障：N ≥ 3f+1|3.3]]，失败反例见 [[#3.4 只差一个节点就失败：两个反例|3.4]]。结论里的几个数下面反复用到：$N=3f+1$ 个副本，每一步凑 $2f+1$ 个一致的消息算 quorum，任意两个 quorum 至少交于 $f+1$ 个副本、其中至少 1 个诚实。

课件说"部分同步"，原论文说"安全性在异步下成立，活性需要弱同步"，两种口径下的下界都是 $3f+1$。这个前提不能省：在同步网络、消息又带签名时，拜占庭协定理论上可以用更少的节点；$3f+1$ 是异步或部分同步模型下的下界。原论文为简单起见就取 $N=3f+1$：更多副本只会降低性能，不会提高容错能力。

### 6.4 正常流程的三个阶段

PBFT 的一次运行由三个阶段依次组成：**pre-prepare**（预准备）、**prepare**（准备）、**commit**（提交）（p68）。前后再加客户端的请求与回复，共五段。下图按课件 p72 重画，副本按原论文从 0 编号，副本 0 是 view 0 的 primary：

![[L16 PBFT 正常流程.png]]

*$N=4$，$f=1$，四个副本都正常。顶部是各阶段的消息格式，底部是各阶段的消息条数。*

消息里的记号：$o$ 是要执行的操作，$t$ 是客户端打的时间戳（用来保证每个请求只执行一次），$c$ 是客户端，$v$ 是 view 编号，$n$ 是序号，$m$ 是请求本身，$d=D(m)$ 是请求的**摘要**（digest：对 $m$ 做抗碰撞哈希得到的短值），$i$ 是发送者的副本编号，$r$ 是执行结果。每条消息都带发送者的签名（或消息认证码，见 [[#6.5 每个阶段为什么必要|6.5]]）。

本笔记用原论文的记号，和课件 p72 的对应是：摘要 $d$ ↔ 课件的 $h$；副本 0 ↔ Primary，副本 1、2、3 ↔ Replica 2、3、4；大写消息名 ↔ 课件的小写（preprepare、prepare……）。考场按课件的写法画也可以，前后一致即可。

**REQUEST**：客户端把 $\langle\text{REQUEST},o,t,c\rangle$ 发给 primary。

**PRE-PREPARE**（p69，三步的主语都是 primary，课件漏写、L17 已补 "Leader"）：

1. primary 接受客户端的请求；
2. 给它分配下一个**序号**（sequence number）$n$——请求将按这个顺序执行；
3. 把 $\langle\langle\text{PRE-PREPARE},v,n,d\rangle,m\rangle$ 广播给所有 backup。

**PREPARE**（p70）：

1. backup 检查后才接受这条 pre-prepare（条件见下面的 warning）；
2. 接受后，向**所有副本**广播 $\langle\text{PREPARE},v,n,d,i\rangle$。

> [!warning] 课件 p70 的接受条件："same view or sequence number" 逻辑不对，且漏了三条
> 课件："Accepts the pre-prepare message only if the replica has not accepted any pre-prepare messages for the same view **or** sequence number before." 按字面，一个副本在同一个 view 里只能接受一条 pre-prepare（整个 view 只能处理一个请求），或者同一个序号在所有 view 里只能用一次（换了 primary 也不能重新安排）——两者都不对。
> 原论文的条件是四条同时满足：
> 1. 签名正确，且 $d$ 确实是 $m$ 的摘要；
> 2. 自己正处于 view $v$；
> 3. 没有接受过 view $v$、序号 $n$ 相同但**摘要不同**的 pre-prepare（同一 view **且**同一序号，内容不同才拒）；
> 4. 序号在**水位线**（watermark，允许使用的序号范围的下界 $h$ 与上界 $H$）之间：$h<n\le H$（怎样确定见 [[#6.6 view change 与 checkpoint|6.6]]；这里的 $h$ 是论文的低水位，和课件图上表示摘要的 $h$ 不是一回事）。
>
> 第 3 条是要害：它防的是 primary 给同一个序号安排两个不同请求。
> 考场写法："A backup accepts the pre-prepare if the signature and digest are valid, it is in view $v$, and it has not accepted another pre-prepare for the same view **and** sequence number with a different digest; it then multicasts a prepare message to all replicas."

**COMMIT**（p71）：

1. 副本等到 $2f+1$ 条 view、序号、请求都一致的 prepare 类消息（严格的数法见下），此时称它对这个请求 **prepared**；
2. 向所有副本广播 $\langle\text{COMMIT},v,n,d,i\rangle$；
3. 等到 $2f+1$ 条有效的、一致的 commit（可以含自己的），称为 **committed-local**；
4. 执行请求（还要等所有更小序号的请求都执行完，保证大家按同样顺序执行）；
5. 把 $\langle\text{REPLY},v,t,c,i,r\rangle$ 发给客户端。

**REPLY**：客户端等到 **$f+1$ 个**来自不同副本、$t$ 和 $r$ 都相同的回复，才接受结果 $r$。

> [!warning] 课件 p71：prepare 的计数口径，以及漏掉的客户端规则
> - **"waits for 2f + 1 prepare messages"**：原论文的 prepared 定义是"日志里有 pre-prepare，外加 **$2f$ 条**来自不同 backup 的匹配 prepare（可以含自己的）"。primary 不发 prepare，它的 pre-prepare 就算它的一票，合计正好是 $2f+1$ 个副本对同一个 $(v,n,d)$ 背书。若按字面只数 backup 发的 prepare、硬凑 $2f+1$ 条，问题出在有故障时：只要有 $f$ 个 backup 故障，诚实 backup 只剩 $2f$ 个，发不出 $2f+1$ 条 prepare，协议卡死，等于连 $f$ 个故障都容不下（$f=1,2,3$ 时诚实 backup 有 2、4、6 个，需要 3、5、7 条）。课件的"$2f+1$"只能理解为把 pre-prepare 也算一票。
> - 课件 commit 阶段的第 1 步"等 prepare 凑够数"其实是 prepare 阶段的结束条件，课件把它放在了 commit 阶段开头。
> - **漏了客户端**：课件写到"副本发回复"就停了。客户端必须等 **$f+1$ 个**内容相同的回复：至多 $f$ 个副本会撒谎，$f+1$ 个一致的回复里至少有一个来自诚实副本，结果才可信。只收一个回复，撒谎的副本就能骗过客户端。
>
> 考场写法："A replica is *prepared* when it has the pre-prepare and $2f$ matching prepares from different backups, i.e. $2f+1$ replicas agree on $(v,n,d)$. … The client accepts the result after receiving $f+1$ matching replies from different replicas." 第一句的 $2f+1$ 与课件一致，又说清了怎么数。

各阶段的消息条数（$N$ 个副本）：

| 阶段 | 谁发给谁 | 条数 | $N=4$ | $N=7$ | $N=10$ |
| --- | --- | --- | --- | --- | --- |
| request | 客户端 → primary | 1 | 1 | 1 | 1 |
| pre-prepare | primary → 每个 backup | $N-1$ | 3 | 6 | 9 |
| prepare | 每个 backup → 其余所有副本 | $(N-1)^2$ | 9 | 36 | 81 |
| commit | 每个副本 → 其余所有副本 | $N(N-1)$ | 12 | 42 | 90 |
| reply | 每个副本 → 客户端 | $N$ | 4 | 7 | 10 |
| **合计（不计 request）** | | $N(2N-1)$ | **28** | **91** | **190** |

一次请求的消息总数一律**不计**客户端发出的那 1 条 request：$N=4$、7、10 时为 28、91、190。若再不计 reply，副本之间的消息共 $2N(N-1)$ 条（24、84、180）。$N=4$ 的一列正是课件 p72 图上的箭头数 1、3、9、12、4。

### 6.5 每个阶段为什么必要

Paxos 两个阶段、PBFT 三个阶段，多出来的一轮和 $3f+1$ 的节点数一样，都是为撒谎者付的代价。逐段说明：

- **pre-prepare：由一个 primary 定顺序。** 总得有人提议"这个请求排第几"；大家各排各的就永远对不上。所以由 primary 分配序号。但 primary 可能就是坏的。
- **prepare：防止 primary 一号两卖。** 坏 primary 可以对不同副本给同一个序号安排不同请求（这种"对不同的人说不同的话"叫**模棱两可**（equivocation））。例：$N=4$，primary 是坏的，它给副本 1 发"序号 5 是请求 A"，给副本 2、3 发"序号 5 是请求 B"。
  - 副本 1 收到副本 2、3 发来的"序号 5 是 B"的 prepare，和自己手里的 pre-prepare 对不上；与 A 匹配的 prepare 只有自己那 1 条，凑不够 $2f=2$ 条，对 A 进不了 prepared。
  - 副本 2 手里是 B 的 pre-prepare，加上自己和副本 3 的两条 B 的 prepare，凑够 2 条，对 B 进入 prepared；副本 3 同理。

  结果序号 5 上至多一个请求能 prepared。一般地：一个副本 prepared，意味着 $2f+1$ 个副本对 $(v,n,d)$ 背书；若另一个请求 $d'$ 也想在某个诚实副本上以同一个 $(v,n)$ prepared，也得凑 $2f+1$ 个背书者。两组至少交于 $f+1$ 个副本，其中至少 1 个诚实，而诚实副本不会为同一个 $(v,n)$ 背书两个不同的请求——矛盾。所以**同一个 view 里，在诚实副本上，一个序号只能对应一个请求**（原论文的不变式 1；故障副本自己怎么宣称都不算数）。这就是 [[#3.3 拜占庭故障：N ≥ 3f+1|3.3]] 的交集在这里的用法。
- **commit：让这个顺序在换 primary 之后也不变。** prepared 只是"我知道大家对序号 5 没有分歧"，它不知道别人是否也 prepared。若副本一 prepared 就执行，随后 primary 被换掉，新 primary 可能不知道序号 5 已经被用了，把它分给别的请求，其他诚实副本就在序号 5 执行了不同的请求。commit 阶段要求凑齐 $2f+1$ 条 commit 才执行：$2f+1$ 个发 commit 的副本里至少 $f+1$ 个是诚实且已 prepared 的。而 view change 要收集 $2f+1$ 个副本的报告，$(f+1)+(2f+1)=3f+2>3f+1$，两组必相交，交点是一个诚实且 prepared 的副本，它会把"序号 5 是请求 B"的证据带进新 view，新 primary 只能沿用。原论文的原话："The pre-prepare and prepare phases are used to totally order requests sent in the same view even when the primary … is faulty. The prepare and commit phases are used to ensure that requests that commit are totally ordered across views."
- **reply 等 $f+1$ 个：防副本骗客户端。** 见 [[#6.4 正常流程的三个阶段|6.4]] 的 warning。
- **签名与摘要：让每一票都赖不掉、冒充不了。** 若坏副本能伪造"副本 2 投了请求 A"，quorum 就可以凭空造出来。所以每条消息都要带发送者的**数字签名**（digital signature，只有持有私钥的人能生成、任何人能用公钥验证，见 [[L8 数字签名、证书与 PKI]]），签的是摘要 $d$ 而不是整条请求，既短又能唯一代表请求。Paxos 和 RAFT 不需要这些，因为它们假定没有人撒谎。（原论文的实现里，正常流程用**消息认证码**（message authentication code，MAC：用双方共享的密钥给消息算一个校验值，见 [[L6 对称密码的安全使用]]）代替签名，快约三个数量级；签名只留给 view change。）

### 6.6 view change 与 checkpoint

这两个子协议课件只各写了一句（p64），下面按原论文补全它们做什么、为什么要有。

**view change（视图切换）**：解决"primary 坏了怎么办"，守的是活性。

1. backup 收到一个请求后开始计时；若这个请求迟迟没被执行，就认为 primary 有问题。
2. 它进入 view $v+1$，广播 VIEW-CHANGE 消息，里面带着最近的检查点证明，以及它所有已 prepared 请求的证据（pre-prepare 加 $2f$ 条 prepare）。
3. view $v+1$ 的 primary（编号 $(v+1)\bmod N$ 的副本）收到 $2f$ 个其他副本的 VIEW-CHANGE（加上自己共 $2f+1$），广播 NEW-VIEW：对证据里出现过的最小序号到最大序号之间的每个序号重新发 pre-prepare。同一序号有多份证据时，取 **view 编号最高**的那份里的请求；这个范围内没有证据的序号，填一个"空请求"。
4. 只有 $f+1$ 个副本都要求换届时，大家才会跟进；$f$ 个坏副本凑不够数，没法无端把一个好 primary 拉下来。primary 按编号轮换，坏副本至多 $f$ 个，所以至多连续 $f$ 个 view 的 primary 是坏的。

view change 对应 RAFT 的重新选举，但不需要投票：下一任是谁事先就定了。

**checkpoint（检查点）**：解决"日志无限增长"。

1. 每执行固定数量的请求（如序号是 100 的倍数时），副本广播一条 CHECKPOINT 消息，带上当前状态的摘要。
2. 凑齐 $2f+1$ 条序号与摘要都相同的 CHECKPOINT，这个检查点就成为**稳定检查点**（stable checkpoint）：至少 $f+1$ 个诚实副本确有这个状态，可以向任何人证明。
3. 于是序号不超过它的日志和消息都可以删掉。
4. 稳定检查点的序号就是**低水位线** $h$，**高水位线** $H=h+k$（$k$ 是一个固定的窗口，如 200）。副本只接受序号在 $(h,H]$ 之间的请求，这样坏 primary 无法发一个巨大的序号把序号空间耗尽。这就是 [[#6.4 正常流程的三个阶段|6.4]] 接受条件里的 $h<n\le H$。

checkpoint 和 RAFT 的日志压缩（快照）目的相同。

### 6.7 代价：O(N²) 条消息

prepare 和 commit 都是"每个副本发给其余所有副本"，消息数随副本数平方增长：不计 request，$N=10$ 时一次请求 190 条消息，$N=100$ 时 19 900 条（[[#6.4 正常流程的三个阶段|6.4]] 的表）。这种增长记作 $O(N^2)$——大 O 记号只看随 $N$ 增长的量级、不看常数。对比 RAFT：正常复制一条命令，leader 发 $N-1$ 条 AppendEntries、收 $N-1$ 条确认，是 $O(N)$；Paxos 由 leader 汇总时同样是线性的。所以 PBFT 只适合几十个节点以内、成员固定的场合，在区块链里用于许可链（早期版本的 Hyperledger Fabric——Linux 基金会主持的开源许可链平台——就用过 PBFT）；公有链既有 Sybil 问题（[[#1.4 从 PoW、PoS 到本讲：能不能直接数票|1.4]]）又有规模问题，两条都让它用不了。

### 6.8 附读物：PBFT 原论文

Moodle 上的 `PBFT-Mathematical Proof.pdf`（14 页）其实是 Castro 与 Liskov 的会议论文原文《Practical Byzantine Fault Tolerance》，发表于 OSDI 1999（Symposium on Operating Systems Design and Implementation，操作系统设计与实现研讨会，系统领域的顶级会议），不是一份单独的数学证明；论文 §4.5 自己说只给证明梗概，完整证明在另一份技术报告里。论文里真正"数学"的部分有三处：§3 的 $3f+1$ 论证（已在 [[#3.3 拜占庭故障：N ≥ 3f+1|3.3]] 逐句展开）、§4.2 的两个不变式（[[#6.5 每个阶段为什么必要|6.5]] 的 prepare 和 commit 两条）、§4.5 的安全性与活性梗概。

> [!example]- 论文各节要点与其中出现的数量关系
> **各节要点**（页码为该 PDF 的页序）：
> - Abstract、§1（p1–2）：第一个在互联网这类异步环境里正确工作的拜占庭容错状态机复制算法；在至多 $\lfloor (N-1)/3\rfloor$ 个副本同时出错时，同时保证安全性与活性；安全性不依赖同步；只读操作 1 个往返、读写操作 2 个往返；用它做的拜占庭容错文件系统 BFS（Byzantine-fault-tolerant NFS；NFS 即 Network File System，网络文件系统）只比不复制的标准 NFS 慢 3%。
> - §2 系统模型（p2）：异步网络，可丢失、延迟、重复、乱序；故障节点行为任意；假定节点故障相互独立（需要不同实现、不同操作系统、不同管理员）；敌手可以串通故障节点、拖延消息，但不能无限期拖延诚实节点，也算不出签名、摘要的碰撞。
> - §3 服务性质（p2–3）：安全性是线性一致性（linearizability：整个系统表现得像一台按某个顺序逐个执行请求的机器）；活性依赖弱同步，用来绕开 FLP；$3f+1$ 是最优下界。
> - §4 算法（p3–7）：view 与 primary $=v\bmod\lvert\mathcal{R}\rvert$（$\mathcal{R}$ 是副本集合）；客户端等 $f+1$ 个相同回复；三阶段与两个不变式；检查点与水位线；view change；正确性梗概。
> - §5 优化（p7–8）：只让一个副本回完整结果、其余回摘要；prepared 后就试执行，客户端等 $2f+1$ 个试执行结果；只读请求直接执行；正常流程用 MAC 代替签名（原文测得 RSA 签名 43 ms，MAC 10.3 µs；RSA 见 [[L7 公钥密码]]）。
> - §6–7 实现与性能（p9–13）：4 个副本（容 1 个故障）的实验；BFS 在 Andrew 基准测试（一套模拟软件开发时各种文件操作的标准测试）上比标准 NFS 慢 3%。
>
> **论文里用到的数量关系**，全都是 [[#3.3 拜占庭故障：N ≥ 3f+1|3.3]] 的同一个交集在不同地方的使用：
>
> | 数量 | 用在哪 | 为什么是这个数 |
> | --- | --- | --- |
> | $2f+1$（pre-prepare + $2f$ 条 prepare） | prepared | 一个 quorum；两组交于 $\ge f+1$，含诚实者 |
> | $2f+1$ 条 commit | committed-local | 一个 quorum ⇒ 至少 $f+1$ 个诚实副本已 prepared |
> | $f+1$ 与 $2f+1$ 相交 | 跨 view 的安全性 | $(f+1)+(2f+1)=3f+2>3f+1$ |
> | $2f$ 条他人的 VIEW-CHANGE | 新 primary 发 NEW-VIEW | 加上自己共 $2f+1$，一个 quorum |
> | $f+1$ 个相同回复 | 客户端接受结果 | 至少 1 个来自诚实副本 |
> | $2f+1$ 条 CHECKPOINT | 稳定检查点 | 一个 quorum，至少 $f+1$ 个诚实副本可作证 |
> | $f+1$ 条 VIEW-CHANGE | 其他副本跟进换届 | 至少 1 个诚实副本确实在怀疑 primary |
>
> 附带一处论文自身的印刷错误：参考文献 [2] Bracha 与 Toueg 的论文年份印成 1995，应为 1985（Journal of the ACM 第 32 卷第 4 期）。

## 7 三个协议的对比

课件没有这张表，下面把三个协议放在一起：

| | Paxos | RAFT | PBFT |
| --- | --- | --- | --- |
| 防什么 | 崩溃（可重启） | 崩溃 | 拜占庭（任意行为） |
| 节点下限 | $2f+1$ 个 acceptor | $2f+1$ 台服务器 | $3f+1$ 个副本 |
| quorum | 多数 $\lfloor N/2\rfloor+1$（$N=2f+1$ 时为 $f+1$） | 多数，leader 算一份（同左） | $2f+1$（$N=3f+1$ 时） |
| 角色 | Proposer、Acceptor、Learner | Leader、Follower、Candidate | Primary（leader）、Backup，统称 Replica |
| 阶段 | Prepare → Accept（含 learn） | Leader election → Log replication | Pre-prepare → Prepare → Commit（另有 view change、checkpoint） |
| leader 怎么来 | 为活性而选一个 proposer | 投票选举，按任期；所有写入都经过它 | 按 view 轮换，$v\bmod N$，不投票 |
| 正常流程消息数 | 由 leader（或指定 learner）汇总时随 $N$ 线性；acceptor 直接通知全部 learner 时为 acceptor 数 × learner 数 | 随 $N$ 线性 | 随 $N$ 平方 |
| 需要签名/MAC | 不需要 | 不需要 | 需要 |
| 典型用途 | 分布式数据库、锁服务 | 分布式数据库与配置存储（如 etcd，一个开源的分布式键值存储）、许可链里给交易排序 | 许可链、联盟链 |

模拟卷 Q3(b)(ii) "List any three consensus mechanisms used in blockchain systems" 的参考答案是 "PoW, PoS, RAFT, Paxos, PBFT, etc."，任写三个即可，规范答法见 [[L15 区块链共识 I#2.4 常见共识机制一览|L15 2.4]]。

三者的共同骨架：**安全性靠 quorum 交集，活性靠超时换人**。区别只在两处：防不防撒谎（决定 quorum 是多数还是 $2f+1$、要不要签名），以及 leader 有多强（Paxos 的 leader 只为避免冲突，RAFT 的 leader 包办一切，PBFT 的 primary 只负责排序且随时可被换掉）。

## 本讲速记

- 公有链身份可伪造（Sybil），只能按算力（PoW）或质押（PoS）抽签；Paxos、RAFT、PBFT **直接数票**，要求成员固定，用于许可链与分布式系统，终局性确定。
- 两类故障按行为分：**崩溃**（不收发消息，但不说谎）；**拜占庭**（任意行为，可以说谎、说两套话、串通；可能出于恶意，也可能是软件缺陷）。
- 复习页（首讲 L15）：Q4(a)(i) 得 $x=3$；Q3(b)(iii) 得 **375 Tx/s**（参考答案 37.5 错）、确认时间 $20\times200=4000$ s。
- 复制状态机：确定性状态机 + 同一初始状态 + 同序执行同一命令序列 ⇒ 执行完同一段命令后状态相同；共识 = 对日志每个位置达成一致。每个节点 = 共识模块 + 日志 + 状态机（p60）。
- 安全性（不出两个决定）永远保证；活性（终会决定）只在网络足够守时时保证（FLP），靠超时、重试、换 leader。
- **quorum 推导**：等不到 $f$ 个 ⇒ $q\le N-f$；两 quorum 最坏交集 $2(N-f)-N=N-2f$；崩溃要交集 $\ge1$ ⇒ $N\ge2f+1$，quorum 为多数（$N=2f+1$ 时 $f+1$）；拜占庭要交集扣掉 $f$ 后 $\ge1$ ⇒ $N\ge3f+1$，quorum $2f+1$，交集 $f+1$。论文写法 $N-2f>f$。
- 反例：$N=2f$ 网络分区各自决定；$N=3f$ 故障节点对两组诚实节点说两套话，两 quorum 只交于故障节点。
- 模拟卷：崩溃 $f=3$ ⇒ $N\ge7$，合法 **4**；拜占庭 $f=3$ ⇒ $N\ge10$，合法 **7**。要写推导，要减 $f$。
- Paxos 前提：消息可延迟、丢、乱序、重复但不被篡改；节点可崩溃重启、不作恶。角色 Proposer / Acceptor / Learner，一个进程可兼任；选一个 proposer 当 leader 是为了避免活锁。
- Paxos Phase 1：proposer 用全局唯一、递增的 $n$ 发 prepare($n$)；acceptor 若 $n$ 大于已承诺的所有编号，就承诺忽略 $<n$、记下 $n$、回 promise($n$) 并带回**接受过的编号最高的提案**，否则忽略（**课件漏这一句**）；超时则用更大 $n$ 重试。
- Paxos Phase 2：收到多数 promise 后，**取带回提案中编号最高者的值**，没有就任选；发 accept($n$, $v$)；acceptor **只要没承诺过更大编号就接受，并把承诺编号提到 $n$**（课件写"对 prepare($n$) 回过才接受"，偏严但安全），回 accepted($n$, $v$) 并通知所有 learner；多数接受即决定。learn 属于 Phase 2。
- p42 图 "Wait for majority 2f+1" = 在 $2f+1$ 个中等**多数 $f+1$ 个**。
- RAFT：好懂；复制状态机 + 持久日志；成员变更、日志压缩；前提无拜占庭、网络不可靠、异步（异步只对安全性成立，进展靠超时）。角色 **Leader / Follower / Candidate**；任期号是逻辑时钟，见大任期即退位，过期 leader 一露面就被识破。
- RAFT 选主：心跳压住选举；收不到心跳 → 选举超时 → candidate，任期 +1、自投一票、发 RequestVote → 多数票当选；超时重选；收到 leader 心跳退回 follower。三条规则：每任期每人一票、随机超时、选举限制（只投日志不比自己旧的 candidate）。
- RAFT 复制：客户端 → leader；分配 term + index、追加日志；AppendEntries 复制（带前一条的 term 与 index 做一致性检查）；**由创建它的 leader 在本任期内复制到全体服务器的多数**（含 leader）即提交，更早任期的条目随之提交（课件写 follower 的多数，不准；只数副本不管任期会出 Figure 8 的错）；leader 执行、回客户端；后续 AppendEntries 告知提交位置，follower 执行。
- RAFT **不能抗拜占庭**：follower 无条件信 leader、无签名；恶意节点可谎报任期、谎称日志新；安全论证只靠多数相交，只够 $N\ge2f+1$。
- PBFT：三个子协议 normal operation（只要求 primary 没坏，不是"系统无错"）/ view change / checkpointing；角色 primary（leader）+ backup，统称 replica；每个 **view** 一个 primary，$p=v\bmod N$；$N\ge3f+1$。
- PBFT 正常流程：REQUEST → PRE-PREPARE（primary 分序号 $n$，广播 $\langle\langle\text{PRE-PREPARE},v,n,d\rangle,m\rangle$）→ PREPARE（backup 验证后广播；prepared = pre-prepare + $2f$ 条匹配 prepare，共 $2f+1$ 个副本）→ COMMIT（广播 commit，收 $2f+1$ 条后按序执行）→ REPLY（**客户端等 $f+1$ 个相同回复**，课件漏）。课件记号 $h$ = 摘要 $d$。
- p70 接受条件应为：签名与摘要正确、处于 view $v$、没接受过同 view **且**同序号但摘要不同的 pre-prepare、$h<n\le H$。p71 的"2f+1 条 prepare"若只数 backup，$f$ 个 backup 故障时诚实 backup 只剩 $2f$ 个，凑不齐。
- 为什么三阶段：pre-prepare 定顺序；prepare 防坏 primary 一号两卖（同 view 内诚实副本上一号一请求）；commit 保证换 view 后顺序不变（$f+1$ 与 $2f+1$ 必相交）。
- PBFT 消息数 $N=4$：1 / 3 / 9 / 12 / 4；不计 request 合计 $N(2N-1)$ = 28 / 91 / 190（$N=4/7/10$），再不计 reply 为 $2N(N-1)$；$O(N^2)$，只适合小规模许可链。
- 附读物是 PBFT 原论文（OSDI 1999），不是单独的证明；BFS 只比 NFS 慢 3%；正常流程用 MAC 代替签名。

浏览器版（带法定人数交集计算器、Paxos 逐条拿掉规则、RAFT 日志提交与选举判定、PBFT 消息计数）：[HTML/L16 区块链共识 II.html](HTML/L16%20%E5%8C%BA%E5%9D%97%E9%93%BE%E5%85%B1%E8%AF%86%20II.html)
