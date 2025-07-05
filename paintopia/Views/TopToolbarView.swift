// 顶部工具栏视图
// 包含Logo、首页、聊天助手、生成、撤销、重做等功能按钮

import SwiftUI

struct TopToolbarView: View {
    let canGenerate: Bool
    let onGenerate: () -> Void
    let onUndo: () -> Void
    let onRedo: () -> Void
    let onHome: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // 左侧Logo
            HStack {
                Image("logo_name")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 40)
            }
            .padding(.leading, 24)
            
            Spacer()
            
            // 中间按钮组
            HStack(spacing: 16) {
                // 首页按钮
                Button(action: onHome) {
                    Image("icon_home")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(TopToolbarButtonStyle())
                
                // 生成按钮
                Button(action: onGenerate) {
                    Image("icon_generate")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .colorMultiply(canGenerate ? .primary : .gray)
                }
                .buttonStyle(TopToolbarButtonStyle(isDisabled: !canGenerate))
                .disabled(!canGenerate)
                
                // 撤销按钮
                Button(action: onUndo) {
                    Image("icon_arrow_left")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(TopToolbarButtonStyle())
                
                // 重做按钮
                Button(action: onRedo) {
                    Image("icon_arrow_right")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
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
        .padding(.top, 20)
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
    let isDisabled: Bool
    
    init(isSelected: Bool = false, isDisabled: Bool = false) {
        self.isSelected = isSelected
        self.isDisabled = isDisabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 44, height: 44)
            .background(
                isDisabled ? Color.gray.opacity(0.1) :
                (isSelected ? Color.blue : 
                (configuration.isPressed ? Color.gray.opacity(0.3) : Color.clear))
            )
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed && !isDisabled ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    TopToolbarView(
        canGenerate: true,
        onGenerate: {},
        onUndo: {},
        onRedo: {},
        onHome: {}
    )
} 