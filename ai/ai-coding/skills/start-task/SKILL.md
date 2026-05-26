---
name: start-task
description: Use when user proposes a new development task in ai-work-os (phrases like 我有个需求 / 新任务 / 我想加/改/修, or explicit "start a task" / "new task"), needing an isolated worktree with task/<id> branch cut from main. Sets up environment so user can switch into the new worktree and start coding.
---

# start-task — ai-work-os 任务环境一站式创建

## 何时用

用户在主仓库提出**明确的开发需求**(改/加/修代码、写新功能、修 bug)。

不用:纯问答、文档查询、运维操作、"这段代码什么意思"这种解释类问题。

## 流程

### 1. 澄清(必要时反问)

需求必须具体到能写**验收标准**(怎样算完成、要不要测试、影响哪些路径)。模糊就反问,直到能写出 2-3 条可勾选的验收项。

只问真正缺的,不照单走流程问废话。

### 2. 取任务 id

格式 `<简短英文描述>-<MMDD>`,例:`retry-logic-0525` `fix-acp-cost-0525`。
用今天的日期(系统注入的 currentDate)。

### 3. 判定涉及仓库

ai-work-os 有四仓:`nerve` `nerve-tui` `nerve-app` `ai`。
判断需求要改哪些。`ai` 仓库总是带上(worker 要靠它读上下文)。

### 4. 预侦察(在主仓库)

跑命令前先在主仓库(`/Users/renjinxi/work/ai-work-os/<repo>/`,**不是** worktree)读相关代码,定位:
- 要改的文件 + file:line
- 主要入口函数 / 类
- 现有的参考实现(类似功能怎么做的)
- 要避开的坑(已知 bug / 历史踩坑)

这步**不能跳**。worker 拿不到这些就要重新摸一遍代码,浪费一轮。

### 5. 选配置 + 建 worktree

按平台选配置文件:
```bash
case "$(uname -s)" in
  Darwin) CONFIG=~/work/ai-work-os/ai/ai-coding/dev-project.mac.json ;;
  Linux)  CONFIG=~/work/ai-work-os/ai/ai-coding/dev-project.json ;;
esac
worktree-task create --config "$CONFIG" --task <id> --repos <r1,r2>,ai
```

完成后会得到 `<worktree_root>/<id>/`,里面每个 repo 是 `task/<id>` 分支(从 main 切)。骨架 `TASK.md` 自动生成,占位符待填。

### 6. 填 TASK.md

Edit `<worktree_root>/<id>/TASK.md`,替换四个占位符:

- `<做什么、为什么>` → 第 1 步澄清出来的需求 + 动机
- `<怎样算完成>` → 验收标准,bullet 列表
- `<相关文件、入口、参考实现、要避开的坑>` → 第 4 步预侦察的产出
- `$repos`(已自动填,确认即可)

骨架其余部分不动。

### 7. 报告

发给用户:
- worktree 路径(`<worktree_root>/<id>/<主repo>/`)
- 任务 id 和分支名
- 一句话总结:他切过去开 Claude Code,worker 自己读 `../TASK.md` 和 `~/work/ai-work-os/AGENTS.md` 就能干

不主动 spawn worker、不自动进入 worktree 写代码。**到此打住**,把控制权交回用户。

## 边界

- 这个 skill **只搭环境**,不写实现代码。代码在新 worktree 里另起 Claude Code 写。
- worktree 已经从 main 切了,不要再把 dev 的改动合进来。
- 如果用户已经在 worktree 里说"我要做 X",那他可能是要起子任务 — 反问确认,不要直接跑 skill 把自己套娃。

## 红旗 - 出现以下就停

- 用户没说清要改什么 → 第 1 步还没过,不许跑 worktree-task
- 没做预侦察就建 worktree → TASK.md 代码地图会空,worker 起步盲跑
- 想"先建 worktree,边写代码边填 TASK.md" → 不行,任务卡是 worker 的输入,不是事后笔记

## 参考

- 工具:`~/work/ai-work-os/ai/ai-coding/worktree-task/README.md`
- 全流程设计:`ai/ai-coding/remote-dev-flow.md`
- worker playbook:`ai/ai-coding/skills/remote-dev.md`
