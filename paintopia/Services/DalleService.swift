// DALL·E 3图像生成服务
// 调用DALL·E 3 API生成卡通绘本风格图片

import Foundation

class DalleService {
    private let apiKey: String = APIConfig.getDalleAPIKey()
    private let urlString = "https://gpt-api.hkust-gz.edu.cn/v1/image/generations"
    
    struct DalleResponse: Decodable {
        struct DataItem: Decodable {
            let url: String
            let revised_prompt: String?
        }
        let data: [DataItem]
    }
    
    func generateImage(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard !apiKey.isEmpty else {
            completion(.failure(DalleError.missingAPIKey))
            return
        }
        guard let url = URL(string: urlString) else {
            completion(.failure(DalleError.invalidURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        let body: [String: Any] = [
            "model": "DALL-E 3",
            "prompt": prompt,
            "size": "1024x1024",
            "quality": "standard",
            "style": "vivid",
            "n": 1
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
                    completion(.failure(DalleError.noData))
                    return
                }
                print("[DEBUG] DALL·E 3 原始返回：", String(data: data, encoding: .utf8) ?? "nil")
                do {
                    let dalleResponse = try JSONDecoder().decode(DalleResponse.self, from: data)
                    if let url = dalleResponse.data.first?.url {
                        completion(.success(url))
                    } else {
                        completion(.failure(DalleError.noImageURL))
                    }
                } catch {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errorMsg = json["error"] as? String {
                        completion(.failure(NSError(domain: "DalleAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMsg])))
                    } else {
                        completion(.failure(error))
                    }
                }
            }
        }.resume()
    }
}

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