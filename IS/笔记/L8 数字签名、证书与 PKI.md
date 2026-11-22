---
chapter: L8
status: 已完成
---

# L8 数字签名、证书与 PKI

> [!info] 这一讲在做什么
> 上一讲留下一个缺口：Diffie–Hellman 挡不住中间人；上一讲的补法是给交换的值签名，可验签又需要一把确知属于对方的公钥，而**公钥只是一个数，这个数并不带着主人的名字**。这一讲分两步补上：
> 1. **数字签名**：一段只有私钥持有者造得出、任何人都能检验的值。它给出消息认证码（message authentication code，MAC：用双方共享的密钥算出的校验值，见 [[L6 对称密码的安全使用]]）给不了的东西——能说服第三方的证据，即不可否认性；
> 2. **证书**：一个你已经信任的机构——**证书颁发机构**（certificate authority，CA）——对"这把公钥属于 bank.com"这句话签名。证书一级级连成链，终止于预装在浏览器里的根；客户端按一张清单逐项检查之后才信任。签发、分发、检验、吊销（到期前宣布作废）证书的这一整套机构、标准和软件，叫 **PKI**（public key infrastructure，公钥基础设施）。
>
> 最后看这套体系在现实中怎样失败（误发、最弱一环、过期、吊销失灵），以及现在靠什么兜底。
> 课件四个部分大体就是按这条线排的，本笔记沿用这个框架，做了三处重组：
> - "为什么签摘要"的三条理由、课堂活动 2(c) 那个伪造值的真正含义、"不加填充的 RSA"（RSA 是 L7 学的公钥算法；不加填充即直接对裸数做幂运算，见 5.4）和"弱哈希"（哈希是把任意长消息压成定长摘要的函数）两种失败，课件分散在三页，这里合成一节（[[#5 签摘要，不签消息|第 5 节]]）；
> - 吊销（课件第 3 部分）和过期、短有效期（第 4 部分）是同一条因果链——吊销靠不住，于是缩短有效期，于是过期变多，于是自动化——这里合成一节（[[#11 证书的寿命：吊销与过期|第 11 节]]）；
> - 四道课后任务各自放回所属的小节（4.6、12.4、12.5、14.2）。
>
> 对应课件 `Lecture8_Signatures_PKI_26_TUL.pdf`，37 页。封面写 Lecture 8，页脚全写 Lecture 7；课件提到别的讲次都按页脚编号，本笔记一律换成 Moodle 编号：课件的 "Lecture 6" 是 [[L7 公钥密码]]，"Lecture 5" 是 [[L6 对称密码的安全使用]]，"Lecture 8" 是 [[L9 实用安全协议]]，"Lecture 1" 是 [[L1 信息安全基础]]。教材 Stallings 第 8 版第 13 章（数字签名）和第 15 章（公钥分发、X.509 证书、PKI）；课件参考页写的 "Chapter 14" 是第 7 版的章号。课件推荐的标准是 RFC 5280（X.509 证书格式及其校验规则）和 RFC 6962（证书透明度，Certificate Transparency：要求公共证书公开登记的机制，见 12.3）；RFC（Request for Comments）是互联网工程任务组 IETF（Internet Engineering Task Force）发布的标准文档。
> 课堂活动 1–4 课件自带答案页，活动 5（四道课后任务）没有，这里的解答是自己做的；数值都用程序核对过，证书判定都用 OpenSSL（最常用的开源密码工具库）复现过。课件有三处内容被页面上的提示框盖住，已从 PDF 文字层补全。课程总览与考情见 [[00 IS 课程信息与考情]]。

> [!tip] 考点
> 课件只有第 36 页预告 capstone（前 10 讲收尾的综合评估）时出现过 "exam"，但学习目标和活动标注把要会的东西说得很清楚。课程介绍列了六条 ILO（intended learning outcome，预期学习成果，全文见 [[00 IS 课程信息与考情]]），本讲服务 ILO 2 "interpret a number of different security protocols"，活动 1 还点到 ILO 3（评估系统的漏洞、推荐最合适的方案）。
> - 第 3 页学习目标 "**Produce and verify an RSA signature by hand**"；第 11 页 "Square and reduce at every step. Do not compute 7²⁷ in full."；第 37 页 "Practise signing and verifying by hand until it is automatic"——手算签名与验证，写出平方-乘过程，见 [[#4.4 手算：平方-乘|4.4]]；
> - 第 3 页 "State what a digital signature provides that a MAC cannot, and why"，见 [[#2.2 签名与 MAC：差在对称与不对称|2.2]]；
> - 第 7 页 "Three things students routinely get wrong"，见 [[#4.3 关于签名的三个误解|4.3]]；
> - 第 10 页 "The rule that resolves every row: To PROVE something about yourself, use YOUR private key. To HIDE something from everyone but one person, use THEIR public key."，见 [[#3.1 一条规则：证明用自己的私钥，隐藏用对方的公钥|3.1]]；
> - 第 9 页 "Item (e) needs two operations. Say which happens first, and why the order matters."；第 10 页 "Choosing the weaker mechanism deliberately, and being able to say why, is the ILO 3 skill."，见 [[#3.2 课堂活动 1：六个场景|3.2]]；
> - 第 11 页 "Part (c) is the one that shows why a signature is worth anything at all."，见 [[#4.5 篡改与抵赖：活动 2 的 (c)(d)|4.5]] 与 [[#5.3 不签摘要会怎样：存在性伪造|5.3]]；
> - 第 3 页 "List what an X.509 certificate contains and what a client checks before trusting it" 与 "Activity 4 is an ILO 2 task in miniature."；第 24 页 "The last check is the one people forget"；第 35 页 "Basic Constraints is the classic example."，见 [[#9.1 九个字段|9.1]]、[[#10.2 客户端的八项检查|10.2]]、[[#10.4 课堂活动 4：找出问题|10.4]]；
> - 第 3 页 "Explain how a chain of trust works, and identify the ways PKI fails in practice"，见 [[#10.1 根、中间、终端|10.1]] 与 [[#12 PKI 怎么失败|第 12 节]]；
> - 第 31 页 "automate the operation so the security property can be strengthened — is one of the most useful ideas in the whole module."，见 [[#11.5 短有效期加自动化|11.5]]；
> - 第 36 页 capstone："Structured evaluation of unseen systems, which is what the report and the exam scenarios ask for."，本讲的样板是 [[#12.4 课后任务 3：评估一个内部 CA|12.4]]。
>
> 模拟卷（去年版）没有直接考签名、证书的题，相关的有四处：
>
> | 题号 | 分值 | 题目 | 对应 |
> | --- | --- | --- | --- |
> | Q2(d) | 10 | "What are the essential steps for proper functioning of public key decryption algorithm? Explain with the aid of a diagram." | 规范答法在 [[L7 公钥密码]]；本讲 [[#7.3 分发公钥的办法\|7.3]] 补充第 ② 步"放进公开目录"的缺陷 |
> | Q3(a)(ii) | 3 | 列出区块链区别于传统数据库的三个特征，参考答案含 Non-repudiation | [[#2.1 四个性质\|2.1]]：区块链的不可否认性来自交易签名 |
> | Q1(c) | 7 | 用图解释主动攻击并举例（参考答案列了 masquerading、repudiation） | [[#7.1 中间人：换掉公钥，什么运算都不报错\|7.1]] 是冒充，[[#2.1 四个性质\|2.1]] 的不可否认性对付抵赖 |
> | Q2(b) | 4 | "What is avalanche effect of an encryption algorithm?" | 主答案在 [[L3 分组密码与 DES#7.1 定义与实测\|L3 7.1]]；本讲 [[#5.1 先哈希再签名\|5.1]] 是哈希上的同一现象 |
>
> 期末 4 道 25 分大题。本讲最可能出的是：手算 RSA 签名与验证、再分析篡改；论证 MAC 为什么给不了不可否认性；列出证书字段及各自防什么；给几张证书判断接受还是拒绝、说出哪一项检查失败；评估一个 PKI 设计并按严重程度排序。

## 1 起点：公钥只是一个数

### 1.1 上一讲留下的缺口

[[L7 公钥密码]] 讲了 **Diffie–Hellman 密钥交换**（Diffie–Hellman key exchange）：两个素不相识的人各在公开信道上发一个公开值，就能算出同一个共享秘密，旁听者算不出来。但它挡不住主动攻击者：攻击者坐在中间，和 Alice 跑一遍交换、再和 Bob 跑一遍，两边各自和攻击者共享了一个秘密。这叫**中间人攻击**（man-in-the-middle attack，MITM：攻击者插在通信双方之间，冒充每一方去和另一方通信）。

缺口是一环扣一环暴露出来的：

1. Diffie–Hellman 被攻破，直接原因是**交换的值没有认证**，收到的值只是一个数，分不清是 Bob 的还是攻击者的；
2. 上一讲的补法是"认证这次交换"：各方用自己的私钥给发出的值签名，对方验签；
3. 可验签要用签名者的公钥，于是问题变成"这把公钥真是 Bob 的吗"——而公钥同样只是一个数。

课件第 2 页的诊断："The mathematics was never the problem. The problem is that a public key is just a number, and numbers do not carry names."

上一讲课后任务 4 问的正是这件事：Alice 收到一把自称属于她银行的公钥，怎么判断真假？课件收集了学生最常给的三种答案：

| 学生的答案 | 课件点评 |
| --- | --- |
| 当面交换公钥 | 可行，但不能扩展：你不可能和每个网站见面 |
| 把公钥公布在网站上 | 访问网站要走 HTTPS，而 HTTPS 本身就需要一把你已经信任的公钥——循环论证 |
| 找一个你信任的人为它担保 | 正确，这就是整讲的内容 |

表里的 **HTTPS**（HTTP Secure）是浏览器与网站之间加了加密与认证的网页协议，地址栏的小锁就是它；底下干活的是 **TLS**（Transport Layer Security，传输层安全协议），负责握手（handshake：建立连接时双方交换几轮消息，协商算法、认证身份、商定密钥）和加密数据，[[L9 实用安全协议]] 专门讲。

### 1.2 解法：不直接验公钥，而是验一句关于它的话

课件第 2 页的思路："You cannot verify a stranger's key directly, so instead you verify a STATEMENT about that key, signed by a party you already trust."

"这把公钥属于 bank.com"这句话，加上一个可信机构的签名，就是**证书**（certificate）。信任问题并没有消失："it is moved to a much smaller number of parties, once."

本讲按顺序讲两样东西：

1. **签名**：怎样让一段数据只能由一个人产生、而任何人都能检验（第 2–6 节）；
2. **证书与 PKI**：怎样用签名把公钥和名字绑在一起，这套体系怎样运转、又怎样失败（第 7–13 节）。

## 2 数字签名要保证什么

### 2.1 四个性质

**数字签名**（digital signature）：签名者用自己的私钥对一条消息算出的一段值；任何持有他公钥的人都能检验这段值确实出自那把私钥、消息也没被改过。课件第 5 页："A handwritten signature on paper is easy to forge and hard to verify. A digital signature is the reverse: infeasible to forge, and anyone can check it."

| # | 性质 | 含义 | 回答的问题 |
| --- | --- | --- | --- |
| 1 | **真实性**（authenticity） | 验证者能确定签名是谁产生的：签名通过私钥绑定在一个具体的签名者身上 | 谁发的？ |
| 2 | **完整性**（integrity） | 消息改动哪怕 1 位，签名就验不过；签名覆盖的是内容，不只是发送者 | 被改过吗？ |
| 3 | **不可否认性**（non-repudiation） | 签名者事后不能否认签过：只有他持有私钥，所以只有他造得出这个签名 | 他能抵赖吗？ |
| 4 | **公开可验证性**（public verifiability） | 任何持有公钥的人都能验证——包括法官、审计员，或者对签名者和接收者都不信任的第三方 | 谁能检查？ |

性质 1 里的"谁"，严格说是"哪把私钥的持有者"。这把私钥属于哪个真实身份，签名本身回答不了——这是第 7 节的问题，也是需要证书的原因。

和 [[L1 信息安全基础#4.2 三个扩展属性|L1 的扩展属性]]对照：L1 说真实性可以靠 MAC 或签名，不可否认性要靠带可信时间戳的签名，并且定义成收发双方都不能否认。本讲讲的是其中"签名者不能否认发过"这一半；接收方不能否认收到要靠回执签名，可信时间戳用来防止签名者事后声称"私钥早就丢了"，这两点本讲不展开。模拟卷 Q3(a)(ii) 把不可否认性列为区块链的特征，也是因为每笔交易都由发起者的私钥签名。

### 2.2 签名与 MAC：差在对称与不对称

MAC 的做法：发送方用双方共享的密钥对消息算出一个短校验值（叫标签，tag），接收方用同一把密钥重算比对。课件拿来对比的是 **CMAC**（cipher-based MAC，基于分组密码的 MAC），即用 [[L4 AES]] 的分组密码构造的 MAC。

| | MAC（如 CMAC） | 数字签名 |
| --- | --- | --- |
| 生成用的密钥 | 双方共享的密钥 | 签名者的**私钥** |
| 验证用的密钥 | 同一把共享密钥 | 签名者的**公钥** |
| 谁能验证 | 只有持有共享密钥的人 | **任何人** |
| 完整性 | 有 | 有 |
| 真实性 | 有，但只对持有密钥的人成立 | 有，对所有人成立 |
| 不可否认性 | **没有** | **有** |
| 速度 | 很快（对称运算） | 慢（公钥运算） |

课件第 6 页对"不可否认性"那一行的论证：

- **MAC 为什么给不了**：Alice 和 Bob 共享密钥。Bob 拿出一条带有效标签的消息说是 Alice 发的，Alice 可以如实回答"Bob 自己也造得出来"，第三方分辨不出是谁造的。"Symmetry is the whole problem."
- **签名为什么可以**：只有 Alice 持有她的私钥；Bob 只有公钥，公钥造不出签名。所以能通过验证的签名只可能来自 Alice，任何第三方都能自己检验这一点。"Asymmetry is the whole answer."

拆开看，不可否认性要两个条件同时成立：**（一）只有一方能产生**这段值；**（二）第三方能检验**它。MAC 两条都不满足：双方都能产生标签；第三方没有密钥就无法检验，把密钥交给他，他也能伪造了。

> [!warning] 签名比 MAC 多出的不止一条
> 课件第 5 页："Property 3 is the one that separates a signature from everything we have built so far. Properties 1 and 2 a MAC already gives you."
> 误：签名和 MAC 只差不可否认性这一条。
> 正：**性质 4 公开可验证性 MAC 也没有**——课件第 6 页的表写着 MAC "Only holders of the shared key" 能验证；而且性质 3 正建立在性质 4 之上，没有第三方能检验，就谈不上向第三方举证。答"签名能提供而 MAC 不能提供什么"时写这两条，并说明前者依赖后者。

## 3 用谁的钥匙

### 3.1 一条规则：证明用自己的私钥，隐藏用对方的公钥

公钥的两种用法 [[L7 公钥密码]] 都讲过（机密性模式与认证模式）。课件第 10 页把选钥匙归结为一句："To PROVE something about yourself, use YOUR private key. To HIDE something from everyone but one person, use THEIR public key."

- **证明**（签名）：用**自己的私钥**签，别人用**你的公钥**验。公钥人人都有，所以人人可验；私钥只有你有，所以只有你能签。
- **隐藏**（加密）：用**对方的公钥**加密，对方用**他的私钥**解密。人人都能加密发给他，只有他能解开。

遇到"用谁的哪把钥匙"的题，先问这一步是要**证明**关于自己的事，还是要对别人**隐藏**内容。

### 3.2 课堂活动 1：六个场景

题目：对每个场景选机制（MAC 还是签名），写出**生成**和**检验**各用哪把钥匙。可用的钥匙：Alice 的公钥、Alice 的私钥、Bob 的公钥、Bob 的私钥、两人的共享密钥。

| | 场景 | 机制 | 生成用 | 检验用 | 理由 |
| --- | --- | --- | --- | --- | --- |
| a | Alice 给 Bob 发合同；闹上法庭时，法官必须能确认是 Alice 签的 | 签名 | Alice 的私钥 | Alice 的公钥 | 法官是第三方，只有签名能当作给双方之外的人看的证据 |
| b | 同一机房里两台已共享密钥的服务器，要在高速内部链路上发现数据损坏 | MAC | 共享密钥 | 共享密钥 | 密钥已经有了，速度要紧，外人永远不需要验证；用签名是浪费 |
| c | Alice 发布软件更新，一万台她从没打过交道的设备要确认更新出自她 | 签名 | Alice 的私钥 | Alice 的公钥 | 一万个验证者与她没有共享秘密；用 MAC 得和每台设备各共享一把密钥 |
| d | Alice 给 Bob 发一条别人不能读的消息 | 都不是——加密 | Bob 的公钥 | Bob 的私钥 | 只要机密性。钥匙翻转了：加密给谁，就用谁的公钥 |
| e | 别人不能读，**并且** Bob 日后能证明出自 Alice | 先签名，再加密 | 先 Alice 的私钥，再 Bob 的公钥 | 先 Bob 的私钥，再 Alice 的公钥 | 见下文 |
| f | CA 声明某把公钥属于 bank.com | 签名 | CA 的私钥 | CA 的公钥 | 这就是证书：人人都要能检验，CA 也不能否认签发过（这一行在课件上被遮住，取自文字层） |

**(e) 为什么先签后加密。** Alice 先对明文签名，再把"明文 + 签名"一起用 Bob 的公钥加密；Bob 先用自己的私钥解密，再用 Alice 的公钥验签。反过来先加密、再对密文签名有两个问题：

1. 签名只证明 Alice 见过这串**密文**，不证明她认可其中的**内容**（课件的理由）。发生争议时，法官要看的是明文和明文上的签名。
2. 签名挂在密文外面，截获者能把它剥掉、换上自己的签名，冒充是自己发的。

[[L7 公钥密码]] 把两者合用写成 $Z=\mathrm{E}\big(PU_b,\mathrm{E}(PR_a,X)\big)$，只加密签名运算的结果；那是因为 L7 的模型直接对消息 $X$ 做私钥运算，RSA 下 $\mathrm{E}(PR_a,X)$ 用 Alice 的公钥一解就还原出 $X$。本讲签的是摘要（第 5 节），摘要还原不出消息，所以要把明文和签名一起加密。两种写法的顺序相同，都是先签后加密。

**(b) 不要为签名而签名。** 课件强调签名比 MAC 慢约一千倍，而它解决的问题——和第三方的纠纷——很多系统根本没有。同一机柜、同一所有者、密钥已就位的两台服务器，只需要完整性。有意选较弱的机制并说清理由，正是课件说的 ILO 3 能力。

> [!example]- 先签后加密也不完美（课件外，选读）
> Bob 解密后得到"Alice 的明文 + Alice 的签名"，他可以原封不动地用 Carol 的公钥重新加密转发给 Carol；Carol 验签通过，会以为 Alice 是写给她的。这叫**暗中转发**（surreptitious forwarding，Davis 2001 年指出，S/MIME 和 PGP 这两种邮件签名与加密标准都有这个问题，见[[#13 网页之外的 PKI|第 13 节]]）。修补办法是在被签名的内容里写明收件人。

## 4 RSA 签名

### 4.1 同一套运算，钥匙反过来

先回顾 [[L7 公钥密码]] 的 RSA（Rivest–Shamir–Adleman，以三位发明者命名的公钥算法）：选两个大素数 $p,q$，模数 $n=pq$，欧拉函数 $\phi(n)=(p-1)(q-1)$；公钥 $\{e,n\}$，私钥 $\{d,n\}$，私有指数 $d$ 满足 $ed\equiv1 \pmod{\phi(n)}$；加密 $C=M^e \bmod n$，解密 $M=C^d \bmod n$。

签名把同一个运算用在相反的钥匙上，这就是 L7 的**认证模式**：

$$
\text{签名（Alice 用私钥）：}\ S=H^d \bmod n
\qquad
\text{验证（任何人用公钥）：}\ S^e \bmod n \overset{?}{=} H
$$

- $H$ 是消息的**摘要**（digest）：把消息送进**哈希函数**（hash function，也叫散列函数：公开的、把任意长度输入压成固定长度输出的函数）得到的短值，当作一个小于 $n$ 的整数。为什么签摘要而不签消息本身，是[[#5 签摘要，不签消息|第 5 节]]的内容，这一节先把 $H$ 当成给定的数。
- 验证者自己从收到的消息算出摘要，再和 $S^e \bmod n$ 比较：相等就接受。
- 签名和消息**一起发送**，消息通常是明文。

课件第 7 页用同一对密钥把两种用法并排（公钥 $\{3,55\}$、私钥 $\{27,55\}$，即 L7 课堂活动 3 造的那一对，$p=5,\ q=11$）：用公钥加密 $M=7$，$C=7^3 \bmod 55=343 \bmod 55=13$；用私钥签 $H=7$，$S=7^{27} \bmod 55=28$（过程见 [[#4.4 手算：平方-乘|4.4]]）。"Same number in, two entirely different results out ... one hides, the other proves."

### 4.2 为什么验证能还原摘要

验证算的是 $(H^d)^e=H^{ed}$。写 $ed=1+k\phi(n)$（$k$ 是某个整数），由欧拉定理（$H$ 与 $n$ 互素时 $H^{\phi(n)}\equiv1 \pmod n$）：

$$
H^{ed}=H\cdot\big(H^{\phi(n)}\big)^k\equiv H \pmod n
$$

和 RSA 解密还原明文是同一件事：$(M^e)^d=M^{ed}$，$(H^d)^e=H^{ed}$，指数都是 $ed$。完整证明（包括 $H$ 与 $n$ 不互素的情形）见 [[L7 公钥密码]]。检查这一对密钥：$\phi(55)=4\times10=40$，$ed=3\times27=81=2\times40+1$。

**谁能做什么**：算 $S$ 必须知道 $d$；从公开的 $e$ 推出 $d$ 需要 $\phi(n)$，求 $\phi(n)$ 要把 $n$ 分解成 $p\times q$。$n=55$ 一眼就能分解，真实的 $n$ 是 2048 位以上，分解不了。

### 4.3 关于签名的三个误解

> [!warning] 课件第 7 页点名的三个误解
> - 误："签名就是用私钥加密。"正：只对 RSA 成立。DSA（Digital Signature Algorithm，数字签名算法）和 ECDSA（Elliptic Curve DSA，椭圆曲线数字签名算法）能签名却根本不能加密（[[#6.1 DSA、ECDSA、Ed25519|6.1]]），只有 RSA 恰好两者共用一套算术。L7 讲认证模式时"用私钥加密"的说法，就是这种 RSA 上的简化，L7 的提示框已说明，按它答题不扣分。
> - 误："签名能让消息保密。"正：不能。签名和通常是明文的消息**一起**发送；要保密，还得另外加密。
> - 误："用收件人的钥匙签名。"正：用**自己的**私钥签，因为要证明的是"这是我"；收件人的公钥管的是机密性。

### 4.4 手算：平方-乘

课堂活动 2（第 11 页）：Alice 的密钥 $n=55,\ e=3,\ d=27$，消息摘要 $H=7$。(a) 算签名 $S=7^{27} \bmod 55$；(b) 像 Bob 那样验证：算 $S^3 \bmod 55$；(c) 攻击者把签名从 $S$ 改成 $S+1$ 重发，验证它，Bob 会得出什么结论？(d) 用一句话说明是哪一个事实使 Alice 不能抵赖。

$7^{27}$ 是 23 位整数，要用 [[L7 公钥密码]] 的**平方-乘**（square-and-multiply）：把 $d$ 写成二进制 $27=(11011)_2$，$r$ 从 1 开始、从最高位逐位读，每位先 $r\leftarrow r^2 \bmod n$，该位为 1 时再 $r\leftarrow r\cdot H \bmod n$。平方让指数翻倍、乘 $H$ 让指数加 1，所以指数依次是 $1\to3\to6\to13\to27$。

**(a) 签名**：

| 读到的位 | 平方 | 取模 | 位为 1 时乘 7 | 结果 $r$ | 此时 $r=7^{?}$ |
| --- | --- | --- | --- | --- | --- |
| 1 | $1^2=1$ | 1 | $1\times7=7$ | 7 | $7^1$ |
| 1 | $7^2=49$ | 49 | $49\times7=343=6\times55+13$ | 13 | $7^3$ |
| 0 | $13^2=169=3\times55+4$ | 4 | — | 4 | $7^6$ |
| 1 | $4^2=16$ | 16 | $16\times7=112=2\times55+2$ | 2 | $7^{13}$ |
| 1 | $2^2=4$ | 4 | $4\times7=28$ | **28** | $7^{27}$ |

$S=28$。这是 L7 的格式二，也是课件提示的做法（课件答案页把五步排成两列网格，要按行读）。用 L7 的格式一（逐次平方表）同样得分，L7 推荐考场上用它，或者拿它复核：$7^1=7$，$7^2=49$，$7^4=49^2=2401\equiv36$，$7^8=36^2=1296\equiv31$，$7^{16}=31^2=961\equiv26$；$27=16+8+2+1$，$26\times31=806\equiv36$，$36\times49=1764\equiv4$，$4\times7=28$。

**(b) 验证**：$28^3=21952=399\times55+7$，所以 $S^3 \bmod 55=7=H$，签名有效。边算边约更快：$28^2=784\equiv14$，$14\times28=392\equiv7$。

### 4.5 篡改与抵赖：活动 2 的 (c)(d)

**(c)**：$S'=29$，$29^3=24389=443\times55+24$，$24\neq7$，Bob 拒绝。他不知道是谁、为什么改的，只知道收到的不是 Alice 签的——这正是完整性保护应该告诉他的全部。（记住 24 这个数，[[#5.3 不签摘要会怎样：存在性伪造|5.3]] 要用。）

**(d)**：课件答案："Only Alice holds d = 27. Bob, and everyone else, holds only e = 3, which cannot create signatures — only check them. So a value that verifies under e could only have been produced by the holder of d."

这句话有两个前提，答题时最好点出：

1. $n$ 大到无法分解，否则任何人都能从 $e$ 算出 $d$。$n=55$ 时攻击者瞬间分解出 $5\times11$、算出 $d=27$，所以课件说这个例子"does NOT show a secure system"——"The arithmetic is genuine; only the size is a toy."
2. 私钥从没被偷过："Non-repudiation also rests on one non-mathematical assumption: that Alice's private key was never stolen. Cryptography cannot establish that."

### 4.6 课后任务 2：签 H = 12

题目：用同一对密钥（$n=55,\ e=3,\ d=27$）给摘要 $H=12$ 签名，再验证，写出平方-乘过程。

| 读到的位 | 平方 | 取模 | 位为 1 时乘 12 | 结果 $r$ |
| --- | --- | --- | --- | --- |
| 1 | $1^2=1$ | 1 | $1\times12=12$ | 12 |
| 1 | $12^2=144=2\times55+34$ | 34 | $34\times12=408=7\times55+23$ | 23 |
| 0 | $23^2=529=9\times55+34$ | 34 | — | 34 |
| 1 | $34^2=1156=21\times55+1$ | 1 | $1\times12=12$ | 12 |
| 1 | $12^2=144\equiv34$ | 34 | $34\times12=408\equiv23$ | **23** |

$S=23$。验证：$23^3=12167=221\times55+12$，等于 $H$，有效。

第 4 步出现 $34^2\equiv1 \pmod{55}$：34 是模 55 下 1 的"非平凡平方根"（不是 $\pm1$ 却平方得 1），中间值因此回到 12，后两步重复前两步。这是小模数的巧合，不是算错。

## 5 签摘要，不签消息

### 5.1 先哈希再签名

真实系统从不直接对消息签名，而是对摘要签名。最常用的哈希函数是 **SHA-256**（Secure Hash Algorithm 256，美国标准的安全哈希算法），输出 256 位即 32 字节。

![[L8 先哈希再签名.png]]

*签名方先哈希再用私钥签摘要；验证方自己重算摘要，和用公钥从签名里还原出的值比较。*

Alice 把消息 $m$ 送进哈希函数得到 $H=h(m)$，算 $S=H^d \bmod n$，发出 $(m,S)$。验证方对收到的 $m$ 自己算 $h(m)$，对 $S$ 算 $S^e \bmod n$，两者相等才接受。消息改 1 位，$h(m)$ 就面目全非：

- `SHA-256("Alice pays Bob 100")` = `15fd38c0a310472112be808157dbe38b6a5173b5a9072c62b362a5da9d6b94bf`
- `SHA-256("Alice pays Bob 101")` = `219e14632b486612ab39cb2c54ee44c561f85269fb81160a1b63b8ae903dabba`

只改最后一个字符，256 位里有 112 位不同，接近一半。这是 [[L3 分组密码与 DES#7.1 定义与实测|雪崩效应]]在哈希上的表现。

### 5.2 三条理由

课件第 8 页：

1. **速度**："Public-key operations are roughly a thousand times slower than symmetric ones. Signing a 4 GB file directly would be absurd; signing a 32-byte digest is instant."
2. **大小**：RSA 只能对小于 $n$ 的整数签名，2048 位的密钥最多签 256 字节（$2048/8$），摘要永远放得下。（严格说是"小于 $n$ 的整数"，加了填充后能容纳的有效内容还要少一些，结论不变。）
3. **方案本身的安全**："Signing raw values makes some algebraic forgeries possible. Hashing first destroys the algebraic structure an attacker would exploit." 这一条最重要，下一小节讲清楚。

### 5.3 不签摘要会怎样：存在性伪造

[[L7 公钥密码]] 讲过的**教科书 RSA**（textbook RSA：不加填充、直接对数做幂运算的 RSA）有两个代数漏洞，放到签名上就是两种伪造。

**第一种**。活动 2(c) 算出 $29^3 \bmod 55=24$，按验证规则，$S=29$ 正是"摘要 24"的合法签名。攻击者不用私钥，只要**先随便挑一个签名值 $S'$，再算 $H'=S'^e \bmod n$**，就得到一对必然通过验证的 $(H',S')$。这叫**存在性伪造**（existential forgery）：不用私钥造出"某一条"消息的有效签名，只是这条消息由数学算出、不由攻击者挑。它是最轻的一类攻破，但一个签名方案只要允许它，就被认为不安全。

教材第 13.1 节有两套分类，不要混：

- **按攻破的程度**（攻击者最终做到了什么）从重到轻：完全攻破（拿到私钥）、通用伪造（能给任何消息造签名）、选择性伪造（能给自己挑的某条消息造签名）、存在性伪造；
- **按攻击者掌握什么**：只有公钥；见过若干消息及其签名；能让签名者签自己选的消息（选择消息攻击）。

教科书 RSA 在最弱的"只有公钥"条件下就能做存在性伪造。

**第二种：可乘性**（malleability），即 L7 讲加密时的可乘性换到了签名上。记 $\text{Sig}(H)=H^d \bmod n$（对 $H$ 的签名），因为 $(H_1H_2)^d=H_1^d\cdot H_2^d$：

$$
\text{Sig}(H_1)\cdot\text{Sig}(H_2)\equiv\text{Sig}(H_1H_2) \pmod n
$$

用本讲的数：$\text{Sig}(7)=28$，$\text{Sig}(12)=23$，$28\times23=644=11\times55+39\to39$；而 $7\times12=84\equiv29$，直接算 $29^{27} \bmod 55$ 也是 39。拿到两个签名，就能不用私钥造出第三个；攻击者手里的已签值越多，能拼出的组合越多。如果签的是裸消息（比如金额），这就有实际意义。

**先哈希为什么能挡住**：伪造出来的只是"某个摘要的签名"。要把它变成一条真消息的签名，攻击者还得找到 $m$ 使 $h(m)=24$（或 29），即攻破哈希的原像抗性（[[#5.5 哈希必须具备的三个性质|5.5]]）。

> [!warning] 活动 2(c) 的真正含义
> 课件给 (c) 的标题是 "The forgery fails"。
> 误：改签名的伪造失败了，所以教科书 RSA 签名伪造不了。
> 正：$(24,29)$ 本身就是一对合法签名，教科书 RSA 允许任何人做存在性伪造；安全要靠"先哈希、再填充"。课件在第 8、14 页讲了原则，但没把它和 (c) 联系起来。

### 5.4 填充：真实系统签的是什么

课件第 14 页把"不加填充的 RSA"列为一种失败："The same problem as textbook RSA encryption in Lecture 6. The fix is the same: standard padding, never raw."

**填充**（padding）：签名前先把摘要按标准格式扩展成和模数一样长的数，再做幂运算。标准是 RFC 8017（即 PKCS#1 v2.2；PKCS 是 RSA 公司起草的公钥密码标准系列），两种做法：

- **PKCS#1 v1.5 签名**：要签的数是 `00 01 FF FF … FF 00 ‖ DigestInfo`，DigestInfo 是"哈希算法的标识 + 摘要"，中间用一串 FF 填满（‖ 表示拼接）。格式固定，至今在证书里广泛使用。
- **RSA-PSS**（probabilistic signature scheme，概率签名方案）：编码里混入随机盐值（salt，每次签名随机取的一串数），同一条消息每次签出不同的值；有严格的安全证明，新系统推荐用它。

填充之后两种伪造都失效：随手挑的 $S'$ 算出的 $S'^e \bmod n$ 是一个看似随机的 2048 位数，恰好符合 `00 01 FF … FF 00` 加正确结构的概率可以忽略；两个合法编码的乘积也不再是合法编码。

### 5.5 哈希必须具备的三个性质

签名的安全压在哈希上："If it fails, the signature fails with it." 课件用三句话描述哈希必须满足的性质，没给名字：

| 性质 | 课件原话 | 含义 | 挡住的对签名的攻击 |
| --- | --- | --- | --- |
| **原像抗性**（preimage resistance，也叫单向性） | "Given a digest, you cannot find a message producing it." | 给定摘要 $y$，找不到 $m$ 使 $h(m)=y$ | 把存在性伪造得到的"某摘要的签名"变成真消息的签名 |
| **第二原像抗性**（second-preimage resistance） | "Given a message, you cannot find a second one with the same digest." | 给定 $m$，找不到 $m'\neq m$ 使 $h(m')=h(m)$ | 给**别人已签好的**文件找摘要相同的替身 |
| **抗碰撞性**（collision resistance） | "And you cannot find any two messages that collide." | 找不到任何一对 $m\neq m'$ 使 $h(m)=h(m')$ | 攻击者**自己准备**一对摘要相同的文件，骗你签无害的那份，再把签名挪到有害的那份 |

三者的差别在攻击者能自由选多少：原像只给一个摘要，第二原像给定了一条消息，碰撞则两条都由攻击者挑——自由度最大，所以抗碰撞是最强的要求，也最先被攻破。

**生日界**（birthday bound）决定了找碰撞要多少次，[[L4 AES#1.1 DES 不是被破解的，是老了|L4 讲 64 位分组太小]]时用过。记摘要长 $\ell$ 位：随机算 $N$ 条消息，约有 $N^2/2$ 对，每对相同的概率是 $2^{-\ell}$，期望碰撞数约 $N^2/2^{\ell+1}$，$N=2^{\ell/2}$ 时达到 $1/2$。所以 $\ell$ 位哈希只提供约 $\ell/2$ 位的抗碰撞强度：SHA-256 是 $2^{128}$，128 位输出的 **MD5**（Message Digest 5，第 5 版消息摘要算法，1992 年）只有 $2^{64}$，实际攻击还远快于此。

课件第 14 页的"弱哈希"失败就是抗碰撞被攻破："Get an innocuous document signed, attach the signature to a damaging one." MD5 在 2004 年被找到碰撞；更危险的是**选择前缀碰撞**（chosen-prefix collision）：两份文件的开头可以各自任意指定，只在末尾补一段碰撞块，于是能做成两份内容完全不同、各自有意义的文件——2008 年研究者就是这样用 MD5 伪造出一张受浏览器信任的 CA 证书。**SHA-1**（Secure Hash Algorithm 1，160 位输出）2017 年被找到碰撞，2020 年连选择前缀碰撞也做到了。两者都已退役。

> [!warning] 哈希的构造不在区块链那半讲
> 课件第 8 页："How hash functions are constructed is covered in the blockchain half of this course."
> 误：后十讲会讲 SHA-256 内部怎么造。
> 正：后十讲只**使用**哈希（哈希指针、Merkle 树、工作量证明，都是建立在哈希之上的区块链机制），没有一讲讲哈希的构造。考试要的是三个性质和"签名依赖它们"；想看构造，读 Stallings 第 8 版第 11 章。

## 6 其他签名算法与失败方式

### 6.1 DSA、ECDSA、Ed25519

课件第 13 页："RSA is not the only signature algorithm, and outside legacy systems it is no longer the most common."

| 算法 | 是什么 | 特点（课件） |
| --- | --- | --- |
| RSA | 用私有指数 $d$ 做模幂，和加密同一套算术 | 验证很快、签名慢；密钥 2048 或 3072 位；"Still ubiquitous in certificates" |
| DSA | 专为签名设计、基于离散对数问题，**不能加密** | 签名快、验证较慢；**每次签名都需要一个新的随机数** |
| ECDSA | 把 DSA 搬到椭圆曲线上（椭圆曲线见 [[L7 公钥密码]]） | 当今主流；256 位密钥的安全性与 3072 位 RSA 相当，签名也小得多 |
| **Ed25519** | 现代的曲线签名方案，设计目标是"难以被实现错" | **确定性**：每次签名不需要随机数，消除了下一小节的失败方式；越来越成为默认 |

课件第一句和 RSA 行的"证书里到处都是"有点张力：网页证书里 RSA 至今很常见，ECDSA 占优的主要是新签发的证书和握手签名。

- **离散对数问题**（discrete logarithm problem）：L7 的记号是已知素数 $q$、本原根 $\alpha$ 和 $Y=\alpha^X \bmod q$，求 $X$。DSA 标准换了一套字母：素数模数 $p$、子群的阶 $q$（$q$ 整除 $p-1$）、生成元 $g$（模 $p$ 下阶为 $q$ 的元素，作用相当于 L7 的 $\alpha$）、私钥 $x$、公钥 $y=g^x \bmod p$。这里的 $p,q$ 和 RSA 的 $p,q$ 无关，$q$ 也不是 L7 那个素数模数。
- "256 位 ECC（elliptic curve cryptography，椭圆曲线密码）与 3072 位 RSA 相当"指两者都提供约 128 位**安全强度**（security strength：破解约需 $2^{128}$ 次运算），出自 NIST（National Institute of Standards and Technology，美国国家标准与技术研究院）的 SP 800-57。
- Ed25519 是 **EdDSA**（Edwards-curve Digital Signature Algorithm，爱德华兹曲线数字签名算法）在 edwards25519 曲线（与 L7 提到的 Curve25519 等价）上的实例。

课件底线："DSA, ECDSA and Ed25519 sign but cannot encrypt. 'Signing is encryption with the private key' is true of RSA alone."

> [!warning] DSA 已经退役（2026 年的现状）
> 误：DSA 是现行可选的签名算法之一。
> 正：FIPS 186-5（2023 年；FIPS 即 Federal Information Processing Standards，美国联邦信息处理标准）不再批准用 DSA 生成新签名，只允许验证旧签名，同时把 EdDSA 纳入批准名单。抗量子签名 ML-DSA（FIPS 204）、SLH-DSA（FIPS 205）已于 2024 年发布，背景见 [[L7 公钥密码]]。考试按课件的四种答即可。

### 6.2 随机数复用：ECDSA 最致命的失败

DSA 和 ECDSA 每签一次名，都要取一个新的、保密的随机数 $k$——一种**一次性随机数**（nonce，number used once）。课件："Use the same one twice and the private key can be recovered directly from the two signatures, by simple algebra."

直觉：DSA 签名有两部分 $(r,s)$。$r$ 只由 $k$ 决定；$s=k^{-1}(H+xr) \bmod q$（$q$ 是上一小节说的子群的阶）里有两个未知数，随机数 $k$ 和私钥 $x$。一次签名给一个方程，解不出来；同一个 $k$ 用两次，就是两个方程、两个未知数，先解 $k$ 再解 $x$。识别方法：两个签名的 $r$ 相同。

课件说这是 [[L6 对称密码的安全使用]] 里 GCM（Galois/Counter Mode，一种加密兼认证的工作模式）随机数复用的同一个病："same cause, worse consequence: not one message lost, but the key itself." 真实案例：2010 年索尼 PlayStation 3 的固件签名每次用同一个 $k$，研究者据此算出了索尼的 ECDSA 私钥。

Ed25519 的修补：$k$ 不再取自随机数发生器，而是用"私钥派生的一段秘密 + 待签消息"做哈希算出。同一条消息总得到同一个 $k$（签名也相同，无害），不同消息得到不同的 $k$。（ECDSA 也有同样思路的确定性版本，RFC 6979。）

> [!example]- 推导与玩具数值：同一个 k 签两次，私钥怎样被解出来（课件外，考试不要求公式）
> **DSA 签名**（FIPS 186-4 的定义，该版已被 186-5 取代；Stallings 13.4 节）：取随机 $k$，$r=(g^k \bmod p) \bmod q$，$s=k^{-1}(H+xr) \bmod q$。验证时算 $w=s^{-1}$、$u_1=Hw$、$u_2=rw$（模 $q$），$v=(g^{u_1}y^{u_2} \bmod p) \bmod q$，$v=r$ 则接受。
> **玩具参数**：$p=23,\ q=11,\ g=4$（$4^{11}\equiv1 \pmod{23}$），$x=7$，$y=4^7 \bmod 23=8$。取 $k=4$：$r=(256 \bmod 23) \bmod 11=3$，$k^{-1} \bmod 11=3$。
> - 签 $H_1=3$：$s_1=3\times(3+7\times3)=72\equiv6$，签名 $(3,6)$；
> - 签 $H_2=5$：$s_2=3\times(5+21)=78\equiv1$，签名 $(3,1)$。两个都通过验证，$r$ 都是 3。
>
> **攻击者的代数**：两式相减消去 $xr$：
> $$s_1-s_2\equiv k^{-1}(H_1-H_2)\ \Rightarrow\ k\equiv(H_1-H_2)(s_1-s_2)^{-1} \pmod q,\qquad x\equiv(s_1k-H_1)\,r^{-1} \pmod q$$
> 代入：$k\equiv(-2)\times5^{-1}=(-2)\times9\equiv81\equiv4$；$x\equiv(24-3)\times3^{-1}=21\times4=84\equiv7$，与真值一致。
> ECDSA 结构相同，只是 $r$ 改成曲线上点 $kG$ 的 x 坐标模 $n$——这里的 $n$ 是曲线基点 $G$ 的阶，和 RSA 模数无关。

### 6.3 五种失败方式

课件第 14 页开头："As with every other primitive in this module, the mathematics is not usually the weak point."

| 失败方式 | 发生了什么 |
| --- | --- |
| ECDSA 随机数复用 | 私钥从两个签名直接解出（[[#6.2 随机数复用：ECDSA 最致命的失败\|6.2]]） |
| 弱哈希 | 碰撞让一份文件上的签名适用于另一份（[[#5.5 哈希必须具备的三个性质\|5.5]]） |
| 不加填充的 RSA | 代数伪造，修补是标准填充（[[#5.4 填充：真实系统签的是什么\|5.4]]） |
| 私钥被盗 | "No mathematical property survives the key being copied."窃贼签的每个签名都完美通过验证——"Which is why signing keys live in hardware modules, and why revocation exists at all." |
| 验错了东西 | 实现只检查签名有效，却不检查用的是**谁的**公钥，或不检查被签数据到底说了什么——"Real vulnerabilities have come from libraries that returned 'valid' without checking the signer at all." |

**硬件安全模块**（hardware security module，HSM）：保管私钥、在内部完成签名运算的防篡改硬件，私钥导不出来。但能调用 HSM 的人仍能让它代签，签出来的同样完美通过验证，所以还要限制、记录谁能调用。

"验错了东西"的例子：2014 年苹果 "goto fail" 漏洞，多写的一行代码让 TLS 实现跳过了服务器签名的检查；2022 年 Java 的 ECDSA 验证接受 $r=s=0$ 这种明显无效的签名。

课件总结："Four of these five are implementation or operational failures." 课件没说例外是哪条，按道理是弱哈希（算法本身被攻破）；不加填充也可算方案设计的错，但它有现成的标准修补，属于没按标准实现。

## 7 信任问题

### 7.1 中间人：换掉公钥，什么运算都不报错

[[#2.1 四个性质|2.1]] 说签名能确定"哪把私钥的持有者"签的。第 2 部分的标题页（第 15 页）接着说："You can verify a signature perfectly and still have no idea who signed it." 第 16 页："It says nothing whatsoever about who that holder is."

![[L8 中间人替换公钥.png]]

*中间人 Darth 只换掉了一把公钥，之后每一步密码运算都正常成功。图只画了加密方向。*

图中四步（课件第 16 页；Darth 是 L7 沿用教材的攻击者名字）：

1. Darth 截下 Alice 向 Bob 索要公钥的请求；
2. Darth 把**自己的**公钥发回去，声称是 Bob 的；
3. Alice 用这把公钥加密发给"Bob"的消息；
4. Darth 用自己的私钥解开、读、改，再用 Bob 真正的公钥加密转发给 Bob。

签名方向同理，只是箭头反过来：Bob 发给 Alice 的签名消息被 Darth 截下、篡改，Darth 用自己的私钥重新签名，Alice 按以为是 Bob 的 $K_{\text{Darth}}$ 验证，照样通过。"No cryptographic operation fails at any point." 这是 L1 讲的**冒充**（masquerade，见 [[L1 信息安全基础#5.3 具名的攻击|L1 5.3]]），一种[[L1 信息安全基础#5.2 被动攻击与主动攻击|主动攻击]]。

缺的是："A binding between a KEY and an IDENTITY. Cryptography can prove that two messages came from the same key holder. It cannot, by itself, tell you that the key holder is your bank." 一句话："Identity is not a mathematical property." 这就是 [[#1.1 上一讲留下的缺口|1.1]] 第 3 环；课件说上一讲"authenticate the exchange"的答案不完整，"Today completes it."

### 7.2 信任起点问题

课件第 16 页的信任起点问题（the bootstrapping problem，也叫自举问题）："To trust a new key you need a key you already trust. So trust cannot be created out of nothing — it has to start somewhere, and every system that claims otherwise has simply hidden where it started."

所以工程上要做的不是避开起点，而是让它"small, visible and manageable"。证书体系的起点是浏览器里预装的那几百张**根证书**（root certificate：自己签自己、被直接信任的顶层 CA 证书，[[#10.1 根、中间、终端|10.1]] 详讲）。

### 7.3 分发公钥的办法

课件第 17 页列了三种。表里的**指纹**（fingerprint）是公钥的哈希值，短到可以念出来核对；**SSH**（Secure Shell，安全外壳协议）是远程登录协议，第一次连接时显示服务器公钥的指纹让你确认，之后就记住它，这叫**首次使用即信任**（trust on first use，TOFU）。

| | 直接交换 | 公开目录 | 证书 |
| --- | --- | --- | --- |
| 怎么做 | 当面交出公钥，或在已可信的信道上念出指纹 | 可信机构维护"名字—公钥"目录，参与者登记、别人来查 | 可信机构对"名字—公钥"的绑定签名，持有该机构公钥的人都能验证 |
| 为什么行 | 真正安全，没有第三方；SSH 主机密钥、核对软件指纹就这么做 | 概念简单；换钥匙时只改一处 | 验证不需在线查询，证明随公钥走；一把可信公钥能验成千上万张证书；使用时不必联系机构 |
| 为什么不行 | 超过几个人就扩展不了 | 目录必须时刻在线；它是单一攻击目标，攻破它就能替换任何人的公钥；通往目录仍需可信信道 | 机构的公钥必须安全地拿到一次；机构被攻破后果严重 |

> [!warning] 教材列的是四种
> 误：分发公钥只有直接交换、公开目录、证书三种办法。
> 正：Stallings 第 8 版 15.3 节列四种——**公开发布**（public announcement：各人自己广播公钥，谁都能冒名发布）、**公开可访问的目录**（publicly available directory）、**公钥权威机构**（public-key authority：在线机构，每次有人查某人的公钥，它就用自己的私钥签一份应答发回；它必须每次在线，是瓶颈也是攻击目标）、**公钥证书**（public-key certificates：把权威机构的签名做成可离线验证、随公钥流转的文件）。四种是一条演进线，证书去掉了"权威机构必须时刻在线"这最后一个瓶颈。课件把"公开发布"放在了第 2 页的学生答案里，"公钥权威机构"没有出现。

模拟卷 Q2(d)（10 分，"公钥解密的基本步骤，配图"）的参考答案和规范答法见 [[L7 公钥密码]]。本讲的补充落在第 ② 步"每个用户把公钥放进公开登记处，并收集别人的公钥"：它正是公开目录，没有把公钥与身份绑定。按 L7 的角色，Alice 用 Bob 的公钥加密——可 Alice 拿到的"Bob 的公钥"可能是 Darth 的（7.1）。答这道题时在第 ② 步后补一句"公钥与身份的绑定须由证书保证"并点出中间人风险，是有依据的加分点。

## 8 证书

### 8.1 证书是一条签了名的陈述

课件第 18 页："A certificate is a signed statement: 'this public key belongs to this name', signed by an authority whose own key you already hold." 证书里被绑定的实体（网站、组织或个人）叫**主体**（subject），签发它的 CA 叫**签发者**（issuer）。

一张网站证书的诞生与使用分五步：

1. **主体生成密钥对**：bank.com 生成私钥和配对的公钥，私钥从不离开它的服务器。
2. **主体向 CA 申请**：发送公钥，并证明自己控制这个域名——在网站上放一个 CA 指定的挑战文件，或在域名系统里加一条 CA 指定的记录。
3. **CA 签名**：CA 构造一条结构化记录——名称、公钥、有效期、用途——用**自己的私钥**对整条记录签名。
4. **主体出示证书**：bank.com 把证书发给每个来访的浏览器。证书公开，里面没有秘密。
5. **客户端验证**：浏览器用它**已经持有的** CA 公钥验证 CA 的签名，通过就接受"名字—公钥"的绑定。（这一步在课件上被提示框盖住，取自文字层。）

提示框的话是整套体系的要害："Notice what step 5 requires: the client must ALREADY hold the CA's public key, securely. That key was not obtained by certificate — it shipped with the browser or the operating system. That is where the trust actually starts." 这就是 [[#7.2 信任起点问题|7.2]] 那个起点的具体位置。

第 2 步的细节：

- **DNS**（Domain Name System，域名系统）是把域名翻译成 IP 地址（Internet Protocol address，网上每台主机的数字地址）的互联网目录；只有域名的控制者能往里加记录，所以"按要求加一条记录"能证明控制权。
- 这两种证明方式来自 **ACME**（Automatic Certificate Management Environment，自动证书管理环境，RFC 8555）协议，叫 http-01 和 dns-01 挑战；免费 CA Let's Encrypt 推动了它的普及，意义见 [[#11.5 短有效期加自动化|11.5]]。
- 实际提交的通常是一份 **CSR**（certificate signing request，证书签名请求）：申请者用自己的私钥对"公钥 + 名称"签名，CA 用其中的公钥验这个签名，顺带确认申请者持有配对的私钥。课件第 36 页的实验预告提到了它。

### 8.2 课堂活动 3：自己设计证书

题目（第 19 页）：从零设计证书格式，CA 会对它签名，全世界的浏览器都依赖它。它显然要包含主体名称和公钥，但只有这两项不够。(a) 至少再列四个字段，各说出防的攻击；(b) 一张证书只含名称和公钥、签名正确，说出两种仍然可行的攻击；(c) 证书该保密吗？一句话说理由；(d) CA 的签名到底要覆盖什么？只覆盖一部分会怎样？课件页底："You are reinventing X.509."（X.509 是通行的证书格式标准，第 9 节。）

课件答案给了七个字段：

| 字段 | 内容 | 没有它会怎样 |
| --- | --- | --- |
| 主体名称 | 公钥属于谁：域名、组织或个人 | 公钥是匿名的 |
| 公钥 | 被认证的公钥及其算法 | 这就是被绑定的东西本身 |
| **有效期** | 起始与截止日期（not-before、not-after） | 被盗的私钥永远有效；有日期，损失才有期限 |
| **签发者名称** | 哪个 CA 签发的 | 验证者不知道该用谁的公钥验签名 |
| **序列号** | 签发者分配的唯一编号 | 无法吊销：想撤回一张证书，得先能叫出它的名字 |
| **密钥用途** | 这把公钥能干什么：签名、加密、签发别的证书 | 证书被挪作他用，比如网站证书被拿去签发更多证书 |
| 签名 | CA 对以上**全部**内容的签名 | 以上每个字段都能被篡改而不被发现 |

> [!example]- 活动 3 的 (b)(c)(d) 解答
> **(b)** 课件答案：没有日期，被盗的私钥永远被信任；没有签发者，不知道该验谁的签名。另外两种也成立：没有用途限制，普通证书可被当作 CA 证书签发别的证书（[[#10.4 课堂活动 4：找出问题|活动 4 的 C]]）；没有序列号，出了事无法吊销。
> **(c)** 不该。证书按设计就公开、不含秘密，它的用途就是让所有人读到"这把公钥属于谁"并检验；秘密的私钥从不在证书里。
> **(d)** 签名必须覆盖**每一个**字段（真实格式里连"签名算法"字段也在内），没被覆盖的字段可以随意修改而签名照样有效。攻击者最想改的是主体名称（换成想冒充的域名）和公钥（换成自己的）。
> 课件答案以外还可以答 [[#9.2 扩展才是干活的部分|9.2]] 的扩展：扩展密钥用途、CA 标志、吊销信息的位置，以及签名算法标识（防止把算法换成弱的）。

## 9 X.509 证书格式

### 9.1 九个字段

**X.509** 是 ITU-T（International Telecommunication Union Telecommunication Standardization Sector，国际电信联盟电信标准化部门）制定的证书格式标准，[[L1 信息安全基础#5.1 X.800 的三个词|X.800]] 也出自这个机构。第 3 版（v3）通行全球，每条 HTTPS 连接背后都是它。

![[L8 X.509 v3 证书结构.png]]

*课件第 22 页：X.509 v3 证书从上到下的九个字段。*

- **Version**（版本）：3。
- **Serial number**（序列号）：在同一签发者范围内唯一。
- **Signature algorithm**（签名算法）：如 "SHA-256 with ECDSA"，即先用 SHA-256 算摘要、再用 ECDSA 签名。
- **Issuer name**（签发者名称）：签这张证书的 CA。
- **Validity**（有效期）：not-before / not-after。
- **Subject name**（主体名称）：公钥属于的实体。
- **Subject public key info**（主体公钥信息）：算法 + 公钥本身。
- **Extensions**（扩展，v3 才有）：密钥用途、主体备用名、CA 标志、吊销信息的位置等，见下一小节。
- **Signature**（签名）：CA 对**以上全部内容**的签名。

九项和活动 3 的七个字段一一对得上，多出版本号和签名算法。签名之前的部分合起来叫 **TBSCertificate**（to-be-signed certificate，待签名的证书主体）：CA 对这一整块算摘要、再签名，签名值附在最后。

> [!warning] 课件的字段表做了简化
> 误：X.509 v3 证书就是这九个字段，版本字段里写的是 3。
> 正（RFC 5280 第 4.1 节）：版本号从 0 起算，**"v3" 编码为整数 2**（OpenSSL 显示 `Version: 3 (0x2)`）；第 2 版加入的**签发者唯一标识**（issuerUniqueID）和**主体唯一标识**（subjectUniqueID）两个可选字段课件省略了；**签名算法标识出现两次**，一次在 TBSCertificate 里（受签名保护，防止被换成别的算法），一次在签名值旁边，两者必须一致。考试列字段按课件九项写即可，被问"v2 加了什么"答两个唯一标识。

### 9.2 扩展才是干活的部分

课件："The extensions do the real work."

- **主体备用名**（Subject Alternative Name，SAN）：证书适用的域名清单，如 `DNS:bank.com, DNS:www.bank.com`。"Modern browsers ignore the subject name and use this." 主体名称里过去放域名的那一项叫 **CN**（common name，通用名），Chrome 从 2017 年起完全不看它。SAN 可以写**通配符**（wildcard）`*.bank.com`，只匹配**最左边恰好一级**：匹配 `www.bank.com`，不匹配 `bank.com` 本身，也不匹配 `a.b.bank.com`。
- **基本约束**（Basic Constraints）：其中的 **CA 标志**（CA flag）为 FALSE 时，这张证书**不得**签发别的证书；还可带**路径长度约束**（pathLenConstraint），限定它下面最多还能有几层中间 CA（终端证书不计）。
- **密钥用途**（Key Usage）：一组开关，常见的有数字签名（digitalSignature）、密钥加密（keyEncipherment）、密钥协商（keyAgreement）、签发证书（keyCertSign）、签发吊销列表（cRLSign）。
- **扩展密钥用途**（Extended Key Usage，EKU，课件没提）：限定应用场景，如 TLS 服务器认证（serverAuth）或代码签名（codeSigning）。网站证书必须含 serverAuth。

扩展还可以标成**关键**（critical）：客户端遇到不认识的关键扩展，必须拒绝整张证书。

**为什么基本约束要紧**：客户端若不检查 CA 标志，任何持有普通网站证书的人都能拿它给**任何域名**签证书并被接受。课件："Major browsers and libraries have shipped with exactly this bug, and it converts one cheap certificate into the ability to impersonate the entire web." 例：2002 年微软 IE（Internet Explorer 浏览器）、2011 年苹果 iOS 都出过这个漏洞。

### 9.3 一张证书实际长什么样

用 OpenSSL 签发的一张网站证书（公钥和签名值截短了）。`Data` 那一块就是 TBSCertificate，可以和九个字段逐项对照：

```
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 16:db:4f:91:37:06:6f:a8:…
        Signature Algorithm: ecdsa-with-SHA256
        Issuer: CN = Toy Intermediate CA
        Validity
            Not Before: Nov 21 18:59:33 2026 GMT
            Not After : Feb 19 18:59:33 2027 GMT
        Subject: CN = bank.com
        Subject Public Key Info:
            Public Key Algorithm: id-ecPublicKey
                Public-Key: (256 bit)
                NIST CURVE: P-256
        X509v3 extensions:
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Key Usage: critical
                Digital Signature
            X509v3 Extended Key Usage:
                TLS Web Server Authentication
            X509v3 Subject Alternative Name:
                DNS:bank.com, DNS:www.bank.com
    Signature Algorithm: ecdsa-with-SHA256
    Signature Value:
        30:46:02:21:00:8d:41:69:…
```

## 10 信任链与客户端校验

### 10.1 根、中间、终端

没有哪个机构亲自签发每一张证书。证书连成**链**：每一张由上面那一张的私钥签发，一直到一个自己签自己的根。这条链叫**信任链**（chain of trust）。

![[L8 信任链的逐级验签.png]]

*三级证书链：每张证书的 Issuer 指向上一张的 Subject，签名用上一张证书里的公钥验。*

从下往上读：

- **终端实体证书**（end-entity certificate）：bank.com 实际出示的那张，CA 标志为 FALSE，"so it can sign data but not further certificates"。它的 Issuer 是 "Intermediate CA"，客户端据此找到 Subject 为 "Intermediate CA" 的证书，用**那张证书里的公钥** $K_{\text{inter}}$ 验终端证书的签名（图中 ①）。
- **中间 CA 证书**（intermediate CA）："Does the day-to-day issuing. If it is compromised, only it needs replacing — the root survives. This is why roots stay offline." 用根的公钥 $K_{\text{root}}$ 验它的签名（图中 ②）。
- **根 CA 证书**（root CA）：Subject 与 Issuer 相同，用自己的私钥签自己，叫**自签名**（self-signed）。"Its public key ships with your browser or operating system. Nothing vouches for it — it is trusted by decision, not by proof." 存放这些根证书的地方叫**信任库**（trust store）。

验证到根就停，"because the root is already in its trust store. Each link is one signature check." 谁都能给自己签一张自称是根的证书，所以自签名本身不提供信任，信任完全来自"它被预装进信任库"这一决定。也因此服务器发链时一般不发根。

课件同页："The chain is only as strong as its weakest link."——第 [[#12 PKI 怎么失败|12]] 节展开。

### 10.2 客户端的八项检查

课件第 3 页说，证书是这门课里第一个真正的协议对象：有定义好的字段、覆盖它们的签名、一组接收方必须执行的检查——读懂它、知道哪些检查要紧，就是 ILO 2 的"解读协议"。第 24 页列出了这组检查："Failing any one of them should abort the connection."

| 检查 | 检查什么 | 失败意味着 |
| --- | --- | --- |
| 签名链（signature chain） | 每张证书都能用上一张证书的公钥验过，一直到可信根 | 证书被伪造或篡改 |
| 可信根（trusted root） | 链终止于一个已在信任库里的根 | 没有你信任的人为它担保 |
| 有效期（validity dates） | 今天在 not-before 和 not-after 之间，**链上每一张**都要 | 已过期或尚未生效——常常是时钟出了问题 |
| 名称匹配（name match） | 你输入的域名出现在 SAN 清单里 | 一张有效的证书，却是别的网站的 |
| 基本约束（Basic Constraints） | 终端之上的每张证书 CA = true；终端 CA = false | 一张普通证书正在被用来签发别的证书 |
| 密钥用途（key usage） | 这把钥匙正被用于证书允许的用途 | 签名用的钥匙被拿去做密钥交换之类 |
| 吊销状态（revocation status） | 证书没有被签发者撤回（**吊销** revocation，机制见[[#11 证书的寿命：吊销与过期\|第 11 节]]） | 私钥已泄露，证书已被撤下 |
| **持有私钥**（possession of the private key） | 服务器在 TLS 握手中证明自己持有证书公钥配对的私钥 | 攻击者复制了证书，但没有私钥 |

第 8 项在课件上被黑条盖住了，而黑条说的正是它："The last check is the one people forget: a certificate is public, so anyone can copy it. Only proof of the private key turns it into evidence of identity." 前七项只检查证书这份**公开文件**，原样复制来的 bank.com 证书七项全过；只有第 8 项要求对方当场用私钥做一件事。在 TLS 1.3 里这一步叫 **CertificateVerify**：服务器用私钥对整个握手记录签名，客户端用证书里的公钥验证，[[L9 实用安全协议]] 会讲它在握手里的位置。

> [!warning] 八项清单的两处不严谨
> 误一：终端证书必须写明 CA = false。
> 正：RFC 5280 和 **CA/B 论坛**（CA/Browser Forum，各大 CA 与浏览器厂商共同制定公共 TLS 证书规则的组织）的规则 Baseline Requirements 都不要求终端证书带基本约束扩展；后者只规定，带了的话 cA 必须为 FALSE。所以"终端 CA = false"的准确含义是"终端不能是 CA"，不是"必须写出 CA:FALSE"。路径校验真正检查的是**签过别人的**证书：CA = true、带密钥用途扩展时须含签发证书、满足路径长度约束。
> 误二：八项就是全部。
> 正：实际客户端还查扩展密钥用途（网站要 serverAuth）、路径长度约束、**名称约束**（Name Constraints：把一个 CA 限定在某些域名之下的扩展，见 12.2），以及证书透明度的收据（12.3）。这些检查并不保证互相兜底：本笔记复现活动 4 的 C 时三项同时报错，是因为玩具中间 CA 设了路径长度 0、mail 证书的密钥用途里没有签发证书；换一种配置，可能只剩基本约束这一道关。所以课件说漏掉它就可能全面失守。

### 10.3 手工校验一条链：答题步骤

把八项检查排成能照着做的顺序。拿到"终端证书 + 服务器发来的中间证书 + 客户端信任库 + 今天的日期 + 用户输入的域名"，依次做：

1. **建链**：从终端证书开始，按它的 Issuer 找 Subject 相同的证书，再往上找，直到信任库里的根。找不到下一张（如服务器漏发中间证书、本地也没有）→ 拒绝，"可信根"失败。
2. **逐级验签**：每张证书的签名用**上一张证书里的公钥**验。验不过 → 拒绝，"签名链"失败。
3. **逐张查有效期**：根、中间、终端都要在有效期内。
4. **查每一张签过别人的证书**：CA 标志为 true；带密钥用途扩展时须含签发证书；它下面的中间 CA 层数不超过它的路径长度约束。普通证书签了别的证书 → 拒绝，"基本约束"失败。
5. **查终端证书的名称与用途**：SAN 含用户输入的域名（按[[#9.2 扩展才是干活的部分|通配符规则]]）；密钥用途、扩展密钥用途允许当前用途。
6. **查吊销**：链上每张都没被撤回。
7. **要求持有证明**：握手中服务器用终端证书的私钥签名，客户端用证书公钥验。

前六步只用到公开数据，第 7 步才把"这份文件"和"正在跟我说话的这台服务器"连起来。答判断题写四样：**接受还是拒绝；哪一项检查失败；依据（题面里的具体数据）；后果**。

### 10.4 课堂活动 4：找出问题

题目（第 26 页）：四张证书出示给浏览器，按校验清单判断接受还是拒绝，并说出哪一项检查失败。

- **A**：SAN 为 bank.com；有效期 2026-01-01 至 2027-01-01；链能验到可信根；你输入的是 www.bank.com。
- **B**：SAN 为 shop.example；有效期 2025-03-01 至 2026-03-01；链能验通；今天是 2026 年 8 月 7 日；你输入的是 shop.example。
- **C**：SAN 为 mail.example；日期有效；签它的那张证书的基本约束写着 CA = FALSE；你输入的是 mail.example。
- **D**：SAN 为 bank.com；日期有效；链能验到可信根；但握手中服务器完成不了持有私钥的证明。

| | 判定 | 失败的检查 | 理由 |
| --- | --- | --- | --- |
| A | **拒绝** | 名称匹配 | SAN 只有 bank.com，你要的是 www.bank.com，两个不同的名字互不蕴含。真实证书会两个都列，或用通配符（但 `*.bank.com` 不覆盖 bank.com 本身，两个都列最稳） |
| B | **拒绝** | 有效期 | 2026 年 3 月 1 日就过期了（到 8 月 7 日已过 159 天）。其余都对，单凭过期就足以拒绝 |
| C | **拒绝** | 基本约束 | 签发者无权签发证书。CA = FALSE 的证书可以签数据，永远不能签别的证书 |
| D | **拒绝** | 持有私钥 | 证书本身真实有效，但服务器没有配对的私钥，几乎肯定是复制来的 |

**配对讨论：假如 C 里浏览器不检查基本约束，持证人能做什么？** 课件："If the Basic Constraints check is skipped, one ordinary certificate becomes a certificate authority." mail.example 的持有者可以用自己的私钥给 bank.com 或任何域名签证书；链"伪造的 bank.com 证书 → mail.example 证书 → 中间 CA → 根"每一环在签名层面都成立，带漏洞的浏览器就会接受。范围是**所有带漏洞的客户端 × 所有域名**，他还能把这种能力卖给别人，直到 mail.example 的证书过期或被吊销——而吊销本身又靠不住（[[#11.3 软失败：吊销是全系统最弱的一环|11.3]]）。

课件最后："In practice most certificate errors are cases B — expiry — and they are operational failures, not attacks." "Which is why users learn to click through warnings — and why that habit is so dangerous." 被过期警告训练成随手点"继续"的用户，遇到 A、C、D 那样的攻击也会照点不误。

## 11 证书的寿命：吊销与过期

### 11.1 为什么需要吊销

课件第 25 页："Keys are stolen, employees leave, and certificates are issued in error. A certificate is valid until its expiry date unless something actively withdraws it." 证书上的签名永远有效；要在到期前让它失效，签发者必须**另外发布**一份"这张作废了"的声明，客户端还得去查。吊销声明靠[[#8.2 课堂活动 3：自己设计证书|序列号]]指出是哪一张。

### 11.2 CRL、OCSP 与 OCSP 装订

| | CRL | OCSP | OCSP 装订 |
| --- | --- | --- | --- |
| 全称 | certificate revocation list，证书吊销列表 | Online Certificate Status Protocol，在线证书状态协议 | OCSP stapling，"服务器自己去取状态" |
| 怎么做 | CA 发布一份签名的已吊销序列号清单，客户端定期下载 | 客户端每次实时问 CA："这一张现在还有效吗？" | 服务器定期从 CA 取一份签名的近期状态，握手时直接附给客户端 |
| 好处 | 简单；下载后可离线验证 | 答案新鲜，应答很小 | 不用额外查询，不泄露隐私 |
| 坏处 | 清单越来越大；两次刷新之间信息过时 | 每次连接都要在线查；**向 CA 泄露你访问了哪些网站**；查不到时大多数客户端照样继续——攻击者可以故意制造这种情况 | 服务器要保证附上的应答一直新鲜 |

"装订"的画面是：服务器把 CA 盖过章的状态证明订在证书上一起交出，客户端不必自己去问 CA。

> [!warning] 课件对吊销机制的两处说法与现状不符
> 误一："The list grows without bound."（CRL 无限增长）
> 正：RFC 5280 允许证书过期后把它移出 CRL，另有只发布增量的差量 CRL、按范围拆分的分区 CRL。CRL 的真正问题是体积大、刷新有延迟。
> 误二：OCSP 装订是 "Now the normal approach"。
> 正（2026 年现状）：CA/B 论坛 2023 年决议，自 2024 年 3 月起 CRL 必选、OCSP 可选；最大的公共 CA Let's Encrypt 已于 2025 年关停 OCSP，理由正是隐私泄露。浏览器改由厂商汇总各 CA 的吊销信息推送给浏览器：Chrome 用 CRLSets；Firefox 137 版（2025 年）起在桌面端启用 CRLite，142 版起对域名验证证书不再做 OCSP。主流做法成了"CRL + 浏览器端汇总 + 短有效期"。
> 课件对三种机制优缺点的分析仍然正确，并且恰好解释了 OCSP 为什么被放弃；考场上按课件分析作答，再补一句现状即可。

### 11.3 软失败：吊销是全系统最弱的一环

课件："Most clients treat a failed revocation check as a pass rather than a failure — because failing closed would break the web every time a responder had an outage."

- **软失败**（soft-fail，也叫失败开放 fail open）：查不到吊销状态时按"没吊销"放行；
- **硬失败**（hard-fail，失败关闭 fail closed）：查不到就拒绝连接。

软失败违反的正是 [[L1 信息安全基础#7.3 十三条设计原则|L1 的故障安全默认]]（出错时默认拒绝，宁可停机也不暴露）；客户端这样选，是因为 OCSP 服务器宕机一次，硬失败就会让所有用它的网站同时打不开。代价：**攻击者只要挡住吊销查询**（他已在中间人位置，挡一个请求轻而易举），效果就和"已吊销的证书被接受"一样。Chrome 安全工程师 Adam Langley 2012 年的比喻：软失败的吊销检查像一条撞车时会断的安全带。

于是 "shorten certificate lifetimes drastically, so that expiry does the work revocation cannot"：证书只活几周或几个月，被盗私钥能被利用的窗口也就这么长。

### 11.4 过期：最常见的证书事故

课件第 31 页："Most real certificate incidents are not attacks. They are a certificate nobody renewed." 原因有四条：证书装一次就被遗忘，装的人往往已离职；安装时到期日在一年以后，没人设提醒；大机构有成千上万张，散在服务器、负载均衡器（把流量分摊到多台服务器的设备）、内部服务和各种设备上；机器对机器的证书没有用户看到警告。

丢的是哪个安全目标？"AVAILABILITY — not confidentiality or integrity." 密码学一切正常，只是服务用不了：客户端拒绝连接，或者用户看到一个本不该被训练去忽略的警告。这是 [[L1 信息安全基础#4.1 CIA 三要素|CIA]] 里的可用性。课件把它说成 L1 的一个观点："a control can itself cause an incident."——L1 笔记里对应的是 [[L1 信息安全基础#7.3 十三条设计原则|故障安全默认]]那条：安全控制出错时宁可造成看得见的停机，也不要看不见的暴露。过期正是一种按设计"拒绝"造成的停机。

### 11.5 短有效期加自动化

课件："Short lifetimes limit the damage from a compromised key and reduce reliance on revocation, which we saw barely works. Long lifetimes reduce the operational burden and the chance of an outage."

| | 短有效期 | 长有效期 |
| --- | --- | --- |
| 好处 | 被盗私钥的可用窗口短；不再依赖吊销 | 运维省事，过期事故少 |
| 代价 | 换证频繁，人工操作必然出错 | 私钥泄露后长期可用；只能指望靠不住的吊销 |

行业选择了**短有效期**，并用**完全自动化**的签发和续期（ACME：服务器上的程序自动证明域名控制权、领新证书、换上，全程无人）让它变得可以承受。

课件认为这是全课最有用的思想之一："The answer to 'this control causes outages' was not to weaken the control. It was to automate the process around it until the control could be applied far more aggressively than before."

> [!warning] "从几年降到几周"还只是方向（2026 年的现状）
> 课件："Certificate validity has fallen from years to weeks."
> 误：公共证书的有效期现在已经是几周。
> 正：截至 2026 年 11 月，公共 TLS 证书最长 **200 天**（2026 年 3 月 15 日起，此前 398 天）；按 CA/B 论坛 2025 年的 SC-081 决议，2027 年 3 月 15 日起 **100 天**，2029 年 3 月 15 日起 **47 天**。Let's Encrypt 默认 90 天，另有可选的约 6 天短期证书。"几周"对一部分证书已是现实，对整个行业还是正在走的方向。

## 12 PKI 怎么失败

### 12.1 误发：证书在密码学上完美，绑定却是假的

第 4 部分标题页："The mathematics has never been the problem here either." 核心风险是**误发**（mis-issuance：CA 把证书发给了并不拥有那个名字的人）："A certificate is only as trustworthy as the CA's validation process."

| 类型 | 怎么发生 | 例子与点评 |
| --- | --- | --- |
| CA 被攻破 | 攻击者入侵 CA 的系统，直接给任何域名签证书；每个浏览器都接受，因为链是真的 | 课件说的荷兰 CA 即 **DigiNotar**：2011 年被入侵，签出 500 多张伪造证书，`*.google.com` 被用来对伊朗用户的 Gmail 做中间人攻击；被各浏览器移出信任库后当年破产 |
| 验证失败 | CA 诚实，但域名控制检查太弱或实现有误，申请者拿到不属于自己的名字的证书 | "Automated validation has repeatedly been found accepting proofs that a determined applicant could fake." |
| 内部人员或胁迫 | CA 内部有人故意签发，或被有权管辖它的机构强迫签发 | 不是技术漏洞，再多的密码学也没用 |
| 子 CA 委托 | CA 给客户签发一张中间 CA 证书，客户就能为**任何**域名签证书 | 合法用途是企业流量检查，泄露或管理不善就是灾难；如 Trustwave（2012）、TÜRKTRUST（2013） |

**流量检查**（traffic inspection）：企业为查毒、防泄密，在网关上把员工的 HTTPS 流量解密、检查、再加密转发——技术上就是一次中间人攻击，只是出于管理目的。

"In every case the certificate is cryptographically perfect. Verification succeeds. The binding between name and key is simply false." 误发的证书能通过[[#10.2 客户端的八项检查|八项检查]]的每一项：清单只能证明"某个受信任的 CA 签过它"，证明不了"CA 签对了"。

### 12.2 最弱一环

课件第 30 页："Your browser trusts a few hundred root certificates. ANY of them can issue a valid certificate for ANY domain."

1. **没有按域名划分**：一个国家的 CA 可以为另一个国家的银行签证书，"that is a policy matter, not a technical one."
2. **它们不是你选的**：信任库随浏览器或操作系统预装，几乎没人看过；删掉一项往往让不相干的网站打不开。
3. **最弱的那个决定安全水平**：攻击者不必攻破给真证书签名的那家 CA，只要攻破信任库里管理最差的那家，或任何一家下面最差的中间 CA。
4. **企业流量检查是同一个机制**：机构在管理的电脑上装自己的根以解密流量，"indistinguishable from an attack — because structurally it is the same thing."

课件："This is Lecture 1's attack surface argument applied to trust: the surface is not one authority, it is every authority." 即 [[L1 信息安全基础#6.2 攻击面|L1 的攻击面]]（对手够得着、用得上的漏洞的集合）：对整个 PKI，攻击面是信任库里**每一个** CA。

> [!warning] X.509 其实有限定 CA 范围的机制
> 课件："Nothing in the design restricts which names a CA may certify."
> 误：X.509 在技术上无法限制一个 CA 能为哪些名字签证书。
> 正：X.509 有名称约束扩展（RFC 5280 第 4.2.1.10 节），能把一个 CA 限定在某些域名之下，如只许签 `*.corp.example`。公共根基本不用它，课件"这是政策问题"的结论大体成立，但"设计里没有"不准确。企业内部 CA 正好可以用它（[[#12.4 课后任务 3：评估一个内部 CA|12.4]]）。

### 12.3 现在靠什么保护

"PKI has not been redesigned. It has been surrounded with mechanisms that make mis-issuance detectable and short-lived."

| 机制 | 是什么 | 起什么作用 |
| --- | --- | --- |
| **证书透明度**（CT） | CA 签发的每张证书都必须公布到公开的、只能追加的日志里；浏览器拒绝没登记过的证书 | 不阻止误发，而是让误发**藏不住**：域名所有者监控日志，几小时内就能看到任何人为他的名字签的证书 |
| 短有效期 | 有效期从几年降到几周，签发与续期自动化 | 压缩被盗私钥的可用窗口，不再依赖吊销 |
| **CAA 记录**（Certification Authority Authorization，CA 授权记录） | 域名所有者在 DNS 里公布哪些 CA 可以为这个名字签证书 | 把最弱一环从"几百家里任何一家"变成"我点名的几家"；CA 自 2017 年起必须遵守 |
| 自动签发 | 无需人工就能证明域名控制并领到证书的协议（ACME） | 让短有效期可行，去掉过期事故起源的人工环节 |
| 信任库治理 | 浏览器和操作系统厂商审计 CA，要求公开报告事故，把不合格的移出 | 2011 年那次入侵立了先例："a CA that loses trust is removed, and does not come back."（后来还有 2017–2018 年移除赛门铁克、2024 年 Chrome 停止信任 Entrust） |

CT 的**只能追加的日志**（append-only log）只能往后加记录、不能改删；它用 **Merkle 树**（把大量记录逐层两两哈希、汇成一个根哈希的树，任何一条被改，根哈希都会变）保证这一点，和区块链用的是同一种结构，见 [[L14 区块链工作原理（下）]]。CA 把证书提交给日志后拿到一张收据，叫 **SCT**（signed certificate timestamp，签名证书时间戳），嵌在证书里供浏览器检查。

**战略的转变**："from PREVENTING mis-issuance to DETECTING it quickly and limiting how long it is useful. That is the three Ds from Lecture 1, applied to an entire ecosystem." 即 [[L1 信息安全基础#7.1 三个 D|L1 的三个 D]]：防御（CA 的验证流程）做不到万无一失，重心移到检测（CT）和限制损失（短有效期）；失信的 CA 会被公开看到并移除，这本身也是威慑。

> [!warning] 证书透明度不覆盖所有证书
> 课件："Every certificate a CA issues must be published to public, append-only logs."
> 误：所有证书都必须登记 CT 日志，这是证书格式本身的要求。
> 正：这是浏览器对**公共信任的 TLS 服务器证书**的政策：Chrome 要求 2018 年 4 月 30 日以后签发的证书带 SCT，从 Chrome 68（2018 年 7 月）起执行；Apple 自 2018 年 10 月起；Firefox 135 版（2025 年）起在桌面端执行。链到用户自装的企业根的证书豁免，私有 CA、代码签名、邮件证书都不在其列。"几小时内看到"也要域名所有者真的在监控。

### 12.4 课后任务 3：评估一个内部 CA

题目：一家公司运行内部 CA。根私钥存放在共享网络盘上；证书有效期十年；没有吊销机制；根证书装在每一台员工笔记本上。按严重程度列出所有问题，说明每一个威胁哪个安全目标。

这是 capstone 题型。做法：逐条找出违背本讲原则的地方；按"被利用后损失多大、多容易被利用"排序；每条写清威胁的安全目标和修补。

> [!example]- 课后任务 3 解答（按严重程度排序）
> **1. 根私钥在共享网络盘上——最严重。** 能访问网盘的人（包括被盗用的员工账号、内网恶意软件）都能复制根私钥，为**任何域名**签证书；因为第 4 点，这些证书在每台员工电脑上都被信任，攻击者可以对全公司的 HTTPS 流量做中间人攻击（包括访问外部的网银、邮箱）。威胁**机密性、完整性**（读取、篡改加密流量）和**真实性**（冒充任何站点）。网盘上的复制不留痕迹，泄露了也不知道。修补：根私钥离线放进 HSM，并限制、审计能调用 HSM 的人；日常签发交给中间 CA（[[#10.1 根、中间、终端|10.1]]）。
> **2. 没有吊销机制。** 私钥泄露或误发后无法撤回，只能等过期；和第 3 点叠加就是十年。威胁**完整性、真实性**，且无法止损。修补：发布 CRL，要求内部客户端检查（内部环境吊销服务器在自己手里，可以用硬失败）。
> **3. 有效期十年。** 被盗的终端私钥十年可用；算法和密钥长度无法及时更新。威胁**机密性、完整性**；另一面是**可用性**：十年后大批证书集中过期，装证书的人早已离职（[[#11.4 过期：最常见的证书事故|11.4]]）。修补：缩短到几十天，用 ACME 之类的协议自动续期。
> **4. 根证书装在所有笔记本上。** 这是内部 PKI 的正常做法，但它把第 1 点的影响扩大到全员；而且不受限的根能为**外部**域名签证书，等于每台电脑上有一个能冒充全世界的根（[[#12.2 最弱一环|12.2]] 第 4 条）。修补：用名称约束把根限定在内部域名。
> 还可补充：没有中间 CA 分层（根直接签发，就得一直在线）；没有签发日志与审计，误发了也发现不了——缺了三个 D 里的检测。

### 12.5 课后任务 1：看一张真证书

题目：打开任意 HTTPS 网站，查看证书，记下签发者、有效期、主体备用名、签名算法、链里有几张证书，以及让你意外的地方。2026 年通常会看到：

- **签发者**是中间 CA 而不是根，如 Let's Encrypt 的 YR1、YE1 这类（2026 年起陆续取代原来的 R、E 系列）；
- **有效期**短：Let's Encrypt 90 天，其他公共证书最长 200 天；
- **主体名称**几乎没信息，域名全在 SAN 里，常同时列裸域名和 www；
- **签名算法**是 `ecdsa-with-SHA256` 或 `sha256WithRSAEncryption`；
- **链**一般显示三张，服务器只发终端和中间两张，根是浏览器从本地信任库补上的；
- 扩展里有"嵌入式 SCT"，即证书透明度的收据；
- 在公司网络里，签发者可能是公司自己的根——这就是流量检查。

课件参考页还建议：顺着证书链一直点到根；数一数自己设备的信任库里有多少个没听说过的 CA；在证书透明度日志的查询网站上搜一个熟悉的域名，"Every certificate is there."

## 13 网页之外的 PKI

课件第 33 页："The same structure appears wherever a key must be bound to an identity."

| 用途 | 做什么 | 风险或特点 |
| --- | --- | --- |
| **代码签名**（code signing） | 软件和驱动带签名，操作系统安装前据此确认发布者 | 偷到签名私钥，恶意软件就能顶着发布者的信誉安装（如 2010 年震网病毒 Stuxnet 盗用了两家台湾硬件公司的私钥），所以这类私钥放在硬件里 |
| 文档签名 | PDF、合同、法律文书带签名，在很多司法辖区有法律效力 | 不可否认性在这里不再抽象：签名就是要拿到法庭上用的 |
| 电子邮件（S/MIME、PGP） | 邮件签名以证明来源，加密以保密 | PGP 用信任网代替中心机构——信任模型不同，底下的问题相同 |
| 设备与机器身份 | 给服务器、物联网设备、容器发证书，让服务之间互相认证 | 数量远多于网站证书，通常由内部 CA 签发，往往管理得最差 |
| 国家身份证件 | 政府智能卡里装着私钥和证书，用于公民身份认证 | 把公钥绑到**法律身份**而不是域名上——最强的一种绑定 |

**S/MIME**（Secure/Multipurpose Internet Mail Extensions，安全多用途互联网邮件扩展）是基于 X.509 证书的邮件签名与加密标准；**PGP**（Pretty Good Privacy）是 1991 年起流行的邮件加密软件及格式。**物联网**（Internet of Things，IoT）指联网的传感器、摄像头、家电等设备；**容器**（container）是把程序连同运行环境打包隔离运行的单元。

**信任网**（web of trust）：PGP 里没有 CA，用户直接互相给对方的公钥签名担保。课件："It is more robust to any single compromise, and it has never scaled."——没有攻破一处就通吃的中心，但普通人不会去互签公钥，它始终停留在小圈子里。

## 14 七条结论与下一讲

### 14.1 七条结论

课件第 35 页 "Seven things to leave with"：

1. 签名用签名者的私钥生成、公钥检验；证明自己用自己的钥匙，隐藏用对方的（[[#3.1 一条规则：证明用自己的私钥，隐藏用对方的公钥|3.1]]）。
2. 只有签名给不可否认性，因为只有签名能说服第三方（[[#2.2 签名与 MAC：差在对称与不对称|2.2]]）。
3. 签摘要不签消息：为速度、为大小、为消除代数结构（[[#5.2 三条理由|5.2]]）。
4. 身份不是数学性质；证书是绑定公钥与名字的签名陈述（[[#8.1 证书是一条签了名的陈述|8.1]]）。
5. PKI 没消除信任，只是把它集中到几百个你没选过的根上（[[#12.2 最弱一环|12.2]]）。
6. 校验是一张清单，漏任何一项都可能全面失守，基本约束是经典例子（[[#10.2 客户端的八项检查|10.2]]）。
7. 多数证书事故是过期不是攻击；对策是自动化续期好让有效期更短，而不是放松控制（[[#11.5 短有效期加自动化|11.5]]）。

### 14.2 课后任务 4：证书之后，怎样得到会话密钥

题目："A certificate proves a server holds a particular private key. It does NOT by itself encrypt anything. So how does a browser get from 'this is really bank.com' to 'we now share a secret key for this session'? Sketch the steps you think are needed. Do not look it up." 课件说这题没有错误答案，先自己想。它是 [[L9 实用安全协议]] 的开场：把本讲的证书和 L7 的 Diffie–Hellman 拼起来。

> [!example]- 一种答案：TLS 1.3 的要点（下一讲完整讲）
> 1. 双方各生成一对**临时的** Diffie–Hellman 密钥（通常在椭圆曲线上，叫 ECDHE：elliptic curve Diffie–Hellman ephemeral），在最初两条握手消息里交换公开值，算出共享秘密。"临时"指用完即弃，日后服务器长期私钥泄露，过去的会话也解不开，这叫**前向保密**（forward secrecy）。
> 2. 服务器发来证书链，客户端按 [[#10.3 手工校验一条链：答题步骤|10.3]] 校验。
> 3. 服务器用证书对应的私钥，对**到目前为止的整个握手记录**（含交换的公开值）签名，即 CertificateVerify。它把证书里的身份和这一次密钥交换绑在一起，正是"认证这次交换"的完整答案：中间人换掉公开值，签名就对不上；不换，他就算不出共享秘密。
> 4. 双方从共享秘密和握手记录派生会话密钥，互发一条对握手记录的校验值（Finished 消息）确认看到的握手一致，之后用 AES-GCM 这类认证加密保护数据。
>
> 课件第 36 页还预告了证书实验："Generate a key pair, create a certificate signing request, sign it with your own CA, and then break it — wrong name, expired dates, missing CA flag — and watch each check fail."

## 本讲速记

- 缺口三环：Diffie–Hellman 不认证交换值 → 补法是给交换值签名 → 验签要可信公钥，而**公钥只是一个数**。解法：验一条可信机构签过名的关于公钥的陈述——证书。
- 签名四性质：真实性、完整性、**不可否认性**、**公开可验证性**（"谁"只到"哪把私钥"）。MAC 只有前两条且只对持钥人；不可否认 = 只有一方能产生 + 第三方能检验。
- 选钥匙：证明用自己的私钥，隐藏用对方的公钥。活动 1：a、c、f 签名；b 用 MAC；d 用 Bob 公钥加密；e **先签后加密**。签名 ≠ 用私钥加密（只对 RSA 成立）；签名不保密；不用收件人的钥匙签。
- RSA 签名 $S=H^d \bmod n$，验证 $S^e \bmod n \overset{?}{=} H$，因 $ed\equiv1 \pmod{\phi(n)}$。平方-乘：$7^{27} \bmod 55=28$，$28^3\equiv7$；$12^{27}\equiv23$，$23^3\equiv12$；篡改 $29^3\equiv24\neq7$。不可否认的前提：$n$ 不可分解、私钥没被偷。
- 签摘要三理由：速度、大小、消除代数伪造。存在性伪造：任取 $S'$，$H'=S'^e$，$(24,29)$ 即一例；可乘性 $\text{Sig}(a)\text{Sig}(b)\equiv\text{Sig}(ab)$。哈希 + 填充（PKCS#1 v1.5、PSS）使之无用。分类别混：攻破程度 vs 攻击者掌握什么。
- 哈希三性质：原像、第二原像、抗碰撞（最强、最先被破）；生日界 $2^{\ell/2}$。MD5、SHA-1 被碰撞，选择前缀碰撞可伪造 CA 证书。
- DSA 不能加密、每次需新随机数（已停用于新签名）；ECDSA 主流（256 位 ≈ RSA 3072）；Ed25519 确定性。随机数复用两签名即泄露私钥（$r$ 相同）。
- 五种失败：随机数复用、弱哈希、无填充、私钥被盗（HSM 防复制不防滥用）、验错东西。
- 验签只说明"出自某把私钥"；中间人换公钥后无运算报错。信任起点要小、看得见、管得住。分发：直接交换、公开目录、证书（教材另有公开发布、公钥权威机构）。
- 证书五步：生成密钥对 → 申请并证明域名控制（ACME、CSR）→ CA 签整条记录 → 出示 → 客户端用**已持有的** CA 公钥验。字段：主体、公钥、有效期、签发者、序列号、用途、覆盖全部的签名。
- X.509 九字段，签名前为 TBSCertificate；v3 编码为 2。扩展：SAN（通配符只配一级）、基本约束（CA 标志、路径长度）、密钥用途、EKU。
- 信任链：终端 ← 中间 ← 自签名的根（"trusted by decision, not by proof"）；每级用上一张的公钥验。八项检查最后一项是持有私钥。活动 4：A 名称、B 过期、C 基本约束、D 无私钥，全拒。
- 吊销：CRL、OCSP（泄露隐私、软失败）、装订；软失败让攻击者挡住查询即可 → 缩短有效期。现状：OCSP 被弃，浏览器汇总。过期丢的是可用性；对策是自动化。上限 200 天，2029 年 47 天。
- 误发四类（DigiNotar）；最弱一环：几百个根任何一个都能签任何域名；防护：CT、短有效期、CAA、ACME、信任库治理——从预防转向检测与限时，即三个 D。

---

下一讲 [[L9 实用安全协议]]：TLS 1.3 握手从头到尾——证书、密钥交换、认证与会话密钥怎样拼成一个协议；另有 Kerberos（靠可信第三方发放票据的网络认证协议）和无线网络认证。课件说："Everything from Lectures 2 to 7 comes together in Lecture 8."（课件编号，即本课 L2–L8 的内容在 L9 汇合。）再往后是 [[L10 网络安全：威胁、攻击与防御]]，以及课件预告、目前还没有课件的 capstone。

浏览器版（带RSA 签名与验签、SHA-256 雪崩、教科书 RSA 两种伪造、同一 k 复用恢复私钥、证书链校验判定）：[HTML/L8 数字签名、证书与 PKI.html](HTML/L8%20%E6%95%B0%E5%AD%97%E7%AD%BE%E5%90%8D%E3%80%81%E8%AF%81%E4%B9%A6%E4%B8%8E%20PKI.html)
