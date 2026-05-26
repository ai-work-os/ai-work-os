# skill: remote-dev — home dispatcher 触发的任务

> 跟 [start-task](./start-task/SKILL.md) 是**同一套流程**,只是触发方在手机端 nerve-app(通过 home 常驻 dispatcher 转发)。
> dispatcher 走 start-task 的三件事(澄清 / 预侦察 / 建 worktree + 填 TASK.md)。
> **下面只列 dispatcher 跟 start-task 不同的地方**。

## dispatcher 角色差异

- **cwd 在主仓库**(`~/work/ai-work-os/`,home 上是 `/home/renjinxi/work/ai-work-os/`),不在 worktree。
- 收到需求来自频道消息(不是当前 cwd 的 user),澄清通过 `nerve_post` 在频道反问。
- **不自己进 worktree 干活,而是 spawn worker**:
  ```
  nerve_spawn --adapter claude --name worker-<id> \
              --cwd <worktree_root>/<id>/<主repo> \
              --channel_id <当前频道>
  ```
  worker 在新 cwd 启动,会自动加载 AGENTS.md → 自动看到 TASK.md → 自己开干。
  **dispatcher 不需要给 worker 发"你要读 X / 读 Y"指令**(AI 工具自动)。
  唯一需要发的:`nerve_dm worker-<id> "开干,完了 push 分支 task/<id> 在频道回报"`。
- **worker 回报后**:转达给用户、确认无误后 `nerve_remove worker-<id>` 清掉。

## 配置

home 用 `dev-project.json`(repos_root=`/home/...`,base=dev/main 见配置)。

## 铁律

- 默认不自动 merge,只推分支 / MR,等用户 review。
- 清理是 dispatcher 的事(不留 idle agent)。
