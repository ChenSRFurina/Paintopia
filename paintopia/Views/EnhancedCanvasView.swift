// 增强版画布视图
// 支持撤销/重做功能的高级绘画画布

import SwiftUI
import UIKit

struct EnhancedCanvasView: View {
    @Binding var selectedColor: Color
    @Binding var selectedLineWidth: CGFloat
    @Binding var isEraser: Bool
    @Binding var paths: [PathSegment]
    @Binding var currentPath: PathSegment?
    
    // 撤销/重做栈
    @State private var undoStack: [CanvasState] = []
    @State private var redoStack: [CanvasState] = []
    private let maxStackSize = 30
    
    // 外部撤销/重做控制
    let onUndo: () -> Void
    let onRedo: () -> Void
    
    init(selectedColor: Binding<Color>,
         selectedLineWidth: Binding<CGFloat>,
         isEraser: Binding<Bool>,
         paths: Binding<[PathSegment]>,
         currentPath: Binding<PathSegment?>,
         onUndo: @escaping () -> Void = {},
         onRedo: @escaping () -> Void = {}) {
        self._selectedColor = selectedColor
        self._selectedLineWidth = selectedLineWidth
        self._isEraser = isEraser
        self._paths = paths
        self._currentPath = currentPath
        self.onUndo = onUndo
        self.onRedo = onRedo
    }
    
    var body: some View {
        ZStack {
            // 画布底部白纸
            Rectangle()
                .fill(Color.white)
                .cornerRadius(12)
                .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
            
            // 已完成的路径
            ForEach(paths) { segment in
                Path { p in
                    if let first = segment.points.first {
                        p.move(to: first)
                        for point in segment.points.dropFirst() {
                            p.addLine(to: point)
                        }
                    }
                }
                .stroke(segment.color, lineWidth: segment.lineWidth)
            }
            
            // 当前正在绘制的路径
            if let segment = currentPath, !isEraser {
                Path { p in
                    if let first = segment.points.first {
                        p.move(to: first)
                        for point in segment.points.dropFirst() {
                            p.addLine(to: point)
                        }
                    }
                }
                .stroke(segment.color, lineWidth: segment.lineWidth)
            }
            
            // 橡皮擦预览
            if isEraser, let segment = currentPath {
                ForEach(Array(segment.points.enumerated()), id: \.offset) { index, point in
                    Circle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: selectedLineWidth * 2, height: selectedLineWidth * 2)
                        .position(point)
                        .allowsHitTesting(false)
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    handleDragChanged(value)
                }
                .onEnded { value in
                    handleDragEnded(value)
                }
        )
        .onAppear {
            // 保存初始状态
            saveToUndoStack()
        }
    }
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        if isEraser {
            // 橡皮擦模式
            if currentPath == nil {
                currentPath = PathSegment(
                    points: [value.location],
                    color: .clear,
                    lineWidth: selectedLineWidth,
                    isEraser: true
                )
            } else {
                currentPath?.points.append(value.location)
            }
            
            // 实时擦除
            performErase(at: value.location)
        } else {
            // 绘画模式
            if currentPath == nil {
                currentPath = PathSegment(
                    points: [value.location],
                    color: selectedColor,
                    lineWidth: selectedLineWidth,
                    isEraser: false
                )
            } else {
                currentPath?.points.append(value.location)
            }
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        if isEraser {
            // 橡皮擦结束，清理当前路径
            currentPath = nil
        } else {
            // 绘画结束，保存路径
            if let finished = currentPath {
                paths.append(finished)
                currentPath = nil
                saveToUndoStack()
            }
        }
    }
    
    private func performErase(at location: CGPoint) {
        let threshold = selectedLineWidth * 1.5
        var newPaths: [PathSegment] = []
        
        for segment in paths {
            var currentSubPath: [CGPoint] = []
            
            for point in segment.points {
                let distance = hypot(point.x - location.x, point.y - location.y)
                if distance < threshold {
                    // 擦除点
                    if !currentSubPath.isEmpty {
                        newPaths.append(PathSegment(
                            points: currentSubPath,
                            color: segment.color,
                            lineWidth: segment.lineWidth,
                            isEraser: false
                        ))
                        currentSubPath = []
                    }
                } else {
                    currentSubPath.append(point)
                }
            }
            
            if !currentSubPath.isEmpty {
                newPaths.append(PathSegment(
                    points: currentSubPath,
                    color: segment.color,
                    lineWidth: segment.lineWidth,
                    isEraser: false
                ))
            }
        }
        
        paths = newPaths.filter { $0.points.count > 1 }
    }
    
    // 撤销功能
    func undo() {
        guard !undoStack.isEmpty else { return }
        
        // 保存当前状态到重做栈
        let currentState = CanvasState(paths: paths)
        if redoStack.count >= maxStackSize {
            redoStack.removeFirst()
        }
        redoStack.append(currentState)
        
        // 恢复上一个状态
        let previousState = undoStack.removeLast()
        paths = previousState.paths
        currentPath = nil
        
        onUndo()
    }
    
    // 重做功能
    func redo() {
        guard !redoStack.isEmpty else { return }
        
        // 保存当前状态到撤销栈
        let currentState = CanvasState(paths: paths)
        if undoStack.count >= maxStackSize {
            undoStack.removeFirst()
        }
        undoStack.append(currentState)
        
        // 恢复重做状态
        let nextState = redoStack.removeLast()
        paths = nextState.paths
        currentPath = nil
        
        onRedo()
    }
    
    private func saveToUndoStack() {
        let state = CanvasState(paths: paths)
        if undoStack.count >= maxStackSize {
            undoStack.removeFirst()
        }
        undoStack.append(state)
        redoStack.removeAll() // 清空重做栈
    }
    
    var canUndo: Bool {
        return undoStack.count > 1
    }
    
    var canRedo: Bool {
        return !redoStack.isEmpty
    }
    
    // 截取画布内容
    func takeScreenshot() -> UIImage? {
        let renderer = ImageRenderer(content: 
            ZStack {
                Rectangle()
                    .fill(Color.white)
                    .cornerRadius(12)
                
                ForEach(paths) { segment in
                    Path { p in
                        if let first = segment.points.first {
                            p.move(to: first)
                            for point in segment.points.dropFirst() {
                                p.addLine(to: point)
                            }
                        }
                    }
                    .stroke(segment.color, lineWidth: segment.lineWidth)
                }
            }
            .frame(width: 800, height: 600)
        )
        
        return renderer.uiImage
    }
}

struct CanvasState {
    let paths: [PathSegment]
    let timestamp = Date()
}

#Preview {
    EnhancedCanvasView(
        selectedColor: .constant(.black),
        selectedLineWidth: .constant(4),
        isEraser: .constant(false),
        paths: .constant([]),
        currentPath: .constant(nil)
    )
    .frame(width: 800, height: 600)
} 