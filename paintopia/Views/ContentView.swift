import SwiftUI

struct ContentView: View {
    @StateObject private var navigationManager = NavigationManager()
    
    var body: some View {
        NavigationView {
            VStack {
                if navigationManager.currentPage == .drawing {
                    MainView()
                        .environmentObject(navigationManager)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if navigationManager.currentPage == .generation {
                    GenerationView(prompt: "请用卡通风格画出这幅画。")
                }
            }
            .navigationTitle("paintopia")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .environmentObject(navigationManager)
    }
}

#Preview {
    ContentView()
        .environmentObject(NavigationManager())
} 