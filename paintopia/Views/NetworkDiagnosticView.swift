import SwiftUI

struct NetworkDiagnosticView: View {
    @State private var chatConnectionStatus: String = "未测试"
    @State private var storybookConnectionStatus: String = "未测试"
    @State private var isTesting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("网络连接诊断")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("聊天API连接:")
                            .font(.headline)
                        Spacer()
                        Text(chatConnectionStatus)
                            .foregroundColor(statusColor(chatConnectionStatus))
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    HStack {
                        Text("绘本API连接:")
                            .font(.headline)
                        Spacer()
                        Text(storybookConnectionStatus)
                            .foregroundColor(statusColor(storybookConnectionStatus))
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                Button(action: testAllConnections) {
                    HStack {
                        if isTesting {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(isTesting ? "测试中..." : "测试所有连接")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isTesting ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isTesting)
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("常见问题解决方案:")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ProblemSolutionItem(
                            problem: "连接超时",
                            solution: "检查后端服务器是否运行，确认IP地址正确"
                        )
                        
                        ProblemSolutionItem(
                            problem: "TTS请求失败",
                            solution: "TTS服务可能需要较长时间，请耐心等待"
                        )
                        
                        ProblemSolutionItem(
                            problem: "绘本生成失败",
                            solution: "绘本生成需要5分钟，请确保网络稳定"
                        )
                        
                        ProblemSolutionItem(
                            problem: "IP地址错误",
                            solution: "在ChatbotAPIClient.swift中修改baseURL为你的Mac实际IP"
                        )
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .alert("诊断结果", isPresented: $showAlert) {
                Button("确定") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func testAllConnections() {
        isTesting = true
        chatConnectionStatus = "测试中..."
        storybookConnectionStatus = "测试中..."
        
        // 测试聊天API连接
        ChatbotAPIClient.shared.testConnection { success, error in
            DispatchQueue.main.async {
                if success {
                    chatConnectionStatus = "连接正常"
                } else {
                    chatConnectionStatus = "连接失败"
                }
                
                // 测试绘本API连接
                StorybookAPIClient.shared.testConnection { success, error in
                    DispatchQueue.main.async {
                        if success {
                            storybookConnectionStatus = "连接正常"
                        } else {
                            storybookConnectionStatus = "连接失败"
                        }
                        
                        isTesting = false
                        
                        // 显示结果
                        let chatStatus = self.chatConnectionStatus == "连接正常" ? "✅" : "❌"
                        let storybookStatus = self.storybookConnectionStatus == "连接正常" ? "✅" : "❌"
                        
                        alertMessage = """
                        诊断完成：
                        
                        聊天API: \(chatStatus) \(self.chatConnectionStatus)
                        绘本API: \(storybookStatus) \(self.storybookConnectionStatus)
                        
                        如果连接失败，请检查：
                        1. 后端服务器是否运行
                        2. IP地址是否正确
                        3. 防火墙设置
                        """
                        showAlert = true
                    }
                }
            }
        }
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status {
        case "连接正常":
            return .green
        case "连接失败":
            return .red
        case "测试中...":
            return .orange
        default:
            return .gray
        }
    }
}

struct ProblemSolutionItem: View {
    let problem: String
    let solution: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("❌ \(problem)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.red)
            
            Text("💡 \(solution)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 20)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NetworkDiagnosticView()
} 