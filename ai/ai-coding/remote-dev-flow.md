# 隔离 worktree 开发流程

两个入口,共用一套流程([start-task skill](skills/start-task/SKILL.md)):

| 入口 | 谁触发 | 谁建 worktree | 谁干活 |
|---|---|---|---|
| Mac | 用户自己 | 当前 Claude Code(走 start-task) | 用户切到 worktree 开新 Claude Code |
| 手机 | 用户 → nerve-app | home dispatcher(走 [remote-dev](skills/remote-dev.md)) | dispatcher `nerve_spawn` worker |

两条路得到同样产物:`<worktree_root>/<id>/` —— 结构跟主仓库 100% 镜像。

## worktree 结构

```
<worktree_root>/<task-id>/
├── AGENTS.md / CLAUDE.md           ← 根仓库 worktree 顶层(AI 工具自动加载)
├── ai/                              ← 项目知识(playbook / architecture / conventions)
├── TASK.md                          ← 任务卡(AGENTS.md 顶部引导自动读)
├── nerve/                           ← 三个代码仓 worktree
├── nerve-app/                       (分支 task/<id>,从 main 切)
└── nerve-tui/
```

worker cwd 在 `<task-id>/<主代码repo>/`,跟主仓库 `~/work/ai-work-os/<repo>/` 相对位置完全一致。

## 当前可用程度

- **Mac**:`worktree-task` 装好,`start-task` skill 注册,直接可用。
- **home**:dispatcher prompt 同步;手动触发跑通;自动 spawn worker 流程文档已就绪、实战待磨。

## 铁律

- 默认不自动 merge,只推分支 `task/<id>` 等 review。
- TASK.md / plan.md / progress.md 是临时的,留 worktree 顶层,**不进 git**(根 `.gitignore` 已屏蔽常见名)。
- worker 完成后用户清理:`worktree-task remove --task <id>`。
