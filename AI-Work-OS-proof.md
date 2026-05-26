# AI Work OS 项目证明

## 项目简介

AI Work OS 是我正在构建的多 Agent 协作系统，核心目标是把“人与单个 AI 对话”升级成“人调度一组 AI 长期协作”。系统以 `nerve` server 为运行时，连接终端 TUI、Android 客户端、MCP 工具和多个 AI agent，实现 agent 启停、DM、频道协作、消息路由、任务调度、日志记录和可回放验证。

## 已实现能力

- `nerve` 服务端：TypeScript 实现，负责 agent 进程管理、WebSocket JSON-RPC、消息路由、频道、DM、插件、MCP 工具和测试 harness。
- `nerve-tui` 终端客户端：Rust + ratatui 实现，支持 DM、频道协作、流式输出、Markdown 渲染、工具调用展示、滚动、分屏观察和中断 agent。
- `nerve-app` Android 客户端：Kotlin + Jetpack Compose 实现，支持连接 server、查看节点、DM、频道消息、spawn/stop agent。
- 程序节点：包括 context-guardian、user-recorder、duty-monitor、ai-ear 等，用于上下文守护、协作记录、定时值守和会议转录。
- 多 Agent 协作模式：已验证 tester/coder/reviewer 管线、测试先审、sub-main 调度 worker 等模式。

## 工程规模

- `nerve`：85 个提交，服务端核心与测试体系。
- `nerve-tui`：89 个提交，终端主控台。
- `nerve-app`：9 个提交，新 Android 主线。
- `nerve-android`：7 个提交，旧 Android 客户端参考实现。

## 代表性提交

- `feat: duty-monitor 动态任务管理 + auto-spawn (M7-lite)`
- `feat: plugin-base 内置事件订阅系统（subscribe/unsubscribe/emit）`
- `feat: support spawn model override`
- `fix: retain program node logs for replay`
- `feat(tui): improve summary_mode — show code blocks and tool summaries`
- `feat: DM 全链路 streaming 支持 + thinking/tool_call + UI 改进`
- `feat(test): add integration test infrastructure with random port + auto cleanup`

## 价值说明

这个项目不是简单的聊天壳或 prompt demo，而是围绕真实开发工作流构建的 Agent runtime。它把 AI 的能力接入可观察、可调度、可验证的工程系统中，让 AI 能主动发现任务、执行、协作、汇报和接受验收。我的重点不是让 AI 写一段代码，而是构建一套能长期驱动 AI 工作的基础设施。
