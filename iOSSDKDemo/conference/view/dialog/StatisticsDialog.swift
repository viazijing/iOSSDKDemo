//
//  StatisticsViewController.swift
//  zj-phone
//
//  Created by Mac on 2023/6/6.
//  会中统计信息对话框
//

import Foundation
import UIKit
import common
import SnapKit
import rtc

public class StatisticsDialog: UIViewController {
    private lazy var excelView = {
        let excelView = ExcelView(frame: CGRect.zero)
        excelView.dataSource = self
        excelView.delegate = self
        return excelView
    }()
    private lazy var titles = ["通道名称", "编码格式", "分辨率", "帧率", "码率", "抖动", "丢包率"]
    private var rtcStatisticsBeans: Array<RTCStatisticsBean> = []
    
    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        initView()
        setListener()
        initData()
    }
    
    private func initView() {
        view.backgroundColor = .clear
        // 内容布局
        let containerView = UIView()
        containerView.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.65)
        containerView.layer.cornerRadius = 4.screenAdapt()
        // 为内容布局设置点击事件，啥也不干，只是为了点击内部视图不关闭对话框
        containerView.addTarget(target: self, action: #selector(doNothing))
        view.addSubview(containerView)
        containerView.snp.makeConstraints({ make in
            make.height.equalTo(285.screenAdapt())
            make.left.equalToSuperview().offset(80.screenAdapt())
            make.right.equalToSuperview().offset(-80.screenAdapt())
            make.center.equalToSuperview()
        })
        let ivClose = UIImageView(image: UIImage(named: "conference_iv_close_src"))
        ivClose.contentMode = .scaleAspectFill
        ivClose.addTarget(target: self, action: #selector(close))
        containerView.addSubview(ivClose)
        ivClose.snp.makeConstraints { make in
            make.width.height.equalTo(30.screenAdapt())
            make.top.right.equalToSuperview()
        }
        containerView.addSubview(excelView)
        excelView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalTo(ivClose.snp.bottom)
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        // 为 view 设置手势监听，使点击内容布局外部能关闭对话框
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(close)))
    }
    
    private func setListener() {
        
    }
    
    private func initData() {
        let conferenceViewController = AppUtil.findViewController(viewControllerType: ConferenceDemoViewController.self)
        conferenceViewController?.conferenceManager.getStatistics(callback: { rtcStatisticsBeans in
            MyShowLogger.instance.showLogger.info("rtcStatisticsBeans--->\(rtcStatisticsBeans)")
            DispatchQueue.main.async {
                self.rtcStatisticsBeans = rtcStatisticsBeans
                self.rtcStatisticsBeans.sort { o1, o2 in
                    // 本地的在前
                    if (o1.userUUID == conferenceViewController?.conferenceManager.getParticipantUUID()
                        && o2.userUUID != conferenceViewController?.conferenceManager.getParticipantUUID()) {
                        return true
                    }
                    if (o1.userUUID != conferenceViewController?.conferenceManager.getParticipantUUID()
                        && o2.userUUID == conferenceViewController?.conferenceManager.getParticipantUUID()) {
                        return false
                    }
                    // 按照媒体类型排序，audio 在前，slide 次之，video 最后
                    if (o1.mediaType == .audio && o2.mediaType != .audio) {
                        return true
                    }
                    if (o1.mediaType != .audio && o2.mediaType == .audio) {
                        return false
                    }
                    if (o1.mediaType == .slide && o2.mediaType == .video) {
                        return true
                    }
                    if (o1.mediaType == .video && o2.mediaType == .slide) {
                        return false
                    }
                    // 本地视频，大流在前，小流在后
                    if o1.mediaType == .video && o2.mediaType == .video {
                        if o1.ssrc == SdpUtil.VIDEO_HD_SSRC_ID && o2.ssrc != SdpUtil.VIDEO_HD_SSRC_ID {
                            return true
                        }
                        if o1.ssrc != SdpUtil.VIDEO_HD_SSRC_ID && o2.ssrc == SdpUtil.VIDEO_HD_SSRC_ID {
                            return false
                        }
                    }
                    // 按照发送方向排序，发送在前，接收在后
                    if (o1.direction == .sent && o2.direction == .recv) {
                        return true
                    }
                    if (o1.direction == .recv && o2.direction == .sent) {
                        return false
                    }
                    // 按照 userNickname 是否为空排序：非空在前，空在后
                    if o1.userNickname != nil && o2.userNickname == nil {
                        return true
                    }
                    if o1.userNickname == nil && o2.userNickname != nil {
                        return false
                    }
                    if let userNickname1 = o1.userNickname, let userNickname2 = o2.userNickname {
                        return userNickname1 < userNickname2
                    }
                    return false
                }
                self.excelView.reloadData()
            }
        })
    }
    
    @objc private func doNothing() {
    }
    
    @objc private func close() {
        let conferenceViewController = AppUtil.findViewController(viewControllerType: ConferenceDemoViewController.self)
        conferenceViewController?.conferenceManager.stopGetStatistics()
        dismiss(animated: true)
    }
}

extension StatisticsDialog: ExcelViewDataSource {
    public func numberOfRows() -> Int {
        return rtcStatisticsBeans.count
    }
    
    public func numberOfColumns() -> Int {
        return titles.count
    }
    
    public func rowHeightOfTopTitle() -> CGFloat {
        return 40.screenAdapt()
    }
    
    public func columnWidthOfLeftTitle() -> CGFloat {
        return 74.screenAdapt()
    }
    
    public func rowHeightAt(row: Int) -> CGFloat {
        return 30.screenAdapt()
    }
    
    public func columnWidthAt(column: Int) -> CGFloat {
        return 74.screenAdapt()
    }
    
    public func rowNameAt(row: Int) -> String {
        let rtcStatisticsBean = rtcStatisticsBeans[row]
        return rtcStatisticsBean.userNickname ?? ""
    }
    
    public func columnNameAt(column: Int) -> String {
        return titles[column]
    }
    
    public func rowDataAt(row: Int) -> [String] {
        var data: Array<String> = []
        let rtcStatisticsBean = rtcStatisticsBeans[row]
        data.append(rtcStatisticsBean.channelName ?? "")
        data.append(rtcStatisticsBean.codec ?? "")
        if let width = rtcStatisticsBean.width, let height = rtcStatisticsBean.height, width != 0 && height != 0 {
            data.append("\(width)x\(height)")
        } else {
            data.append("-")
        }
        if let frameRate = rtcStatisticsBean.frameRate, frameRate != 0.0 {
            data.append("\(frameRate)")
        } else {
            data.append("-")
        }
        if let bitRate = rtcStatisticsBean.bitRate {
            data.append("\(bitRate)")
        } else {
            data.append("-")
        }
        if let jitter = rtcStatisticsBean.jitter {
            data.append("\(jitter)ms")
        } else {
            data.append("0ms")
        }
        data.append("\(String(format: "%.2f", rtcStatisticsBean.getLostPacketRate()))%")
        return data
    }
    
}

extension StatisticsDialog: ExcelViewDelegate {

}
