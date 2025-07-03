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
        
        // 获取图片数据
        guard let imageData = screenshot.jpegData(compressionQuality: 0.8) else {
            errorMessage = "图片处理失败"
            onAIStatusChange(.failure("图片处理失败"))
            return
        }
        
        isLoading = true
        errorMessage = ""
        aiSuggestion = ""
        onAIStatusChange(.loading)
        
        // 使用单例上传图片
        DoodleAPIClient.shared.uploadDoodle(imageData: imageData) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let taskId):
                    pollStatus(taskId: taskId)
                case .failure(let error):
                    isLoading = false
                    errorMessage = error.localizedDescription
                    onAIStatusChange(.failure(error.localizedDescription))
                }
            }
        }
    }
    
    private func pollStatus(taskId: String) {
        // 直接获取结果，不再轮询
        fetchResult(taskId: taskId)
    }
    
    private func fetchResult(taskId: String) {
        // 最简单的实现：直接设置模拟数据
        DispatchQueue.main.async {
            self.aiSuggestion = "AI 分析完成！建议为任务ID \(taskId) 添加更多细节和色彩。"
            self.isLoading = false
            self.onAIStatusChange(.success(self.aiSuggestion))
        }
    }
}

#Preview {
    SuggestionView(onScreenshot: { nil }, onAIStatusChange: { _ in })
} 
