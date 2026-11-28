# IS Lab 3 & 4（区块链部分）协作说明

题面：`题面/Part II - lab 1.docx`（Lab 3，搭一条区块链）、`题面/Part II_Lab2.docx`（Lab 4，PoW 共识）。
报告模板：`题面/Report_template-part II-Blockchain.docx`。两次实验合交一份报告，Moodle 入口 "laboratory 3&4 report submission (Blockchain part)"，截止 **2026-12-11 23:59**。

## 1 评分构成（两次实验相同，题面原文）

| 项 | 占比 | 怎么拿 |
| --- | --- | --- |
| Demonstration | 50% | 现场把每个 Task 跑给 GTA 看（"demonstrate a functional blockchain system for each task"） |
| Lab Questions | 10% | 现场回答 GTA 的提问 |
| Reflection | 25% | 每个 Task 写几行反思：做了什么意味着什么、下一步是什么；**题面明说只写总结不给分** |
| Coding good practice | 15% | 有意义的变量名、开头和关键行的注释、一致缩进 |

## 2 环境

- 只用 Python 标准库（`datetime`、`hashlib`、`json`、`time`、`csv`、`statistics`），**不需要装任何包**。Python 3.8 及以上即可。
- Task 2 要求在命令行建虚拟环境，现场照下面做一遍给 GTA 看：

```bash
cd 代码
python -m venv venv
# Windows:  venv\Scripts\activate      macOS/Linux:  source venv/bin/activate
python --version
```

## 3 文件与题号对应（2026-11-28 更新）

现场演示用的是搭档自己写的那套代码，提交的报告也以这套为准，这套代码与两份分析脚本放在 `代码/_private/`（用户 2026-11-28 定：不公开到 GitHub，`_private` 不进仓库）。`代码/` 根下仍是我方最初写的版本（`task1_python_tutorial.py`、`lab3_demo.py`、`lab4_demo.py`、`test_blockchain.py` 等），报告不再使用，但保留在公开仓库里。下表的文件都在 `代码/_private/`。

| 文件 | 对应 | 用法 |
| --- | --- | --- |
| `blockchain.py` | Lab 3 Task 1–3、Lab 4 Task 3 与 Validate | `BlockRecords`（10 条练习记录）与 `Blockchain`（创世块、`mine_block`、`proof_of_work`、`is_chain_valid`）；搭档现场演示的原代码 |
| `run_lab.py` | 两次实验的主程序 | `python run_lab.py --json-out run_results.json`：打印 10 条记录、挖两块、跑 10 项自检；搭档现场演示的原代码 |
| `difficulty_experiment.py` | 报告分析用（事后补写） | `python difficulty_experiment.py 4 200`：难度 1–4 各挖 200 块，对照 $16^d$ |
| `tamper_experiment.py` | 报告分析用（事后补写） | `python tamper_experiment.py`：区分哈希链接与 PoW 各能查出哪种篡改 |
| `*_output.txt`、`run_results.json`、`difficulty_results.csv` | 报告附录 C 与表 2–4 的原始输出 | 复跑结果 |

## 4 题面里的几处笔误，代码怎么处理的

- 结构图里写 `timestep`，正文写 Timestamp：代码用 **`timestamp`**。
- Task 3.1 列表里写 "**Date**: The recorded information"：指的是 **data**，代码用 `data`。
- Task 1.2 写"achieve the block record in task**3.1**"：上下文是 Task 1.1 的记录，按 1.1 实现。
- Task 1.1 "index and data in equal steps starting from 100 until it reaches 1000"：理解为 10 个块的 data 依次是 100, 200, …, 1000（每个包成列表 `[100]`），index 是 0–9 的位置。（搭档代码 `generate_records()` 也是这样实现的。）
- 课程代码写的是 UESTC4036_2023 / 2022，是旧版题面，不影响内容。

## 5 设计上和网上常见写法的一处不同（GTA 可能会问）

网上常见的教程（题面里 `check_proof`、`hash_operation` 这些变量名就出自这类教程）把 PoW 写成"找 `new_proof`，使 `sha256(str(new_proof**2 - previous_proof**2))` 以 0000 开头"。那个谜题**只和上一块的 proof 有关，和本块的数据无关**：改掉某块的数据，它的 proof 依然"有效"，攻击者只需重算后面各块的哈希，**一次 PoW 都不用重做**，PoW 起不到防篡改作用。

本代码让哈希覆盖**整块**（index、timestamp、data、proof、previous_hash），与比特币对区块头做哈希的做法一致：改动任何字段，这一块的工作量证明立刻失效，攻击者必须重挖这一块和它后面的每一块。搭档的 `proof_of_work()` 同样对整块做哈希；`tamper_experiment.py` 演示了这一点。

## 6 需要你现场完成或回传的

1. 题面 Lab 4 "Preliminary" 要求登录 https://besharing.net/ 看其他同学的 PoW 设计，现场做即可，无需回传。
2. **回传给我**（写报告用，有就发，没有也不卡）：
   - 现场跑 `lab4_demo.py` 的终端截图一张；
   - GTA 现场问了什么问题、对代码有没有提出修改意见。
