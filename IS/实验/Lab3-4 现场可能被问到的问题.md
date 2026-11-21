---
chapter: Lab3-4
status: 已完成
---

# Lab3-4 现场可能被问到的问题

> [!info] 这份文件怎么用
> 现场要把每个 Task 跑给助教看，助教也会问原理和代码（Lab Questions 占 10%，演示占 50%）。这里先列现场操作步骤，再按主题列出可能被问到的问题。
> 每题先给一两句**可以直接用英文说出口的回答**，再给中文要点；末尾链回讲解原文，那里有完整的来龙去脉。
> 程序与结果在 [[Lab3-4 区块链与 PoW 的 Python 实现]]。

## 现场操作

**开场前：拿到程序**

1. 打开课程包仓库 `https://github.com/AlanCommitK/Fourth-year1stSemester`，点绿色的 `Code` → `Download ZIP`，解压。
2. 程序在解压后的 `IS/实验/交付物/Lab3-4/代码/` 里。把整个 `代码` 文件夹拷到实验室电脑上；中文路径碍事的话改名为 `code`、放到纯英文路径下（如 `C:\lab34\code\`），程序之间只用相对导入，改名不影响运行。
3. 只用 Python 标准库，Python 3.8 以上即可，不用装任何包。

**Task 2：建虚拟环境（题面要求现场做）**

4. 打开命令行（Windows 的 PowerShell 或 cmd，macOS 的 Terminal），进入 `code` 文件夹：

```bash
python -m venv venv
venv\Scripts\activate          # Windows
source venv/bin/activate       # macOS / Linux
python --version
```

提示符前面出现 `(venv)` 就说明虚拟环境已激活。Windows 上若提示禁止运行脚本，改用 cmd 而不是 PowerShell。

**自检**

5. 运行 `python -m unittest test_blockchain -v`。最后应是 `Ran 11 tests ... OK`。中途会打印一两行 `{'index': 3, 'data': [400]}` 之类，是测试在调用打印函数，正常。

**按顺序演示**

6. `python task1_python_tutorial.py`：Task 1.1 打印 10 条记录（data 从 `[100]` 到 `[1000]`），Task 1.2/1.3 再用类打印一遍。`python task1_python_tutorial.py 3` 只打印 index 3 那一条。
7. `python lab3_demo.py`：创世块、记录两块、取上一块、整条链以及每块的哈希，最后 `Hash links valid: True`。
8. `python lab4_demo.py`：难度 4 下挖两块，每块打印 proof 和用了多少次哈希、多少秒；整条链里两块的哈希都以 `0000` 开头；`Chain valid: True`；然后篡改第 1 块，`Chain valid: False block 1: hash does not meet the PoW target`。
9. 有时间可以跑 `python lab4_demo.py 5` 展示难度 5（平均约 100 万次哈希，几秒钟），或 `python difficulty_experiment.py 4 50` 展示工作量随难度的增长。

## 概念

### Q1 What is a blockchain?

> "A blockchain is a list of blocks where each block stores the hash of the block before it. Changing any block changes its hash and breaks the link to the next block, so the history is tamper-evident. Proof of Work then makes rewriting that history expensive."

区块链 = 用哈希首尾相接的块序列。哈希链让篡改留下痕迹，PoW 让篡改变贵。见 [[Lab3-4 区块链与 PoW 的 Python 实现#5 链：用哈希把块串起来|第 5 节]]。

### Q2 What is in each of your blocks, and why?

> "Five fields: index, timestamp, data, proof and previous_hash. Index is the position, timestamp records when it was mined, data is the content, proof is the nonce found by Proof of Work, and previous_hash links it to the block before."

见 [[Lab3-4 区块链与 PoW 的 Python 实现#3 一个块里有什么|第 3 节]]。

### Q3 What is the genesis block? Why is its previous hash '0'?

> "It is the first block, created when the Blockchain object is instantiated. There is no earlier block to point to, so previous_hash is a fixed placeholder, '0'. It is not mined, so its proof is 0."

见 [[Lab3-4 区块链与 PoW 的 Python 实现#3 一个块里有什么|第 3 节]]。

### Q4 Why SHA-256? Which properties do you rely on?

> "It is deterministic, so anyone can recompute a block's hash. It has the avalanche effect, so a tiny change gives a completely different hash. It is preimage resistant, so the only way to find a hash with four leading zeros is trial and error — that is what makes the puzzle work. And it is collision resistant, so one hash identifies one block."

见 [[Lab3-4 区块链与 PoW 的 Python 实现#4.1 SHA-256 提供的四个性质|4.1]]。

### Q5 Why do you use json.dumps with sort_keys=True?

> "hashlib only accepts bytes, so the dictionary has to be encoded first. The same dictionary can be written with its keys in different orders, which would give different hashes. sort_keys makes the encoding unique, so the same block always has the same hash."

可以现场指出 `test_hash_is_independent_of_key_order` 这项测试。见 [[Lab3-4 区块链与 PoW 的 Python 实现#4.2 为什么要先 json.dumps，而且要 sort_keys|4.2]]。

### Q6 If I change the data in one block, how do you detect it?

> "Its hash changes, so the next block's previous_hash no longer matches, and with Proof of Work its own hash also stops meeting the difficulty target. is_chain_valid checks both and reports which block failed."

现场可以直接演示：`lab4_demo.py` 最后一段就是篡改。见 [[Lab3-4 区块链与 PoW 的 Python 实现#6.5 校验|6.5]]。

### Q7 Is the hash chain alone enough to stop tampering?

> "No. Without Proof of Work an attacker can change a block and simply recompute every later hash — SHA-256 takes microseconds, so the whole chain can be rewritten almost instantly and it would look consistent. The chain makes tampering visible; Proof of Work makes it expensive."

这是理解 PoW 意义的关键一问。见 [[Lab3-4 区块链与 PoW 的 Python 实现#5 链：用哈希把块串起来|第 5 节]]。

## Proof of Work

### Q8 Explain your proof_of_work function.

> "The block's other fields are fixed; only the proof can change. I start the proof at 0, hash the whole block, and check whether the hash starts with four zeros. If not, I increase the proof by one and try again. check_proof is False until a hash meets the target."

见 [[Lab3-4 区块链与 PoW 的 Python 实现#6.1 谜题是什么|6.1]]。

### Q9 What does the difficulty mean? How many hashes do you expect at difficulty 4?

> "Difficulty is the number of leading hexadecimal zeros required. Each hex digit is zero with probability one in sixteen, so four zeros has probability $16^{-4}$, and on average it takes $16^4 = 65\,536$ tries. Each extra zero multiplies the work by sixteen."

见 [[Lab3-4 区块链与 PoW 的 Python 实现#6.2 平均要试多少次|6.2]]。

### Q10 Why did one block take much longer than the other?

> "Each try is an independent trial, so the number of tries is geometrically distributed. Its standard deviation is about as large as its mean, so one block can take a few hundred tries and another several hundred thousand. Only the average is predictable."

演示时两块的 proof 往往差好几倍，助教很可能会问。实测里难度 4 的 200 块，最少 136 次、最多 48 万次。见 [[Lab3-4 区块链与 PoW 的 Python 实现#6.2 平均要试多少次|6.2]]。

### Q11 Why do you hash the whole block instead of new_proof² − previous_proof²?

> "That version only links the proof to the previous proof, not to the block's data. If someone changes the data, the proof is still valid, so the attacker only has to recompute the hashes and never redoes any work. Hashing the whole block binds the proof to the data, so changing anything means re-mining that block and every block after it."

见 [[Lab3-4 区块链与 PoW 的 Python 实现#6.4 与常见教程写法的区别|6.4]]。

### Q12 What happens if someone tampers with the last block?

> "There is no later block whose previous_hash would expose it, so the link check cannot catch it. The Proof of Work check still does: the tampered block's hash no longer starts with four zeros."

有一项测试专门验证这一点。见 [[Lab3-4 区块链与 PoW 的 Python 实现#6.5 校验|6.5]]。

### Q13 Why is the timestamp fixed during mining?

> "The timestamp is part of the hashed block. If it changed on every try, the stored block would not match the hash that was found. I take the time once when mining starts and keep it until the proof is found."

### Q14 How much work does it take to rewrite history?

> "Changing block k means re-mining block k and every block after it, so about $(n-k)\times 16^d$ hashes. In a real network honest miners keep adding blocks at the same time, so the attacker needs more computing power than the rest of the network combined — the 51% attack."

见 [[Lab3-4 区块链与 PoW 的 Python 实现#6.3 PoW 为什么让篡改变贵|6.3]]。

### Q15 What are the advantages and limitations of PoW?

> "Advantages: it is simple, anyone can verify a proof with one hash, it needs no trusted authority, and rewriting history costs real computing power. Limitations: it wastes energy on hashes that have no other use, block time is slow and unpredictable, throughput is low, and an attacker with a majority of the hash rate can take over."

可以顺带提 PoS：按持有的权益而不是算力选出块者，省能耗。见 [[Lab3-4 区块链与 PoW 的 Python 实现#7 这个程序离真正的区块链还差什么|第 7 节]]。

### Q16 Could two miners find valid proofs at the same time?

> "Yes. Then the chain temporarily forks. In Bitcoin each node follows the chain with the most accumulated work, so one branch wins as soon as the next block extends it, and the other block is abandoned. My program runs on a single machine, so forks cannot happen in it."

### Q17 How is your chain different from Bitcoin?

> "Mine runs on one machine with no network, stores one data item per block instead of many transactions in a Merkle tree, uses a fixed difficulty, has no mining reward, and does not check timestamps. Bitcoin also compares the hash with a numeric target rather than counting leading zeros, so it can adjust difficulty smoothly."

见 [[Lab3-4 区块链与 PoW 的 Python 实现#7 这个程序离真正的区块链还差什么|第 7 节]]。

## 代码与 Python

### Q18 What is a virtual environment and why use one?

> "It is an isolated Python installation inside the project folder. Packages installed there don't affect the system Python or other projects, so the project's dependencies are reproducible."

本程序只用标准库，虚拟环境主要是题面 Task 2 的要求。

### Q19 What is a docstring, and how is it different from a comment?

> "A docstring is the triple-quoted string at the start of a function, class or module. Python stores it, so help() can show it. My docstrings state each function's arguments and return value. A # comment is ignored by Python and explains individual lines."

可以现场演示 `python -c "import blockchain; help(blockchain.Blockchain.mine_block)"`。

### Q20 Why did you put the functions into a class?

> "The chain and the methods that change it belong together. The class keeps the list of blocks and the difficulty as its state, and every method works on that state, so several independent chains can exist at once — the tests create a new one for each case."

### Q21 How did you interpret Task 1.1?

> "Ten blocks whose data goes from 100 to 1000 in steps of 100, each stored as a one-element list, with the index giving the position from 0 to 9."

题面原句有歧义；若助教理解为 index 也从 100 起，改 `record_blocks` 里一行即可。

### Q22 How do you know your code is correct?

> "Eleven unit tests: the ten Task 1 records, the genesis block fields, the hash links, key-order independence of the hash, every mined hash meeting the target, the proof being the smallest one that works, and detection of tampering in the middle and at the end of the chain."

现场直接跑 `python -m unittest test_blockchain -v`。
