import Foundation
import UIKit

extension QwenVLWebSocketClient {
    func recognizeImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        var resultHandler: ((String?) -> Void)? = completion
        
        // 设置代理
        self.delegate = QwenVLImageRecognitionDelegate(onResult: { result in
            resultHandler?(result)
            resultHandler = nil  // 防止多次回调
            self.disconnect()
        })
        
        // 连接成功后发送图片
        connect()
        
        // 准备图片数据
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion("图片转换失败")
            return
        }
        
        let base64 = imageData.base64EncodedString()
        let message: [String: Any] = [
            "action": "qwenvl_image_recognition",
            "image": base64
        ]
        
        // 发送数据
        send(message: message) { error in
            if let error = error {
                completion("发送失败: \(error.localizedDescription)")
            }
        }
    }
}

// 图片识别专用的代理实现
private class QwenVLImageRecognitionDelegate: WebSocketDelegate {
    private let onResult: (String?) -> Void
    
    init(onResult: @escaping (String?) -> Void) {
        self.onResult = onResult
    }
    
    func didReceive(message: String) {
        if let data = message.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            
            if let action = json["action"] as? String,
               action == "qwenvl_image_recognition" {
                onResult(json["result"] as? String)
            } else if let errorMsg = json["message"] as? String {
                onResult("错误: \(errorMsg)")
            }
        }
    }
    
    func didConnect() {
        // 连接成功，等待发送数据
    }
    
    func didDisconnect(error: Error?) {
        if let error = error {
            onResult("连接断开: \(error.localizedDescription)")
        }
    }
    
    func didReconnect() {
        // 重新连接成功，可以在这里重新发送之前失败的请求
        onResult("重新连接成功")
    }
} 