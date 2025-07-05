import Foundation
import UIKit

// AI处理结果结构体
struct AIProcessingResult {
    let recognition: String     // AI识别结果
    let suggestion: String      // AI建议
    let story: String          // 生成的故事
    let success: Bool          // 处理是否成功
    let error: String?         // 错误信息（如果有）
}

enum APIError: LocalizedError {
    case invalidURL
    case invalidData
    case invalidResponse
    case networkError(Error)
    case serverError(Int)
    case connectionRefused
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .invalidData:
            return "无效的数据"
        case .invalidResponse:
            return "无效的服务器响应"
        case .networkError(let error):
            return "网络错误：\(error.localizedDescription)"
        case .serverError(let code):
            return "服务器错误（\(code)）"
        case .connectionRefused:
            return "连接被拒绝"
        }
    }
}

class DoodleAPIClient {
    static let shared = DoodleAPIClient()
    
    private let baseURL = "http://10.4.176.7:8000"
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60  // 增加超时时间，因为后端需要处理AI
        config.timeoutIntervalForResource = 300
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        session = URLSession(configuration: config)
    }
    
    // 测试服务器连接
    func testConnection(completion: @escaping (Bool) -> Void) {
        let endpoint = "\(baseURL)/api/health"
        guard let url = URL(string: endpoint) else {
            print("错误：无效的URL - \(endpoint)")
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        print("正在测试连接：\(endpoint)")
        print("缓存策略：\(request.cachePolicy.rawValue)")
        
        session.dataTask(with: request) { data, response, error in
            if let error = error as NSError? {
                print("连接测试错误：\(error.localizedDescription)")
                print("错误域：\(error.domain)")
                print("错误代码：\(error.code)")
                
                if error.code == -1004 && error.domain == NSURLErrorDomain {
                    print("连接被拒绝，可能是服务器未运行或无法访问")
                }
                completion(false)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("错误：未收到HTTP响应")
                completion(false)
                return
            }
            
            print("服务器响应状态码：\(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200,
                  let data = data,
                  let responseStr = String(data: data, encoding: .utf8) else {
                print("错误：无效的响应状态码或数据")
                completion(false)
                return
            }
            
            print("服务器响应内容：\(responseStr)")
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: String],
                   let status = json["status"],
                   status == "ok" {
                    print("服务器状态正常")
                    completion(true)
                } else {
                    print("错误：无效的状态响应")
                    completion(false)
                }
            } catch {
                print("JSON解析错误：\(error.localizedDescription)")
                completion(false)
            }
        }.resume()
    }
    
    // 上传涂鸦图片并获取AI处理结果
    func uploadDoodle(imageData: Data, completion: @escaping (Result<AIProcessingResult, Error>) -> Void) {
        // 生成唯一请求ID用于调试
        let requestId = UUID().uuidString.prefix(8)
        print("🚀 [请求\(requestId)] 开始上传涂鸦图片...")
        
        let endpoint = "\(baseURL)/api/image/analyze"
        guard let url = URL(string: endpoint) else {
            print("❌ [请求\(requestId)] 无效的URL - \(endpoint)")
            completion(.failure(APIError.invalidURL))
            return
        }
        
        // 处理图片数据，确保正确的 alpha 通道
        guard let image = UIImage(data: imageData),
              let processedData = processImageForUpload(image) else {
            print("❌ [请求\(requestId)] 图片处理失败")
            completion(.failure(APIError.invalidData))
            return
        }
        
        // 将图片数据转换为 base64
        let base64String = processedData.base64EncodedString()
        let base64Preview = String(base64String.prefix(50)) + "..."
        print("📷 [请求\(requestId)] 图片处理完成，base64预览: \(base64Preview)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.cachePolicy = .reloadIgnoringLocalCacheData // 确保不使用缓存
        
        // 新接口body
        var jsonBody: [String: Any] = [
            "image_data": base64String,
            "text": "请分析这幅画并给出建议"
        ]
        // 如果后续需要支持会话，可以这样加：
        // if let sessionId = ... { jsonBody["session_id"] = sessionId }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonBody)
            request.httpBody = jsonData
            
            print("📤 [请求\(requestId)] 正在发送API请求...")
            print("   - URL：\(endpoint)")
            print("   - Content-Type：application/json")
            print("   - 请求体大小：\(jsonData.count) 字节")
            print("   - 缓存策略：不使用缓存")
            
            session.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ [请求\(requestId)] 网络错误：\(error.localizedDescription)")
                    completion(.failure(APIError.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ [请求\(requestId)] 未收到 HTTP 响应")
                    completion(.failure(APIError.invalidResponse))
                    return
                }
                
                print("📡 [请求\(requestId)] 服务器响应状态码：\(httpResponse.statusCode)")
                
                guard let data = data else {
                    print("❌ [请求\(requestId)] 未收到响应数据")
                    completion(.failure(APIError.invalidData))
                    return
                }
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📥 [请求\(requestId)] 服务器响应内容：\(responseString)")
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        // 检查是否有错误
                        if let errorMessage = json["error"] as? String {
                            print("❌ [请求\(requestId)] 服务器错误：\(errorMessage)")
                            completion(.failure(NSError(domain: "DoodleAPIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                            return
                        }
                        
                        // 检查是否是新格式（包含success字段）
                        if json["success"] != nil {
                            // 新格式：解析完整的AI处理结果
                            let recognition = json["recognition"] as? String ?? ""
                            let suggestion = json["suggestion"] as? String ?? ""
                            let story = json["story"] as? String ?? ""
                            let success = json["success"] as? Bool ?? false
                            let error = json["error"] as? String
                            
                            let result = AIProcessingResult(
                                recognition: recognition,
                                suggestion: suggestion,
                                story: story,
                                success: success,
                                error: error
                            )
                            
                            print("✅ [请求\(requestId)] AI处理成功（新格式）")
                            print("   - 识别：\(recognition)")
                            print("   - 建议：\(suggestion)")
                            print("   - 故事长度：\(story.count)字符")
                            
                            completion(.success(result))
                        } else if let oldResult = json["result"] as? String {
                            // 旧格式：兼容处理，将result作为识别结果
                            print("⚠️ [请求\(requestId)] 收到旧格式响应，进行兼容处理")
                            
                            // 生成简单的建议和故事
                            let suggestion = "根据AI识别的内容，你可以尝试添加更多细节和色彩让画面更丰富。"
                            let story = "基于你的画作，AI识别出：\(oldResult)\n\n这是一个很有创意的开始！继续发挥你的想象力，为这个作品添加更多元素吧。"
                            
                            let result = AIProcessingResult(
                                recognition: oldResult,
                                suggestion: suggestion,
                                story: story,
                                success: true,
                                error: nil
                            )
                            
                            print("✅ [请求\(requestId)] AI处理成功（兼容模式）")
                            print("   - 识别：\(oldResult)")
                            print("   - 建议：\(suggestion)")
                            print("   - 故事长度：\(story.count)字符")
                            
                            completion(.success(result))
                        } else {
                            print("❌ [请求\(requestId)] 无效的响应格式，JSON: \(json)")
                            completion(.failure(APIError.invalidData))
                        }
                    } else {
                        print("❌ [请求\(requestId)] 无法解析 JSON 响应")
                        completion(.failure(APIError.invalidData))
                    }
                } catch {
                    print("❌ [请求\(requestId)] JSON 解析错误：\(error.localizedDescription)")
                    completion(.failure(APIError.invalidData))
                }
            }.resume()
        } catch {
            print("JSON 编码错误：\(error.localizedDescription)")
            completion(.failure(APIError.invalidData))
        }
    }
    
    // 处理图片上传的辅助方法
    private func processImageForUpload(_ image: UIImage) -> Data? {
        // 确保图片具有正确的 alpha 通道
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        let processedImage = renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        
        return processedImage.pngData()
    }
}

 