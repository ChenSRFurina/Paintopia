import Foundation
import UIKit

class AIGCService: ObservableObject {
    private let apiKey: String = APIConfig.getAIGCApiKey()
    private let urlString = "https://aigc-api.hkust-gz.edu.cn/v1/chat/completions"
    
    func analyzeImageWithGPT4(image: UIImage, prompt: String = "请描述这张图片：", completion: @escaping (Result<String, Error>) -> Void) {
        guard !apiKey.isEmpty else {
            completion(.failure(NSError(domain: "AIGC", code: -1, userInfo: [NSLocalizedDescriptionKey: "缺少 AIGC API Key"])))
            return
        }
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "AIGC", code: -2, userInfo: [NSLocalizedDescriptionKey: "图片转换失败"])))
            return
        }
        let base64String = imageData.base64EncodedString()
        
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                [
                    "role": "system",
                    "content": "You are a helpful assistant."
                ],
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
            "temperature": 0.8,
            "max_tokens": 2048
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
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
                    completion(.failure(NSError(domain: "AIGC", code: -3, userInfo: [NSLocalizedDescriptionKey: "无数据返回"])))
                    return
                }
                print("[DEBUG] AIGC 原始返回：", String(data: data, encoding: .utf8) ?? "nil")
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let message = choices.first?["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        completion(.success(content))
                    } else if let errorMsg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String {
                        completion(.failure(NSError(domain: "AIGC", code: -4, userInfo: [NSLocalizedDescriptionKey: errorMsg])))
                    } else {
                        completion(.failure(NSError(domain: "AIGC", code: -5, userInfo: [NSLocalizedDescriptionKey: "解析失败"])))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
} 