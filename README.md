# Paintopia 🎨

一个支持 iOS 15+ 和 macOS 12+ 的多端绘画与绘本生成软件，集成了 AI 智能分析功能。

## ✨ 主要功能

- **多端支持**: iOS 15+ 和 macOS 12+ 跨平台
- **自由绘画**: 支持多种颜色和笔刷大小
- **智能橡皮擦**: 精确擦除绘画内容
- **AI 分析**: 使用 Qwen2.5-VL 模型分析绘画并提供建议
- **响应式布局**: 完美适配 iPad 横屏和 Mac 窗口

## 🚀 快速开始

### 1. 克隆项目
```bash
git clone <repository-url>
cd paintopia
```

### 2. 配置 AI 功能（可选）
```bash
./setup_api.sh
```

### 3. 打开项目
```bash
open paintopia.xcodeproj
```

### 4. 运行应用
选择目标设备（iPhone、iPad 或 Mac）并运行项目。

## 🤖 AI 功能配置

Paintopia 集成了 OpenRouter 的 Qwen2.5-VL 视觉语言模型，可以为你的绘画提供智能建议。

### 配置方式

1. **快速配置**: 运行 `./setup_api.sh`
2. **手动配置**: 参考 [API_SETUP.md](API_SETUP.md)
3. **环境变量**: 在 Xcode 中设置 `OPENROUTER_API_KEY`

### 使用 AI 功能

1. 在绘画界面进行创作
2. 点击右侧"截图分析"按钮
3. AI 将分析你的绘画并提供约30字的改进建议

## 📱 界面布局

- **左侧**: 工具栏（颜色选择、笔刷大小、橡皮擦）
- **中间**: 画布区域（自由绘画）
- **右侧**: 智能建议区（AI 分析结果）

## 🛠️ 技术栈

- **框架**: SwiftUI
- **平台**: iOS 15+, macOS 12+
- **AI 模型**: Qwen2.5-VL (通过 OpenRouter)
- **架构**: MVVM

## 📁 项目结构

```
paintopia/
├── Views/           # 视图组件
├── Models/          # 数据模型
├── Services/        # 服务层（AI API）
├── Config/          # 配置文件
├── Utils/           # 工具类
└── Assets.xcassets/ # 资源文件
```

## 🔧 开发

### 环境要求
- Xcode 14.0+
- iOS 15.0+ / macOS 12.0+
- Swift 5.7+

### 构建
```bash
xcodebuild -project paintopia.xcodeproj -scheme paintopia build
```

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📞 支持

如有问题，请查看 [API_SETUP.md](API_SETUP.md) 或提交 Issue。 