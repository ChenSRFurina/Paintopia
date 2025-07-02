// 导航管理器
// 管理应用页面间的导航状态

import Foundation
import SwiftUI

class NavigationManager: ObservableObject {
    enum Page {
        case drawing
        case generation
    }
    @Published var currentPage: Page = .drawing
} 