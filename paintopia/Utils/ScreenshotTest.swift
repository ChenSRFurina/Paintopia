import SwiftUI

@MainActor
struct ScreenshotTest {
    
    /// 测试截图功能
    static func testScreenshot(paths: [PathSegment], currentPath: PathSegment?) -> UIImage? {
        let canvasContent = 
            ZStack {
                // 画布底部白纸
                Rectangle()
                    .fill(Color.white)
                    .cornerRadius(12)
                
                // 已完成的路径
                ForEach(paths) { segment in
                    Path { p in
                        if let first = segment.points.first {
                            p.move(to: first)
                            for point in segment.points.dropFirst() {
                                p.addLine(to: point)
                            }
                        }
                    }
                    .stroke(segment.color, lineWidth: segment.lineWidth)
                }
                
                // 当前正在绘制的路径
                if let segment = currentPath {
                    Path { p in
                        if let first = segment.points.first {
                            p.move(to: first)
                            for point in segment.points.dropFirst() {
                                p.addLine(to: point)
                            }
                        }
                    }
                    .stroke(segment.color, lineWidth: segment.lineWidth)
                }
            }
            .frame(width: 800, height: 600)
            .background(Color.white)
        
        let renderer = ImageRenderer(content: canvasContent)
        return renderer.uiImage
    }
    
    /// 保存截图到相册（需要权限）
    static func saveToPhotos(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
} 