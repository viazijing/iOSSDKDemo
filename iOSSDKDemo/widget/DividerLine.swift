//
//  DividerLine.swift
//  CloudConference
//
//  Created by zst on 2023/4/13.
//

import UIKit
import common

class DividerLine: UIView {
    
    convenience init() {
        self.init(height: 0.5.screenAdapt())
    }
    
    convenience init(height: CGFloat) {
        self.init(height: height, color: .divider_line_color_ffedeff2)
    }
    
    init(height: CGFloat, color: UIColor) {
        super.init(frame: CGRect(x: 0, y: 0, width: ScreenUtil.SCREEN_WIDTH, height: height))
        backgroundColor = color
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
