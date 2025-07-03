import Foundation

protocol WebSocketDelegate: AnyObject {
    func didReceive(message: String)
    func didConnect()
    func didDisconnect(error: Error?)
    func didReconnect()
}

class QwenVLWebSocketClient {
    private var webSocketTask: URLSessionWebSocketTask?
    private let serverURL: URL
    weak var delegate: WebSocketDelegate?
    private var isConnected = false
    private var shouldReconnect = true
    private var reconnectTimer: Timer?
    private let reconnectInterval: TimeInterval = 5.0
    
    init(url: String) {
        guard let url = URL(string: url) else {
            fatalError("Invalid URL")
        }
        self.serverURL = url
    }
    
    func connect() {
        guard !isConnected else { return }
        
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: serverURL)
        webSocketTask?.resume()
        
        // 开始接收消息
        receiveMessage()
        
        isConnected = true
        shouldReconnect = true
        
        // 通知连接成功
        DispatchQueue.main.async {
            self.delegate?.didConnect()
        }
    }
    
    func disconnect() {
        shouldReconnect = false
        stopReconnectTimer()
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        isConnected = false
    }
    
    private func reconnect() {
        guard shouldReconnect else { return }
        
        print("尝试重新连接 WebSocket...")
        isConnected = false
        webSocketTask = nil
        connect()
        
        DispatchQueue.main.async {
            self.delegate?.didReconnect()
        }
    }
    
    private func startReconnectTimer() {
        stopReconnectTimer()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: reconnectInterval, repeats: false) { [weak self] _ in
            self?.reconnect()
        }
    }
    
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    DispatchQueue.main.async {
                        self.delegate?.didReceive(message: text)
                    }
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            self.delegate?.didReceive(message: text)
                        }
                    }
                @unknown default:
                    break
                }
                
                // 继续接收下一条消息
                self.receiveMessage()
                
            case .failure(let error):
                print("WebSocket 接收消息错误：\(error.localizedDescription)")
                self.isConnected = false
                
                DispatchQueue.main.async {
                    self.delegate?.didDisconnect(error: error)
                    if self.shouldReconnect {
                        self.startReconnectTimer()
                    }
                }
            }
        }
    }
    
    func send(message: [String: Any], completion: ((Error?) -> Void)? = nil) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            completion?(NSError(domain: "QwenVLWebSocketClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的 JSON 数据"]))
            return
        }
        
        webSocketTask?.send(.string(jsonString)) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("发送 WebSocket 消息失败：\(error.localizedDescription)")
                }
                completion?(error)
            }
        }
    }
    
    func sendImageForRecognition(_ imageBase64: String, completion: ((Error?) -> Void)? = nil) {
        let message: [String: Any] = [
            "action": "qwenvl_image_recognition",
            "image": imageBase64
        ]
        send(message: message, completion: completion)
    }
    
    deinit {
        disconnect()
    }
} 