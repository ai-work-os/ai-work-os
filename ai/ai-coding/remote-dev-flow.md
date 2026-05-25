# 远程开发流程(手机发起 → home 隔离 worktree 执行)

> 状态:设计已收敛,工具(`worktree-task`)与 dispatcher 自动化尚未实现。
> 完整设计与落地计划见 `notes/tasks/mobile-agent-worktree-execution-20260506/design.md`。
> 本文件是给常驻 AI 节点读的**操作说明**。

---

## 目标

renjinxi 在手机 nerve-app 上聊清一个开发需求 → 系统切隔离 git worktree、起 AI 干活、
跑测试、推分支 → renjinxi 有空时 review / merge。**默认不自动 merge,只推分支 / MR。**

## 流程(8 阶段)

```
①手机聊需求 → ②dispatcher 蒸馏任务卡+预侦察代码 → ③worktree-task 建隔离区
→ ④worker 装载上下文 → ⑤TDD 开发 → ⑥build & verify → ⑦push/MR/回报/自退
→ ⑧renjinxi review / merge
```

| 阶段 | 谁 | 做什么 |
|------|----|----|
| ① Intake | renjinxi ↔ dispatcher | 在 nerve-app 聊需求,dispatcher 反问澄清到具体 |
| ② 任务卡 | dispatcher | 蒸馏需求 + 预侦察代码 → 写 `TASK.md`(需求/验收标准/代码地图) |
| ③ 建隔离区 | `worktree-task` | 多仓 worktree + `task/<id>` 分支(从基线切) |
| ④ 装上下文 | worker | spawn 进 worktree,读 `TASK.md` + `ai/ai.md` |
| ⑤ 开发 | worker | TDD 红-绿-重构;改 nerve 用测试端口 4801 |
| ⑥ 验证 | worker | 全量 build + test + lint,按 CLAUDE.md 完成清单卡门 |
| ⑦ 提交 | worker | commit / push 分支(nerve 双 remote 都推)/ MR / 回报频道 / 自退 |
| ⑧ Review | renjinxi | 有空时 review,起 codex 二审,手动 merge |

## 角色

- **dispatcher** —— 常驻 agent(`#ai-work-os` 的 `ai-work-os-agent` / `#erp` 的 `erp-agent`),
  cwd 在主仓库,**只派活、不写代码**。负责 ①②③ 和 spawn worker。
- **worker** —— 一次性 agent,cwd 指向 worktree。负责 ④⑤⑥⑦,干完自退。

## 上下文怎么给 worker

worker 是全新 agent,上下文靠三层喂:

1. **任务卡** `TASK.md` —— dispatcher 把手机对话蒸馏成的需求 + 验收标准 + 代码地图。
   放 worktree 任务根目录(所有 sub-repo worktree 的上一级),freestanding,不进 git。
2. **项目文档** —— `ai/`(本仓库)随 worktree 一起在场,worker 读 `ai/ai.md` 入口。
3. **代码地图** —— dispatcher 预侦察后写进 `TASK.md`。

**飞轮**:worker 收尾时筛出"确认有效的沉淀"写回 `ai/knowledge/`,下个 worker 起点更高。

## 当前可用程度

- 现在:home 常驻 agent 能读到本仓库,即"知道流程是什么"。
- 未实现:`worktree-task` 工具、dispatcher 自动派活、worker 自动 spawn。见 design.md 落地计划。
