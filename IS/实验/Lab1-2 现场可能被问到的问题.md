---
chapter: Lab1-2
status: 已完成
---

# Lab1-2 现场可能被问到的问题

> [!info] 这份文件怎么用
> 实验课上要当场运行程序、接受助教的新输入测试，助教也可能问原理和代码。这里先列现场操作步骤，再按任务列出可能被问到的问题。
> 每题给一两句**可以直接用英文说出口的回答**，再给中文要点；每题末尾链回讲解原文，那里有完整的来龙去脉。
> 原理在 [[L2 古典密码与密码分析]]，程序与结果在 [[Lab1-2 古典密码的 MATLAB 实现]]。

## 现场操作

**开场前：拿到程序**

1. 打开课程包仓库 `https://github.com/AlanCommitK/Fourth-year1stSemester`，点绿色的 `Code` → `Download ZIP`，解压。
2. 程序在解压后的 `IS/实验/交付物/Lab1-2/` 里，包含 `代码/`、`figures/`、`output/` 三个文件夹。把整个 `Lab1-2` 文件夹拷到实验室电脑上。
3. 如果实验室电脑的 MATLAB 处理中文路径出问题（打不开文件、找不到函数），把 `Lab1-2` 放到纯英文路径下（如 `C:\lab12\`），并把 `代码` 文件夹改名为 `code`。程序用的都是相对路径，改名不影响运行。
4. 版本要求：R2016b 或更新就能跑出全部数字；画图和导出图片最好是 R2020a 或更新。画图失败不会中断计算，只会打印一行 `[Plotting skipped: …]`。

**开场前：自检**

5. 打开 MATLAB，把当前文件夹切到 `代码/`（左侧文件浏览器里双击进入，或在命令行 `cd` 过去）。
6. 运行 `test_lab`。最后一行应为 `44 checks, 0 failed`，说明这台电脑上程序完全正常。如果出现 `FAIL`，记下是哪一行，照常运行各任务演示（任务结果不依赖自测），事后再查。`run_all` 开头也会先跑一遍自测，自测出问题时它会打印一行提示并继续跑完四个任务。

**按任务演示**（每个脚本都能单独运行，输出打印在命令行窗口）

| 要演示 | 运行 | 屏幕上要指给助教看的 |
| --- | --- | --- |
| Task 1 | `task1_caesar` | 两步计算：GUID 之和 5918919 → 数字和 $k=42$ → $k_{\text{mod}}=16$；明文；密文；最后一行 `true`（解密回原文） |
| Task 2 | `task2_bruteforce` | 26 行候选里只有 $k=16$ 那行是英文；"match: true" |
| Task 3 | `task3_frequency` | 频率表；三行频率攻击：把 j 当 e 得 $k=5$（错），当 t 得 16（对），第二高频的 u 当 e 得 16（对）；然后弹出柱状图 |
| Task 4 | `task4_playfair` | monarchy 矩阵与手册图 2 一致（`true`）；balloon → IB SU PM NA；exceeding、KeChen、MingxiangBian 三个矩阵 |
| 全部 | `run_all` | 依次跑完，日志存到 `output/run_all_log.txt` |

**助教给新的关键词和明文时**

```matlab
playfair('关键词', '明文')                  % 加密：打印矩阵、预处理结果、密文、解密回来的结果
playfair('关键词', '密文', 'decrypt')       % 解密
playfair('关键词')                          % 只看矩阵
```

例：`playfair('monarchy', 'balloon')`。关键词和明文可以含空格、大小写、标点、J，程序会按手册规则自动处理。输出里的 `Round trip OK : true` 表示解密回来与预处理结果一致。程序输出的密文是两两一组、大写、带空格的（如 `IB SU PM NA`）；助教写成小写或不带空格，是同一个答案。

**程序默认严格按手册的规则处理。** 只有两种输入可能和助教的答案不同：**同一组里两个字母都是 X**（如 TAXXI），或**落单的最后一个字母是 X**（如 BOX）。按手册，它们会产生 XX 这一对（BOX → BO XX）。如果助教期望的是改用 Q 做填充（BO XQ），在命令末尾加 `'qfill'` 重跑（理由见 [[#Q28 What happens with a double X, or a final X?|Q28]]）：

```matlab
playfair('关键词', '明文', 'encrypt', 'qfill')
```

**出问题时**

- 报 `Unrecognized function or variable '…'`（旧版本是 `Undefined function or variable '…'`）：当前文件夹不在 `代码/` 里，切过去再运行。
- 图弹不出来、或打印了 `[Plotting skipped: …]`：不影响结果，命令行里的数字照样有效；任务 3 的三张图已经存在 `figures/` 里，直接打开给助教看。
- 解密时报 `Ciphertext must have an even number of letters` 或 `Valid Playfair ciphertext never contains J`：这是程序在拒绝一段**不可能是 Playfair 密文**的输入——Playfair 密文总是成对出现，矩阵里也没有 J。请助教核对一下输入（见 [[#Q35 What if I give you an odd-length ciphertext, or one with a J?|Q35]]）。

## Task 1 凯撒加密

### Q1 How did you get k?

**答**："We added our two GUIDs, 2959453 plus 2959466, which gives 5918919. The handout calls the digit sum k: that is 42. Then k_mod is 42 mod 26, which is 16, and 16 is the shift we use. Our code also reproduces the handout's own example, which gives 9."

要点：两步，先加 GUID，再加各位数字，最后模 26。屏幕上 42 和 16 两个数都会出现：42 是手册记的 $k$，16 是实际移位 $k_{\text{mod}}$。详见 [[Lab1-2 古典密码的 MATLAB 实现#3.1 由 GUID 算 k|实验笔记 3.1]]。

### Q2 Why mod 26?

**答**："Because the alphabet has 26 letters and the shift wraps around. Shifting by 42 is exactly the same as shifting by 16, so mod 26 just brings k into the range 0 to 25."

详见 [[L2 古典密码与密码分析#3.1 规则：把字母变成数，做模 26 加法|L2 3.1]]。

### Q3 How does your code do the shift and the wrap-around?

**答**："Each letter is turned into a number from 0 to 25 by subtracting the ASCII code of 'a'. We add k, take mod 26, and turn it back into a letter. MATLAB's mod always gives a value between 0 and 25, even for negative numbers, so decryption is simply encryption with minus k."

要点：MATLAB 里字符就是 ASCII 码；`mod` 对负数也返回 0–25；大小写分开处理，非字母不动。详见 [[Lab1-2 古典密码的 MATLAB 实现#3.2 实现|实验笔记 3.2]]。

### Q4 Why did you keep the spaces and punctuation?

**答**："So that the brute-force candidates are easy to read by eye in Task 2. In real use this would be a weakness, because word lengths leak information, so we also output the conventional form: capital letters only, in groups of five."

详见 [[Lab1-2 古典密码的 MATLAB 实现#3.2 实现|实验笔记 3.2]]、[[L2 古典密码与密码分析#4.2 语言的统计指纹|L2 4.2]]（词长泄露）。

### Q5 How many keys does the Caesar cipher have?

**答**："Twenty-five useful keys. A shift of 0 or 26 leaves the text unchanged, so only shifts 1 to 25 actually encrypt."

详见 [[L2 古典密码与密码分析#3.1 规则：把字母变成数，做模 26 加法|L2 3.1]]。

### Q6 What if k_mod had come out as 0?

**答**："Then the 'ciphertext' would be the plaintext itself, because a shift of zero changes nothing. In that case we would have to pick another key."

### Q7 Would your mod trick work in C or Java?

**答**："Not directly. In C and Java the % operator can return a negative number for a negative input, so we would have to add 26 before taking the remainder. MATLAB's mod, like Python's %, always returns a value between 0 and 25."

详见 [[Lab1-2 古典密码的 MATLAB 实现#3.2 实现|实验笔记 3.2]]。

### Q8 Is the Caesar cipher symmetric? Block or stream?

**答**："It is symmetric: the same key encrypts and decrypts. It is a monoalphabetic substitution cipher: every letter is replaced using one fixed shift. The block and stream categories are really meant for modern ciphers."

详见 [[L2 古典密码与密码分析#1.3 给密码分类的三个维度|L2 1.3]]。

## Task 2 暴力破解

### Q9 How does your brute-force attack work?

**答**："It decrypts the ciphertext with every possible key from 0 to 25 and prints all 26 candidates. Only one of them reads as English, and that gives the key."

详见 [[Lab1-2 古典密码的 MATLAB 实现#4.1 做法|实验笔记 4.1]]。

### Q10 How do you know which candidate is correct?

**答**："By looking: only the line for k equals 16 is readable English. We also added an automatic check, a chi-squared score that compares each candidate's letter counts with normal English. The correct key scores about 171; the next best is about 1640, roughly ten times larger."

要点：$\chi^2=\sum (O_i-E_i)^2/E_i$，越小越像英文。详见 [[Lab1-2 古典密码的 MATLAB 实现#4.3 让机器替眼睛判断：χ² 统计量|实验笔记 4.3]]。

### Q11 Does the key you found match the key you used?

**答**："Yes, both are 16. It has to match: only shifting back by the same amount restores the original text."

详见 [[Lab1-2 古典密码的 MATLAB 实现#4.2 结果与回答|实验笔记 4.2]]。

### Q12 Why does brute force need readable plaintext?

**答**："Trying every key is easy; the hard part is recognising the right answer. Readable English stands out. If the plaintext were random or compressed data, all 26 candidates would look equally meaningless, and brute force alone could not pick the key."

详见 [[L2 古典密码与密码分析#3.2 为什么一下午就能破|L2 3.2]]。

### Q13 Why is brute force so easy here, but impossible for AES?

**答**："The Caesar cipher has only 25 keys, so trying them all takes nanoseconds. AES-128 has two to the power of 128 keys. Even at a billion keys per second, trying half of them would take around ten to the twenty-one years."

详见 [[L2 古典密码与密码分析#2.3 暴力破解要花多少|L2 2.3]]。

## Task 3 频率分析

### Q14 What do your bar charts show?

**答**："The ciphertext chart is the plaintext chart shifted 16 places to the right, wrapping around. The shape is exactly the same; only the letters are relabelled. For example, the tallest bar moves from t in the plaintext to j in the ciphertext."

要点：$t=19$，$19+16=35$，$35 \bmod 26=9$，即 j。详见 [[Lab1-2 古典密码的 MATLAB 实现#5.1 统计与作图|实验笔记 5.1]]。

### Q15 Did the frequency method work?

**答**："Yes, but not on the first guess. In this text the most common letter is t, not e: the word substitution appears four times with three t's each, and the word 'the' appears only seven times. So assuming the top ciphertext letter is e gives k equals 5, which is wrong. Assuming it is t, or taking the second most common letter as e, gives 16, which is correct."

详见 [[Lab1-2 古典密码的 MATLAB 实现#5.2 最高频字母不是 e|实验笔记 5.2]]。

### Q16 Why does frequency analysis work at all?

**答**："Because a monoalphabetic substitution cipher, such as Caesar, maps each plaintext letter to the same ciphertext letter every time. It hides which letter it is, but not how often it appears, so the ciphertext keeps the frequency fingerprint of English."

详见 [[L2 古典密码与密码分析#4.1 密钥空间 26! 也救不了它|L2 4.1]]。

### Q17 Why is it even easier for Caesar than for a general substitution cipher?

**答**："In Caesar every letter is shifted by the same k, so guessing one letter correctly fixes the whole key. A general substitution cipher needs all 26 letters worked out, using common words like THE."

详见 [[L2 古典密码与密码分析#4.4 凯撒是频率攻击最简单的情形|L2 4.4]]、[[L2 古典密码与密码分析#4.3 频率攻击的四步|L2 4.3]]。

### Q18 How does your chart compare with the English chart in the book?

**答**："The plaintext chart has the same overall pattern as general English: e, t, a, i, n and s are high, and j and z are zero. The differences come from the text being short, only 634 letters, and full of technical words, so t is higher and e lower than average. The ciphertext chart does not look like English at all until you shift it back."

详见 [[Lab1-2 古典密码的 MATLAB 实现#5.1 统计与作图|实验笔记 5.1]]。

### Q19 Why is the frequency attack less reliable on short texts?

**答**："Published letter frequencies are averages over very large amounts of text. A short text can easily depart from them because of a few repeated words, as ours did with t. Using all 26 letters, as the chi-squared score does, is much more robust than relying on the single most common letter."

详见 [[Lab1-2 古典密码的 MATLAB 实现#5.3 这个方法管用吗|实验笔记 5.3]]。

### Q20 Where does the plaintext come from?

**答**："It is the paragraph given at the end of the handout; it reads like the opening of the classical-encryption chapter of Stallings's textbook. We saved it in plaintext.txt and the program loads it from there, as the handout asks."

## Task 4 Playfair

### Q21 How do you build the matrix?

**答**："Convert the keyword to upper case, remove non-letters, and treat J as I. Then write the keyword letters in order, keeping only the first occurrence of each, and fill the remaining squares with the rest of the alphabet in alphabetical order, row by row."

要点：代码里一句 `unique([关键词, 字母表], 'stable')` 完成"去重 + 保留首次出现 + 补齐字母表"。详见 [[L2 古典密码与密码分析#6.1 造矩阵|L2 6.1]]、[[Lab1-2 古典密码的 MATLAB 实现#6.1 程序如何对应每一条规则|实验笔记 6.1]]。

### Q22 Why are repeated letters in the keyword removed?

**答**："Each letter must appear only once in the matrix. Otherwise a letter would have two positions, and encryption would not be unique."

详见 [[L2 古典密码与密码分析#6.1 造矩阵|L2 6.1]]。

### Q23 Why are I and J combined, and why is there never a J in the ciphertext?

**答**："There are 26 letters but only 25 squares, so two letters must share one. J is chosen because it is very rare in English. Since J is changed to I before encryption and the matrix has no J, the ciphertext can never contain a J; that is also why a Playfair letter count has only 25 letters."

详见 [[L2 古典密码与密码分析#6.1 造矩阵|L2 6.1]]。

### Q24 Why insert a filler between double letters, and why X?

**答**："The rules depend on where the two letters are relative to each other in the matrix, and a letter has no position relative to itself. A fixed pattern for double letters would also leak information. X is used because it is rare in English, so it is easy to recognise and remove after decryption."

详见 [[L2 古典密码与密码分析#6.2 明文预处理|L2 6.2]]。

### Q25 Explain the three encryption rules.

**答**："Same row: each letter is replaced by the one to its right, wrapping around. Same column: by the one below, wrapping around. Otherwise the two letters are opposite corners of a rectangle, and each is replaced by the other corner in its own row."

用 balloon 当场演示：BA 同列 → IB；LX 矩形 → SU；LO 矩形 → PM；ON 同行 → NA。详见 [[L2 古典密码与密码分析#6.3 三条加密规则与解密|L2 6.3]]、[[L2 古典密码与密码分析#6.4 完整算一遍 balloon|L2 6.4]]。

### Q26 Why does decryption move left and up, but use the same rectangle rule?

**答**："Decryption must undo encryption. One step left undoes one step right, and up undoes down. The rectangle rule undoes itself: swapping to the other corner twice brings you back. In our code this is one direction parameter, plus one or minus one."

详见 [[L2 古典密码与密码分析#6.3 三条加密规则与解密|L2 6.3]]、[[Lab1-2 古典密码的 MATLAB 实现#6.1 程序如何对应每一条规则|实验笔记 6.1]]。

### Q27 Why does the decrypted text still contain X and I?

**答**："The filler X and the J-to-I change are part of the input to encryption, so decryption gives them back. The program cannot tell whether an X was a filler or part of a word; a reader removes them from the context. The handout says we do not need to remove them."

详见 [[Lab1-2 古典密码的 MATLAB 实现#6.3 演示结果|实验笔记 6.3]]。

### Q28 What happens with a double X, or a final X?

**答**："Our program follows the handout word for word: a final single X gets an X added, and a double X gets an X inserted, so we get the pair XX, which the same-row rule turns into ZZ. That is still decryptable. Some people prefer Q as the filler in exactly this case, to avoid a pair of equal letters, so our program also has an optional Q mode."

例：box → BO XX → HA ZZ；加 `'qfill'` 时 → BO XQ → HA WS（关键词 monarchy）。详见 [[Lab1-2 古典密码的 MATLAB 实现#6.2 X 本身重复时会出现 XX 这一对|实验笔记 6.2]]。

### Q29 Can a ciphertext pair contain two identical letters?

**答**："Not when the two plaintext letters are different: each rule maps two different squares to two different squares. Following the handout, a double X can produce the plaintext pair XX, and that one becomes a pair like ZZ. A letter is never encrypted to itself, in any case."

详见 [[L2 古典密码与密码分析#6.3 三条加密规则与解密|L2 6.3]]。

### Q30 How many Playfair keys are there?

**答**："A key is a whole 5 by 5 matrix, so there are at most 25 factorial, about 1.6 times ten to the 25, arrangements. In fact fewer are really different, because shifting all rows or all columns cyclically gives the same cipher. The number 676 often quoted is the number of letter pairs, not of keys."

详见 [[L2 古典密码与密码分析#6.5 它强在哪、为什么还是被破|L2 6.5]]。

### Q31 Why is Playfair stronger than Caesar?

**答**："It encrypts pairs of letters, so the single-letter statistics are flattened. On our text the index of coincidence drops from 0.070 for Caesar to 0.049 for Playfair, and the most common letter drops from 13 to 9 percent."

要点：凯撒只给字母换名字，分布形状和 IC 都不变；Playfair 让同一个字母在不同组合里变成不同字母。这是对本实验长文本的观察。详见 [[Lab1-2 古典密码的 MATLAB 实现#7 扩展：Playfair 为什么比凯撒难做频率分析|实验笔记 7]]。

### Q32 How would you break Playfair?

**答**："Count pairs of letters in the ciphertext and match the common ones with common English pairs such as TH and HE. Use the reversal property: if AB encrypts to XY, then BA encrypts to YX. With a known piece of plaintext, the matrix can be rebuilt. A few hundred letters are usually enough."

详见 [[L2 古典密码与密码分析#6.5 它强在哪、为什么还是被破|L2 6.5]]。

### Q33 Why did you use KeChen for the comparison, and why is Playfair's index still above uniform?

**答**："Any keyword would do; we used one of the keywords the handout asked us to show. The index stays above uniform because Playfair only flattens the statistics: letter pairs still carry the structure of English."

详见 [[Lab1-2 古典密码的 MATLAB 实现#7 扩展：Playfair 为什么比凯撒难做频率分析|实验笔记 7]]。

## 关于程序本身

### Q34 How did you test the program?

**答**："Our test script makes 44 checks against results we computed independently: the handout examples, our four keyword matrices, every special case, and 500 random keywords and texts in both modes."

详见 [[Lab1-2 古典密码的 MATLAB 实现#6.4 测试：怎么确认它对|实验笔记 6.4]]。

### Q35 What if I give you an odd-length ciphertext, or one with a J?

**答**："The program refuses it with a clear message, because no Playfair ciphertext can look like that: letters are always encrypted in pairs, and the matrix contains no J."

### Q36 Your round trip passes. Does that prove the encryption is correct?

**答**："No, any reversible transformation would pass a round trip. Correctness comes from matching the handout's examples, the monarchy matrix and IB SU PM NA, and from expected values computed by a separate implementation."

详见 [[Lab1-2 古典密码的 MATLAB 实现#6.4 测试：怎么确认它对|实验笔记 6.4]]。

### Q37 How is the code organised, and where is each rule?

**答**："Each function does one job, and the task scripts only call them and print the results."

| 规则 | 文件 |
| --- | --- |
| 由 GUID 求 k | `k_from_guids.m` |
| 凯撒加密、解密 | `caesar_encrypt.m`、`caesar_decrypt.m` |
| 暴力破解与 $\chi^2$ | `caesar_bruteforce.m` |
| 字母计数、频率攻击 | `letter_frequency.m`、`frequency_attack.m` |
| 造矩阵（去重、J→I、补齐字母表） | `playfair_matrix.m` |
| 明文预处理（插 X、补 X） | `playfair_prepare.m` |
| 同行、同列、矩形三条规则 | `playfair_crypt.m` |

详见 [[Lab1-2 古典密码的 MATLAB 实现#2 程序结构与运行方式|实验笔记 2]]。
