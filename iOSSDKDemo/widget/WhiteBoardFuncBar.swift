//
//  WhiteBoardFuncBar.swift
//  zj-phone
//
//  Created by Mac on 2023/6/13.
//

import Foundation
import UIKit
import common

class WhiteBoardFuncBar: UIView {
    private lazy var whiteBoardFuncViewsContainer = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1)
        view.layer.cornerRadius = 5.screenAdapt()
        return view
    }()
    private lazy var whiteBoardFuncViews = UIStackView()
    private lazy var paintFuncViews = UIView()
    private lazy var paintColorViews = UIStackView()
    private lazy var paintWidthViews = UIStackView()
    private lazy var clearViews = UIView()
    /**
     收起时被选中的功能的位置
     */
    private var preSelectedIndex = 1
    var onUnfoldListener: ((_ unfold: Bool) -> Void)?
    var onPaintColorSelectedListener: ((_ color: UIColor) -> Void)?
    var onPaintWidthSelectedListener: ((_ width: CGFloat) -> Void)?
    var onEraserModeClickListener: ((_ eraserMode: Bool) -> Void)?
    var onClearMarkClickListener: ((_ clearMarkType: ClearMarkType) -> Void)?
    var onDownloadClickListener: (() -> Void)?
    
    init(hideClearAllAndClearOther: Bool = false) {
        super.init(frame: CGRect.zero)
        initWhiteBoardFuncViews()
        initPaintFuncViews()
        initClearFuncViews(hideClearAllAndClearOther: hideClearAllAndClearOther)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        var view = super.hitTest(point, with: event)
        // 处理子控件超出父布局 frame 时的点击事件
        if (view == nil) {
            view = findOnTouchView(parent: self, point: point)
        }
        return view
    }
    
    private func initWhiteBoardFuncViews() {
        addSubview(whiteBoardFuncViewsContainer)
        whiteBoardFuncViewsContainer.snp.makeConstraints { make in
            make.width.height.equalTo(45.screenAdapt())
        }
        whiteBoardFuncViews.backgroundColor = UIColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1)
        whiteBoardFuncViews.layer.cornerRadius = 5.screenAdapt()
        whiteBoardFuncViews.distribution = .fillEqually
        whiteBoardFuncViewsContainer.addSubview(whiteBoardFuncViews)
        whiteBoardFuncViews.snp.makeConstraints { make in
            make.width.height.equalToSuperview()
        }
        // 展开/收起
        let unfoldView = WhiteBoardFuncView(title: "收起", selectedTitle: "展开", image: UIImage(named: "conference_iv_fold_src"), selectedImage: UIImage(named: "conference_iv_fold_src_selected"))
        unfoldView.addTarget(target: self, action: #selector(unfold(_:)))
        unfoldView.isSelected = true
        whiteBoardFuncViews.addArrangedSubview(unfoldView)
    }
    
    private func initPaintFuncViews() {
        // 画笔功能控件
        paintFuncViews.isHidden = true
        addSubview(paintFuncViews)
        paintFuncViews.snp.makeConstraints { make in
            make.width.equalTo(160.screenAdapt())
            make.height.equalTo(65.screenAdapt())
            make.left.equalTo(whiteBoardFuncViews.snp.left).offset(32.screenAdapt())
            make.bottom.equalTo(whiteBoardFuncViews.snp.top).offset(-6.screenAdapt())
        }
        let container = UIView()
        container.backgroundColor = UIColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1)
        container.layer.cornerRadius = 3.screenAdapt()
        paintFuncViews.addSubview(container)
        container.snp.makeConstraints { make in
            make.height.equalTo(62.screenAdapt())
            make.left.top.right.equalToSuperview()
        }
        let ivArrorDown = UIImageView(image: UIImage(named: "conference_iv_arrow_down_src"))
        paintFuncViews.addSubview(ivArrorDown)
        ivArrorDown.snp.makeConstraints { make in
            make.width.equalTo(8.screenAdapt())
            make.height.equalTo(3.screenAdapt())
            make.top.equalTo(container.snp.bottom)
            make.left.equalToSuperview().offset(30.screenAdapt())
        }
        // 顶部边距
        let topSpaceView = UIView()
        container.addSubview(topSpaceView)
        topSpaceView.snp.makeConstraints { make in
            make.height.equalTo(5.screenAdapt())
            make.left.right.top.equalToSuperview()
        }
        // 底部边距
        let bottomSpaceView = UIView()
        container.addSubview(bottomSpaceView)
        bottomSpaceView.snp.makeConstraints { make in
            make.height.equalTo(5.screenAdapt())
            make.left.right.bottom.equalToSuperview()
        }
        let stackView = UIStackView()
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        stackView.spacing = 10.screenAdapt()
        container.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(topSpaceView.snp.bottom)
            make.bottom.equalTo(bottomSpaceView.snp.top)
        }
        // 画笔颜色
        paintColorViews.distribution = .fillEqually
        stackView.addArrangedSubview(paintColorViews)
        // 黑
        let black = PaintColorView(UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1))
        black.addTarget(target: self, action: #selector(selectColor(_:)))
        paintColorViews.addArrangedSubview(black)
        // 黄
        let yellow = PaintColorView(UIColor(red: 255/255, green: 213/255, blue: 98/255, alpha: 1))
        yellow.addTarget(target: self, action: #selector(selectColor(_:)))
        paintColorViews.addArrangedSubview(yellow)
        // 红
        let red = PaintColorView(UIColor(red: 255/255, green: 96/255, blue: 92/255, alpha: 1))
        red.addTarget(target: self, action: #selector(selectColor(_:)))
        paintColorViews.addArrangedSubview(red)
        // 绿
        let green = PaintColorView(UIColor(red: 64/255, green: 227/255, blue: 171/255, alpha: 1))
        green.addTarget(target: self, action: #selector(selectColor(_:)))
        paintColorViews.addArrangedSubview(green)
        // 蓝
        let blue = PaintColorView(UIColor(red: 64/255, green: 140/255, blue: 255/255, alpha: 1))
        blue.addTarget(target: self, action: #selector(selectColor(_:)))
        paintColorViews.addArrangedSubview(blue)
        // 画笔粗细
        paintWidthViews.distribution = .fillEqually
        stackView.addArrangedSubview(paintWidthViews)
        //  2.5
        let paintWidthView2_5 = PaintWidthView(2.5)
        paintWidthView2_5.addTarget(target: self, action: #selector(selectWidth(_:)))
        paintWidthViews.addArrangedSubview(paintWidthView2_5)
        // 5
        let paintWidthView5 = PaintWidthView(5)
        paintWidthView5.addTarget(target: self, action: #selector(selectWidth(_:)))
        paintWidthViews.addArrangedSubview(paintWidthView5)
        // 7.5
        let paintWidthView7_5 = PaintWidthView(7.5)
        paintWidthView7_5.addTarget(target: self, action: #selector(selectWidth(_:)))
        paintWidthViews.addArrangedSubview(paintWidthView7_5)
        // 10
        let paintWidthView10 = PaintWidthView(10)
        paintWidthView10.addTarget(target: self, action: #selector(selectWidth(_:)))
        paintWidthViews.addArrangedSubview(paintWidthView10)
        black.isSelected = true
        paintWidthView2_5.isSelected = true
        for view in paintWidthViews.subviews {
            guard let paintWidthView = (view as? PaintWidthView) else {
                continue
            }
            paintWidthView.selectedColor = black.color.cgColor
        }
    }
    
    private func initClearFuncViews(hideClearAllAndClearOther: Bool) {
        // 清除功能控件
        if (hideClearAllAndClearOther) {
            clearViews.isHidden = true
            addSubview(clearViews)
            clearViews.snp.makeConstraints { make in
                make.width.equalTo(110.screenAdapt())
                make.height.equalTo(28.screenAdapt())
                make.left.equalTo(whiteBoardFuncViews.snp.left).offset(60.screenAdapt())
                make.bottom.equalTo(whiteBoardFuncViews.snp.top).offset(-6.screenAdapt())
            }
            let container = UIView()
            container.backgroundColor = UIColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1)
            container.layer.cornerRadius = 3.screenAdapt()
            clearViews.addSubview(container)
            container.snp.makeConstraints { make in
                make.height.equalTo(25.screenAdapt())
                make.left.top.right.equalToSuperview()
            }
            let ivArrorDown = UIImageView(image: UIImage(named: "conference_iv_arrow_down_src"))
            clearViews.addSubview(ivArrorDown)
            ivArrorDown.snp.makeConstraints { make in
                make.width.equalTo(8.screenAdapt())
                make.height.equalTo(3.screenAdapt())
                make.top.equalTo(container.snp.bottom)
                make.left.equalToSuperview().offset(95.screenAdapt())
            }
            // 左边边距
            let leftSpaceView = UIView()
            container.addSubview(leftSpaceView)
            leftSpaceView.snp.makeConstraints { make in
                make.width.equalTo(7.screenAdapt())
                make.left.top.bottom.equalToSuperview()
            }
            let stackView = UIStackView()
            stackView.distribution = .fillEqually
            stackView.axis = .vertical
            stackView.alignment = .leading
            container.addSubview(stackView)
            stackView.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.left.equalTo(leftSpaceView.snp.right)
                make.right.equalToSuperview()
            }
            // 清除我的标注
            let clearMyMark = UILabel()
            clearMyMark.text = "清除我的标注"
            clearMyMark.textColor = .white
            clearMyMark.font = .systemFont(ofSize: 12.screenAdapt())
            clearMyMark.addTarget(target: self, action: #selector(clearMark(_:)))
            stackView.addArrangedSubview(clearMyMark)
        } else {
            clearViews.isHidden = true
            addSubview(clearViews)
            clearViews.snp.makeConstraints { make in
                make.width.equalTo(110.screenAdapt())
                make.height.equalTo(78.screenAdapt())
                make.left.equalTo(whiteBoardFuncViews.snp.left).offset(60.screenAdapt())
                make.bottom.equalTo(whiteBoardFuncViews.snp.top).offset(-6.screenAdapt())
            }
            let container = UIView()
            container.backgroundColor = UIColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1)
            container.layer.cornerRadius = 3.screenAdapt()
            clearViews.addSubview(container)
            container.snp.makeConstraints { make in
                make.height.equalTo(75.screenAdapt())
                make.left.top.right.equalToSuperview()
            }
            let ivArrorDown = UIImageView(image: UIImage(named: "conference_iv_arrow_down_src"))
            clearViews.addSubview(ivArrorDown)
            ivArrorDown.snp.makeConstraints { make in
                make.width.equalTo(8.screenAdapt())
                make.height.equalTo(3.screenAdapt())
                make.top.equalTo(container.snp.bottom)
                make.left.equalToSuperview().offset(95.screenAdapt())
            }
            // 左边边距
            let leftSpaceView = UIView()
            container.addSubview(leftSpaceView)
            leftSpaceView.snp.makeConstraints { make in
                make.width.equalTo(7.screenAdapt())
                make.left.top.bottom.equalToSuperview()
            }
            let stackView = UIStackView()
            stackView.distribution = .fillEqually
            stackView.axis = .vertical
            stackView.alignment = .leading
            container.addSubview(stackView)
            stackView.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.left.equalTo(leftSpaceView.snp.right)
                make.right.equalToSuperview()
            }
            // 清除所有标注
            let clearAllMark = UILabel()
            clearAllMark.text = "清除所有标注"
            clearAllMark.textColor = .white
            clearAllMark.font = .systemFont(ofSize: 12.screenAdapt())
            clearAllMark.addTarget(target: self, action: #selector(clearMark(_:)))
            stackView.addArrangedSubview(clearAllMark)
            // 清除我的标注
            let clearMyMark = UILabel()
            clearMyMark.text = "清除我的标注"
            clearMyMark.textColor = .white
            clearMyMark.font = .systemFont(ofSize: 12.screenAdapt())
            clearMyMark.addTarget(target: self, action: #selector(clearMark(_:)))
            stackView.addArrangedSubview(clearMyMark)
            // 清除其他人的标注
            let clearOtherMark = UILabel()
            clearOtherMark.text = "清除其他人的标注"
            clearOtherMark.textColor = .white
            clearOtherMark.font = .systemFont(ofSize: 12.screenAdapt())
            clearOtherMark.addTarget(target: self, action: #selector(clearMark(_:)))
            stackView.addArrangedSubview(clearOtherMark)
        }
    }
    
    private func findOnTouchView(parent: UIView, point: CGPoint) -> UIView? {
        if (parent.subviews.count == 0) {
            // 没有子控件了，判断自己符不符合要求
            if (CGRectContainsPoint(parent.bounds, point) && parent.isVisible()) {
                return parent
            } else {
                return nil
            }
        }
        // 有子控件，就继续递归找符合要求的子控件
        for view in parent.subviews {
            let convertPoint = view.convert(point, from: parent)
            let onTouchView = findOnTouchView(parent: view, point: convertPoint)
            if (onTouchView != nil) {
                return onTouchView
            }
        }
        return nil
    }
    
    @objc private func unfold(_ gesture: UIGestureRecognizer) {
        if (gesture.view == nil) {
            return
        }
        guard let button = gesture.view!.subviews.first as? UIButton else {
            return
        }
        button.isSelected = !button.isSelected
        onUnfoldListener?(!button.isSelected)
        if (button.isSelected) {
            // 被选中说明是收起状态，需要移除其他功能控件
            for i in (1 ..< whiteBoardFuncViews.arrangedSubviews.count).reversed() {
                if let whiteBoardFuncView = whiteBoardFuncViews.arrangedSubviews[i] as? WhiteBoardFuncView {
                    if (whiteBoardFuncView.isSelected) {
                        preSelectedIndex = i
                    }
                }
                whiteBoardFuncViews.arrangedSubviews[i].removeFromSuperview()
            }
            paintFuncViews.isHidden = true
            clearViews.isHidden = true
            whiteBoardFuncViewsContainer.snp.updateConstraints { make in
                make.width.equalTo(45.screenAdapt())
            }
        } else {
            // 未被选中说明是展开状态，需要添加其他功能控件
            // 画笔
            let paintView = WhiteBoardFuncView(title: "画笔", selectedTitle: "画笔", image: UIImage(named: "conference_iv_paint_src"), selectedImage: UIImage(named: "conference_iv_paint_src_selected"))
            paintView.addTarget(target: self, action: #selector(selectWhiteBoardFunc(_:)))
            whiteBoardFuncViews.addArrangedSubview(paintView)
            // 橡皮
            let eraserView = WhiteBoardFuncView(title: "橡皮", selectedTitle: "橡皮", image: UIImage(named: "conference_iv_eraser_src"), selectedImage: UIImage(named: "conference_iv_eraser_src_selected"))
            eraserView.addTarget(target: self, action: #selector(selectWhiteBoardFunc(_:)))
            whiteBoardFuncViews.addArrangedSubview(eraserView)
            // 清除
            let clearView = WhiteBoardFuncView(title: "清除", selectedTitle: "清除", image: UIImage(named: "conference_iv_clear_src"), selectedImage: UIImage(named: "conference_iv_clear_src_selected"))
            clearView.addTarget(target: self, action: #selector(selectWhiteBoardFunc(_:)))
            whiteBoardFuncViews.addArrangedSubview(clearView)
            // 下载
            let downloadView = WhiteBoardFuncView(title: "下载", selectedTitle: "下载", image: UIImage(named: "conference_iv_download_src"), selectedImage: UIImage(named: "conference_iv_download_src_selected"))
            downloadView.addTarget(target: self, action: #selector(selectWhiteBoardFunc(_:)))
            whiteBoardFuncViews.addArrangedSubview(downloadView)
            whiteBoardFuncViewsContainer.snp.updateConstraints { make in
                make.width.equalTo(225.screenAdapt())
            }
            // 展开时选中之前选中的
            (whiteBoardFuncViews.arrangedSubviews[preSelectedIndex] as? WhiteBoardFuncView)?.isSelected = true
            // 根据选中的是否是画笔功能，来决定画笔功能控件是否展示
            paintFuncViews.isHidden = preSelectedIndex != 1
            // 根据选中的是否是清除功能，来决定清除功能控件是否展示
            clearViews.isHidden = preSelectedIndex != 3
        }
    }
    
    @objc private func selectWhiteBoardFunc(_ gesture: UIGestureRecognizer) {
        if let isSelected = (gesture.view as? WhiteBoardFuncView)?.isSelected {
            if (isSelected) {
                // 点击的控件，已经是被选中状态，直接 return
                return
            }
        }
        // 获取之前选中的，还是从 1 开始，跳过“展开/收起”
        var preSelectedPosition: Int?
        for i in 1..<whiteBoardFuncViews.subviews.count {
            let view = whiteBoardFuncViews.subviews[i]
            guard let whiteBoardFuncView = (view as? WhiteBoardFuncView) else {
                continue
            }
            if (whiteBoardFuncView.isSelected) {
                preSelectedPosition = i
                break
            }
        }
        // 从 1 开始，跳过“展开/收起”
        for i in 1..<whiteBoardFuncViews.subviews.count {
            let view = whiteBoardFuncViews.subviews[i]
            (view as? WhiteBoardFuncView)?.isSelected = (view == gesture.view)
        }
        paintFuncViews.isHidden = (gesture.view as? WhiteBoardFuncView)?.title != "画笔"
        clearViews.isHidden = (gesture.view as? WhiteBoardFuncView)?.title != "清除"
        onEraserModeClickListener?((gesture.view as? WhiteBoardFuncView)?.title == "橡皮")
        if let title = (gesture.view as? WhiteBoardFuncView)?.title {
            if (title == "下载") {
                onDownloadClickListener?()
                // 下载按钮点击后，响应了对应回调后恢复到非选中状态，并且选中之前选中的
                if let preSelectedPosition = preSelectedPosition {
                    (whiteBoardFuncViews.subviews[preSelectedPosition] as? WhiteBoardFuncView)?.isSelected = true
                    paintFuncViews.isHidden =  (whiteBoardFuncViews.subviews[preSelectedPosition] as? WhiteBoardFuncView)?.title != "画笔"
                    clearViews.isHidden =  (whiteBoardFuncViews.subviews[preSelectedPosition] as? WhiteBoardFuncView)?.title != "清除"
                }
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { timer in
                    (gesture.view as? WhiteBoardFuncView)?.isSelected = false
                }
            }
        }
    }
    
    @objc private func selectColor(_ gesture: UIGestureRecognizer) {
        for view in paintColorViews.subviews {
            guard let paintColorView = (view as? PaintColorView) else {
                continue
            }
            paintColorView.isSelected = (view == gesture.view)
            if (paintColorView.isSelected) {
                onPaintColorSelectedListener?(paintColorView.color)
                for view in paintWidthViews.subviews {
                    guard let paintWidthView = (view as? PaintWidthView) else {
                        continue
                    }
                    paintWidthView.selectedColor = paintColorView.color.cgColor
                }
            }
        }
    }
    
    @objc private func selectWidth(_ gesture: UIGestureRecognizer) {
        for view in paintWidthViews.subviews {
            guard let paintWidthView = (view as? PaintWidthView) else {
                continue
            }
            paintWidthView.isSelected = (view == gesture.view)
            if (paintWidthView.isSelected) {
                onPaintWidthSelectedListener?(paintWidthView.width)
            }
        }
    }
    
    @objc private func clearMark(_ gesture: UIGestureRecognizer) {
        if ((gesture.view as? UILabel)?.text == "清除所有标注") {
            onClearMarkClickListener?(.allMark)
        } else if ((gesture.view as? UILabel)?.text == "清除我的标注") {
            onClearMarkClickListener?(.myMark)
        } else if ((gesture.view as? UILabel)?.text == "清除其他人的标注") {
            onClearMarkClickListener?(.otherMark)
        }
    }
    
    func isUnfold() -> Bool? {
        // whiteBoardFuncViews.subviews.first 是 unfoldView
        guard let whiteBoardFuncView = whiteBoardFuncViews.subviews.first as? WhiteBoardFuncView else {
            return nil
        }
        guard let button = whiteBoardFuncView.subviews.first as? UIButton else {
            return nil
        }
        return !button.isSelected
    }
    
    func fold() {
        guard let whiteBoardFuncView = whiteBoardFuncViews.subviews.first as? WhiteBoardFuncView else {
            return
        }
        guard let button = whiteBoardFuncView.subviews.first as? UIButton else {
            return
        }
        if (button.isSelected) {
            // 被选中说明已经是收起状态，直接 return
            return
        }
        button.isSelected = !button.isSelected
        onUnfoldListener?(!button.isSelected)
        if (button.isSelected) {
            // 被选中说明是收起状态，需要移除其他功能控件
            for i in (1 ..< whiteBoardFuncViews.arrangedSubviews.count).reversed() {
                if let whiteBoardFuncView = whiteBoardFuncViews.arrangedSubviews[i] as? WhiteBoardFuncView {
                    if (whiteBoardFuncView.isSelected) {
                        preSelectedIndex = i
                    }
                }
                whiteBoardFuncViews.arrangedSubviews[i].removeFromSuperview()
            }
            paintFuncViews.isHidden = true
            clearViews.isHidden = true
            whiteBoardFuncViewsContainer.snp.updateConstraints { make in
                make.width.equalTo(45.screenAdapt())
            }
        }
    }
}

enum ClearMarkType {
    case allMark, myMark, otherMark
}
