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

### 2. 预侦察

在主仓库读相关代码,定位:
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
case "$(uname -s)" in
  Darwin) CONFIG=~/work/ai-work-os/ai/ai-coding/dev-project.mac.json ;;
  Linux)  CONFIG=~/work/ai-work-os/ai/ai-coding/dev-project.json ;;
esac
worktree-task create --config "$CONFIG" --task <id> --type <type>
```

分支名自动 `<type>/<id>`(例 `fix/retry-logic-0526`)。工具默认全切,不传 `--repos`。骨架 `TASK.md` 自动写入 `<worktree_root>/<id>/`(根 `.gitignore` 屏蔽 TASK.md,不进 git)。

Edit `<worktree_root>/<id>/TASK.md` 替换三个占位符:
- `<做什么、为什么>` → 澄清后的需求 + 动机
- `<怎样算完成>` → 验收标准 bullet 列表
- `<相关文件、入口、参考实现、要避开的坑>` → 预侦察产出(**最重要**,写到 `file:line`)

## 红旗

- 需求没说清就建 worktree → 代码地图会空,worker 盲跑
- 没预侦察就建 worktree → 同上
- 边干边填 TASK.md → 不行,任务卡是 worker 的输入,不是事后笔记
- cwd 已在 worktree 里(路径含 `worktree/ai-work-os/<task-id>`)还触发 → 反问是不是子任务,不要套娃
