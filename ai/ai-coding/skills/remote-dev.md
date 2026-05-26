# skill: remote-dev — 手机发起的隔离 worktree 开发

> 远程开发流程的可执行 playbook。dispatcher 与 worker 各按自己那段走。
> 设计见 `knowledge/specs/remote-dev-flow.md`。

## 角色:dispatcher(常驻 agent,cwd 在主仓库)

只派活、不写代码。收到一个开发需求时:

1. **澄清** —— 在频道反问,直到需求具体到能写验收标准。
2. **判定** —— 是代码任务吗?哪个项目?涉及哪些 repo?不是代码任务就正常回答,不走本流程。
3. **任务 id** —— 取 `<简短英文描述>-<MMDD>`,如 `retry-logic-0519`。
4. **预侦察** —— 在主仓库里读相关代码,定位要改的文件、入口函数、参考实现、要避开的坑。
5. **建隔离区**(在 shell 里跑;路径已正确):
   ```
   # 平台自动选:Mac 用 .mac.json,home 用 .json
   case "$(uname -s)" in
     Darwin) CONFIG=~/work/ai-work-os/ai/ai-coding/dev-project.mac.json ;;
     Linux)  CONFIG=~/work/ai-work-os/ai/ai-coding/dev-project.json ;;
   esac
   worktree-task create --config "$CONFIG" --task <id> --repos <涉及的repo>
   ```
   不要带 `ai` —— `ai/` 是根仓库子目录,worker 直接读 `~/work/ai-work-os/AGENTS.md` 拿上下文。
6. **填任务卡** —— 编辑 `<worktree_root>/<id>/TASK.md`:需求、验收标准、第 4 步的代码地图。
7. **spawn worker** —— 用 `nerve_spawn` 工具:`adapter`=`claude`、`name`=`worker-<id>`、
   `cwd`=`<worktree_root>/<id>/<主repo>`、`channel_id`=当前频道。然后用 `nerve_dm`
   给 `worker-<id>` 发起始指令:
   > 你是 worker。先读 `../TASK.md`(任务卡)和 `~/work/ai-work-os/AGENTS.md`(根仓库项目入口),
   > 按 `CLAUDE.md` 的 TDD 铁律执行;完成后 push 分支 `task/<id>` 并在频道回报。
8. **转达 + 收尾** —— worker 回报后转达给 renjinxi;确认无误后用 `nerve_remove`
   清掉 `worker-<id>`,不留 idle agent。

## 角色:worker(一次性 agent,cwd 在 worktree)

1. **装上下文** —— 读 `../TASK.md`(任务卡)+ `~/work/ai-work-os/AGENTS.md`(根仓库项目入口)+ `CLAUDE.md`(铁律)。
2. **TDD** —— 先写失败测试 → 看红 → 最小实现 → 看绿 → 重构。改 nerve 用测试端口 4801。
3. **验证** —— 跑全量 build + test + lint,按 `CLAUDE.md` 完成验证清单逐项卡门。
4. **提交** —— commit(附改动说明);push 分支 `task/<id>`(nerve 双 remote 都推)。必要时建 MR。
5. **收尾沉淀** —— 把这次"确认有效"的踩坑/规范写回 `ai/knowledge/`(过滤器,不是水龙头)。
6. **回报** —— 用 `nerve_post` 在频道回报:分支、commits、测试结果、MR、待确认项。
   报完即停手,不必自退 —— 由 dispatcher `nerve_remove` 清理(清理是 lead 的事)。

## 铁律

- 默认不自动 merge,只推分支 / MR,等 renjinxi review。
- 没有失败测试不写生产代码。没有测试的代码不算完成。
- 任务卡(`TASK.md`/`plan.md`/`progress.md`)是临时的,留在 worktree 根,不进 git。
