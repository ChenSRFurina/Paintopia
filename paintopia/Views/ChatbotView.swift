// 智能聊天助手视图
// 集成FractFlow后端，支持LLM对话、VLM图像分析、记忆存储和定时提问

import SwiftUI
import AVFoundation

struct ChatbotView: View {
    @Binding var canvasImage: UIImage?
    @Binding var paths: [PathSegment]
    @Binding var isObservingCanvas: Bool
    
    @StateObject private var apiClient = ChatbotAPIClient.shared
    @StateObject private var audioRecorder = AudioRecorder()
    @EnvironmentObject var navigationManager: NavigationManager
    
    @State private var messages: [EnhancedChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var isRecording = false
    @State private var isUploading = false
    @State private var recognitionError: String?
    @State private var audioPlayer: AVAudioPlayer?
    
    // 自动分析相关
    @State private var autoAnalysisTimer: Timer?
    @State private var lastAnalysisTime: Date?
    private let analysisInterval: TimeInterval = 30.0 // 30秒间隔
    
    @State private var connectionStatus: String = "未连接"
    @State private var connectionColor: Color = .gray
    
    init(canvasImage: Binding<UIImage?> = .constant(nil), paths: Binding<[PathSegment]> = .constant([]), isObservingCanvas: Binding<Bool> = .constant(false)) {
        self._canvasImage = canvasImage
        self._paths = paths
        self._isObservingCanvas = isObservingCanvas
    }
    
    var body: some View {
        if isObservingCanvas {
            HStack {
                Spacer()
                Text("正在观察画布，请稍等...")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.top, 8)
                Spacer()
            }
        }
        HStack(spacing: 0) {
            // 头像区域
            VStack {
                ZStack {
                    Image("avatar")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(connectionColor, lineWidth: 2)
                        )
                    
                    // 连接状态指示器
                    if isLoading {
                        Circle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 52, height: 52)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            )
                    }
                }
                .padding(.top, 20)
                
                // 连接状态文本
                Text(connectionStatus)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                
                Spacer()
            }
            .frame(width: 60)
            
            // 聊天内容区域 - 悬浮气泡形式
            VStack(spacing: 0) {
                // 头部
                HStack {
                    VStack(alignment: .leading) {
                        Text("小画")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        if let sessionId = apiClient.currentSessionId {
                            Text("会话: \(sessionId.prefix(8))...")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // 功能按钮
                    HStack(spacing: 8) {
                        // 分析画布按钮
                        Button(action: analyzeCurrentCanvas) {
                            Image(systemName: "eye.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .frame(width: 24, height: 24)
                        .background(Color.blue)
                        .cornerRadius(6)
                        .disabled(isLoading || paths.isEmpty)
                        
                        // 新会话按钮
                        Button(action: startNewSession) {
                            Image(systemName: "plus.circle.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .frame(width: 24, height: 24)
                        .background(Color.green)
                        .cornerRadius(6)
                        .disabled(isLoading)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                // 消息列表 - 悬浮气泡
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                FloatingChatBubble(message: message)
                                    .id(message.id)
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .opacity
                                    ))
                                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: message.id)
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
                                .id("loading")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20) // 底部留白
                    }
                    .frame(maxHeight: 400) // 限制高度
                    .onChange(of: messages.count) { _ in
                        if let lastMessage = messages.last {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Spacer()
            }
        }
        .frame(width: 300)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.leading, 16)
        .padding(.top, 16)
        .overlay(
            // 悬浮麦克风按钮
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        if audioRecorder.isRecording {
                            stopRecordingAndRecognize()
                        } else if !isUploading {
                            startRecording()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(audioRecorder.isRecording ? Color.red : Color.blue)
                                .frame(width: 56, height: 56)
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            
                            // 录音时的脉冲动画
                            if audioRecorder.isRecording {
                                Circle()
                                    .stroke(Color.red.opacity(0.3), lineWidth: 2)
                                    .frame(width: 72, height: 72)
                                    .scaleEffect(1.5)
                                    .opacity(0)
                                    .animation(
                                        Animation.easeInOut(duration: 1.5)
                                            .repeatForever(autoreverses: false),
                                        value: audioRecorder.isRecording
                                    )
                            }
                            
                            Image(systemName: audioRecorder.isRecording ? "mic.fill" : "mic")
                                .foregroundColor(.white)
                                .font(.system(size: 24, weight: .bold))
                        }
                        .scaleEffect(audioRecorder.isRecording ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: audioRecorder.isRecording)
                    }
                    .accessibilityLabel(audioRecorder.isRecording ? "正在录音，点击结束" : "点击开始语音输入")
                    .disabled(isUploading)
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
                    
                    // 录音状态提示
                    if audioRecorder.isRecording {
                        Text("正在录音...")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.trailing, 16)
                            .padding(.bottom, 8)
                    } else if isUploading {
                        Text("识别中...")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.trailing, 16)
                            .padding(.bottom, 8)
                    }
                }
            }
        )
        .onAppear {
            initializeChatbot()
        }
        .onDisappear {
            stopAutoAnalysis()
        }
        .onChange(of: paths) { newPaths in
            handleCanvasChange()
        }
    }
    
    // MARK: - 计算属性
    
    private func initializeChatbot() {
        connectionStatus = "初始化中..."
        
        // 创建新会话
        apiClient.createNewSession { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.success {
                        self.connectionStatus = "已连接"
                        self.connectionColor = .green
                        // 添加欢迎消息
                        let welcomeMessage = EnhancedChatMessage(
                            text: response.message ?? "哈喽小朋友，我是小画！有什么想和我分享的呀？我可以看你的画哦～",
                            isUser: false,
                            messageType: .text
                        )
                        self.messages.append(welcomeMessage)
                        
                        // 开始自动分析定时器
                        self.startAutoAnalysis()
                    } else {
                        self.connectionStatus = "连接失败"
                        self.connectionColor = .gray
                        print("❌ 会话创建失败: \(response.error ?? "未知错误")")
                    }
                case .failure(let error):
                    self.connectionStatus = "连接失败"
                    self.connectionColor = .gray
                    print("❌ 网络连接失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func startNewSession() {
        isLoading = true
        connectionStatus = "创建新会话..."
        
        apiClient.createNewSession { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    if response.success {
                        self.connectionStatus = "已连接"
                        self.connectionColor = .green
                        // 清空消息并添加新的欢迎消息
                        self.messages.removeAll()
                        let welcomeMessage = EnhancedChatMessage(
                            text: "新的绘画对话开始啦！我是小画，准备好和你一起创作了～",
                            isUser: false,
                            messageType: .text
                        )
                        self.messages.append(welcomeMessage)
                        self.startAutoAnalysis()
                    } else {
                        self.connectionStatus = "连接失败"
                        self.connectionColor = .gray
                    }
                case .failure(_):
                    self.connectionStatus = "连接失败"
                    self.connectionColor = .gray
                }
            }
        }
    }
    
    // MARK: - 图像分析功能
    
    private func analyzeCurrentCanvas() {
        print("🔍 开始分析画布...")
        print("🔍 当前路径数量: \(paths.count)")
        
        guard !paths.isEmpty else {
            let hintMessage = EnhancedChatMessage(
                text: "画布上还没有内容呢，先画一些东西让我看看吧～",
                isUser: false,
                messageType: .text
            )
            messages.append(hintMessage)
            return
        }
        
        // 创建画布截图
        let canvasImage = createCanvasScreenshot()
        guard let image = canvasImage else {
            let errorMessage = EnhancedChatMessage(
                text: "抱歉，我现在看不清你的画，请稍后再试～",
                isUser: false,
                messageType: .error
            )
            messages.append(errorMessage)
            return
        }
        
        isLoading = true
        
        // 添加分析提示消息
        let analysisMessage = EnhancedChatMessage(
            text: "让我看看你画的是什么...",
            isUser: false,
            messageType: .analysis
        )
        messages.append(analysisMessage)
        
        // 使用新的observeAndReply接口
        print("🔍 调用observeAndReply接口...")
        apiClient.observeAndReply(image) { result, rawJson in
            DispatchQueue.main.async {
                self.isLoading = false
                
                // 检查rawJson中的audio_data
                if let audioBase64 = rawJson?["audio_data"] as? String, !audioBase64.isEmpty {
                    print("收到音频数据，长度: \(audioBase64.count) 字符")
                    // 播放从后端返回的音频
                    self.playAudioFromBase64(audioBase64)
                    print("✅ 已播放后端返回的音频")
                } else {
                    print("未检测到audio_data或内容为空")
                }
                
                switch result {
                case .success(let response):
                    if response.success {
                        // 移除分析提示消息
                        if let lastMessage = self.messages.last, lastMessage.messageType == .analysis {
                            self.messages.removeLast()
                        }
                        
                        // 优先使用vision_desc作为回复内容，如果为空则使用llm_reply
                        let replyText = !response.visionDesc.isEmpty ? response.visionDesc : response.llmReply
                        
                        // 检查回复内容是否包含错误信息
                        let errorKeywords = ["小画需要先看看", "请截图", "看不清楚"]
                        let containsError = errorKeywords.contains { keyword in
                            replyText.contains(keyword)
                        }
                        
                        // 如果包含错误信息，使用vision_desc或默认回复
                        let finalReplyText: String
                        if containsError && !response.visionDesc.isEmpty {
                            finalReplyText = response.visionDesc
                            print("⚠️ 检测到错误回复，使用vision_desc: \(response.visionDesc)")
                        } else if containsError {
                            finalReplyText = "我看到你画了一些很有趣的东西！能告诉我你在画什么吗？"
                            print("⚠️ 检测到错误回复，使用默认回复")
                        } else {
                            finalReplyText = replyText
                        }
                        
                        // 添加AI回复消息
                        let aiMessage = EnhancedChatMessage(
                            text: finalReplyText,
                            isUser: false,
                            messageType: .imageAnalysis,
                            imageData: image
                        )
                        
                        self.messages.append(aiMessage)
                        
                        // 为画布分析回复生成TTS语音（仅在TTS启用时）
                        if !finalReplyText.isEmpty && self.navigationManager.isTTSEnabled {
                            print("🎵 为画布分析回复生成TTS语音，文本: \(finalReplyText.prefix(50))...")
                            self.apiClient.generateTTS(text: finalReplyText) { ttsResult in
                                DispatchQueue.main.async {
                                    switch ttsResult {
                                    case .success(let audioData):
                                        print("🎵 画布分析TTS成功，播放音频，大小: \(audioData.count) bytes")
                                        self.playAudioFromData(audioData)
                                    case .failure(let error):
                                        print("❌ 画布分析TTS失败: \(error.localizedDescription)")
                                    }
                                }
                            }
                        } else if !finalReplyText.isEmpty && !self.navigationManager.isTTSEnabled {
                            print("🔇 TTS已禁用，跳过画布分析语音生成")
                        }
                        
                        // 更新最后分析时间
                        self.lastAnalysisTime = Date()
                        
                        print("✅ 画布分析完成，视觉描述: \(response.visionDesc)")
                        print("✅ AI回复已添加到消息列表，内容: \(finalReplyText)")
                        print("✅ 当前消息总数: \(self.messages.count)")
                        print("✅ 最新消息ID: \(aiMessage.id)")
                        print("✅ 最新消息类型: \(aiMessage.messageType)")
                        print("✅ 最新消息时间: \(aiMessage.timestamp)")
                        
                    } else {
                        let errorMessage = EnhancedChatMessage(
                            text: "抱歉，我现在看不清楚，能再试一次吗？",
                            isUser: false,
                            messageType: .error
                        )
                        messages.append(errorMessage)
                    }
                case .failure(let error):
                    print("❌ 画布分析失败: \(error.localizedDescription)")
                    let errorMessage = EnhancedChatMessage(
                        text: "网络连接有问题，请稍后再试～",
                        isUser: false,
                        messageType: .error
                    )
                    messages.append(errorMessage)
                }
            }
        }
    }
    
    private func createCanvasScreenshot() -> UIImage? {
        let canvasContent = ZStack {
            Rectangle()
                .fill(Color.white)
                .cornerRadius(12)
            
            ForEach(paths) { segment in
                Path { p in
                    if let first = segment.points.first {
                        p.move(to: first)
                        for point in segment.points.dropFirst() {
                            p.addLine(to: point)
                        }
                    }
                }
                .stroke(segment.color, lineWidth: segment.lineWidth)
            }
        }
        .frame(width: 800, height: 600)
        .background(Color.white)
        
        let renderer = ImageRenderer(content: canvasContent)
        return renderer.uiImage
    }
    
    // MARK: - 自动分析功能
    
    private func startAutoAnalysis() {
        stopAutoAnalysis()
        autoAnalysisTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            checkForAutoAnalysis()
        }
    }
    
    private func stopAutoAnalysis() {
        autoAnalysisTimer?.invalidate()
        autoAnalysisTimer = nil
    }
    
    private func handleCanvasChange() {
        // 当画布有新内容时，重置分析计时
        if !paths.isEmpty {
            lastAnalysisTime = nil
        }
    }
    
    private func checkForAutoAnalysis() {
        guard !paths.isEmpty, !isLoading else { return }
        
        let now = Date()
        let shouldAnalyze: Bool
        
        if let lastTime = lastAnalysisTime {
            // 如果超过分析间隔，进行新分析
            shouldAnalyze = now.timeIntervalSince(lastTime) > analysisInterval
        } else {
            // 如果从未分析过，检查画布是否有足够内容
            shouldAnalyze = paths.count >= 3 // 至少有3条路径
        }
        
        if shouldAnalyze {
            // 发送智能提问
            sendSmartQuestion()
        }
    }
    
    private func sendSmartQuestion() {
        let questions = [
            "我看到你画了一些很有趣的东西！能告诉我你在画什么吗？",
            "你的画看起来很棒呢！想加一些颜色或者细节吗？",
            "这幅画让我想到了很多故事，你想听我分析一下吗？",
            "画得真不错！你觉得还可以添加什么来让它更丰富呢？",
            "你的创意很棒！要不要我给你一些绘画建议？"
        ]
        
        let randomQuestion = questions.randomElement() ?? "画得真不错！要不要和我聊聊你的作品？"
        
        let questionMessage = EnhancedChatMessage(
            text: randomQuestion,
            isUser: false,
            messageType: .smartQuestion
        )
        
        DispatchQueue.main.async {
            self.messages.append(questionMessage)
            self.lastAnalysisTime = Date()
        }
    }
    
    // MARK: - 录音与语音识别
    private func startRecording() {
        print("🎤 开始录音流程...")
        recognitionError = nil
        
        // 先检查当前权限状态
        let currentStatus = AVAudioSession.sharedInstance().recordPermission
        print("🎤 当前麦克风权限状态: \(currentStatus.rawValue)")
        
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                print("🎤 权限请求结果: \(granted)")
                if granted {
                    print("🎤 权限已获得，开始录音...")
                    self.audioRecorder.startRecording()
                } else {
                    print("🎤 权限被拒绝")
                    self.recognitionError = "请在设置中允许麦克风访问"
                }
            }
        }
    }
    private func stopRecordingAndRecognize() {
        audioRecorder.stopRecording()
        guard let url = audioRecorder.audioURL else {
            recognitionError = "录音失败，请重试"
            return
        }
        isUploading = true
        uploadAudioForRecognition(audioURL: url) { result in
            DispatchQueue.main.async {
                self.isUploading = false
                switch result {
                case .success(let text):
                    if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        self.recognitionError = "未识别到有效语音"
                    } else {
                        // 直接发送给LLM，不再填入输入框
                        let userMessage = EnhancedChatMessage(text: text, isUser: true, messageType: .text)
                        self.messages.append(userMessage)
                        self.sendRecognizedText(text)
                    }
                case .failure(_):
                    self.recognitionError = "语音识别失败，请重试"
                }
                // 清理录音
                self.audioRecorder.deleteRecording()
            }
        }
    }
    
    private func sendRecognizedText(_ text: String) {
        isLoading = true
        apiClient.sendTextMessage(text, observeCanvasHandler: { sessionId in
            observeCanvasAndReply(sessionId: sessionId)
        }) { result, rawJson in
            DispatchQueue.main.async {
                self.isLoading = false
                // 检查rawJson中的audio_data
                if let audioBase64 = rawJson?["audio_data"] as? String, !audioBase64.isEmpty {
                    print("收到音频数据，长度: \(audioBase64.count) 字符")
                    // 播放从后端返回的音频
                    self.playAudioFromBase64(audioBase64)
                    print("✅ 已播放后端返回的音频")
                } else {
                    print("未检测到audio_data或内容为空")
                }
                switch result {
                case .success(let response):
                    if response.success {
                        let aiMessage = EnhancedChatMessage(
                            text: response.response,
                            isUser: false,
                            messageType: .text
                        )
                        
                        // 为AI回复生成TTS语音（仅在TTS启用时）
                        if !response.response.isEmpty && self.navigationManager.isTTSEnabled {
                            print("🎵 为AI回复生成TTS语音，文本: \(response.response.prefix(50))...")
                            self.apiClient.generateTTS(text: response.response) { ttsResult in
                                DispatchQueue.main.async {
                                    switch ttsResult {
                                    case .success(let audioData):
                                        print("🎵 AI回复TTS成功，播放音频，大小: \(audioData.count) bytes")
                                        self.playAudioFromData(audioData)
                                    case .failure(let error):
                                        print("❌ AI回复TTS失败: \(error.localizedDescription)")
                                    }
                                }
                            }
                        } else if !response.response.isEmpty && !self.navigationManager.isTTSEnabled {
                            print("🔇 TTS已禁用，跳过AI回复语音生成")
                        }
                        
                        self.messages.append(aiMessage)
                    } else {
                        let errorMessage = EnhancedChatMessage(
                            text: "抱歉，我现在有点困惑。能再试一次吗？",
                            isUser: false,
                            messageType: .error
                        )
                        self.messages.append(errorMessage)
                    }
                case .failure(_):
                    let errorMessage = EnhancedChatMessage(
                        text: "网络连接有问题，请稍后再试～",
                        isUser: false,
                        messageType: .error
                    )
                    self.messages.append(errorMessage)
                }
            }
        }
    }
    
    // MARK: - 上传音频到后端识别
    private func uploadAudioForRecognition(audioURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "http://10.4.176.7:8000/api/speech-to-text")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        let filename = audioURL.lastPathComponent
        let mimetype = "audio/wav"
        let fileData = try? Data(contentsOf: audioURL)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData ?? Data())
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let success = json["success"] as? Bool, success,
                  let text = json["text"] as? String else {
                completion(.failure(NSError(domain: "SpeechToText", code: -1, userInfo: nil)))
                return
            }
            completion(.success(text))
        }.resume()
    }
    
    private func observeCanvasAndReply(sessionId: String?) {
        self.isObservingCanvas = true
        // 截图
        let canvasImage = createCanvasScreenshot()
        guard let image = canvasImage else {
            self.isObservingCanvas = false
            return
        }
        // 回传给后端，带session_id
        apiClient.analyzeImage(image) { result, rawJson in
            DispatchQueue.main.async {
                self.isObservingCanvas = false
                // 回传后可自动触发分析/对话流程（如有需要）
                // 这里可根据实际需求继续后续流程
            }
        }
    }
    
    private func playAudioFromBase64(_ base64String: String) {
        guard let audioData = Data(base64Encoded: base64String) else {
            print("Base64解码失败")
            return
        }
        playAudioFromData(audioData)
    }
    
    private func playAudioFromData(_ audioData: Data) {
        do {
            // 确保音频会播放
            try? AVAudioSession.sharedInstance().setCategory(.playback)
            let player = try AVAudioPlayer(data: audioData)
            player.prepareToPlay()
            player.play()
            self.audioPlayer = player // 必须持有引用
            print("音频已开始播放，长度: \(audioData.count) 字节")
        } catch {
            print("音频播放失败: \(error)")
        }
    }
}

// MARK: - 增强消息模型

struct EnhancedChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp = Date()
    let messageType: MessageType
    let imageData: UIImage?
    
    init(text: String, isUser: Bool, messageType: MessageType, imageData: UIImage? = nil) {
        self.text = text
        self.isUser = isUser
        self.messageType = messageType
        self.imageData = imageData
    }
    
    enum MessageType {
        case text
        case imageAnalysis
        case smartQuestion
        case analysis
        case error
    }
}

// MARK: - 悬浮对话气泡组件
struct FloatingChatBubble: View {
    let message: EnhancedChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.text)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.blue)
                        )
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        // 消息类型图标
                        Group {
                            switch message.messageType {
                            case .imageAnalysis:
                                Image(systemName: "eye.fill")
                                    .foregroundColor(.blue)
                            case .smartQuestion:
                                Image(systemName: "questionmark.circle.fill")
                                    .foregroundColor(.orange)
                            case .analysis:
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.purple)
                            case .error:
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                            default:
                                Image(systemName: "message.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .font(.caption)
                        
                        Text(message.text)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(backgroundColorForType(message.messageType))
                            )
                    }
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.leading, 20)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 4)
    }
    
    private func backgroundColorForType(_ type: EnhancedChatMessage.MessageType) -> Color {
        switch type {
        case .imageAnalysis:
            return Color.blue.opacity(0.1)
        case .smartQuestion:
            return Color.orange.opacity(0.1)
        case .analysis:
            return Color.purple.opacity(0.1)
        case .error:
            return Color.red.opacity(0.1)
        default:
            return Color(.systemGray6)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    ChatbotView(canvasImage: .constant(nil), paths: .constant([]), isObservingCanvas: .constant(false))
        .padding()
        .background(Color.gray.opacity(0.1))
} 