# ADR 001 — polyrepo + meta-repo + 软链

**日期**:2026-05-26
**状态**:已落地

## 背景

ai-work-os 包含 4 个独立子项目(`nerve` 服务端、`nerve-app` Android、`nerve-tui` Rust、`ai` 项目级配置),且要兼容多个 AI 工具(Claude Code 读 `CLAUDE.md`、Codex 读 `AGENTS.md`、未来可能加 Cursor / Gemini)。需要决定整体仓库布局。

## 决定

**根目录 `~/work/ai-work-os/` 本身是一个 git 仓库**(`ai-work-os/ai-work-os`),`.gitignore` 屏蔽内嵌的代码子仓库(`nerve/` `nerve-app/` `nerve-tui/`)。`AGENTS.md` 是真身,`CLAUDE.md` 软链 → `AGENTS.md`。`ai/` 是根仓库的子目录(不再是独立 git)。

## 为什么

- **多 AI 工具兼容**:单一真身 + 多软链,加一个工具只要加一个软链,改一次内容所有工具受益
- **代码仓独立性**:子仓库各自 git,自己的 history / push / hook,不被根仓库污染
- **跨机器同步**:`git clone` 根仓库 + 各子仓 `git clone`,onboarding ≤ 3 步
- **不需要 submodule**:submodule 的 HEAD 漂移、init 体验差,polyrepo + .gitignore 干净

## 拒绝的替代方案

| 方案 | 拒绝理由 |
|---|---|
| 真 monorepo(合并所有子仓) | release / 权限 / history 重洗代价大 |
| git submodule | HEAD 漂移、init/update 体验差 |
| dotfiles 风格(CLAUDE.md 放 `~/.dotfiles/`) | 项目知识跟个人配置混淆,团队无法共享 |
| meta-repo 嵌套(原 `ai/` 子仓库版本) | 路径有歧义("ai/ai.md" 还是 "ai.md"?),软链来回指 |

## 代价

- 嵌套 git(根 + 子仓库)对部分 GUI 工具不友好(命令行 git 没问题)
- 加新机器需要建一批软链(`worktree-task` / 各 skill / `~/.local/bin/`),要么手动要么写 setup 脚本
- AGENTS.md / CLAUDE.md / GEMINI.md 软链关系是隐性约定,新人需要看 AGENTS.md 顶部说明才理解

## 关联

- 实施:commit `5106cca`(meta-repo 提升)及前后
- AGENTS.md 顶部"为什么这样组织"段
