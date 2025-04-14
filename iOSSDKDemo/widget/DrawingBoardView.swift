//
//  DrawingBoardView.swift
//  zj-phone
//
//  Created by Mac on 2023/6/9.
//

import UIKit
import common

public class DrawingBoardView: UIView {
    public class PathInfo: HumanReadable {
        var id: Int?
        var color: UIColor?
        var width: Int?
        var path: UIBezierPath?
        var lineType: LineType?
    }
    
    public enum LineType {
        /**
         手动绘制的线条
         */
        case drawn;
        /**
         添加的线条，由其他人绘制的
         */
        case added
    }

    private var pathInfoStack: [PathInfo] = []
//    private var redoPathInfoStack: [PathInfo] = []
    private var bgColor: UIColor = .clear
    var paintColor: UIColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1)
    var paintWidth: CGFloat = 2.5
    var eraseMode: Bool = false
    var onAddLineListener: ((_ path: PathInfo) -> Void)?
    var onRemoveLineListener: ((_ path: PathInfo) -> Void)?

    public init() {
        super.init(frame: CGRect.zero)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)
        
        // Draw the background color
        context.setFillColor(bgColor.cgColor)
        context.fill(rect)
        
        // Draw all the paths
        for pathInfo in pathInfoStack {
            if let color = pathInfo.color {
                context.setStrokeColor(color.cgColor)
            }
            if let width = pathInfo.width {
                context.setLineWidth(CGFloat(width))
            }
            context.setLineCap(.round)
            context.setLineJoin(.round)
            if let path = pathInfo.path {
                context.addPath(path.cgPath)
            }
            context.strokePath()
        }
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if (eraseMode) {
            for (i,pathInfo) in pathInfoStack.enumerated() {
                if (pathInfo.lineType == .added) {
                    // 添加的别人画的线条，擦不掉
                    continue
                }
                guard let pathMeasure = pathInfo.path?.cgPath.copy(strokingWithWidth: 10, lineCap: .round, lineJoin: .round, miterLimit: .infinity) else {
                    continue
                }
                if (pathMeasure.contains(touch.location(in: self))) {
                    pathInfoStack.remove(at: i)
                    onRemoveLineListener?(pathInfo)
                    break
                }
            }
        } else {
            let pathInfo  = PathInfo()
            pathInfo.color = paintColor
            pathInfo.width = Int(paintWidth)
            pathInfo.path = UIBezierPath()
            pathInfo.path?.lineJoinStyle = .round
            pathInfo.path?.move(to: touch.location(in: self))
            pathInfo.lineType = .drawn
            pathInfoStack.append(pathInfo)
        }
        setNeedsDisplay()
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if (eraseMode) {
            for (i,pathInfo) in pathInfoStack.enumerated() {
                if (pathInfo.lineType == .added) {
                    // 添加的别人画的线条，擦不掉
                    continue
                }
                guard let pathMeasure = pathInfo.path?.cgPath.copy(strokingWithWidth: 10, lineCap: .round, lineJoin: .round, miterLimit: .infinity) else {
                    continue
                }
                if (pathMeasure.contains(touch.location(in: self))) {
                    pathInfoStack.remove(at: i)
                    onRemoveLineListener?(pathInfo)
                    break
                }
            }
        } else {
            let pathInfo = pathInfoStack.last { pathInfo in
                return pathInfo.lineType == .drawn
            }
            if let pathInfo = pathInfo {
                pathInfo.path?.addLine(to: touch.location(in: self))
            }
        }
        setNeedsDisplay()
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (eraseMode) {
        } else {
            let pathInfo = pathInfoStack.last { pathInfo in
                return pathInfo.lineType == .drawn
            }
            if let pathInfo = pathInfo {
                onAddLineListener?(pathInfo)
            }
        }
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (eraseMode) {
        } else {
            let pathInfo = pathInfoStack.last { pathInfo in
                return pathInfo.lineType == .drawn
            }
            if let pathInfo = pathInfo {
                onAddLineListener?(pathInfo)
            }
        }
        setNeedsDisplay()
    }
    
    func setBgColor(_ color: UIColor) {
        bgColor = color
        setNeedsDisplay()
    }
    
//    func undo() {
//        if let lastPath = pathInfoStack.popLast() {
//            redoPathInfoStack.append(lastPath)
//            setNeedsDisplay()
//        }
//    }
//
//    func redo() {
//        if let lastPath = redoPathInfoStack.popLast() {
//            pathInfoStack.append(lastPath)
//            setNeedsDisplay()
//        }
//    }
    
    func addPath(pathInfo: PathInfo) {
        let contains = pathInfoStack.contains { p in
            return p.id == pathInfo.id
        }
        if (contains) {
            return
        }
        pathInfoStack.append(pathInfo)
        setNeedsDisplay()
    }
    
    func getPaths() -> Array<PathInfo> {
        return pathInfoStack
    }
    
    func clearAllLine() {
        pathInfoStack.removeAll()
        setNeedsDisplay()
    }
    
    func clearDrawnLines() {
        for (i,pathInfo) in pathInfoStack.enumerated().reversed() {
            if (pathInfo.lineType == .drawn) {
                pathInfoStack.remove(at: i)
                continue
            }
        }
        setNeedsDisplay()
    }
    
    func clearAddedLines() {
        for (i,pathInfo) in pathInfoStack.enumerated().reversed() {
            if (pathInfo.lineType == .added) {
                pathInfoStack.remove(at: i)
                continue
            }
        }
        setNeedsDisplay()
    }
    
    func remove(id: Int) {
        for (i,pathInfo) in pathInfoStack.enumerated() {
            if (pathInfo.id == id) {
                pathInfoStack.remove(at: i)
                break
            }
        }
        setNeedsDisplay()
    }
}
