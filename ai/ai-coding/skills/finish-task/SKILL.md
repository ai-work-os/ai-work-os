---
name: finish-task
description: Use when an ai-work-os development task is ready to close, needs an MR, needs post-merge cleanup, or the user asks what remains before a task is done.
---

# finish-task

Close the loop for an ai-work-os task. This is the counterpart to `start-task`: use it when implementation is done or the user asks to "收尾 / 发 MR / 合并 / 清 workspace / 看还剩什么".

## Default Flow

1. Pick config by host:
   ```bash
   case "$(uname -s)" in
     Darwin) CONFIG=~/work/ai-work-os/ai/ai-coding/dev-project.mac.json ;;
     Linux)  CONFIG=~/work/ai-work-os/ai/ai-coding/dev-project.json ;;
   esac
   ```
2. Run closeout status:
   ```bash
   finish-task status --config "$CONFIG" --task <id>
   ```
3. For each repo shown:
   - If `DIRTY=yes`: inspect, test, commit.
   - If branch is not pushed: push the task branch to the right remote.
   - If there is no MR: create a GitLab MR to `main`, link the Issue when known.
   - If `MERGED_IN_BASE=no`: do not cleanup yet.
4. After MR is merged, fetch base and cleanup:
   ```bash
   finish-task cleanup --config "$CONFIG" --task <id>
   ```

## Android Release Rule

Do not treat MR merge as Android release. For `nerve-app` release work:
- version bump must already be in `main`;
- GitLab `android_release` publishes from the main pipeline;
- verify `/var/www/html/nerve-app.apk` and `nerve-app-version.json` before saying the phone should see it.

## Report Format

Keep the user-facing summary short:
- MR link or commit hash
- tests run
- release status, if Android
- cleanup status
- any blocker that still needs user choice

## Red Flags

- Do not delete a workspace with dirty files.
- Do not delete a workspace whose HEAD is not merged into configured `remote/base`.
- Do not claim "released" from a successful test pipeline; release requires the publish job/artifacts.
- Do not ask the user to run git/glab commands that this skill can run directly.
