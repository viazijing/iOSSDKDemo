//
//  PaintWidthView.swift
//  zj-phone
//
//  Created by Mac on 2023/6/13.
//

import UIKit

class PaintWidthView: UIView {
    let width: CGFloat
    var isSelected: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var selectedColor: CGColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1).cgColor {
        didSet {
            setNeedsDisplay()
        }
    }
    
    init(_ width: CGFloat) {
        self.width = width
        super.init(frame: CGRect.zero)
        backgroundColor = UIColor.clear
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        let path = UIBezierPath()
        // 起点
        path.move(to: CGPoint(x: bounds.minX + width / 2, y: bounds.maxY - width / 2))
        // 添加直线
        path.addLine(to: CGPoint(x: bounds.maxX - width / 2, y: bounds.minY + width / 2))
        if (isSelected) {
            context.setStrokeColor(selectedColor)
        } else {
            context.setStrokeColor(UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1).cgColor)
        }
        context.setLineWidth(width)
        context.setLineCap(.round)
        
        context.addPath(path.cgPath)
        context.strokePath()
    }
    
    override var bounds: CGRect{
        didSet {
            // 保证正方形
            if (bounds.width != bounds.height) {
                bounds.size.width = min(bounds.width, bounds.height)
            }
            if (bounds.height != bounds.width) {
                bounds.size.height = min(bounds.width, bounds.height)
            }
            setNeedsDisplay()
        }
    }
}
