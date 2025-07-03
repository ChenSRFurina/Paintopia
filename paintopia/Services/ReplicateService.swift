// Replicate AI服务
// 提供图片上传和AI模型调用功能

import Foundation
import UIKit

// 该服务已废弃，所有功能由后端统一实现
class ReplicateService {}

enum ReplicateError: Error, LocalizedError {
    case imageConversionFailed
    case noData
    case invalidResponse
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed: return "图片转换失败"
        case .noData: return "无数据返回"
        case .invalidResponse: return "服务器响应格式错误"
        case .custom(let msg): return msg
        }
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
} 