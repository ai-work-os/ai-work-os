# home 开发工具链

> 远程开发流程在 home 服务器上执行,worker 要能在 home 构建/测试各项目。
> home 默认只有 node;其余工具链补装,全部 **user-level、无 sudo**。

## 现状

| 工具 | 状态 | 服务的项目 |
|------|------|-----------|
| node / npm | 自带 | nerve、erp 多数仓 |
| Rust(rustup) | ✅ 2026-05-19 装,`~/.cargo` | nerve-tui |
| Go | ✅ 2026-05-19 装,`~/.local/go` | erp-lt-vv |
| JDK 21(Temurin) | ✅ 2026-05-19 装,`~/.local/jdk` | nerve-app(Android)|
| Android SDK | ⏳ 待装,见下 | nerve-app(Android)|

PATH 已写入 `~/.profile`:`~/.local/go/bin`、`~/.cargo/bin`、`~/.local/jdk/bin`。

## Android SDK(待装)

cmdline-tools 没有稳定的 "latest" 下载 URL,需从
<https://developer.android.com/studio#command-line-tools> 取当前 Linux 版 zip:

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

装好后把 `ANDROID_HOME` 和那两段 PATH 也写进 `~/.profile`。

注:Android **真机验证**无法在 home 自动化,仍需回手机点。
