---
chapter: Lab3-4
status: 代码完成，报告待写
---

# Lab3-4 区块链与 PoW 的 Python 实现

> [!info] 这次实验在做什么
> 后半学期（区块链部分）的两次实验合成一份报告：Lab 3（题面 *Lab 1 – Build a Blockchain in Python*）用 Python 搭一条最小的区块链，Lab 4（题面 *Lab 2 – Design a PoW Consensus*）给它加上工作量证明（Proof of Work，PoW）。两人一组，报告用模板 *Report on Laboratory Session 3 & 4*，Moodle 截止 2026/12/11 23:59。
> 这篇讲**程序怎样把每一个概念落实下来**、跑出了什么、结果说明了什么。现场演示与助教提问的准备见 [[Lab3-4 现场可能被问到的问题]]。

## 1 任务与评分

两份题面的评分标准完全相同：

| 项 | 占比 | 题面要求 |
| --- | --- | --- |
| Demonstration | 50% | 每个 Task 都要现场跑给助教看 |
| Lab Questions | 10% | 现场回答提问 |
| Reflection and significance | 25% | 每个 Task 写几行"做了什么、意味着什么、下一步是什么"；**只写总结不给分** |
| Coding good practice | 15% | 有意义的命名（不要 `x`、`y`、人名）、开头与关键行的注释、一致的缩进 |

| 实验 | 任务 | 内容 |
| --- | --- | --- |
| Lab 3 | Task 1.1–1.4 | Python 热身：列表、字典、函数、类、docstring |
| Lab 3 | Task 2 | 建虚拟环境，`blockchain.py` 里导入 `time`/`datetime`、`json`、`hashlib` |
| Lab 3 | Task 3.1–3.3 | `Blockchain` 类：实例化时生成创世块；记录新块；取上一块 |
| Lab 4 | Task 3.1–3.4 | `proof_of_work()`：用 `json.dumps` + SHA-256 算哈希，找到让哈希以 `0000` 开头的 proof |
| Lab 4 | Mine / Validate | 挖两个新块；（可选）校验整条链 |

代码在课程资料文件夹的 `IS/实验/Lab3-4/代码/`，只用 Python 标准库，Python 3.8 以上都能跑；协作说明是同目录的 `README_协作说明.md`。

## 2 程序结构

| 文件 | 作用 |
| --- | --- |
| `task1_python_tutorial.py` | Task 1：循环生成 10 条记录、`BlockRecorder` 类、按 index 打印 |
| `blockchain.py` | 核心：`Blockchain` 类，所有 Lab 3/Lab 4 的方法都在这里 |
| `lab3_demo.py` | Lab 3 演示：创世块、`add_block` 记两块、取上一块、打印整条链 |
| `lab4_demo.py` | Lab 4 演示：难度 4 下挖两块、校验、篡改后再校验 |
| `difficulty_experiment.py` | 扩展：难度 1–4（或更高）各挖若干块，比较实测哈希次数与理论值 |
| `test_blockchain.py` | 11 项单元测试 |

`blockchain.py` 里的方法与题号：

| 方法 | 题号 | 做什么 |
| --- | --- | --- |
| `__init__` | Lab 3 Task 3.1 | 建空链 `self.chain`，立刻生成创世块 |
| `create_block` | Lab 3 Task 3.1 | 由五个字段拼成一个块并追加到链尾 |
| `add_block` | Lab 3 Task 3.2 | 不挖矿，直接记录信息（Lab 4 之前的版本，proof 记 0） |
| `get_previous_block` | Lab 3 Task 3.3 | 返回链尾那一块 |
| `hash_block` | Lab 4 Task 3.2 | `json.dumps(block, sort_keys=True)` → SHA-256 → 64 位十六进制 |
| `proof_of_work` | Lab 4 Task 3.1/3.3/3.4 | 从 0 开始逐个试 proof，直到哈希满足难度 |
| `mine_block` | Mine New Block | 取上一块的哈希，跑 PoW，把结果写进新块 |
| `is_chain_valid` | Validate（可选） | 逐块检查链接、index 和工作量 |

## 3 一个块里有什么

每个块是一个 Python 字典，五个键：

| 键 | 含义 | 创世块的值 |
| --- | --- | --- |
| `index` | 这一块在链里的位置，等于它生成时链的长度 | 0 |
| `timestamp` | 生成（挖出）的日期时间 | 当前时间 |
| `data` | 记录的信息 | `"Hello World!"` |
| `proof` | 工作量证明，也就是矿工找到的那个数 | 0 |
| `previous_hash` | 上一块的哈希 | `'0'` |

题面的结构图把 timestamp 写成了 `timestep`，Task 3.1 的列表把 data 写成了 "Date"，两处都是笔误，代码按 `timestamp`、`data` 写。

创世块（genesis block）是链的第一块，前面没有块可以引用，所以 `previous_hash` 只能填一个约定值 `'0'`。它也不经过挖矿，proof 填 0。

## 4 哈希：把一个块压成一个"指纹"

### 4.1 SHA-256 提供的四个性质

哈希函数（hash function）把任意长度的输入映射成固定长度的输出。SHA-256（Secure Hash Algorithm，输出 256 位，写成 64 个十六进制数字）是比特币用的那一个。这个实验用到它的四个性质：

1. **确定性**：同样的输入永远得到同样的输出。所以任何人都能重算一个块的哈希来核对。
2. **雪崩效应**：输入改一位，输出大约一半的位都会变，看起来与原哈希毫无关系。所以"改了一点点"也藏不住。
3. **抗原像**（preimage resistance）：给定一个输出，找不到比"一个个去试"更快的办法得到对应的输入。PoW 的谜题就建立在这一条上。
4. **抗碰撞**（collision resistance）：找不到两个不同的输入有相同的输出。所以一个哈希值能唯一地代表一个块。

### 4.2 为什么要先 json.dumps，而且要 sort_keys

`hashlib.sha256()` 只吃字节串，不吃字典，所以要先把字典编码成字符串。问题在于：**同一个字典可以写成不止一种字符串**——键的顺序不同，字符串就不同，哈希也就不同。`sort_keys=True` 让键永远按字母序排列，同一个块就只有一种编码、一个哈希。测试 `test_hash_is_independent_of_key_order` 验证的正是这一点。

$$
\text{hash}(B) = \text{SHA256}\big(\text{json.dumps}(B,\ \text{sort\_keys}=\text{True})\big)
$$

## 5 链：用哈希把块串起来

第 $i$ 块的 `previous_hash` 存的是第 $i-1$ 块的哈希：

$$
B_i.\text{previous\_hash} = \text{hash}(B_{i-1})
$$

这样每一块都"记住"了它前一块的指纹。假设有人改了第 1 块的 data：第 1 块的哈希随之改变（雪崩效应），而第 2 块里存的还是旧哈希，两者对不上，校验立刻报错。

但**只有哈希链是不够的**。改了第 1 块之后，攻击者完全可以顺手把第 2 块的 `previous_hash` 改成新值，再重算第 2 块的哈希、改第 3 块……一路改到链尾。SHA-256 算一次只要微秒级，一条几千块的链一眨眼就能整条重写，而且重写后的链内部完全自洽。哈希链只能让篡改**留下痕迹**，不能让篡改**变得昂贵**。这正是 PoW 要补的缺口。

## 6 工作量证明

### 6.1 谜题是什么

规定：一个块要被接受，它的哈希必须以 $d$ 个十六进制 0 开头（$d$ 叫难度，题面取 4，即 `"0000"`）。块里的 index、timestamp、data、previous_hash 都已经定了，唯一能改的就是 proof。矿工从 proof = 0 开始一个个试，直到哈希满足条件为止：

```python
new_proof = 0
check_proof = False
while check_proof is False:
    candidate_block = {..., "proof": new_proof, ...}
    hash_operation = self.hash_block(candidate_block)
    if hash_operation[:self.difficulty] == self.target_prefix:
        check_proof = True
    else:
        new_proof += 1
```

为什么只能一个个试？因为抗原像：没有任何办法从"想要的哈希形状"倒推出 proof。

### 6.2 平均要试多少次

把 SHA-256 的输出看成均匀随机。一位十六进制数字是 0 的概率是 $1/16$，前 $d$ 位全是 0 的概率是

$$
p = \left(\frac{1}{16}\right)^{d}
$$

每试一次都是一次独立的"抛硬币"，成功概率 $p$。第一次成功前要试的次数服从几何分布（geometric distribution），期望是

$$
E[\text{试的次数}] = \frac{1}{p} = 16^{d}
$$

难度每加 1，平均工作量乘 16。$d=4$ 时约 65 536 次。几何分布的标准差约等于期望本身，所以单块的耗时波动极大：运气好几百次就中，运气差要几十万次。

`difficulty_experiment.py` 在难度 1–4 下各挖 200 块的实测（测试机上约每秒 25 万次哈希，换一台电脑耗时会不同，哈希次数的统计规律不变）：

| 难度 $d$ | 理论 $16^d$ | 实测平均 | 最少 | 最多 | 平均每块耗时 |
| --- | --- | --- | --- | --- | --- |
| 1 | 16 | 15.9 | 1 | 95 | 0.1 ms |
| 2 | 256 | 237.7 | 2 | 1 427 | 0.9 ms |
| 3 | 4 096 | 3 704.0 | 1 | 32 179 | 17 ms |
| 4 | 65 536 | 64 844.3 | 136 | 482 183 | 0.25 s |

平均值与 $16^d$ 吻合，最少与最多之间差了两到三个数量级，正是几何分布的样子。

### 6.3 PoW 为什么让篡改变贵

本代码的哈希覆盖整块，**proof 和 data 绑在同一个哈希里**。改了第 $k$ 块的 data，它的哈希就不再以 0000 开头，proof 作废，必须重挖；而第 $k$ 块的哈希一变，第 $k+1$ 块的 previous_hash 也要改，它的 proof 也作废……一直到链尾。设链长 $n$，篡改第 $k$ 块要重做的期望工作量是

$$
(n-k)\times 16^{d}
$$

次哈希。与第 5 节相比，篡改从"微秒级重算"变成了"重做后面每一块的工作量"。在真实网络里，诚实节点同时还在链尾不断挖新块，攻击者必须**比全网其余算力加起来还快**才追得上——这就是"51% 攻击"这个说法的来源。

### 6.4 与常见教程写法的区别

题面里 `check_proof`、`hash_operation` 这些变量名出自网上一类常见教程。那类教程把谜题写成：找 `new_proof`，使 `sha256(str(new_proof**2 - previous_proof**2))` 以 0000 开头。那个谜题**只和上一块的 proof 有关，和本块的数据无关**。改掉某块的 data，它的 proof 依然"有效"，攻击者只要按第 5 节那样重算后面各块的哈希即可，一次 PoW 都不用重做，PoW 形同虚设。本代码对整块做哈希，与比特币对区块头做哈希的思路一致（比特币的区块头通过 Merkle 根间接覆盖全部交易）。

### 6.5 校验

`is_chain_valid` 对第 1 块起的每一块检查三件事：`previous_hash` 等于上一块的哈希；`index` 等于位置；哈希满足难度。只要一条不满足，就返回 False 并指出是哪一块、哪一条。

两种篡改的检出方式不同：

| 篡改位置 | 怎么被发现 |
| --- | --- |
| 中间某块 | 它自己的哈希不再满足难度；它后一块的 previous_hash 也对不上 |
| 最后一块 | 没有后继块可以暴露它，只能靠它自己的哈希不满足难度来发现 |

第二行说明：**没有 PoW 检查时，篡改最后一块是查不出来的**。测试 `test_tampering_last_block_breaks_its_proof` 专门验证这一点。

## 7 这个程序离真正的区块链还差什么

这些差距正是报告 Reflection 和 Discussion 可以展开的地方：

- **单机、没有网络**。真实系统是许多节点各自保存一份账本，靠共识机制对"下一块是什么"达成一致；没有网络，就没有分叉，也没有"最长链"规则。
- **一块只有一条 data**。真实区块装成百上千笔交易，用 Merkle 树汇总成一个根哈希放进区块头。
- **难度固定**。比特币每 2016 块按实际出块速度调整一次目标值，让平均出块时间稳定在约 10 分钟。
- **没有激励**。没有出块奖励和手续费，就没有人愿意花算力挖矿。
- **前导零只是目标值的特例**。比特币要求哈希作为一个 256 位整数小于目标值 $T$，"前 $d$ 位为 0"相当于 $T = 16^{64-d}$，只能以 16 倍为单位调难度；用整数目标值可以连续地调。
- **timestamp 没有校验**，任何人都能填任意时间。
- **PoW 本身的代价**：全网算力绝大部分花在"找一个以 0 开头的哈希"上，这些计算除了维护安全之外没有其他用处，这就是 PoW 被批评耗能的原因，也是 PoS 等替代机制要解决的问题。

## 8 现场环节

现场操作步骤、Task 2 建虚拟环境的命令、以及助教可能问的问题，见 [[Lab3-4 现场可能被问到的问题]]。
