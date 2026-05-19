# ai-work-os (super-project 级 AI 入口)

`ai-work-os` 是包含多个独立 git 子仓库的工作区:`nerve`(服务端)+ `nerve-app`(Android)+ `nerve-tui`(Rust 终端)+ `notes`(文档/任务)。

本仓库(`ai/`)是 **super-project 级 AI 上下文** —— AI 工具配置 + 跨子仓库的项目知识。它本身是一个独立 git 仓库。

---

## 定位:三层上下文

| 层 | 家 | 内容 | 生命周期 |
|----|----|------|---------|
| 个人层 | `~/.ai/` | 日报 / duty / memory | 不碰,自有 `~/.ai/ops/config/directory-structure.md` 管 |
| **项目层** | **本仓库 `ai/`** | AI 工具配置 + 项目知识 | 长期沉淀,随仓库走 |
| 任务层 | worktree 任务根目录 | `TASK.md` / `plan.md` / `progress.md`,freestanding 不进 git | 临时,随 worktree 清理 |

**铁律**:临时状态进任务层(`notes/` 或 worktree 根),长期沉淀进项目层(`ai/`)。不要把任务进度塞进 `ai/` 稀释它;也不要把规范留在临时任务区被归档埋葬。

**`ai/` 与 `notes/` 分工**:`ai/` = 项目使用手册(项目是什么、怎么开发、怎么排错)+ 工具配置;`notes/` = 任务追踪(谁在做什么、状态、决策、历史)。不互混。

---

## 入口导航

**worker 进 worktree 干活,先读 `context/`。**

| `ai/` 内 | 内容 |
|---|---|
| `ai.md` | 这个文件,super-project 级入口 |
| `ai-coding/` | AI 编码工具配置 —— `skills/` · `worktree-task/` · `dev-project.json` 等;`mcp.json`/`commands/` 待第 3 件落地 |
| `context/architecture.md` | ai-work-os 架构地图:子仓库、核心概念、需求入口 |
| `context/playbook.md` | 操作手册:跑/构建/测试/发版/home 运维 |
| `context/conventions.md` | 稳定约定 + 常见坑 |
| `context/task-index.md` | 历史任务索引(notes/tasks/ 归类) |

| 子仓库 ai/ | 内容 |
|---|---|
| `nerve/ai/` | nerve 服务端(可选,真有仓特有内容才建) |
| `nerve-app/ai/` | Android 客户端 |
| `nerve-tui/ai/` | Rust TUI |

| 其他位置 | 内容 |
|---|---|
| `notes/` | 任务追踪(`tasks/<topic>/`, archive)— 跟 `ai/` 分开,不混 |

---

## 现有内容

| 主题 | 文件 |
|---|---|
| 架构地图(子仓库、nerve 核心概念、需求入口地图) | `context/architecture.md` |
| 操作手册(跑/构建/测试/发版/home 运维) | `context/playbook.md` |
| 稳定约定 + 常见坑 | `context/conventions.md` |
| 历史任务索引 | `context/task-index.md` |
| 远程开发流程(设计) | `ai-coding/remote-dev-flow.md` |
| 远程开发 playbook(dispatcher / worker 怎么做) | `ai-coding/skills/remote-dev.md` |
| worktree-task 工具 + ai-work-os 项目配置 | `ai-coding/worktree-task/` · `ai-coding/dev-project.json` |
| dispatcher 角色 prompt | `ai-coding/dispatcher-prompt.md` |
| nerve-server 管理脚本(服务/构建/发版/部署) | `ai-coding/skills/nerve-server.md` |

(其他遇到再加,空目录是合法状态)

---

## 演进方式

按"遇到卡点就加一笔"演进,不强求一次到位:

- 一次性卡到 / 重复踩 → 更新进 `context/` 对应文件
- 跨子仓库的反复出现 → 升到本仓库 `ai/`
- AI 工具配置(skill / mcp / 行为)→ 进 `ai-coding/`,作真相源
- **task 完成、产生固有知识 → 更新进 `context/` 对应文件**
