// AI 建议状态枚举
// 用于跟踪AI建议功能的不同状态

import Foundation

enum AISuggestionStatus {
    case idle
    case loading
    case success(String) // AI 建议
    case failure(String) // 错误信息
} 