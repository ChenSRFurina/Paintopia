import SwiftUI

enum AISuggestionStatus {
    case idle
    case loading
    case success(String) // AI 建议
    case failure(String) // 错误信息
}

struct MainView: View {
    @StateObject private var navigationManager = NavigationManager()
    @State private var currentColor: Color = .black
    @State private var brushSize: CGFloat = 5
    @State private var isErasing = false
    @State private var paths: [PathSegment] = []
    @State private var currentPath: PathSegment?
    @State private var screenshot: UIImage?
    @State private var showScreenshot = false
    @State private var aiStatus: AISuggestionStatus = .idle
    @State private var showGenerationView = false
    @State private var generationImage: UIImage? = nil
    
    var body: some View {
        NavigationView {
            HStack(spacing: 0) {
                // 左侧工具栏
                ToolbarView(
                    selectedColor: $currentColor,
                    selectedLineWidth: $brushSize,
                    isEraser: $isErasing,
                    undoAction: {
                        if !paths.isEmpty {
                            paths.removeLast()
                        }
                    }
                )
                .frame(width: 80)
                .background(Color(.systemGray6))
                
                // 中间画布区域
                ZStack(alignment: .top) {
                    ZStack {
                        CanvasView(
                            selectedColor: $currentColor,
                            selectedLineWidth: $brushSize,
                            isEraser: $isErasing,
                            paths: $paths,
                            currentPath: $currentPath
                        )
                        .background(Color.white)
                        .id("canvasView")
                        
                        // 右下角生成绘本按钮
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button(action: {
                                    let img = takeCanvasScreenshotForGeneration()
                                    if let img = img {
                                        self.generationImage = img
                                        self.showGenerationView = true
                                    }
                                }) {
                                    Text("生成绘本")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(Color.purple)
                                        .cornerRadius(24)
                                        .shadow(radius: 4)
                                }
                                .padding(.trailing, 32)
                                .padding(.bottom, 32)
                            }
                        }
                    }
                    
                    // 顶部提示区
                    VStack(spacing: 8) {
                        if let screenshot = screenshot, showScreenshot {
                            Image(uiImage: screenshot)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 120, height: 80)
                                .cornerRadius(8)
                                .shadow(radius: 4)
                                .onTapGesture {
                                    showScreenshot = false
                                }
                                .padding(.top, 8)
                        }
                        switch aiStatus {
                        case .loading:
                            Text("AI 正在分析中...")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.top, 2)
                        case .success:
                            Text("AI 分析成功！")
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding(.top, 2)
                        case .failure(let msg):
                            Text("AI 分析失败：\(msg)")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 2)
                        default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .zIndex(10)
                    .padding(.top, 8)
                }
                
                // 右侧建议区域
                SuggestionView(
                    onScreenshot: handleScreenshot,
                    onAIStatusChange: { status in
                        aiStatus = status
                    }
                )
                .frame(width: UIScreen.main.bounds.width * 0.25)
                .background(Color(.systemBackground))
            }
            .navigationTitle("Paintopia")
            .navigationBarTitleDisplayMode(.inline)
            // 跳转到绘本生成页面
            .fullScreenCover(isPresented: $showGenerationView) {
                GenerationView(image: generationImage ?? UIImage(systemName: "photo") ?? UIImage())
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .environmentObject(navigationManager)
    }
    
    // 生成画布截图并显示在顶部
    private func handleScreenshot() -> UIImage? {
        let canvasContent =
            ZStack {
                Rectangle()
                    .fill(Color.white)
                    .cornerRadius(12)
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
                if let segment = currentPath, !isErasing {
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
        guard let img = renderer.uiImage else { return nil }
        self.screenshot = img
        self.showScreenshot = true
        // 3秒后自动隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showScreenshot = false
        }
        return img
    }
    
    // 生成绘本专用截图
    private func takeCanvasScreenshotForGeneration() -> UIImage? {
        let canvasContent =
            ZStack {
                Rectangle()
                    .fill(Color.white)
                    .cornerRadius(12)
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
                if let segment = currentPath, !isErasing {
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
}

#Preview {
    MainView()
        .environmentObject(NavigationManager())
} 
