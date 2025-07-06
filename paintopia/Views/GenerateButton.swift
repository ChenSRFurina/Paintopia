import SwiftUI
import UIKit

struct GenerateButton: View {
    let image: UIImage
    @Binding var isLoading: Bool
    @Binding var story: String
    @Binding var errorMessage: String
    @Binding var showStorybookView: Bool
    @Binding var storybookData: StorybookData?
    
    // 新增状态变量
    @State private var showLoadingView = false
    @State private var isGenerating = false
    
    // 添加环境对象
    @EnvironmentObject var navigationManager: NavigationManager
    
    var body: some View {
        Button(action: {
            generateStorybook()
        }) {
            Text("生成绘本")
                .font(.title2)
                .frame(maxWidth: 300)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .disabled(isLoading || isGenerating)
        .fullScreenCover(isPresented: $showLoadingView) {
            StorybookLoadingView(
                onCancel: {
                    // 取消生成
                    isGenerating = false
                    showLoadingView = false
                    isLoading = false
                    errorMessage = ""
                    // 恢复TTS
                    navigationManager.enableTTS()
                },
                onSuccess: { storybook in
                    // 生成成功
                    self.storybookData = storybook
                    self.story = storybook.pages.first?.text ?? ""
                    self.showLoadingView = false
                    self.isGenerating = false
                    self.isLoading = false
                    self.showStorybookView = true
                    // 恢复TTS
                    navigationManager.enableTTS()
                }
            )
        }
    }
    
    private func generateStorybook() {
        isLoading = true
        isGenerating = true
        errorMessage = ""
        story = ""
        storybookData = nil
        
        // 禁用TTS以避免干扰
        navigationManager.disableTTS()
        
        // 显示等待页面
        showLoadingView = true
        
        // 使用新的StorybookAPIClient
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
                    
                    // 关闭等待页面，显示绘本页面
                    self.showLoadingView = false
                    self.showStorybookView = true
                    
                case .failure(let error):
                    print("❌ 绘本生成失败: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                    self.showLoadingView = false
                    // 恢复TTS
                    navigationManager.enableTTS()
                }
            }
        }
    }
}

#Preview {
    GenerateButton(
        image: UIImage(systemName: "photo") ?? UIImage(),
        isLoading: .constant(false),
        story: .constant(""),
        errorMessage: .constant(""),
        showStorybookView: .constant(false),
        storybookData: .constant(nil)
    )
    .environmentObject(NavigationManager())
} 
