// 主内容视图控制器
// 只保留绘画页面

import SwiftUI

struct ContentView: View {
    @StateObject private var navigationManager = NavigationManager()
    @State private var isLoggedIn: Bool = false
    
    var body: some View {
        if isLoggedIn {
            NewMainView()
                .environmentObject(navigationManager)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            LoginPage { username, password in
                // 这里可以加账号密码校验逻辑
                withAnimation {
                    isLoggedIn = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(NavigationManager())
} 
