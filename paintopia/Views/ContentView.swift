// 主内容视图控制器
// 管理应用的主要导航和页面切换，支持新旧UI切换

import SwiftUI

struct ContentView: View {
    @StateObject private var navigationManager = NavigationManager()
    @State private var useNewUI = false // 控制使用新UI还是旧UI
    
    var body: some View {
        NavigationView {
            VStack {
                if navigationManager.currentPage == .drawing {
                    if useNewUI {
                        // 新的HTML风格界面
                        NewMainView()
                            .environmentObject(navigationManager)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // 原始界面
                        VStack {
                            // UI切换按钮
                            HStack {
                                Spacer()
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                        useNewUI.toggle()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: useNewUI ? "arrow.left.circle" : "sparkles")
                                        Text(useNewUI ? "切换到原版" : "体验新版UI")
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                                }
                                .padding(.trailing, 20)
                                .padding(.top, 10)
                            }
                            
                            MainView()
                                .environmentObject(navigationManager)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                } else if navigationManager.currentPage == .generation {
                    GenerationView(image: UIImage(systemName: "photo") ?? UIImage())
                }
            }
            .navigationTitle("paintopia")
            .navigationBarHidden(useNewUI) // 新UI隐藏导航栏
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .environmentObject(navigationManager)
        .overlay(
            // 新UI下的切换按钮
            Group {
                if useNewUI {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    useNewUI.toggle()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.left.circle")
                                    Text("切换到原版")
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.black.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .font(.caption)
                            }
                            .padding(.trailing, 20)
                            .padding(.top, 20)
                        }
                        Spacer()
                    }
                }
            }
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(NavigationManager())
} 