# 隔离 worktree 开发流程

不论从哪触发(Mac 直接 / 手机 → 频道 dispatcher),都走 [start-task skill](skills/start-task/SKILL.md),产出同一种 worktree。

先识别当前运行环境:

```bash
uname -s
hostname
pwd
```

当前在 Mac(Darwin) 时使用 `dev-project.mac.json`;当前在 home(Linux) 时使用 `dev-project.json`。home 本机执行时不要再 `ssh home`;只有 Mac 上操作 home 服务才把 home 当远端。

## 产出结构(跟主仓库 100% 镜像)

```
<worktree_root>/<task-id>/
├── AGENTS.md / CLAUDE.md    ← 根仓库 worktree 顶层
├── ai/                       ← 项目知识
├── TASK.md                   ← 任务卡(AGENTS.md 顶部引导自动读)
├── nerve/                    ← 三个代码仓 worktree(分支 <type>/<id>)
├── nerve-app/
└── nerve-tui/
```

worker 启动 / spawn / 调度由 nerve scene 配置处理,不在本流程范围。

## A 档:日常开发闭环

A 档是默认开发流程,只处理"从需求到 MR 合并"。

1. GitLab Issue 是入口:用户给 Issue 就关联;没给就 TASK.md 标 `Issue: <待创建/待关联>`。
2. `start-task` 澄清需求后先做主工作区同步检查,再做 baseline preflight;代码地图预侦察不得基于旧 checkout。
3. `worktree-task create` 从配置 remote/base 最新 commit 建 worktree。
4. worker 在任务 worktree 内改代码、跑测试、提交分支。
5. MR 是交付出口:推到 GitLab 后创建 MR,MR 关联 Issue,让看板跟 Issue/MR 状态走。
6. `main` 受保护:不要直接 push main,通过 MR review/merge 进入 main。

## 授权直推档:低风险 worker 自主交付

默认仍走 A 档 MR。只有 TASK.md 明确写 `交付模式: 授权直推 main` 时,worker 才能绕过 MR gate 直接交付。适用范围限低风险 docs/refactor/chore,例如文档补充、无行为变化的小重构、清理已确认的临时文件。

worker 必须满足:

1. 任务卡验收标准全部完成。
2. 相关测试或验证命令通过;纯文档任务至少跑格式/链接/状态检查里可用的一项。
3. worktree clean,提交信息清楚。
4. 推送前 fetch/rebase 到配置的 remote/base;冲突、测试失败、非快进或不确定影响面时停止并改走 MR/主 agent 审查。
5. 推送配置里的目标基线:root 是 `gitlab/main`,子仓默认 `origin/main`;需要镜像同步时按任务卡或收尾流程处理。
6. 频道报告 commit hash、验证命令、是否已清理 workspace。

主 agent 对授权直推任务做事后抽样审计,不再作为每次 merge 的必经 gate。

## B 档:合并后同步与发布

B 档只在 A 档完成后发生,不要混进普通开发任务。

1. GitHub 是镜像:GitLab main 合并后再同步到 GitHub,不要把 GitHub 当工作入口。
2. 合并后的部署/重启按 `ai/context/playbook.md` 的当前 host 规则执行。
3. Android release 独立于 MR 合并:需要发版时单独 bump `versionCode` / `versionName`,构建 APK,发布到 home nginx,更新版本 JSON。
4. Android 功能修复合入 main 不等于已发布到手机;只有 release 流程完成才算手机可更新。

## 铁律

- 默认不自动 merge,只推分支 `<type>/<id>` 等 review;授权直推必须写在 TASK.md。
- TASK.md / plan.md / progress.md 是任务工作区临时文件,留在 worktree 顶层,**不进 git**。
- 任务合入或授权直推完成后立即收尾:先 `finish-task status`,确认 clean 且已进入配置 remote/base,再 `finish-task cleanup`。不要等用户另行提醒。
