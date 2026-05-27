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
├── worktree-task/                # 多仓 worktree 创建工具(bash 脚本)
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

`worktree-task` 用 JSON 配置决定 `repos_root` / `worktree_root` / 各 repo 远端基线。
Mac 和 home 路径不同,所以分两份;基线都显式写 remote/base:

| 文件 | 平台 | 路径前缀 | 基线 |
|---|---|---|---|
| `dev-project.json` | home(Linux) | `/home/renjinxi/...` | root `gitlab/main`,子仓 `origin/main` |
| `dev-project.mac.json` | Mac(Darwin) | `/Users/renjinxi/...` | root `gitlab/main`,子仓 `origin/main` |

`worktree-task create` 会先 fetch 配置的 remote/base,再从远端最新 commit 建 worktree,并把 baseline 写进 TASK.md。

## A+B 档交付流程

- A 档(日常开发):GitLab Issue 入口 → baseline worktree → worker 实现测试 → GitLab MR 关联 Issue → main 保护分支只经 MR 合并。
- B 档(合并后):GitHub 只是镜像同步;部署/重启按当前 host 执行;Android release 独立于 MR 合并,需单独 bump/build/publish。
- 收尾统一走 `finish-task` skill:先 `finish-task status`,确认 dirty/MR/release/merge 状态;合入后再 `finish-task cleanup` 清理任务工作区。

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
