//
//  VerticalListDialog.swift
//  iOSSDKDemo
//
//  Created by Mac on 2024/10/12.
//  共享图片时，展示单张图片的界面
//

import Foundation
import UIKit

public class VerticalListDialog: UIViewController {
    
    private lazy var backgroundView: UIView = UIView()
    private let negativeButtonText: String
    private let negativeButtonTextColor: UIColor
    private let negativeButtonHandler: (() -> Void)?
    private let items: Array<(text: String, textColor: UIColor?, handler: ((UIAlertAction) -> Void)?)>
    init(negativeButtonText: String = "取消", negativeButtonTextColor: UIColor = .systemRed, negativeButtonHandler: (() -> Void)? = nil
         , items: Array<(text: String, textColor: UIColor?, handler: ((UIAlertAction) -> Void)?)>) {
        self.negativeButtonText = negativeButtonText
        self.negativeButtonTextColor = negativeButtonTextColor
        self.negativeButtonHandler = negativeButtonHandler
        self.items = items
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        // 为 view 设置手势监听，使点击内容布局外部能关闭对话框
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(close)))
        // 取消
        let btnCancel = UIButton()
        btnCancel.backgroundColor = .white
        btnCancel.layer.cornerRadius = 10.screenAdapt()
        btnCancel.setTitle(negativeButtonText, for: .normal)
        btnCancel.titleLabel?.font = .systemFont(ofSize: 14.screenAdapt())
        btnCancel.setTitleColor(negativeButtonTextColor, for: .normal)
        btnCancel.addTarget(self, action: #selector(close))
        view.addSubview(btnCancel)
        btnCancel.snp.makeConstraints { make in
            make.width.equalTo(300.screenAdapt())
            make.height.equalTo(50.screenAdapt())
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-10.screenAdapt())
        }
        let listView = UIView()
        listView.backgroundColor = .white
        listView.layer.cornerRadius = 10.screenAdapt()
        view.addSubview(listView)
        listView.snp.makeConstraints { make in
            make.width.equalTo(300.screenAdapt())
            make.height.equalTo(50.screenAdapt() * CGFloat(items.count))
            make.centerX.equalToSuperview()
            make.bottom.equalTo(btnCancel.snp.top).offset(-10.screenAdapt())
        }
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        listView.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        let scrollContentView = UIView()
        scrollView.addSubview(scrollContentView)
        scrollContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            // 这里必须得给宽或高设置优先级，哪个方向要滚动，优先级就必须低
            make.width.equalTo(scrollView.snp.width)
            make.height.equalTo(listView.snp.height).priority(.low)
        }
        var preItem: UIView?
        var height: CGFloat = 0
        for (index, item) in items.enumerated() {
            let button = UIButton()
            button.setTitle("\(item.text)", for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 14.screenAdapt())
            let textColor = item.textColor ?? .systemBlue
            button.setTitleColor(textColor, for: .normal)
            button.tag = index  // 用于区分按钮
            // 添加按钮的点击事件
            button.addTarget(self, action: #selector(itemTapped(_:)), for: .touchUpInside)
            scrollContentView.addSubview(button)
            button.snp.makeConstraints { make in
                make.height.equalTo(50.screenAdapt())
                make.left.right.equalToSuperview()
                if let preItem = preItem {
                    make.top.equalTo(preItem.snp.bottom)
                } else {
                    make.top.equalToSuperview()
                }
            }
            if (index != items.count - 1) {
                let dividerLine = DividerLine()
                scrollContentView.addSubview(dividerLine)
                dividerLine.snp.makeConstraints { make in
                    make.height.equalTo(1.screenAdapt())
                    make.left.right.equalToSuperview()
                    make.bottom.equalTo(button.snp.bottom)
                }
            }
            preItem = button
            height += 50.screenAdapt()
        }
        scrollContentView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
            // 这里必须得给宽或高设置优先级，哪个方向要滚动，优先级就必须低
            make.width.equalTo(scrollView.snp.width)
            make.height.equalTo(height).priority(.low)
        }
    }
    
    @objc private func close() {
        backgroundView.removeFromSuperview()
        dismiss(animated: false)
    }
    
    @objc private func cancel() {
        close()
        negativeButtonHandler?()
    }
    
    @objc private func itemTapped(_ sender: UIButton) {
        close()
        // 获取按钮对应的 handler，并调用
        let index = sender.tag
        if let handler = items[index].handler {
            handler(UIAlertAction())
        }
    }
    
    public func show(viewController: UIViewController) {
        // InputPwdViewController 为了动画弹出，所以不设置背景，即透明背景，为了背景变暗，在弹出该对话框的界面添加一个控件达到背景变暗的效果
        backgroundView.frame = viewController.view.frame
        backgroundView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.16)
        viewController.view.addSubview(backgroundView)
        viewController.present(self, animated: false, completion: nil)
    }
}
