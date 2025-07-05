// 右侧AI建议视图
// 提供截图分析和AI绘画建议功能

import SwiftUI
import UIKit

struct Suggestion: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct SuggestionView: View {
    @State private var aiSuggestion: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""

    
    let onScreenshot: () -> UIImage?
    let onAIStatusChange: (AISuggestionStatus) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // 顶部留白
            Spacer()
                .frame(height: 20)
            
            // 截图按钮
            Button(action: takeScreenshotAndAnalyze) {
                HStack {
                    Image(systemName: "camera")
                    Text("截图分析")
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue)
                .cornerRadius(8)
            }
            .disabled(isLoading)
            
            // 加载状态
            if isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("AI 正在分析中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            
            // 错误信息
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            }
            
            // AI 建议滚动区
            if !aiSuggestion.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI 绘画建议")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(aiSuggestion)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 220) // 限制最大高度，超出可滚动
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private func takeScreenshotAndAnalyze() {
        guard let screenshot = onScreenshot() else {
            errorMessage = "截图失败"
            onAIStatusChange(.failure("截图失败"))
            return
        }
        
        // 检查是否是系统占位图标
        if screenshot.isSymbolImage || isSystemPlaceholderImage(screenshot) {
            errorMessage = "请先在画布上绘制一些内容再进行分析"
            onAIStatusChange(.failure("请先绘制内容"))
            return
        }
        
        // 获取图片数据
        guard let imageData = screenshot.jpegData(compressionQuality: 0.8) else {
            errorMessage = "图片处理失败"
            onAIStatusChange(.failure("图片处理失败"))
            return
        }
        
        // 检查图片大小，如果太小可能是空图片
        if imageData.count < 500 {
            errorMessage = "图片内容过少，请绘制更多内容后再试"
            onAIStatusChange(.failure("图片内容不足"))
            return
        }
        
        print("✅ SuggestionView图片验证通过，大小: \(imageData.count) bytes")
        
        print("🎨 SuggestionView开始截图分析...")
        
        isLoading = true
        errorMessage = ""
        aiSuggestion = ""
        onAIStatusChange(.loading)
        
        print("📤 开始上传截图进行AI识别，图片大小: \(imageData.count) bytes")
        
        // 使用单例上传图片，后端处理所有AI逻辑
        DoodleAPIClient.shared.uploadDoodle(imageData: imageData) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let aiResult):
                    print("✅ AI处理成功")
                    print("   - 识别结果: \(aiResult.recognition)")
                    print("   - 建议: \(aiResult.suggestion)")
                    
                    if aiResult.success {
                        // 直接使用后端返回的建议
                        self.aiSuggestion = aiResult.suggestion
                        self.isLoading = false
                        self.onAIStatusChange(.success(aiResult.suggestion))
                        print("✅ SuggestionView分析完成")
                    } else {
                        // 处理失败情况
                        self.isLoading = false
                        self.errorMessage = aiResult.error ?? "AI处理失败"
                        self.onAIStatusChange(.failure(self.errorMessage))
                        print("❌ AI处理失败: \(self.errorMessage)")
                    }
                    
                case .failure(let error):
                    print("❌ 网络请求失败: \(error.localizedDescription)")
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.onAIStatusChange(.failure(error.localizedDescription))
                }
            }
        }
    }
    
    // 检查是否是系统占位图标
    private func isSystemPlaceholderImage(_ image: UIImage) -> Bool {
        let size = image.size
        
        // 检查是否是我们使用的特定系统图标尺寸 (通常很小且为正方形)
        if size.width == size.height && size.width < 100 {
            // 进一步检查是否是常见的系统图标尺寸
            let systemIconSizes: [CGFloat] = [20, 22, 24, 26, 28, 30, 32, 34, 36, 40, 48, 64]
            if systemIconSizes.contains(size.width) {
                print("⚠️ SuggestionView检测到可能的系统图标，尺寸: \(size.width)x\(size.height)")
                return true
            }
        }
        
        // 画布截图通常是较大的矩形 (800x600)，这样的大小不太可能是系统图标
        if size.width >= 400 && size.height >= 300 {
            print("✅ SuggestionView图片尺寸正常，应该是画布内容: \(size.width)x\(size.height)")
            return false
        }
        
        return false
    }
}

#Preview {
    SuggestionView(onScreenshot: { nil }, onAIStatusChange: { _ in })
} 
