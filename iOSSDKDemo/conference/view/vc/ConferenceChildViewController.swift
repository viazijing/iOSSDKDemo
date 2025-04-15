//
//  TestConferenceChildViewController.swift
//  fastsdk
//
//  Created by Mac on 2024/4/1.
//

import Foundation
import common
import rtc
import WebRTC

open class ConferenceChildViewController: UIViewController {
    var layoutBeans = [rtc.LayoutBean]()
    
    open override func viewDidLoad() {
        initView()
        setListener()
        initData()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        // 移除状态栏方向改变观察者
        NotificationCenter.default.removeObserver(self, name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    
    public func initView() {
        
    }
    
    public func setListener() {
        
    }
    
    public func initData() {
        
    }

    func rtcVideoFrame2UIImage(frame: RTCVideoFrame) -> UIImage? {
        guard let rtcCVPixelBuffer = frame.buffer as? RTCCVPixelBuffer else {
            return nil
        }
        let cvPixelBuffer = rtcCVPixelBuffer.pixelBuffer
        let ciImage = CIImage(cvPixelBuffer: cvPixelBuffer)
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        let image = UIImage(cgImage: cgImage)
        return image
    }

    open func onLayout(conferenceManager: ConferenceManager?, layoutBeans: [LayoutBean]) {}
    open func onParticipantsUpdate(conferenceManager: ConferenceManager?, participantBeans: [rtc.ParticipantBean]) {}
    open func onWhiteboardStart(url: String?) {}
    open func onWhiteboardStop() {}
    open func onWhiteboardAddLine(whiteboardAddLineBean: WhiteboardAddLineBean) {}
    open func onWhiteboardDeleteLine(whiteboardDeleteLineBean: WhiteboardDeleteLineBean) {}
    open func onWhiteboardClearLine() {}
    open func onWhiteboardMarkPermissionChanged(isWhiteboardAllowOtherMark: Bool, screenShare: Int?, fold: Bool = true) {}
    open func onWhiteboardBackgroundUpdate(url: String) {}
    open func onPictureInPictureUpdate(_ pictureInPicture: Bool) {}
    
    func resortLayoutBeans() {
        let presentationLayoutBeanIndex = layoutBeans.firstIndex { layoutBean in
            return layoutBean.ssrc == SdpUtil.PRESENTATION_VIDEO_RECEIVE_SSRC_ID
        }
        if let presentationLayoutBeanIndex = presentationLayoutBeanIndex {
            // 有演讲画面，固定在第一个的位置
            let presentationLayoutBean = layoutBeans.remove(at: presentationLayoutBeanIndex)
            layoutBeans.insert(presentationLayoutBean, at: 0)
        }
        let conferenceViewController = AppUtil.findViewController(viewControllerType: ConferenceDemoViewController.self)
        // 在没有其他人时，本地视频在第一个的位置
        if (layoutBeans.count == 1 && layoutBeans[0].participantUUID == conferenceViewController?.conferenceManager.getParticipantUUID()) {
            return
        }
        let myLayoutBeanIndex = layoutBeans.firstIndex{ layoutBean in
            return layoutBean.participantUUID == conferenceViewController?.conferenceManager.getParticipantUUID()
        }
        if (conferenceViewController?.conferenceManager.getParticipantUUID() == conferenceViewController?.conferenceManager.getSelectSeeUUID()) {
            // 锁定选看自己时，本地视频在第一个的位置
            if let myLayoutBeanIndex = myLayoutBeanIndex {
                let myLayoutBean = layoutBeans.remove(at: myLayoutBeanIndex)
                layoutBeans.insert(myLayoutBean, at: 0)
            }
        } else {
            // 否则本地视频在第二个的位置
            if let myLayoutBeanIndex = myLayoutBeanIndex {
                let myLayoutBean = layoutBeans.remove(at: myLayoutBeanIndex)
                layoutBeans.insert(myLayoutBean, at: 1)
            }
        }
    }
    
    func mergeUIImage(uiImage1: UIImage, uiImage2: UIImage) -> UIImage {
        let minWidth = min(uiImage1.size.width, uiImage2.size.width)
        let minHeight = min(uiImage1.size.height, uiImage2.size.height)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: minWidth, height: minHeight))
        let rect = CGRect(x: 0, y: 0, width: minWidth, height: minHeight)
        let result = renderer.image { context in
            uiImage1.draw(in: rect)
            uiImage2.draw(in: rect)
        }
//        // 压缩
//        if let data = result.jpegData(compressionQuality: 0.2), let compress = UIImage(data: data) {
//            result = compress
//        }
        return result
    }
}
