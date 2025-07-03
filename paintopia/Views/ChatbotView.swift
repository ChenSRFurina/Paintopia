// 聊天助手视图
// 左侧可切换显示的AI聊天助手界面

import SwiftUI

struct ChatbotView: View {
    @State private var messages: [ChatMessage] = [
        ChatMessage(text: "哈喽小朋友，有什么想和我分享的呀？", isUser: false)
    ]
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    
    var body: some View {
        HStack(spacing: 0) {
            // 头像区域
            VStack {
                Image("avatar")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.blue, lineWidth: 2)
                    )
                    .padding(.top, 20)
                Spacer()
            }
            .frame(width: 60)
            
            // 聊天内容区域
            VStack(spacing: 0) {
                // 头部
                HStack {
                    Text("小画")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                // 消息列表
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            ChatMessageRow(message: message)
                        }
                        
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("小画正在思考...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .frame(maxHeight: 300)
                
                // 输入区域
                VStack(spacing: 8) {
                    Divider()
                    
                    HStack(spacing: 8) {
                        TextField("想和小画说什么...", text: $inputText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.body)
                        
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .frame(width: 36, height: 36)
                        .background(Color.blue)
                        .cornerRadius(8)
                        .disabled(inputText.isEmpty || isLoading)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .frame(width: 280)
        .background(
            Color.white.opacity(0.95)
                .background(.ultraThinMaterial)
        )
        .cornerRadius(16)
        .shadow(color: .blue.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(.leading, 16)
        .padding(.top, 16)
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        
        // 添加用户消息
        let userMessage = ChatMessage(text: inputText, isUser: true)
        messages.append(userMessage)
        
        let messageText = inputText
        inputText = ""
        isLoading = true
        
        // 模拟AI回复
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let responses = [
                "哇，这个想法很棒呢！继续画下去吧～",
                "我觉得可以加一些颜色哦，会更好看的！",
                "画得真不错！要不要试试用不同的笔刷？",
                "很有创意呢！小画很喜欢你的作品～",
                "继续加油！期待看到更多精彩的作品！"
            ]
            
            let aiReply = ChatMessage(
                text: responses.randomElement() ?? "谢谢分享，继续创作吧！",
                isUser: false
            )
            messages.append(aiReply)
            isLoading = false
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp = Date()
}

struct ChatMessageRow: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                Text(message.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .frame(maxWidth: 200, alignment: .trailing)
            } else {
                Text(message.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                    .frame(maxWidth: 200, alignment: .leading)
                Spacer()
            }
        }
    }
}

#Preview {
    ChatbotView()
        .padding()
        .background(Color.gray.opacity(0.1))
} 