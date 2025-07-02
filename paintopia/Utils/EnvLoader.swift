// 环境变量加载器
// 从.env文件加载API密钥等配置

import Foundation

struct EnvLoader {
    
    /// 从 .env 文件加载环境变量
    static func loadEnvFile() {
        guard let envPath = Bundle.main.path(forResource: ".env", ofType: nil) else {
            print("⚠️ 未找到 .env 文件")
            return
        }
        
        do {
            let envContent = try String(contentsOfFile: envPath, encoding: .utf8)
            let lines = envContent.components(separatedBy: .newlines)
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // 跳过空行和注释
                if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                    continue
                }
                
                // 解析 KEY=VALUE 格式
                if let equalIndex = trimmedLine.firstIndex(of: "=") {
                    let key = String(trimmedLine[..<equalIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let value = String(trimmedLine[trimmedLine.index(after: equalIndex)...]).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // 移除引号
                    let cleanValue = value.replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: "'", with: "")
                    
                    // 设置环境变量
                    setenv(key, cleanValue, 1)
                    print("✅ 加载环境变量: \(key)")
                }
            }
        } catch {
            print("❌ 读取 .env 文件失败: \(error)")
        }
    }
    
    /// 获取环境变量值
    static func getEnv(_ key: String) -> String? {
        return getenv(key).map { String(cString: $0) }
    }
} 