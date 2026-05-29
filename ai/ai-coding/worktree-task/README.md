# worktree-task

多仓库任务工作区管理 —— 非交互、项目无关、读 JSON 配置。

远程开发流程的"机械手":把一个任务切成一组隔离 Workspace。底层仍使用 git worktree。
公用引擎一个,每个项目一份 `dev-project.json` 配置。

## 用法

```bash
worktree-task create --config <p> --task <id> --repos <r1,r2>   # 建任务工作区
worktree-task list   --config <p>                               # 列出任务工作区
worktree-task remove --config <p> --task <id>                   # 删除任务工作区
```

`create` 会:

- 在 `<workspace_root>/<task-id>/` 下,为每个 repo `git worktree add` 一个 git worktree,
  分支 `<type>/<task-id>`(默认 `feat/<task-id>`),从该 repo 配置的远端基线最新 commit 切出。
- 创建前对每个 repo 执行 fetch,刷新配置的 `remote/base`,不会静默使用可能落后的本地分支。
- 在任务根目录写一份 `TASK.md` 骨架(freestanding,不进 git,由 dispatcher 填),并记录每个 repo 的 baseline `repo: remote/base @ commit`。

## 配置 `dev-project.json`

```json
{
  "project": "项目名",
  "repos_root": "各 git 仓库所在的父目录",
  "workspace_root": "任务 Workspace 根目录",
  "repos": {
    "<repo 名>": { "base": "基线分支", "remote": "远端名" }
  }
}
```

`remote` 可省略:root repo(`path: "."`)会优先从本地 `base` 分支 upstream 推断,其他 repo 默认 `origin`。ai-work-os 的正式配置应显式写明 remote。旧字段 `worktree_root` 仍兼容,但新配置统一使用 `workspace_root`。

示例见 `dev-project.example.json`。

## 测试

```bash
test/run.sh
```

隔离 sandbox(临时目录 + 一次性 git repo),每个用例独立。
