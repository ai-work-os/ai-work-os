# 隔离 worktree 开发流程(Mac 与手机同构)

> 状态:`worktree-task` 工具已装,Mac 入口 `start-task` skill 已落地。
> 手机端 dispatcher 自动 spawn worker 还未完全实现,但流程对齐。
> 本文件是给 AI 节点(Mac 上 Claude Code / home 上 dispatcher)读的**操作说明**。

## 两个入口,同一套流程

| 入口 | 谁 | 触发 |
|---|---|---|
| **Mac** | renjinxi 自己在主仓库开 Claude Code | 用 `start-task` skill(说"我有个需求 X")|
| **手机** | renjinxi 在 nerve-app 跟常驻 dispatcher 聊 | dispatcher 走 `remote-dev` skill |

两边都得到同样的产物:`<worktree_root>/<id>/<repos>/` + `task/<id>` 分支 + 填好的 `TASK.md`。
区别只是"谁澄清需求 + 谁跑 worktree-task":Mac 是 Claude Code 自己,手机是常驻 dispatcher。

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
| ④ 装上下文 | worker | spawn 进 worktree,读 `TASK.md` + `~/work/ai-work-os/AGENTS.md`(根仓库入口) |
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
2. **项目文档** —— 根仓库 `~/work/ai-work-os/AGENTS.md` + `ai/` 子目录是上下文来源。**worktree-task 待改:**目前 worktree 里不自动 sync 根仓库内容,worker 直接去根仓库目录读。
3. **代码地图** —— dispatcher 预侦察后写进 `TASK.md`。

**飞轮**:worker 收尾时筛出"确认有效的沉淀"写回 `ai/knowledge/`,下个 worker 起点更高。

## 当前可用程度

- **Mac**:`worktree-task` 已装,`start-task` skill 已注册,直接可用。
- **home**:常驻 agent 能读根仓库 / 跑 worktree-task;dispatcher 自动 spawn worker 还在手动阶段(skill 文档已就绪)。
- 配置见 `dev-project.{mac,home}.json`,`README.md` 有装机说明。
