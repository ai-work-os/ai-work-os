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

**技术栈:** Node.js / TypeScript(ESM),vitest,SQLite(better-sqlite3)。不用框架,自己实现 WS/HTTP 服务。nerve.db 是 SQLite,位于 `~/.nerve/nerve.db`,存频道消息/节点记录,可直接查询。

**仓库地址:**
- GitHub: `git@github.com:ai-work-os/nerve.git`
- GitLab: `https://g.ktvsky.com/ai-work-os/nerve.git`

**本地路径:**
- 主仓库(main): `~/work/ai-work-os/nerve/`
- worktree(dev): `~/work/worktree/ai-work-os/nerve/`

**顶层结构:**
- `src/` — 核心代码,已分层:`transport/ storage/ channel/ node/ scene/ agent/ mcp/ infra/ integration/ channel-mcp/`,顶层只剩 `cli.ts server.ts index.ts`
- `test/` — `unit/ integration/ e2e/ legacy/ fixtures/ helpers/`(分目录分层)
- `scenes/` — scene 定义 JSON(如 duty.json、work.json)
- `bin/` — 辅助脚本(nerve-post 等)
- `dist/` — tsc 编译产物(home 生产跑这个)

**插件目录(`src/plugins/`):** ai-life-log、ai-ear、feishu-bridge、mac-clipboard、screenshot、duty-monitor、context-guardian、system-watchdog、user-recorder、email-watcher(macOS,IMAP 邮件验证码→剪贴板)、observer(订阅全频道事件,JSONL 持久化到 `~/.nerve/plugins/observer/events/*.jsonl`)。

**MCP(`src/mcp/`):** `nerve-mcp.ts` 实现两个工具:`nerve_command`(结构化调用程序节点命令)、`nerve_capabilities`(发现可用能力)。

**nerve-channel(`src/channel-mcp/`):** 独立 MCP server,外部 Claude Code 进程作为 external node 接入 nerve 频道协作。

**nerve-cli(`src/cli/commands/`):** nerve 全量 HTTP 端点的 CLI 镜像,子命令在 `channel.ts / node.ts / dm.ts / scene.ts / session.ts` 等。输出默认 JSON(供 AI 消费),`--human` 可读,错误走 stderr `{"error":...}` + exit 1。

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

**技术栈:** Rust,ratatui 0.29 + crossterm,tokio,WebSocket;syntect(语法高亮)、pulldown-cmark(Markdown 渲染)。Cargo workspace,4 个 crate:nerve-tui、nerve-tui-core、nerve-tui-bin、nerve-tui-protocol。底层走 claude-agent-acp,支持 superpowers skill(无原生 `/` 命令提示)。

**仓库地址:**
- GitHub: `git@github.com:ai-work-os/nerve-tui.git`
- GitLab: `https://g.ktvsky.com/ai-work-os/nerve-tui.git`

**本地路径:**
- 主仓库(main): `~/work/ai-work-os/nerve-tui/`
- worktree(dev): `~/work/worktree/ai-work-os/nerve-tui/`

---

## nerve 核心概念

### 三个核心对象

**Agent** = 函数 `f(prompt) → stream<update>`。有工具调用能力,两次 prompt 之间静止。不知道自己在哪个频道,不知道其他 agent 的存在。"说话"能力靠注入的 nerve 技能(shell 脚本调 nerve API)。

**频道(Channel)** = nerve 内部数据结构(成员列表 + SQLite 消息记录)。不是独立实体,所有动作(存消息、路由、推送)都是 nerve 做的。频道定义消息共享范围。消息必须 @someone,没有无目标广播。

**Nerve** = 连接器。三件事:进程管理(spawn/stop)、消息传递(prompt 下发 + update 透传)、频道路由(@mention 分发)。

### 频道的准确类比

**频道 ≈ 路由器/邮局,不是群聊。** 发进频道的消息默认所有节点都看不到;只有被 @mention 的节点才会收到 `node.message`。`channel.message` 广播明确跳过程序节点。这是最常被新手误解的地方。

### headless 是核心定位

AI 节点和程序节点在服务器常驻推进任务;TUI 和 Android 只是观察与输入入口。nerve 的价值在"后台无人值守"运行,而不是实时人机对话。

### 两条数据路径

**直连(1v1 DM):**  用户 → nerve → agent → nerve → 用户。nerve 不存对话内容,只做管道。agent 不知道对面是谁。对话历史由 agent 自持(claude-agent-acp 的 session),nerve 靠 `session/load` 让 agent 推回历史。

**频道:** 用户/agent → nerve → 存进频道 → @mention 路由 → 目标 agent → 输出回频道。频道消息持久化在 SQLite。人和 AI 用同样方式 @mention 通信。

### 程序节点(Program Node)

程序节点是 nerve plugin 的别名 —— 不是 AI agent,而是长期运行的程序(定时任务、桥接器、监控)。特点:

- 只响应 @mention 的已知命令,非命令消息忽略
- `channel.message` 广播**不**送给程序节点(只走 `@mention` → `node.message`)
- `node.spawn` 返回 ≠ ACP session ready;首次 prompt 需等 session 握手完成

代表插件:duty-monitor(定时派任务)、feishu-bridge(飞书桥)、mac-clipboard(截图同步)、screenshot(截图上传 HTTP)、ai-life-log(24/7 语音录制)、ai-ear(原 mc-transcriber,AI 的耳朵,目录 `src/plugins/ai-ear/`,调用流程:spawn → 入频道 → subscribe transcription → start)。

**plugin-base(`src/plugins/plugin-base.ts`)** 内置能力:
- 统一持有 `channelId`(加入频道时设置,离开时清空)
- 内置事件订阅系统:`subscribe` / `unsubscribe` / `subscribers` 命令;支持 `event:filter` 过滤;节点离线自动 unsubscribe
- `normalizeArgs`:统一 @mention positional args 与 MCP `nerve_command` named args 两条路径,插件两种调用方式都兼容
- `registerNotifications` 可 override,base 默认监听 `channel.nodeJoined` / `channel.message` / `node.message`

### Scene

Scene = 一组预定义的节点+频道配置,nerve 启动时或 scene-manager 加载时按 JSON 定义自动 spawn。配置在 `nerve/scenes/*.json`(如 duty.json、work.json)和 `~/.nerve/scenes/`(home 个性化)。

**ServiceSupervisor** 管理持久化的服务类程序节点(带退避重启)。声明文件:`~/.nerve/services.json`。设计原则:两台 nerve 实例不互相通信 —— 本地 nerve 负责保活本地程序节点,程序节点自己以 WS 连接 home nerve,WS 在线即 online 信号。`placement`(local/remote)与 `kind`(agent/service)正交。

### ai-life-log 技术细节

ASR 栈:`sherpa-onnx-node` + silero-VAD + SenseVoice ONNX。模型搜索顺序:env override → 官方 sherpa-onnx 模型目录 → 闪电说安装目录 → `~/.nerve/plugins/ai-life-log/models/`。两类噪音在 `transcript-filter.ts` 过滤:VAD 误触发产生的单标点、token 复读。wake watchdog 阈值 300s(5 min 才视为系统休眠,规避 GC/CPU 尖峰误报)。

---

## 需求入口地图

| 需求类型 | 从哪里找起 |
|---|---|
| nerve 服务端逻辑(路由/API/协议) | `nerve/src/` — channel、node、transport、agent 目录 |
| 新 plugin / 程序节点 | `nerve/src/plugins/` — 参考现有 plugin,继承 `plugin-base.ts` |
| MCP 工具(nerve_command / nerve_capabilities) | `nerve/src/mcp/nerve-mcp.ts` |
| 外部 Claude Code 接入频道 | `nerve/src/channel-mcp/nerve-channel.ts` |
| nerve-cli 全量 CLI | `nerve/src/cli/commands/` |
| Scene 配置 / 服务管理 | `nerve/scenes/`、`nerve/src/service/service-supervisor.ts` |
| Android 客户端(DM/频道/UI) | `nerve-app/app/src/main/` — presentation/ui/domain/server 四层 |
| Android 架构设计 | `nerve-app/README.md` |
| 终端 TUI 客户端 | `nerve-tui/crates/` — nerve-tui-core(逻辑)、nerve-tui(UI) |
| TUI 终端问题 | `nerve-tui/docs/` + ratatui 官方文档 |
| 部署/运维 | `context/playbook.md` 的 home 运维节 |
| 操作命令速查 | `ai-coding/skills/nerve-server.md` |
