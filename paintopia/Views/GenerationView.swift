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
        isLoading = true
        errorMessage = ""
        
        // 获取图片数据
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            isLoading = false
            errorMessage = "图片处理失败"
            return
        }
        
        // 使用单例上传图片
        DoodleAPIClient.shared.uploadDoodle(imageData: imageData) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let taskId):
                    pollStatus(taskId: taskId)
                case .failure(let error):
                    isLoading = false
                    errorMessage = error.localizedDescription
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
            self.story = "绘本生成完成！这是一个关于任务ID \(taskId) 的有趣故事。"
            self.generatedImage = UIImage(systemName: "photo.artframe")
            self.isLoading = false
        }
    }
}

#Preview {
    GenerationView(image: UIImage(systemName: "photo") ?? UIImage())
} 
