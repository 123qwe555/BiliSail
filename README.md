<p align="center">
  <img src="assets/branding/app_icon.png" width="144" height="144" alt="BiliSail 哔帆应用图标">
</p>

<h1 align="center">BiliSail · 哔帆</h1>

<p align="center">
  专注观看体验的跨平台 Bilibili 第三方客户端（个人改造版）<br>
  基于 Flutter 与 Dart，面向 Windows、Android、macOS、iOS 和 Linux
</p>

<p align="center">
  <a href="pubspec.yaml"><img src="https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2F123qwe555%2FBiliSail%2Fmain%2Fpubspec.yaml&amp;query=%24.version&amp;label=version&amp;color=fb7299" alt="源码版本（pubspec.yaml）"></a>
  <a href="pubspec.yaml"><img src="https://img.shields.io/badge/Flutter-3.47.6-02569B?logo=flutter&amp;logoColor=white" alt="Flutter 3.47.6"></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.13.5-0175C2?logo=dart&amp;logoColor=white" alt="Dart 3.13.5"></a>
  <a href="#许可与第三方资源"><img src="https://img.shields.io/badge/license-unlicensed-lightgrey" alt="许可证未确定"></a>
</p>

<p align="center">
  <a href="#下载与安装">下载与安装</a> ·
  <a href="docs/README.md">项目文档</a> ·
  <a href="https://github.com/123qwe555/BiliSail/issues">问题反馈</a> ·
  <a href="#参与贡献">参与贡献</a>
</p>

---

BiliSail（哔帆）以视频、影视和直播观看为核心，提供双／多标签浏览、原生播放、弹幕、云端观看历史与本地续播，以及下载队列和离线播放。晴湾界面采用桌面分组侧栏与窄屏四项底部导航，结合自适应网格、视频卡片悬停预览、播放详情分栏和可配置快捷键。

本仓库是 [上游 BiliSail](https://github.com/CKopoer/BiliSail) 的**个人改造版**，在上游基础上重做了界面与转场动效，并调整了播放启动时序与部分浏览行为，差异见[与上游的差异](#与上游的差异)。

## 使用声明

本应用是哔哩哔哩第三方客户端，视频、影视、直播及相关内容均来自哔哩哔哩，与官方无隶属关系。

本程序仅供学习交流与编程技术研究使用。

如果侵犯了您的合法权益，请及时联系维护者，我们会第一时间处理并删除相关内容。可通过[项目问题反馈](https://github.com/123qwe555/BiliSail/issues)联系我们。

## 目录

- [使用声明](#使用声明)
- [功能概览](#功能概览)
- [与上游的差异](#与上游的差异)
- [技术栈](#技术栈)
- [平台与开发状态](#平台与开发状态)
- [下载与安装](#下载与安装)
- [从源码运行](#从源码运行)
- [使用说明](#使用说明)
- [设置项一览](#设置项一览)
- [开发与文档](#开发与文档)
- [参与贡献](#参与贡献)
- [贡献者](#贡献者)
- [致谢](#致谢)
- [Star 趋势](#star-趋势)
- [许可与第三方资源](#许可与第三方资源)

## 功能概览

| 模块 | 当前能力 |
| --- | --- |
| 内容浏览 | 推荐、分区；热门内含综合热门、可选期数的每周必看、入站必刷和排行榜；动态、视频动态、番剧、国创、放映厅和直播；自适应卡片网格、自动分页与列表位置保留 |
| 视频卡片 | 悬停封面放大与静音视频预览、添加稍后再看、操作菜单；推荐反馈保留原卡片位置并支持撤销；连续点击同一卡片 400 毫秒内只打开一次 |
| 搜索 | 综合、视频、番剧、影视、直播、专栏和用户七类搜索，支持对应排序、筛选与自动分页 |
| 视频与影视 | DASH 音视频分轨播放，分 P、合集与选集、合集订阅、稍后再看队列；清晰度、编码与 CDN 偏好、倍速、音量、全屏、章节与进度条缩略图 |
| 打开与全屏转场 | 点卡片后播放页从卡片位置放大落地：过渡期间画面为纯黑，落地后才开始出画与播放；返回时封面从播放器位置飞回原卡片。内联与全屏之间同为缩放过渡，旋转进全屏的设备交由系统旋转完成。详见[播放页转场](#播放页转场) |
| DLNA 投屏 | 视频／影视投屏地址、局域网设备搜索、暂停／继续／停止，适配明暗主题与窄屏；真实电视兼容性待验，见 [投屏记录](docs/validation/dlna-casting.md) |
| 直播 | HLS / FLV、可用清晰度、实时聊天与表情、画面弹幕、Super Chat 展示、用户主页跳转及弹幕发送入口 |
| 弹幕与字幕 | 滚动、顶部、底部弹幕，暂停与缓冲冻结、seek 重定位；样式、密度与本地过滤配置，字幕 cue 显示与字号／背景／位置调节 |
| 账号与个人空间 | 扫码登录、内嵌官方网页密码／短信登录、系统安全存储；用户主页、关注分组、收藏夹查看与编辑、追番、追剧、稍后再看及消息／私信 |
| 评论与动态互动 | 最热／最新评论、楼中楼、表情与图片、作者装扮、服务端提供的 IP 属地、正文链接与时间点跳转；视频点赞／投币／收藏，动态点赞、评论、复制链接与转发 |
| 导航与界面 | 单／双／多标签模式与 Android 默认单标签、Windows／macOS 双标签独立播放窗口及媒体返回历史、Android 应用内双标签、多标签可选并发播放、桌面侧栏与窄屏首页／动态／我的／设置、我的页历史／稍后再看／收藏／下载内容标签、分类横向滚轮、紧凑播放布局、手机横屏浏览（紧凑导航与左右分栏播放，可在设置中关闭）、桌面平滑滚动、键盘与鼠标侧键配置、图片缓存 |
| 历史与续播 | 当前账号云端观看历史分页；登录点播上报云端进度，记住进度开启时本地优先、云端补充；新点播继承本次运行中最近选择的倍速 |
| 下载与离线 | 分 P／剧集多选、画质与编码、队列暂停/继续/重试、断点和重启恢复、文件校验；本地音视频分轨、弹幕与字幕播放 |
| 个性化 | 应用图标切换、明暗主题、HarmonyOS Sans／系统默认／已安装字体、播放、弹幕、字幕和空降助手设置；手动及每日首次启动更新检查；可选空降助手，默认关闭 |


应用默认不添加自动遥测。空降助手启用后会查询独立第三方服务，不携带 Bilibili 账号凭据，也不自动上报。

## 与上游的差异

以下为本仓库在上游基线上的改动，均已在本地构建并装机验证（Android arm64）。

| 方面 | 上游 | 本仓库 |
| --- | --- | --- |
| 界面与动效 | 既有 Material 风格 | 新增 `apple_design.dart` / `apple_motion.dart` 设计令牌与动效体系，主题、对话框、页面入场、卡片按压与新界面共用同一套节奏；模糊强度按屏幕刷新率分档（165/144/120/90/80/60 Hz） |
| 打开视频 | 直接切换到播放页 | 卡片矩形放大到播放器位置的共享元素转场（460 ms），期间为纯黑，落地后才开始播放；返回时封面飞回原卡片（320 ms，无回弹） |
| 内联 ↔ 全屏 | 直接换页 | 以只影响绘制的合成变换做缩放过渡（进入 300 ms / 退出 240 ms），不改变布局与命中测试，原生画面尺寸不重协商；会真实旋转的设备仍交由系统旋转 |
| 播放启动 | 解析完成即开始 | 由转场闸门统一放行：动画落地后才播放；页面被销毁、动画被中断或超时（1.5 s）时立即释放，不会卡住或重复触发 |
| 播放标签 | 不限 | 保留的播放页最多 6 个，超出按最久未访问淘汰，不误伤浏览页 |
| 横屏频道条 | 选中高亮可能错位 | 用分页容器的真实分组顺序映射索引，横屏下选中态与页面一致 |
| 设置 | — | 新增「打开视频后自动全屏」，每页只自动进入一次 |

## 技术栈

| 层次 | 选型 |
| --- | --- |
| 语言与框架 | Dart 3.13.5（SDK `>=3.13.0 <4.0.0`）、Flutter 3.47.6 stable（`>=3.47.6`） |
| 状态与路由 | `flutter_riverpod` 3.4.3、`go_router` 18.0.2 |
| 播放 | `media_kit`（默认，取自固定 fork 提交）、`fvp`（实验性可选后端），自研 `packages/bili_player` 契约层与 `VideoSurface` |
| 弹幕 | 自研 `packages/bili_danmaku`（无网络的有界调度与绘制） |
| 网络与存储 | `drift` 2.35.2、`flutter_secure_storage` 11.2.0、`path_provider`、`archive`、`crypto`、`xml`、`file_selector` |
| 平台集成 | `window_manager` 0.5.2（桌面窗口与全屏）、`audio_service` + `audio_service_mpris`（后台与 MPRIS）、`flutter_inappwebview` 6.2.0-beta.3（网页登录）、`url_launcher`、`package_info_plus`、`qr_flutter` |
| 本地封装 | `packages/bili_mux`：独立精简原生组件，仅处理本地 MP4 无损封装 |

直接依赖采用精确版本，根应用与各包均保留锁文件；`media_kit`、`fvp`、`canvas_danmaku` 通过 `dependency_overrides` 固定到指定 fork 提交，**首次 `flutter pub get` 需能访问 GitHub**。

## 平台与开发状态

本仓库是个人改造版，验证集中在一个 Android arm64 真机上；其余平台沿用上游工程，未在本仓库复验。

| 平台 | 目标架构 / 系统 | 本仓库的验证状态 |
| --- | --- | --- |
| Android | arm64 / Android 7.0（API 24）及以上 | **主要验证平台**：本地 release 构建、固定签名与单 arm64 ABI 校验通过；视频／影视／直播播放、卡片与全屏转场、自动全屏、离线下载均在真机上跑过 |
| Windows | x64 / Windows 10 1809 及以上 | 沿用上游工程与打包脚本，本仓库未复验；构建命令见[从源码运行](#从源码运行) |
| Windows ARM64 | ARM64 / Windows 11 及以上 | 沿用上游的独立构建目标，本仓库未复验 |
| macOS | arm64、Intel x64 / macOS 13.0 及以上 | 沿用上游工程；需在 macOS 主机上构建，本仓库未复验 |
| iOS | arm64 / iOS 15.0 及以上 | 沿用上游工程与未签名构建流程，本仓库未复验 |
| Linux | x64 / AppImage 基线 Ubuntu 24.04；Flatpak Freedesktop 25.08 | 沿用上游的 GTK 工程与打包配置，本仓库未复验 |

上游各平台的 CI 构建与签名记录见上游仓库的 [CI/CD 说明](docs/validation/ci-cd.md)；文中涉及的签名、MSIX 与 DMG 结论针对上游流水线。

## 下载与安装

本仓库**不发布安装包**，也没有 Release；包体与签名由你按[从源码运行](#从源码运行)自行构建。

如需现成安装包，可使用[上游 Releases](https://github.com/CKopoer/BiliSail/releases)——那是上游版本，**不包含本仓库的界面与转场改动**。

自建 Android 安装包后，可直接安装到已连接的设备（`dev.bilisail.bilisail.test` 为开发版包名，与上游正式包可共存）：

```powershell
.\tool\build-android-development.ps1 -Mode Release -SkipMuxBuild
adb install -r .\build\development\android-arm64\BiliSail-test-arm64-release.apk
```

固定 release 签名与覆盖升级的边界见 [Android 签名](docs/validation/ci-cd.md#android-固定签名与覆盖升级)。

## 从源码运行

### 环境要求

项目固定使用 **Flutter 3.47.6 stable / Dart 3.13.5**。直接依赖采用精确版本，根应用和各包均保留锁文件。

Windows 开发还需安装 **Visual Studio 2022** 的“使用 C++ 的桌面开发”工作负载及 Windows SDK，并将 NuGet CLI 加入 `PATH`（内嵌网页插件构建使用）。Windows 密码／短信登录需要 WebView2 Runtime；来源与平台边界见[登录验证](docs/validation/password-sms-login.md)。Android 和 macOS 的构建需各自的工具链，macOS 构建需在 macOS 主机上执行。

### Windows 调试

下载合并组件需先从固定源码准备原生资产；Windows 额外需要 MSYS2 UCRT64 GCC/G++ 和 make。Android 使用固定 NDK 28.2.13676358，macOS 使用 Xcode 工具链。三端准备命令见 [bili_mux 构建说明](packages/bili_mux/README.md)。

在 PowerShell 中执行：

```powershell
git clone https://github.com/123qwe555/BiliSail.git
cd BiliSail
flutter pub get
.\tool\build-download-mux.ps1 -Target windows-x64
flutter run -d windows
```

### Windows Release 构建

```powershell
.\tool\build-download-mux.ps1 -Target windows-x64
flutter build windows --release
.\build\windows\x64\runner\Release\bilisail.exe
```

移动或分发便携构建时，需保留整个 `Release` 目录，包括原生 DLL 和 `data`。播放器原生库由插件从固定来源下载，首次构建需能访问 GitHub。**运行应用无需另行安装 FFmpeg**；测试媒体的生成才使用本机 FFmpeg。

### Android 构建与安装

```powershell
# 只构建（产物：build\development\android-arm64\BiliSail-test-arm64-release.apk）
.\tool\build-android-development.ps1 -Mode Release -SkipMuxBuild

# 构建并安装到指定设备
.\tool\build-android-development.ps1 -Mode Release -Install -DeviceId <序列号>
```

脚本参数：`-Mode Release|Profile|Debug`、`-Install`（必须同时给 `-DeviceId`）、`-SkipMuxBuild`（跳过本地封装原生组件）。开发版依赖本机已配置的固定签名与版本信息，脚本会校验单项 ABI 与版本号。

## 使用说明

设置“关于”提供项目 GitHub 地址和“检查更新”。每天首次打开应用时会自动检查已发布版本（包含预览版）；发现新版本后弹窗提示，点击“前往 Release”可查看说明并下载。自动检查失败时保持安静，可随时手动重试；应用不会自动下载或安装更新。本仓库没有 Release，检查更新会指向无内容，介意可在“关于”中关闭预发布检查。

桌面工作区支持固定根页面，以及搜索、视频、影视、直播播放、用户和历史等标签。根标签固定，最多打开 16 个标签；标签状态保留至本次运行结束。每个播放标签拥有独立播放器，切换到普通页面时媒体继续播放；是否允许不同播放标签同时播放由下方设置控制。关闭播放标签只停止并释放该标签的播放器。**同时保留的播放页最多 6 个**：超出的按最久未访问顺序关闭，当前页与浏览页不会被淘汰，所以连续点开多个视频后旧播放页会自动回收。

页面导航提供单／双／多标签，Android 默认单标签，其他平台默认双标签；已保存的有效选择保持，旧单标签偏好可直接恢复。单标签按实际访问顺序返回，从视频进入 UP 主空间后返回原播放页并保留会话、进度与分 P；最后一次出栈释放页面和会话，详见[单标签记录](docs/validation/single-page-navigation.md#恢复单标签2026-10-25)。Windows 和 macOS 双标签的所有媒体共用一个独立播放窗，标题栏返回可回到上一媒体，媒体历史为空时关闭播放窗；系统关闭按钮直接关闭播放窗并回到浏览。在本次应用运行期间，关闭播放窗后再打开媒体会恢复正常窗口的位置、尺寸和最大化状态；点击还原仍回到此前的普通窗口大小。退出应用后清除这份记忆。双标签浏览返回会关闭离开的搜索、用户等临时页；Android 双标签在应用内切换浏览与播放，保留页面状态和媒体返回历史。macOS 从无原生主控制器的 engine 启动，再创建主浏览窗和播放窗，原因与验证边界见[播放崩溃修复](docs/validation/macos-dual-playback-crash.md)。

首页、动态、直播、我的、消息、下载、设置属于同一固定根标签，一级切换不另开标签，各自保留列表与筛选。“我的”以紧凑资料区展示等级、经验、硬币及关注/粉丝/动态，直接分标签显示历史、稍后再看、收藏和下载；桌面直播直接显示推荐直播、我的关注、观看记录。首页、动态和直播保留头像与搜索，头像仍打开账号抽屉；动态首次进入默认视频动态，之后保留本次选择。设置只保留分类与设置内容。

播放默认使用 media_kit。可在「设置 → 播放 → 视频编解码 → 播放后端」选择实验性 fvp，保存后对下次打开或重新加载的播放源生效，方便同包实机对比；当前播放不切换。接入及测试边界见[可选 fvp 后端](docs/validation/fvp-backend-2026-11-07.md)。

### 播放页转场

打开与返回按“先动画、后播放”的顺序执行，画面不会在转场过程中提前出画：

- **打开**：点卡片后，播放页从卡片的矩形放大到播放器位置（460 ms，先快后缓、无过冲），过渡期间该区域是纯黑；落地同一帧才放行播放，因此看到的是“黑卡放大 → 视频开始”。
- **返回**：播放器收起并让封面飞回卡片原位（320 ms），页面在动画下方切回网格。
- **内联 ↔ 全屏**：画面从播放器槽位放大到铺满屏幕（300 ms），退出时反向收回（240 ms）；过渡只改变绘制，不改变布局，所以画面尺寸不会反复重协商。设置里开启“打开视频后自动全屏”时，卡片动画会直接长到全屏。
- **打断与异常**：页面在动画结束前被销毁、动画被中断或信号丢失时，闸门会在 1.5 秒内强制放行，不会出现“永远停在暂停态”或同一视频重复触发播放。

### 常用快捷键

默认键位（可在「设置 → 快捷键」逐项录制；macOS 可切换为 Apple 默认键位）：

| 操作 | 默认快捷键 |
| --- | --- |
| 播放 / 暂停 | `Space` |
| 前进 / 后退 | `→` / `←`，步长默认 3 秒（可调） |
| 前进 90 秒 | `O` / `P` |
| 临时加速 | 长按 `→` 或长按画面，默认 2 倍速（可调） |
| 提高 / 降低音量 | `↑` / `↓` |
| 切换 / 退出全屏 | `F`、`F11` 或 `Enter` / `Esc` |
| 收起 / 展开视频信息 | `W` 或 `F12` |
| 开关弹幕 / 字幕 | `D` 或 `F9` / `F6` |
| 降低 / 提高倍速 | `F1` 或 `;` / `F2` 或 `'` |
| 切换 1 / 2 倍速 | `Ctrl+1` |
| 上一 / 下一分 P | `Z`、`N` 或 `,` / `X`、`M` 或 `.` |
| 刷新当前页面 | `Ctrl+R` 或 `F5` |
| 新建 / 关闭标签 | `Ctrl+T` / `Ctrl+W`（或鼠标侧键后退） |
| 下一个 / 上一个标签 | `Ctrl+Tab` / `Ctrl+Shift+Tab` |

静音默认不绑定按键，需要时在快捷键设置里录制。

## 设置项一览

设置分为 9 个分类，全部保存在本地数据库（`drift`），登录凭据单独进入系统安全存储。

| 分类 | 主要设置项 |
| --- | --- |
| 外观 | 应用图标切换、页面导航模式（单／双／多标签）、导航栏模式（自动／底栏／侧边栏）、允许手机横屏浏览、侧栏样式（随窗口宽度／完整侧栏／图标上下）、动态页默认标签、应用主题（跟随系统／浅色／深色）、界面字体（HarmonyOS Sans／系统默认／已安装字体）、滚轮阻尼比 |
| 缓存 | 缓存图片（关闭后停止读写图片缓存，已显示的图片保留） |
| 推荐流 | 推荐来源、标题关键词过滤、分区关键词过滤及若干过滤开关，可一键恢复默认 |
| 快捷键 | 启用快捷键、标签页与页面、播放控制、长按临时倍速、前进／后退步长、逐项键位录制、Apple 默认键位 |
| 播放 | 双指缩小视频、中部滑动切换全屏及其反向、滑动调节亮度与音量、隐藏控件时显示底部进度条、进入播放页默认显示评论区、自动播放、视频卡悬停播放、高能进度条、列表循环、连续播放相关视频、允许多个标签页同时播放、记住播放进度、**打开视频后自动全屏**、视频/直播默认清晰度、默认播放倍速、记忆播放倍速、全局音量记忆、默认音量、CDN 线路、播放后端（media_kit／fvp）、优先视频编码（H.264／HEVC／AV1／杜比视界）、视频解码方式（自动优硬解／软件解码）、Android 视频输出方式、优先音质 |
| 弹幕 | 显示弹幕、隐藏滚动弹幕、显示区域、字号缩放、滚动速度、行距、不透明度、顶部距离、同屏数量、每秒最大数量、时间偏移、本地过滤与发送样式 |
| 字幕 | 默认显示字幕、字号、背景不透明度、底部距离 |
| 空降助手 | 工作模式（关闭／手动提示／自动跳过）与分类（赞助广告、片头、片尾、自我推广、互动提醒、预告） |
| 关于 | 版本与项目地址、检查预发布更新、检查更新 |

## 开发与文档

### 工程结构

```text
lib/
├── app/                  # 组合根、路由、主题与工作区
├── core/                 # 存储、安全凭据、取消与平台能力
├── domain/               # 共享领域类型（含快捷键定义）
├── features/             # 按 domain / data / application / presentation 分层
└── shared/               # 共用数据映射与 ui 组件
    └── ui/               # 含 apple_design.dart / apple_motion.dart（设计令牌与动效）、
                          # video_open_transition.dart（打开与返回转场）、
                          # fullscreen_reveal.dart（内联↔全屏过渡）
packages/
├── bili_api/             # 纯 Dart 协议与 API 包
├── bili_player/          # 通用播放器契约、media_kit/fvp 适配与 VideoSurface
├── bili_danmaku/         # 无网络的有界弹幕调度与绘制
└── bili_mux/             # 独立精简原生组件，仅处理本地 MP4 无损封装
docs/                     # 设计、决策与验证记录
tool/                     # 检查、原生测试与构建打包脚本
```

### 检查与调试

根应用与四个包的格式、静态分析和离线测试：

```powershell
.\tool\check.ps1
```

Windows 原生受控媒体与安全存储测试：

```powershell
.\tool\test-windows-media.ps1
```

显式运行游客公开 API 与媒体 CDN 烟测：

```powershell
.\tool\test-windows-media.ps1 -Online

# 纯 Dart API 只读烟测
Push-Location packages\bili_api
dart run tool\live_smoke.dart
Pop-Location
```

正常测试使用 fake transport、repository、player 和人工生成的媒体，无需真实账号。播放诊断保存在本机应用数据目录的 `logs` 下，限制容量并过滤账号、请求头和媒体 URL，不自动上传；路径与排查方法见[播放错误排查](docs/validation/native-playback-errors.md)。

### 文档入口

| 文档 | 内容 |
| --- | --- |
| [文档索引](docs/README.md) | 全部设计与功能验证记录 |
| [整体架构](docs/architecture.md) | 功能分层、独立包、状态与生命周期 |
| [API 与会话](docs/api-design.md) | 接口、鉴权、错误处理与账号隔离 |
| [播放、直播与弹幕](docs/playback-and-danmaku.md) | 播放会话、媒体请求与弹幕时钟 |
| [下载与离线播放](docs/downloads.md) | 下载队列、断点恢复、文件校验与离线播放边界 |
| [快捷键实施记录](docs/shortcut-system/implementation-results.md) | 输入作用域、页面刷新、键位录制与验证 |
| [CI/CD 与安装包](docs/validation/ci-cd.md) | 三端构建、MSIX／APK／DMG、签名与安装说明（上游流水线） |
| [实施与验收](docs/implementation-plan.md) | 开发阶段与平台验收要求 |
| [架构决策](docs/decisions.md) | 重要技术选择及其依据 |
| [开发约定](AGENTS.md) | 代码、文档、测试与交付规则 |
| [第三方说明](THIRD_PARTY_NOTICES.md) | 依赖、原生二进制与资源来源 |

项目原名 Bili Lite，当前工程名为 `bilisail`。更名后的安装与数据标识以及数据空间变化见[项目更名记录](docs/validation/project-renaming.md)。

## 参与贡献

欢迎通过 [Issues](https://github.com/123qwe555/BiliSail/issues) 反馈问题、提出建议，通过 [Pull Requests](https://github.com/123qwe555/BiliSail/pulls) 改进代码、文档和平台适配。

- **反馈问题**：附上应用版本、操作系统、复现步骤、预期与实际结果；播放问题可提供公开视频 BV 号及脱敏诊断。请勿提交 Cookie、token、二维码 key 或带签名参数的媒体 URL。
- **提出改进**：说明使用场景与预期行为。较大的功能或架构调整建议先通过 Issue 讨论。
- **提交修改**：先阅读[文档索引](docs/README.md)与 [AGENTS.md](AGENTS.md)，保持改动聚焦，并在 PR 中说明变更、验证结果和未测项。代码改动运行 `tool/check.ps1`；原生播放改动补充受影响平台的构建与实机验证。纯文档改动检查链接、路径和内容一致性即可。

## 贡献者

本仓库为个人改造版，维护者 [@123qwe555](https://github.com/123qwe555)。界面、播放与平台能力的绝大部分工作来自上游 BiliSail 及其贡献者：

<a href="https://github.com/CKopoer/BiliSail/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=CKopoer/BiliSail" alt="BiliSail 代码贡献者头像">
</a>


## 致谢

感谢以下项目及其维护者提供的参考与基础能力：

| 项目 | 与 BiliSail 的关系 |
| --- | --- |
| [BiliSail（上游）](https://github.com/CKopoer/BiliSail) | 本仓库的基线与绝大部分功能来源 |
| [biliuwp-lite（原项目）](https://github.com/xiaoyaocz/biliuwp-lite) / [ywmoyue 维护分支](https://github.com/ywmoyue/biliuwp-lite) | 功能、桌面布局与交互参考；部分图标资源来源见[资源记录](assets/README.md) |
| [bili-kernel](https://github.com/Richasy/bili-kernel) | C# / .NET API 项目，为协议模型、鉴权与职责划分提供参考 |
| [PiliPlus](https://github.com/bggRGjQaUbCoE/PiliPlus) | 播放器配置、Android Surface 生命周期与弹幕优化思路参考；具体采用范围见[移植记录](docs/validation/piliplus-media-kit-port.md) |
| [Flutter](https://github.com/flutter/flutter) / [Dart](https://github.com/dart-lang/sdk) | 跨平台界面与语言运行时 |
| [Riverpod](https://github.com/rrousselGit/riverpod) / [go_router](https://pub.dev/packages/go_router) | 应用状态、依赖注入与路由 |
| [media_kit](https://github.com/media-kit/media-kit) / [mpv](https://github.com/mpv-player/mpv) / [FFmpeg](https://ffmpeg.org) | 播放适配与原生媒体解码基础 |
| [Dio](https://github.com/cfug/dio) / [Drift](https://github.com/simolus3/drift) / [flutter_secure_storage](https://github.com/juliansteenbakker/flutter_secure_storage) | 网络、结构化存储与系统安全凭据 |
| [BilibiliSponsorBlock](https://github.com/hanydd/BilibiliSponsorBlock) | 可选空降助手的公开查询协议与服务 |
| [Star History](https://github.com/star-history/star-history) / [contributors-img](https://github.com/lacolaco/contributors-img) | README 的 Star 趋势与贡献者展示 |

参考项目的具体采用范围见[参考文档](docs/references.md)，资源、字体和原生组件的来源及许可范围见[第三方说明](THIRD_PARTY_NOTICES.md)。

感谢 [Linux DO 社区](https://linux.do/latest) 的支持

## Star 趋势

如果这个改造版对你有帮助，欢迎点亮 Star。

<a href="https://www.star-history.com/?repos=123qwe555%2FBiliSail&amp;type=date">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=123qwe555/BiliSail&amp;type=date&amp;theme=dark">
    <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=123qwe555/BiliSail&amp;type=date">
    <img src="https://api.star-history.com/chart?repos=123qwe555/BiliSail&amp;type=date" alt="BiliSail Star 数量随时间的变化趋势">
  </picture>
</a>

## 许可与第三方资源

本项目尚未确定开源许可证。第三方依赖与素材保留各自许可和权利范围，公开源码不代表所有资源均已取得再分发授权。

部分参考图标目前仅记录了本机预览的采用范围，对外发行前仍需核实；原生播放器及其子依赖的许可材料也需单独归档。详见[第三方来源与分发检查](THIRD_PARTY_NOTICES.md)及[资源来源](assets/README.md)。

本项目基于上游 [BiliSail](https://github.com/CKopoer/BiliSail) 修改，上游同样未声明开源许可证；再分发前请先与上游确认授权范围。
