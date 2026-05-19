# 操作手册

> 各仓库怎么跑/构建/测试/发版,home 怎么运维。不装一次性排查流水。

## 各仓库:跑 / 构建 / 测试
<!-- Phase 2 填 -->

## 测试规则
<!-- Phase 2 填:在 worktree dev 分支跑、4801 端口、不在主分支测 -->

## nerve 重启 / 发版 / 部署
<!-- Phase 2 填 -->

## Android 发版
<!-- Phase 2 填:publish-android -->

## home 运维

> Home: Linux x86_64 / 8 核 / 14GB / AMD Vega 集显（无独立 GPU）
> ssh alias: `home`
> tailscale ip: `100.75.43.90`

### 关键：服务用 user-level systemd（不是 system-level）

`/etc/systemd/system/nerve.service` 也存在但是 **inactive (dead) 且 disabled**，不要碰。

**所有 home 服务都在 user-level**：

```
~/.config/systemd/user/nerve.service                # Nerve 主服务
~/.config/systemd/user/nerve-log-collector.service  # nerve-app 远程日志收集器
```

管理命令必须带 `--user`：

```bash
systemctl --user list-units --type=service       # 看在跑啥
systemctl --user status nerve                    # 服务状态
systemctl --user restart nerve                   # 重启
systemctl --user daemon-reload                   # 改 unit/drop-in 后必须 reload
systemctl --user cat nerve                       # 看完整 unit + 所有 drop-in
journalctl --user -u nerve -n 100                # service stdout / stderr
```

**不要 `sudo systemctl ...`** —— 那是死的 system-level，不是活的 user-level。

### drop-in 配置（加 env）

`~/.config/systemd/user/nerve.service.d/` 下放 `.conf` 片段，systemd 自动合并：

```
~/.config/systemd/user/nerve.service.d/
├── cwd.conf      # WorkingDirectory + ExecStart override
├── gemini.conf   # GEMINI_API_KEY
└── lifelog.conf  # AI_LIFE_LOG_REMOTE_UPLOAD / HTTP_PORT / TOKEN / AUDIO_RETAIN_DAYS
```

加新 env：写 `.conf` → `systemctl --user daemon-reload` → `systemctl --user restart nerve`。

### Nerve 主服务关键路径

- WorkingDirectory: `/home/renjinxi/.ai`（cwd.conf override，不是 nerve 仓库根）
- ExecStart: `/usr/bin/node /home/renjinxi/work/ai-work-os/nerve/dist/cli.js serve`
- **跑 dist 不是 tsx** —— 改完代码必须 `cd ~/work/ai-work-os/nerve && npm run build`（=tsc）再 restart
- 仓库分支：main（不是 dev）

### 标准部署改动后的重启流程

```bash
ssh home '
  set -e
  cd ~/work/ai-work-os/nerve
  git pull origin main
  npm install
  npm run build
  systemctl --user restart nerve
  sleep 5
  ss -tlnp 2>/dev/null | grep -E ":(4800|4810|4811)"
  tail -20 ~/.nerve/nerve.log
'
```

### 端口分工

| 端口 | 服务 | 用途 |
|---|---|---|
| 4800 | nerve 主 WS/HTTP | TUI/Android 客户端连这个 |
| 4810 | ai-life-log plugin | 手机 Opus chunk 上传，需 `X-LifeLog-Token` |
| 4811 | nerve-log-collector | 手机 nerve-app 远程日志 POST `/log` (JSON) |
| 80 | nginx | APK 发版 `/var/www/html/nerve-app.apk` + `nerve-app-version.json` |
| 22 | sshd | ssh alias `home` |

### 日志路径速查

| 路径 | 内容 |
|---|---|
| `~/.nerve/nerve.log` | nerve 主服务（所有节点 + spawn + ACP） |
| `~/.nerve/plugins/ai-life-log/activity.log` | ai-life-log 自己的活动（capture/chunk/transcript/cleaner） |
| `~/.nerve/plugins/ai-life-log/log/{date}.txt` | 转录文本，行格式 `[HH:MM:SS][source] text` |
| `~/.nerve/plugins/ai-life-log/audio/{date}/{chunkId}.opus` | 手机上传的原始 Opus（`AI_LIFE_LOG_AUDIO_RETAIN_DAYS=7` 天） |
| `~/.nerve/plugins/ai-life-log/audio/{corrupt,failed}/{date}/` | 解码失败 / ASR 抛错 隔离 |
| `~/.nerve/client-logs/nerve-app-{date}.log` | nerve-app 远程日志（WARN+ERROR） |

### ai-life-log 模型路径

```
~/.nerve/plugins/ai-life-log/models/sensevoice-small/model.onnx + tokens.txt   # 1GB
~/.nerve/plugins/ai-life-log/models/silero_vad.onnx                             # 632KB
```

下载命令在 `nerve/src/plugins/ai-life-log/README.md`。

### 排查 SOP

| 现象 | 看哪里 |
|---|---|
| 服务死了 / 没响应 | `systemctl --user status nerve` 看 ExecStart 是不是 dist 路径 → `journalctl --user -u nerve -n 100` |
| plugin 没起（4810 没监听） | `grep ai-life-log ~/.nerve/nerve.log \| tail` 看 spawned / skipped / spawn failed |
| plugin 起了但 endpoint 异常 | 看 plugin 自己的 `~/.nerve/plugins/{name}/activity.log` |
| nerve-app 异常 | `tail ~/.nerve/client-logs/nerve-app-{date}.log`，按 `dev=` 前缀过滤设备 |
| mac → home tailscale 不通 | `tailscale status \| grep home`；mac curl 加 `--noproxy '*'` 绕 mac 系统代理 |
| 端口检查 | `ss -tlnp 2>/dev/null \| grep -E ':(4800\|4810\|4811)'` |

### home 开发工具链

> home 默认只有 node；其余工具链补装，全部 user-level、无 sudo。

| 工具 | 状态 | 服务的项目 |
|------|------|-----------|
| node / npm | 自带 | nerve、erp 多数仓 |
| Rust(rustup) | ✅ 装好，`~/.cargo` | nerve-tui |
| Go | ✅ 装好，`~/.local/go` | erp-lt-vv |
| JDK 21(Temurin) | ✅ 装好，`~/.local/jdk` | nerve-app(Android)|
| Android SDK | ⏳ 待装，见下 | nerve-app(Android)|

PATH 已写入 `~/.profile`：`~/.local/go/bin`、`~/.cargo/bin`、`~/.local/jdk/bin`。

**Android SDK（待装）**

cmdline-tools 没有稳定的 "latest" 下载 URL，需从 <https://developer.android.com/studio#command-line-tools> 取当前 Linux 版 zip：

```bash
mkdir -p ~/.local/android-sdk/cmdline-tools
cd /tmp && curl -sLO <commandline-tools-linux-XXXX_latest.zip 的当前 URL>
unzip -q commandline-tools-linux-*.zip -d ~/.local/android-sdk/cmdline-tools
mv ~/.local/android-sdk/cmdline-tools/cmdline-tools ~/.local/android-sdk/cmdline-tools/latest

export ANDROID_HOME=~/.local/android-sdk
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH
yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
```

装好后把 `ANDROID_HOME` 和那两段 PATH 也写进 `~/.profile`。注：Android 真机验证无法在 home 自动化，仍需回手机点。

### 不要踩的坑

- **不要 `sudo systemctl ...`** — system-level 那个 nerve.service 是死的，user-level 才是活的
- **改完 nerve TS 必须 `npm run build`** —— 光 `git pull` 不生效（跑的是 dist）
- **加 env 必须 `daemon-reload`**（不然新 env 不生效）
- **ai-life-log auto-spawn 条件**：darwin OR `AI_LIFE_LOG_REMOTE_UPLOAD=true`（commit `376c2b7` 修过 Linux 原本被 skip 的 bug）
- **新增 npm 依赖后 home 上要跑 `npm install`** —— 不然 plugin spawn 时 ERR_MODULE_NOT_FOUND 反复 restart，旧进程堆积
