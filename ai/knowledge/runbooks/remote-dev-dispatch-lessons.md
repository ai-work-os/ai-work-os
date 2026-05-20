# remote-dev 派发复盘

> 第一次通过 #ai-work-os dispatcher -> isolated worktree -> worker 跑完整任务后的问题记录。
> 原始 worker 反馈: `~/.nerve/docs/chat-bubble-white-edge-0520-dispatch-feedback.md`

## 背景

- 任务: `chat-bubble-white-edge-0520`
- 需求: 修复 nerve-app Android 聊天界面 assistant Markdown 气泡露白边/白底问题
- worktree: `/home/renjinxi/work/worktree/ai-work-os/chat-bubble-white-edge-0520`
- repo: `nerve-app`, `ai`
- MR: <https://g.ktvsky.com/ai-work-os/nerve-app/-/merge_requests/1>

## 已确认的问题

### worker adapter 过期

`ai/tooling/skills/remote-dev.md` 里 dispatcher playbook 写的是 `adapter=claude`。

实际情况:

- 这个仓库里 Claude worker 路线已经不能用了。
- 当前派发 worker 应使用 `adapter=codex`。

影响:

- dispatcher 第一次按旧 playbook 启了 Claude worker,需要停掉后重启 Codex worker。

待讨论:

- 是否直接把 `remote-dev.md` 的默认 worker adapter 改为 `codex`。
- 是否在 playbook 里加入 "spawn 后确认 node ready + 可响应" 的检查。

### MR target 分支必须明确

本次 MR 默认 target 是 `main`,但当前实际集成分支是 `dev`。

实际情况:

- GitLab `dev`: `70915d4`
- GitLab `main`: `56d2aa9`
- worker 第一次按 MR 默认 target `main` 解冲突,方向错了。
- 后续已改为 rebase 到 `gitlab/dev`,并把 MR target 改为 `dev`。

影响:

- 如果任务卡不写目标分支,worker 容易根据平台默认值做错基线。

建议规则:

- `TASK.md` 必须显式写:
  - target branch
  - base remote branch
  - 是否需要创建/更新 MR
- 当前 ai-work-os 多 repo 开发任务默认应以 `gitlab/dev` 为基线,target `dev`,除非任务卡另写。

### 预侦察必须基于目标分支最新状态

dispatcher 预侦察时记录了旧代码地图:

- "assistant 气泡当前使用 `surfaceVariant`"

但最新 `dev` 上已重构为:

- `MessageBubble` 使用 `Surface`
- assistant 气泡颜色是 `WhiteSurface`
- user 气泡颜色是 `StoneMain`

影响:

- 任务卡里的旧代码地图会误导测试期望和实现方向。
- 本次 worker 后续已调整测试期望为 `WhiteSurface`。

建议规则:

- 预侦察前先确认目标分支/远端。
- 若主仓工作区不是目标分支最新状态,dispatcher 应:
  - 在隔离 worktree 创建后,让 worker 以 worktree 内代码为准再校验代码地图;或
  - dispatcher 在目标分支对应 worktree 中做预侦察。
- 任务卡里的代码地图应标注"基于哪个 commit / branch 观察"。

### Android 测试环境不可用

当前 home/worktree 环境没有 Android SDK 配置。

现象:

- 无 `ANDROID_HOME`
- worktree 无 `local.properties sdk.dir`
- `./gradlew testDebugUnitTest` 在依赖解析前失败
- `./gradlew connectedDebugAndroidTest ...` 也无法进入测试执行

已知相关记录:

- `knowledge/runbooks/home-toolchain.md` 已记录 JDK 21 可用,Android SDK 待装。

影响:

- worker 不能完成真正的 Android 红绿验证。
- 对 Android UI 任务,目前只能做:
  - `git diff --check`
  - 冲突标记扫描
  - 代码审查级验证
  - 提交 MR 后等待有 SDK/真机环境验证

建议规则:

- Android 任务卡必须注明当前验证能力:
  - SDK 是否预期可用
  - 是否需要真机验证
  - 若 SDK 不可用,允许 worker 报告 blocked,不要伪造红绿测试结果
- 补齐 home Android SDK 后,更新 `knowledge/runbooks/home-toolchain.md`。

## 本次最终状态

- Branch: `task/chat-bubble-white-edge-0520`
- Commit: `94ae5f6 Fix assistant markdown bubble background`
- MR target: `dev`
- Base: `gitlab/dev` (`70915d4`)
- GitLab: `has_conflicts=false`, `merge_status=can_be_merged`

## 后续要固化到 playbook 的候选项

等讨论确认后,再更新 `ai/tooling/skills/remote-dev.md`:

1. dispatcher 默认 spawn `adapter=codex`。
2. `TASK.md` 模板增加 target branch / base remote branch / MR target。
3. dispatcher 预侦察必须基于目标分支最新代码,并在任务卡标注观察基线。
4. Android 项目任务卡必须写清验证能力和 SDK/真机限制。
5. worker 回报里必须包含:
   - branch
   - commit
   - MR target
   - base commit
   - conflict status
   - tests run / blocked reason

