import Foundation
import UIKit

// MARK: - 标准化故事格式响应模型

struct StandardizedStorybookResponse: Codable {
    let success: Bool
    let stories: [String: StoryPage]
    let images: StoryImages
    let message: String?
}

struct StoryPage: Codable {
    let page_number: Int
    let title: String
    let content: String
}

struct StoryImages: Codable {
    let character_image: String? // base64编码的图片数据
    let story_pages_images: [String] // 每页对应的base64编码图片数组
}

// MARK: - API客户端

class StorybookAPIClient: ObservableObject {
    static let shared = StorybookAPIClient()
    
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
    
    @Published var isConnected = false
    
    private init() {}
    
    // MARK: - 网络连接测试
    
    /// 测试网络连接
    func testConnection(completion: @escaping (Bool, String?) -> Void) {
        // 使用绘本生成端点来测试连接，因为这个端点一定存在
        let url = URL(string: "\(baseURL)/api/generate-storybook")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0
        
        print("🔍 测试绘本API连接: \(baseURL)")
        
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 绘本API连接测试失败: \(error.localizedDescription)")
                    completion(false, "连接失败: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 绘本API HTTP状态码: \(httpResponse.statusCode)")
                    // 只要不是404就认为连接成功（可能是400等，但至少服务在运行）
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
    
    // MARK: - 绘本生成
    
    /// 生成绘本
    func generateStorybook(image: UIImage, completion: @escaping (Result<StorybookData, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/api/generate-storybook")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 1800.0 // 30分钟超时，绘本生成需要很长时间
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "图片转换失败"])))
            return
        }
        
        let base64Image = imageData.base64EncodedString()
        
        let requestBody: [String: Any] = [
            "image_data": base64Image
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        let requestId = UUID().uuidString.prefix(8)
        print("🚀 [请求\(requestId)] 生成绘本，图片大小: \(imageData.count) bytes")
        print("🚀 [请求\(requestId)] 绘本生成超时设置: \(request.timeoutInterval)秒 (30分钟)")
        
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
                    
                    // 检查是否有错误
                    if let error = json["error"] as? String, !error.isEmpty {
                        print("❌ [请求\(requestId)] 绘本生成错误: \(error)")
                        completion(.failure(NSError(domain: "StorybookError", code: 0, userInfo: [NSLocalizedDescriptionKey: error])))
                        return
                    }
                    
                    // 详细分析响应结构
                    print("🔍 [请求\(requestId)] 响应结构分析:")
                    print("  - success: \(json["success"] ?? "nil")")
                    print("  - full_story: \(json["full_story"] != nil ? "存在" : "不存在")")
                    print("  - pages: \(json["pages"] != nil ? "存在" : "不存在")")
                    print("  - images: \(json["images"] != nil ? "存在" : "不存在")")
                    print("  - generation_stats: \(json["generation_stats"] != nil ? "存在" : "不存在")")
                    
                    if let fullStory = json["full_story"] as? String {
                        print("  - full_story长度: \(fullStory.count)")
                        print("  - full_story预览: \(String(fullStory.prefix(100)))...")
                    }
                    
                    if let pages = json["pages"] as? [[String: Any]] {
                        print("  - pages数量: \(pages.count)")
                        for (index, page) in pages.enumerated() {
                            print("    - \(index): \(page)")
                        }
                    }
                    
                    if let images = json["images"] as? [String: Any] {
                        print("  - images键: \(Array(images.keys))")
                    }
                    
                    if let stats = json["generation_stats"] as? [String: Any] {
                        print("  - generation_stats: \(stats)")
                    }
                    
                    // 解析绘本数据 - 适配新的pages数组格式
                    if let success = json["success"] as? Bool, success {
                        
                        // 检查是否有pages字段
                        let pages = json["pages"] as? [[String: Any]] ?? []
                        
                        print("🔍 找到success: \(success)")
                        print("🔍 找到pages数组: \(pages)")
                        
                        // 检查生成统计信息
                        let totalPages = json["total_pages"] as? Int ?? 0
                        let projectId = json["project_id"] as? String ?? ""
                        
                        print("🔍 生成统计: 总页数=\(totalPages), 项目ID=\(projectId)")
                        
                        // 检查是否生成了有效内容
                        if pages.isEmpty {
                            print("⚠️ 后端生成失败: pages数组为空")
                            completion(.failure(NSError(domain: "GenerationError", code: 0, userInfo: [NSLocalizedDescriptionKey: "绘本生成失败，请稍后重试"])))
                            return
                        }
                        
                        // 从full_story中提取标题
                        let fullStory = json["full_story"] as? String ?? ""
                        let title = self.extractTitle(from: fullStory)
                        print("🔍 提取的标题: \(title)")
                        
                        // 解析页面数据
                        let storybookPages = self.parsePagesArray(from: pages)
                        
                        // 检查解析结果
                        if storybookPages.isEmpty {
                            print("⚠️ 页面数据解析失败")
                            completion(.failure(NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "故事内容解析失败"])))
                            return
                        }
                        
                        // 解析角色图片（如果有的话）
                        let characterImage = self.parseCharacterImageFromPages(pages: pages)
                        
                        let storybook = StorybookData(
                            title: title,
                            author: "AI创作",
                            createdAt: Date(),
                            pages: storybookPages,
                            characterImage: characterImage
                        )
                        
                        print("✅ [请求\(requestId)] 绘本生成成功，共 \(storybook.pages.count) 页")
                        completion(.success(storybook))
                    } else {
                        print("❌ [请求\(requestId)] 绘本数据解析失败")
                        print("❌ success存在: \(json["success"] != nil)")
                        print("❌ success值: \(json["success"] ?? "nil")")
                        print("❌ pages存在: \(json["pages"] != nil)")
                        print("❌ pages类型: \(type(of: json["pages"]))")
                        
                        // 提供更具体的错误信息
                        let errorMessage = json["error"] as? String ?? "绘本生成失败，请稍后重试"
                        completion(.failure(NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                    }
                } else {
                    print("❌ [请求\(requestId)] JSON解析失败")
                    completion(.failure(NSError(domain: "JSONError", code: 0, userInfo: [NSLocalizedDescriptionKey: "JSON解析失败"])))
                }
            } catch {
                print("❌ [请求\(requestId)] JSON解析错误: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - 私有方法
    
    /// 从完整故事中提取标题
    private func extractTitle(from fullStory: String) -> String {
        // 尝试从《》中提取标题
        if let range = fullStory.range(of: "《.*?》", options: .regularExpression) {
            let title = String(fullStory[range])
            return title.replacingOccurrences(of: "《", with: "").replacingOccurrences(of: "》", with: "")
        }
        return "我的绘本"
    }
    
    /// 解析故事页面数据
    private func parseStories(from stories: [String: [String: Any]], images: [String: Any]? = nil) -> [StorybookPage] {
        var pages: [StorybookPage] = []
        
        print("🔍 开始解析故事数据，原始数据: \(stories)")
        print("🔍 图片数据: \(images ?? [:])")
        
        // 按page_number排序
        let sortedStories = stories.sorted { first, second in
            let firstNumber = self.extractPageNumber(from: first.value["page_number"]) ?? 0
            let secondNumber = self.extractPageNumber(from: second.value["page_number"]) ?? 0
            return firstNumber < secondNumber
        }
        
        print("🔍 排序后的故事数据: \(sortedStories)")
        
        for (key, storyData) in sortedStories {
            print("🔍 解析故事页面 \(key): \(storyData)")
            
            // 详细检查每个字段
            let pageNumber = self.extractPageNumber(from: storyData["page_number"])
            let content = storyData["content"] as? String
            let title = storyData["title"] as? String
            
            print("🔍 页面 \(key) 字段检查:")
            print("  - page_number: \(pageNumber ?? -1) (类型: \(type(of: storyData["page_number"])))")
            print("  - content: \(content?.prefix(20) ?? "nil") (类型: \(type(of: storyData["content"])))")
            print("  - title: \(title ?? "nil") (类型: \(type(of: storyData["title"])))")
            
            // 宽松的字段检查：只要page_number和content存在就生成页面
            guard let pageNumber = pageNumber,
                  let content = content, !content.isEmpty else {
                print("❌ 故事页面 \(key) 缺少必要字段，跳过")
                print("❌ 缺少字段: page_number=\(pageNumber != nil), content=\(content?.isEmpty == false)")
                continue
            }
            
            // 使用默认标题如果title不存在
            let pageTitle = title ?? "第\(pageNumber)页"
            
            // 解析页面图片
            let pageImage = self.parsePageImage(pageNumber: pageNumber, images: images)
            
            print("✅ 成功解析页面 \(pageNumber): \(pageTitle)")
            
            let page = StorybookPage(
                text: content,
                title: pageTitle,
                imageData: pageImage,
                pageNumber: pageNumber
            )
            pages.append(page)
        }
        
        print("📚 最终解析结果: 共 \(pages.count) 页")
        return pages
    }
    
    /// 解析页面图片
    private func parsePageImage(pageNumber: Int, images: [String: Any]?) -> UIImage? {
        guard let images = images else { return nil }
        
        print("🔍 解析页面 \(pageNumber) 的图片，图片数据: \(images)")
        
        // 查找对应页面的图片
        if let storyPagesImages = images["story_pages_images"] as? [[String: Any]] {
            print("🔍 找到story_pages_images数组，共 \(storyPagesImages.count) 张图片")
            
            for (index, imageData) in storyPagesImages.enumerated() {
                print("🔍 检查图片 \(index): \(imageData)")
                
                if let name = imageData["name"] as? String,
                   let type = imageData["type"] as? String,
                   type == "story_page" {
                    
                    print("🔍 图片名称: \(name), 类型: \(type)")
                    
                    // 检查是否是对应的页面
                    let isTargetPage = name.contains("第\(pageNumber)页") || 
                                     name.contains("page_\(String(format: "%03d", pageNumber))") ||
                                     name.contains("page_\(pageNumber)") ||
                                     name == "第\(pageNumber)页" ||
                                     name.contains("\(pageNumber)") ||
                                     name.contains("page") ||
                                     name.contains("story")
                    
                    if isTargetPage {
                        print("✅ 找到页面 \(pageNumber) 对应的图片: \(name)")
                        
                        if let base64Data = imageData["data"] as? String {
                            print("🔍 找到base64数据，长度: \(base64Data.count)")
                            
                            if let imageData = Data(base64Encoded: base64Data) {
                                let image = UIImage(data: imageData)
                                print("✅ 成功创建图片: \(image != nil)")
                                return image
                            } else {
                                print("❌ base64数据转换失败")
                            }
                        } else {
                            print("❌ 未找到data字段")
                        }
                    }
                }
            }
        } else {
            print("❌ 未找到story_pages_images数组")
        }
        
        return nil
    }
    
    /// 提取页面编号，支持多种数字类型
    private func extractPageNumber(from value: Any?) -> Int? {
        if let intValue = value as? Int {
            return intValue
        }
        if let nsNumber = value as? NSNumber {
            return nsNumber.intValue
        }
        if let stringValue = value as? String, let intValue = Int(stringValue) {
            return intValue
        }
        return nil
    }
    
    /// 解析页面数据（保留原有方法以兼容）
    private func parsePages(from pagesData: [[String: Any]]) -> [StorybookPage] {
        return pagesData.compactMap { pageData in
            guard let pageNumber = pageData["page_number"] as? Int,
                  let text = pageData["text"] as? String,
                  let imageBase64 = pageData["image"] as? String else {
                return nil
            }
            
            // 将base64字符串转换为UIImage
            var imageData: UIImage? = nil
            if let imageDataFromBase64 = Data(base64Encoded: imageBase64) {
                imageData = UIImage(data: imageDataFromBase64)
            }
            
            return StorybookPage(
                text: text,
                title: pageData["title"] as? String ?? "第\(pageNumber)页",
                imageData: imageData,
                pageNumber: pageNumber
            )
        }
    }
    
    /// 解析角色图片 - 新格式可能不包含角色图片
    private func parseCharacterImageFromPages(pages: [[String: Any]]) -> UIImage? {
        print("🔍 新格式可能不包含角色图片，返回nil")
        // 新格式主要关注故事页面，角色图片不是必需的
        // 如果需要角色图片，可以在第一页的图片中使用
        return nil
    }
    
    /// 解析页面数据 - 适配新的pages数组格式
    private func parsePagesArray(from pages: [[String: Any]]) -> [StorybookPage] {
        var storybookPages: [StorybookPage] = []
        
        print("🔍 开始解析pages数组，共 \(pages.count) 页")
        
        for (index, pageData) in pages.enumerated() {
            print("🔍 解析页面 \(index): \(pageData)")
            
            // 解析页面基本信息
            let pageNumber = self.extractPageNumber(from: pageData["page_number"])
            let title = pageData["title"] as? String
            let content = pageData["content"] as? String
            
            print("🔍 页面 \(index) 基本信息:")
            print("  - page_number: \(pageNumber ?? -1)")
            print("  - title: \(title ?? "nil")")
            print("  - content: \(content?.prefix(50) ?? "nil")")
            
            // 检查必要字段
            guard let pageNumber = pageNumber,
                  let content = content, !content.isEmpty else {
                print("❌ 页面 \(index) 缺少必要字段，跳过")
                continue
            }
            
            // 解析图片数据
            let pageImage = self.parsePageImageFromObject(pageData["image"])
            
            let pageTitle = title ?? "第\(pageNumber)页"
            
            print("✅ 成功解析页面 \(pageNumber): \(pageTitle)")
            
            let page = StorybookPage(
                text: content,
                title: pageTitle,
                imageData: pageImage,
                pageNumber: pageNumber
            )
            storybookPages.append(page)
        }
        
        print("📚 最终解析结果: 共 \(storybookPages.count) 页")
        return storybookPages
    }
    
    /// 从图片对象中解析图片数据
    private func parsePageImageFromObject(_ imageObject: Any?) -> UIImage? {
        guard let imageData = imageObject as? [String: Any] else {
            print("❌ 图片对象格式错误")
            return nil
        }
        
        print("🔍 解析图片对象: \(imageData)")
        
        if let type = imageData["type"] as? String,
           let name = imageData["name"] as? String,
           let base64Data = imageData["data"] as? String {
            
            print("🔍 图片信息: type=\(type), name=\(name), data长度=\(base64Data.count)")
            
            if let imageData = Data(base64Encoded: base64Data) {
                let image = UIImage(data: imageData)
                print("✅ 成功创建图片: \(image != nil)")
                return image
            } else {
                print("❌ base64数据转换失败")
            }
        } else {
            print("❌ 图片对象缺少必要字段")
        }
        
        return nil
    }
}

// MARK: - 错误类型

enum StorybookError: Error, LocalizedError {
    case invalidURL
    case imageConversionFailed
    case noData
    case generationFailed(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .imageConversionFailed:
            return "图片转换失败"
        case .noData:
            return "没有接收到数据"
        case .generationFailed(let message):
            return "绘本生成失败: \(message)"
        case .networkError(let message):
            return "网络错误: \(message)"
        }
    }
} 