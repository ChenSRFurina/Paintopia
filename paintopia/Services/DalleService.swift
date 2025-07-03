// DALL·E 3图像生成服务
// 调用DALL·E 3 API生成卡通绘本风格图片

import Foundation

// 该服务已废弃，所有功能由后端统一实现
class DalleService {}

enum DalleError: Error, LocalizedError {
    case missingAPIKey
    case invalidURL
    case noData
    case noImageURL
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "缺少 DALL·E 3 API Key"
        case .invalidURL: return "DALL·E 3 API 地址无效"
        case .noData: return "服务器未返回数据"
        case .noImageURL: return "未获取到图片 URL"
        }
    }
} 