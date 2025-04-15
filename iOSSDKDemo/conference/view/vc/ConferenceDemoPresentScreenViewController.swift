//
//  ConferenceScreenShareViewController.swift
//  iOSSDKDemo
//
//  Created by Mac on 2023/6/9.
//  会中自己分享屏幕时的界面
//

import UIKit
import common
import SnapKit

class ConferenceDemoPresentScreenViewController: ConferenceChildViewController {
    
    override func initView() {
        view.backgroundColor = UIColor(red: 21/255, green: 30/255, blue: 63/255, alpha: 1)
        let container = UIView()
        view.addSubview(container)
        container.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        let ivScreenSharing = UIImageView()
        ivScreenSharing.contentMode = .scaleAspectFit
        ivScreenSharing.image = UIImage(named: "conference_iv_screen_sharing_src")
        container.addSubview(ivScreenSharing)
        ivScreenSharing.snp.makeConstraints { make in
            make.width.height.equalTo(100.screenAdapt())
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        let lbScreenSharing = UILabel()
        lbScreenSharing.text = "当前正在共享手机屏幕"
        lbScreenSharing.textColor = .text_color_ffffffff
        lbScreenSharing.font = .systemFont(ofSize: 16.screenAdapt())
        lbScreenSharing.sizeToFit()
        container.addSubview(lbScreenSharing)
        lbScreenSharing.snp.makeConstraints { make in
            make.top.equalTo(ivScreenSharing.snp.bottom).offset(5.screenAdapt())
            make.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
        }
    }
    
    override func setListener() {
    }
    
    override func initData() {
        
    }
}
