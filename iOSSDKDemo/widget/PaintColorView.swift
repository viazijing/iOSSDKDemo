//
//  ColorView.swift
//  zj-phone
//
//  Created by Mac on 2023/6/12.
//

import Foundation
import UIKit
import common

class PaintColorView: UIView {
    let color: UIColor
    var isSelected: Bool = false {
        didSet {
            if (isSelected) {
                layer.borderColor = UIColor(red: 22/255, green: 97/255, blue: 211/255, alpha: 1).cgColor
            } else {
                layer.borderColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1).cgColor
            }
        }
    }
    
    init(_ color: UIColor) {
        self.color = color
        super.init(frame: CGRect.zero)
        backgroundColor = color
        layer.borderWidth = 2.screenAdapt()
        layer.borderColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1).cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
            // 圆角度数为宽高一半 ，变成圆形
            layer.cornerRadius = bounds.width / 2
        }
    }
    
}
