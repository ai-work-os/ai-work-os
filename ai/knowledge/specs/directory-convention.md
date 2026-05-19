# ai/ 目录约定

> 2026-05-12 首版。2026-05-19 重订:并入三层上下文标准、`ai/` 内部分区、AI 工具配置真相源模型。

---

## 1. 三层上下文标准

按生命周期分,每层一个唯一的家:

| 层 | 家 | 内容 | 生命周期 |
|----|----|------|---------|
| 个人层 | `~/.ai/` | 日报 / duty / memory | 不碰,自有 `~/.ai/ops/config/directory-structure.md` 管 |
| 项目层 | `ai/`(本目录) | AI 工具配置 + 项目知识 | 长期沉淀,随仓库走 |
| 任务层 | worktree 任务根目录 | `TASK.md` / `plan.md` / `progress.md`,freestanding 不进 git | 临时,随 worktree 清理 |

**铁律**:临时状态进任务层,长期沉淀进项目层。不要把任务进度塞进 `ai/` 稀释它;也不要把规范留在临时任务区被归档埋葬。

---

## 2. ai/ 内部结构(v0)

`ai/` 装两类不同的东西,分两个区:

```
ai/
  ai.md            ← 入口导航 + 工具指令真身
  tooling/         ← AI 工具相关(让工具跑起来的配置)
      skills/        项目级 skill
      mcp.json       MCP server 统一定义
      commands/      slash command / hooks / 子 agent
  knowledge/       ← 项目知识 / 架构
      architecture/  架构
      runbooks/      运维 / 排错 SOP
      specs/         规范(含本文件)
      adr/           架构决策记录
```

- `ai/tooling/` —— "AI 工具怎么配"。真相源,见 §3。
- `ai/knowledge/` —— "项目本身的知识"。worker 读它干活,收尾往它写沉淀。

> **归位待办**(landing 阶段轻量迁移):现有 `ai/skills/` → `ai/tooling/skills/`,`ai/runbooks/` → `ai/knowledge/runbooks/`,`ai/specs/` → `ai/knowledge/specs/`。

不追求一开始铺满,空目录是合法状态,遇到再加。

---

## 3. ai/tooling/ 是 AI 工具配置的真相源

多个 AI 工具(Claude Code / Codex / Gemini)各有原生配置位置(`CLAUDE.md`、`.claude/skills/`、`.mcp.json`……)。约定:**配置只写在 `ai/tooling/` 里,工具原生位置由它派生。**

落地分两步,不一步到位:

1. 先把配置**收进 `ai/tooling/`** —— 物理归位。
2. 后补 sync 脚本,从 `ai/tooling/` 生成各工具原生格式(尤其 MCP:Claude `.mcp.json` / Codex `config.toml` / Gemini `settings.json` 三家格式不同)。能纯软链的(md)先软链。

机器本地状态(`settings.local.json`、权限 allowlist、`*.lock`)**不进 `ai/`** —— 那是本地状态不是项目配置,留 `.claude/` 原地。

---

## 4. 入口文件 + symlink 约定

每个仓库根的 3 个 AI 工具入口,全部 symlink 到 `ai/ai.md` —— 一份内容、所有工具读:

```
<repo>/
  CLAUDE.md  → ai/ai.md
  AGENTS.md  → ai/ai.md
  GEMINI.md  → ai/ai.md
  ai/ai.md                ← 真身
```

`AGENTS.md` 是跨工具事实标准,作为概念真身;物理真身是 `ai/ai.md`,三个名字都软链到它。新增工具入口(如 cursor `.cursor/rules`)照样软链进来。

---

## 5. AGENTS.md 在 nerve / nerve-tui 被 .gitignore 排除

历史原因:`nerve` / `nerve-tui` 的 `.gitignore` 各排除 `AGENTS.md`。这两个仓:`CLAUDE.md` / `GEMINI.md` 软链进 git,`AGENTS.md` 软链**不**进 git,克隆 / worktree 后需自己 `ln -s ai/ai.md AGENTS.md`。`nerve-app` 无此条目,三个都进 git。

统一时:移除 `nerve/.gitignore`、`nerve-tui/.gitignore` 各一行 + `git add AGENTS.md`。非阻塞。

---

## 6. 多仓层级

- **顶层 `ai/` 是主场。** 一个 multi-repo 项目,顶层一个 `ai/`,放跨子仓的工具配置 + 项目知识。
- **子仓 `ai/` 可选,默认不建。** 真出现"某仓特有、放顶层不合适"的东西,才给那个仓建 `ai/`。
- 子仓 `ai/` 与顶层 `ai/` 的**合并语义现在不定** —— 等第一个真实案例出现再定(YAGNI)。

---

## 7. ai/ 跟 notes/ 分工

- `ai/` = 项目使用手册(项目是什么、怎么开发、怎么排错)+ 工具配置。
- `notes/` = 任务追踪(谁在做什么、状态、决策、历史)。

不把 ai 类内容塞进 notes,不把任务追踪塞进 ai。

---

## 8. ai/ 的 git 归属(待定)

顶层 `ai-work-os/` 不是 git 仓库,`ai-work-os/ai/` 当前是普通目录、未 git 化(不能 push、重装会丢)。

候选:做成独立 git 仓库 `ai-work-os/ai`,跟 nerve / nerve-app 同级 —— 这样 `worktree-task` 能把它当多仓之一拉进任务工作区,代码仓 commit 相对软链 `AGENTS.md → ../ai/ai.md`(`ai/` 永远是兄弟目录,相对软链稳定)。**暂 parked**,先用着看顺不顺手。

---

## 9. 演进规则

卡点驱动,不要一次铺完。遇到卡点 / 重复踩坑 → 加进对应 `knowledge/runbooks/` 或 `knowledge/specs/`;跨子仓反复出现 → 升到顶层 `ai/`。空目录正常。
