import Foundation
import UIKit

// MARK: - 绘本数据模型

/// 绘本数据模型 - 用于存储完整的绘本信息
/// 包含标题、作者、创建时间、页面列表和角色图片
struct StorybookData {
    /// 唯一标识符
    let id = UUID()
    /// 绘本标题
    let title: String
    /// 作者名称
    let author: String
    /// 创建时间
    let createdAt: Date
    /// 绘本页面列表
    let pages: [StorybookPage]
    /// 角色图片（可选）
    let characterImage: UIImage?
}

/// 绘本页面模型 - 用于存储单个页面的信息
/// 包含文本内容、标题、图片和页码
struct StorybookPage {
    /// 唯一标识符
    let id = UUID()
    /// 页面文本内容
    let text: String
    /// 页面标题
    let title: String
    /// 页面图片（可选）
    let imageData: UIImage?
    /// 页码
    let pageNumber: Int
}

// MARK: - 扩展方法

extension StorybookData {
    /// 获取总页数
    var totalPages: Int {
        return pages.count
    }
    
    /// 检查是否有内容
    var hasContent: Bool {
        return !pages.isEmpty
    }
}

extension StorybookPage {
    /// 检查页面是否有图片
    var hasImage: Bool {
        return imageData != nil
    }
    
    /// 获取页面描述
    var description: String {
        return "第\(pageNumber)页: \(title)"
    }
} 