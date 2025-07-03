// 右侧绘画工具栏视图
// 包含画笔、橡皮擦、颜色选择器、粗细调节等绘画工具

import SwiftUI

struct RightToolsView: View {
    @Binding var selectedColor: Color
    @Binding var selectedLineWidth: CGFloat
    @Binding var isEraser: Bool
    
    let colors: [Color] = [.black, .red, .blue, .green, .yellow, .orange, .purple, .gray, .brown]
    let lineWidths: [CGFloat] = [2, 4, 8, 16, 24]
    
    var body: some View {
        VStack(spacing: 24) {
            // 顶部留白
            Spacer()
                .frame(height: 32)
            
            // 画笔按钮
            Button(action: { 
                isEraser = false 
            }) {
                Image("pen_1")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .colorMultiply(isEraser ? .gray : .white)
            }
            .frame(width: 48, height: 48)
            .background(isEraser ? Color.white : Color.blue)
            .cornerRadius(24)
            .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
            .overlay(
                Circle()
                    .stroke(isEraser ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
            )
            
            // 橡皮擦按钮
            Button(action: { 
                isEraser = true 
            }) {
                Image("eraser")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .colorMultiply(isEraser ? .white : .gray)
            }
            .frame(width: 48, height: 48)
            .background(isEraser ? Color.blue : Color.white)
            .cornerRadius(24)
            .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
            .overlay(
                Circle()
                    .stroke(isEraser ? Color.clear : Color.blue.opacity(0.3), lineWidth: 2)
            )
            
            // 颜色选择器
            VStack(spacing: 8) {
                ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
                    Circle()
                        .fill(color)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(
                                    selectedColor == color && !isEraser ? Color.blue : Color.clear, 
                                    lineWidth: 3
                                )
                        )
                        .scaleEffect(selectedColor == color && !isEraser ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: selectedColor)
                        .onTapGesture {
                            selectedColor = color
                            isEraser = false
                        }
                }
            }
            
            // 分隔线
            Rectangle()
                .frame(width: 32, height: 1)
                .foregroundColor(.gray.opacity(0.3))
                .padding(.vertical, 8)
            
            // 笔刷粗细选择
            VStack(spacing: 12) {
                ForEach(lineWidths, id: \.self) { width in
                    Button(action: {
                        selectedLineWidth = width
                    }) {
                        Circle()
                            .fill(selectedLineWidth == width ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: width + 8, height: width + 8)
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                    }
                    .scaleEffect(selectedLineWidth == width ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: selectedLineWidth)
                }
            }
            
            Spacer()
        }
        .frame(width: 80)
        .background(
            Rectangle()
                .fill(Color.blue.opacity(0.12))
                .background(.ultraThinMaterial)
        )
        .overlay(
            Rectangle()
                .frame(width: 2)
                .foregroundColor(.blue.opacity(0.3)),
            alignment: .leading
        )
        .cornerRadius(0)
    }
}

#Preview {
    RightToolsView(
        selectedColor: .constant(.black),
        selectedLineWidth: .constant(4),
        isEraser: .constant(false)
    )
    .frame(height: 600)
} 