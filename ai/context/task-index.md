# 历史任务索引

> `notes/tasks/` 的任务按主题归类。worker 找"这类需求以前做过吗、文档在哪"。
> 格式:任务名 — 状态 — 路径 — 一句话
> 状态说明:done/已完成 / in-progress/进行中 / implemented / design/待实施 / captured/痛点记录 / pain-point

---

## nerve 服务端

**feishu-bridge** — implemented(上线 home) — `notes/tasks/feishu-bridge-20260513/` — 飞书机器人 ↔ nerve 频道桥，用户 @ 机器人即可对话 codex agent，AI 回复发回飞书。

**m10-distributed-nerve** — 重新设计并发版 — `notes/tasks/m10-distributed-nerve/` — M10 ServiceSupervisor + 持久频道成员；mac-clipboard 从 launchd 切到 nerve 托管。

**nerve-mcp-node-spawn-ux-20260429** — proposed — `notes/tasks/nerve-mcp-node-spawn-ux-20260429/` — 通过 MCP 节点创建体验改进，让 AI 直接在聊天窗口 spawn agent。

**nerve-channel** — done — `notes/tasks/nerve-channel/` — 外部 Claude Code 进程通过 MCP 接入 nerve 作为频道节点的使用指南。

**nerve-cli-debug-helpers-20260514** — done(2026-05-14) — `notes/tasks/nerve-cli-debug-helpers-20260514/` — nerve 全功能 CLI（nerve-cli skill），从 debug 子命令扩展到全量 HTTP endpoint 镜像。

**codebase-audit** — done(2026-04-11) — `notes/tasks/codebase-audit/` — 四个子仓库全面代码审计（架构、测试、代码质量、可观测性）。

---

## 程序节点 / 外部桥接

**program-node-feishu-mobile-capture-20260506** — captured — `notes/tasks/program-node-feishu-mobile-capture-20260506/` — AI Work OS 外部系统程序节点与手机端轻量派活的痛点记录与方向。

**duty-monitor-daily-audit-pilot-20260428** — in-progress — `notes/tasks/duty-monitor-daily-audit-pilot-20260428/` — duty-monitor 程序节点每日日报 + 审判试点（定时任务给 AI 发消息、结果进频道）。

**m7-lite-duty-monitor** — design/implemented — `notes/tasks/m7-lite-duty-monitor/` — M7-lite: duty-monitor 定时任务跑通的 spec + smoke 测试结果。

---

## ai-life-log（生活录音与 ASR）

**ai-life-log-20260506** — design — `notes/tasks/ai-life-log-20260506/` — 24/7 本地 ASR 生活记录节点设计：随 nerve 自启、按天滚动、本地 ONNX 推理。

**ai-life-log-watchdog-and-filter** — planned — `notes/tasks/ai-life-log-watchdog-and-filter/` — ai-life-log watchdog 阈值收紧 + transcript 噪音过滤方案。

**mobile-life-log-20260509** — design — `notes/tasks/mobile-life-log-20260509/` — 手机端 24h 生活日志录音设计（与 ai-life-log 服务端配合的客户端侧方案）。

---

## Android 客户端

**android-walkthrough** — in-progress — `notes/tasks/android-walkthrough/` — nerve-app Android 客户端逐项走通任务（背景、进度、交接文档）。

**android-dm-ux-issues-20260518** — captured — `notes/tasks/android-dm-ux-issues-20260518/` — 2026-05-18 手机 DM 截图反馈的 UX 问题（消息无法复制、工具卡片布局）。

**mobile-agent-capture-local-recorder-20260506** — captured — `notes/tasks/mobile-agent-capture-local-recorder-20260506/` — Android 端 agent 创建、图片发送与本地全天录音功能设计。

**mobile-agent-worktree-execution-20260506** — pain-point — `notes/tasks/mobile-agent-worktree-execution-20260506/` — 手机端小需求触发隔离 worktree/分支执行的痛点，暂不实现。

**phone-screenshot-bridge-20260516** — implemented-needs-e2e-validation — `notes/tasks/phone-screenshot-bridge-20260516/` — 手机截图桥：手机截图 → home screenshot plugin → mac-clipboard → Mac 剪贴板同步。

---

## TUI 终端客户端

**tui-visual-upgrade** — spec+plan-done/impl-pending — `notes/tasks/tui-visual-upgrade/` — TUI 视觉体系升级设计（方案 B，output rendering + opencode 对齐）。spec(`opencode-alignment-spec.md`)和 plan(`opencode-alignment-plan.md`)已完成，实现待开始。

**tui-program-node-log-retention** — design — `notes/tasks/tui-program-node-log-retention/` — 程序节点 TUI 视图切换时保留最近日志输出的设计。

---

## 截图调研流水线

**screenshot-triage** — design — `notes/tasks/screenshot-triage/` — 截图调研流水线设计：home 常驻 AI 对新截图做分诊，有价值的派 researcher agent 深入调研。

---

## duty / 监控体系

**duty-orchestration-architecture-20260513** — in-progress — `notes/tasks/duty-orchestration-architecture-20260513/` — duty 编排架构长周期演进任务（M1 已落地，持续演进）。

**duty-system-monitoring-20260514** — captured — `notes/tasks/duty-system-monitoring-20260514/` — duty 系统监控设计（待讨论）：L2 任务级监控，确认 duty 任务是否正确执行。

**system-watchdog-20260514** — deployed(mac + home, 2026-05-14) — `notes/tasks/system-watchdog-20260514/` — system-watchdog L1 系统级节点监控设计，已实际部署到 mac + home 两端。v1 只能检测 hang/leak，看不到被 kill 移除的节点。

**daily-review-personal-team-20260510** — configured — `notes/tasks/daily-review-personal-team-20260510/` — 每日回顾：个人优先 + 团队动态，已配置 duty 任务。

---

## AI 工具 / 开发基础设施

**ai-cli-model-opencode** — design — `notes/tasks/ai-cli-model-opencode/` — AI CLI Model Override + OpenCode Adapter 实现方案（spec + plan）。

**harness-engineering** — in-progress — `notes/tasks/harness-engineering/` — nerve harness 行为清单与工程化，逐步自动化缩小用户验证范围。

**integration-test-infra** — design — `notes/tasks/integration-test-infra/` — 集成测试基础设施：nerve 服务端 + Android 端测试框架建设。

**integration-test-strategy** — design — `notes/tasks/integration-test-strategy/` — 集成测试策略讨论（2026-04-14），分层方案与现状分析。

**collaboration-modes** — ongoing — `notes/tasks/collaboration-modes/` — AI 协作模式记录，对比不同模式效果（Mode A/B/C/D 等）。

**mode-exploration-external** — in-progress — `notes/tasks/mode-exploration-external/` — 外部仓库协作模式探索（2026-04-09）。

---

## 项目知识 / 文档

**project-context-20260519** — in-progress — `notes/tasks/project-context-20260519/` — ai/ 项目上下文管理：建 context/ + 四文件填实（本任务即由此派生）。

**project-knowledge-distillation-20260506** — pain-point — `notes/tasks/project-knowledge-distillation-20260506/` — 从 notes/tasks 沉淀项目开发知识索引的痛点记录（已被 project-context-20260519 接续）。

---

## 战略 / 里程碑规划

**strategy-20260423** — done — `notes/tasks/strategy-20260423/` — 项目战略讨论稿（2026-04-23）：nerve 核心定位确认 + 四条主线排序。

**milestone-discuss** — done — `notes/tasks/milestone-discuss/` — 四条主线排序 + 里程碑建议（Strategist A v2）。

**milestone-roadmap** — in-progress — `notes/tasks/milestone-roadmap/` — 里程碑推进路线 + harness 验证系统专项建设规划。

---

## 分享 / 其他

**share-prep** — done — `notes/tasks/share-prep/` — 项目分享准备（内容已完成：HTML slides + AI 参考资料）。
