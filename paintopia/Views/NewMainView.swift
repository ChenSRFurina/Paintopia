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
    @State private var showGenerationView = false
    @State private var generationImage: UIImage? = nil
    @State private var isObservingCanvas = false
    
    // 绘本生成相关状态
    @State private var isGeneratingStorybook = false
    @State private var storybookStory = ""
    @State private var storybookErrorMessage = ""
    @State private var showStorybookView = false
    @State private var storybookData: StorybookData?
    
    // 网络诊断相关状态
    @State private var showNetworkDiagnostic = false
    
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
                HStack {
                    TopToolbarView(
                        canGenerate: true,
                        onGenerate: handleGenerate,
                        onUndo: handleUndo,
                        onRedo: handleRedo,
                        onHome: handleHome
                    )
                    
                    Spacer()
                    
                    // TTS控制按钮
                    Button(action: {
                        navigationManager.toggleTTS()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: navigationManager.isTTSEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .font(.system(size: 14))
                            Text(navigationManager.isTTSEnabled ? "TTS开" : "TTS关")
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(navigationManager.isTTSEnabled ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                        .foregroundColor(navigationManager.isTTSEnabled ? .green : .red)
                        .cornerRadius(6)
                    }
                    .padding(.trailing, 8)
                    
                    // 网络诊断按钮
                    Button(action: {
                        showNetworkDiagnostic = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "network")
                                .font(.system(size: 14))
                            Text("网络诊断")
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                    }
                    .padding(.trailing, 16)
                }
                
                // 主要区域
                HStack(spacing: 0) {
                    // 左侧聊天助手（始终显示）
                    ChatbotView(canvasImage: .constant(nil), paths: $paths, isObservingCanvas: $isObservingCanvas)
                        .environmentObject(navigationManager)
                        .onChange(of: isGeneratingStorybook) { newValue in
                            // 当绘本生成状态改变时，控制TTS
                            print("📚 绘本生成状态改变: \(newValue ? "开始生成" : "生成完成")")
                            if newValue {
                                print("🔇 绘本生成期间，禁用TTS以避免干扰")
                                navigationManager.disableTTS()
                            } else {
                                print("🔊 绘本生成完成，TTS功能恢复正常")
                                navigationManager.enableTTS()
                            }
                        }
                    
                    // 中间画布区域
                    VStack {
                        Spacer()
                        if isObservingCanvas {
                            Text("正在观察画布，请稍等...")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.bottom, 4)
                        }
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
                        .padding(.leading, 0)
                        
                        // 绘本生成按钮区域
                        VStack(spacing: 12) {
                            if isGeneratingStorybook {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("正在生成绘本...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(8)
                            }
                            
                            if !storybookErrorMessage.isEmpty {
                                Text(storybookErrorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            
                            // 生成绘本按钮
                            if let canvasImage = takeCanvasScreenshot() {
                                GenerateButton(
                                    image: canvasImage,
                                    isLoading: $isGeneratingStorybook,
                                    story: $storybookStory,
                                    errorMessage: $storybookErrorMessage,
                                    showStorybookView: $showStorybookView,
                                    storybookData: $storybookData
                                )
                                .environmentObject(navigationManager)
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 20)
                        
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
        .fullScreenCover(isPresented: $showStorybookView) {
            if let storybook = storybookData {
                StorybookView(storybookData: storybook)
            }
        }
        .sheet(isPresented: $showNetworkDiagnostic) {
            NetworkDiagnosticView()
        }
    }
    
    // MARK: - 按钮处理函数
    
    private func handleGenerate() {
        // 检查是否有绘画内容
        if paths.isEmpty {
            print("⚠️ 画布为空，但仍然允许尝试生成绘本")
            // 注释掉return，允许用户尝试生成
            // return
        }
        
        print("🎨 开始截取画布内容，当前路径数: \(paths.count)")
        let img = takeCanvasScreenshot()
        if let img = img {
            print("✅ 画布截图成功，图片大小: \(img.size)")
            self.generationImage = img
            self.showGenerationView = true
        } else {
            print("❌ 画布截图失败")
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
        
        let renderer = ImageRenderer(content: canvasContent)
        renderer.scale = 1.0
        
        if let image = renderer.uiImage {
            return image
        }
        
        return nil
    }
}

#Preview {
    NewMainView()
        .environmentObject(NavigationManager())
} 