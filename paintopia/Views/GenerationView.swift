import SwiftUI

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
            generateWithDalleAndStory()
        }
    }
    
    private func generateWithDalleAndStory() {
        let aigc = AIGCService()
        let dalle = DalleService()
        isLoading = true
        errorMessage = ""
        // debug: 打印图片信息
        print("[DEBUG] GenerationView image size:", image.size)
        if let data = image.jpegData(compressionQuality: 0.8) {
            print("[DEBUG] GenerationView image base64 length:", data.base64EncodedString().count)
        } else {
            print("[DEBUG] GenerationView image jpegData 失败")
        }
        // 1. 先识别原始画布图片，总结画了什么
        aigc.analyzeImageWithGPT4(image: self.image, prompt: "请用一句话总结这幅画的主要内容。") { summaryResult in
            switch summaryResult {
            case .success(let summary):
                // 拼接卡通绘本风格
                let cartoonPrompt = "请用卡通绘本风格画出：" + summary
                dalle.generateImage(prompt: cartoonPrompt) { result in
                    switch result {
                    case .success(let imageUrl):
                        downloadImage(from: imageUrl) { img in
                            if let img = img {
                                self.generatedImage = img
                                // 3. 用生成图片生成故事
                                aigc.analyzeImageWithGPT4(image: img, prompt: "请根据画面生成一个小故事。") { storyResult in
                                    isLoading = false
                                    switch storyResult {
                                    case .success(let text):
                                        story = text
                                    case .failure(let error):
                                        errorMessage = error.localizedDescription
                                    }
                                }
                            } else {
                                isLoading = false
                                errorMessage = "下载 DALL·E 3 生成图片失败"
                            }
                        }
                    case .failure(let error):
                        isLoading = false
                        errorMessage = error.localizedDescription
                    }
                }
            case .failure(let error):
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private func downloadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let img = UIImage(data: data) {
                DispatchQueue.main.async {
                    completion(img)
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }
}

#Preview {
    GenerationView(image: UIImage(systemName: "photo") ?? UIImage())
} 