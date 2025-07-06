import SwiftUI

struct StorybookView: View {
    let storybookData: StorybookData
    @State private var currentPage = 0
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.1),
                        Color.pink.opacity(0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if !storybookData.pages.isEmpty {
                    VStack(spacing: 0) {
                        // 顶部工具栏
                        HStack {
                            Button(action: {
                                dismiss()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            Text("我的绘本")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button(action: {
                                shareStorybook()
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.9))
                        
                        // 绘本内容
                        if currentPage == 0 {
                            // 封面页
                            StorybookCoverView(storybook: storybookData)
                        } else {
                            // 内容页
                            let pageIndex = currentPage - 1
                            if pageIndex < storybookData.pages.count {
                                StorybookPageView(
                                    page: storybookData.pages[pageIndex],
                                    pageNumber: pageIndex + 1
                                )
                            }
                        }
                        
                        Spacer()
                        
                        // 底部导航
                        HStack {
                            Button(action: {
                                if currentPage > 0 {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentPage -= 1
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("上一页")
                                }
                                .font(.title3)
                                .foregroundColor(currentPage > 0 ? .primary : .secondary)
                            }
                            .disabled(currentPage == 0)
                            
                            Spacer()
                            
                            // 页码指示器
                            Text("\(currentPage + 1) / \(storybookData.pages.count + 1)")
                                .font(.title3)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: {
                                if currentPage < storybookData.pages.count {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentPage += 1
                                    }
                                }
                            }) {
                                HStack {
                                    Text("下一页")
                                    Image(systemName: "chevron.right")
                                }
                                .font(.title3)
                                .foregroundColor(currentPage < storybookData.pages.count ? .primary : .secondary)
                            }
                            .disabled(currentPage == storybookData.pages.count)
                        }
                        .padding()
                        .background(Color.white.opacity(0.9))
                    }
                } else {
                    // 空状态
                    VStack(spacing: 20) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 100))
                            .foregroundColor(.secondary)
                        
                        Text("还没有绘本")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("去画画生成你的第一个绘本吧！")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Text("返回")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
    }
    
    private func shareStorybook() {
        // 生成分享图片
        // 这里可以生成当前页面的截图用于分享
        // 暂时使用一个示例图片
        shareImage = UIImage(systemName: "book.closed")
        showShareSheet = true
    }
}

// MARK: - 绘本封面视图
struct StorybookCoverView: View {
    let storybook: StorybookData
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // 封面图片 - 如果有角色图片则显示，否则显示默认封面
            if let characterImage = storybook.characterImage {
                Image(uiImage: characterImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 1200, maxHeight: 1200)
                    .cornerRadius(20)
                    .shadow(radius: 10)
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(maxWidth: 1200, maxHeight: 1200)
                    .overlay(
                        VStack {
                            Image(systemName: "book.closed.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                            Text("绘本")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    )
                    .shadow(radius: 10)
            }
            
            // 标题
            Text(storybook.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // 作者信息
            Text("作者：\(storybook.author)")
                .font(.title3)
                .foregroundColor(.secondary)
            
            // 创建时间
            Text("创建于：\(formatDate(storybook.createdAt))")
                .font(.body)
                .foregroundColor(.secondary)
            
            // 页数信息
            Text("共 \(storybook.pages.count) 页")
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - 绘本页面视图
struct StorybookPageView: View {
    let page: StorybookPage
    let pageNumber: Int
    
    var body: some View {
        VStack(spacing: 20) {
            // 页面标题
            Text(page.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // 页面图片 - 设置为1200x1200
            if let imageData = page.imageData {
                Image(uiImage: imageData)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 1200, maxHeight: 1200)
                    .cornerRadius(20)
                    .shadow(radius: 8)
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.3))
                    .frame(maxWidth: 1200, maxHeight: 1200)
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            Text("暂无图片")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    )
            }
            
            // 页面文字
            ScrollView {
                Text(page.text)
                    .font(.title2)
                    .lineSpacing(8)
                    .multilineTextAlignment(.leading)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(15)
            }
            .frame(maxHeight: 200)
            
            // 页码
            Text("第 \(pageNumber) 页")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - 分享页面
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - 数据模型
// 注意：数据模型定义已移至 Models/StorybookModels.swift

// MARK: - 预览
struct StorybookView_Previews: PreviewProvider {
    static var previews: some View {
        // 创建示例数据
        let samplePages = [
            StorybookPage(
                text: "这是一个示例故事页面，讲述了小兔子的冒险故事。",
                title: "小兔子的冒险",
                imageData: nil,
                pageNumber: 1
            )
        ]
        
        let sampleStorybook = StorybookData(
            title: "示例绘本",
            author: "AI创作",
            createdAt: Date(),
            pages: samplePages,
            characterImage: nil
        )
        
        StorybookView(storybookData: sampleStorybook)
    }
} 