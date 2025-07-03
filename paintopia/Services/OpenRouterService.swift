// OpenRouter多模态AI服务
// 使用Qwen2.5-VL模型进行图像分析

import Foundation
import UIKit

// 该服务已废弃，所有功能由后端统一实现
class OpenRouterService: ObservableObject {}

enum OpenRouterError: Error, LocalizedError {
    case missingAPIKey
    case imageConversionFailed
    case noData
    case invalidResponse
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "缺少 OpenRouter API Key"
        case .imageConversionFailed:
            return "图片转换失败"
        case .noData:
            return "服务器未返回数据"
        case .invalidResponse:
            return "服务器响应错误"
        case .custom(let msg):
            return msg
        }
    }
} 