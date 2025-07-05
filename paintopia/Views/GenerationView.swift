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
    @Environment(\.dismiss) private var dismiss
    

    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            if isLoading {
                ProgressView()
                    .scaleEffect(1.2)
                Text("绘本生成中...")
                    .font(.title3)
                    .foregroundColor(.secondary)
            } else if !errorMessage.isEmpty {
                Text("生成失败：\(errorMessage)")
                    .foregroundColor(.red)
                    .font(.title3)
                Button("返回") { dismiss() }
                    .padding(.top, 16)
            } else {
                Text("绘本生成成功！")
                    .font(.title2)
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
                .frame(maxHeight: 220)
                Button("返回") { dismiss() }
                    .padding(.top, 8)
            }
            Spacer()
        }
        .padding()
        .onAppear {
            startDoodleGeneration()
        }
    }
    
    private func startDoodleGeneration() {
        print("📚 GenerationView开始生成绘本...")
        
        isLoading = true
        errorMessage = ""
        story = ""
        generatedImage = nil
        
        // 检查是否是系统占位图标
        if image.isSymbolImage || isSystemPlaceholderImage(image) {
            print("❌ 检测到系统占位图标，无法生成绘本")
            isLoading = false
            errorMessage = "请先在画布上绘制一些内容再生成绘本"
            return
        }
        
        // 获取图片数据
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ 图片处理失败")
            isLoading = false
            errorMessage = "图片处理失败"
            return
        }
        
        // 检查图片大小，如果太小可能是空图片
        if imageData.count < 500 {
            print("❌ 图片数据过小 (\(imageData.count) bytes)，可能是空白图片")
            isLoading = false
            errorMessage = "图片内容过少，请绘制更多内容后再试"
            return
        }
        
        print("✅ 图片验证通过，大小: \(imageData.count) bytes，尺寸: \(image.size.width)x\(image.size.height)")
        
        print("📤 开始上传图片进行AI识别，图片大小: \(imageData.count) bytes")
        
        // 使用单例上传图片，后端处理所有AI逻辑
        DoodleAPIClient.shared.uploadDoodle(imageData: imageData) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let aiResult):
                    print("✅ AI处理成功")
                    print("   - 识别结果: \(aiResult.recognition)")
                    print("   - 故事: \(aiResult.story)")
                    
                    if aiResult.success {
                        // 直接使用后端返回的故事
                        self.story = aiResult.story
                        self.generatedImage = UIImage(systemName: "photo.artframe")
                        self.isLoading = false
                        print("✅ GenerationView绘本生成完成")
                    } else {
                        // 处理失败情况
                        self.isLoading = false
                        self.errorMessage = aiResult.error ?? "AI处理失败"
                        print("❌ AI处理失败: \(self.errorMessage)")
                    }
                    
                case .failure(let error):
                    print("❌ 网络请求失败: \(error.localizedDescription)")
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
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
                print("⚠️ 检测到可能的系统图标，尺寸: \(size.width)x\(size.height)")
                return true
            }
        }
        
        // 画布截图通常是较大的矩形 (800x600)，这样的大小不太可能是系统图标
        if size.width >= 400 && size.height >= 300 {
            print("✅ 图片尺寸正常，应该是画布内容: \(size.width)x\(size.height)")
            return false
        }
        
        return false
    }
}

#Preview {
    GenerationView(image: UIImage(systemName: "photo") ?? UIImage())
} 
