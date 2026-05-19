# 约定与坑

> 稳定约定 + 常见坑。worker 动手前先读。

## 稳定约定

### 仓库结构与 git 流程

- **多仓结构:** nerve / nerve-app / nerve-tui / notes 是四个独立 git 仓库,各自有 `.git`。`worktree/` 下是 git worktree(`.git` 是指针文件),不是手动复制目录。
- **开发在 worktree dev 分支,不在主仓库改代码**。提交: `git -C ~/work/worktree/ai-work-os/nerve commit`。合并到 main: `git -C ~/work/ai-work-os/nerve merge dev`。
- **双 remote push(nerve):** nerve 仓配了两个 remote — `origin`(GitHub) + `gitlab`(公司 GitLab)。推送必须两个都推,不能漏。`git push origin main && git push gitlab main`。
- commit 时若 hook 报错,需要 `GVM_ROOT="" git commit ...`。

### 测试规则

- **永远在 worktree dev 分支测试**,不在主分支测未验证改动。
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

### 演进原则

- **先搭骨架后演进**:遇到卡点才加内容,空目录是合法状态。不要"为了完整性"一次铺满。
- **不要顺手扩 scope**:只做用户明确指出的范围。
- **task 完成产生固有知识 → 更新进 `context/` 对应文件**。

### 工程规范

- nerve 服务端:关键路径必须有日志,新增/修改模块必须有测试。
- 程序节点输出:关键状态写 DM 视图(node.log),业务动作走频道(channel.post)—— 两条路互不干扰。

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

nerve `PluginBase`(外部插件客户端)原本无心跳。机器睡眠/网络抖动后客户端那侧不收到 `close` 事件 → 重连不触发 → 插件卡死 offline。
修复(commit `e561f5c`,2026-05-18 在 dev 分支):PluginBase 客户端 + server 端双向心跳。**未发版前:**插件卡 offline 手动 `pkill -f <plugin-path>`,ServiceSupervisor 会重拉。

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
