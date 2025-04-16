//
//  ConferenceDemoDefaultViewController.swift
//  iOSSDKDemo
//
//  Created by Mac on 2025/4/14.
//  会中显示平台布局的默认界面
//

import common
import Foundation
import permission
import rtc
import SnapKit
import UIKit
import net

class ConferenceDemoDefaultViewController: ConferenceChildViewController {
    private lazy var pvLandscape = {
        let view = UIView()
        return view
    }()
    private lazy var pv1Landscape = {
        let participantView = ParticipantView(participantInfoBottomHidden: true, participantInfoTopHidden: false)
        participantView.isHidden = true
        return participantView
    }()
    private lazy var pv2Landscape = {
        let participantView = ParticipantView()
        participantView.isHidden = true
        return participantView
    }()
    private lazy var pv3Landscape = {
        let participantView = ParticipantView()
        participantView.isHidden = true
        return participantView
    }()
    private lazy var pv4Landscape = {
        let participantView = ParticipantView()
        participantView.isHidden = true
        return participantView
    }()
    private lazy var pv5Landscape = {
        let participantView = ParticipantView()
        participantView.isHidden = true
        return participantView
    }()
    private lazy var pv6Landscape = {
        let participantView = ParticipantView()
        participantView.isHidden = true
        return participantView
    }()
    private lazy var pv7Landscape = {
        let participantView = ParticipantView()
        participantView.isHidden = true
        return participantView
    }()
    
    override func initView() {
        view.addSubview(pvLandscape)
        pvLandscape.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalToSuperview()
        }
        pvLandscape.addSubview(pv1Landscape)
        pvLandscape.addSubview(pv2Landscape)
        pvLandscape.addSubview(pv3Landscape)
        pvLandscape.addSubview(pv4Landscape)
        pvLandscape.addSubview(pv5Landscape)
        pvLandscape.addSubview(pv6Landscape)
        pvLandscape.addSubview(pv7Landscape)
        pv1Landscape.snp.makeConstraints { make in
            make.width.equalTo(pv1Landscape.snp.height).multipliedBy(16.0 / 9.0)
            make.height.equalToSuperview()
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        pv2Landscape.snp.makeConstraints { make in
            make.width.equalToSuperview().dividedBy(6)
            make.height.equalTo(pv2Landscape.snp.width).multipliedBy(9.0 / 16.0)
            make.left.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        pv3Landscape.snp.makeConstraints { make in
            make.width.equalToSuperview().dividedBy(6)
            make.height.equalTo(pv3Landscape.snp.width).multipliedBy(9.0 / 16.0)
            make.left.equalTo(pv2Landscape.snp.right)
            make.bottom.equalToSuperview()
        }
        pv4Landscape.snp.makeConstraints { make in
            make.width.equalToSuperview().dividedBy(6)
            make.height.equalTo(pv4Landscape.snp.width).multipliedBy(9.0 / 16.0)
            make.left.equalTo(pv3Landscape.snp.right)
            make.bottom.equalToSuperview()
        }
        pv5Landscape.snp.makeConstraints { make in
            make.width.equalToSuperview().dividedBy(6)
            make.height.equalTo(pv5Landscape.snp.width).multipliedBy(9.0 / 16.0)
            make.left.equalTo(pv4Landscape.snp.right)
            make.bottom.equalToSuperview()
        }
        pv6Landscape.snp.makeConstraints { make in
            make.width.equalToSuperview().dividedBy(6)
            make.height.equalTo(pv6Landscape.snp.width).multipliedBy(9.0 / 16.0)
            make.left.equalTo(pv5Landscape.snp.right)
            make.bottom.equalToSuperview()
        }
        pv7Landscape.snp.makeConstraints { make in
            make.width.equalToSuperview().dividedBy(6)
            make.height.equalTo(pv7Landscape.snp.width).multipliedBy(9.0 / 16.0)
            make.left.equalTo(pv6Landscape.snp.right)
            make.bottom.equalToSuperview()
        }
    }
    
    override func setListener() {
        let onDoubleClickListener: ((String?) -> Void) = { uuid in
            guard let uuid = uuid else {
                return
            }
            let conferenceViewController = AppUtil.findViewController(viewControllerType: ConferenceDemoViewController.self)
//            conferenceViewController?.selectSee(uuid: uuid)
        }
        pv1Landscape.onDoubleClickListener = onDoubleClickListener
        pv2Landscape.onDoubleClickListener = onDoubleClickListener
        pv3Landscape.onDoubleClickListener = onDoubleClickListener
        pv4Landscape.onDoubleClickListener = onDoubleClickListener
        pv5Landscape.onDoubleClickListener = onDoubleClickListener
        pv6Landscape.onDoubleClickListener = onDoubleClickListener
        pv7Landscape.onDoubleClickListener = onDoubleClickListener
    }
    
    override func initData() {
    }
    
    @objc private func viewDragged(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        guard let movedView = gesture.view else{
            return
        }
        movedView.transform = movedView.transform.translatedBy(x: translation.x, y: translation.y)
        gesture.setTranslation(CGPoint.zero, in: view)
    }
    
    override func onLayout(conferenceManager: ConferenceManager?, layoutBeans: [LayoutBean]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.layoutBeans.removeAll()
            let presentationLayoutBean = layoutBeans.first { layoutBean in
                return layoutBean.ssrc == SdpUtil.PRESENTATION_VIDEO_SEND_SSRC_ID
                || layoutBean.ssrc == SdpUtil.PRESENTATION_VIDEO_RECEIVE_SSRC_ID
            }
            if (presentationLayoutBean == nil) {
                // 没有演讲流的时候，才会显示自己
                if let myLayoutBean = conferenceManager?.getMyLayoutBean() {
                    self.layoutBeans.append(myLayoutBean)
                }
            }
            self.layoutBeans.append(contentsOf: layoutBeans)
            updateParticipantViews()
        }
    }
    
    override func onParticipantsUpdate(conferenceManager: ConferenceManager?, participantBeans: [rtc.ParticipantBean]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if (!self.isViewLoaded) {
                return
            }
            participantBeans.forEach { participantBean in
                if (self.pv1Landscape.getParticipantBean()?.uuid == participantBean.uuid) {
                    self.pv1Landscape.setParticipantBean(participantBean)
                } else if (self.pv2Landscape.getParticipantBean()?.uuid == participantBean.uuid) {
                    self.pv2Landscape.setParticipantBean(participantBean)
                } else if (self.pv3Landscape.getParticipantBean()?.uuid == participantBean.uuid) {
                    self.pv3Landscape.setParticipantBean(participantBean)
                } else if (self.pv4Landscape.getParticipantBean()?.uuid == participantBean.uuid) {
                    self.pv4Landscape.setParticipantBean(participantBean)
                } else if (self.pv5Landscape.getParticipantBean()?.uuid == participantBean.uuid) {
                    self.pv5Landscape.setParticipantBean(participantBean)
                } else if (self.pv6Landscape.getParticipantBean()?.uuid == participantBean.uuid) {
                    self.pv6Landscape.setParticipantBean(participantBean)
                } else if (self.pv7Landscape.getParticipantBean()?.uuid == participantBean.uuid) {
                    self.pv7Landscape.setParticipantBean(participantBean)
                }
            }
        }
    }
    
    override func onPictureInPictureUpdate(_ pictureInPicture: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            updateParticipantViews()
        }
    }
    
    @objc private func unselectSee() {
//        let conferenceViewController = AppUtil.findViewController(viewControllerType: ConferenceViewController.self)
//        if let selectSeeUUID = conferenceViewController?.conferenceManager.getSelectSeeUUID() {
//            conferenceViewController?.unselectSee(uuid: selectSeeUUID)
//        }
    }
    
    private func updateParticipantViews() {
        if (layoutBeans.count == 0) {
            return
        }
        resortLayoutBeans()
        updateParticipantViewsLandscape()
    }
    
    private func updateParticipantViewsLandscape() {
        pvLandscape.isHidden = true
        pv1Landscape.isHidden = true
        pv2Landscape.isHidden = true
        pv3Landscape.isHidden = true
        pv4Landscape.isHidden = true
        pv5Landscape.isHidden = true
        pv6Landscape.isHidden = true
        pv7Landscape.isHidden = true
        pv1Landscape.setMirror(false)
        pv2Landscape.setMirror(false)
        pvLandscape.isHidden = false
        let conferenceViewController = AppUtil.findViewController(viewControllerType: ConferenceDemoViewController.self)
        let conferenceManager = conferenceViewController?.conferenceManager
        if (layoutBeans.count >= 1) {
            pv1Landscape.isHidden = false
            pv1Landscape.setVideoTrack(conferenceManager?.getRTCManager()?.getVideoTrack(trackId: layoutBeans[0].mediaStremTrackId))
            pv1Landscape.setParticipantBean(conferenceManager?.getParticipantBean(uuid: layoutBeans[0].participantUUID))
            if (layoutBeans[0].participantUUID == conferenceManager?.getParticipantUUID()) {
                let front = conferenceManager?.getRTCManager()?.isFrontFacing() ?? true
                let cameraEnabled = conferenceManager?.getRTCManager()?.isCameraEnabled() ?? true
                let mirror = true
                pv1Landscape.setMirror(front && cameraEnabled && mirror)
            }
        }
        if (conferenceViewController?.isPictureInPicture() == false) {
            // 横屏时，小画面都属于画中画，如果关闭了画中画模式，则除了第一个大画面显示，后面的小画面都不显示了，直接 return
            return
        }
        if (layoutBeans.count >= 2) {
            pv2Landscape.isHidden = false
            pv2Landscape.setVideoTrack(conferenceManager?.getRTCManager()?.getVideoTrack(trackId: layoutBeans[1].mediaStremTrackId))
            pv2Landscape.setParticipantBean(conferenceManager?.getParticipantBean(uuid: layoutBeans[1].participantUUID))
            if (layoutBeans[1].participantUUID == conferenceManager?.getParticipantUUID()) {
                let front = conferenceManager?.getRTCManager()?.isFrontFacing() ?? true
                let cameraEnabled = conferenceManager?.getRTCManager()?.isCameraEnabled() ?? true
                let mirror = true
                pv2Landscape.setMirror(front && cameraEnabled && mirror)
            }
        }
        if (layoutBeans.count >= 3) {
            pv3Landscape.isHidden = false
            pv3Landscape.setVideoTrack(conferenceManager?.getRTCManager()?.getVideoTrack(trackId: layoutBeans[2].mediaStremTrackId))
            pv3Landscape.setParticipantBean(conferenceManager?.getParticipantBean(uuid: layoutBeans[2].participantUUID))
        }
        if (layoutBeans.count >= 4) {
            pv4Landscape.isHidden = false
            pv4Landscape.setVideoTrack(conferenceManager?.getRTCManager()?.getVideoTrack(trackId: layoutBeans[3].mediaStremTrackId))
            pv4Landscape.setParticipantBean(conferenceManager?.getParticipantBean(uuid: layoutBeans[3].participantUUID))
        }
        if (layoutBeans.count >= 5) {
            pv5Landscape.isHidden = false
            pv5Landscape.setVideoTrack(conferenceManager?.getRTCManager()?.getVideoTrack(trackId: layoutBeans[4].mediaStremTrackId))
            pv5Landscape.setParticipantBean(conferenceManager?.getParticipantBean(uuid: layoutBeans[4].participantUUID))
        }
        if (layoutBeans.count >= 6) {
            pv6Landscape.isHidden = false
            pv6Landscape.setVideoTrack(conferenceManager?.getRTCManager()?.getVideoTrack(trackId: layoutBeans[5].mediaStremTrackId))
            pv6Landscape.setParticipantBean(conferenceManager?.getParticipantBean(uuid: layoutBeans[5].participantUUID))
        }
        if (layoutBeans.count >= 7) {
            pv7Landscape.isHidden = false
            pv7Landscape.setVideoTrack(conferenceManager?.getRTCManager()?.getVideoTrack(trackId: layoutBeans[6].mediaStremTrackId))
            pv7Landscape.setParticipantBean(conferenceManager?.getParticipantBean(uuid: layoutBeans[6].participantUUID))
        }
    }
    
    func showLockedTip() {
//        DispatchQueue.main.async { [weak self] in
//            guard let self = self else { return }
//            self.lockedTip.isHidden = false
//        }
    }
    
    func hideLockedTip() {
//        DispatchQueue.main.async { [weak self] in
//            guard let self = self else { return }
//            self.lockedTip.isHidden = true
//        }
    }
}
