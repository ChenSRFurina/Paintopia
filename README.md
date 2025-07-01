# Paintopia 🎨

> 多端自由绘画 × AI 智能分析 × 卡通绘本生成

---

## ✨ 项目简介

Paintopia 是一款支持 **iOS 15+** 和 **macOS 12+** 的 SwiftUI 跨端绘画与智能绘本生成软件。

- **自由绘画**：多色多笔刷、橡皮擦、撤销、响应式画布
- **AI 智能建议**：一键截图，AI 分析画面并给出创作建议
- **卡通绘本生成**：AI 总结画面内容，自动生成卡通风格图片和故事文本
- **多端适配**：iPhone、iPad、Mac Catalyst 全面支持

---

## 🖼️ 主要功能

- **三栏主界面**：左侧工具栏、中间画布、右侧建议区
- **画布截图**：一键截取当前画布内容，顶部缩略图预览
- **AI 建议区**：调用 GPT-4o 多模态模型，分析画面并给出约30字建议
- **生成绘本**：
  1. 画布截图 → AI 总结内容
  2. 用总结内容+卡通风格 prompt 生成 DALL·E 3 图片
  3. 再用新图片生成故事文本
  4. 页面展示生成图片和故事
- **错误与状态提示**：全流程 loading、错误、成功提示，用户体验友好

---

## 🚀 快速开始

### 1. 克隆项目
```bash
git clone https://github.com/ChenSRFurina/Paintopia.git
cd Paintopia
```

### 2. 配置 AI API Key
- 支持 .env、Info.plist、环境变量多种方式
- 推荐在根目录创建 `.env` 文件：
  ```
  AIGC_API_KEY=你的AIGC多模态API key
  DALLE_API_KEY=你的DALL·E 3 API key
  ```
- 详细配置见 [API_SETUP.md](API_SETUP.md)

### 3. 打开项目
```bash
open paintopia.xcodeproj
```

### 4. 运行
- 选择 iOS/macOS 目标设备，点击运行
- 体验自由绘画、AI 智能建议与绘本生成

---

## 🛠️ 技术栈
- **SwiftUI** 跨端开发
- **UIKit** 局部渲染与截图
- **AIGC GPT-4o** 多模态 API（图片+文本分析）
- **DALL·E 3** 文生图 API
- **MVVM 架构**

---

## 📁 目录结构
```
paintopia/
├── Views/           # 视图组件（主界面、画布、建议区、生成页等）
├── Models/          # 数据模型
├── Services/        # AI 服务（AIGC、DALL·E 3 等）
├── Config/          # 配置文件与 API Key 读取
├── Utils/           # 工具类（环境变量、截图等）
└── Assets.xcassets/ # 资源文件
```

---

## ⚡ 特色亮点
- **AI 智能建议与生成**：全流程自动化，支持多模态理解与创作
- **卡通绘本风格**：生成图片始终为卡通绘本风格，适合儿童与创意场景
- **极简配置**：API Key 支持多种方式，开发/生产环境灵活切换
- **高可扩展性**：支持自定义 prompt、模型切换、更多 AI 服务集成

---

## 📝 开发者须知
- 推荐 Xcode 14.0+，Swift 5.7+
- 画布截图与建议区用到 ImageRenderer，需 iOS 16+/macOS 13+
- 详细 API 配置与常见问题见 [API_SETUP.md](API_SETUP.md)
- 代码结构清晰，便于二次开发与功能扩展

---

## 📮 联系与贡献
- 欢迎 issue/PR 反馈建议与 bug
- 适合 AI 创意绘画、儿童教育、AI 绘本创作等场景

---

> Paintopia —— 让每个人都能用 AI 创作属于自己的卡通绘本！ 