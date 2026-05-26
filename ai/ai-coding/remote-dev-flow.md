# 隔离 worktree 开发流程

不论从哪触发(Mac 直接 / 手机 → 频道 dispatcher),都走 [start-task skill](skills/start-task/SKILL.md),产出同一种 worktree。

## 产出结构(跟主仓库 100% 镜像)

```
<worktree_root>/<task-id>/
├── AGENTS.md / CLAUDE.md    ← 根仓库 worktree 顶层
├── ai/                       ← 项目知识
├── TASK.md                   ← 任务卡(AGENTS.md 顶部引导自动读)
├── nerve/                    ← 三个代码仓 worktree(分支 task/<id>)
├── nerve-app/
└── nerve-tui/
```

worker 启动 / spawn / 调度由 nerve scene 配置处理,不在本流程范围。

## 铁律

- 默认不自动 merge,只推分支 `task/<id>` 等 review。
- TASK.md / plan.md / progress.md 是任务工作区临时文件,留在 worktree 顶层,**不进 git**。
- 任务完成清理:`worktree-task remove --task <id>`。
