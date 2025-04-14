//
//  WhiteBoardFuncView.swift
//  zj-phone
//
//  Created by Mac on 2023/6/13.
//

import Foundation
import UIKit
import SnapKit
import common

class WhiteBoardFuncView: UIView {
    let title: String
    var isSelected: Bool = false {
        didSet {
            for view in subviews {
                if let button = view as? UIButton {
                    button.isSelected = isSelected
                }
            }
        }
    }
    
    init(title: String, selectedTitle: String, image: UIImage?, selectedImage: UIImage?) {
        self.title = title
        super.init(frame: CGRect.zero)
        isUserInteractionEnabled = true
        let text = UIButton()
        // 点击事件交给父控件处理
        text.isUserInteractionEnabled = false
        text.setTitle(title, for: .normal)
        text.setTitleColor(.text_color_ffa1a1a2, for: .normal)
        text.setTitle(selectedTitle, for: .selected)
        text.setTitleColor(.text_color_ffffffff, for: .selected)
//        text.isSelected = true
        text.titleLabel?.font = .systemFont(ofSize: 10.screenAdapt())
        text.titleLabel?.textAlignment = .center
        text.sizeToFit()
        addSubview(text)
        text.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        let img = UIButton()
        // 点击事件交给父控件处理
        img.isUserInteractionEnabled = false
        img.setImage(image, for: .normal)
        img.setImage(selectedImage, for: .selected)
        img.setImage(selectedImage, for: .highlighted)
//        img.isSelected = true
        addSubview(img)
        img.snp.makeConstraints { make in
            make.width.height.equalTo(25.screenAdapt())
            make.top.equalToSuperview().offset(18.screenAdapt())
            make.centerX.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
