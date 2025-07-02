// 绘画视图占位符
// 预留的绘画页面组件

import SwiftUI

struct DrawingView: View {
    var body: some View {
        VStack {
            Text("绘画页（Canvas 占位）")
                .font(.title)
                .padding()
            Spacer()
        }
    }
}

#Preview {
    DrawingView()
} 