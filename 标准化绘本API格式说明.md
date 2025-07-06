# 标准化绘本API格式说明

## API接口

### 请求格式
```
POST /api/generate-storybook
Content-Type: application/json

{
    "image_data": "base64编码的图片数据",
    "session_id": "会话ID"
}
```

### 响应格式
```json
{
    "success": true,
    "stories": {
        "story1": {
            "page_number": 1,
            "title": "故事标题1",
            "content": "故事内容1"
        },
        "story2": {
            "page_number": 2,
            "title": "故事标题2", 
            "content": "故事内容2"
        }
    },
    "images": {
        "character_image": "base64编码的角色图片",
        "story_pages_images": [
            "base64编码的第1页图片",
            "base64编码的第2页图片"
        ]
    },
    "message": "成功消息"
}
```

## 前端处理流程

### 1. 发送请求
```swift
StorybookAPIClient.shared.generateStorybook(image: userImage) { result in
    switch result {
    case .success(let storybookData):
        // 处理成功响应
    case .failure(let error):
        // 处理错误
    }
}
```

### 2. 数据解析
- 解析 `stories` 对象，按 `page_number` 排序
- 解析 `images.story_pages_images` 数组，与故事页面一一对应
- 解析 `images.character_image` 作为封面图片

### 3. 创建绘本数据
```swift
struct StorybookData {
    let title: String
    let author: String
    let createdAt: Date
    let pages: [StorybookPage]
    let characterImage: UIImage?
}

struct StorybookPage {
    let text: String
    let title: String
    let imageData: UIImage?
    let pageNumber: Int
}
```

### 4. 显示绘本
- 封面页：显示角色图片或默认封面
- 内容页：每页显示对应的故事内容和图片
- 支持翻页浏览

## 主要特性

### 1. 多页故事支持
- 每页都有独立的标题和内容
- 按页码顺序排列
- 支持任意页数

### 2. 图片对应
- 每页故事都有对应的图片
- 角色图片作为封面
- 图片以base64格式传输

### 3. 标准化格式
- 统一的请求/响应格式
- 清晰的字段命名
- 易于扩展和维护

## 错误处理

### 常见错误
- 图片转换失败
- 网络请求失败
- JSON解析失败
- 生成失败

### 错误响应格式
```json
{
    "success": false,
    "message": "错误描述"
}
```

## 使用示例

### 完整流程
1. 用户绘制图片
2. 点击"生成绘本"按钮
3. 显示等待页面（支持30分钟等待）
4. 调用API生成绘本
5. 解析响应数据
6. 创建绘本对象
7. 显示绘本页面

### 代码示例
```swift
// 生成绘本
StorybookAPIClient.shared.generateStorybook(image: canvasImage) { result in
    DispatchQueue.main.async {
        switch result {
        case .success(let storybookData):
            // 显示绘本
            self.storybookData = storybookData
            self.showStorybookView = true
            
        case .failure(let error):
            // 显示错误
            self.errorMessage = error.localizedDescription
        }
    }
}
```

## 注意事项

1. **图片格式**：使用JPEG格式，压缩质量0.8
2. **Base64编码**：图片数据需要base64编码
3. **网络超时**：支持长时间等待（30分钟）
4. **错误处理**：完善的错误处理和用户提示
5. **内存管理**：及时释放图片数据，避免内存泄漏 