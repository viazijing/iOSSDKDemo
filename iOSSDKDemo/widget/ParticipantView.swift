//
//  ParticipantView.swift
//  fastsdk
//
//  Created by Mac on 2024/5/23.
//

import UIKit
import WebRTC
import rtc

class MyVideoView: RTCEAGLVideoView {
    weak var curRTCVideoFrame: RTCVideoFrame?
    
    override func renderFrame(_ frame: RTCVideoFrame?) {
        super.renderFrame(frame)
//        MyShowLogger.instance.showLogger.debug("renderFrame--->\(frame)")
        curRTCVideoFrame = frame
    }
}

class ParticipantView: UIView {
    private let videoView = MyVideoView()
    private lazy var ivMuteBottom = {
        let imageView = UIImageView(image: UIImage(named: "conference_iv_mute_src"))
        imageView.isHidden = true
        return imageView
    }()
    private lazy var lbNameBottom = {
        let label = UILabel()
        label.textColor = .text_color_ffffffff
        label.font = UIFont.systemFont(ofSize: 14.screenAdapt())
        return label
    }()
    private lazy var participantInfoViewBottom = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.6)
        view.layer.cornerRadius = 2.screenAdapt()
        view.addSubview(ivMuteBottom)
        ivMuteBottom.snp.makeConstraints { make in
            make.width.height.equalTo(15.screenAdapt())
            make.left.equalToSuperview().offset(5.screenAdapt())
            make.centerY.equalToSuperview()
        }
        view.addSubview(lbNameBottom)
        lbNameBottom.snp.makeConstraints { make in
            if (ivMuteBottom.isHidden) {
                make.left.equalToSuperview().offset(5.screenAdapt())
            } else {
                make.left.equalToSuperview().offset(5.screenAdapt() + 15.screenAdapt() + 5.screenAdapt())
            }
            make.right.equalToSuperview().offset(-5.screenAdapt())
            make.centerY.equalToSuperview()
        }
        return view
    }()
    private lazy var ivMuteTop = {
        let imageView = UIImageView(image: UIImage(named: "conference_iv_mute_src"))
        imageView.isHidden = true
        return imageView
    }()
    private lazy var lbNameTop = {
        let label = UILabel()
        label.textColor = .text_color_ffffffff
        label.font = UIFont.systemFont(ofSize: 14.screenAdapt())
        return label
    }()
    private lazy var participantInfoViewTop = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.6)
        view.layer.cornerRadius = 2.screenAdapt()
        view.addSubview(ivMuteTop)
        ivMuteTop.snp.makeConstraints { make in
            make.width.height.equalTo(15.screenAdapt())
            make.left.equalToSuperview().offset(5.screenAdapt())
            make.centerY.equalToSuperview()
        }
        view.addSubview(lbNameTop)
        lbNameTop.snp.makeConstraints { make in
            if (ivMuteTop.isHidden) {
                make.left.equalToSuperview().offset(5.screenAdapt())
            } else {
                make.left.equalToSuperview().offset(5.screenAdapt() + 15.screenAdapt() + 5.screenAdapt())
            }
            make.right.equalToSuperview().offset(-5.screenAdapt())
            make.centerY.equalToSuperview()
        }
        return view
    }()
    private var participantBean: rtc.ParticipantBean?
    private weak var videoTrack: RTCVideoTrack? = nil
    
    var onDoubleClickListener: ((String?) -> Void) = { uuid in
        
    }
    
    init(participantInfoBottomHidden: Bool = false, participantInfoTopHidden: Bool = true) {
        super.init(frame: CGRect.zero)
        backgroundColor = .background_color_ff131313
//        backgroundColor = UIColor(red: 17/255, green: 41/255, blue: 78/255, alpha: 1.0)
        participantInfoViewBottom.isHidden = participantInfoBottomHidden
        participantInfoViewTop.isHidden = participantInfoTopHidden
        // 双击
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onDoubleClick))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGestureRecognizer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
//        showIvLoadingTimer?.invalidate()
//        showIvLoadingTimer = nil
        // 释放资源，防止内存泄漏
        participantBean = nil
        videoTrack?.remove(videoView)
        videoTrack = nil
    }

    
    override var bounds: CGRect{
        didSet {
            videoView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        }
    }
    
    @objc private func onDoubleClick() {
        onDoubleClickListener(participantBean?.uuid)
    }
    
    func getParticipantBean() -> rtc.ParticipantBean? {
        return participantBean
    }
    
    func setParticipantBean(_ participantBean: rtc.ParticipantBean?) {
        guard let participantBean = participantBean else {
            lbNameBottom.text = ""
            ivMuteBottom.isHidden = true
            lbNameTop.text = ""
            ivMuteTop.isHidden = true
            lbNameBottom.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(0)
                make.right.equalToSuperview().offset(0.screenAdapt())
            }
            lbNameTop.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(0)
                make.right.equalToSuperview().offset(0.screenAdapt())
            }
            return
        }
//        MyShowLogger.instance.showLogger.debug("participantBean--->\(participantBean), videoView.superview--->\(videoView.superview)")
        if (participantInfoViewBottom.superview == nil) {
            addSubview(participantInfoViewBottom)
            participantInfoViewBottom.snp.makeConstraints { make in
                make.height.equalTo(20.screenAdapt())
                make.left.equalToSuperview().offset(2.screenAdapt())
                make.right.lessThanOrEqualToSuperview().offset(-2.screenAdapt())
                make.bottom.equalToSuperview().offset(-2.screenAdapt())
            }
        }
        if (participantInfoViewTop.superview == nil) {
            addSubview(participantInfoViewTop)
            participantInfoViewTop.snp.makeConstraints { make in
                make.height.equalTo(20.screenAdapt())
                make.left.equalToSuperview().offset(2.screenAdapt())
                make.right.lessThanOrEqualToSuperview().offset(-2.screenAdapt())
                make.top.equalToSuperview().offset(2.screenAdapt())
            }
        }
        lbNameBottom.text = participantBean.getShowName()
        if (participantBean.isServerMutedOrClientMuted()) {
            ivMuteBottom.isHidden = false
        } else {
            ivMuteBottom.isHidden = true
        }
        lbNameBottom.snp.remakeConstraints { make in
            if (ivMuteBottom.isHidden) {
                make.left.equalToSuperview().offset(5.screenAdapt())
            } else {
                make.left.equalToSuperview().offset(5.screenAdapt() + 15.screenAdapt() + 5.screenAdapt())
            }
            make.right.equalToSuperview().offset(-5.screenAdapt())
            make.centerY.equalToSuperview()
        }
        lbNameTop.text = participantBean.getShowName()
        if (participantBean.isServerMutedOrClientMuted()) {
            ivMuteTop.isHidden = false
        } else {
            ivMuteTop.isHidden = true
        }
        lbNameTop.snp.remakeConstraints { make in
            if (ivMuteTop.isHidden) {
                make.left.equalToSuperview().offset(5.screenAdapt())
            } else {
                make.left.equalToSuperview().offset(5.screenAdapt() + 15.screenAdapt() + 5.screenAdapt())
            }
            make.right.equalToSuperview().offset(-5.screenAdapt())
            make.centerY.equalToSuperview()
        }
        self.participantBean = participantBean
    }
    
    func setMirror(_ mirror: Bool?) {
        videoView.transform = mirror == true ? CGAffineTransformMakeScale(-1.0, 1.0) : CGAffineTransformIdentity
    }
    
    func setVideoTrack(_ videoTrack: RTCVideoTrack?) {
        if (videoView.superview == nil) {
            let videoViewContainer = UIView()
            videoViewContainer.backgroundColor = UIColor(red: 17/255, green: 41/255, blue: 78/255, alpha: 1.0)
            addSubview(videoViewContainer)
            videoViewContainer.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(1.screenAdapt())
                make.top.equalToSuperview().offset(1.screenAdapt())
                make.right.equalToSuperview().offset(-1.screenAdapt())
                make.bottom.equalToSuperview().offset(-1.screenAdapt())
            }
            videoView.delegate = self
            videoView.backgroundColor = UIColor(red: 17/255, green: 41/255, blue: 78/255, alpha: 1.0)
            videoViewContainer.addSubview(videoView)
            videoView.snp.makeConstraints { make in
                make.width.equalToSuperview()
                make.height.equalToSuperview()
                make.center.equalToSuperview()
            }
        }
        self.videoTrack?.remove(videoView)
        videoTrack?.add(videoView)
        self.videoTrack = videoTrack
    }
    
    func getCurrentVideoFrame() -> RTCVideoFrame? {
        return videoView.curRTCVideoFrame
    }
}

extension ParticipantView: RTCVideoViewDelegate {
    
    func videoView(_ rtcVideoRender: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
        if (size.width > size.height) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.videoView.snp.remakeConstraints { make in
                    make.width.equalToSuperview()
                    //                    make.height.equalTo(self.videoView.snp.width).multipliedBy(size.height / size.width)
                    make.height.equalTo(self.videoView.snp.width).multipliedBy(9.0 / 16.0)
                    make.center.equalToSuperview()
                }
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.videoView.snp.remakeConstraints { make in
                    make.height.equalToSuperview()
                    //                    make.width.equalTo(self.videoView.snp.height).multipliedBy(size.width / size.height)
                    make.width.equalTo(self.videoView.snp.height).multipliedBy(9.0 / 16.0)
                    make.center.equalToSuperview()
                }
            }
        }
    }
}
