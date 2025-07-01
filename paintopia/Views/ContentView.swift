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
                    GenerationView(image: UIImage(systemName: "photo") ?? UIImage())
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