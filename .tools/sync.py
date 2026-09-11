#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
大四上课程包 → GitHub 同步工具

设计前提：仓库不是给 GitHub 网页读的，而是「整包下载后丢进 Obsidian 仓库使用」的课程包。
所以本脚本不做任何内容改写（不转 [[双链]]、不转 callout、不改图片路径），只做四件事：

    筛选 → 复制 → 校验 → 提交推送

用法：
    python3 .tools/sync.py              完整同步并推送
    python3 .tools/sync.py --dry-run    只打印会做什么，不写盘、不提交
    python3 .tools/sync.py --no-push    同步 + 提交，但不推送
    python3 .tools/sync.py --check-only 只对仓库现有内容跑校验
    python3 .tools/sync.py --self-test  用故意构造的坏样本验证校验器真的能报错
    python3 .tools/sync.py --force      校验报 ERROR 时仍继续（慎用）

同一份脚本在两种环境下都能跑：Cowork 设备端 Linux VM（路径为 ~/mnt/...）
与 macOS 本机（路径为 /Users/alan/...）；启动时自动探测。
"""

from __future__ import annotations

import argparse
import hashlib
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.parse
from pathlib import Path

# ══════════════════════════ 一、配置 ══════════════════════════

COURSES = ["RTCS", "控制", "IS"]

VAULT_CANDIDATES = [
    "~/mnt/大四上",
    "/Users/alan/Library/Mobile Documents/iCloud~md~obsidian/Documents/"
    "可的十年之河/🗓️ Projects · 项目/📦 Curriculum · 课程/大四上",
]
SCHOOL_CANDIDATES = [
    "~/mnt/大学文件",
    "/Users/alan/Library/Mobile Documents/com~apple~CloudDocs/大学文件",
]
REPO_CANDIDATES = [
    "~/mnt/Fourth-year1stSemester",
    "/Users/alan/Downloads/Fourth-year1stSemester",
]

REMOTE_URL = "https://github.com/AlanCommitK/Fourth-year1stSemester.git"
GIT_USER_NAME = "AlanCommitK"
GIT_USER_EMAIL = "170943770+AlanCommitK@users.noreply.github.com"
BRANCH = "main"

# 任何一层路径叫这些名字就整棵跳过
# 「报告」：交给校方评分的个人实验报告一律不发布——原文被同学逐字抄走会构成
# plagiarism，风险由报告作者承担。代码与配图仍然发布（它们是工具性的）。
EXCLUDE_DIR_NAMES = {
    "_private", "_to_delete", "报告", "__pycache__", "node_modules",
    ".obsidian", ".trash", ".smart-env", ".git", ".tools",
}
EXCLUDE_FILE_NAMES = {".DS_Store", "desktop.ini", "Thumbs.db"}

ASSET_EXTS = {
    ".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg", ".bmp",
    ".pdf", ".mp4", ".mov", ".mp3", ".wav", ".webm",
}
# Obsidian 侧只发布这些类型；交付物与真题侧不限类型（那是我们自己的产出）
VAULT_EXTS = {".md", ".html"} | ASSET_EXTS

WARN_FILE_MB = 25    # GitHub 超过 50MB 会警告
BLOCK_FILE_MB = 90   # 超过 100MB 直接拒收

# 个人信息扫描：只放高精度模式，命中即 ERROR（可用 --force 强推）
PERSONAL_PATTERNS = [
    ("手机号", r"(?<!\d)1[3-9]\d{9}(?!\d)"),
    ("身份证号", r"(?<!\d)\d{17}[\dXx](?![\dXx])"),
    ("邮箱", r"[\w.+-]+@[\w-]+\.[\w.-]{2,}"),
    ("学号", r"(?<!\d)20\d{9,10}(?!\d)"),
]
ALLOW_PATTERNS = [
    r"@users\.noreply\.github\.com",
    r"@example\.(com|org|net)",
]
# 需要屏蔽的真实姓名，按需填入，例如 ["张三"]。留空表示不查姓名。
PERSONAL_NAMES: list[str] = []

# ══════════════════════════ 二、路径与规则 ══════════════════════════


class Rule:
    """一条同步规则：把 src 子树按 accept 过滤后镜像到 dst。"""

    def __init__(self, name, src, dst, accept, exts=None):
        self.name = name
        self.src = src
        self.dst = dst
        self.accept = accept       # (相对路径 Path) -> bool
        self.exts = exts           # None 表示不限扩展名


def resolve_root(candidates, label, required=True):
    for c in candidates:
        p = Path(c).expanduser()
        if p.is_dir():
            return p
    if required:
        sys.exit(f"❌ 找不到{label}，试过：\n  " + "\n  ".join(candidates))
    return None


def build_rules(vault, school, repo):
    rules = []
    for c in COURSES:
        if vault is not None:
            rules.append(Rule(
                name=f"{c} · Obsidian 笔记",
                src=vault / c,
                dst=repo / c,
                accept=lambda rel: True,
                exts=VAULT_EXTS,
            ))
        if school is not None:
            rules.append(Rule(
                name=f"{c} · 实验交付物",
                src=school / c / "实验",
                dst=repo / c / "实验" / "交付物",
                # 只收子目录里的东西。直接躺在「实验/」根下的是校方发的实验手册，不发布。
                accept=lambda rel: len(rel.parts) > 1,
            ))
            rules.append(Rule(
                name=f"{c} · 往届真题",
                src=school / c / "试卷",
                dst=repo / c / "资料" / "真题",
                accept=lambda rel: True,
            ))
    return rules


# ══════════════════════════ 三、筛选与复制 ══════════════════════════

FM_RE = re.compile(r"\A---\r?\n(.*?)\r?\n---\r?\n", re.S)
SHARE_RE = re.compile(r"^share:\s*(\S+)", re.M)
PRIVATE_TAG_RE = re.compile(r"(?<![\w#])#私人(?![\w-])")


def is_private_note(text: str) -> bool:
    """frontmatter 里 share: false，或正文带 #私人 标签的笔记不发布。"""
    m = FM_RE.match(text)
    if m:
        s = SHARE_RE.search(m.group(1))
        if s and s.group(1).strip().strip('"\'').lower() in {"false", "no", "0"}:
            return True
    return bool(PRIVATE_TAG_RE.search(text))


def read_text(p: Path) -> str:
    return p.read_text(encoding="utf-8", errors="replace")


def file_hash(p: Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def collect(rule: Rule):
    """返回 {目标路径: 源路径}，以及被 share:false / #私人 挡掉的清单。"""
    plan, skipped = {}, []
    if not rule.src.is_dir():
        return plan, skipped
    for p in sorted(rule.src.rglob("*")):
        if not p.is_file():
            continue
        rel = p.relative_to(rule.src)
        if any(part.startswith(".") for part in rel.parts):
            continue
        if any(part in EXCLUDE_DIR_NAMES for part in rel.parts):
            continue
        if p.name in EXCLUDE_FILE_NAMES:
            continue
        if rule.exts is not None and p.suffix.lower() not in rule.exts:
            continue
        if not rule.accept(rel):
            continue
        if p.suffix.lower() == ".md":
            try:
                if is_private_note(read_text(p)):
                    skipped.append(p)
                    continue
            except OSError:
                skipped.append(p)
                continue
        plan[(rule.dst / rel).resolve()] = p
    return plan, skipped


def apply_plan(plan, dry_run):
    added, updated = [], []
    for dst, src in sorted(plan.items()):
        if dst.exists() and file_hash(dst) == file_hash(src):
            continue
        (added if not dst.exists() else updated).append(dst)
        if not dry_run:
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
    return added, updated


def prune(managed_roots, keep, dry_run):
    """删掉受管目录下、本次没有产出的文件——源里删了的东西也要从仓库消失。"""
    removed = []
    for root in managed_roots:
        if not root.is_dir():
            continue
        for p in sorted(root.rglob("*")):
            if p.is_file() and p.resolve() not in keep:
                removed.append(p)
                if not dry_run:
                    p.unlink()
    if not dry_run:
        for root in managed_roots:
            if root.is_dir():
                remove_empty_dirs(root)
    return removed


def remove_empty_dirs(root: Path):
    for p in sorted(root.rglob("*"), key=lambda x: len(x.parts), reverse=True):
        if p.is_dir() and not any(p.iterdir()):
            p.rmdir()


# ══════════════════════════ 四、校验 ══════════════════════════

EMBED_RE = re.compile(r"!\[\[([^\[\]\n]+?)\]\]")
WIKI_RE = re.compile(r"(?<!!)\[\[([^\[\]\n]+?)\]\]")
MDLINK_RE = re.compile(r"!?\[[^\]\n]*\]\(([^)\s]+)\)")
FENCE_RE = re.compile(r"^```.*?^```", re.S | re.M)
INLINE_CODE_RE = re.compile(r"`[^`\n]*`")


def strip_code(text: str) -> str:
    """挖掉代码块，但保留行数，这样报出的行号仍然对得上原文。"""
    text = FENCE_RE.sub(lambda m: "\n" * m.group(0).count("\n"), text)
    return INLINE_CODE_RE.sub("", text)


def build_index(published):
    notes, assets = {}, {}
    for p in published:
        if p.suffix.lower() == ".md":
            notes.setdefault(p.stem.lower(), []).append(p)
        else:
            assets.setdefault(p.name.lower(), []).append(p)
    return notes, assets


def check_links(published):
    """附件闭包 + 双链可达性。返回 [(级别, 文件, 行号, 说明)]。"""
    problems = []
    notes, assets = build_index(published)
    fileset = {p.resolve() for p in published}
    for p in sorted(published):
        if p.suffix.lower() != ".md":
            continue
        for lineno, line in enumerate(strip_code(read_text(p)).splitlines(), 1):
            for m in EMBED_RE.finditer(line):
                target = m.group(1).split("|")[0].split("#")[0].strip()
                if not target:
                    continue
                base = target.split("/")[-1]
                if Path(base).suffix.lower() in ASSET_EXTS:
                    if base.lower() not in assets:
                        problems.append(("ERROR", p, lineno,
                                         f"嵌入的附件不在发布包内：![[{target}]]"))
                elif base.lower().removesuffix(".md") not in notes:
                    problems.append(("WARN", p, lineno,
                                     f"嵌入的笔记不在发布包内：![[{target}]]"))
            for m in WIKI_RE.finditer(line):
                target = m.group(1).split("|")[0].split("#")[0].strip()
                if not target:
                    continue  # [[#本文小节]]，同文件锚点
                base = target.split("/")[-1].lower().removesuffix(".md")
                if base not in notes and base not in {
                        k.removesuffix(".md") for k in assets}:
                    problems.append(("WARN", p, lineno,
                                     f"双链指向发布包之外：[[{target}]]"))
            for m in MDLINK_RE.finditer(line):
                target = m.group(1)
                if re.match(r"^(https?:|mailto:|obsidian:|#)", target):
                    continue
                rel = urllib.parse.unquote(target.split("#")[0])
                if not rel:
                    continue
                dest = (p.parent / rel).resolve()
                if dest not in fileset and not dest.is_dir():
                    problems.append(("ERROR", p, lineno,
                                     f"相对链接指向不存在的文件：]({target})"))
    return problems


def check_personal(published):
    problems = []
    pats = [(n, re.compile(r)) for n, r in PERSONAL_PATTERNS]
    allow = [re.compile(r) for r in ALLOW_PATTERNS]
    for p in sorted(published):
        if p.suffix.lower() not in {".md", ".html"}:
            continue
        for lineno, line in enumerate(read_text(p).splitlines(), 1):
            for name, rx in pats:
                for m in rx.finditer(line):
                    hit = m.group(0)
                    if any(a.search(hit) for a in allow):
                        continue
                    problems.append(("ERROR", p, lineno, f"疑似{name}：{hit}"))
            for nm in PERSONAL_NAMES:
                if nm and nm in line:
                    problems.append(("ERROR", p, lineno, f"出现真实姓名：{nm}"))
    return problems


def check_sizes(published):
    problems = []
    for p in sorted(published):
        mb = p.stat().st_size / 1024 / 1024
        if mb >= BLOCK_FILE_MB:
            problems.append(("ERROR", p, 0, f"文件 {mb:.1f} MB，超过 GitHub 上限"))
        elif mb >= WARN_FILE_MB:
            problems.append(("WARN", p, 0, f"文件 {mb:.1f} MB，偏大"))
    return problems


def report(problems, repo):
    errs = [x for x in problems if x[0] == "ERROR"]
    warns = [x for x in problems if x[0] == "WARN"]
    for level, items in (("ERROR", errs), ("WARN", warns)):
        if not items:
            continue
        mark = "❌" if level == "ERROR" else "⚠️ "
        print(f"\n{mark} {level} × {len(items)}")
        for _, p, lineno, msg in items:
            try:
                shown = p.relative_to(repo)
            except ValueError:
                shown = p
            loc = f":{lineno}" if lineno else ""
            print(f"   {shown}{loc}  {msg}")
    return len(errs), len(warns)


# ══════════════════════════ 五、Git ══════════════════════════


def git(repo, *args, check=True):
    # core.quotepath=false：否则含中文的路径会被 git 转义成 "\350\265\204..."，
    # 导致提交信息里按课程归类失败
    r = subprocess.run(["git", "-C", str(repo), "-c", "core.quotepath=false", *args],
                       capture_output=True, text=True)
    if check and r.returncode != 0:
        raise SystemExit(f"❌ git {' '.join(args)} 失败：\n{r.stdout}{r.stderr}")
    return r


def find_credentials(repo: Path):
    """凭据优先放仓库根的 .credentials（已在 .gitignore 里，且不会随 .git 被删掉一起消失），
    其次兼容旧位置 .git/credentials。文件内容一行：https://用户名:令牌@github.com"""
    for p in (repo / ".credentials", repo / ".git" / "credentials"):
        if p.exists():
            return p
    return None


def ensure_git_config(repo: Path):
    git(repo, "config", "user.name", GIT_USER_NAME)
    git(repo, "config", "user.email", GIT_USER_EMAIL)
    r = git(repo, "remote", "get-url", "origin", check=False)
    if r.returncode != 0:
        git(repo, "remote", "add", "origin", REMOTE_URL)
    elif r.stdout.strip() != REMOTE_URL:
        git(repo, "remote", "set-url", "origin", REMOTE_URL)
    cred = find_credentials(repo)
    if cred is not None:
        cred.chmod(0o600)
        git(repo, "config", "credential.helper", f"store --file={cred}")
        return True
    return False


def build_commit_message(repo):
    out = git(repo, "diff", "--cached", "--name-status").stdout
    buckets = {"新增": [], "修改": [], "删除": [], "重命名": []}
    for line in out.splitlines():
        if not line.strip():
            continue
        parts = line.split("\t")
        code = parts[0][0]
        if code == "A":
            buckets["新增"].append(parts[1])
        elif code == "M":
            buckets["修改"].append(parts[1])
        elif code == "D":
            buckets["删除"].append(parts[1])
        elif code == "R":
            buckets["重命名"].append(f"{parts[1]} → {parts[2]}")
        else:
            buckets["修改"].append(parts[-1])

    per_course = {}
    for kind, files in buckets.items():
        for f in files:
            top = f.split("/")[0]
            course = top if top in COURSES else "仓库"
            per_course.setdefault(course, {}).setdefault(kind, 0)
            per_course[course][kind] += 1
    chunks = []
    for course in COURSES + ["仓库"]:
        if course in per_course:
            inner = "、".join(f"{k} {v}" for k, v in per_course[course].items())
            chunks.append(f"{course} {inner}")
    subject = "同步：" + "；".join(chunks) if chunks else "同步"

    body = []
    for kind, files in buckets.items():
        if files:
            body.append(kind + "：")
            body += [f"  {f}" for f in sorted(files)]
    return subject + ("\n\n" + "\n".join(body) if body else "")


def push(repo):
    r = git(repo, "rev-parse", "--abbrev-ref", f"{BRANCH}@{{upstream}}", check=False)
    if r.returncode != 0:
        git(repo, "push", "-u", "origin", BRANCH)
    else:
        git(repo, "push")


# ══════════════════════════ 六、自测 ══════════════════════════


def self_test():
    """用故意构造的坏样本验证校验器真的能报错——「没查到问题」≠「没有问题」。"""
    results = []
    with tempfile.TemporaryDirectory() as td:
        root = Path(td)
        (root / "附件").mkdir()
        (root / "附件" / "有的图.png").write_bytes(b"x")
        good = root / "好笔记.md"
        good.write_text("看图 ![[有的图.png]]，另见 [[另一篇]]。\n", encoding="utf-8")
        other = root / "另一篇.md"
        other.write_text("正文。\n", encoding="utf-8")
        miss_asset = root / "缺图.md"
        miss_asset.write_text("![[根本不存在的图.png]]\n", encoding="utf-8")
        dead_link = root / "断链.md"
        dead_link.write_text("见 [[根本没有这篇笔记]]\n", encoding="utf-8")
        privacy = root / "隐私.md"
        privacy.write_text("联系方式 13800138000\n", encoding="utf-8")
        code_ok = root / "代码里的假阳性.md"
        code_ok.write_text("```\n[[不该被当成断链]]\n```\n", encoding="utf-8")

        published = [good, other, miss_asset, dead_link, privacy, code_ok,
                     root / "附件" / "有的图.png"]
        links = check_links(published)
        pers = check_personal(published)

        def has(problems, path, level, kw):
            return any(x[0] == level and x[1] == path and kw in x[3] for x in problems)

        results.append(("缺失附件应报 ERROR", has(links, miss_asset, "ERROR", "附件")))
        results.append(("断链应报 WARN", has(links, dead_link, "WARN", "双链")))
        results.append(("手机号应报 ERROR", has(pers, privacy, "ERROR", "手机号")))
        results.append(("正常笔记不应报错", not any(x[1] == good for x in links + pers)))
        results.append(("代码块内不应误报", not any(x[1] == code_ok for x in links)))

        wl = root / "白名单.md"
        wl.write_text("提交邮箱 170943770+AlanCommitK@users.noreply.github.com\n",
                      encoding="utf-8")
        results.append(("白名单邮箱不应报错",
                        not any(x[1] == wl for x in check_personal([wl]))))

    print("── 校验器自测 ──")
    ok = True
    for name, passed in results:
        print(f"  {'✅' if passed else '❌'} {name}")
        ok &= passed
    print("── 自测" + ("通过" if ok else "未通过") + " ──")
    return 0 if ok else 1


# ══════════════════════════ 七、主流程 ══════════════════════════


def main():
    ap = argparse.ArgumentParser(description="大四上课程包 → GitHub 同步")
    ap.add_argument("--dry-run", action="store_true", help="只打印，不写盘不提交")
    ap.add_argument("--no-push", action="store_true", help="提交但不推送")
    ap.add_argument("--check-only", action="store_true", help="只对仓库现有内容跑校验")
    ap.add_argument("--self-test", action="store_true", help="验证校验器本身是否有效")
    ap.add_argument("--force", action="store_true", help="校验有 ERROR 时仍继续")
    args = ap.parse_args()

    if args.self_test:
        return self_test()

    repo = resolve_root(REPO_CANDIDATES, "本地仓库")
    vault = resolve_root(VAULT_CANDIDATES, "Obsidian 大四上", required=False)
    school = resolve_root(SCHOOL_CANDIDATES, "大学文件", required=False)
    print(f"仓库    {repo}")
    print(f"笔记源  {vault or '（未找到，跳过）'}")
    print(f"资料源  {school or '（未找到，跳过）'}")

    managed_roots = [repo / c for c in COURSES]

    if not args.check_only:
        plan, skipped = {}, []
        for rule in build_rules(vault, school, repo):
            p, s = collect(rule)
            plan.update(p)
            skipped += s
            if p:
                print(f"  {rule.name}: {len(p)} 个文件")
        added, updated = apply_plan(plan, args.dry_run)
        removed = prune(managed_roots, set(plan.keys()), args.dry_run)
        print(f"\n同步{'（预演）' if args.dry_run else ''}："
              f"新增 {len(added)}、更新 {len(updated)}、删除 {len(removed)}")
        for label, items in (("新增", added), ("更新", updated), ("删除", removed)):
            for p in items:
                print(f"   {label} {p.relative_to(repo)}")
        if skipped:
            print(f"\n因 share: false / #私人 未发布：{len(skipped)} 篇")
            for p in skipped:
                print(f"   跳过 {p}")

    published = [p for root in managed_roots if root.is_dir()
                 for p in sorted(root.rglob("*")) if p.is_file()]
    print(f"\n发布包内共 {len(published)} 个文件，开始校验……")
    problems = check_links(published) + check_personal(published) + check_sizes(published)
    n_err, n_warn = report(problems, repo)
    if not problems:
        print("✅ 校验全过")

    if args.check_only or args.dry_run:
        return 1 if n_err else 0
    if n_err and not args.force:
        print(f"\n❌ 有 {n_err} 个 ERROR，已中止提交。修掉，或确认无误后加 --force。")
        return 2

    ensure_git_config(repo)
    git(repo, "add", "-A")
    if not git(repo, "diff", "--cached", "--name-only").stdout.strip():
        print("\n没有变化，无需提交。")
        return 0
    msg = build_commit_message(repo)
    git(repo, "commit", "-m", msg)
    print(f"\n已提交：{msg.splitlines()[0]}")

    if args.no_push:
        print("（--no-push，未推送）")
        return 0
    if find_credentials(repo) is None:
        print("\n⚠️  没找到凭据文件，无法推送。把 PAT 按"
              " https://用户名:令牌@github.com 一行写进仓库根的 .credentials 后重跑。")
        return 3
    push(repo)
    print("✅ 已推送到 " + REMOTE_URL)
    return 0


if __name__ == "__main__":
    sys.exit(main())
