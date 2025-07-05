import Foundation
import AVFoundation

class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var audioURL: URL? = nil
    private var audioRecorder: AVAudioRecorder?
    
    // 录音设置
    private let settings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatLinearPCM),
        AVSampleRateKey: 16000,  // 后端ASR要求16kHz
        AVNumberOfChannelsKey: 1,
        AVLinearPCMBitDepthKey: 16,
        AVLinearPCMIsFloatKey: false,
        AVLinearPCMIsBigEndianKey: false,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue  // 高质量录音
    ]
    
    // 开始录音
    func startRecording() {
        // 先请求麦克风权限
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if granted {
                    // 配置音频会话
                    do {
                        try AVAudioSession.sharedInstance().setCategory(.record, mode: .default)
                        try AVAudioSession.sharedInstance().setActive(true)
                        print("🎤 音频会话配置成功")
                    } catch {
                        print("🎤 音频会话配置失败: \(error)")
                    }
                    
                    let fileName = "recording_\(UUID().uuidString.prefix(8)).wav"
                    let tempDir = FileManager.default.temporaryDirectory
                    let fileURL = tempDir.appendingPathComponent(fileName)
                    print("[AudioRecorder] 尝试开始录音，文件路径: \(fileURL.path)")
                    do {
                        self.audioRecorder = try AVAudioRecorder(url: fileURL, settings: self.settings)
                        self.audioRecorder?.delegate = self
                        self.audioRecorder?.record()
                        self.isRecording = true
                        self.audioURL = fileURL
                        print("[AudioRecorder] 录音已开始，isRecording: true")
                    } catch {
                        print("[AudioRecorder] 录音启动失败: \(error)")
                        self.isRecording = false
                        self.audioURL = nil
                    }
                } else {
                    print("[AudioRecorder] 用户拒绝了麦克风权限")
                    self.isRecording = false
                    self.audioURL = nil
                }
            }
        }
    }
    
    // 停止录音
    func stopRecording() {
        print("[AudioRecorder] 尝试停止录音")
        audioRecorder?.stop()
        isRecording = false
        if let url = audioURL {
            do {
                let data = try Data(contentsOf: url)
                print("[AudioRecorder] 停止录音后文件路径: \(url.path)，文件大小: \(data.count) 字节")
            } catch {
                print("[AudioRecorder] 停止录音后读取文件失败: \(error)")
            }
        } else {
            print("[AudioRecorder] 停止录音后 audioURL 为空")
        }
    }
    
    // 录音完成回调
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            print("[AudioRecorder] 录音完成: \(recorder.url)")
            audioURL = recorder.url
            do {
                let data = try Data(contentsOf: recorder.url)
                print("[AudioRecorder] 录音完成后文件大小: \(data.count) 字节")
            } catch {
                print("[AudioRecorder] 录音完成后读取文件失败: \(error)")
            }
        } else {
            print("[AudioRecorder] 录音失败")
            audioURL = nil
        }
    }
    
    // 清理录音文件
    func deleteRecording() {
        if let url = audioURL {
            do {
                try FileManager.default.removeItem(at: url)
                print("[AudioRecorder] 已删除录音文件: \(url.path)")
            } catch {
                print("[AudioRecorder] 删除录音文件失败: \(error)")
            }
        }
        audioURL = nil
    }
} 