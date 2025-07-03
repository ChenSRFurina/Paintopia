// 新的主界面视图
// 实现HTML设计的布局：顶部工具栏 + 主区域（聊天助手 + 画布 + 绘画工具）

import SwiftUI

struct NewMainView: View {
    @StateObject private var navigationManager = NavigationManager()
    @State private var currentColor: Color = .black
    @State private var brushSize: CGFloat = 4
    @State private var isErasing = false
    @State private var paths: [PathSegment] = []
    @State private var currentPath: PathSegment?
    @State private var showChatbot = false
    @State private var showGenerationView = false
    @State private var generationImage: UIImage? = nil
    
    // 画布引用，用于撤销/重做
    @State private var canvasRef: EnhancedCanvasView?
    
    var body: some View {
        ZStack {
            // 背景图片
            Image("background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .overlay(
                    // 半透明渐变覆盖层，保持原有的渐变效果
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.97, green: 0.97, blue: 1.0).opacity(0.8),
                            Color(red: 0.9, green: 0.92, blue: 1.0).opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                )
            
            VStack(spacing: 0) {
                // 顶部工具栏
                TopToolbarView(
                    showChatbot: $showChatbot,
                    onGenerate: handleGenerate,
                    onUndo: handleUndo,
                    onRedo: handleRedo,
                    onHome: handleHome
                )
                
                // 主要区域
                HStack(spacing: 0) {
                    // 左侧聊天助手（可隐藏）
                    if showChatbot {
                        ChatbotView()
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                    
                    // 中间画布区域
                    VStack {
                        Spacer()
                        
                        EnhancedCanvasView(
                            selectedColor: $currentColor,
                            selectedLineWidth: $brushSize,
                            isEraser: $isErasing,
                            paths: $paths,
                            currentPath: $currentPath,
                            onUndo: {},
                            onRedo: {}
                        )
                        .frame(width: 800, height: 600)
                        .background(Color.clear)
                        .padding(.leading, showChatbot ? 0 : 80) // 当没有聊天框时左边距
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    
                    // 右侧绘画工具栏
                    RightToolsView(
                        selectedColor: $currentColor,
                        selectedLineWidth: $brushSize,
                        isEraser: $isErasing
                    )
                }
                .frame(maxHeight: .infinity)
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showGenerationView) {
            GenerationView(image: generationImage ?? UIImage(systemName: "photo") ?? UIImage())
        }
        .animation(.easeInOut(duration: 0.3), value: showChatbot)
    }
    
    // MARK: - 按钮处理函数
    
    private func handleGenerate() {
        let img = takeCanvasScreenshot()
        if let img = img {
            self.generationImage = img
            self.showGenerationView = true
        }
    }
    
    private func handleUndo() {
        // 通过画布引用执行撤销
        // 这里需要实现画布撤销逻辑
        if !paths.isEmpty {
            paths.removeLast()
        }
    }
    
    private func handleRedo() {
        // 通过画布引用执行重做
        // 这里需要实现画布重做逻辑
        print("重做操作")
    }
    
    private func handleHome() {
        // 处理首页导航
        navigationManager.currentPage = .drawing
    }
    
    // 截取画布内容
    private func takeCanvasScreenshot() -> UIImage? {
        let canvasContent = ZStack {
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
        }
        .frame(width: 800, height: 600)
        .background(Color.white)
        
        let renderer = ImageRenderer(content: canvasContent)
        return renderer.uiImage
    }
}

#Preview {
    NewMainView()
        .environmentObject(NavigationManager())
} 