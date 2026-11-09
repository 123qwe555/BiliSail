# 手机横屏浏览适配

日期：2026-11-07。范围：Android／iOS 手机在横屏姿态下浏览、搜索、设置与播放时的布局与方向策略；不改变桌面窗口、平板和全屏播放的既有行为。

## 问题

Flutter 工程原本已支持 Android，但浏览态被 `WindowService` 固定在 `DeviceOrientation.portraitUp`：

```text
updateDisplaySize -> compactDisplay(displaySize) == true
                  -> _browsePortrait = true
                  -> setPreferredOrientations([portraitUp])
```

只有全屏播放会请求横屏。因此手机用户在系统旋转打开时，应用仍停回竖屏。

第二层问题是断点口径：全仓 20 余处使用 `width < 600` 判定紧凑布局。手机横屏的逻辑视口约 `800 × 360`（1080 × 2400 @ 3.0 旋转后），宽度会越过 600 让页面误选桌面/平板分支，而高度完全没有参与判断。典型后果：

- 视频页 `collapsedHeight = width * 9 / 16 ≈ 450dp`，高于可用高度；
- 设置、消息、下载等页按宽屏双栏排布，在 360dp 高度下互相挤压；
- 卡片网格使用 20dp 桌面间距与 20dp 内边距；
- 底栏 52dp 带文字标签、页面工具栏 48dp 控件加 16dp 内边距，合计占去约三分之一高度。

## 判定口径

`lib/core/platform/window_size_policy.dart` 新增纯函数，全部可单元测试：

| 函数 | 含义 |
| --- | --- |
| `phoneLandscape(Size)` | 宽 > 高、宽 ≥ 600、最短边 < 600、高 ≤ 480，且尺寸有限 |
| `compactViewport({viewport, mobile})` | 宽度 < 600，或手机横屏 |
| `compactExtent({extent, viewport, mobile})` | 内容宽度 < 600，或手机横屏 |

`mobile` 由调用方按平台给出，保证桌面小窗口不会因为缩到 `800 × 360` 被误判成手机。`lib/shared/ui/app_layout.dart` 把这组函数绑定到 `BuildContext`（`MediaQuery` + `Theme.platform`），并集中提供：

- `compactOf(context, extent: ...)` —— 各页面统一替换原来的裸宽度比较；
- `phoneLandscapeOf` / `shortOf` / `compactNavigationOf`；
- `playbackSideBySideOf(context, extent: ...)` —— 桌面 ≥ 1000dp 才左右分栏；移动端（手机或平板）只要处于横屏（宽 > 高）且内容宽度 ≥ 600dp，就把播放器与信息栏左右分栏，让简介/评论区落在右侧。这样平板在横屏播放时也会走左右分栏，而不是竖叠在播放器下方。

## 改动

| 层 | 文件 | 变化 |
| --- | --- | --- |
| 方向 | `window_service.dart` | 新增 `setBrowseLandscapeAllowed`；允许时浏览态不再下发 `portraitUp`，改为不设偏好，跟随系统旋转锁。`keepsBrowsePortrait` 只在真正上锁时为 true，播放页的旋转全屏状态机据此区分"锁定"与"未锁定" |
| 方向 | `window_orientation_host.dart` / `bili_app.dart` | 把设置值注入方向宿主，旋转/设置变化走同一条命令队列 |
| 设置 | `app_settings.dart` 等 5 处 | 新增 `allowPhoneLandscape`（默认开启），`preferences.v1` 快照版本 42 → 43；旧快照缺键回退 true；外观页新增开关，关闭后完全恢复旧的竖屏锁定 |
| 外壳 | `shell.dart` | `_compactLayout` 叠加视口判定；横屏底栏 52 → 44dp 且隐藏文字标签；两处底栏实现同步 |
| 工具栏 | `page_toolbar.dart` | 矮视口下控件 48 → 40dp、上下内边距收紧 |
| 卡片 | `responsive_card_grid.dart` | 紧凑间距与内边距在横屏生效；列数仍按内容宽度计算 |
| 播放 | `video_screen.dart` / `pgc_screen.dart` | 横屏提前进入左右分栏；视频页 `collapsedHeight` 与影视页一致地按高度 55% 封顶；矮屏 `minimumInfoHeight` 归零 |
| 播放 | `playback_page_layout.dart` | 信息栏宽度由固定 380dp 改为 `min(380, max(240, 宽度 × 0.38))`；折叠播放器高度按可用高度封顶；**新增可选 `leftContent`**：在 `wide` 模式下若传入，则左栏改为「播放器（16:9、按可用高度 60% 封顶）+ 左栏内容滚动」、右栏全高为 `info`，实现平板横屏「左播放器 + 视频信息、右评论区」的浏览式布局 |
| 播放 | `video_screen.dart` | 横屏且无稍后再看队列时，把视频信息 `content` 作为 `leftContent` 传入；右栏 `info` 改为「评论 / 相关视频推荐」两个 Tab（默认评论）。`_tab` 初始化在 `wide` 下把评论映射到 tab 0；非 `wide` 时保持原「简介 / 评论」语义 |
| 页面 | router / search / settings / messages / downloads / history / profile / video_card / 两个播放弹窗等 | 断点统一走 `AppLayout.compactOf` |

保留未改的宽度判定：`audio_playback_view.dart`（按高度判定封面尺寸）、`playback_timeline_bar.dart`（无 `BuildContext` 的静态高度计算，横屏下最多多占 8dp）、以及若干 `>= 720` 的次级列判断（横屏下双栏本身可用）。

## 测试

- `test/core/phone_landscape_layout_test.dart`：`phoneLandscape` / `compactExtent` 的边界值、平台门禁；`AppLayout` 在竖屏手机、横屏手机、桌面矮窗三种视口下的 BuildContext 结果。
- `test/features/settings/phone_landscape_setting_test.dart`：默认值、`copyWith`、旧快照（schemaVersion 42）回退、持久化与控制器写入。

## 验证边界

本次改动为源码级重构，**未执行 Flutter 3.47.6 工具链、未构建 APK、未在真机横屏验证**。仍需按仓库约定补做：

1. `.\tool\check.ps1`（格式、`flutter analyze`、`flutter test` 及四个包）；
2. `.\tool\build-android-development.ps1 -Mode Release -Install -DeviceId <id>` 后，在真机检查：旋转到横屏后是否按系统旋转锁响应、状态栏与挖孔安全区、底栏触摸目标、卡片首屏可见行数、视频页左右分栏与退出全屏后的方向恢复；
3. 关闭「允许手机横屏浏览」后回归旧的竖屏锁定与旋转自动全屏路径。

特别留意：Android 的 `setPreferredOrientations([])` 是否完全遵从系统旋转锁，以及全屏播放退出时 `keepsBrowsePortrait == false` 分支的等待逻辑，都需要真机确认。
