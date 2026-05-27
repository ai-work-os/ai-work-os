---
name: nerve-server
description: ai-work-os 项目的本地管理脚本（~/.local/bin/nerve-server）。封装服务启停、3 个子项目构建、本地/远端安装、Android 发版、home 远端部署。AI 写跟"启动/构建/发版/部署"相关的代码或回答相关问题时优先用这个命令而不是手撕 npm/cargo/gradle/ssh。
---

# nerve-server skill

ai-work-os 的"瑞士军刀" — 服务管理 + 跨 3 个子项目的 build/install/deploy + Android 发版。脚本路径 `~/.local/bin/nerve-server`，shell 全局可用。

---

## 一图看懂

```
nerve-server <command> [args]

服务管理:
  start | stop | restart | status | log

构建:
  build [nerve|tui|android|all]

本地安装:
  install <tui|android>

home 构建+安装（Mac 上通过 ssh home;home 本机直接执行）:
  install-remote <tui>

Android 发版（home nginx）:
  publish-android [notes]

home 部署（Mac 上通过 ssh home + systemctl restart;home 本机直接执行等价步骤）:
  deploy [nerve|tui|all]
```

---

## 命令详解

### 当前 host 判定

启动、部署、发版前先执行:

```bash
uname -s
hostname
pwd
```

- Darwin = Mac 本机:本地 `nerve-server start/restart` 管 Mac 进程;操作 home 才用 `ssh home` 或 `nerve-server deploy`。
- Linux + `/home/renjinxi/...` = home 本机:不要再 `ssh home`;直接按 deploy 等价步骤在本机执行 `git pull` / build / `systemctl --user restart nerve`。

### 服务管理（管当前本机的 nerve 进程）

| 命令 | 干什么 |
|---|---|
| `nerve-server start` | 启当前本机 nerve（端口 4800），写 pid 到 `~/.nerve/server.pid` |
| `nerve-server stop` | 杀 nerve（按 pid + 端口） |
| `nerve-server restart` | stop + start，老进程清干净再起新的 |
| `nerve-server status` | 看是不是在跑、pid、端口 |
| `nerve-server log` | `tail -f ~/.nerve/nerve.log` |

**注意**：home 上的生产 nerve 是 user-level systemd（`systemctl --user restart nerve`）。如果当前就在 home 本机,直接用 user-level systemd;如果当前在 Mac,home 部署用 `nerve-server deploy nerve`。

### 构建

| 命令 | 干什么 |
|---|---|
| `nerve-server build` 或 `... all` | nerve（tsc）+ tui（cargo release）+ android（assembleDebug） |
| `nerve-server build nerve` | `cd ~/work/ai-work-os/nerve && npm run build` |
| `nerve-server build tui` | `cd ~/work/ai-work-os/nerve-tui && cargo build --release` |
| `nerve-server build android` | `cd <ANDROID_DIR> && ./gradlew :app:assembleDebug` |

**注**：build 默认走 **主仓库**（`~/work/ai-work-os/`），不是 worktree。如果你在 worktree 改了代码想构建，要么先合到 main、要么 `cd worktree && ./gradlew ...` 自己跑。

### 本地安装

| 命令 | 干什么 |
|---|---|
| `nerve-server install tui` | build + `cargo install --path .` 到 `~/.cargo/bin/nerve-tui` |
| `nerve-server install android` | build + `adb install -r app-debug.apk` 到当前 USB 手机 |

### home 构建+安装

| 命令 | 干什么 |
|---|---|
| `nerve-server install-remote tui` | Mac 上 ssh home → git pull + cargo install;home 本机按等价命令直接执行 |

### Android 发版（**最常用**）

```
nerve-server publish-android [notes]
```

4 步：
1. `cd <ANDROID_DIR> && ./gradlew :app:assembleDebug`
2. rsync `app-debug.apk` 到 `home:/tmp/nerve-app.apk`（自带重试 8 次，60s server alive）
3. Mac 上 ssh home 执行 `sudo cp /tmp/nerve-app.apk /var/www/html/nerve-app.apk`;home 本机直接执行 copy
4. 写 `nerve-app-version.json` 到 nginx（手机端 auto-update 看这个）

`versionCode / versionName` 自动从 `app/build.gradle.kts` 读。`notes` 是 UI 横幅文案，可空则默认 `v<versionName>`。

签名 key 不要进 git。固定发版 key 推荐放:

```bash
~/.nerve/secrets/nerve-app-release.jks
```

并通过环境变量传给 `publish-android`:

```bash
export NERVE_ANDROID_KEYSTORE="$HOME/.nerve/secrets/nerve-app-release.jks"
export NERVE_ANDROID_KEYSTORE_PASSWORD="..."
export NERVE_ANDROID_KEY_ALIAS="nerve-app"
export NERVE_ANDROID_KEY_PASSWORD="..."
```

如果没有设置这些变量,`assembleDebug` 会使用当前机器的 debug keystore。不同机器 debug keystore 不同,会导致手机端覆盖安装失败。切换到正式 release key 时,现有 debug 签名包需要在手机上卸载一次。

**用之前必须先 bump versionCode**（feedback `feedback_android_publish_default`：完工默认 bump + publish）：
```bash
# 改 app/build.gradle.kts 里
versionCode = N+1
versionName = "0.5.X"
git commit -am "release(android): bump versionCode N→N+1 / versionName 0.5.X — 说明"
nerve-server publish-android "说明"
```

**慢/卡住调试**：rsync 60MB 走 tailscale 通常 2-5 分钟。如果 30 分钟没完成，看是不是走了 DERP relay（`tailscale status` 看 `direct` vs `via DERP`）。

### 远端部署（home 上的服务更新）

```
nerve-server deploy [nerve|tui|all]
```

- `deploy nerve`：Mac 上 ssh home → `cd nerve && git pull origin main && npm install && npm run build && systemctl --user restart nerve`
- `deploy tui`：Mac 上 ssh home → 同上但 cargo
- `deploy` 或 `... all`：两个都做

home 上的 nerve 是 **user-level systemd**（详见 `ai/context/playbook.md`）—— 当前在 home 本机时不要 `ssh home`,直接执行等价步骤,且 **不要 sudo systemctl**。

---

## 环境变量

| 变量 | 默认 | 用 |
|---|---|---|
| `NERVE_ANDROID_DIR` | `~/work/worktree/ai-work-os/nerve-app` | 改 Android 构建源 |
| `NERVE_PUBLISH_HOST` | `home` (ssh alias) | 改 publish 目标机器 |
| `NERVE_PUBLISH_ROOT` | `/var/www/html` | 改 nginx 路径 |
| `NERVE_PUBLISH_IP` | — | version.json url 用 |

---

## AI 怎么用这个 skill

写代码 / 处理需求时遇到下列场景，**先想 nerve-server**：

| 用户说 / 任务里看到 | 用 | 不要 |
|---|---|---|
| "重启 nerve" / "nerve 启动失败" | `nerve-server restart` | 手动 `npx tsx src/cli.ts serve` 不清旧进程 |
| "看 nerve 日志" | `nerve-server log` | 手动 tail |
| "把 Android 发版" / "更新 APK" / "手机看到新版" | bump versionCode → `nerve-server publish-android "notes"` | 手动 gradle + rsync + ssh |
| "home 上的 nerve 怎么更新" | `nerve-server deploy nerve` | 手动 ssh + git pull + build + systemctl |
| "tui 安装到 home" | `nerve-server install-remote tui` | 手动 ssh + cargo |
| "构建 Android APK 不发版" | `nerve-server build android` | 手动 cd + gradlew |

**只有 `nerve-server` 不覆盖的场景才手撕**（比如改 systemd unit / drop-in env，那些没封装）。

---

## 关联文档

- 服务在 home 上的部署结构 / systemd 细节 → `ai/runbooks/home-deploy.md`
- 部署过程踩过的坑历史 → `ai/runbooks/home-deploy.md` 末尾"不要踩的坑"
- Android 自动更新机制 → memory `project_android_auto_update`
- APK 发版的默认行为 → memory `feedback_android_publish_default`（"完工默认 bump + publish"）
