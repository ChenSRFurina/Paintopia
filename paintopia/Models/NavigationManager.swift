// 导航管理器
// 管理应用页面间的导航状态

import Foundation
import SwiftUI

class NavigationManager: ObservableObject {
    @Published var currentPage: Page = .drawing
    
    // TTS控制
    @Published var isTTSEnabled: Bool = true
    
    enum Page {
        case drawing
        case storybook
        case settings
    }
    
    func disableTTS() {
        isTTSEnabled = false
        print("🔇 TTS已禁用")
    }
    
    func enableTTS() {
        isTTSEnabled = true
        print("🔊 TTS已启用")
    }
    
    func toggleTTS() {
        isTTSEnabled.toggle()
        print("🔊 TTS状态切换为: \(isTTSEnabled ? "启用" : "禁用")")
    }
} 