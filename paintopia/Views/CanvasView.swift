// 画布视图，处理绘画交互
// 支持自由绘画、橡皮擦、路径管理

import SwiftUI

struct PathSegment: Identifiable, Hashable {
    let id = UUID()
    var points: [CGPoint]
    var color: Color
    var lineWidth: CGFloat
    var isEraser: Bool
}

struct CanvasView: View {
    @Binding var selectedColor: Color
    @Binding var selectedLineWidth: CGFloat
    @Binding var isEraser: Bool
    @Binding var paths: [PathSegment]
    @Binding var currentPath: PathSegment?
    
    // 用于记录橡皮擦轨迹
    @State private var eraserPath: [CGPoint] = []
    
    var body: some View {
        ZStack {
            // 画布底部白纸，不可被橡皮擦除
            Rectangle()
                .fill(Color.white)
                .cornerRadius(12)
                .shadow(radius: 2)
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
            if let segment = currentPath, !isEraser {
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
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if isEraser {
                        eraserPath.append(value.location)
                        // 实时擦除逻辑，橡皮判定半径与 selectedLineWidth 同步
                        let threshold: CGFloat = max(selectedLineWidth * 1.5, 10)
                        var newPaths: [PathSegment] = []
                        for segment in paths {
                            var currentSubPath: [CGPoint] = []
                            for pt in segment.points {
                                let erased = hypot(pt.x - value.location.x, pt.y - value.location.y) < threshold
                                if erased {
                                    if !currentSubPath.isEmpty {
                                        newPaths.append(PathSegment(points: currentSubPath, color: segment.color, lineWidth: segment.lineWidth, isEraser: false))
                                        currentSubPath = []
                                    }
                                } else {
                                    currentSubPath.append(pt)
                                }
                            }
                            if !currentSubPath.isEmpty {
                                newPaths.append(PathSegment(points: currentSubPath, color: segment.color, lineWidth: segment.lineWidth, isEraser: false))
                            }
                        }
                        // 只保留长度大于1的路径段
                        paths = newPaths.filter { $0.points.count > 1 }
                    } else {
                        if currentPath == nil {
                            currentPath = PathSegment(points: [value.location], color: selectedColor, lineWidth: selectedLineWidth, isEraser: false)
                        } else {
                            currentPath?.points.append(value.location)
                        }
                    }
                }
                .onEnded { _ in
                    if isEraser {
                        eraserPath = []
                    } else {
                        if let finished = currentPath {
                            paths.append(finished)
                            currentPath = nil
                        }
                    }
                }
        )
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
    }
    
    /// 截取画布内容
    func takeScreenshot() -> UIImage? {
        let renderer = ImageRenderer(content: 
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
            }
            .frame(width: 800, height: 600) // 固定尺寸用于截图
        )
        
        return renderer.uiImage
    }
}

#Preview {
    CanvasView(selectedColor: .constant(.black), selectedLineWidth: .constant(2), isEraser: .constant(false), paths: .constant([]), currentPath: .constant(nil))
} 