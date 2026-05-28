# 操作手册

> 各仓库怎么跑/构建/测试/发版,home 怎么运维。不装一次性排查流水。

## 当前 host 判定

涉及路径、remote、服务、部署前,先执行:

```bash
uname -s
hostname
pwd
```

- Darwin = Mac 本机:Mac 路径是 `/Users/renjinxi/...`;只有这时才把 home 当远端并使用 `ssh home`。
- Linux + `/home/renjinxi/...` = home 本机:直接用本机路径和 `systemctl --user`;不要 `ssh home`。
- 手机触发的 dispatcher/worker 常驻 home 是常态,不要默认"当前本机是 Mac"。

## A+B 档流程边界

- A 档(日常开发):GitLab Issue 是入口,worker 交付 GitLab MR,MR 关联 Issue,main 保护分支只经 MR 合并。
- B 档(合并后):GitHub 只是镜像同步;部署/重启按当前 host 选择本机或远端命令;Android release 独立于 MR 合并。
- Android MR 合并不等于已发版。发版必须单独 bump 版本、构建 APK、发布到 home nginx、更新版本 JSON。

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

**注:** 工作路径是 `~/work/worktree/ai-work-os/nerve/`(dev 分支)。Mac 开发机上的 `nerve-server` wrapper 封装了常用操作(见 `ai-coding/skills/nerve-server.md`);home/Linux 本机不要假设该 wrapper 存在,按本机路径和 `systemctl --user` 执行等价命令。

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

# Mac 开发机可用封装命令
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

### 本机开发 nerve 管理（Mac wrapper）

```bash
nerve-server start    # 启动(端口 4800,pid 写 ~/.nerve/server.pid)
nerve-server stop     # 杀进程(按 pid + 端口)
nerve-server restart  # 完整清理再起
nerve-server status   # 查状态
nerve-server log      # tail -f ~/.nerve/nerve.log
```

这些命令只按 Mac 开发机 wrapper 处理。当前 host 是 home/Linux 时,生产 nerve 由 user-level systemd 管:

```bash
systemctl --user status nerve
systemctl --user restart nerve
journalctl --user -u nerve -n 100
```

**重启必须干净:** 要杀掉旧进程(nerve + agent + mcp)、确认端口释放、再单实例启动。不能双实例。

### home 上的 nerve 部署

```bash
# Mac 上推代码到 home 并重启(推荐)
nerve-server deploy nerve

# Mac 上手动等价流程
ssh home '
  cd ~/work/ai-work-os/nerve
  git pull origin main
  npm install
  npm run build
  systemctl --user restart nerve
'
```

如果当前已经在 home 本机,不要 `ssh home`,也不要假设 `nerve-server` 存在;直接执行引号内命令。

**关键:** home 跑的是 `dist/`,改完 TS 必须 `npm run build` 才生效。

---

## Android 发版

Android release 是 B 档独立流程,不由 MR 合并自动完成。只有完成 bump/build/publish 后,手机才会看到更新。

### GitLab CI 发布（main release commit 后）

`nerve-app` 现在有独立 GitLab CI。MR、分支和 main pipeline 都跑:

```bash
./gradlew :app:testDebugUnitTest
```

发布 job 只在 `main` push pipeline 出现,并且是 manual。release commit 合并到 `main` 后,在 GitLab 手动执行 `android_release`;CI 会在 home shell runner 上构建并发布:

```bash
bash scripts/ci/publish-android.sh
```

CI 发布语义:

- 不 bump `versionCode`,不 commit,不 push;版本必须在 release commit 里提前改好。
- 从 `app/build.gradle.kts` 读取 `versionCode` / `versionName`。
- 构建 `./gradlew :app:assembleDebug`,发布到 `/var/www/html/nerve-app.apk` 和 `/var/www/html/nerve-app-version.json`。
- JSON 的 APK URL 是 `http://100.75.43.90/nerve-app.apk`;说明来自 CI 变量 `RELEASE_NOTES`,为空时默认 `v<versionName>`。
- 发布前后都用 Android SDK build-tools 的 `aapt dump badging` 校验 APK 中的 `versionCode/versionName` 与 JSON 一致。脚本会从 `$AAPT`、`$ANDROID_HOME/build-tools/*/aapt`、`$ANDROID_SDK_ROOT` 和常见 SDK 路径发现 `aapt`。

runner 要求:

- runner tag: `home`。
- executor: shell,运行在 home,不要 `ssh home`。
- runner 用户需要能写 `/var/www/html`。推荐给最小 sudo 权限,只允许 `install` 写 `/var/www/html/nerve-app.apk` 和 `/var/www/html/nerve-app-version.json`;不要把 sudo 密码、runner token 或 `/etc/gitlab-runner/config.toml` 写进仓库。

排查点:

- `aapt not found`:安装 Android SDK build-tools,或在 CI 变量里设置 `AAPT=/path/to/aapt`。
- 写 `/var/www/html` 失败:检查 runner 用户的目录写权限或最小 sudoers 配置。
- 手机看不到更新:确认 release job 是 main pipeline 手动执行,再对比 `curl http://100.75.43.90/nerve-app-version.json` 和 `aapt dump badging /var/www/html/nerve-app.apk | head -1`。

### 手动发布（备用）

Mac 开发机完整发版流程(一条 wrapper 命令):

```bash
nerve-server publish-android "本次更新说明"
```

步骤:1) gradle assembleDebug → 2) rsync APK 到 home `/tmp/` → 3) ssh home `sudo cp` 到 `/var/www/html/nerve-app.apk` → 4) 写 `nerve-app-version.json`(手机 auto-update 依赖)。

**发版前必须 bump 版本:**

```bash
# 在 nerve-app main 上操作,不要从任务分支直接发 APK
git switch main
git pull origin main
# 合入已验证修复并推双远端后,改 app/build.gradle.kts
versionCode = N+1
versionName = "0.x.y"
git commit -am "release(android): bump versionCode N→N+1 — 说明"
# Mac 开发机 wrapper;home/Linux 本机按 Gradle/copy/version JSON 等价流程执行
nerve-server publish-android "说明"
```

**默认规则:** Android 功能/修复完工后,默认合入 `main` → bump → 从 `main` 构建 → publish,不要停在 push。手机启动 app 自动看到更新横幅。

**发布校验:**

```bash
./gradlew :app:testDebugUnitTest :app:assembleDebug :app:compileDebugAndroidTestKotlin
aapt dump badging app/build/outputs/apk/debug/app-debug.apk | head -1
curl -i http://100.75.43.90/nerve-app-version.json
curl -I http://100.75.43.90/nerve-app.apk
```

确认 `aapt` 输出的 `versionCode` 和 `nerve-app-version.json` 一致,且二者都来自 `main` 最新提交。

APK URL: `http://100.75.43.90/nerve-app.apk`

### Android 签名

不要依赖每台机器自己的 `~/.android/debug.keystore` 发版。debug keystore 是机器本地生成的,Mac/Home 签名不同会导致手机覆盖安装失败。

固定发版 key 放在私有目录,不要进 git:

```bash
~/.nerve/secrets/nerve-app-release.jks
chmod 600 ~/.nerve/secrets/nerve-app-release.jks
```

Mac 开发机的 `nerve-server publish-android` 支持通过环境变量指定签名:

```bash
export NERVE_ANDROID_KEYSTORE="$HOME/.nerve/secrets/nerve-app-release.jks"
export NERVE_ANDROID_KEYSTORE_PASSWORD="..."
export NERVE_ANDROID_KEY_ALIAS="nerve-app"
export NERVE_ANDROID_KEY_PASSWORD="..."
# Mac 开发机 wrapper
nerve-server publish-android "本次更新说明"
```

**切换签名证书时 Android 不能覆盖安装旧签名应用。** 如果从 debug key 切到 release key,手机端需要卸载一次旧包再安装新包;之后同一 release key 才能持续覆盖更新。

发版后必须校验 nginx 上的 APK 本体,不能只看 `nerve-app-version.json`:

```bash
ssh home 'apksigner verify --print-certs /var/www/html/nerve-app.apk'
ssh home 'aapt dump badging /var/www/html/nerve-app.apk | head -1'
```

### Android 更新检测排查

如果手机点"检测更新"没有反应:

1. 先确认服务端发布文件:
   ```bash
   curl -i http://100.75.43.90/nerve-app-version.json
   curl -I http://100.75.43.90/nerve-app.apk
   ```
2. 再看手机远程日志:
   ```bash
   rg -n "UpdateViewModel|UpdateChecker|ApkDownloader|ApkInstaller|fetch_fail|update_available|up_to_date" \
     ~/.nerve/client-logs/nerve-app-$(date +%F).log
   ```
3. 常见结论:
   - `fetch_fail reason=timeout` 或 `failed to connect to /100.75.43.90 (port 80)` 是手机到 home nginx/Tailscale 80 端口不通。
   - 只有聊天/连接日志,没有 `UpdateChecker`,说明本次检查没有进入更新链路或日志没上传。
   - Settings 页点 `Check Now` 后若检测成功但没有横幅,检查 `UpdateBanner` 是否挂在全局 overlay,不要只挂在 Main tab 内。

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
