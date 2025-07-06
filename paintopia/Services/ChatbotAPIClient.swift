// 聊天助手API客户端
// 处理与FractFlow后端的通信，包括LLM对话、VLM图像分析和会话管理

import Foundation
import UIKit

// MARK: - 数据模型
struct ChatSession {
    let sessionId: String
    let createdAt: Date
}

struct ChatHistoryItem {
    let role: String // "user" or "assistant"
    let content: String
    let timestamp: String
    let imageData: String?
}

struct ChatResponse {
    let success: Bool
    let response: String
    let sessionId: String
    let error: String?
}

struct ImageAnalysisResponse {
    let success: Bool
    let response: String
    let sessionId: String
    let analysis: String?
    let error: String?
}

struct SessionResponse {
    let success: Bool
    let sessionId: String?
    let message: String?
    let error: String?
}

struct ObserveReplyResponse {
    let success: Bool
    let llmReply: String
    let visionDesc: String
    let sessionId: String
    let error: String?
}

// MARK: - API客户端
class ChatbotAPIClient: ObservableObject {
    static let shared = ChatbotAPIClient()
    
    // 支持多种环境配置
    private let baseURL: String = {
        #if DEBUG
        // 开发环境 - 使用你的Mac的IP地址
        // 请根据你的实际IP地址修改
        return "http://10.4.176.7:8000"  // 替换为你的Mac的IP地址
        #else
        // 生产环境
        return "https://your-production-server.com"
        #endif
    }()
    
    private let session = URLSession.shared
    
    @Published var currentSessionId: String?
    @Published var isConnected = false
    
    private init() {}
    
    // MARK: - 网络连接测试
    
    /// 测试网络连接
    func testConnection(completion: @escaping (Bool, String?) -> Void) {
        // 使用会话创建端点来测试连接，因为这个端点一定存在
        let url = URL(string: "\(baseURL)/api/session/new")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0
        
        print("🔍 测试聊天API连接: \(baseURL)")
        
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 聊天API连接测试失败: \(error.localizedDescription)")
                    completion(false, "连接失败: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 聊天API HTTP状态码: \(httpResponse.statusCode)")
                    // 只要不是404就认为连接成功（可能是401、400等，但至少服务在运行）
                    if httpResponse.statusCode != 404 {
                        completion(true, nil)
                    } else {
                        completion(false, "服务器响应错误: \(httpResponse.statusCode)")
                    }
                } else {
                    completion(false, "无效的响应")
                }
            }
        }.resume()
    }
    
    // MARK: - 会话管理
    
    /// 创建新的聊天会话
    func createNewSession(completion: @escaping (Result<SessionResponse, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/api/session/new")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0 // 30秒超时
        
        let requestId = UUID().uuidString.prefix(8)
        print("🚀 [请求\(requestId)] 创建新聊天会话...")
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ [请求\(requestId)] 网络错误: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("❌ [请求\(requestId)] 响应数据为空")
                completion(.failure(NSError(domain: "NoData", code: 0, userInfo: nil)))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 [请求\(requestId)] 服务器响应状态码: \(httpResponse.statusCode)")
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("📥 [请求\(requestId)] 服务器响应: \(json)")
                    
                    let sessionResponse = SessionResponse(
                        success: json["success"] as? Bool ?? false,
                        sessionId: json["session_id"] as? String,
                        message: json["message"] as? String,
                        error: json["error"] as? String
                    )
                    
                    if sessionResponse.success, let sessionId = sessionResponse.sessionId {
                        DispatchQueue.main.async {
                            self.currentSessionId = sessionId
                        }
                        print("✅ [请求\(requestId)] 会话创建成功: \(sessionId)")
                    }
                    
                    completion(.success(sessionResponse))
                }
            } catch {
                print("❌ [请求\(requestId)] JSON解析错误: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - 文本对话
    
    /// 发送文本消息给LLM
    /// 新增observeCanvasHandler参数
    func sendTextMessage(_ text: String, observeCanvasHandler: ((String?) -> Void)? = nil, completion: @escaping (Result<ChatResponse, Error>, [String: Any]?) -> Void) {
        let url = URL(string: "\(baseURL)/api/chat")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60.0 // 60秒超时
        
        let requestBody: [String: Any] = [
            "text": text,
            "session_id": currentSessionId as Any
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error), nil)
            return
        }
        
        let requestId = UUID().uuidString.prefix(8)
        print("🚀 [请求\(requestId)] 发送文本消息: \(text.prefix(50))...")
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ [请求\(requestId)] 网络错误: \(error.localizedDescription)")
                completion(.failure(error), nil)
                return
            }
            
            guard let data = data else {
                print("❌ [请求\(requestId)] 响应数据为空")
                completion(.failure(NSError(domain: "NoData", code: 0, userInfo: nil)), nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 [请求\(requestId)] 服务器响应状态码: \(httpResponse.statusCode)")
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("📥 [请求\(requestId)] 服务器响应: \(json)")
                    
                    // 检查command字段
                    if let command = json["command"] as? String, command == "observe_canvas" {
                        let sessionId = json["session_id"] as? String
                        DispatchQueue.main.async {
                            observeCanvasHandler?(sessionId)
                        }
                    }
                    
                    let chatResponse = ChatResponse(
                        success: json["success"] as? Bool ?? false,
                        response: json["response"] as? String ?? "",
                        sessionId: json["session_id"] as? String ?? "",
                        error: json["error"] as? String
                    )
                    
                    if chatResponse.success {
                        print("✅ [请求\(requestId)] 对话成功")
                    } else {
                        print("⚠️ [请求\(requestId)] 对话失败: \(chatResponse.error ?? "未知错误")")
                    }
                    
                    completion(.success(chatResponse), json)
                }
            } catch {
                print("❌ [请求\(requestId)] JSON解析错误: \(error)")
                completion(.failure(error), nil)
            }
        }.resume()
    }
    
    // MARK: - 观察画布并回复
    
    /// 观察画布并生成综合回复（文字+语音）
    func observeAndReply(_ image: UIImage, completion: @escaping (Result<ObserveReplyResponse, Error>, [String: Any]?) -> Void) {
        let url = URL(string: "\(baseURL)/api/observe-and-reply")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120.0 // 2分钟超时
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "图片转换失败"])), nil)
            return
        }
        
        let base64Image = imageData.base64EncodedString()
        
        let requestBody: [String: Any] = [
            "image_data": base64Image,
            "session_id": currentSessionId as Any
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error), nil)
            return
        }
        
        let requestId = UUID().uuidString.prefix(8)
        print("🚀 [请求\(requestId)] 观察画布并回复，图片大小: \(imageData.count) bytes")
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ [请求\(requestId)] 网络错误: \(error.localizedDescription)")
                completion(.failure(error), nil)
                return
            }
            
            guard let data = data else {
                print("❌ [请求\(requestId)] 响应数据为空")
                completion(.failure(NSError(domain: "NoData", code: 0, userInfo: nil)), nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 [请求\(requestId)] 服务器响应状态码: \(httpResponse.statusCode)")
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("📥 [请求\(requestId)] 服务器响应: \(json)")
                    
                    let observeResponse = ObserveReplyResponse(
                        success: json["success"] as? Bool ?? false,
                        llmReply: json["llm_reply"] as? String ?? "",
                        visionDesc: json["vision_desc"] as? String ?? "",
                        sessionId: json["session_id"] as? String ?? "",
                        error: json["error"] as? String
                    )
                    
                    if observeResponse.success {
                        print("✅ [请求\(requestId)] 画布观察成功")
                    } else {
                        print("⚠️ [请求\(requestId)] 画布观察失败: \(observeResponse.error ?? "未知错误")")
                    }
                    
                    completion(.success(observeResponse), json)
                }
            } catch {
                print("❌ [请求\(requestId)] JSON解析错误: \(error)")
                completion(.failure(error), nil)
            }
        }.resume()
    }
    
    // MARK: - 图像分析
    
    /// 分析图像内容
    func analyzeImage(_ image: UIImage, completion: @escaping (Result<ImageAnalysisResponse, Error>, [String: Any]?) -> Void) {
        let url = URL(string: "\(baseURL)/api/analyze")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60.0 // 60秒超时
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "图片转换失败"])), nil)
            return
        }
        
        let base64Image = imageData.base64EncodedString()
        
        let requestBody: [String: Any] = [
            "image_data": base64Image,
            "session_id": currentSessionId as Any
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error), nil)
            return
        }
        
        let requestId = UUID().uuidString.prefix(8)
        print("🚀 [请求\(requestId)] 分析图像，图片大小: \(imageData.count) bytes")
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ [请求\(requestId)] 网络错误: \(error.localizedDescription)")
                completion(.failure(error), nil)
                return
            }
            
            guard let data = data else {
                print("❌ [请求\(requestId)] 响应数据为空")
                completion(.failure(NSError(domain: "NoData", code: 0, userInfo: nil)), nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 [请求\(requestId)] 服务器响应状态码: \(httpResponse.statusCode)")
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("📥 [请求\(requestId)] 服务器响应: \(json)")
                    
                    let analysisResponse = ImageAnalysisResponse(
                        success: json["success"] as? Bool ?? false,
                        response: json["response"] as? String ?? "",
                        sessionId: json["session_id"] as? String ?? "",
                        analysis: json["analysis"] as? String,
                        error: json["error"] as? String
                    )
                    
                    if analysisResponse.success {
                        print("✅ [请求\(requestId)] 图像分析成功")
                    } else {
                        print("⚠️ [请求\(requestId)] 图像分析失败: \(analysisResponse.error ?? "未知错误")")
                    }
                    
                    completion(.success(analysisResponse), json)
                }
            } catch {
                print("❌ [请求\(requestId)] JSON解析错误: \(error)")
                completion(.failure(error), nil)
            }
        }.resume()
    }
    
    // MARK: - 获取会话历史
    
    /// 获取当前会话的聊天历史
    func getSessionHistory(completion: @escaping (Result<[ChatHistoryItem], Error>) -> Void) {
        guard let sessionId = currentSessionId else {
            completion(.failure(NSError(domain: "NoSession", code: 0, userInfo: [NSLocalizedDescriptionKey: "无活跃会话"])))
            return
        }
        
        let url = URL(string: "\(baseURL)/api/session/history")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0 // 30秒超时
        
        let requestBody: [String: Any] = [
            "session_id": sessionId
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        let requestId = UUID().uuidString.prefix(8)
        print("🚀 [请求\(requestId)] 获取会话历史: \(sessionId)")
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ [请求\(requestId)] 网络错误: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("❌ [请求\(requestId)] 响应数据为空")
                completion(.failure(NSError(domain: "NoData", code: 0, userInfo: nil)))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success,
                   let historyArray = json["history"] as? [[String: Any]] {
                    
                    let historyItems = historyArray.compactMap { item -> ChatHistoryItem? in
                        guard let role = item["role"] as? String,
                              let content = item["content"] as? String,
                              let timestamp = item["timestamp"] as? String else {
                            return nil
                        }
                        
                        return ChatHistoryItem(
                            role: role,
                            content: content,
                            timestamp: timestamp,
                            imageData: item["image_data"] as? String
                        )
                    }
                    
                    print("✅ [请求\(requestId)] 获取到 \(historyItems.count) 条历史记录")
                    completion(.success(historyItems))
                } else {
                    print("❌ [请求\(requestId)] 历史记录解析失败")
                    completion(.failure(NSError(domain: "ParseError", code: 0, userInfo: nil)))
                }
            } catch {
                print("❌ [请求\(requestId)] JSON解析错误: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - TTS 文本转语音
    
    /// 基于文本生成音频
    func generateTTS(text: String, completion: @escaping (Result<Data, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/api/tts")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60.0 // 60秒超时，TTS通常需要较长时间
        
        let requestBody: [String: Any] = [
            "text": text,
            "session_id": currentSessionId as Any
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        let requestId = UUID().uuidString.prefix(8)
        print("🎵 [请求\(requestId)] 发送TTS请求，文本: \(text.prefix(50))...")
        print("🎵 [请求\(requestId)] TTS超时设置: \(request.timeoutInterval)秒")
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ [请求\(requestId)] TTS网络错误: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("❌ [请求\(requestId)] TTS响应数据为空")
                completion(.failure(NSError(domain: "NoData", code: 0, userInfo: nil)))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 [请求\(requestId)] TTS响应状态码: \(httpResponse.statusCode)")
            }
            
            // 检查是否是JSON错误响应
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // 检查是否有错误字段
                if let error = json["error"] as? String, !error.isEmpty {
                    print("❌ [请求\(requestId)] TTS错误: \(error)")
                    completion(.failure(NSError(domain: "TTSError", code: 0, userInfo: [NSLocalizedDescriptionKey: error])))
                    return
                }
                
                // 检查是否有base64音频数据
                if let audioBase64 = json["audio_data"] as? String, !audioBase64.isEmpty {
                    if let audioData = Data(base64Encoded: audioBase64) {
                        print("✅ [请求\(requestId)] TTS成功，从base64解码音频，大小: \(audioData.count) bytes")
                        completion(.success(audioData))
                        return
                    } else {
                        print("❌ [请求\(requestId)] TTS base64解码失败")
                        completion(.failure(NSError(domain: "TTSError", code: 0, userInfo: [NSLocalizedDescriptionKey: "音频数据解码失败"])))
                        return
                    }
                }
                
                // 如果没有audio_data字段，检查其他可能的响应格式
                print("⚠️ [请求\(requestId)] TTS响应格式异常: \(json)")
            }
            
            // 检查原始数据大小
            if data.count < 100 {
                print("❌ [请求\(requestId)] TTS响应数据过小 (\(data.count) bytes)，可能是错误信息")
                if let errorText = String(data: data, encoding: .utf8) {
                    print("❌ [请求\(requestId)] 错误内容: \(errorText)")
                }
                completion(.failure(NSError(domain: "TTSError", code: 0, userInfo: [NSLocalizedDescriptionKey: "TTS响应数据异常"])))
                return
            }
            
            print("✅ [请求\(requestId)] TTS成功，音频数据大小: \(data.count) bytes")
            completion(.success(data))
        }.resume()
    }
} 