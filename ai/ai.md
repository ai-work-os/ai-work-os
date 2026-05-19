# ai-work-os (super-project 级 AI 入口)

`ai-work-os` 是包含多个独立 git 子仓库的工作区:`nerve`(服务端)+ `nerve-app`(Android)+ `nerve-tui`(Rust 终端)+ `notes`(文档/任务)。

本仓库(`ai/`)是 **super-project 级 AI 上下文** —— AI 工具配置 + 跨子仓库的项目知识。它本身是一个独立 git 仓库。

---

## 定位:三层上下文

| 层 | 家 | 内容 |
|----|----|------|
| 个人层 | `~/.ai/` | 日报 / duty / memory,与项目无关 |
| **项目层** | **本仓库 `ai/`** | AI 工具配置 + 项目知识,长期沉淀 |
| 任务层 | worktree 任务根目录 | `TASK.md` / `plan.md` / `progress.md`,临时 |

铁律:临时状态进任务层(`notes/` 或 worktree 根),长期沉淀进 `ai/`。详见 `knowledge/specs/directory-convention.md`。

---

## 入口导航

| `ai/` 内 | 内容 |
|---|---|
| `ai.md` | 这个文件,super-project 级入口 |
| `tooling/` | AI 工具配置 —— `skills/` · `mcp.json` · `commands/`。真相源,工具原生位置由它派生 |
| `knowledge/` | 项目知识 —— `architecture/` · `runbooks/` · `specs/` · `adr/` |

| 子仓库 ai/ | 内容 |
|---|---|
| `nerve/ai/` | nerve 服务端(可选,真有仓特有内容才建) |
| `nerve-app/ai/` | Android 客户端 |
| `nerve-tui/ai/` | Rust TUI |

| 其他位置 | 内容 |
|---|---|
| `notes/` | 任务追踪(`tasks/<topic>/`, archive)— 跟 `ai/` 分开,不混 |
| 顶层 `AGENTS.md` / `CLAUDE.md` | super-project 级强约束(worktree 流程、TDD、协作角色)|

---

## 现有内容

| 主题 | 文件 |
|---|---|
| ai/ 目录约定(三层标准 + 内部分区 + 真相源模型) | `knowledge/specs/directory-convention.md` |
| 远程开发流程(手机发起 → home 隔离 worktree 执行) | `knowledge/specs/remote-dev-flow.md` |
| home server 部署 / 运维 | `knowledge/runbooks/home-deploy.md` |
| nerve-server 管理脚本(服务/构建/发版/部署) | `tooling/skills/nerve-server.md` |

(其他遇到再加,空目录是合法状态)

---

## 演进方式

按"遇到卡点就加一笔"演进,不强求一次到位:

- 一次性卡到 / 重复踩 → 加进 `knowledge/runbooks/` 或 `knowledge/specs/`
- 跨子仓库的反复出现 → 升到本仓库 `ai/`
- AI 工具配置(skill / mcp / 行为)→ 进 `tooling/`,作真相源
