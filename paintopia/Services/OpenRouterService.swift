// OpenRouter多模态AI服务
// 使用Qwen2.5-VL模型进行图像分析

import Foundation
import UIKit

class OpenRouterService: ObservableObject {
    private let apiKey: String
    private let baseURL = "https://openrouter.ai/api/v1"
    
    init() {
        // 从配置文件获取 API key
        self.apiKey = APIConfig.getOpenRouterAPIKey()
        print("[DEBUG] OpenRouter API Key:", self.apiKey)
    }
    
    /// 用于建议区：分析画面并给出后续绘画建议
    func analyzeImageForSuggestion(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        let prompt = "请分析这个绘画画面，并提供约30字的后续绘画建议。建议应该具体、实用，帮助用户继续完善这幅画。"
        analyzeImage(image, prompt: prompt, completion: completion)
    }
    
    /// 用于生成页：根据画面生成一个小故事
    func analyzeImageForStory(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        let prompt = "请根据画面生成一个小故事。"
        analyzeImage(image, prompt: prompt, completion: completion)
    }
    
    /// 通用底层方法
    private func analyzeImage(_ image: UIImage, prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard !apiKey.isEmpty else {
            completion(.failure(OpenRouterError.missingAPIKey))
            return
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(OpenRouterError.imageConversionFailed))
            return
        }
        let base64String = imageData.base64EncodedString()
        
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("paintopia-app", forHTTPHeaderField: "HTTP-Referer")
        
        let requestBody: [String: Any] = [
            "model": "qwen/qwen2.5-vl-72b-instruct",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64String)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 200,
            "temperature": 0.7
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(OpenRouterError.noData))
                    return
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    // debug 打印
                    print("[DEBUG] OpenRouter 返回: \(json ?? [:])")
                    if let choices = json?["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        completion(.success(content))
                    } else if let errorMsg = json?["error"] as? String {
                        completion(.failure(OpenRouterError.invalidResponse))
                    } else {
                        completion(.failure(OpenRouterError.invalidResponse))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}

enum OpenRouterError: Error, LocalizedError {
    case missingAPIKey
    case imageConversionFailed
    case noData
    case invalidResponse
    
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
        }
    }
} 