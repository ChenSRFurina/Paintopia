// 绘本生成视图
// 将画布内容转换为卡通绘本图片和故事

import SwiftUI
import UIKit

struct GenerationView: View {
    let image: UIImage
    @State private var generatedImage: UIImage? = nil
    @State private var story: String = ""
    @State private var isLoading: Bool = true
    @State private var errorMessage: String = ""
    @State private var showStorybookView = false
    @State private var storybookData: StorybookData?
    @State private var showLoadingView = false
    @State private var isGenerating = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("绘本生成中...")
                        .font(.title3)
                        .foregroundColor(.secondary)
                } else if !errorMessage.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("绘本生成遇到问题")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        
                        Text(errorMessage)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            Button("重新生成") {
                                startStorybookGeneration()
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            
                            Button("返回") { dismiss() }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.gray.opacity(0.3))
                                .foregroundColor(.primary)
                                .cornerRadius(8)
                        }
                        .padding(.top, 16)
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("绘本生成成功！")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        if let img = generatedImage {
                            Image(uiImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 320, maxHeight: 320)
                                .cornerRadius(12)
                                .shadow(radius: 6)
                        }
                        
                        ScrollView {
                            Text(story)
                                .font(.body)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxHeight: 200)
                        
                        HStack(spacing: 16) {
                            Button("查看完整绘本") {
                                showStorybookView = true
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            
                            Button("返回") { dismiss() }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.gray.opacity(0.3))
                                .foregroundColor(.primary)
                                .cornerRadius(8)
                        }
                    }
                }
                Spacer()
            }
            .padding()
        }
        .onAppear {
            startStorybookGeneration()
        }
        .fullScreenCover(isPresented: $showStorybookView) {
            if let storybook = storybookData {
                StorybookView(storybookData: storybook)
            }
        }
        .fullScreenCover(isPresented: $showLoadingView) {
            StorybookLoadingView(
                onCancel: {
                    // 取消生成
                    isGenerating = false
                    showLoadingView = false
                    isLoading = false
                    errorMessage = ""
                    dismiss()
                },
                onSuccess: { storybook in
                    // 生成成功
                    self.storybookData = storybook
                    self.story = storybook.pages.first?.text ?? ""
                    self.generatedImage = storybook.characterImage ?? UIImage(systemName: "book.closed.fill")
                    self.showLoadingView = false
                    self.isGenerating = false
                    self.isLoading = false
                }
            )
        }
    }
    
    private func startStorybookGeneration() {
        print("📚 GenerationView开始生成绘本...")
        
        isLoading = true
        isGenerating = true
        errorMessage = ""
        story = ""
        generatedImage = nil
        storybookData = nil
        
        // 显示等待页面
        showLoadingView = true
        
        // 使用新的API客户端生成绘本
        StorybookAPIClient.shared.generateStorybook(image: image) { result in
            DispatchQueue.main.async {
                isLoading = false
                isGenerating = false
                
                switch result {
                case .success(let storybookData):
                    print("✅ 绘本生成成功")
                    print("   - 页数: \(storybookData.pages.count)")
                    print("   - 标题: \(storybookData.title)")
                    
                    // 设置生成的故事
                    self.story = storybookData.pages.first?.text ?? ""
                    self.storybookData = storybookData
                    
                    // 设置默认图片（如果有角色图片的话）
                    self.generatedImage = storybookData.characterImage ?? UIImage(systemName: "book.closed.fill")
                    
                    // 关闭等待页面
                    self.showLoadingView = false
                    print("✅ GenerationView绘本生成完成")
                    
                case .failure(let error):
                    print("❌ 绘本生成失败: \(error.localizedDescription)")
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.showLoadingView = false
                }
            }
        }
    }
}

#Preview {
    GenerationView(image: UIImage(systemName: "photo") ?? UIImage())
} 
