import Foundation
import UIKit

// MARK: - 模型测试

/// 用于测试StorybookModels的示例数据
struct StorybookModelsTest {
    
    /// 创建示例绘本数据
    static func createSampleStorybook() -> StorybookData {
        let pages = [
            StorybookPage(
                text: "这是一个示例故事页面，讲述了小兔子的冒险故事。小兔子在森林里遇到了很多有趣的朋友。",
                title: "小兔子的冒险",
                imageData: nil,
                pageNumber: 1
            ),
            StorybookPage(
                text: "小兔子和小松鼠一起寻找美味的坚果，他们度过了愉快的一天。",
                title: "寻找坚果",
                imageData: nil,
                pageNumber: 2
            )
        ]
        
        return StorybookData(
            title: "示例绘本",
            author: "AI创作",
            createdAt: Date(),
            pages: pages,
            characterImage: nil
        )
    }
    
    /// 测试模型功能
    static func testModels() {
        let storybook = createSampleStorybook()
        
        print("📚 绘本测试:")
        print("   - 标题: \(storybook.title)")
        print("   - 作者: \(storybook.author)")
        print("   - 总页数: \(storybook.totalPages)")
        print("   - 有内容: \(storybook.hasContent)")
        
        for page in storybook.pages {
            print("   - \(page.description)")
            print("     有图片: \(page.hasImage)")
        }
    }
} 