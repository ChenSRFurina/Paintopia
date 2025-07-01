//
//  paintopiaApp.swift
//  paintopia
//
//  Created by Pine's Macmini on 2025/7/1.
//

import SwiftUI

@main
struct paintopiaApp: App {
    init() {
        // 加载 .env 文件
        EnvLoader.loadEnvFile()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
