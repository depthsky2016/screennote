# ScreenNote (截图笔记) - Codex 开发指南

## 项目概述
截图笔记是一款 iOS App，核心功能为截图导入、OCR 识别、AI 摘要与搜索整理。
技术栈：SwiftUI + SwiftData + Vision Framework + Kimi API。

## 当前工作目录
- 项目根目录：`/Users/wujiang/Downloads/03-开发项目/截图笔记`
- 所有代码、工程和资源均放在当前目录下

## 关键约定
- 语言：Swift 5.9+，部署目标 iOS 17.0
- 架构：MVVM + Repository Pattern
- 异步：Swift Concurrency
- UI：纯 SwiftUI，系统 API 通过桥接调用
- 数据：SwiftData，注册 `Note`、`Tag`、`NoteFolder`
- LLM：Kimi OpenAI 兼容接口，模型默认 `kimi-k2.5`
- API Key：仅存 Keychain，不写入 UserDefaults

## 开发顺序
1. 项目骨架和数据层
2. 笔记列表和导入
3. 截图监听提示
4. OCR
5. Kimi 摘要
6. AI 流水线
7. 详情编辑
8. 搜索
9. 批量导入
10. 设置与上架准备

## 构建命令
```bash
xcodegen generate
xcodebuild -scheme ScreenNote -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```
