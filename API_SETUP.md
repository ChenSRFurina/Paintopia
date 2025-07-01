# Paintopia API 设置指南

## OpenRouter API 配置

Paintopia 使用 OpenRouter 的 Qwen2.5-VL 模型来分析绘画并提供建议。

### 1. 获取 OpenRouter API Key

1. 访问 [OpenRouter](https://openrouter.ai/)
2. 注册账户并登录
3. 在控制台中创建新的 API key
4. 复制生成的 API key

### 2. 配置 API Key

支持三种配置方式，按优先级排序：

#### 方式一：.env 文件（推荐）

1. 运行设置脚本：
   ```bash
   ./setup_api.sh
   ```
   选择选项 A 创建 .env 文件

2. 或者手动创建：
   ```bash
   cp env.template .env
   ```

3. 编辑 .env 文件：
   ```
   OPENROUTER_API_KEY=your_actual_api_key_here
   ```

**注意**：.env 文件已被添加到 .gitignore，不会被提交到版本控制。

#### 方式二：Xcode 环境变量

在 Xcode 中设置环境变量：

1. 选择项目 → Edit Scheme
2. 选择 Run → Arguments → Environment Variables
3. 添加变量：
   - Name: `OPENROUTER_API_KEY`
   - Value: 你的 API key

#### 方式二：Info.plist 配置

在项目的 Info.plist 文件中添加：

```xml
<key>OpenRouterAPIKey</key>
<string>your_actual_api_key_here</string>
```

#### 方式三：配置文件

1. 复制模板文件：
   ```bash
   cp paintopia/Config/config.template.plist paintopia/Config/config.plist
   ```

2. 编辑 `paintopia/Config/config.plist` 文件：
   ```xml
   <key>OpenRouterAPIKey</key>
   <string>your_actual_api_key_here</string>
   ```

**注意**：config.plist 文件已被添加到 .gitignore，不会被提交到版本控制。

### 3. 配置优先级

系统按以下顺序查找 API key：
1. .env 文件中的 `OPENROUTER_API_KEY`
2. Xcode 环境变量 `OPENROUTER_API_KEY`
3. Info.plist 中的 `OpenRouterAPIKey`
4. config.plist 文件中的 `OpenRouterAPIKey`
5. 默认值（需要用户配置）

### 4. 功能说明

配置完成后，你可以：

1. 在绘画界面点击"截图分析"按钮
2. 系统会自动截取当前画布
3. 将截图发送给 Qwen2.5-VL 模型分析
4. 获得约30字的绘画建议

### 5. 安全建议

- **生产环境**：使用环境变量方式，避免将 API key 提交到代码仓库
- **开发环境**：可以使用配置文件方式，但确保不要提交真实的 API key
- 定期轮换 API key
- 监控 API 使用量

### 6. 故障排除

如果遇到问题：

1. 检查 API key 是否正确配置
2. 确认网络连接
3. 查看控制台错误信息
4. 确认 OpenRouter 账户有足够的配额
5. 检查配置优先级是否正确

### 7. 开发提示

- 如果 API key 未配置，应用会显示提示信息
- 截图分析按钮在未配置时会自动禁用
- 可以在运行时动态检查配置状态 