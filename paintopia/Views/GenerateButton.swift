// 生成按钮组件
// 通用的生成操作按钮

import SwiftUI

struct GenerateButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text("生成")
                .font(.title2)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
}

#Preview {
    GenerateButton(action: {})
} 