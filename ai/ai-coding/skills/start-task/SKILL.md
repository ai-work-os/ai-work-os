---
name: start-task
description: Use when user proposes a new development task in ai-work-os (我有个需求 / 新任务 / 我想加/改/修 / start a task / new task). Distills requirement into an isolated worktree with a filled task card.
---

# start-task — 新任务环境 + 任务卡

## 何时用

用户提出**明确的开发需求**(改/加/修代码、写新功能、修 bug)。

不用:问答、文档查询、运维操作、解释类问题。

## 三件事

### 1. 澄清

反问到能写出 2-3 条可勾选的验收标准为止。

同时确认 GitLab Issue / 看板入口:
- 用户给了 Issue URL 或编号:写入 TASK.md,后续 MR 关联这个 Issue。
- 用户没给 Issue:在 TASK.md 留 `Issue: <待创建/待关联>`,不要自己编编号。
- 看板状态以 GitLab Issue / MR 为准;任务卡只是 worker 输入,不是长期看板。

### 2. baseline preflight + 预侦察

先识别当前运行环境,再确定配置:

```bash
uname -s
hostname
pwd
case "$(uname -s)" in
  Darwin) CONFIG=~/work/ai-work-os/ai/ai-coding/dev-project.mac.json ;;
  Linux)  CONFIG=~/work/ai-work-os/ai/ai-coding/dev-project.json ;;
esac
```

`worktree-task create` 会按配置对每个 repo 先 `fetch` 远端基线,再从 `remote/base` 的最新 commit 创建 worktree。配置里的 root `ai-work-os` 基线是 `gitlab/main`,子仓是 `origin/main`。

预侦察必须和远端基线对齐:不要用当前 checkout 或可能落后的本地 `main` 当代码地图。需要读代码时,先确认对应 repo 的远端基线已刷新,或在刚创建出的 worktree 里读。

定位:
- 要改的文件:`path/to/file.ts:line`
- 主要入口函数 / 类
- 现有参考实现
- 要避开的坑

**这一步最值钱**。worker 拿不到这些就要重新摸代码,浪费一轮。

### 3. 建 worktree + 填 TASK.md

任务 id:`<简短英文描述>-<MMDD>`,例 `retry-logic-0526`。

判定分支类型(`--type`),按 git flow 选:

| type | 用于 |
|---|---|
| `feat` | 新功能 / 增能 (缺省) |
| `fix` | 修 bug |
| `refactor` | 重构(不改行为) |
| `docs` | 仅文档 |
| `chore` | 杂活(构建/CI/依赖等) |

```bash
worktree-task create --config "$CONFIG" --task <id> --type <type>
```

分支名自动 `<type>/<id>`(例 `fix/retry-logic-0526`)。工具默认全切,不传 `--repos`。骨架 `TASK.md` 自动写入 `<worktree_root>/<id>/`(根 `.gitignore` 屏蔽 TASK.md,不进 git),并包含每个 repo 的 baseline `repo: remote/base @ commit`。

Edit `<worktree_root>/<id>/TASK.md` 替换三个占位符:
- `<做什么、为什么>` → 澄清后的需求 + 动机
- `<怎样算完成>` → 验收标准 bullet 列表
- `<相关文件、入口、参考实现、要避开的坑>` → 预侦察产出(**最重要**,写到 `file:line`)

若已有 GitLab Issue,补充到 TASK.md:
- `Issue: <url 或 #id>`
- `MR: <待创建>`
- `看板: <当前列/状态>`

worker 完工后创建 MR,把 MR URL 回填 TASK.md 或频道报告;不要把临时进度当看板真相源。

## 红旗

- 需求没说清就建 worktree → 代码地图会空,worker 盲跑
- 没做 baseline preflight / 用旧 checkout 预侦察 → 代码地图可能指向旧实现
- 没预侦察就建 worktree → worker 仍会盲跑
- 有 Issue 却没关联到 TASK.md / MR → 看板会断链
- 边干边填 TASK.md → 不行,任务卡是 worker 的输入,不是事后笔记
- cwd 已在 worktree 里(路径含 `worktree/ai-work-os/<task-id>`)还触发 → 反问是不是子任务,不要套娃
