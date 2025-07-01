import Foundation
import UIKit

class ReplicateService {
    // 你的 Replicate API Token（已在 APIConfig.swift 硬编码）
    private let replicateToken: String = APIConfig.getReplicateAPIToken()
    
    // 上传图片到 sm.ms，返回图片公网URL
    func uploadImageToSMMS(image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "https://sm.ms/api/v2/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            completion(.failure(ReplicateError.imageConversionFailed))
            return
        }
        
        var body = Data()
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"smfile\"; filename=\"image.jpg\"\r\n")
        body.append("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n")
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let data = data else {
                    completion(.failure(ReplicateError.noData))
                    return
                }
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    if let dataDict = json?["data"] as? [String: Any], let url = dataDict["url"] as? String {
                        completion(.success(url))
                    } else if let message = json?["message"] as? String {
                        completion(.failure(ReplicateError.custom(message)))
                    } else {
                        completion(.failure(ReplicateError.invalidResponse))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // 调用 Replicate API
    func callReplicateAPI(imageURL: String, prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "https://api.replicate.com/v1/models/black-forest-labs/flux-kontext-pro/predictions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(replicateToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("wait", forHTTPHeaderField: "Prefer")
        
        let body: [String: Any] = [
            "input": [
                "prompt": prompt,
                "input_image": imageURL,
                "output_format": "jpg"
            ]
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
                    completion(.failure(ReplicateError.noData))
                    return
                }
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    if let outputArr = json?["output"] as? [String], let outputURL = outputArr.first {
                        completion(.success(outputURL))
                    } else if let errorDict = json?["error"] as? [String: Any], let message = errorDict["message"] as? String {
                        completion(.failure(ReplicateError.custom(message)))
                    } else if let message = json?["message"] as? String {
                        completion(.failure(ReplicateError.custom(message)))
                    } else {
                        completion(.failure(ReplicateError.invalidResponse))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}

enum ReplicateError: Error, LocalizedError {
    case imageConversionFailed
    case noData
    case invalidResponse
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed: return "图片转换失败"
        case .noData: return "无数据返回"
        case .invalidResponse: return "服务器响应格式错误"
        case .custom(let msg): return msg
        }
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
} 