# 约定与坑

> 稳定约定 + 常见坑。worker 动手前先读。

## 稳定约定

### 仓库结构与 git 流程

- **多仓结构:** 根仓库 `ai-work-os` + 三个代码仓 `nerve` / `nerve-app` / `nerve-tui`(各自独立 git)。根 `.gitignore` 屏蔽代码仓。
- **开发在任务 worktree 内(`task/<id>` 分支)**,不在主仓库改代码。worktree 由 `start-task` skill 自动创建,结构跟主仓库 100% 镜像。提交: `git -C <worktree>/<repo> commit`。
- **双 remote push:** 所有仓库(根 + 三代码仓)都配了 `origin`(GitHub) + `gitlab`(公司 GitLab),推送两个都要推。
- commit 时若 hook 报错,需要 `GVM_ROOT="" git commit ...`。

### 测试规则

- **测试在任务 worktree 内跑**,不在主分支测未验证改动。
- **nerve 测试实例用 4801 端口**,不抢生产 4800。
- 集成测试必须随机端口 + 临时数据目录隔离(详见 `context/playbook.md` 测试规则节)。

### TDD 与 review

- **新增/修改模块必须有测试**,关键路径必须有日志。
- **review 必须同时起 claude + codex 两个 reviewer**,两个都通过才算通过。codex 只 review 不改代码不更新进度。

### 多 agent 协作

- **默认单 agent 干活**,等同 Claude Code 体验。不要进 nerve 就开多 agent。只有任务明确可拆分、确实需要并行时才上多 agent 协调。
- **Mode D(sub-main 协调):** main 派任务给 sub-main(fix-lead),sub-main 协调 tester/coder/reviewer。批量小任务优先用此模式。Sub-main 完成后 stop 所有 worker 和自己,不留 idle。
- **Agent 分工:** claude 主力干活写代码,codex 做 code review。排查方案时两者可同时讨论。

### Android 开发

- **当前项目是 nerve-app**,旧版 `nerve-android` 已废弃永不改。代码路径: `~/work/worktree/ai-work-os/nerve-app/`。
- **包名: `com.nerve.android`**。`applicationId` 虽是 `com.nerve.app` 但 `adb` 命令用包名 `com.nerve.android`。
- **Android 端不做本地持久化:** server buffer 是唯一真相源,DM 消息只存内存,内存中消息列表永远不清空(靠 replay 去重追加)。给 AI 写代码时必须显式说明此约束。
- **Android 功能完工默认 bump versionCode + publish-android**,不要停在 push。
- **Android release commit 合并 main 后由 GitLab CI 发布**: `nerve-app` 的 `android_release` 只允许 main push pipeline 手动触发;CI 不 bump 版本、不 commit、不 push。

### 演进原则

- **先搭骨架后演进**:遇到卡点才加内容,空目录是合法状态。不要"为了完整性"一次铺满。
- **不要顺手扩 scope**:只做用户明确指出的范围。
- **task 完成产生固有知识 → 更新进 `context/` 对应文件**。

### 工程规范

- nerve 服务端:关键路径必须有日志,新增/修改模块必须有测试。
- 程序节点输出:关键状态写 DM 视图(node.log),业务动作走频道(channel.post)—— 两条路互不干扰。
- 高频运行期流水写 `~/.nerve/` runtime/plugin data,不要写进 `~/.ai` git。`~/.ai` 只放低频沉淀、任务材料、日报/周报/审计汇总。
- 插件 adapter 必须填 `commands` + `usage` 字段 —— AI 和人都靠这个知道怎么用插件。
- 客户端发消息**不要加 `node_name:` 前缀** —— 服务端已统一处理,加了反而格式出错。
- 插件等频道用事件驱动(`channel.nodeJoined`),不要 poll;集成测试避免 hardcoded sleep,用事件驱动 + waitFor。
- worktree 任务文件(TASK.md / plan.md / progress.md)freestanding 放 worktree 根目录,不属任何 git 仓,天然被各子仓 worktree 共享。需要软链才能"够得着"上下文 = 结构错位信号(例外:适配外部工具写死的文件名如 CLAUDE.md)。
- worker 收尾时将本次发现的坑/规范写回 `ai/context/`,随代码一起 commit —— "过滤器不是水龙头"。

---

## 常见坑

### nerve 程序节点两坑

**坑 1:`channel.message` 不广播给程序节点**
`channel-manager.broadcastToChannel` 明确跳过 program nodes。Plugin 注册 `channel.message` 是死代码,永远收不到。
解决:必须走 @mention → `node.message` 路径;让发消息方 `@<plugin-name>` 或调 `nerve_post({to: "<plugin-name>", content: ...})`。

**坑 2:`node.spawn` 返回 ≠ ACP session ready**
`node.spawn` 返回时子进程已起,但 ACP handshake 还在跑(实测 ~1.9s)。期间任何 prompt 立刻失败 `error="no session"`,消息被吞无重试。
解决:简单方案 spawn 后 sleep 4s;严谨方案监听 `node.statusChanged` 第二次触发或用 `scene-manager.ts` 的 `waitForReady`。

### Android 客户端不做本地持久化

nerve 的 AI 对话是任务型,server buffer 是 source of truth。AI 默认按常规 Android 架构写代码时会清内存等 replay 恢复,但 replay 不可靠。**给 AI 的指令里必须显式说"不做持久化、消息只存内存、永不清空"**。DM bug 五轮修不好的根因就在此。

### WS 心跳(半开连接)

WS 半开连接会导致节点假在线:机器睡眠/网络抖动后客户端不收到 `close` → 重连不触发 → 插件卡死 offline。nerve 已在 PluginBase 客户端 + server 端实现双向心跳检测处理此问题。

### Agent 执行被消息打断

Agent 调用 Write/Edit 工具期间收到新消息可能被打断,文件未写入且不自动恢复。操作:不要在 agent 写文件期间催促;如果 agent 卡住优先起新 agent 重做。

### Agent 空转不写文件

Agent 可能在 thinking 中规划了代码但没实际调用 Write/Edit,却报告完成。检验方法:要求 agent 完成后跑 `git diff --stat` 或 `cargo check` 验证改动存在;reviewer 先检查文件是否有实际改动。

### nerve 重启必须干净

重启时必须:杀所有旧进程(nerve + agent + mcp) → 确认端口释放 → 单实例启动。不完整重启导致端口占用、双实例、旧 agent 进程残留。
`nerve-server restart` 封装了正确流程。手动重启用:
```bash
pkill -f "claude-agent-acp"; pkill -f "nerve-mcp"
lsof -ti:4800 | xargs kill -9
sleep 2
nerve-server start
```

### home systemd 常见错误

- **不要 `sudo systemctl`** — system-level nerve.service 是死的,user-level 才是活的
- **改完 TS 必须 build** — `npm run build` 后再 `systemctl --user restart nerve`
- **加 env 必须 daemon-reload** — 不然新 env 不生效
- **新依赖必须 home 上 `npm install`** — 否则 plugin spawn ERR_MODULE_NOT_FOUND 循环重启

### ACP cost 字段类型

ACP `usage_update` 的 `cost` 字段是 `{amount, currency}` 对象,不是数字。nerve 需要提取 `.amount`,TUI 端 `NodeUsage.cost: f64` 反序列化需防御。写 ACP 相关代码时注意此字段类型。

### mac-clipboard 已切 ServiceSupervisor 托管

mac-clipboard 已从 launchd 改为 nerve ServiceSupervisor 管理(2026-05-17)。配置在 `~/.nerve/services.json`。launchd plist 已 `bootout` 并改名为 `.disabled`。不要再试图用 launchd 管 mac-clipboard。

### `import.meta.url` 路径层数

移动插件文件后,`import.meta.url` 计算的 `../` 层数必须同步调整,否则 program node spawn 时找不到 plugin 文件(ESM 没有 `__dirname`)。这是改目录结构必踩的坑。

### system-watchdog 集成测试隔离

system-watchdog v1 看不到被 kill 移除的节点(只能测 hang/leak)。集成测试须设置 `WATCHDOG_SILENCE_FILE` 环境变量隔离 watchdog 行为,防干扰其他测试。

### system-watchdog alert 文件不进 `~/.ai`

system-watchdog 是分钟级监控,默认 alert 文件在 `~/.nerve/plugins/system-watchdog/alerts/system-alerts.md`。不要把实时 alert 流水写回 `~/.ai/ops/state/system-alerts.md`,否则 Mac/home 双端自动同步时会在 rebase 过程中被运行期写入打断。需要长期留存时,由 duty 生成日汇总/审计报告进 `~/.ai/ops/reports/` 或 `workspace/activity/audits/`。

### Android ColorOS 后台冻结

ColorOS 会冻结整个 app 进程。需在系统设置中给 nerve-app 开启后台白名单,否则 socket 连接和录音进程均被杀。nerve-app 的 GitLab 默认分支已从 `dev` 改为 `main`。

### 频道消息不支持二进制/大 blob

频道消息只传文本。图片等大 blob 走专用 HTTP 端点,严禁把 base64 塞进频道消息 —— 历史上曾导致 buffer 内存飙至 2.3GB。
