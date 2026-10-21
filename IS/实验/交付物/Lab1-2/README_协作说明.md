# IS Lab 1–2 运行说明

这个文件夹是 Information Security 第 1–2 次实验（古典密码：凯撒、暴力破解、频率分析、Playfair）的 MATLAB 程序、输出与图。

## 最短流程

1. 把整个 `Lab1-2/` 文件夹（`代码/`、`figures/`、`output/`）拷到要运行的电脑上。MATLAB 处理中文路径有问题时，放到纯英文路径下，并把 `代码` 改名为 `code`，不影响运行。
2. MATLAB 当前文件夹切到 `代码/`，运行 `test_lab`，最后一行应为 `44 checks, 0 failed`。
3. 按任务运行：`task1_caesar`、`task2_bruteforce`、`task3_frequency`、`task4_playfair`；或 `run_all` 一次跑完（日志存到 `output/run_all_log.txt`）。
4. Playfair 测试任意关键词和明文：`playfair('关键词', '明文')`；解密：`playfair('关键词', '密文', 'decrypt')`。默认严格按实验手册的规则；明文里出现"同一组两个 X"或"落单的末字母是 X"时，可加第 4 个参数 `'qfill'` 改用 Q 作填充。

版本：R2016b 或更新可算出全部结果；画图与导出图片建议 R2020a 或更新，画图失败不会中断计算。

## 详细说明

每个任务的输出怎么看、各种报错的含义、实验原理的问答：

- 课程包里的 `IS/实验/Lab1-2 现场可能被问到的问题.md`
- 原理：`IS/笔记/L2 古典密码与密码分析.md`；程序与结果：`IS/实验/Lab1-2 古典密码的 MATLAB 实现.md`

这三份是 Obsidian 笔记，用 Obsidian 打开阅读效果最好，也可以用任何文本编辑器看。
