import SwiftUI

struct Suggestion: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct SuggestionView: View {
    @StateObject private var aigcService = AIGCService()
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
            .disabled(isLoading || !APIConfig.isAPIKeyConfigured())
            
            // 截图状态提示
            if !APIConfig.isAPIKeyConfigured() {
                Text("配置 API Key 后可进行 AI 分析")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // API Key 配置状态
            let configResult = ConfigValidator.validateOpenRouterConfig()
            let configSource = ConfigValidator.getConfigSource()
            
            if !configResult.isSuccess {
                VStack(spacing: 8) {
                    Image(systemName: configResult.isSuccess ? "checkmark.circle" : "exclamationmark.triangle")
                        .foregroundColor(configResult.isSuccess ? .green : .orange)
                    Text(configResult.message)
                        .font(.caption)
                        .foregroundColor(configResult.isSuccess ? .green : .orange)
                    Text("配置来源: \(configSource)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    if !configResult.isSuccess {
                        Text("请参考 API_SETUP.md 配置 OpenRouter API Key")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding()
                .background((configResult.isSuccess ? Color.green : Color.orange).opacity(0.1))
                .cornerRadius(8)
            }
            
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
        guard APIConfig.isAPIKeyConfigured() else {
            errorMessage = "请先配置 OpenRouter API Key"
            return
        }
        
        guard let screenshot = onScreenshot() else {
            errorMessage = "截图失败"
            onAIStatusChange(.failure("截图失败"))
            return
        }
        
        isLoading = true
        errorMessage = ""
        aiSuggestion = ""
        onAIStatusChange(.loading)
        
        let prompt = "请分析这个绘画画面，并提供约30字的后续绘画建议。建议应该具体、实用，帮助用户继续完善这幅画。"
        aigcService.analyzeImageWithGPT4(image: screenshot, prompt: prompt) { result in
            isLoading = false
            switch result {
            case .success(let suggestion):
                aiSuggestion = suggestion
                onAIStatusChange(.success(suggestion))
            case .failure(let error):
                errorMessage = error.localizedDescription
                onAIStatusChange(.failure(error.localizedDescription))
            }
        }
    }
}

#Preview {
    SuggestionView(onScreenshot: { nil }, onAIStatusChange: { _ in })
} 