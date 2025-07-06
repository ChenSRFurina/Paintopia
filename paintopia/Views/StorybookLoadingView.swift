import SwiftUI

struct StorybookLoadingView: View {
    let onCancel: () -> Void
    let onSuccess: (StorybookData) -> Void
    
    @State private var progress = 0.0
    @State private var currentStep = 0
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    
    private let steps = [
        "正在分析你的画作...",
        "生成故事大纲...",
        "创作故事内容...",
        "生成绘本插图...",
        "优化页面布局...",
        "完成绘本制作..."
    ]
    
    var body: some View {
        ZStack {
            // 背景
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Logo和标题
                VStack(spacing: 20) {
                    Image("logo_name")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200)
                    
                    Text("正在生成你的专属绘本")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                // 进度指示器
                VStack(spacing: 20) {
                    // 圆形进度条
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.5), value: progress)
                        
                        VStack {
                            Text("\(Int(progress * 100))%")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("\(Int(elapsedTime))秒")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // 当前步骤
                    Text(steps[currentStep])
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut(duration: 0.5), value: currentStep)
                }
                
                // 提示信息
                VStack(spacing: 10) {
                    Text("绘本生成需要较长时间，请耐心等待")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    Text("预计需要 15-30 分钟")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // 取消按钮
                Button(action: onCancel) {
                    Text("取消生成")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(25)
                }
                .padding(.top, 20)
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            startProgress()
        }
        .onDisappear {
            stopProgress()
        }
    }
    
    private func startProgress() {
        // 启动计时器
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime += 1
        }
        
        // 模拟进度更新
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
            withAnimation {
                if progress < 0.95 {
                    progress += 0.05
                }
                
                if currentStep < steps.count - 1 {
                    currentStep += 1
                }
            }
            
            // 如果进度接近完成，停止定时器
            if progress >= 0.95 {
                timer.invalidate()
            }
        }
    }
    
    private func stopProgress() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    StorybookLoadingView(
        onCancel: {},
        onSuccess: { _ in }
    )
} 