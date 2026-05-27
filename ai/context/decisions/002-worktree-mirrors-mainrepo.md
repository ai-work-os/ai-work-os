# ADR 002 — 任务 worktree 跟主仓库镜像 + 全切

**日期**:2026-05-26
**状态**:已落地

## 背景

每个开发任务在 `<worktree_root>/<task-id>/` 切出隔离 worktree。需要决定:
1. worktree 怎么布局(根仓库塞哪里?子代码仓嵌套结构?)
2. 跑 `worktree-task create` 时切哪些 repo(让 dispatcher 判定还是全切?)

## 决定

**worktree 结构跟主仓库 100% 镜像**:

```
<worktree_root>/<task-id>/      ← 根仓库 worktree 占顶层
├── AGENTS.md / CLAUDE.md       ← AI 工具自动加载
├── ai/                         ← 项目知识
├── TASK.md                     ← 任务卡(AGENTS.md 顶部引导自动读)
├── nerve/                      ← 三个代码仓 worktree(分支 <type>/<id>)
├── nerve-app/                  (根 .gitignore 屏蔽,嵌套位置合法)
└── nerve-tui/
```

**全切**:`worktree-task create` 不传 `--repos` 时,默认 config 里所有 repos 都切。

## 为什么

**为什么镜像主仓库结构**:
- worker cwd 在 `<task-id>/<主代码repo>/`,跟主仓库 `~/work/ai-work-os/<repo>/` 相对位置完全一致 — 所有路径 (`../AGENTS.md` `../ai/...`) 直接复用,**无歧义**
- AI 工具(Claude Code / Codex)启动时向上递归找 `CLAUDE.md` / `AGENTS.md`,自动加载顶层根仓库的入口,**零额外配置**
- worktree 是完整的,worker 不用 reach back 到 `~/work/ai-work-os/`,符合 worktree 隔离原则

**为什么全切**:
- "判定哪些 repo 需要"是认知开销,而且经常判错
- 切了用不到无害(磁盘几百兆),用得到时手边就有
- 简化 skill 流程(少一步判断)

## 拒绝的替代方案

| 方案 | 拒绝理由 |
|---|---|
| 根仓库放 `<task-id>/ai-work-os/` 子目录 | worker 路径要写 `../ai-work-os/AGENTS.md`,跟主仓库相对位置不一致,容易乱 |
| 不切根仓库(worker 读绝对路径 `~/work/ai-work-os/AGENTS.md`) | 破坏 worktree 隔离 + AI 工具不会自动加载非 worktree 范围内文件 |
| dispatcher 判定涉及 repo | 增加 dispatcher 负担,常误判,且全切代价很小 |

## 代价

- 每个 worktree 多 3 个嵌套 git worktree(磁盘小代价)
- `worktree-task` 实现要分两轮:root repo 占顶层(创建 `$task_dir`)→ sub repos 嵌套(`$task_dir/<repo>/`)。remove 反着来
- `dev-project.json` 需要 `"ai-work-os": { "base": "main", "remote": "gitlab", "path": "." }` 这个特殊条目

## 关联

- 实施:commit `9659dec`(worktree-task 支持 `path: "."` + root 占顶层 + 默认全切)
- 工具:`ai/ai-coding/worktree-task/worktree-task`
- 配置:`ai/ai-coding/dev-project.json` / `ai/ai-coding/dev-project.mac.json`
