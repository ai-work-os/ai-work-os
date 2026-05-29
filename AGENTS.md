# ai-work-os — super-project AI 入口

> **如果当前目录或上级目录有 `TASK.md`,那是任务卡,先读它再继续。**
>
> **运维相关动作前必读 `ai/context/playbook.md`** —— 启停/构建/测试 nerve、改 systemd / 端口、Android 发版、home 部署。配置和真实服务高度耦合,凭直觉跑命令容易踩坑。
>
> **涉及路径、remote、部署、运维对象时先识别当前环境** —— 执行 `uname -s`、`hostname`、`pwd`;在 home 本机不要再 `ssh home`,Mac 上才把 home 当远端。

`ai-work-os` 是 monorepo 工作区(根目录 `~/work/ai-work-os/`),它本身是一个 git 仓库,用 `.gitignore` 把内嵌的代码子仓库(`nerve/` `nerve-app/` `nerve-tui/` `nerve-android/`)忽略掉。

| 目录 / 文件 | 是否进根 git | 内容 |
|---|---|---|
| `AGENTS.md` | ✅ | **本文件,真身**。super-project 级 AI 入口,行业新兴标准(Codex 等读 AGENTS.md)|
| `CLAUDE.md` | ✅(软链 → AGENTS.md) | Claude Code 入口 |
| `ai/` | ✅ | 项目知识 + AI 编码工具配置(skill / context / 工具脚本)|
| `nerve/` | ❌(自己的 git) | nerve 服务端(Node.js / TypeScript) |
| `nerve-app/` | ❌(自己的 git) | Android 客户端(Kotlin) |
| `nerve-tui/` | ❌(自己的 git) | 终端客户端(Rust) |

## 为什么这样组织

- **多 AI 工具兼容**:`AGENTS.md` 真身一份,`CLAUDE.md` 软链过来,未来要加 `.cursorrules` / `GEMINI.md` 等同样办法
- **嵌套 git 模式**:根仓库管 super-project 级配置 + 文档,子代码仓库各自独立维护 history,不互相污染。根 `git status` 看不到子仓的脏状态(`.gitignore` 屏蔽了)
- **跨机器同步**:`git clone <根仓库>` + 各子仓 `git clone`,完整 onboarding

各子仓库内若有自己的 `ai/` 目录或 `CLAUDE.md` 软链,是该仓库本地的事,与本仓库无关。

---

## 定位:三层上下文

| 层 | 家 | 内容 | 生命周期 |
|----|----|------|---------|
| 个人层 | `~/.ai/` | 日报 / duty / memory | 不碰,自有 `~/.ai/ops/config/directory-structure.md` 管 |
| **项目层** | **根仓库 `ai-work-os/`**(本文件 + `ai/` 子目录) | super-project 级 AI 配置 + 项目知识 | 长期沉淀,随根仓库走 |
| 任务层 | Workspace 任务根目录 | `TASK.md` / `plan.md` / `progress.md`,freestanding 不进 git | 临时,随 Workspace 清理 |

**铁律**:临时状态进任务层(Workspace 根),长期沉淀进项目层(根仓库)。不要把任务进度塞进根仓库稀释它;也不要把规范留在临时任务区被归档埋葬。

---

## 入口导航

**path 全部相对 super-project 根 `~/work/ai-work-os/`**。

| 文件 / 目录 | 内容 |
|---|---|
| `AGENTS.md` / `CLAUDE.md` | 本文件(`CLAUDE.md` 是软链)。super-project 级 AI 入口 |
| `ai/ai-coding/` | AI 编码工具配置真身(skill / 工具 / 平台配置)。软链给 `~/.claude` `~/.codex`。**新开发任务用 `start-task` skill,按当前 host 自动选 Mac/home 配置。** 详见 `ai/ai-coding/README.md`。 |
| `ai/context/architecture.md` | 架构地图:子仓库结构、nerve 核心概念、需求入口 |
| `ai/context/playbook.md` | 操作手册:跑/构建/测试/发版/home 运维 / scene 维护 |
| `ai/context/conventions.md` | 稳定约定 + 常见坑 |
| `ai/context/decisions/` | ADR — 设计决定的"为什么"(读它免得撕重) |

---

## 现有内容速查

| 主题 | 文件 |
|---|---|
| 架构地图(子仓库、nerve 核心概念、需求入口地图) | `ai/context/architecture.md` |
| 操作手册(跑/构建/测试/发版/home 运维) | `ai/context/playbook.md` |
| 稳定约定 + 常见坑 | `ai/context/conventions.md` |
| 远程开发流程(Mac + home 同构) | `ai/ai-coding/remote-dev-flow.md` |
| 远程开发 playbook(dispatcher / worker 怎么做) | `ai/ai-coding/skills/remote-dev.md` |
| start-task skill(任务环境一站式创建) | `ai/ai-coding/skills/start-task/SKILL.md` |
| worktree-task 工具 + 平台配置 | `ai/ai-coding/worktree-task/` · `ai/ai-coding/dev-project.json` · `ai/ai-coding/dev-project.mac.json` |
| dispatcher 角色 prompt(home 常驻 agent) | `ai/ai-coding/dispatcher-prompt.md` |
| nerve-server 管理脚本(服务/构建/发版/部署) | `ai/ai-coding/skills/nerve-server.md` |

(其他遇到再加,空目录是合法状态)

---

## 演进方式

按"遇到卡点就加一笔"演进,不强求一次到位:

- 一次性卡到 / 重复踩 → 更新进 `ai/context/` 对应文件
- 跨子仓库的反复出现 → 升到根仓库(`ai/` 子目录或本文件)
- AI 工具配置(skill / mcp / 行为)→ 进 `ai/ai-coding/`,作真相源
- **task 完成、产生固有知识 → 更新进 `ai/context/` 对应文件**
