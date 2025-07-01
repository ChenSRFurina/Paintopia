import Foundation
import SwiftUI

class NavigationManager: ObservableObject {
    enum Page {
        case drawing
        case generation
    }
    @Published var currentPage: Page = .drawing
} 