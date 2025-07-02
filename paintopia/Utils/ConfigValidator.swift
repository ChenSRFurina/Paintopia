// 配置验证器
// 验证API密钥配置的有效性

import Foundation

struct ConfigValidator {
    
    /// 验证 OpenRouter API 配置
    static func validateOpenRouterConfig() -> ConfigValidationResult {
        let apiKey = APIConfig.getOpenRouterAPIKey()
        
        if apiKey.isEmpty {
            return .failure("API Key 为空")
        }
        
        if apiKey == "your_openrouter_api_key_here" {
            return .failure("API Key 未配置，请使用默认值")
        }
        
        // 检查 API key 格式（OpenRouter API key 通常以 sk- 开头）
        if !apiKey.hasPrefix("sk-") {
            return .warning("API Key 格式可能不正确，OpenRouter API key 通常以 'sk-' 开头")
        }
        
        return .success("API Key 配置正确")
    }
    
    /// 获取配置来源信息
    static func getConfigSource() -> String {
        if EnvLoader.getEnv("OPENROUTER_API_KEY") != nil {
            return ".env 文件"
        } else if ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"] != nil {
            return "系统环境变量"
        } else if Bundle.main.object(forInfoDictionaryKey: "OpenRouterAPIKey") != nil {
            return "Info.plist"
        } else {
            return "默认值（未配置）"
        }
    }
}

enum ConfigValidationResult {
    case success(String)
    case warning(String)
    case failure(String)
    
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .warning, .failure:
            return false
        }
    }
    
    var message: String {
        switch self {
        case .success(let message):
            return message
        case .warning(let message):
            return "警告: \(message)"
        case .failure(let message):
            return "错误: \(message)"
        }
    }
} 