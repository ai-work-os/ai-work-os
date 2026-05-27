# 操作手册

> 各仓库怎么跑/构建/测试/发版,home 怎么运维。不装一次性排查流水。

## 各仓库:跑 / 构建 / 测试

### nerve(服务端 — Node.js/TypeScript)

```bash
# 开发模式(tsx 直跑,端口 4800)
npm run dev
# 或
npx tsx src/cli.ts serve

# 构建(生成 dist/)
npm run build   # = tsc

# 生产启动(跑 dist)
node dist/cli.js serve

# 测试(test/{unit,integration,e2e,legacy,fixtures,helpers})
npm test                  # 只跑单元测试(秒级)
npm run test:unit         # 同上
npm run test:integration  # 集成测试(并行)
npm run test:e2e          # e2e 测试
npm run test:all          # 全量(unit + integration + e2e)
```

**注:** 工作路径是 `~/work/worktree/ai-work-os/nerve/`(dev 分支)。`nerve-server` 命令封装了常用操作(见 `ai-coding/skills/nerve-server.md`)。

---

### nerve-tui(终端客户端 — Rust)

```bash
# 开发构建(debug)
cargo build

# 发布构建
cargo build --release
# 或用 scripts/
scripts/build.sh

# 安装到 ~/.cargo/bin/nerve-tui
scripts/install.sh

# 拉代码并安装
scripts/update.sh

# 运行
nerve-tui --host 127.0.0.1 --port 4800
```

**工作路径:** `~/work/worktree/ai-work-os/nerve-tui/`

---

### nerve-app(Android 客户端 — Kotlin/Gradle)

```bash
# 单元测试
./gradlew test

# 构建 debug APK
./gradlew assembleDebug

# 连真机后安装
./gradlew installDebug

# 或用封装命令
nerve-server build android       # 只构建
nerve-server install android     # 构建 + adb install
```

**工作路径:** `~/work/worktree/ai-work-os/nerve-app/`(包名 `com.nerve.android`)

---

## 测试规则

1. **永远在 worktree dev 分支跑测试**,不在 main 分支测试未验证的改动。
2. **nerve 测试实例用 4801 端口**,不占 4800(4800 是开发时 nerve 实例)。
3. **集成测试必须隔离:**
   - 端口随机生成(不写固定端口),多组并行不冲突
   - 数据目录用临时目录 `/tmp/nerve-test-{port}/`,不写 `~/.nerve/`
   - 测试结束后清理临时目录
4. **纯函数测试独立文件**,秒级完成,不依赖 server。集成测试批量跑,不要每改一行跑全量。

---

## nerve 重启 / 发版 / 部署

### mac 本地 nerve 管理

```bash
nerve-server start    # 启动(端口 4800,pid 写 ~/.nerve/server.pid)
nerve-server stop     # 杀进程(按 pid + 端口)
nerve-server restart  # 完整清理再起
nerve-server status   # 查状态
nerve-server log      # tail -f ~/.nerve/nerve.log
```

**重启必须干净:** 要杀掉旧进程(nerve + agent + mcp)、确认端口释放、再单实例启动。不能双实例。

### home 上的 nerve 部署

```bash
# 推代码到 home 并重启(推荐)
nerve-server deploy nerve

# 手动等价流程
ssh home '
  cd ~/work/ai-work-os/nerve
  git pull origin main
  npm install
  npm run build
  systemctl --user restart nerve
'
```

**关键:** home 跑的是 `dist/`,改完 TS 必须 `npm run build` 才生效。

---

## Android 发版

完整发版流程(一条命令):

```bash
nerve-server publish-android "本次更新说明"
```

步骤:1) gradle assembleDebug → 2) rsync APK 到 home `/tmp/` → 3) ssh home `sudo cp` 到 `/var/www/html/nerve-app.apk` → 4) 写 `nerve-app-version.json`(手机 auto-update 依赖)。

**发版前必须 bump 版本:**

```bash
# 改 app/build.gradle.kts
versionCode = N+1
versionName = "0.x.y"
git commit -am "release(android): bump versionCode N→N+1 — 说明"
nerve-server publish-android "说明"
```

**默认规则:** Android 功能/修复完工后,默认 bump + publish,不要停在 push。手机启动 app 自动看到更新横幅。

APK URL: `http://100.75.43.90/nerve-app.apk`

---

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
~/.config/systemd/user/xvfb.service                 # Xvfb 虚拟显示 :99（codex clipboard 桥）
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
├── lifelog.conf  # AI_LIFE_LOG_REMOTE_UPLOAD / HTTP_PORT / TOKEN / AUDIO_RETAIN_DAYS
└── path.conf     # PATH 加 ~/.local/bin(让 nerve 子进程能找到 worktree-task 等)
```

**path.conf 内容**(新 host 必加,否则 dispatcher 跑 worktree-task 等命令会 command not found):

```
[Service]
Environment="PATH=/home/<user>/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"
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
  ss -tlnp 2>/dev/null | grep -E ":(4800|4810|4811|4812)"
  tail -20 ~/.nerve/nerve.log
'
```

### 端口分工

| 端口 | 服务 | 用途 |
|---|---|---|
| 4800 | nerve 主 WS/HTTP | TUI/Android 客户端连这个 |
| 4810 | ai-life-log plugin | 手机 Opus chunk 上传，需 `X-LifeLog-Token` |
| 4811 | nerve-log-collector | 手机 nerve-app 远程日志 POST `/log` (JSON) |
| 4812 | screenshot plugin | 手机截图 HTTP 上传端点（mac-clipboard 拉取） |
| 80 | nginx | APK 发版 `/var/www/html/nerve-app.apk` + `nerve-app-version.json` |
| 22 | sshd | ssh alias `home` |

### 日志路径速查

| 路径 | 内容 |
|---|---|
| `~/.nerve/nerve.log` | nerve 主服务（所有节点 + spawn + ACP） |
| `~/.nerve/plugins/system-watchdog/alerts/system-alerts.md` | system-watchdog 分钟级 alert 流水（runtime，不进 `~/.ai` git） |
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
| plugin 没起（4810/4812 没监听） | `grep ai-life-log ~/.nerve/nerve.log \| tail` 看 spawned / skipped / spawn failed |
| plugin 起了但 endpoint 异常 | 看 plugin 自己的 `~/.nerve/plugins/{name}/activity.log` |
| nerve-app 异常 | `tail ~/.nerve/client-logs/nerve-app-{date}.log`，按 `dev=` 前缀过滤设备 |
| mac → home tailscale 不通 | `tailscale status \| grep home`；mac curl 加 `--noproxy '*'` 绕 mac 系统代理 |
| 端口检查 | `ss -tlnp 2>/dev/null \| grep -E ':(4800\|4810\|4811\|4812)'` |

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

### nerve scene 运维

scene 定义 nerve 启动时自动 spawn 哪些节点 + 怎么初始化它们。

**位置**:
- 真身 home `~/.nerve/scenes/*.json`(**不进 git**,每台 home 独立)
- 项目级 dispatcher prompt 真身在 `ai/ai-coding/dispatcher-prompt.md`(进 git),scene 里的 prompt 是从这里 copy 进去的

**当前 dispatcher 配置**(home `~/.nerve/scenes/ai-work-os.json`):
- 节点 `ai-work-os-agent`,**adapter = codex**(在 scene 配,不在文档/skill 里写)
- channel `ai-work-os`,auto_create
- scene 顶层 `on_ready[0].command` = dispatcher prompt(从 dispatcher-prompt.md `---` 之后内容 copy)

**改完 dispatcher-prompt.md 同步到 home scene**:

```bash
ssh home 'bash -s' <<'EOF'
set -e
cp ~/.nerve/scenes/ai-work-os.json /tmp/scene.bak-$(date +%s)
new=$(sed -n "/^---$/,$p" ~/work/ai-work-os/ai/ai-coding/dispatcher-prompt.md | tail -n +2)
jq --arg p "$new" '(.on_ready[] | select(.to == "ai-work-os-agent")) .command = $p' \
  ~/.nerve/scenes/ai-work-os.json > /tmp/scene.new && mv /tmp/scene.new ~/.nerve/scenes/ai-work-os.json
systemctl --user restart nerve
sleep 3 && tail -5 ~/.nerve/nerve.log | grep "scene ai-work-os"
EOF
```

**reload 时机**:scene 改了**必须 nerve 重启**(`systemctl --user restart nerve`)才生效,nerve 启动时只读一次 scene。

**其他 scene**(`~/.nerve/scenes/` 还有 `duty.json` `companion.json` `erp.json` `screenshot-triage.json` 等),改完同样要 restart。

### feishu-bridge 配置

凭据文件 `~/.nerve/feishu.json`(含 app_id / app_secret,chmod 600,**不进 git**)。飞书后台必须开启**长连接模式**,并订阅 `im.message.receive_v1` 事件,否则收不到消息。

### duty-monitor 动态命令

DM 发给 `duty-monitor`:

| 命令 | 含义 |
|---|---|
| `add HH:MM @target 消息` | 每天固定时间触发 |
| `add every:Xm @target 消息` | 每 X 分钟触发 |
| `add DDD:HH:MM @target 消息` | 指定星期(MON/TUE/...)+时间 |
| `remove <名称>` | 删除任务 |
| `list` | 查看任务列表 |
| `trigger <名称>` | 立即触发 |
| `status` | 显示运行状态 |
| `reload` | 从磁盘重新加载任务 |

任务持久化在 `~/.nerve/duty-tasks.json`。

### 不要踩的坑

- **不要 `sudo systemctl ...`** — system-level 那个 nerve.service 是死的，user-level 才是活的
- **改完 nerve TS 必须 `npm run build`** —— 光 `git pull` 不生效（跑的是 dist）
- **加 env 必须 `daemon-reload`**（不然新 env 不生效）
- **ai-life-log auto-spawn 条件**：darwin OR `AI_LIFE_LOG_REMOTE_UPLOAD=true`（修过 Linux 原本被 skip 的 bug）
- **新增 npm 依赖后 home 上要跑 `npm install`** —— 不然 plugin spawn 时 ERR_MODULE_NOT_FOUND 反复 restart，旧进程堆积
- **systemctl --user 默认 PATH 不含 `~/.local/bin`** —— nerve 服务的 dispatcher 跑 `worktree-task` 等会 command not found,必须配 `nerve.service.d/path.conf`(见上节)
