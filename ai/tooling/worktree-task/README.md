# worktree-task

多仓库任务工作区管理 —— 非交互、项目无关、读 JSON 配置。

远程开发流程的"机械手":把一个任务切成一组隔离 git worktree。
公用引擎一个,每个项目一份 `dev-project.json` 配置。

## 用法

```bash
worktree-task create --config <p> --task <id> --repos <r1,r2>   # 建任务工作区
worktree-task list   --config <p>                               # 列出任务工作区
worktree-task remove --config <p> --task <id>                   # 删除任务工作区
```

`create` 会:

- 在 `<worktree_root>/<task-id>/` 下,为每个 repo `git worktree add` 一个 worktree,
  分支 `task/<task-id>`,从该 repo 配置的基线分支切出。
- 在任务根目录写一份 `TASK.md` 骨架(freestanding,不进 git,由 dispatcher 填)。

## 配置 `dev-project.json`

```json
{
  "project": "项目名",
  "repos_root": "各 git 仓库所在的父目录",
  "worktree_root": "任务工作区根目录",
  "repos": {
    "<repo 名>": { "base": "基线分支" }
  }
}
```

示例见 `dev-project.example.json`。

## 测试

```bash
bash test/run.sh
```

隔离 sandbox(临时目录 + 一次性 git repo),每个用例独立。
