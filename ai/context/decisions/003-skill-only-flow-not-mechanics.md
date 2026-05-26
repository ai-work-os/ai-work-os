# ADR 003 — skill 只写流程,不写运行机制

**日期**:2026-05-26
**状态**:已落地

## 背景

第一版 `start-task` skill / `remote-dev.md` 里写了大量 worker 启动机制 ——
`nerve_spawn --adapter claude --cwd ... --channel_id ...`、"用户在新窗口开
Claude Code"、"worker 读 ../AGENTS.md" 等。

实战发现这些**全是废话**:
- AI 工具自己会找 `CLAUDE.md` / `AGENTS.md` 自动加载,不用 skill 写
- worker 启动用什么 adapter / cwd / channel,是 **scene 配置**(`~/.nerve/scenes/`)决定的,不是 skill 决定的
- 手机端 dispatcher 用 codex、Mac 端用 Claude Code,工具是会变的;文档里写死会过时

## 决定

**skill 只写**:
- 触发条件(何时调用 skill)
- 判断标准(怎么做对/做错)
- 流程产出(skill 跑完该有什么物质产出,如 TASK.md / worktree)
- 用到的项目工具命令(如 `worktree-task create`)

**skill 不写**:
- worker / agent 用什么 AI 工具(adapter / 模型 / 平台)
- worker 启动方式(nerve_spawn / 新窗口手开 / hook 触发)
- worker 自动加载的入口文件(`AGENTS.md` / `CLAUDE.md`)它"应该读什么"
- 跟具体 nerve 节点 / channel / scene 名挂钩的细节

## 为什么

- **可移植**:同一份 skill 在 Mac / home / 未来其他机器都能用,因为它不依赖某个具体运行环境
- **可解耦**:nerve scene 配置改了(换 adapter / 加节点),不需要改 skill
- **AI 工具能力外延**:Claude Code / Codex / Cursor 都自动读约定文件名,文档"教 worker 读 X"是侮辱 AI 工具

## 边界

**例外:`dispatcher-prompt.md`** —— 这本身就是 scene 配置的内容(注入 home `~/.nerve/scenes/ai-work-os.json` 的 `on_ready`),它属于"运行机制"层,不是 skill。但**它也应该尽量精简**,只说"走 start-task skill"。

## 拒绝的替代方案

| 方案 | 拒绝理由 |
|---|---|
| skill 里写 "worker 用 claude adapter" | 手机端 dispatcher 用 codex,Mac 端用啥都行,写死会错 |
| skill 里写 "worker 启动后读 ../AGENTS.md" | AI 工具自动加载,重复指令污染 system prompt |
| skill 里写完整 nerve_spawn 命令 | scene 配置的事,skill 不该管 |

## 代价

- skill 文档变短(其实是好事)
- 新人/AI 第一次接触流程,不知道 worker 怎么起 → 这是 scene 配置 / playbook 该回答的
- 流程文档(`remote-dev-flow.md`)只描述产出,不描述触发链,有人会感到"跳"

## 关联

- 实施:commit `33a3480`(skill 砍掉运行机制,删 `skills/remote-dev.md`)
- 触发本 ADR 的反思:用户骂了一次"这 skill 写的完全不知道这项目怎么干活"
