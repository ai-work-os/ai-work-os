# 架构地图

> ai-work-os 项目结构。供 worker AI 接需求时定位。粒度:稳定结构,不写行号。

## ai-work-os 是什么

ai-work-os 是"活着的 AI 操作系统" —— 让 AI 持续工作、人随时从手机接管的协作基础设施。

核心定位:**nerve 管连接,不管内容**。nerve 是进程管理器 + 消息路由器:管 AI agent 的生死,把消息送到该去的地方,把 agent 的输出推给该看到的人。不存对话内容,不理解对话语义。

使用场景:1v1 聊天、多 agent 频道协作、程序节点定时任务、手机随时接管控制。

项目由四个独立 git 仓库组成,全部双 remote(GitHub origin + GitLab gitlab)。

---

## 子仓库

### nerve — 服务端

**职责:** 进程管理(spawn/stop agent) + 消息路由(@mention 分发) + 频道管理(成员 + SQLite 消息持久化) + WebSocket/HTTP API。

**技术栈:** Node.js / TypeScript(ESM),vitest,SQLite(better-sqlite3)。不用框架,自己实现 WS/HTTP 服务。

**仓库地址:**
- GitHub: `git@github.com:ai-work-os/nerve.git`
- GitLab: `https://g.ktvsky.com/ai-work-os/nerve.git`

**本地路径:**
- 主仓库(main): `~/work/ai-work-os/nerve/`
- worktree(dev): `~/work/worktree/ai-work-os/nerve/`

**顶层结构:**
- `src/` — 核心代码:agent、channel、node、scene、service、plugins、transport
- `test/` — 单元测试 + 集成测试 + e2e 测试
- `scenes/` — scene 定义 JSON(如 duty.json、work.json)
- `bin/` — 辅助脚本(nerve-post 等)
- `dist/` — tsc 编译产物(home 生产跑这个)

**插件目录(`src/plugins/`):** ai-life-log、ai-ear、feishu-bridge、mac-clipboard、screenshot、duty-monitor、context-guardian、system-watchdog、user-recorder 等。

---

### nerve-app — Android 客户端

**职责:** 手机端控制台 —— 查 agent 状态、DM 聊天、频道协作、spawn/stop、巡检结果/日报查看。

**技术栈:** Kotlin / Jetpack Compose,Gradle,WebSocket JSON-RPC。四层架构:server/domain/presentation/UI。

**仓库地址:**
- GitHub: `git@github.com:ai-work-os/nerve-app.git`
- GitLab: `https://g.ktvsky.com/ai-work-os/nerve-app.git`

**本地路径:**
- 主仓库(main): `~/work/ai-work-os/nerve-app/`
- worktree(dev): `~/work/worktree/ai-work-os/nerve-app/`

**包名:** `com.nerve.android`(不变)

**注:** 旧版 `nerve-android` 已废弃,勿改。

---

### nerve-tui — 终端客户端

**职责:** Mac/Linux 终端界面 —— 主力开发客户端,查看 agent 输出、发消息、切换频道/DM。

**技术栈:** Rust,ratatui(TUI 框架),tokio,WebSocket。Cargo workspace,4 个 crate:nerve-tui、nerve-tui-core、nerve-tui-bin、nerve-tui-protocol。

**仓库地址:**
- GitHub: `git@github.com:ai-work-os/nerve-tui.git`
- GitLab: `https://g.ktvsky.com/ai-work-os/nerve-tui.git`

**本地路径:**
- 主仓库(main): `~/work/ai-work-os/nerve-tui/`
- worktree(dev): `~/work/worktree/ai-work-os/nerve-tui/`

---

### notes — 文档与任务中心

**职责:** 整个 ai-work-os super-project 的共享文档库 —— 架构文档(ARCHITECTURE.md、API.md、ACP.md、INTERNALS.md)、任务目录(`tasks/`)、里程碑、设计稿。

**不含代码。** 是所有子仓库文档的统一中心。

**仓库地址:** `git@github.com:renjinxi/ai-memory.git`

**本地路径:** `~/work/worktree/ai-work-os/notes/`(只有一个)

**关键文件:**
- `ARCHITECTURE.md` — nerve 设计理念(管什么/不管什么/三个核心概念)
- `API.md` — WS JSON-RPC 2.0 + HTTP 端点契约
- `tasks/` — ~36 个任务目录 + `active.md`(当前活跃任务)

---

## nerve 核心概念

### 三个核心对象

**Agent** = 函数 `f(prompt) → stream<update>`。有工具调用能力,两次 prompt 之间静止。不知道自己在哪个频道,不知道其他 agent 的存在。"说话"能力靠注入的 nerve 技能(shell 脚本调 nerve API)。

**频道(Channel)** = nerve 内部数据结构(成员列表 + SQLite 消息记录)。不是独立实体,所有动作(存消息、路由、推送)都是 nerve 做的。频道定义消息共享范围。消息必须 @someone,没有无目标广播。

**Nerve** = 连接器。三件事:进程管理(spawn/stop)、消息传递(prompt 下发 + update 透传)、频道路由(@mention 分发)。

### 两条数据路径

**直连(1v1 DM):**  用户 → nerve → agent → nerve → 用户。nerve 不存对话内容,只做管道。agent 不知道对面是谁。对话历史由 agent 自持(claude-agent-acp 的 session),nerve 靠 `session/load` 让 agent 推回历史。

**频道:** 用户/agent → nerve → 存进频道 → @mention 路由 → 目标 agent → 输出回频道。频道消息持久化在 SQLite。人和 AI 用同样方式 @mention 通信。

### 程序节点(Program Node)

程序节点是 nerve plugin 的别名 —— 不是 AI agent,而是长期运行的程序(定时任务、桥接器、监控)。特点:

- 只响应 @mention 的已知命令,非命令消息忽略
- `channel.message` 广播**不**送给程序节点(只走 `@mention` → `node.message`)
- `node.spawn` 返回 ≠ ACP session ready;首次 prompt 需等 session 握手完成

代表插件:duty-monitor(定时派任务)、feishu-bridge(飞书桥)、mac-clipboard(截图同步)、screenshot(截图上传 HTTP)、ai-life-log(24/7 语音录制)。

### Scene

Scene = 一组预定义的节点+频道配置,nerve 启动时或 scene-manager 加载时按 JSON 定义自动 spawn。配置在 `nerve/scenes/*.json`(如 duty.json、work.json)和 `~/.nerve/scenes/`(home 个性化)。ServiceSupervisor 管理持久化的服务类程序节点(带退避重启)。

---

## 需求入口地图

| 需求类型 | 从哪里找起 |
|---|---|
| nerve 服务端逻辑(路由/API/协议) | `nerve/src/` — channel、node、transport、agent 目录 |
| nerve 协议文档(WS JSON-RPC/ACP) | `notes/API.md`、`notes/ACP.md` |
| nerve 设计理念 | `notes/ARCHITECTURE.md` |
| 新 plugin / 程序节点 | `nerve/src/plugins/` — 参考现有 plugin,继承 `plugin-base.ts` |
| Scene 配置 / 服务管理 | `nerve/scenes/`、`nerve/src/service/service-supervisor.ts` |
| Android 客户端(DM/频道/UI) | `nerve-app/app/src/main/` — presentation/ui/domain/server 四层 |
| Android 架构设计 | `nerve-app/README.md` |
| 终端 TUI 客户端 | `nerve-tui/crates/` — nerve-tui-core(逻辑)、nerve-tui(UI) |
| TUI 终端问题 | `nerve-tui/docs/` + ratatui 官方文档 |
| 历史任务 / 以前做过什么 | `notes/tasks/` + `context/task-index.md` |
| 部署/运维 | `context/playbook.md` 的 home 运维节 |
| 操作命令速查 | `ai-coding/skills/nerve-server.md` |
