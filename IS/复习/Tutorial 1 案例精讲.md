---
chapter: Tut1
status: 已完成
---

# Tutorial 1 案例精讲

> [!info] 这批材料是什么、本篇怎么用
> Moodle "Tutorial 1 materials" 文件夹：**10 份案例**（`Case Study 1.pdf` … `CaseStudy 10.pdf`，30 页，每份是"场景 → 选项 → 要求 → 'For example' 示范答案"，本篇称 Case N）；**9 份旧版辅导幻灯片**（`Information Security 01` … `09`，280 页，署名 Sana Hafeez，本篇称 T01–T09）。
>
> **示范答案不是标准答案**，错误在各案例末尾的 warning 框里逐条指出。Case 9 写明了评分取向："There are no right or wrong answers, but be prepared to logically reason through your choices."
>
> 第 2–5 节按题型分四类，每类先讲框架、再逐份解答，并配一份英文考场版；第 6 节收旧幻灯片里今年没讲、可能考的条目。

> [!tip] 考点
> - 今年 L1 课件预告了 tutorial 的做法："Full company scenarios. You build the threat vector table, add likelihood and impact, and produce a ranked risk register with justifications."；L1 正文没讲威胁向量表怎么做，本篇 [[#2.1 统一答题框架：威胁向量表与风险登记册|2.1]] 补上。
> - **复习顺序**：今年课件里标成考试形态的同型题优先（L6 说它的选模式活动就是期末场景题的形态），这批往年案例用来练手、练论证；对应关系见 [[#1.2 题型导航|1.2]]。
> - 模拟卷（去年版）与这批材料相关的题，单题的规范答法只放在模拟卷全解：
>
> | 模拟卷 | 考什么 | 答法与本篇的位置 |
> | --- | --- | --- |
> | Q1(a) 7 分 | 威胁向量的定义、例子与识别 | [[模拟卷全解#1.1 Q1(a) 威胁向量（7 分）\|模拟卷全解 1.1]]；建表 [[#2.1 统一答题框架：威胁向量表与风险登记册\|2.1]]，举例素材 [[#6.2 威胁定义清单与入侵途径（T02 p25、T05 p3–p4）\|6.2]] |
> | Q1(b) 4 分 | 病毒与蠕虫的区别 | [[模拟卷全解#1.2 Q1(b) 病毒与蠕虫（4 分）\|模拟卷全解 1.2]]、[[L10 网络安全：威胁、攻击与防御#2.2 病毒与蠕虫的区别\|L10 2.2]]；经典定义 [[#6.3 恶意软件的经典定义（T05 p5–p16）\|6.3]]、[[#6.4 蠕虫与僵尸网络（T05 p17–p22）\|6.4]] |
> | Q1(c) 7 分 | 借助图解释主动攻击并举例 | [[模拟卷全解#1.3 Q1(c) 主动攻击（7 分）\|模拟卷全解 1.3]]；分类练习 [[#2.4 Case 9：主动攻击与被动攻击的风险排序\|2.4]]；可画的 DDoS（distributed denial of service，分布式拒绝服务）结构图 [[#6.5 直接型与反射型 DDoS（T05 p23–p24）\|6.5]] |
> | Q2(a) 4 分、Q2(c) 7 分 | AES 的 AddRoundKey；ShiftRows 手算 | [[模拟卷全解#2.1 Q2(a) AddRoundKey（4 分）\|模拟卷全解 2.1]]、[[模拟卷全解#2.3 Q2(c) ShiftRows（7 分）\|2.3]]；AES 每轮四步的作用 [[#5.2 逐项评价\|5.2]] |
>
> Q1(d)、Q2(d) 与本材料无关。参考答案的出处：Q1(a) 出自 Rhodes-Ousley《Information Security: The Complete Reference》；Q1(c) 的文字出自 Forouzan 的教材，配图是 Stallings《Cryptography and Network Security》Fig. 1.2(b)。都不出自这 9 份幻灯片。

## 1 这批材料怎么读

### 1.1 十份案例的共同骨架

每份案例都考同一种能力：**面对几个选项，按给定标准逐个评价，排出顺序或选出一个，并说出理由**（要求词是 assess、prioritize、justify、rank）。示范答案常见四种毛病：

1. **只评了一部分选项**：题目要求 "for each"，示范只写了几项（Case 1）。
2. **用"贵不贵"代替"险不险"排序**：成本是选控制时的考虑，不是给风险排序的依据（Case 2）。
3. **题目前提有错，示范照着作答**：AES（Advanced Encryption Standard，高级加密标准）一轮的四个变换不能"选一个"（Case 8）；选了 AES-CTR（计数器模式，counter mode，见 [[#4.4 Case 5：随机比特、流密码与 Feistel 解密|4.4]]）就不存在 "Feistel 解密"（Case 5）。**Feistel 结构**（Feistel structure）是每轮只改分组的一半、另一半原样换位的结构，DES（Data Encryption Standard，数据加密标准）用的就是它（[[L3 分组密码与 DES#5.2 一轮 Feistel|L3 5.2]]）。
4. **事实错误**：RSA（Rivest–Shamir–Adleman，以三位发明者命名的公钥算法）"基于分解大质数"（Case 3、6）；端口扫描是被动攻击（Case 9）；拿速度当理由排除伪随机函数（pseudorandom function，PRF，见 [[#4.1 统一答题框架：随机数的三个环节|4.1]]；Case 7）。

答卷的写法：**逐项作答 → 每一级一句有依据的理由 → 题目前提有错先指出，再在修正后的前提下作答**。

### 1.2 题型导航

| 题型 | 本篇 | 答题骨架 | 今年课件的同类练习 |
| --- | --- | --- | --- |
| 风险评估 | 第 2 节（Case 1、2、9） | 威胁写成"来源 → 路径 → 目标"；L、I 各配一句依据；按 R = L × I 排序；控制标明降 L 还是 I | [[L10 网络安全：威胁、攻击与防御#7.2 评一个设计：三个最严重的问题\|L10 7.2]]、[[L10 网络安全：威胁、攻击与防御#7.3 花预算：六选三\|7.3]]（通用做法 [[L10 网络安全：威胁、攻击与防御#7 场景题：沿攻击链放防御\|L10 §7]]）；降 L 还是 I：[[L10 网络安全：威胁、攻击与防御#6.1 likelihood 还是 impact：判断规则\|L10 6.1]] |
| CIA 归类 | [[#6.7 CIA 归类练习（T01）\|6.7]] | 问"丢了什么"，主属性加一句为什么 | [[L1 信息安全基础#4.3 判断一起事件丢了什么\|L1 4.3]] |
| 算法选型 | 第 3 节（Case 3、4、10） | 写需求 → 逐个排除（给可核对的数）→ 选定 → 写模式、密钥管理、完整性 | [[L6 对称密码的安全使用#8.2 课堂活动 2：为四个系统选模式\|L6 8.2]]（"One sentence each"） |
| 随机数与流密码 | 第 4 节（Case 7、6、5） | 先摆正真随机源、伪随机发生器、PRF 各在哪一环，再按题给因素逐项比 | [[L6 对称密码的安全使用#9.4 课堂活动 3：这些序列随机吗\|L6 9.4]] |
| 构件与设计评价 | 第 5 节（Case 8） | 先指出前提的错，再逐项说"贡献什么、代价多少"，最后排优先级 | [[L6 对称密码的安全使用#11.2 课后作业 3：评估一个设计\|L6 11.2]] |

第 4 节按 7 → 6 → 5 讲：Case 7 先讲清随机数分几个环节，Case 6 在其中一环比较两种生成器，Case 5 是综合题。

## 2 风险评估类：Case 1、2、9

### 2.1 统一答题框架：威胁向量表与风险登记册

**三个词**（[[L1 信息安全基础#3.1 六个常被混用的词|L1 3.1]]）：**威胁**（threat）是可能出错并造成损害的事，**漏洞**（vulnerability）是让威胁得以实现的弱点，**风险**（risk）把两者合成"多可能 × 多严重"：

$$
\text{风险} = P(\text{威胁利用了漏洞}) \times \text{资产受损的代价}
$$

两个因子记作**可能性**（likelihood，L）和**影响**（impact，I），即 $R = L \times I$。题面给的常是漏洞（"No multi-factor authentication"），答题时补成一句威胁："没有多因素认证，**攻击者**用钓到的口令**登录**，读走患者记录"——有了"谁、怎么、打到什么"才谈得上 L 和 I。

**威胁向量**（threat vector）是威胁从哪里来（**来源**，source）、沿哪条路（**路径**，path）到达哪个**目标**（target）。定义与识别的答法见 [[模拟卷全解#1.1 Q1(a) 威胁向量（7 分）|模拟卷全解 1.1]]；T02 p25 的威胁清单可作识别时的检查表，见 [[#6.2 威胁定义清单与入侵途径（T02 p25、T05 p3–p4）|6.2]]。

**威胁向量表加上打分，就是风险登记册**（risk register：逐行列出风险、评级和处置措施的表）。列：

| 列 | 写什么 |
| --- | --- |
| 威胁；来源 → 路径 → 目标 | 一句带动词的话；外部攻击者 / 内部人员 / 故障 → 走哪条路 → 打到哪个资产 |
| L、I；R = L × I | 各 1–5 分，各配一句依据；风险等级 High / Medium / Low |
| 优先级 | Critical / High / Medium / Low |
| 控制 | 用什么挡，降的是 L 还是 I |
| 受损属性 | 机密性、完整性、可用性（[[L1 信息安全基础#4.1 CIA 三要素\|CIA 三要素]]），或真实性、可追责性、不可否认性（[[L1 信息安全基础#4.2 三个扩展属性\|扩展属性]]）；写中文，免得与影响 I 混淆 |

**打分口径。** 课件只给了乘积，没给刻度；本篇统一用 5 级刻度（常用的 5×5 风险矩阵）：

| 分 | 可能性 L（一年内） | 影响 I |
| --- | --- | --- |
| 1 | 很少发生 | 可忽略 |
| 2 | 不太可能 | 小：个别记录、可轻易恢复 |
| 3 | 可能 | 中：局部业务受损或短时中断 |
| 4 | 很可能 | 大：大量数据泄露或关键服务长时间中断 |
| 5 | 几乎肯定（或题面说正在发生） | 严重：全量敏感数据、监管处罚、人身安全 |

**风险等级**：$R \ge 15$ 为 High，$8 \le R \le 14$ 为 Medium，$R \le 7$ 为 Low。**优先级**回答"先修哪个"，规则：

1. 起点按 R 定：$R \ge 20$ 为 Critical，15–19 为 High，8–14 为 Medium，$\le 7$ 为 Low；
2. 可上调或下调一级，但必须写出理由：它是别的威胁的**入口**（修了它，后面几条的可能性一起降）、或修复几乎不花钱，可上调；题面明确说已有控制压住了它，可下调；
3. R 相同时，影响大的在前；再相同，控制便宜、见效快的在前（[[L1 信息安全基础#3.2 给控制措施算一笔账：ALE|L1 3.2]] 的"按净收益选控制"）。

打几分是判断，每个分都要能用场景里的一句原文或一条常识撑住。场景没写的防御不假设存在；要假设，就明写"若……则调整为……"。

**读题：只有进行时能让 L 直接取 5。** 题面用进行时说攻击正在发生（"is flooding"、"are being sent"），L 取 5。"An attacker can …" 只说明攻击可能，不说明漏洞已存在，L 按暴露面定：面向互联网、能被自动化工具扫到的取高，要物理接入或内部身份的取低。

**控制降 L 还是降 I**，以攻击得手那一刻为界：之前起作用、让攻击打不成的降 L（补丁、多因素认证）；之后起作用、让损失变小的降 I（备份、加密存储、分段）。易判错的例子见 [[L10 网络安全：威胁、攻击与防御#6.1 likelihood 还是 impact：判断规则|L10 6.1]]。

英文考场版的格式见 [[#2.2 Case 1：医疗云数据库的五项威胁|2.2]] 末尾，Case 2、9 照写。

### 2.2 Case 1：医疗云数据库的五项威胁

**场景。** ACME 医疗系统把患者健康记录存在云数据库里，你作为安全分析员评估威胁、排整改优先级。题面五项（按顺序记作 A–E）：

- A "Lack of encryption allows plaintext data exfiltration if the cloud database is breached."
- B "No multi-factor authentication leaves accounts vulnerable to password attacks."
- C "Unpatched operating systems and software increase exploit risks."
- D "Employees sharing passwords leads to unauthorized access."
- E "Outdated antivirus allows new malware strains to evade detection."

**要求原文**："For each identified threat/vulnerability, assess the risk level (high, medium, low) and priority (critical, high, medium, low)." "Justify each ranking with a short explanation."

几个词：**PHI**（protected health information，美国法规对可识别到个人的医疗记录的称呼）；**HIPAA**（Health Insurance Portability and Accountability Act，美国《健康保险流通与责任法案》）；**多因素认证**（multi-factor authentication，MFA，登录要同时出示两类以上凭据）；**钓鱼**（phishing，用伪造的邮件或网页骗人交出凭据）；**撞库**（credential stuffing，拿别处泄露的口令批量去试）；**勒索软件**（ransomware，加密数据再索要赎金，[[L10 网络安全：威胁、攻击与防御#2.3 勒索软件：五个阶段，每段配一个防御|L10 2.3]]）。

**规范解答。** 资产是患者记录，以及能访问它的账户、服务器和电脑。排序 B（25，Critical）> C（20，Critical）> D（16，High）> A（15，High）> E（9，Medium），整张登记册直接写成下面的英文考场版。

![[Tut 风险矩阵与 Case 1 定位.png]]

*横轴可能性、纵轴影响，格内数字是 R＝L×I，颜色是风险等级。*

理由里不显然的两条：

- **B 排第一。** 没有 MFA，一个口令就是整把钥匙，钓鱼和撞库都冲它来：攻击者拿合法口令登录，数据库**按正常流程把明文交给他**，A 的加密不起作用。MFA（管理员用只对真网站应答的抗钓鱼硬件密钥，[[L10 网络安全：威胁、攻击与防御#4.3 社会工程：合法的人用合法的凭据|L10 4.3]]）也让 D 的共享口令被外人滥用变难，属于"入口"。
- **A 只排第四。** 静态加密（磁盘、快照、备份里存密文）和传输加密（走 **TLS**，Transport Layer Security，传输层安全协议，[[L9 实用安全协议#6.2 TLS 提供什么、不提供什么|L9 6.2]]）挡的是"拿到介质、快照、备份或链路"这一路，把后果从明文外流降成一堆密文——降 I 不降 L；题面自己写的是 "if the cloud database is breached"。经认证会话或应用漏洞进来的攻击者拿到的是自动解密后的明文，密钥另外托管的应用层字段加密才挡得住整表导出。监管后果严重（I=5），仍是 High。

C 对应 L1 开场"31% 的泄露始于利用已知漏洞"，医疗业又是勒索软件的主要目标；D 毁掉的可追责性见 [[L1 信息安全基础#4.2 三个扩展属性|L1 4.2]]。

> [!example] 考场版（英文，风险评估类通用格式；刻度、表、每行一句理由都写）
> Scale: L and I from 1 to 5, R = L × I; risk High if R ≥ 15, Medium 8–14, Low ≤ 7; priority starts from R (Critical if ≥ 20) and moves one level only with a stated reason.
>
> | Rank | Threat: source → path → target | L | I | R | Risk / Priority | Control (reduces) |
> | --- | --- | --- | --- | --- | --- | --- |
> | 1 | No MFA: attacker → phished or reused password → staff account → patient DB | 5 | 5 | 25 | High / Critical | MFA for all staff (L) |
> | 2 | Unpatched systems: attacker → known flaw in an exposed service → servers | 4 | 5 | 20 | High / Critical | Patching deadlines, scanning (L) |
> | 3 | Shared passwords: insider → shared account → records | 4 | 4 | 16 | High / High | Individual accounts, audit logs (L) |
> | 4 | No encryption: attacker → stolen media, backup or link → plaintext | 3 | 5 | 15 | High / High | Encryption at rest and in transit (I) |
> | 5 | Outdated antivirus: attacker → attachment → staff PCs | 3 | 3 | 9 | Medium / Medium | Behaviour-based endpoint protection (L) |
>
> - No MFA first: a stolen password gives a legitimate session, and the database decrypts data for it, so encryption does not help.
> - Unpatched systems: known flaws are found by automated scanning; exploitation hits confidentiality, integrity and availability.
> - Shared passwords: cheap to fix and they destroy accountability.
> - Encryption fourth: it only defeats stolen media, backups or links and reduces impact, not likelihood; High because a breach of unencrypted PHI must be notified.
> - Antivirus last: signatures miss new strains; it is only a detection layer.

> [!warning] 示范答案的问题
> - **只评了 5 项中的 3 项**，漏了 No MFA 和 Outdated antivirus。
> - **"encrypted data provides a last line of defence if other controls fail" 错**：见"A 只排第四"，这推翻了示范把加密排第一的主要理由。
> - **"exposed data directly violates HIPAA" 说过头了**：HIPAA 安全规则把加密列为 "addressable"（可用替代措施并书面说明），不是 "required"（2025 年 1 月的修订提案拟改为 required，截至 2026 年 11 月未定稿）。加密的价值在于：按美国卫生部指南加密过的数据泄露不算须通报的 "unsecured PHI" 泄露。
> - **"Shared passwords … Changing default passwords" 答非所问**：共用口令与出厂默认口令是两回事。
> - **"Unpatched systems are medium risk since other controls help" 没有依据**：场景里的其他控制（MFA、杀毒）恰恰缺失或过期。
>
> 示范的结论也能辩护，只要理由换对：把 A 的 L 记为 4（云存储桶与快照配置错误很常见），$R=4\times5=20$，与 C 并列 Critical。

### 2.3 Case 2：客户数据库的 CIA 定级

**场景。** 小公司的客户数据库存姓名、地址、电话、信用卡信息、购买记录；只有数据库管理员和客服能访问；"No encryption is used on the data"；"The database is backed up to tape weekly and stored offsite." 每个属性给三档：

| 属性 | Low | Medium | High |
| --- | --- | --- | --- |
| 机密性 | 不加密 | 只加密信用卡数据 | 加密全部敏感客户数据 |
| 完整性 | 不做完整性检查 | 每天检查关键字段 | 实时完整性监控与告警 |
| 可用性 | 只有每周异地磁带备份 | 每天本地备份＋每周异地备份 | 实时复制到另一个站点 |

**要求原文**："You must choose a level for each component and justify your choices based on the company's specific situation, resources, and security priorities." "After assigning levels, you must prioritize the components to guide security investment."

现状三项全 Low，升级要花钱，每一档都要用风险说明。**规范解答**，先列威胁打分：

| 威胁（来源 → 路径 → 目标） | L | I | R | 受损属性 |
| --- | --- | --- | --- | --- |
| A 外部攻击者 → 网页应用漏洞或被盗管理员凭据 → 批量导出明文卡号 | 3 | 5 | 15 | 机密性 |
| B 客服 → 用合法账户查超出业务需要的字段 → 带走客户数据 | 3 | 4 | 12 | 机密性、可追责性 |
| C 磁盘故障或勒索软件 → 数据库不可用，最多丢一周订单 | 3 | 4 | 12 | 可用性 |
| D 物流或存放环节 → 未加密的异地磁带丢失或被复制 | 2 | 5 | 10 | 机密性 |
| E 外部攻击者或内部人员 → 越权改写收货地址、订单 | 2 | 3 | 6 | 完整性 |

- **机密性 High**（含备份磁带）：A、B、D 都是机密性威胁，A 风险最高。按 **PCI DSS**（Payment Card Industry Data Security Standard，处理银行卡数据的机构都要遵守的行业标准），存储的卡号必须不可读（加密、单向哈希、截断或令牌化都算），授权后 CVV（卡背面的验证码）根本不许保存。所以对卡号，"不存"或令牌化（[[#6.9 在线口令暴力破解与 Equifax（T03、T04）|6.9]]）比加密更好，加密是最低要求；其余个人数据也该加密，一次到位选 High。
- **完整性 Medium**：唯一的完整性威胁 E 风险最低（6），实时监控对 "small company" 不相称；每天检查花费小，还能保证备份下来的不是已被改坏的数据。
- **可用性 Medium**：C（12）高于 E；每天备份把最坏损失从 7 天降到 1 天，异地副本防勒索和机房灾难；实时复制投入过大。

**投资优先级：机密性（15）→ 可用性（12）→ 完整性（6）**，依据是各属性下最高的 R。示范排成机密性 → 完整性 → 可用性，理由是 "real-time monitoring is too expensive"——成本说明不了谁的风险更大；成本只用来在同一档里挑控制。

> [!warning] 示范答案的问题
> - **漏了最大的硬伤：异地磁带不加密**（威胁 D）。选机密性 High 时要明确包括备份加密。
> - **"Daily onsite backups provide good availability" 混淆了可用性与可恢复性**：备份决定能恢复到哪个时间点，不让系统在故障期间继续服务；提高可用性的是冗余与复制。反过来复制也不能代替备份：误删和勒索加密会被实时复制过去。示范还只讲了本地备份，Medium 档的另一半价值在 "weekly offsite"。记一句："Backups give recoverability; replication gives availability."
> - **理由与选项范围对不上**：只写 "credit card and purchase data"，High 档却是 "Encrypt **all** sensitive customer data"。
> - **没问客服需不需要看完整卡号**（威胁 B，[[L1 信息安全基础#7.3 十三条设计原则|最小权限]]）：加密挡不住有合法权限的人，要靠"只显示后四位"这类访问控制。

### 2.4 Case 9：主动攻击与被动攻击的风险排序

**场景。** 大公司的安全管理员评估五种攻击：

- **Passive Wiretapping**："An attacker can tap into the company's network cables and monitor traffic."
- **Port Scanning**："An attacker scans open ports on the company's servers to determine what services are running and look for vulnerabilities."
- **SQL Injection**："An attacker can inject malicious SQL code into input fields on the company's web application to gain access to the backend database."
- **Denial of Service**："An attacker is flooding the company's web servers with garbage traffic to overwhelm them and take them offline."
- **Phishing**："Emails impersonating the company's CEO are being sent to employees in an attempt to trick them into revealing their passwords."

**要求原文**："Consider factors like existing defences, the criticality of targeted systems, and attack complexity when making your decisions."

几个词：**搭线窃听**（wiretapping，接入线缆旁听流量）；**端口扫描**（port scanning，向服务器各端口发探测包，看哪些服务在监听）；**SQL 注入**（SQL injection；SQL 即 Structured Query Language，结构化查询语言；注入指用户输入被拼进查询、被数据库当成指令执行，[[L10 网络安全：威胁、攻击与防御#4.1 注入：数据被当成指令|L10 4.1]]）；**拒绝服务**（denial of service，DoS）。

**读题**（[[#2.1 统一答题框架：威胁向量表与风险登记册|2.1]] 的规则）：拒绝服务、钓鱼是进行时，L=5；SQL 注入、搭线窃听都是 "An attacker can …"，按暴露面定——网页表单面向互联网，L=4；搭线要物理接入，L=2。

**第一步：分类。** 被动攻击两类、主动攻击四类是 Stallings 的分法，今年 L1 沿用（[[L1 信息安全基础#5.2 被动攻击与主动攻击|L1 5.2]]、[[L1 信息安全基础#5.3 具名的攻击|5.3]]）：

| 威胁 | 被动 / 主动 | Stallings / L1 类别 | 主要受损属性 |
| --- | --- | --- | --- |
| 搭线窃听 | **被动** | 消息内容泄露（release of message contents）；加密后仍有流量分析（traffic analysis，看出谁和谁通信、多频繁） | 机密性 |
| 端口扫描 | **主动**（向目标发包、能被记录），攻击前的侦察 | 不属于四类中的任何一类 | 本身不直接损害 |
| SQL 注入 | 主动 | 不属于四类中的典型一类：攻击者发自己构造的请求、借应用之手执行，不是篡改别人的消息 | 机密性、完整性 |
| 拒绝服务 | 主动 | 拒绝服务 | 可用性 |
| 冒充 CEO 的钓鱼 | 主动 | 冒充（masquerade） | 真实性，随后机密性、完整性 |

**第二步：打分排序。** 控制列的词：**参数化查询**（parameterized query，查询结构先交数据库定死，输入只作为值填进去）；**僵尸网络**（botnet，攻击者遥控的大批被感染机器，[[#6.4 蠕虫与僵尸网络（T05 p17–p22）|6.4]]）；**上游清洗**（scrubbing，流量到达前滤掉攻击包）与 **CDN**（content delivery network，内容分发网络，用各地节点分摊流量），见 [[L10 网络安全：威胁、攻击与防御#3.6 拒绝服务：可用性是容量问题|L10 3.6]]；**镜像口**（mirror / SPAN port，把交换机流量复制送出的端口）；**VPN**（virtual private network，虚拟专用网，公共网络上的加密隧道，[[L9 实用安全协议#7.4 IPsec 与 TLS 怎么选|L9 7.4]]）；**IDS**（intrusion detection system，入侵检测系统，发现攻击迹象并告警，[[L10 网络安全：威胁、攻击与防御#5.2 入侵检测与入侵防御|L10 5.2]]）。

| 排名 | 威胁（来源 → 路径 → 目标） | L | I | R | 风险等级 | 优先级 | 控制（降 L / I） |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 钓鱼：外部攻击者 → 冒充 CEO 的邮件 → 员工口令 → 内部系统 | 5 | 5 | 25 | High | **Critical** | 抗钓鱼 MFA、邮件来源认证（降 L）；方便的上报渠道 |
| 2 | SQL 注入：外部攻击者 → 表单输入拼进查询 → 后台数据库 | 4 | 5 | 20 | High | **Critical** | **参数化查询**（降 L）；数据库账户最小权限（降 I） |
| 3 | 拒绝服务：外部攻击者（常借僵尸网络）→ 洪泛流量 → 对外网页服务器 | 5 | 3 | 15 | High | High | 上游清洗、CDN、限速（降 L；吸收不完全、只是变慢时降 I） |
| 4 | 搭线窃听：内部人员或闯入者 → 线缆、镜像口 → 传输中的数据 | 2 | 4 | 8 | Medium | Medium | 全链路 TLS、跨站点 VPN（降 I）；机房门禁（降 L） |
| 5 | 端口扫描：互联网扫描者 → 探测包 → 对外服务器 | 5 | 1 | 5 | Low | Low | 关掉不需要的端口（降 L）；给暴露的服务打补丁；IDS 记录扫描源 |

I 的依据：钓鱼得手后攻击者以合法身份通过每道检查（5）；SQL 注入直达后台数据库（5）；拒绝服务是**暂时的**可用性损失，被打的是对外网页服务器而非后台数据（3，即题面的 "criticality of targeted systems"）；端口扫描只泄露开了哪些端口（1）。

**existing defences**：场景没写已有防御，上表按"没有"打分；要考虑就**明写假设再调分**，如"若敏感流量已全部加密，搭线窃听的 I 降到 2，$R=2\times2=4$，降为 Low"。示范第二轮做的正是这种分析，但把假设当成了场景事实。

材料最后一段比较了被动与主动攻击，正确的对比见 [[L1 信息安全基础#5.2 被动攻击与主动攻击|L1 5.2]]：被动难发现，重**预防**（加密）；主动难以绝对防止，重**检测与恢复**。

> [!warning] 示范答案的问题
> - **"Passive attacks include wiretapping, port scanning, and traffic analysis" 错**：端口扫描向目标发包、能被 IDS 记下，是主动侦察。Stallings（今年 L1）的被动攻击只有消息内容泄露和流量分析。
> - **"Overall mitigation strategies focus more on preventing active attacks" 方向反了**。
> - **搭线窃听**："physical access to network cables may be easy to obtain" 对大公司不成立；第二轮的 "we have encryption on all sensitive network traffic" 是新事实，应标为假设。
> - **"proper input sanitization" 不是首选修复**：过滤输入是总会漏的黑名单，结构性修复是参数化查询。
> - **拒绝服务 "until permanent access control fixes are made" 说不通**：洪泛是容量问题。
> - **"Common active attack examples include malware" 混了层次**：恶意软件是载体，不是四类中的一类（[[L1 信息安全基础#5.3 具名的攻击|L1 5.3]] 末尾）。

这个分类可直接用于模拟卷 Q1(c)（[[模拟卷全解#1.3 Q1(c) 主动攻击（7 分）|模拟卷全解 1.3]]）；Darth 图（Stallings 给攻击者起的名字）之外，可加画 [[#6.5 直接型与反射型 DDoS（T05 p23–p24）|6.5]] 的 DDoS 结构图说明拒绝服务。

## 3 算法选型类：Case 3、4、10

### 3.1 统一答题框架：先排除，再选定，最后写实施条件

这类题给几个加密算法，问哪个最适合保护机密性。四步：

1. **写清需求**：数据量、存储还是传输、要保护多久、要不要完整性。
2. **逐个排除**，给**可核对的理由**：密钥空间、穷举时间（[[L2 古典密码与密码分析#2.3 暴力破解要花多少|L2 2.3]]，课程口径每秒 $10^9$ 把、平均试一半）、有没有比穷举快的攻击（频率分析；Kasiski 方法，用密文里重复片段的间距求多表密码的周期）、能否处理大批量数据。
3. **选定**一个，说出它满足哪几条需求；选项都不合格就明说"跳出选项"并说明为什么。
4. **写实施条件**：**工作模式**（mode of operation，怎样把分组密码反复用于任意长的数据，[[L6 对称密码的安全使用#8.1 四种模式对照表|L6 8.1]]）、**密钥管理**（生成、分发、存放、更换）、**完整性**（只加密不认证，密文可以被改而不被发现）。三份示范都只答到第 3 步。

两条反复用到的结论：**密钥空间大是必要条件，不是充分条件**——单表代换有 $26! \approx 4.03\times10^{26} \approx 2^{88.4}$ 把密钥，比 DES 的 $2^{56}$ 大，照样被频率分析几分钟破掉（[[L2 古典密码与密码分析#4.1 密钥空间 26! 也救不了它|L2 4.1]]）；**一次一密**（one-time pad）**只在密钥真随机、和消息一样长、永不重用时完美保密**（[[L2 古典密码与密码分析#8.2 一次一密的三个条件|L2 8.2]]），它把通信问题换成同样大小的密钥分发问题（[[L2 古典密码与密码分析#8.4 为什么几乎不用|L2 8.4]]）。

### 3.2 Case 3：DES、AES、RSA 选哪个保机密性

**场景。** 跨国科技公司 LaGuardia Enterprises 要用加密保护大量专有研发数据。题面：DES 用 56 位密钥，"its relatively short key length makes it vulnerable to modern-day attacks like brute force"，公司还有遗留系统在用；AES 支持 128、192、256 位密钥，"widely considered the industry standard"；RSA 是非对称算法，"commonly used for secure key exchange, digital signatures, and protecting sensitive data"。

**要求原文**："Which encryption algorithm among DES, AES, and RSA is best suited to ensure the confidentiality of LaGuardia Enterprises' data, and why?"

**规范解答：数据用 AES（建议 256 位），套在 GCM 这类认证加密模式里；RSA 只封装 AES 密钥；DES 列入迁移计划。** **认证加密**（authenticated encryption）一次运算同时给出机密性和完整性；**GCM**（Galois/Counter Mode，伽罗瓦/计数器模式）用计数器模式加密，再在**有限域**（finite field，元素有限、四则运算封闭的代数结构）里算一个认证标签，密文改一位标签就对不上（[[L6 对称密码的安全使用#7.2 GCM：CTR 加一个在有限域里算的标签|L6 7.2]]）。

| 算法 | 评价 | 依据 |
| --- | --- | --- |
| DES | 排除 | $2^{56}\approx7.2\times10^{16}$ 把；1998 年 EFF（Electronic Frontier Foundation，电子前哨基金会）的 Deep Crack 56 小时破出一把（[[L3 分组密码与 DES#8.1 56 位密钥的寿命\|L3 8.1]]）；课程口径平均约 1.14 年 |
| AES | 选定 | AES-128 平均穷举约 $5.4\times10^{21}$ 年，AES-256 约 $1.8\times10^{60}$ 年；二十多年无实用攻击（[[L4 AES#11.1 四条理由\|L4 11.1]]）；有硬件指令 |
| RSA | 不加密数据 | 慢几个数量级；一次只能加密比模数短的一块；用来封装 AES 密钥（[[L7 公钥密码#7.1 混合加密：公钥管钥匙，对称管数据\|L7 7.1]]） |

"一块"有多大：2048 位 RSA 配 **OAEP**（optimal asymmetric encryption padding，RSA 加密前加随机填充的标准方法）时，填充占 $2h+2$ 字节（$h$ 是哈希输出字节数）；模数 $k=256$ 字节，SHA-256（输出 32 字节的标准哈希函数）$h=32$：

$$
k - 2h - 2 = 256 - 64 - 2 = 190 \text{ 字节}.
$$

实施条件：不用 ECB（electronic codebook，电子密码本模式，每块独立加密，相同明文块得相同密文块，[[L6 对称密码的安全使用#2.2 确定性：重复原样漏进密文|L6 2.2]]）；密钥与数据分开保管、定期更换；遗留 DES 先隔离再迁到 AES，**不以三重 DES 过渡**——NIST（National Institute of Standards and Technology，美国国家标准与技术研究院）已禁止 2023 年底后用它加密（[[L3 分组密码与 DES#10.2 三重 DES|L3 10.2]]）。

> [!example] 考场版（英文，算法选型类通用格式；结论、逐项排除、实施条件都写）
> **Choice:** AES-256 in an authenticated mode such as GCM for the data; RSA only to protect the AES key; DES phased out.
> - **DES — rejected:** a 56-bit key gives $2^{56} \approx 7.2\times10^{16}$ keys; Deep Crack found a key in 56 hours in 1998.
> - **RSA — not for bulk data:** orders of magnitude slower, and one operation encrypts less than the modulus (190 bytes for 2048-bit RSA-OAEP), so it encrypts the AES key (hybrid encryption). Its security rests on factoring $n = pq$, a product of two large primes.
> - **AES — selected:** no practical attack after 20+ years of analysis; brute force on AES-128 takes about $5.4\times10^{21}$ years at $10^9$ keys/s; fast with hardware support.
> - **Implementation:** GCM, not ECB, so patterns do not leak and tampering is detected; keys stored apart from data and rotated; legacy DES isolated and migrated straight to AES, not to 3DES, which NIST disallows for encryption after 2023.

> [!warning] 材料的问题
> - **"RSA's security relies on the mathematical complexity of factoring large prime numbers" 错**：质数不能再分解，RSA 依赖的是分解两个大质数之积 $n = pq$ 的困难（[[L7 公钥密码#5.5 安全性建立在大数分解上|L7 5.5]]）。
> - 示范没提模式、密钥管理和遗留系统；说 RSA "computationally more intensive" 只说了一半，一次只能装一个比模数短的块才是根本原因。

### 3.3 Case 4：古典密码与一次一密

**场景。** 软件公司的安全工程师 Kim 要为产品里的敏感客户数据选加密技术：Caesar、Transposition、Substitution、One-Time Pad；选定后对三个实施因素（Speed/Performance impact、Key management complexity、Cost of deployment）排序。示范一选 One-Time Pad（"theoretically unbreakable"，"The one-time cost of key distribution provides very high security"），因素排序密钥管理 > 成本 > 速度；示范二列出条件（"very sensitive customer information that requires strong encryption"、"less than 1GB per day"、"speed is important"、"Budget is limited"），然后选了**不在选项里的 AES**。

**要求原文**："Kim must choose an encryption technique and justify his choice based on the company's specific security needs and priorities."

**规范解答。**

| 选项 | 评价 | 依据 |
| --- | --- | --- |
| 凯撒 | 不可接受 | 只有 25 把有效密钥，手算就能穷举（[[L2 古典密码与密码分析#3.2 为什么一下午就能破\|L2 3.2]]） |
| 置换 | 不可接受 | 只重排不换字母，密文频率与英文一致，一眼可认出（[[L2 古典密码与密码分析#9.3 怎么一眼认出置换\|L2 9.3]]） |
| 单表代换 | 不可接受 | $2^{88.4}$ 把密钥也挡不住频率分析 |
| 一次一密 | 理论完美，对这个产品不可行 | 每天约 1 GB 数据就要每天生成并送达 1 GB 真随机密钥，一年 365 GB；数据存在产品里，密钥要和数据一样长、一样妥善地保存，"保护 1 GB 数据"换成了"保护 1 GB 密钥"；也不提供完整性（[[#3.4 Case 10：多表代换、Vigenère、Vernam\|3.4]]） |

**结论：四个都不满足 "requires strong encryption"，跳出选项选 AES（GCM），并写明跳出的理由**；若坚持四选一，选一次一密，把密钥管理写成第一风险。它的三个因素排序示范是对的：密钥管理决定成败（用两次就失去全部安全，[[L2 古典密码与密码分析#8.5 密钥重用的代价|L2 8.5]]）> 成本（由密钥管理派生）> 速度（逐位异或，几乎没有开销）。

> [!warning] 示范答案的问题
> - **"The one-time cost of key distribution" 自相矛盾**：密钥与全部明文一样长、只用一次，分发是持续的、与数据量成正比的成本。
> - **"No complex key management is required as AES uses a single symmetric key" 错**：对称密钥照样要生成、分发、保存、轮换、销毁，双方事先共享同一把密钥恰恰让分发成为难题（[[L7 公钥密码#1.1 密钥分发：建安全信道之前先得有安全信道|L7 1.1]]、[[L6 对称密码的安全使用#10 密钥管理|L6 第 10 节]]）。
> - **示范二没说为什么跳出选项**；两例都只讲机密性，没提一次一密不防篡改。

### 3.4 Case 10：多表代换、Vigenère、Vernam

**场景。** 创业公司做加密聊天应用，选项是 "Polyalphabetic substitution cipher"、"Vigenère cipher"、"Vernam cipher (one-time pad)"。示范选 Vernam（"the highest level of mathematically proven security"），并说 "keys can be securely exchanged out-of-band when users initialize their conversations"。

**要求原文**："You must evaluate each option based on: Security level, Implementation difficulty, Performance impact, Data size limitations."

三者的关系：**多表代换**（polyalphabetic substitution）是用几张代换表轮流加密的一类密码；**Vigenère** 是其中最典型的一个，关键词每个字母决定一张凯撒表，周期等于关键词长度（[[L2 古典密码与密码分析#7.1 一组轮换使用的凯撒|L2 7.1]]）；**Vernam** 逐位把明文与密钥流异或（[[L2 古典密码与密码分析#8.1 Vernam：用异或机械化|L2 8.1]]），密钥流真随机、等长、只用一次时就是一次一密。前两个是包含关系，不是并列的选项。

| 选项 | 安全性 | 实现难度 | 性能 | 数据量限制 |
| --- | --- | --- | --- | --- |
| 一般多表代换 | 低：用 Kasiski 方法或重合指数（index of coincidence，随机取两个密文字母相同的概率，单表时约 0.066，周期越长越接近 1/26）求出周期，再分列做频率分析 | 低 | 快 | 无 |
| Vigenère | 低：同样被 Kasiski 方法破（[[L2 古典密码与密码分析#7.2 重复泄露周期：Kasiski 方法\|L2 7.2]]） | 低 | 快 | 无 |
| Vernam / 一次一密 | 三个条件全满足时完美保密 | 算法极简，密钥管理极难 | 快 | **每发 1 字节消耗 1 字节密钥** |

**结论：三者都不适合。** 一次一密除了 [[#3.3 Case 4：古典密码与一次一密|3.3]] 说的密钥与数据等量、不防篡改，在聊天里还会**密钥耗尽**：初始化时交换的密钥必须等于以后要发的全部消息，用完就发不了；用户要么频繁见面换密钥，要么重用——重用即 $C_1 \oplus C_2 = P_1 \oplus P_2$，密钥被消掉（[[L2 古典密码与密码分析#8.5 密钥重用的代价|L2 8.5]]）。不防篡改：攻击者知道某处明文是 DAWN，把密文那四个字节异或上 $P \oplus P'$ = `0A 0E 18 00`，接收方就解出 NOON，因为 $C \oplus P \oplus P' = P' \oplus K$（[[L6 对称密码的安全使用#5.1 三种模式下怎样不用密钥改密文|L6 5.1]]）。

实际做法是认证加密（AES-GCM 或 ChaCha20-Poly1305，[[#4.4 Case 5：随机比特、流密码与 Feistel 解密|4.4]]）加公钥密钥协商（[[L7 公钥密码#6.1 在公开信道上约定一个秘密|L7 6.1]]）；必须三选一则选 Vernam，并写出三个前提和这些代价。

> [!warning] 示范答案的问题
> - **选项重叠没指出**："The Vigenère cipher is an incremental improvement with a longer key" 不准确，两者是包含关系；"Easy to implement simple substitution cipher" 又把多表代换说成单表代换。
> - **"keys can be securely exchanged out-of-band when users initialize their conversations" 与一次一密的定义冲突**：示范自己写了 "need for a random key as long as the message"，却一句带过了密钥耗尽。
> - **"Vernam cipher (one-time pad)" 的等号要加条件**：Vernam 1918 年的原设计用循环纸带，密钥流会重复，Mauborgne 加上"真随机且只用一次"后才是一次一密；"future-proofing" 也只在三个前提全满足时成立，且不含完整性。

## 4 随机数与流密码类：Case 7、6、5

### 4.1 统一答题框架：随机数的三个环节

题目常让"TRNG、PRNG、PRF 选一个"，可它们是一条流水线上的三个环节，不是互相替代的选项。完整定义见 [[L6 对称密码的安全使用#9.2 TRNG、PRNG、PRF|L6 9.2]]，各一行定位：

- **TRNG**（true random number generator，真随机数发生器）：从物理噪声采集不可预测的比特；慢、量少，原始输出有偏，要先**调理**（conditioning，去偏并压成均匀比特）。
- **PRNG**（pseudorandom number generator，伪随机数发生器）：确定性算法，从**种子**（seed）快速产生大量比特，安全全靠种子不可预测且保密。用于密码的叫 **CSPRNG**（cryptographically secure PRNG，密码学安全伪随机数发生器），NIST 标准（SP 800-90A）里叫 **DRBG**（deterministic random bit generator，确定性随机比特发生器）。
- **PRF**（伪随机函数）：输入**已有的秘密**加一段上下文，输出看似随机的值，用来从一个秘密派生出几个独立的子密钥，如一把加密、一把算 **MAC**（message authentication code，消息认证码，用共享密钥算出的校验值）。它**不产生熵**（entropy，"真正猜不到的信息量"）。

![[Tut 随机数的三个环节.png]]

*TRNG 只提供少量真随机的种子；CSPRNG 用种子产生大量密钥、IV（initialization vector，初始向量）和 nonce（number used once，只用一次的数），两者的要求见下面规则 3；PRF 从已有的秘密派生出用途不同的子密钥。*

L6 原话："You need the TRNG because algorithms cannot create unpredictability; you need the PRNG because physical entropy is far too slow to encrypt a video call." 由此三条规则：

1. **只选一个时，选由操作系统熵源播种的 CSPRNG**，并写出另两者的位置；代码调用操作系统接口（如 Linux 的 `getrandom()`），不用语言的普通 `random()`。
2. **看构造，不看输出**：统计检验只查"看起来随机"，查不了"不可预测"（[[L6 对称密码的安全使用#9.4 课堂活动 3：这些序列随机吗|L6 9.4]]）。参数选得好的线性同余发生器（[[#4.3 Case 6：LCG 与 BBS|4.3]]）能通过统计检验，照样不能生成密钥。
3. **IV 与 nonce 的要求随模式不同**：**CBC**（cipher block chaining，每块明文先与上一块密文异或再加密）的 **IV**（加密第一块时代替"上一块密文"的公开值）必须不可预测（[[L6 对称密码的安全使用#3.2 IV：公开，但必须不可预测|L6 3.2]]）；CTR（加密递增的计数器生成密钥流，[[L6 对称密码的安全使用#4.1 加密计数器，再与明文异或|L6 4.1]]）、GCM 的 **nonce** 只需唯一，但绝不能重复（[[L6 对称密码的安全使用#4.2 nonce 绝不能重复|L6 4.2]]）。

### 4.2 Case 7：TRNG、PRNG、PRF 选一个

**场景。** 为新的安全邮件服务生成随机密钥和 IV，三选一："Hardware-based TRNG"、"Cryptographically secure PRNG (e.g. BBS, Fortuna)"、"Hash-based PRF (e.g. HMAC-SHA256)"。

**要求原文**："You must select one option and justify your decision based on factors like: Unpredictability, Security strengths, Performance efficiency, Ease of implementation." 示范选 CSPRNG，排序不可预测性 > 安全强度 > 性能 > 实现难度——选择和排序都对，理由有错（见 warning）。

**规范解答：选 CSPRNG，由操作系统熵源（底层就是 TRNG）播种，为每封邮件生成会话密钥和 IV。**

只用 TRNG 不行：慢，供不上每封邮件，硬件故障或虚拟机克隆还会让熵不足；只用 PRF 不行：它的不可预测性全取决于输入的秘密，自己不产生熵，主密钥一泄露派生出的全部失守。

PRF 的位置：会话密钥生成后，用 **HMAC**（hash-based message authentication code，基于哈希的消息认证码，可当 PRF 用）或建在它上面的 **HKDF**（HMAC-based key derivation function，基于 HMAC 的密钥派生函数）派生出加密子密钥和 MAC 子密钥。

> [!example] 考场版（英文，随机数类通用格式；选择、逐因素理由、另两者的位置都写）
> **Choice:** a cryptographically secure PRNG seeded from the operating system's entropy source, which is itself a hardware TRNG.
> - **Unpredictability (first):** a predictable key makes key length irrelevant; with a true-random seed the output cannot be predicted.
> - **Security strength:** standard designs (HMAC_DRBG and CTR_DRBG in NIST SP 800-90A, Fortuna) reseed regularly and recover after a state compromise.
> - **Performance:** a TRNG alone is too slow for a key and IV per message; the CSPRNG produces bits in bulk.
> - **Ease of implementation:** call the OS interface (e.g. getrandom()), never a language's ordinary random().
> - **The other two:** the TRNG is the seed source, not the bulk generator; a PRF needs a secret input and creates no entropy, so it derives keys (e.g. HKDF: separate encryption and MAC keys from the session key) rather than generating them.

> [!warning] 示范答案的问题
> - **"PRFs … are relatively slow compared to symmetric cryptographic PRNGs" 不是排除 PRF 的理由**：每封邮件只要几十字节的密钥和 IV，速度无关紧要；标准的 CSPRNG 本身就由 PRF 或分组密码构造（HMAC_DRBG 核心是 HMAC，CTR_DRBG 核心是 AES 的计数器模式）。不用 PRF 生成随机数，是因为它需要秘密输入、不产生熵。
> - **"The cryptographic primitives introduce randomness" 错**：确定性算法不引入随机性，L6 原话 "algorithms cannot create unpredictability"。
> - **"TRNGs … require specialized hardware which may be costly" 与现状不符**：x86 的 RDRAND/RDSEED、ARM 的 RNDR 指令、操作系统的熵池都免费可用。
> - **"e.g. BBS" 不是 CSPRNG 的典型例子**：BBS 在实际系统里几乎不用（[[#4.3 Case 6：LCG 与 BBS|4.3]]）。Fortuna 这个例子对：FreeBSD 内核的随机数生成器默认用它，Apple 平台的内核 CSPRNG 也基于它。

### 4.3 Case 6：LCG 与 BBS

**场景与要求原文。** 安全消息应用要在 "Linear Congruential Generator (LCG)" 与 "Blum Blum Shub (BBS) Generator" 中二选一："You must select one of these two options and justify your choice based on factors such as security, performance, and ease of implementation." 示范选 BBS，排序安全 > 性能 > 实现难度。

**LCG**（linear congruential generator，线性同余发生器）：$X_{n+1} = (aX_n + c) \bmod m$。它是线性的：模数 $m$ 已知时，三个连续输出就能解出 $a$、$c$，前后输出全部可算（$m=2^{32}$ 或未知时要多看几个；手算见 [[L6 对称密码的安全使用#9.3 两项要求：统计上随机，且不可预测|L6 9.3]] 的 $m=31$ 例）。统计性质可以过关，**不可预测性为零**。

**BBS**（Blum Blum Shub，取三位提出者 Lenore Blum、Manuel Blum、Michael Shub 的姓）：

1. 选两个大质数 $p$、$q$，都满足 $p \equiv q \equiv 3 \pmod 4$，令 $n = pq$；
2. 选与 $n$ 互素的种子 $s$，令 $X_0 = s^2 \bmod n$；
3. $X_i = X_{i-1}^2 \bmod n$，输出最低位 $B_i = X_i \bmod 2$。

小例（Stallings 第 8 章的教学参数）：$p=383$、$q=503$（除以 4 都余 3），$n = 192649$，种子 $s=101355$。

| $i$ | 0 | 1 | 2 | 3 | 4 | 5 |
| --- | --- | --- | --- | --- | --- | --- |
| $X_i$ | 20749 | 143135 | 177671 | 97048 | 89992 | 174051 |
| $B_i$ | — | 1 | 1 | 0 | 0 | 1 |

前 20 个输出位：`1 1 0 0 1 1 1 0 0 0 0 1 0 0 1 1 1 0 1 0`（实际 $n$ 至少 2048 位）。安全性：已证明能预测下一位的人就能分解 $n$，所以预测至少和分解一样难——在"分解大数难"的假设下**可证明安全**。代价是每输出 1 位做一次 2048 位的模平方，很慢。

**规范解答。**

| 因素 | LCG | BBS |
| --- | --- | --- |
| 安全 | **不可用**：几个输出就能解出参数 | 可证明安全，前提是分解 $n$ 难且 $p$、$q$、种子保密 |
| 性能 | 极快 | 很慢 |
| 实现难度 | 极简单 | 要生成满足条件的大质数，容易出错 |

**二选一选 BBS**：安全是第一因素，LCG 在这一项不及格。再补一句：**实际产品两个都不选**，用操作系统的 CSPRNG 或 NIST SP 800-90A（NIST 关于 DRBG 的标准）里基于哈希、HMAC 或 AES 计数器模式的 DRBG——同样安全、快得多、有审计过的实现。

> [!warning] 示范答案的问题
> - **"BBS utilizes factorization of large primes" 错**，与 Case 3 同一个错：安全性来自分解 $n = pq$ 的困难；生成过程只做模平方，不做任何"分解"。
> - **"The large asymmetric key sizes used in BBS" 用词不当**：BBS 没有公钥私钥对，攻击者要猜的是种子与内部状态。
> - **"Benchmarks show BBS can produce random bits at speeds fast enough" 没有出处**，BBS 恰恰以慢著称；**"industry-standard BBS library"** 也不存在：主流密码库和操作系统都不用 BBS，SP 800-90A 里也没有它。

### 4.4 Case 5：随机比特、流密码与 Feistel 解密

**场景。** 加密消息应用要从三类里各选一项：Random Bit Generation（"Hardware-based true random number generator"、"Cryptographically secure pseudo-random number generator"）；Stream Ciphers（"RC4"、"Salsa20"、"AES in CTR mode"）；Feistel Decryption（"Basic Feistel structure"、"Optimized Feistel with 16 rounds"）。

**要求原文**："You must choose one option from each category and assign a security-level justification." 示范选硬件 TRNG、AES-CTR（"CTR mode is recommended over RC4 and Salsa20"）、16 轮 Feistel，因素排序安全 > 性能 > 成本。

选项里的名字：**RC4** 是 1987 年的流密码，曾用于网页加密和早期 Wi-Fi，密钥流有统计偏差；**Salsa20** 及其改进版 **ChaCha20** 是 Bernstein 设计的流密码，ChaCha20 配 **Poly1305**（一次性消息认证码）组成认证加密方案；**CTR** 用分组密码加密递增的计数器生成密钥流再与明文异或，L6 原话 "CTR — turning a block cipher into a stream cipher"。

| 类别 | 选择 | 理由 |
| --- | --- | --- |
| 随机比特 | **两者组合**：操作系统熵源播种 CSPRNG | TRNG 慢且有偏，单独用供不上；PRNG 没有真随机种子就是确定的 |
| 流密码 | **AES-CTR，但放在 AES-GCM 里**；没有 AES 硬件加速的手机用 ChaCha20-Poly1305 | CTR 只给机密性，消息应用必须防篡改。RC4 有密钥流偏差，RFC 7465（RFC，Request for Comments，互联网标准文档的编号系列）已禁止 TLS 使用它 |
| Feistel 解密 | **本设计里不适用** | 见下 |

**为什么不适用。** AES 不是 Feistel 结构，每轮处理整个分组（[[L4 AES#2.2 放弃 Feistel：每轮处理整块|L4 2.2]]）；更根本的是，**CTR 只用分组密码的加密方向**：解密时同样计算 $E_K(\text{counter})$ 得到同一段密钥流再异或，根本不调用 $D_K$。若一定要答：Feistel 的解密就是同一结构把子密钥倒序使用（[[L3 分组密码与 DES#5.4 解密：同一个算法，密钥倒序|L3 5.4]]），轮数由设计者按已知攻击定，不是使用者在 "Basic" 与 "Optimized" 之间挑的。

**因素排序**安全 > 性能 > 成本与示范一致，理由换成：消息内容是首要资产；性能靠 AES 硬件指令或 ChaCha20 解决；熵源和这些算法都免费，成本几乎为零。

> [!warning] 示范答案的问题
> - **"CTR mode is recommended over … Salsa20" 没有依据**：TLS 1.3（RFC 8446）里 AES-128-GCM 是唯一必须实现（MUST）的套件，ChaCha20-Poly1305 与 AES-256-GCM 同为应当实现（SHOULD）。
> - **"AES in CTR mode" 列在 "Stream Ciphers" 下要说明**：AES 是分组密码，是 CTR 把它变成流密码。
> - **"Hardware entropy source gives maximum unpredictability" 只说了一半**（Priority 3 的 "a true RNG provide the highest security" 同理）：原始输出要调理且慢，实际都用它播种 CSPRNG。
> - **通篇没提完整性**，对消息应用是硬伤。

## 5 构件评价类：Case 8 AES 的轮变换

### 5.1 先纠正题意：四步缺一不可

**场景。** 为安全文件存储系统设计高效的 AES 实现，评价轮函数里的 ShiftRows、MixColumns、AddRoundKey。**要求原文**："You must analyze each transformation based on criteria such as: Security level, Implementation complexity, Performance impact, Memory requirements." 示范接着用 "You could then rank the priorities as" 给标准排了序，最后"选定"MixColumns（"brings the strongest cryptographic properties"）。

题意有两处错，答卷先指出：

1. **不存在"选一个"**：AES 每轮依次执行 SubBytes、ShiftRows、MixColumns、AddRoundKey，缺一不可（最后一轮省掉 MixColumns，第一轮前先做一次 AddRoundKey，[[L4 AES#3.2 AES-128 的总体结构|L4 3.2]]）。
2. **漏了 SubBytes**，唯一的非线性步骤：没有它整个密码是一组线性方程，可直接解出密钥（[[L4 AES#5.3 没有它，整个密码就是一组线性方程|L4 5.3]]）。

### 5.2 逐项评价

表中的词：**混淆**（confusion，让密钥与密文的关系尽量复杂）与**扩散**（diffusion，把一个明文位的影响摊到许多密文位上）（[[L3 分组密码与 DES#4.4 两者缺一不可|L3 4.4]]）；**S 盒**（substitution box，256 项的固定字节代换表，[[L4 AES#5.1 查表：高 4 位定行，低 4 位定列|L4 5.1]]）；**恒定时间**（constant-time）实现指运行时间与密钥和数据无关，用来防**侧信道**（side channel，从运行时间、功耗等物理表现偷信息，[[L3 分组密码与 DES#8.3 计时攻击与侧信道|L3 8.3]]）。

| 变换 | 做什么 | 安全作用 | 实现复杂度 | 性能 | 内存 |
| --- | --- | --- | --- | --- | --- |
| SubBytes | 每个字节查 S 盒 | **唯一的非线性**，提供混淆 | 低；做成恒定时间较难 | 快 | 256 字节的表 |
| ShiftRows | 第 $r$ 行循环左移 $r$ 字节 | **跨列扩散**；没有它 AES 就是四个并排的 32 位密码（[[L4 AES#6.2 没有它，AES 就是四个并排的 32 位密码\|L4 6.2]]） | 极低 | 几乎为零 | 无 |
| MixColumns | 每列乘固定矩阵（[[L4 AES#7.1 一列乘一个固定矩阵\|L4 7.1]]） | **列内扩散**；与 ShiftRows 合起来两轮完全扩散（[[L4 AES#7.4 两轮达到完全扩散\|L4 7.4]]） | 中：有限域乘法，实为移位与异或 | 软件实现里最费时 | 可与 S 盒合并成 4 张各 1 KB 的表 |
| AddRoundKey | 与 128 位轮密钥逐位异或 | **唯一引入密钥的步骤**（[[L4 AES#8.2 四步单拿出来都不是密码\|L4 8.2]]） | 极低 | 一条异或 | AES-128 要 11 把 16 字节轮密钥 |

四步单拿出来都不是密码，交替叠加十轮才是，所以只能问每一步"贡献什么"。标准优先级：安全（四步完整实现，不为性能删改）> 性能 > 实现复杂度（复杂处易出侧信道）> 内存（几 KB 不是约束）。实现用 **AES-NI**（AES New Instructions，一条指令完成一整轮），更快且运行时间与密钥无关（[[L4 AES#11.2 实际部署|L4 11.2]]）；整盘用 XTS（为磁盘扇区设计的模式），单个文件用 GCM（[[L6 对称密码的安全使用#8.1 四种模式对照表|L6 8.1]]）。

> [!example] 考场版（英文，构件评价类通用格式；先纠正前提，再逐项评价，最后排优先级）
> **Premise:** every AES round applies all four transformations (the last omits MixColumns), so none can be "selected"; the list also omits SubBytes, the only non-linear step.
> - **SubBytes:** S-box lookup; confusion — without it AES is linear; 256-byte table; must be constant-time to avoid cache-timing leaks.
> - **ShiftRows:** row $r$ rotated left by $r$ bytes; spreads each column over four columns; no computation or memory.
> - **MixColumns:** each column times a fixed matrix over GF(2⁸); diffusion within a column, full diffusion after two rounds with ShiftRows; the costliest step in software.
> - **AddRoundKey:** XOR with the round key; the only step using the key; 11 round keys (176 bytes) for AES-128.
>
> **Priorities:** security > performance > implementation complexity > memory. Use AES-NI (fast, constant-time); XTS for whole disks, GCM for files.

> [!warning] 示范答案的问题
> - **"selection of the mix columns transformation" 没有意义，且漏了 SubBytes**：见 [[#5.1 先纠正题意：四步缺一不可|5.1]]。
> - **"ShiftRows: High-security level … provides good diffusion"**：单独的 ShiftRows 只是公开的重排，本身不提供安全性，只在与 MixColumns 配合时提供扩散。
> - **"This makes attacks against the cipher computationally infeasible" 把整体安全归给 MixColumns**：前三步不含密钥，拿到密文可直接倒回去；AddRoundKey 单独用就是重复使用密钥的 Vernam 密码。
> - **前后矛盾**：结尾 "security first, implementation simplicity second, and performance third" 与前文 Security > Performance > Implementation > Memory 对不上。

模拟卷 Q2(a)、Q2(c) 的单题答法见 [[模拟卷全解#2.1 Q2(a) AddRoundKey（4 分）|模拟卷全解 2.1]]、[[模拟卷全解#2.3 Q2(c) ShiftRows（7 分）|2.3]]。

## 6 旧版辅导幻灯片：今年没讲但可能考的条目

### 6.1 九份幻灯片是什么，哪些不收

9 份幻灯片是辅导课和自学用的案例材料，不是往年讲义：T01–T04 是概念练习与风险管理，T05 是恶意软件与应用安全（与模拟卷 Q1(b) 同族），T06–T09 介绍几篇论文。收录标准：**今年 L1–L10 没有成段讲过**、且可能出成简答。6.2–6.12 按题族排：Q1(a) 族 → Q1(b) 族（6.3、6.4）→ Q1(c) 可用的图与阶段模型（6.5、6.6）→ 风险与 CIA（6.7–6.9）→ 应用安全（6.10）→ 密码学延伸（6.11、6.12）。不收的四处：

- **T02 p3–p12 银行安全计划**：共 10 项（编号到 9，"Data Backup and Recovery" 漏了编号），都是 L1、L10 讲过的控制。
- **T05 p25–p27 防火墙与 SQL 查询四步**：[[L10 网络安全：威胁、攻击与防御#5.1 防火墙：看懂多少流量，以及放在哪|L10 5.1]]、[[L10 网络安全：威胁、攻击与防御#4.1 注入：数据被当成指令|4.1]] 已讲透。
- **T09 机载网络的敌方方向感知路由**（Hostile-Direction Aware Routing Protocol）：军用路由仿真论文，与本课无交点。
- **T03 p28–p41 区块链用于预测性维护**：可作模拟卷 Q4(c)(iv) "other two potential blockchain-enabled applications" 的一个答案（[[模拟卷全解#4.9 Q4(c)(iv) 其他区块链应用（2 分）|模拟卷全解 4.9]]）：物联网（Internet of Things，IoT）传感数据上链保完整性，**智能合约**（smart contract，链上条件满足时自动执行的程序）触发维护工单。

### 6.2 威胁定义清单与入侵途径（T02 p25、T05 p3–p4）

**T02 p25**："To avoid overlooking important threat sources, you need to consider all types of threats"，接着列六项；它是 Rhodes-Ousley 那本书第 2 章的提纲，用作**建威胁向量表的检查清单**：

| 项 | 意思 |
| --- | --- |
| Threat vectors | 威胁从哪来、走哪条路到达目标 |
| Threat sources and targets | 来源：外部攻击者、内部人员、供应商、自然灾害与故障；目标：数据、系统、人 |
| Types of attacks | 按手段分：恶意代码、拒绝服务、钓鱼、未授权访问 |
| Malicious mobile code（恶意移动代码） | 从远端传来、不经明确安装就在本机执行的代码：网页脚本、文档宏、浏览器插件 |
| APT（advanced persistent threat，高级持续性威胁） | 资源充足（常有国家背景）的攻击者，长期潜伏、用定制工具持续窃取 |
| Manual attacks（手动攻击） | 由人实时操作、随机应变，区别于蠕虫、扫描器这类自动化攻击 |

**T05 p3–p4 "How do computers get compromised?"** 的六类途径，每条都是现成的威胁向量例子（来源 → 路径 → 目标）：恶意网站 → 浏览器 → 用户电脑；外部发件人 → 邮件附件 → 用户电脑；被感染的 U 盘 → USB 接口 → 电脑；被感染的安装介质 → 安装程序 → 电脑；互联网攻击者 → 开放的服务端口（操作系统、网页服务器、SQL 数据库的漏洞）→ 服务器；供应链某一环 → 出厂硬件或软件 → 最终用户。

今年最接近的是 [[L1 信息安全基础#6.2 攻击面|L1 6.2 攻击面]]：攻击面是"够得着的弱点的集合"，威胁向量是"从来源走到弱点的那条路"。

### 6.3 恶意软件的经典定义（T05 p5–p16）

L10 按"怎么传播 × 做了什么"给恶意软件分类（[[L10 网络安全：威胁、攻击与防御#2.1 两个独立的问题：怎么传播，做了什么|L10 2.1]]），多态/变形只在 [[L10 网络安全：威胁、攻击与防御#2.4 为什么恶意软件难检测|L10 2.4]] 一句带过。下面是 T05 里 Stallings 式的经典定义。

**病毒的四个阶段（p16）**，经典简答考点："dormant · propagation · triggering · execution"：

| 阶段 | 意思 |
| --- | --- |
| 潜伏（dormant） | 已在系统里但不活动，等某个事件唤醒；不是所有病毒都有 |
| 传播（propagation） | 把副本插入其他程序或磁盘系统区，每个被感染的程序又成为传染源 |
| 触发（triggering） | 条件满足，被激活 |
| 执行（execution） | 执行载荷：显示消息或删改文件 |

**后门 / 陷门**（backdoor / trapdoor，p10–p12）：程序里隐藏的入口，知道它的人可绕过正常检查直接进入。三种来路：被漏洞利用植入（远程控制，可潜伏很久）；用户被骗自己装上，即**特洛伊木马**（Trojan，伪装成有用程序、诱人主动安装的恶意代码）；设计时留下（测试入口忘了删），靠**安全开发生命周期**（secure development lifecycle，需求到发布各阶段都做安全审查的流程）预防。

**逻辑炸弹**（logic bomb，p14）：嵌在合法程序里，条件满足（某文件存在与否、某日期、某用户登录）时删改文件、清空磁盘；典型来源是心怀不满的内部人员（"我的账号被删时清空数据库"）。

**三种躲避检测的病毒（p6）**，针对的都是**特征码**（signature，杀毒软件识别已知样本的字节模式）匹配：**隐形病毒**（stealth virus）对检测软件隐藏整个病毒，如拦截系统调用、让扫描器读到未感染的内容；**多态病毒**（polymorphic virus）每次感染换密钥加密病毒体并变换解密代码，特征码变、**功能不变**；**变形病毒**（metamorphic virus）每次**整体重写自己**，行为也可能变。

**exploit**（漏洞利用，p7–p9）：利用软硬件缺陷让系统做出设计外行为的代码、数据或命令序列；载体常是藏着畸形数据的 PDF、办公文档、媒体文件；功能是下载后门，或直接取得控制、提权、拒绝服务。放进 L10 的两问：病毒、蠕虫回答"怎么传播"，后门、逻辑炸弹回答"做什么、何时做"，exploit 是撬开系统的那一下。

> [!warning] T05 p6 的定义不标准
> 幻灯片按"跨系统 / 同一系统"区分："Polymorphic virus — Different for every system"、"Metamorphic virus — Different after every activation on the same system"。标准区分（Stallings）是"改外形"与"整体重写"，答题按 Stallings 写。"Stealth virus — Uses techniques to hide, e.g., encryption" 也把隐形与加密混了：用加密改外形的是**加密病毒**（encrypted virus）。

### 6.4 蠕虫与僵尸网络（T05 p17–p22）

**蠕虫（p17–p18）**："Replicating programs that propagate over the net"——经开放端口攻击远程系统上有漏洞的进程，也可走邮件、远程执行、远程登录；主动搜索下一个目标，可能伪装成系统进程。两个案例：**Morris 蠕虫**（1988，利用 UNIX 漏洞，第一个造成大范围互联网事故的蠕虫，约感染当时 6 万台主机的十分之一）；**WannaCry**（2017 年 5 月，"蠕虫 × 勒索"，利用 Windows 文件共享协议 SMB（Server Message Block）第 1 版的漏洞 MS17-010 自动传播）。

**传播三阶段（p19）**：感染主机数随时间呈 S 形（约 600 分钟升到约 $5\times10^5$ 台）：慢启动（slow start）→ 快速扩散（fast spread）→ 慢收尾（slow finish）。这是 logistic 模型。设地址空间大小 $\Omega$（IPv4 为 $2^{32}$）、易感主机 $N$ 台、每台每秒扫描 $s$ 次、已感染 $n(t)$ 台：一次扫描命中未感染易感主机的概率是 $(N-n)/\Omega$，于是

$$
\frac{dn}{dt} = \frac{s}{\Omega}\, n\, (N-n) = \beta\, n \left(1-\frac{n}{N}\right), \qquad \beta = \frac{sN}{\Omega}.
$$

$n$ 小时增长近似 $\beta n$，是指数增长（慢启动只是基数小）；$n$ 接近 $N$ 时停下。$\beta$ 正比于 $N$：**打补丁同时压低增长率和平台**，越早越好。

**僵尸网络（p20–p22）**："A botnet is a collection of computers infected with malicious software agents (robots) that can be controlled remotely by an attacker." 被感染的机器（**bot**）的主人通常不知情；控制者（**bot herder / bot master**）经**命令与控制**（command and control，C&C）服务器下指令，让 bot 协同发垃圾邮件、收集身份信息、拒绝服务、扩散、挖矿。下一节的 DDoS 结构就是这个架构用于拒绝服务。

> [!warning] T05 p18：WannaCry 不是 "Windows XP" 的事
> 幻灯片说它 "exploits known, but unpatched, vulnerability in Windows XP"。MS17-010（EternalBlue）影响多个 Windows 版本，受害机绝大多数是 **Windows 7**；在 XP 上它常直接让系统崩溃而传播不了。"known, but unpatched" 对：补丁 2017 年 3 月已发布，两个月后爆发。

### 6.5 直接型与反射型 DDoS（T05 p23–p24）

DDoS 用成千上万台被控机器同时洪泛。两种结构（Stallings《Computer Security》的经典图，按其结构重画）：

![[Tut 直接型与反射型 DDoS.png]]

*上半部分相同：攻击者经主控僵尸向从属僵尸下指令。直接型由从属僵尸自己打受害者；反射型由从属僵尸把源地址伪造成受害者的请求发给无辜的反射器，回复全部涌向受害者。*

| | 直接型（direct） | 反射型（reflected） |
| --- | --- | --- |
| 幻灯片原话 | "Bots send traffic with their own or spoofed sender address to the victim" | "Bots send traffic to innocent hosts with the victim's address as the sender's address. Innocent hosts become part of an attack by replying to the victim." |
| 伪造源地址 | 可选 | **必须**是受害者的地址 |
| 受害者看到的来源 | 僵尸或伪造地址 | 无辜的反射器，追溯更难；回复远大于请求时就是**放大**攻击 |

两层结构隐藏攻击者、便于指挥。[[L10 网络安全：威胁、攻击与防御#3.6 拒绝服务：可用性是容量问题|L10 3.6]] 讲了反射放大，但没有这张图。

### 6.6 攻击的阶段：网络杀伤链（T05 p13、T02 p26–p35）

**网络杀伤链**（cyber kill chain）是洛克希德·马丁公司 Hutchins 等人 2011 年提出的模型，把一次有针对性的入侵拆成七个必须依次完成的阶段：侦察（reconnaissance，收集员工、邮箱、对外服务、软件版本）→ 武器化（weaponisation，把漏洞利用代码和后门打包成载体）→ 投递（delivery，钓鱼邮件、恶意网站、U 盘）→ 利用（exploitation）→ 安装（installation，装后门实现持久化）→ 命令与控制（C&C）→ 行动 / 外泄（actions on objectives / exfiltration）。

![[Tut 网络杀伤链.png]]

*T05 p13 原图：左栏七个阶段，右栏每阶段通常持续的时间。"Reconaissance" 拼写有误，应为 Reconnaissance。*

两个推论：**任意一环被打断，整条链就断**（"possible steps to kill it"），与 [[L1 信息安全基础#6.3 攻击树|L1 6.3]] 攻击树的与节点同理；**时间尺度决定防御方式**：利用、安装以毫秒、秒计，只能事先预防（补丁、最小权限），侦察、命令与控制持续几小时以上，是**检测**的窗口（监控异常的对外连接）。

**T02 p26–p35 "CSI" 攻击八阶段**：侦察 → 社会工程（**鱼叉式钓鱼**，spear phishing，针对特定个人定制的钓鱼）→ 利用 → 提权 → 外泄 → 掩盖痕迹（"delete or alter logs, modify timestamps, and use anti-forensic techniques"）→ 后续活动 → 退出。多出的"掩盖痕迹"说明日志要实时送到独立服务器（[[L1 信息安全基础#4.4 回到开场的四起事故|L1 4.4]] 事故 D）。L10 的勒索软件五阶段也是"阶段 + 每段配防御"的分析。

> [!warning] T02 p26 自相矛盾
> 同一页标题写着 "Use Case: Computer Security Institute (CSI) Attack-Type"，正文却说 "CSI is a fictitious hacking group known for its sophisticated cyberattacks"。CSI 是真实的美国安全专业组织，多年与 FBI 联合发布年度计算机犯罪调查；"CSI attack types" 指那份调查按攻击类型的统计，不是一个虚构黑客组织的手法。

### 6.7 CIA 归类练习（T01）

题干："Classify each of the following as an attack on confidentiality, integrity, and/or availability (more than one may apply). Justify your answers."（改编自 Bishop《Computer Security: Art and Science》第 1 章习题 1。）与 [[L1 信息安全基础#4.3 判断一起事件丢了什么|L1 4.3]] 同型：问"失去了什么"。

| 情景 | 幻灯片 | 正确答案与理由 |
| --- | --- | --- |
| John copies Mary's homework | C + I | **C**：作业被未授权获取，没有数据被改。幻灯片把 "academic integrity" 的 integrity 当成了完整性 |
| Paul crashes Linda's system | A | **A** |
| Liza spoofs Julie's IP address to gain access to her computer | C + I + A | **I + C**：伪造源 IP 即伪造来源，破坏真实性（FIPS 199 把真实性算在完整性里，[[L1 信息安全基础#4.2 三个扩展属性\|L1 4.2]]）；借此进入还能读数据。A 只是"可能" |
| Jena obtains Peter's credit card number and has the card company cancel the card and replace it with another card bearing a different account number | C + I | **C + I + A**：获取卡号（C）；冒充 Peter 改发卡行记录（I）；旧卡注销后 Peter 用不了卡（A） |
| Rosy registers the domain name "AddisonWesley.com" and refuses to let the publishing house buy or use it | A | **A**：**域名抢注**（cybersquatting）让所有者用不上本属于它的资源 |
| Gina forges Roger's signature on a deed | I | **I**：也可说破坏了真实性与不可否认性 |
| Carol changes the amount of Angelo's check from \$100 to \$1,000 | I | **I** |

英文每条一句，先属性后依据："Confidentiality only — Mary's homework is disclosed without authorisation; nothing is modified, so integrity is not affected."

> [!warning] T01 的两处问题
> - **p22 标题 "✓ Confidentiality" 带勾**，正文却说 confidentiality "is not the primary focus"（改支票那题，答案只有完整性）。
> - **p8 的 IP 欺骗图是盲目欺骗**：回复发往被冒充的真实地址，攻击者收不到，单靠伪造源 IP 不能交互地 "gain access"（除非他在通信路径上，或猜中 TCP 序号，即传输控制协议给连接上的数据编的号），判三个属性全受损是论证过度。

### 6.8 风险分析与安全计划（T02 p2–p24）

**安全计划六阶段（p2）**：授权（章程、资源）→ 框架（策略、标准、指南）→ 评估（风险分析、差距分析、整改计划）→ 规划（路线图、架构）→ 行动（规程、事件响应）→ 维护（执行、培训）。第 2 节的风险登记册是"评估"阶段的产出。

**风险分析的优缺点（p13–p17）**：优点是识别风险、按影响和可能性排序（"address the most critical risks first"）、支撑决策；缺点是只是某一时刻的快照（"new vulnerabilities and threats continually emerge"）、给人虚假的安全感、耗费资源。可补 L1 的一条：L、I 都是估计，ALE（annualised loss expectancy，年度损失期望）这类平均值看不到"一次就致命"的尾部风险（[[L1 信息安全基础#3.2 给控制措施算一笔账：ALE|L1 3.2]]）。

**电商风险计划（p18–p24）** 把数据泄露定 high、支付欺诈与 DDoS 定 moderate，问题是**等级没有可能性和影响的依据**；按 2.1 应写成"来源 → 路径 → 目标、L、I、理由"，如数据泄露 high："存有全部客户的支付信息（I 高），网页应用持续被扫描（L 高）"。

### 6.9 在线口令暴力破解与 Equifax（T03、T04）

**在线暴力破解（T03 p2–p27，T04 p26–p38 重复）**：攻击者对网银登录页系统地尝试大量"用户名 + 口令"。与离线破解对比：

| | 在线（online） | 离线（offline） |
| --- | --- | --- |
| 对象 | 运行中的登录接口 | 偷到的口令哈希库或密文（例：[[L9 实用安全协议#9.3 WPA2：四次握手与离线字典攻击\|L9 9.3]]） |
| 速度受谁限制 | 服务器：可限速、可锁定 | 攻击者自己的算力 |
| 主要防御 | 锁定、限速、人机验证、MFA | 长口令、慢哈希、库不被偷 |

关键一步是**绕过锁定与限速**："IP rotation or distributed attacks using multiple compromised systems or botnets"，每个来源都低于阈值；后果是**账户接管**（account takeover）。对策与局限：

| 对策 | 局限 |
| --- | --- |
| MFA | 短信或 App 的一次性验证码（one-time password，OTP）能被实时中继钓鱼绕过，要用抗钓鱼的 MFA |
| 账户锁定 | 可被故意输错来锁住大批用户（成了拒绝服务工具）；挡不住每个账户只试一两个常见口令的**口令喷洒**（password spraying） |
| 限速 | 被 IP 轮换和僵尸网络绕过 |
| 人机验证（CAPTCHA，Completely Automated Public Turing test to tell Computers and Humans Apart，区分人和程序的全自动公开图灵测试） | 有人工打码服务和识别工具 |
| **基于风险的认证**（risk-based authentication，地点、设备、时间异常时才加验证） | 有误报 |

> [!warning] T03、T04 的两处错误
> - **"regularly enforced password changes"、"frequently changed passwords" 与现行标准相反**：NIST SP 800-63B-4（2025 年修订，§3.1.1.2）规定 "SHALL NOT require subscribers to change passwords periodically"，只在有泄露迹象时强制更换；定期强制更换只产生 Summer2024! 这种可预测口令（[[L1 信息安全基础#7.3 十三条设计原则|L1 7.3]] 的心理可接受性）。
> - **T03 p2 的图与场景不符**：场景是在线破解，图画的却是离线解密口令库（"Vault containing Ciphertext"），"Decryption" 箭头方向画反，"密文" 0xeg3d21 等含 g、l、z、o，不是合法十六进制。

**Equifax 泄露（T04 p19–p25）**：2017 年约 1.47 亿人的信息被窃；Apache Struts 的公开漏洞（CVE-2017-5638，CVE 是公开漏洞的统一编号）补丁 3 月已发布，Equifax 没打，攻击者 5 月起入侵。教训：多层防御；补丁管理（"could have been prevented if they had applied the available patch"）；特权账户管理；**令牌化**（tokenization，"replace sensitive data elements with non-sensitive placeholders"：用无意义的替代值代替卡号等数据，真实值只存在专门保护的库里）。常见的令牌库方案里替代值随机生成、与原值没有数学关系，没有可破解的密钥；用格式保留加密生成令牌的方案则有密钥。

### 6.10 应用安全三条（T05 p28–p39）

**会话 ID 放在 URL 里（p28–p29）。** **会话 ID**（session ID）是服务器发给已登录用户的标识，此后每个请求带上它，服务器据此认人（"User authentication is only at one point in time"）。写进 URL 后，转发的链接、浏览器历史、服务器日志都会把它漏出去，拿到的人就是 Alice。对策：放进标记为安全的 **cookie**（浏览器替网站保存、每次请求自动带上的一小段数据），登录后换新 ID，可绑定 TLS 会话（绑 IP 会让切换网络的手机掉线）。这是 [[L10 网络安全：威胁、攻击与防御#3.3 会话劫持：偷的是已经登录的证明|L10 3.3]] 会话劫持的一个成因。

**OWASP Top 10（p30–p33）。** **OWASP**（Open Worldwide Application Security Project，开放全球应用安全项目）是非营利组织，**Top 10** 是它定期发布的十类最关键网页应用安全风险；**ASVS**（Application Security Verification Standard，应用安全验证标准）是它的应用层安全要求。幻灯片是 **2013 版**，现行 **2025 版**：

| 序 | 2013 版（幻灯片） | 2025 版（现行） |
| --- | --- | --- |
| 1 | Injection | Broken Access Control |
| 2 | Broken Authentication and Session Management | Security Misconfiguration |
| 3 | Cross-Site Scripting (XSS) | Software Supply Chain Failures |
| 4 | Insecure Direct Object References | Cryptographic Failures |
| 5 | Security Misconfiguration | Injection |
| 6 | Sensitive Data Exposure | Insecure Design |
| 7 | Missing Function Level Access Control | Authentication Failures |
| 8 | Cross-Site Request Forgery (CSRF) | Software or Data Integrity Failures |
| 9 | Using Components with Known Vulnerabilities | Security Logging & Alerting Failures |
| 10 | Unvalidated Redirects and Forwards | Mishandling of Exceptional Conditions |

XSS（跨站脚本，把恶意脚本注入网页、在别的用户浏览器里执行）与 CSRF（跨站请求伪造，诱使已登录用户的浏览器发出攻击者构造的请求）见 [[L10 网络安全：威胁、攻击与防御#4.2 XSS 与 CSRF：方向相反的两种信任|L10 4.2]]。2013 版的 A4、A7、A8 并进了"访问控制失效"，XSS 并进了"注入"。问 Top 10 写现行版并注明年份；问"举几类"时，注入、安全配置错误两版都有，访问控制在 2013 版拆成 A4、A7。

**敏捷开发里的威胁建模（p34–p39）。** STRIDE（微软的威胁建模方法，取六类威胁的英文首字母）见 [[L1 信息安全基础#5.4 STRIDE：设计者视角的同一张图|L1 5.4]]，幻灯片多三点：每个**冲刺**（sprint，敏捷开发里一到四周的开发周期）对新功能问 "How could this new function be misused or attacked?"；**攻击者故事**（attacker story）套用**用户故事**（user story，"作为某角色，我想做某事，以便达成某目的"的一句话需求）的格式："As an [attacker] I want [action] so that [achievement]."；**误用用例**（misuse case）是**用例**（use case，用户为达成目标与系统的一串交互）的反面，写出攻击者达成目标的步骤。

### 6.11 计时攻击与改进版 DES 论文（T06、T08）

**DES 计时攻击场景（T06 p20–p34；T08）。** 计时攻击的原理在 [[L3 分组密码与 DES#8.3 计时攻击与侧信道|L3 8.3]]，查表 AES 的缓存计时在 [[L4 AES#11.2 实际部署|L4 11.2]]，RSA 的计时攻击与"恒定时间、盲化"两种修法在 [[L7 公钥密码#5.6 教科书 RSA 的三个问题|L7 5.6]]。幻灯片的场景：Eve 向一台用 DES 加密传输的服务器发构造好的请求、测响应时间，用 "correlation analysis or machine learning algorithms" 把时间差映射到密钥。这个前提偏弱：Stallings 认为 DES 本身对计时攻击相当有抵抗力，场景只在实现里有依赖数据的分支或查表时成立；经典对象是 RSA 求幂和查表 AES。

| 对策（T06 缺第 2 条，T08 p9 补上） | 评价 |
| --- | --- |
| 1 恒定时间实现 | **根本修复**：时间与密钥和数据无关 |
| 2 随机延迟 | **弱**：多测几次取平均就消掉，只加成本 |
| 3 盲化（blinding） | **公钥密码**的对策：取随机 $r$，算 $c' = c\cdot r^e$，解出 $m' = c'^d = m\,r$，再乘 $r^{-1}$ 得 $m$，运算时间与真实输入无关。分组密码防计时靠恒定时间实现；**掩码**（masking，把中间值与随机数混合）主要对付功耗分析 |
| 4 "AES, which is resistant to timing attacks" | **错**：查表 AES 恰是缓存计时的经典对象，防它靠恒定时间实现或 AES-NI |

**改进版 DES 论文（T06 p3–p19，Alhag & Mohamed 2018）**：密钥加长到 1024 位，切成 16 段 64 位，每轮一段独立子密钥，声称复杂度从 $2^{56}$ 升到 $2^{896}$。分三层看：

1. **标称**：$16\times64=1024$ 含校验位，去掉每段 8 个校验位是 $16\times56=896$；
2. **进入轮函数的**：每段还要经过 PC-2（DES 密钥编排里从 56 位选出 48 位的置换；p15 的表写明 "PC-2 使用次数 16"），每轮只有 48 位影响输出，最多 $16\times48=768$ 位，穷举空间最多 $2^{768}$；
3. **最便宜的攻击**：这正是 Biham 与 Shamir 分析过的 768 位独立子密钥 DES，**差分密码分析**（differential cryptanalysis，观察成对明文的差异怎样传到密文来推子密钥）约 $2^{61}$ 个**选择明文**（chosen plaintext，攻击者自选明文、拿到对应密文）即可攻破。

与 [[L3 分组密码与 DES#10.4 评估对 DES 的四项修改|L3 10.4]] 不矛盾：代价从穷举的 $2^{56}$ 升到约 $2^{61}$，有提升，远不是 $2^{896}$。强度取决于最便宜的攻击，不取决于密钥位数——与[[L2 古典密码与密码分析#4.1 密钥空间 26! 也救不了它|单表代换的 26!]] 同一个教训。

> [!warning] T06 p5–p6 的机密性定义错
> "Confidentiality safeguards data and information from unauthorized access, alteration, loss, or disclosure"：alteration 属完整性，loss 属可用性；机密性只管未经授权的披露（[[L1 信息安全基础#4.1 CIA 三要素|L1 4.1]]）。

### 6.12 穷举时间表与物理层密钥生成（T07）

**穷举时间（T07 p20）**：$t = 2^n / r$，这是"全部试完"；课程口径平均试一半，再除以 2（[[L2 古典密码与密码分析#2.3 暴力破解要花多少|L2 2.3]]）。两例：32 位、每秒 $10^{17}$ 次，$2^{32}/10^{17} \approx 4.29\times10^{-8}$ s $=42.9$ ns（幻灯片写 0.42 ns）；64 位、每秒 $10^{6}$ 次，$\approx 1.84\times10^{13}$ s $\approx 5.85\times10^{5}$ 年（幻灯片写 $75.03\times10^{4}$ 年）。幻灯片有三格明显算错：32 位在 $10^{17}$、$10^{18}$ 两列差 100 倍，64 位在 $10^6$ 列偏大约 28%；"够不够"的判断不受影响，128 位最快也要约 $1.08\times10^{13}$ 年。

> [!warning] T07 p20 的两处概念错误
> - **"$10^{18}$ FLOPs (quantum computer)"**（FLOPs 指每秒浮点运算次数，表里当作每秒尝试的密钥数）：量子加速来自 **Grover 算法**，把 $2^n$ 次尝试降到约 $2^{n/2}$ 次，相当于密钥长度减半，不是"每秒算得更快"。128 位密钥面对约 $2^{64}$ 量级的量子运算，所以抗量子建议用 256 位（Grover 难以并行，NIST 的后量子分级仍以 AES-128 为第 1 级基准）。$10^{18}$ 次每秒是经典超级计算机的量级；"TaihuLight"（神威·太湖之光，实测约 $9.3\times10^{16}$ 次每秒）记作 $10^{17}$ 可以接受。
> - **"Keys Rotation Time" 一列**（16、32 位每条消息一换，64 位每分钟，128 位每 15 分钟）只适用于必须在有效期内实时使用的密钥（认证、往会话里注入伪造消息）。对录下来的密文，换密钥挡不住离线穷举：16、32 位无论换多勤，每条消息都能各自被穷举。按表自己的数，64 位在 $10^{18}$ 列只要 18.4 s，每分钟一换也不够。[[L3 分组密码与 DES#8.4 密钥长度是保质期|L3 8.4]] 的"保质期"指破解时间要超过信息需要保密的时间，不是密钥有效期。

**车联网的物理层密钥生成（T07，Ribouh 等 2021）**：车与车、车与路边设施的通信（**V2X**，vehicle-to-everything）利用**信道互易性**——A 到 B 与 B 到 A 的信道在很短时间内几乎相同——双方各自测信号强度（**RSSI**，received signal strength indicator，接收信号强度指示）或**信道状态信息**（channel state information，CSI，各子载波的幅度和相位；与 6.6 的 Computer Security Institute 无关），量化、纠错、哈希后得到同一把密钥，密钥不在空中传输；离开超过约半个波长的窃听者测到的信道基本无关，幻灯片报告第三辆车的密钥与 A–B 密钥不一致率超过 50%。它相当于 [[L6 对称密码的安全使用#9.2 TRNG、PRNG、PRF|L6 9.2]] 里一个特殊的 TRNG：信道是熵源，而且双方同时得到同一份随机数。

## 速记

- 示范答案不是标准答案：逐项作答、每级给理由、前提有错先指出。Q1(a)(b)(c)、Q2(a)(c) 的单题答法在模拟卷全解。
- 威胁向量 = 来源 → 路径 → 目标；加 L、I、排序即风险登记册。$R=L\times I$（各 1–5）：$\ge15$ High，8–14 Medium，$\le7$ Low；优先级起点 $\ge20$ Critical，凭入口性、修复成本、已有控制上下调一级并写理由。进行时 L 取 5，"can" 按暴露面定。得手前起作用的控制降 L，得手后降 I。
- Case 1：无 MFA 25 > 未打补丁 20 > 共用口令 16 > 未加密 15 > 杀毒过期 9；磁盘与传输加密不保护经认证会话读出的数据。
- Case 2：机密性 High（含磁带）、完整性 Medium、可用性 Medium，投资顺序机密性 > 可用性 > 完整性；PCI DSS：卡号不可读，授权后不存 CVV；备份给可恢复性，复制给可用性。
- Case 9：钓鱼 > SQL 注入 > DoS > 搭线窃听 > 端口扫描；端口扫描是主动侦察；被动只有消息内容泄露与流量分析；SQL 注入、恶意软件不属于 Stallings 四类主动攻击；被动重预防，主动重检测与恢复。
- 选型四步：需求 → 逐个排除（给数）→ 选定（可跳出选项）→ 模式、密钥管理、完整性。Case 3：AES-GCM 加密数据，RSA 只封装密钥（2048 位 RSA-OAEP 一次最多 190 字节），DES 直接迁 AES；RSA 基于分解两个大质数之积。
- Case 4、10：凯撒 25 把，置换保留频率，单表 $2^{88.4}$ 照样被频率分析，Vigenère 是多表代换的一种；一次一密密钥与数据等量、无完整性、聊天里会耗尽，重用即 $C_1\oplus C_2=P_1\oplus P_2$；对称密钥同样要管理。
- 随机数：TRNG 播种 CSPRNG，CSPRNG 生成密钥与 IV，PRF 派生子密钥；PRF 不当随机数源是因为要秘密输入、不产生熵，与快慢无关。LCG（$m$ 已知）三个输出解出参数；BBS：$p\equiv q\equiv3 \pmod 4$，$X_i=X_{i-1}^2 \bmod n$ 取最低位，能预测下一位就能分解 $n$，慢。
- Case 5：CTR 只用加密方向，没有"Feistel 解密"；CTR 要放进 GCM；RC4 被 RFC 7465 禁于 TLS；TLS 1.3 唯一 MUST 是 AES-128-GCM。Case 8：四步缺一不可，漏了唯一非线性的 SubBytes；用 AES-NI。
- 病毒四阶段：潜伏 → 传播 → 触发 → 执行；多态改外形、变形整体重写、隐形对检测软件隐藏自身。蠕虫 logistic，$\beta=sN/\Omega$，打补丁同时压低增长率和平台。DDoS 反射型要把源地址伪造成受害者。
- 杀伤链：侦察 → 武器化 → 投递 → 利用 → 安装 → C&C → 行动/外泄；断一环即断链；侦察与 C&C 是检测窗口。
- 在线破解：锁定可被拿来锁人、挡不住口令喷洒；限速被 IP 轮换绕过；OTP 会被中继钓鱼；不定期强制改口令（SP 800-63B-4：SHALL NOT）。Equifax：Struts 补丁未打。OWASP Top 10 现行 2025 版。
- 计时攻击：恒定时间（根本）＞ 随机延迟（弱）；盲化是 RSA 的对策；查表 AES 不免疫。改进版 DES：1024 → 768 → 约 $2^{61}$ 个选择明文。
- 穷举 $t=2^n/r$（全部试完，平均再除以 2）；Grover 把 $2^n$ 降到约 $2^{n/2}$；换密钥挡不住对录下密文的离线穷举。
