import SwiftUI

struct ToolbarView: View {
    @Binding var selectedColor: Color
    @Binding var selectedLineWidth: CGFloat
    @Binding var isEraser: Bool
    var undoAction: () -> Void
    
    let colors: [Color] = [.black, .red, .blue, .green, .yellow, .orange, .purple, .gray, .white]
    let lineWidths: [CGFloat] = [2, 4, 8, 16]
    
    var body: some View {
        VStack(spacing: 20) {
            // 画笔/橡皮切换
            Button(action: { isEraser = false }) {
                Image(systemName: "pencil")
                    .foregroundColor(isEraser ? .gray : .accentColor)
                    .padding(8)
                    .background(isEraser ? Color.clear : Color.accentColor.opacity(0.15))
                    .clipShape(Circle())
            }
            Button(action: {
                isEraser = true
                selectedColor = .white // 橡皮擦默认纯白
            }) {
                Image(systemName: "eraser")
                    .foregroundColor(isEraser ? .accentColor : .gray)
                    .padding(8)
                    .background(isEraser ? Color.accentColor.opacity(0.15) : Color.clear)
                    .clipShape(Circle())
            }
            Divider().frame(height: 1)
            // 颜色选择
            ForEach(colors, id: \.self) { color in
                Circle()
                    .fill(color)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle().stroke(selectedColor == color && !isEraser ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
                    .onTapGesture {
                        selectedColor = color
                        isEraser = false
                    }
            }
            Divider().frame(height: 1)
            // 粗细选择
            ForEach(lineWidths, id: \.self) { width in
                Circle()
                    .fill(selectedLineWidth == width ? Color.accentColor : Color.secondary)
                    .frame(width: width + 12, height: width + 12)
                    .overlay(
                        Circle().stroke(Color.gray, lineWidth: 1)
                    )
                    .onTapGesture {
                        selectedLineWidth = width
                    }
            }
            Divider().frame(height: 1)
            // 撤销按钮
            Button(action: undoAction) {
                Image(systemName: "arrow.uturn.backward")
            }
            Spacer()
        }
        .padding(.top, 20)
    }
}

#Preview {
    ToolbarView(selectedColor: .constant(.black), selectedLineWidth: .constant(4), isEraser: .constant(false), undoAction: {})
} 