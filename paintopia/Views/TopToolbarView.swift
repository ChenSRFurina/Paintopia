// 顶部工具栏视图
// 包含Logo、首页、聊天助手、生成、撤销、重做等功能按钮

import SwiftUI

struct TopToolbarView: View {
    @Binding var showChatbot: Bool
    let onGenerate: () -> Void
    let onUndo: () -> Void
    let onRedo: () -> Void
    let onHome: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // 左侧Logo
            HStack {
                Image(systemName: "paintpalette.fill")
                    .foregroundColor(.purple)
                    .font(.title2)
                Text("画趣星球")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
            }
            .padding(.leading, 24)
            
            Spacer()
            
            // 中间按钮组
            HStack(spacing: 16) {
                // 首页按钮
                Button(action: onHome) {
                    Image(systemName: "house.fill")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
                .buttonStyle(TopToolbarButtonStyle())
                
                // 聊天助手按钮
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showChatbot.toggle() 
                    }
                }) {
                    Image(systemName: "message.fill")
                        .font(.title3)
                        .foregroundColor(showChatbot ? .white : .primary)
                }
                .buttonStyle(TopToolbarButtonStyle(isSelected: showChatbot))
                
                // 生成按钮
                Button(action: onGenerate) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
                .buttonStyle(TopToolbarButtonStyle())
                
                // 撤销按钮
                Button(action: onUndo) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
                .buttonStyle(TopToolbarButtonStyle())
                
                // 重做按钮
                Button(action: onRedo) {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
                .buttonStyle(TopToolbarButtonStyle())
            }
            
            Spacer()
            
            // 右侧占位，保持居中
            HStack {
                Text("")
            }
            .frame(width: 120)
            .padding(.trailing, 24)
        }
        .padding(.vertical, 10)
        .background(
            Color.white.opacity(0.8)
                .background(.ultraThinMaterial)
        )
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray.opacity(0.3)),
            alignment: .bottom
        )
    }
}

struct TopToolbarButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    init(isSelected: Bool = false) {
        self.isSelected = isSelected
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 44, height: 44)
            .background(
                isSelected ? Color.blue : 
                (configuration.isPressed ? Color.gray.opacity(0.3) : Color.clear)
            )
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    TopToolbarView(
        showChatbot: .constant(false),
        onGenerate: {},
        onUndo: {},
        onRedo: {},
        onHome: {}
    )
} 