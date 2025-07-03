import Foundation
import UIKit

enum APIError: LocalizedError {
    case invalidURL
    case invalidData
    case invalidResponse
    case networkError(Error)
    case serverError(Int)
    case connectionRefused
    case webSocketError(Error)
    
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
        case .webSocketError(let error):
            return "WebSocket 错误：\(error.localizedDescription)"
        }
    }
}

class DoodleAPIClient {
    static let shared = DoodleAPIClient()
    
    private let baseURL = "http://10.4.176.7:8000"
    private let wsURL = "ws://10.4.176.7:8000/ws"
    private var webSocketClient: QwenVLWebSocketClient?
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        session = URLSession(configuration: config)
        
        setupWebSocket()
    }
    
    private func setupWebSocket() {
        webSocketClient = QwenVLWebSocketClient(url: wsURL)
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
    
    // WebSocket 连接测试
    func testWebSocketConnection(completion: @escaping (Bool) -> Void) {
        guard let webSocketClient = webSocketClient else {
            print("错误：WebSocket 客户端未初始化")
            completion(false)
            return
        }
        
        print("正在测试 WebSocket 连接：\(wsURL)")
        
        webSocketClient.connect()
        // 发送测试消息，使用 send(message:)，参数需加标签
        let pingMessage: [String: Any] = ["action": "ping"]
        webSocketClient.send(message: pingMessage) { error in
            if let error = error {
                print("ping 测试失败：\(error.localizedDescription)")
                webSocketClient.disconnect()
                completion(false)
            } else {
                print("收到 ping 响应")
                webSocketClient.disconnect()
                completion(true)
            }
        }
    }
    
    // 上传涂鸦图片
    func uploadDoodle(imageData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        let endpoint = "\(baseURL)/api/upload"
        guard let url = URL(string: endpoint) else {
            print("错误：无效的URL - \(endpoint)")
            completion(.failure(APIError.invalidURL))
            return
        }
        
        // 处理图片数据，确保正确的 alpha 通道
        guard let image = UIImage(data: imageData),
              let processedData = processImageForUpload(image) else {
            print("错误：图片处理失败")
            completion(.failure(APIError.invalidData))
            return
        }
        
        // 将图片数据转换为 base64
        let base64String = processedData.base64EncodedString()
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonBody: [String: Any] = ["image": base64String]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonBody)
            request.httpBody = jsonData
            
            print("正在发送 JSON 请求...")
            print("- URL：\(endpoint)")
            print("- Content-Type：application/json")
            print("- 请求体大小：\(jsonData.count) 字节")
            
            session.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("上传错误：\(error.localizedDescription)")
                    completion(.failure(APIError.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("错误：未收到 HTTP 响应")
                    completion(.failure(APIError.invalidResponse))
                    return
                }
                
                print("服务器响应状态码：\(httpResponse.statusCode)")
                
                guard let data = data else {
                    print("错误：未收到响应数据")
                    completion(.failure(APIError.invalidData))
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let result = json["result"] as? String {
                            print("识别结果：\(result)")
                            completion(.success(result))
                        } else if let error = json["error"] as? String {
                            print("服务器错误：\(error)")
                            completion(.failure(NSError(domain: "DoodleAPIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: error])))
                        } else {
                            print("错误：无效的响应格式")
                            completion(.failure(APIError.invalidData))
                        }
                    } else {
                        print("错误：无法解析 JSON 响应")
                        completion(.failure(APIError.invalidData))
                    }
                } catch {
                    print("JSON 解析错误：\(error.localizedDescription)")
                    completion(.failure(APIError.invalidData))
                }
            }.resume()
        } catch {
            print("JSON 编码错误：\(error.localizedDescription)")
            completion(.failure(APIError.invalidData))
        }
    }
    
    // 通过 WebSocket 发送图片进行识别
    func recognizeImageViaWebSocket(imageData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        guard let webSocketClient = webSocketClient else {
            completion(.failure(APIError.invalidData))
            return
        }
        
        // 处理图片数据
        guard let image = UIImage(data: imageData),
              let processedData = processImageForUpload(image) else {
            completion(.failure(APIError.invalidData))
            return
        }
        
        // 转换为 base64
        let base64String = processedData.base64EncodedString()
        
        // 设置 WebSocket 代理
        let delegate = ImageRecognitionDelegate(completion: completion)
        webSocketClient.delegate = delegate
        
        // 发送识别请求（只传递 base64String 和一个 error 回调，不要多余闭包）
        webSocketClient.sendImageForRecognition(base64String) { error in
            if let error = error {
                completion(.failure(APIError.webSocketError(error)))
            }
            // 如果 error == nil，说明消息已成功发送，等待 delegate 回调即可，这里无需再调用 completion
        }
    }
    
    // 检查任务状态
    func checkStatus(taskId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let endpoint = "\(baseURL)/api/status/\(taskId)"
        guard let url = URL(string: endpoint) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        print("正在检查任务状态：\(endpoint)")
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(APIError.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(APIError.invalidResponse))
                return
            }
            
            print("状态检查响应码：\(httpResponse.statusCode)")
            
            if httpResponse.statusCode >= 400 {
                completion(.failure(APIError.serverError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let status = json["status"] as? String else {
                completion(.failure(APIError.invalidData))
                return
            }
            
            completion(.success(status))
        }.resume()
    }
    
    // 获取生成结果
    func getResult(taskId: String, completion: @escaping (Result<Data, Error>) -> Void) {
        let endpoint = "\(baseURL)/api/result/\(taskId)"
        guard let url = URL(string: endpoint) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        print("正在获取结果：\(endpoint)")
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(APIError.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(APIError.invalidResponse))
                return
            }
            
            print("获取结果响应码：\(httpResponse.statusCode)")
            
            if httpResponse.statusCode >= 400 {
                completion(.failure(APIError.serverError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.invalidData))
                return
            }
            
            completion(.success(data))
        }.resume()
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

// WebSocket 代理实现
private class ImageRecognitionDelegate: WebSocketDelegate {
    private let completion: (Result<String, Error>) -> Void
    
    init(completion: @escaping (Result<String, Error>) -> Void) {
        self.completion = completion
    }
    
    func didReceive(message: String) {
        do {
            if let data = message.data(using: .utf8),
               let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let action = json["action"] as? String {
                    switch action {
                    case "qwenvl_image_recognition":
                        if let result = json["result"] as? String {
                            completion(.success(result))
                        } else {
                            completion(.failure(APIError.invalidData))
                        }
                    case "error":
                        if let errorMessage = json["message"] as? String {
                            completion(.failure(NSError(domain: "WebSocket", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                        } else {
                            completion(.failure(APIError.invalidData))
                        }
                    default:
                        completion(.failure(APIError.invalidData))
                    }
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func didConnect() {
        print("WebSocket 已连接")
    }
    
    func didDisconnect(error: Error?) {
        if let error = error {
            completion(.failure(APIError.webSocketError(error)))
        }
    }
    
    func didReconnect() {
        print("WebSocket 已重新连接")
    }
} 