# ai-coding/ — AI 工具配置真相源

本目录是 ai-work-os **AI 编码工具配置的项目级真相源**(skills / 工具脚本 / 平台配置)。
原则:真身在这里、git 管;`~/.claude/skills` 和 `~/.codex/skills` 用软链指过来。

## 目录

```
ai-coding/
├── README.md                     # 本文件
├── skills/                       # skill 真身(目录形式,每个含 SKILL.md)
│   ├── start-task/SKILL.md       # 任务环境创建(Mac/home 自动按当前 host 选配置)
│   ├── finish-task/SKILL.md      # 任务收尾(MR / release / cleanup 闭环)
│   ├── nerve-server.md           # nerve 服务管理(文件形式,文档不是注册 skill)
│   └── remote-dev.md             # dispatcher/worker playbook(同上)
├── worktree-task/                # 多仓 Workspace 创建工具(bash 脚本;底层 git worktree)
├── finish-task/                  # 任务收尾状态/清理工具(bash 脚本)
├── dev-project.json              # home/Linux 平台配置(repos_root=/home/...,remote/base)
├── dev-project.mac.json          # Mac/Darwin 平台配置(repos_root=/Users/...,remote/base)
├── dev-project.example.json      # 示例
├── dispatcher-prompt.md          # home dispatcher 角色 prompt
└── remote-dev-flow.md            # 全流程设计
```

## 注册形 skill vs 文档形 skill

| 类型 | 长啥样 | 怎么被发现 |
|---|---|---|
| **注册形** | `skills/<name>/SKILL.md` + 可选资源 | 软链到 `~/.claude/skills/` `~/.codex/skills/` 后,Claude/Codex 在 skill 列表里直接看到 |
| **文档形** | `skills/<name>.md` 单文件 | 不在 skill 列表,但被其他 skill / prompt 引用(如 dispatcher prompt 引用 `remote-dev.md`) |

新建注册形 skill 时:

1. 真身写在 `skills/<name>/SKILL.md`(目录形式)
2. 软链:
   ```bash
   SKILL_REAL=~/work/ai-work-os/ai/ai-coding/skills/<name>
   ln -sfn "$SKILL_REAL" ~/.claude/skills/<name>
   ln -sfn "$SKILL_REAL" ~/.codex/skills/<name>
   ```
3. SKILL.md frontmatter 用 "Use when ..." 第三人称描述,不要把 workflow 塞进描述

## 运行环境识别

任何涉及路径、remote、部署、运维对象的动作,先判定当前 host:

```bash
uname -s
hostname
pwd
```

- Darwin = Mac 本机,路径用 `/Users/renjinxi/...`,操作 home 才需要 `ssh home`。
- Linux + `/home/renjinxi/...` = home 本机,不要再 `ssh home`,直接执行 user-level systemd / 本地路径命令。
- 手机触发的 dispatcher/worker 常驻 home,不要假设自己在 Mac。

## 双平台配置策略

`worktree-task` 用 JSON 配置决定 `repos_root` / `worktree_root` / 各 repo 远端基线。对人和流程层统一叫 Workspace;`worktree_root` 是历史配置字段和 git 底层实现名。
Mac 和 home 路径不同,所以分两份;基线都显式写 remote/base:

| 文件 | 平台 | 路径前缀 | 基线 |
|---|---|---|---|
| `dev-project.json` | home(Linux) | `/home/renjinxi/...` | root `gitlab/main`,子仓 `origin/main` |
| `dev-project.mac.json` | Mac(Darwin) | `/Users/renjinxi/...` | root `gitlab/main`,子仓 `origin/main` |

`start-task` 做代码地图预侦察前,必须先把本次涉及的主工作区同步到 `main` 最新状态:工作区干净才允许 `git switch main`,再 `git fetch --all --prune && git pull --ff-only`。如果 dirty、非 fast-forward、或仍看到 `dev` 分支残留,先停下来说明,不要用旧 checkout 预侦察。

`worktree-task create` 会先 fetch 配置的 remote/base,再从远端最新 commit 建 Workspace,并把 baseline 写进 TASK.md。主工作区同步是为了预侦察不落后;任务分支仍以 `worktree-task` 写入的 remote/base 为准。

## A+B 档交付流程

- A 档(日常开发):GitLab Issue 入口 → 主工作区同步检查 → baseline Workspace → worker 实现测试 → GitLab MR 关联 Issue → main 保护分支默认只经 MR 合并。
- 授权直推档:仅限低风险 docs/refactor/chore 且 TASK.md 明确写 `交付模式: 授权直推 main`。worker 必须验证、提交、必要时 rebase、推配置 remote/base,再报告 commit hash。主 agent 事后抽样审计,不是必经 merge gate。
- B 档(合并后):GitHub 只是镜像同步;部署/重启按当前 host 执行;Android release 独立于 MR 合并,需单独 bump/build/publish。
- 收尾统一走 `finish-task` skill:任务合入或授权直推完成后,当轮就跑 `finish-task complete --config "$CONFIG" --task <id>`。它会先打印 status,再在 clean 且 `MERGED_IN_BASE=yes` 时清理 Workspace。不要等用户另行提醒清 Workspace。

## 工具装机

```bash
# worktree-task 进 PATH(已是 ~/.local/bin 软链)
ln -sfn ~/work/ai-work-os/ai/ai-coding/worktree-task/worktree-task ~/.local/bin/worktree-task

# finish-task 进 PATH
ln -sfn ~/work/ai-work-os/ai/ai-coding/finish-task/finish-task ~/.local/bin/finish-task

# 软链所有 skill 进 Claude/Codex
for skill in ~/work/ai-work-os/ai/ai-coding/skills/*/; do
  name=$(basename "$skill")
  ln -sfn "$skill" ~/.claude/skills/"$name"
  ln -sfn "$skill" ~/.codex/skills/"$name"
done
```

## 演进规则

- 新 skill 一律先进 `ai-coding/skills/`,**别再单独写到 `~/.claude/skills/`**(会丢、不进 git、机器间不同步)
- 配置/工具改完同步 home(home 上根仓库 `~/work/ai-work-os/` `git pull` 即可)
- skill 真身改了就立即生效(软链穿透),不需要重装
