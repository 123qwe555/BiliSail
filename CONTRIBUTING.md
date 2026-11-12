# 参与贡献（Contributing）

感谢你关注 BiliSail（哔帆）个人改造版。本仓库以学习交流与编程技术研究为目的，
欢迎通过 Issue 与 Pull Request 反馈问题、提出改进或补充文档。

> 更完整的工程约定（代码风格、文档、测试与交付规则）请先阅读 [AGENTS.md](AGENTS.md)。

## 反馈问题（Issue）

- 选择最合适的模板：缺陷报告 / 功能建议 / 使用求助 / 文档问题。
- 至少包含：**应用版本、操作系统与设备、复现步骤、预期与实际结果**。
- 播放问题可提供公开视频 BV 号与脱敏诊断（应用数据目录 `logs` 下）。
- **请勿提交** Cookie、token、登录二维码 key，或带签名参数的媒体 URL。

## 提出改进（PR）

1. 较大的功能或架构调整，建议先开 Issue 讨论背景与方案。
2. 从 `main` 切出特性分支，保持改动聚焦、提交信息清晰。
3. 在 PR 中说明：变更内容、验证结果、未覆盖的平台或场景。
4. 代码改动请运行 `tool/check.ps1`（格式、静态分析、离线测试）。
5. 涉及原生播放的改动，补充受影响平台的构建与实机验证。
6. 纯文档改动，检查链接、路径与内容一致性即可。

## 开发环境

- 固定使用 **Flutter 3.47.6 stable / Dart 3.13.5**。
- 依赖通过 `flutter pub get` 解析（`media_kit`、`fvp`、`canvas_danmaku` 为固定 fork 提交，
  首次获取需能访问 GitHub）。
- 三端原生资产准备见 [packages/bili_mux/README.md](packages/bili_mux/README.md)。

## 行为准则

参与本仓库的沟通与协作，请遵守 [行为准则](CODE_OF_CONDUCT.md)。

## 许可证

本仓库当前为 **All Rights Reserved（保留所有权利）**，未采用开源许可证。提交贡献即表示
你理解：你的贡献可能被本仓库以与当前许可一致的方式使用，且不自动获得再分发授权。
详见 [LICENSE](LICENSE)。
