---
name: start-task
description: Use when user proposes a new development task in ai-work-os (我有个需求 / 新任务 / 我想加/改/修 / start a task / new task). Sets up an isolated worktree mirroring the main repo layout, writes a task card with requirement + acceptance criteria + code map, hands path back to user.
---

# start-task — ai-work-os 新任务环境

## 何时用

用户在主仓库提出**明确的开发需求**(改/加/修代码、写新功能、修 bug)。

不用:问答、文档查询、运维操作、"这段代码什么意思"等解释类。

## 你要做的事

**三件**(其他全自动):

1. **澄清** —— 反问到能写出 2-3 条可勾选验收标准为止。模糊就停下来问,别硬建 worktree。
2. **预侦察** —— 在主仓库读相关代码,定位:
   - 要改的文件:`path/to/file.ts:line`
   - 主要入口函数 / 类 / 路由
   - 现有参考实现(类似功能怎么做的)
   - 要避开的坑(已知 bug、历史踩坑、相邻代码的隐性约束)
   
   **这一步最值钱**。worker 拿不到这些就要重新摸代码、浪费一轮。
3. **建 worktree + 填 TASK.md** —— 见下。

干完报告路径给用户。**到此打住**,worker 由用户自己在新窗口开 Claude Code 启动(AI 工具自动加载 AGENTS.md → AGENTS.md 自动引导读 TASK.md,你不用写"worker 应该读什么")。

## 取任务 id

格式 `<简短英文描述>-<MMDD>`,例 `retry-logic-0526`。用今天的日期(系统注入的 currentDate)。

## 跑 worktree-task

```bash
case "$(uname -s)" in
  Darwin) CONFIG=~/work/ai-work-os/ai/ai-coding/dev-project.mac.json ;;
  Linux)  CONFIG=~/work/ai-work-os/ai/ai-coding/dev-project.json ;;
esac
worktree-task create --config "$CONFIG" --task <id>
```

工具默认全切(根仓库 + 三个代码仓),不要传 `--repos`。

得到 `<worktree_root>/<id>/`,结构跟主仓库 100% 镜像(AGENTS.md / CLAUDE.md / ai/ 在顶层,三个代码仓嵌套,TASK.md 骨架自动写)。

## 填 TASK.md

骨架由工具写,你 Edit 替换三个占位符:

- `<做什么、为什么>` → 澄清后的需求 + 动机(不只是"做 X",还要"为什么")
- `<怎样算完成>` → 验收标准,bullet 列表
- `<相关文件、入口、参考实现、要避开的坑>` → 预侦察产出(**最重要**,写具体到 file:line)

骨架其余不动。

## 报告

发给用户:
- worktree 路径(主代码仓位置,如 `<worktree_root>/<id>/nerve/`)
- 任务 id + 分支 `task/<id>`
- 一句话:切过去开 Claude Code 直接干,AGENTS.md / TASK.md 都会自动加载。

## 红旗 —— 出现就停

- 需求没说清就跑 worktree-task → TASK.md 代码地图会空,worker 盲跑
- 没做预侦察就建 worktree → 同上
- 想"边干边填 TASK.md" → 不行,TASK.md 是 worker 的输入,不是事后笔记
- 已经在 worktree 里(cwd 路径含 `worktree/ai-work-os/<task-id>/`)用户说"我要做 X" → 反问是不是子任务,不要套娃建 worktree

## 参考

- 工具内部:`ai/ai-coding/worktree-task/README.md`
- 平台配置:`ai/ai-coding/dev-project.{mac,home}.json`
