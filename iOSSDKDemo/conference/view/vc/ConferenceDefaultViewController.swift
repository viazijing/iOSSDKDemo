//
//  ConferenceDefaultViewController.swift
//  fastsdk
//
//  Created by Mac on 2024/4/1.
//

import common
import Foundation
import permission
import rtc
import SnapKit
import UIKit
import net

class ConferenceDefaultViewController: ConferenceChildViewController {
    private lazy var pvPrimary = {
        let participantView = ParticipantView()
        participantView.isHidden = true
        return participantView
    }()
    private lazy var pvSecondary = {
        let participantView = ParticipantView()
        participantView.isHidden = true
        return participantView
    }()
    private lazy var pvPortrait = {
        let view = UIView()
        return view
    }()
    private lazy var pv1 = {
        let participantView = ParticipantView()
        participantView.isHidden = true
        return participantView
    }()
    private lazy var pv2 = {
        let participantView = ParticipantView()
        participantView.isHidden = true
        return participantView
    }()
    private lazy var pv3 = {
        let participantView = ParticipantView()
        participantView.isHidden = true
        return participantView
    }()
    private lazy var pv4 = {
        let participantView = ParticipantView()
        participantView.isHidden = true
        return participantView
    }()
    private lazy var pv5 = {
        let participantView = ParticipantView()
        participantView.isHidden = true
        return participantView
    }()
    private lazy var pv6 = {
        let participantView = ParticipantView()
        participantView.isHidden = true
        return participantView
    }()
    private lazy var pv7 = {
        let participantView = ParticipantView()
        participantView.isHidden = true
        return participantView
    }()
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
    private lazy var ivPresentImage = {
       let imageView = UIImageView()
        imageView.isHidden = true
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    private lazy var drawingBoardView = {
        let drawingBoardView = DrawingBoardView()
        drawingBoardView.onAddLineListener = {  [weak self] pathInfo in
            guard let self = self else { return }
            let width = ScreenUtil.isPortrait() ? drawingBoardView.frame.height : drawingBoardView.frame.width
            let height = ScreenUtil.isPortrait() ? drawingBoardView.frame.width : drawingBoardView.frame.height
            guard let lineWidth = pathInfo.width, let lineColor = pathInfo.color, let path = pathInfo.path else {
                return
            }
            let conferenceManager = (self.parent?.parent as? ConferenceViewController)?.conferenceManager
            conferenceManager?.getPresentationManager()?.addLine(width: Int(width),
                                                                 height: Int(height),
                                                                 lineWidth: lineWidth,
                                                                 lineColor: lineColor,
                                                                 path: path,
                                                                 onSuccess: { id in
                pathInfo.id = id
            }, onFailure: { error in
            })
        }
        drawingBoardView.onRemoveLineListener = {  [weak self] pathInfo in
            guard let self = self else { return }
            guard let id = pathInfo.id else {
                return
            }
            let conferenceManager = (self.parent?.parent as? ConferenceViewController)?.conferenceManager
            conferenceManager?.getPresentationManager()?.removeLine(id: id, onSuccess: {
            }, onFailure: { error in
            })
        }
        return drawingBoardView
    }()
    private lazy var whiteBoardFuncBar = {
        let whiteBoardFuncBar = WhiteBoardFuncBar(hideClearAllAndClearOther: true)
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(viewDragged(_:)))
        whiteBoardFuncBar.addGestureRecognizer(panGestureRecognizer)
        whiteBoardFuncBar.onUnfoldListener = {  [weak self] unfold in
            guard let self = self else { return }
            // 白板功能栏展开时，白板控件才可以进行交互，进行绘制
            self.drawingBoardView.isUserInteractionEnabled = unfold
        }
        whiteBoardFuncBar.onPaintColorSelectedListener = { [weak self] color in
            guard let self = self else { return }
            self.drawingBoardView.paintColor = color
        }
        whiteBoardFuncBar.onPaintWidthSelectedListener = { [weak self] width in
            guard let self = self else { return }
            self.drawingBoardView.paintWidth = width
        }
        whiteBoardFuncBar.onEraserModeClickListener = { [weak self] eraserMode in
            guard let self = self else { return }
            self.drawingBoardView.eraseMode = eraserMode
        }
        whiteBoardFuncBar.onClearMarkClickListener = { [weak self] clearMarkType in
            guard let self = self else { return }
            let conferenceManager = (self.parent?.parent as? ConferenceViewController)?.conferenceManager
            switch (clearMarkType) {
            case .allMark:
                conferenceManager?.getPresentationManager()?.clearLine(onSuccess: {
                }, onFailure: { error in
                })
                self.drawingBoardView.clearAllLine()
                break
            case .myMark:
                for pathInfo in self.drawingBoardView.getPaths() {
                    if let id = pathInfo.id, pathInfo.lineType == .drawn {
                        conferenceManager?.getPresentationManager()?.removeLine(id: id, onSuccess: {
                        }, onFailure: { error in
                        })
                    }
                }
                self.drawingBoardView.clearDrawnLines()
                break
            case .otherMark:
                for pathInfo in self.drawingBoardView.getPaths() {
                    if let id = pathInfo.id, pathInfo.lineType == .added {
                        conferenceManager?.getPresentationManager()?.removeLine(id: id, onSuccess: {
                        }, onFailure: { error in
                        })
                    }
                }
                self.drawingBoardView.clearAddedLines()
                break
            }
        }
        whiteBoardFuncBar.onDownloadClickListener = { [weak self] in
            PhotoLibraryPermissionChecker().request { [weak self] in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    guard let rtcVideoFrame = self.pv1Landscape.getCurrentVideoFrame() else {
                        Toast.makeText(text: "保存失败").show()
                        return
                    }
                    guard let uiImage = self.rtcVideoFrame2UIImage(frame: rtcVideoFrame) else {
                        Toast.makeText(text: "保存失败").show()
                        return
                    }
                    let screenshot = self.drawingBoardView.screenshot()
                    // 合并保存
                    let result = self.mergeUIImage(uiImage1: uiImage, uiImage2: screenshot)
                    FileUtil.writeImg2PhotoLibrary(image: result) {
                        DispatchQueue.main.async {
                            Toast.makeText(text: "已保存到系统相册").show()
                        }
                    } failure: { error in
                        DispatchQueue.main.async {
                            Toast.makeText(text: "保存失败").show()
                        }
                    }
                }
            } failure: { error in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    let message = "请在iPhone的\"设置-隐私-照片\"选项中，允许\(AppUtil.getAppName() ?? "")访问你的手机相册"
                    CommonDialog(title: nil, message: message, negativeButtonText: "暂不", positiveButtonText: "去设置", positiveButtonHandler: { UIAlertAction in
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url, options: [:])
                        }
                    }).show(uiViewController: self)
                }
            }
        }
        return whiteBoardFuncBar
    }()
    private lazy var btnUnlock = {
        let button = UIButton()
        button.backgroundColor = .text_color_ff0e8cee
        button.layer.cornerRadius = 2.screenAdapt()
        button.setTitle("解锁", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12.screenAdapt())
        button.setTitleColor(.text_color_ff000000, for: .normal)
        button.addTarget(self, action: #selector(unselectSee))
        return button
    }()
    private lazy var lockedTip = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 0.8)
        view.layer.cornerRadius = 2.screenAdapt()
        let label = UILabel()
        label.text = "主屏已锁定"
        label.font = .systemFont(ofSize: 13.screenAdapt())
        label.textColor = .text_color_ff000000
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10.screenAdapt())
            make.centerY.equalToSuperview()
        }
        view.addSubview(btnUnlock)
        btnUnlock.snp.makeConstraints { make in
            make.width.equalTo(40.screenAdapt())
            make.height.equalTo(20.screenAdapt())
            make.right.equalToSuperview().offset(-6.screenAdapt())
            make.centerY.equalToSuperview()
        }
        view.isHidden = true
        return view
    }()
    private lazy var lbLecturer = {
        let label = UILabel()
        label.text = ""
        label.font = .systemFont(ofSize: 12.screenAdapt())
        label.textColor = .text_color_ff000000
        return label
    }()
    private lazy var viewLecturerBackground = {
        let view = UIView()
        view.layer.backgroundColor = UIColor(red: 12/255, green: 26/255, blue: 44/255, alpha: 0.67).cgColor
        view.layer.cornerRadius = 2.screenAdapt()
        view.addSubview(lbLecturer)
        lbLecturer.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(2.screenAdapt())
            make.top.equalToSuperview().offset(2.screenAdapt())
            make.right.equalToSuperview().offset(-2.screenAdapt())
            make.bottom.equalToSuperview().offset(-2.screenAdapt())
        }
        return view
    }()
    
    override func initView() {
        view.addSubview(pvPrimary)
        pvPrimary.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(pvPrimary.snp.width).multipliedBy(16.0 / 9.0)
            make.center.equalToSuperview()
        }
        view.addSubview(pvSecondary)
        pvSecondary.snp.makeConstraints { make in
            make.width.equalTo(90.screenAdapt())
            make.height.equalTo(160.screenAdapt())
            make.top.equalToSuperview().offset(70.screenAdapt() + StatusBarUtil.getHeight())
            make.right.equalToSuperview().offset(-15.screenAdapt())
        }
        view.addSubview(pvPortrait)
        pvPortrait.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(ScreenUtil.getScreenWidth() * 9.0 / 16.0 * 2.5)
            make.center.equalToSuperview()
        }
        pvPortrait.addSubview(pv1)
        pvPortrait.addSubview(pv2)
        pvPortrait.addSubview(pv3)
        pvPortrait.addSubview(pv4)
        pvPortrait.addSubview(pv5)
        pvPortrait.addSubview(pv6)
        pvPortrait.addSubview(pv7)
        pv1.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(pv1.snp.width).multipliedBy(9.0 / 16.0)
            make.left.equalToSuperview()
            make.top.equalToSuperview()
        }
        pv2.snp.makeConstraints { make in
            make.width.equalToSuperview().dividedBy(2)
            make.height.equalTo(pv2.snp.width).multipliedBy(9.0 / 16.0)
            make.left.equalToSuperview()
            make.top.equalTo(pv1.snp.bottom)
        }
        pv3.snp.makeConstraints { make in
            make.width.equalToSuperview().dividedBy(2)
            make.height.equalTo(pv3.snp.width).multipliedBy(9.0 / 16.0)
            make.left.equalTo(pv2.snp.right)
            make.top.equalTo(pv2.snp.top)
        }
        pv4.snp.makeConstraints { make in
            make.width.equalToSuperview().dividedBy(2)
            make.height.equalTo(pv4.snp.width).multipliedBy(9.0 / 16.0)
            make.left.equalToSuperview()
            make.top.equalTo(pv2.snp.bottom)
        }
        pv5.snp.makeConstraints { make in
            make.width.equalToSuperview().dividedBy(2)
            make.height.equalTo(pv4.snp.width).multipliedBy(9.0 / 16.0)
            make.left.equalTo(pv4.snp.right)
            make.top.equalTo(pv4.snp.top)
        }
        pv6.snp.makeConstraints { make in
            make.width.equalToSuperview().dividedBy(2)
            make.height.equalTo(pv4.snp.width).multipliedBy(9.0 / 16.0)
            make.left.equalToSuperview()
            make.top.equalTo(pv4.snp.bottom)
        }
        pv7.snp.makeConstraints { make in
            make.width.equalToSuperview().dividedBy(2)
            make.height.equalTo(pv4.snp.width).multipliedBy(9.0 / 16.0)
            make.left.equalTo(pv6.snp.right)
            make.top.equalTo(pv6.snp.top)
        }
        view.addSubview(pvLandscape)
        pvLandscape.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalToSuperview()
        }
        pvLandscape.addSubview(pv1Landscape)
        // 白板底图
        pvLandscape.addSubview(ivPresentImage)
        ivPresentImage.snp.makeConstraints { make in
            // 宽大于高时，以高为基准进行缩放
            make.height.equalToSuperview()
            make.width.equalTo(ivPresentImage.snp.height).multipliedBy(16.0/9.0)
            make.center.equalToSuperview()
        }
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
//        updateParticipantViews()
        // 白板
        // 设置为透明背景，用底图做背景
        drawingBoardView.isHidden = true
        drawingBoardView.setBgColor(.clear)
        view.addSubview(drawingBoardView)
        drawingBoardView.snp.makeConstraints { make in
            // 宽大于高时，以高为基准进行缩放
            make.height.equalToSuperview()
            make.width.equalTo(drawingBoardView.snp.height).multipliedBy(16.0/9.0)
            make.center.equalToSuperview()
        }
        whiteBoardFuncBar.isHidden = true
        view.addSubview(whiteBoardFuncBar)
        whiteBoardFuncBar.snp.makeConstraints { make in
            make.width.height.equalTo(45.screenAdapt())
            make.left.equalToSuperview().offset(45.screenAdapt())
            make.centerY.equalToSuperview()
        }
        view.addSubview(lockedTip)
        lockedTip.snp.makeConstraints { make in
            make.width.equalTo(128.screenAdapt())
            make.height.equalTo(32.screenAdapt())
            make.left.equalToSuperview().offset(15.screenAdapt())
            make.top.equalToSuperview().offset(59.screenAdapt() + StatusBarUtil.getHeight())
        }
        view.addSubview(viewLecturerBackground)
        viewLecturerBackground.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15.screenAdapt())
            make.top.equalToSuperview().offset(15.screenAdapt())
        }
    }
    
    override func setListener() {
        let onDoubleClickListener: ((String?) -> Void) = { uuid in
            guard let uuid = uuid else {
                return
            }
            let conferenceViewController = AppUtil.findViewController(viewControllerType: ConferenceViewController.self)
            conferenceViewController?.selectSee(uuid: uuid)
        }
        pvPrimary.onDoubleClickListener = onDoubleClickListener
        pvSecondary.onDoubleClickListener = onDoubleClickListener
        pv1.onDoubleClickListener = onDoubleClickListener
        pv2.onDoubleClickListener = onDoubleClickListener
        pv3.onDoubleClickListener = onDoubleClickListener
        pv4.onDoubleClickListener = onDoubleClickListener
        pv5.onDoubleClickListener = onDoubleClickListener
        pv6.onDoubleClickListener = onDoubleClickListener
        pv7.onDoubleClickListener = onDoubleClickListener
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
                if (self.pvPrimary.getParticipantBean()?.uuid == participantBean.uuid) {
                    self.pvPrimary.setParticipantBean(participantBean)
                } else if (self.pvSecondary.getParticipantBean()?.uuid == participantBean.uuid) {
                    self.pvSecondary.setParticipantBean(participantBean)
                } else if (self.pv1.getParticipantBean()?.uuid == participantBean.uuid) {
                    self.pv1.setParticipantBean(participantBean)
                } else if (self.pv2.getParticipantBean()?.uuid == participantBean.uuid) {
                    self.pv2.setParticipantBean(participantBean)
                } else if (self.pv3.getParticipantBean()?.uuid == participantBean.uuid) {
                    self.pv3.setParticipantBean(participantBean)
                } else if (self.pv4.getParticipantBean()?.uuid == participantBean.uuid) {
                    self.pv4.setParticipantBean(participantBean)
                } else if (self.pv5.getParticipantBean()?.uuid == participantBean.uuid) {
                    self.pv5.setParticipantBean(participantBean)
                } else if (self.pv6.getParticipantBean()?.uuid == participantBean.uuid) {
                    self.pv6.setParticipantBean(participantBean)
                } else if (self.pv7.getParticipantBean()?.uuid == participantBean.uuid) {
                    self.pv7.setParticipantBean(participantBean)
                } else if (self.pv1Landscape.getParticipantBean()?.uuid == participantBean.uuid) {
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
    
    override func onWhiteboardStart(url: String?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let conferenceViewController = AppUtil.findViewController(viewControllerType: ConferenceViewController.self)
            if let isWhiteboardAllowOtherMark = conferenceViewController?.conferenceManager.getConferenceStatus()?.isWhiteboardAllowOtherMark() {
                if (isWhiteboardAllowOtherMark) {
                    self.drawingBoardView.isHidden = false
                    self.drawingBoardView.isUserInteractionEnabled = false
                    self.whiteBoardFuncBar.isHidden = false
                    self.whiteBoardFuncBar.fold()
                } else {
                    self.drawingBoardView.isHidden = true
                    self.drawingBoardView.isUserInteractionEnabled = false
                    self.drawingBoardView.clearAllLine()
                    self.whiteBoardFuncBar.isHidden = true
                }
            }
            if let conferenceStatusBean = conferenceViewController?.conferenceManager.getConferenceStatus()
                , let url = url
                , conferenceStatusBean.isWhiteboardAllowOtherMark()
                , conferenceStatusBean.screenshare == 0 {
                MyHttpHepler.instance.httpHelper.getCaller(HttpCaller.Builder(url: url)
                    .setMethod(.get)
                    .setCachePolicy(.reloadIgnoringLocalAndRemoteCacheData))
                .enqueue(success: { [weak self] data, response in
                    guard let self = self else { return }
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.ivPresentImage.image = UIImage(data: data)
                        self.ivPresentImage.isHidden = false
                    }
                }, failure: { [weak self] data, error in
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.ivPresentImage.image = nil
                        self.ivPresentImage.isHidden = true
                    }
                })
            } else {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.ivPresentImage.image = nil
                    self.ivPresentImage.isHidden = true
                }
            }
        }
    }

    override func onWhiteboardStop() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let conferenceViewController = AppUtil.findViewController(viewControllerType: ConferenceViewController.self)
            self.drawingBoardView.isHidden = true
            self.drawingBoardView.isUserInteractionEnabled = false
            self.drawingBoardView.clearAllLine()
            self.whiteBoardFuncBar.isHidden = true
            self.ivPresentImage.isHidden = true
        }
    }
    
    override func onWhiteboardAddLine(whiteboardAddLineBean: WhiteboardAddLineBean) {
        guard let payload = whiteboardAddLineBean.payload else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let pathInfo = DrawingBoardView.PathInfo()
            pathInfo.id = whiteboardAddLineBean.id
            pathInfo.color = UIColor.fromHexString(hexString: payload.lineColor ?? "#FF000000") ?? .black
            pathInfo.width = payload.lineWidth ?? 1
            if let width = payload.width, let height = payload.height, let points = payload.points {
                let path = UIBezierPath()
                // 等比例缩放
                let drawingBoardViewWidth = ScreenUtil.isPortrait()
                ? self.drawingBoardView.frame.height
                : self.drawingBoardView.frame.width
                let drawingBoardViewHeight = ScreenUtil.isPortrait()
                ? self.drawingBoardView.frame.width
                : self.drawingBoardView.frame.height
                let widthScale = drawingBoardViewWidth / width
                let heightScale = drawingBoardViewHeight / height
                for (i,point) in points.enumerated() {
                    guard let x = point.x, let y = point.y else {
                        continue
                    }
                    if (i ==  0) {
                        path.move(to: CGPoint(x: x * widthScale, y: y * heightScale))
                    } else {
                        path.addLine(to: CGPoint(x: x * widthScale, y: y * heightScale))
                    }
                }
                pathInfo.path = path
            }
            let conferenceViewController = AppUtil.findViewController(viewControllerType: ConferenceViewController.self)
            if (whiteboardAddLineBean.sender == conferenceViewController?.conferenceManager.getParticipantUUID()) {
                pathInfo.lineType = .drawn
            } else {
                pathInfo.lineType = .added
            }
            self.drawingBoardView.addPath(pathInfo: pathInfo)
        }
    }
    
    override func onWhiteboardDeleteLine(whiteboardDeleteLineBean: WhiteboardDeleteLineBean) {
        guard let id = whiteboardDeleteLineBean.id else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.drawingBoardView.remove(id: id)
        }
    }
    
    override func onWhiteboardClearLine() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.drawingBoardView.clearAllLine()
        }
    }
    
    override func onWhiteboardBackgroundUpdate(url: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let conferenceViewController = AppUtil.findViewController(viewControllerType: ConferenceViewController.self)
            if let conferenceStatusBean = conferenceViewController?.conferenceManager.getConferenceStatus()
                , conferenceStatusBean.isWhiteboardAllowOtherMark()
                , conferenceStatusBean.screenshare == 0 {
                MyHttpHepler.instance.httpHelper.getCaller(HttpCaller.Builder(url: url)
                    .setMethod(.get)
                    .setCachePolicy(.reloadIgnoringLocalAndRemoteCacheData))
                .enqueue(success: { [weak self] data, response in
                    guard let self = self else { return }
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.ivPresentImage.image = UIImage(data: data)
                        self.ivPresentImage.isHidden = false
                    }
                }, failure: { [weak self] data, error in
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.ivPresentImage.image = nil
                        self.ivPresentImage.isHidden = true
                    }
                })
            } else {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.ivPresentImage.image = nil
                    self.ivPresentImage.isHidden = true
                }
            }
        }
    }
    
    override func onWhiteboardMarkPermissionChanged(isWhiteboardAllowOtherMark: Bool, screenShare: Int?, fold: Bool = true) {
        MyShowLogger.instance.showLogger.debug("onWhiteboardMarkPermissionChanged, isWhiteboardAllowOtherMark--->\(isWhiteboardAllowOtherMark)")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let conferenceViewController = AppUtil.findViewController(viewControllerType: ConferenceViewController.self)
            if (isWhiteboardAllowOtherMark) {
                self.drawingBoardView.isHidden = false
                if (fold) {
                    self.drawingBoardView.isUserInteractionEnabled = false
                }
                self.whiteBoardFuncBar.isHidden = false
                if (fold) {
                    self.whiteBoardFuncBar.fold()
                }
                self.ivPresentImage.isHidden = false
            } else {
                self.drawingBoardView.isHidden = true
                self.drawingBoardView.isUserInteractionEnabled = false
                self.drawingBoardView.clearAllLine()
                self.whiteBoardFuncBar.isHidden = true
                self.ivPresentImage.isHidden = true
            }
            if (isWhiteboardAllowOtherMark && screenShare == 0) {
                self.ivPresentImage.isHidden = false
            } else {
                self.ivPresentImage.isHidden = true
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
        let conferenceViewController = AppUtil.findViewController(viewControllerType: ConferenceViewController.self)
        if let selectSeeUUID = conferenceViewController?.conferenceManager.getSelectSeeUUID() {
            conferenceViewController?.unselectSee(uuid: selectSeeUUID)
        }
    }
    
    private func updateParticipantViews() {
        if (layoutBeans.count == 0) {
            return
        }
        resortLayoutBeans()
        if (ScreenUtil.isPortrait()) {
            updateParticipantViewsPortrait()
        } else {
            updateParticipantViewsLandscape()
        }
        let presentLayoutBean = layoutBeans.first { layoutBean in
            return layoutBean.ssrc == SdpUtil.PRESENTATION_VIDEO_RECEIVE_SSRC_ID
        }
        if let presentLayoutBean = presentLayoutBean {
            let presentParticipantBean = (parent?.parent as? ConferenceViewController)?.conferenceManager.getParticipantBean(uuid: presentLayoutBean.participantUUID)
            lbLecturer.text = "演讲者：\(presentParticipantBean?.getShowName() ?? "")"
            viewLecturerBackground.isHidden = false
        } else {
            lbLecturer.text = ""
            viewLecturerBackground.isHidden = true
        }
    }
    
    private func updateParticipantViewsPortrait() {
        pvPortrait.isHidden = true
        pvLandscape.isHidden = true
        pvPrimary.isHidden = true
        pvSecondary.isHidden = true
        pv1.isHidden = true
        pv2.isHidden = true
        pv3.isHidden = true
        pv4.isHidden = true
        pv5.isHidden = true
        pv6.isHidden = true
        pv7.isHidden = true
        pv1Landscape.isHidden = true
        pv2Landscape.isHidden = true
        pv3Landscape.isHidden = true
        pv4Landscape.isHidden = true
        pv5Landscape.isHidden = true
        pv6Landscape.isHidden = true
        pv7Landscape.isHidden = true
        pvPrimary.setMirror(false)
        pvSecondary.setMirror(false)
        pv1.setMirror(false)
        pv2.setMirror(false)
        pv1Landscape.setMirror(false)
        pv2Landscape.setMirror(false)
        let conferenceManager = (parent?.parent as? ConferenceViewController)?.conferenceManager
        if (layoutBeans.count == 1) {
            pvPrimary.isHidden = false
            pvPrimary.setVideoTrack(conferenceManager?.getRTCManager()?.getVideoTrack(trackId: layoutBeans[0].mediaStremTrackId))
            pvPrimary.setParticipantBean(conferenceManager?.getParticipantBean(uuid: layoutBeans[0].participantUUID))
            if (layoutBeans[0].participantUUID == conferenceManager?.getParticipantUUID()) {
                let front = conferenceManager?.getRTCManager()?.isFrontFacing() ?? true
                let cameraEnabled = conferenceManager?.getRTCManager()?.isCameraEnabled() ?? true
                let mirror = true
                pvPrimary.setMirror(front && cameraEnabled && mirror)
            }
            return
        }
        if (layoutBeans.count == 2) {
            pvPrimary.isHidden = false
            pvPrimary.setVideoTrack(conferenceManager?.getRTCManager()?.getVideoTrack(trackId: layoutBeans[0].mediaStremTrackId))
            pvPrimary.setParticipantBean(conferenceManager?.getParticipantBean(uuid: layoutBeans[0].participantUUID))
            if (layoutBeans[0].participantUUID == conferenceManager?.getParticipantUUID()) {
                let front = conferenceManager?.getRTCManager()?.isFrontFacing() ?? true
                let cameraEnabled = conferenceManager?.getRTCManager()?.isCameraEnabled() ?? true
                let mirror = true
                pvPrimary.setMirror(front && cameraEnabled && mirror)
            }
            if (AppUtil.findViewController(viewControllerType: ConferenceViewController.self)?.isPictureInPicture() == false) {
                // 竖屏时，有两个视频画面时，第二个小画面属于画中画，如果关闭了画中画模式，则第二个小画面就不显示了，直接 return
                return
            }
            pvSecondary.isHidden = false
            pvSecondary.setVideoTrack(conferenceManager?.getRTCManager()?.getVideoTrack(trackId: layoutBeans[1].mediaStremTrackId))
            pvSecondary.setParticipantBean(conferenceManager?.getParticipantBean(uuid: layoutBeans[1].participantUUID))
            if (layoutBeans[1].participantUUID == conferenceManager?.getParticipantUUID()) {
                let front = conferenceManager?.getRTCManager()?.isFrontFacing() ?? true
                let cameraEnabled = conferenceManager?.getRTCManager()?.isCameraEnabled() ?? true
                let mirror = true
                pvSecondary.setMirror(front && cameraEnabled && mirror)
            }
            return
        }
        pvPortrait.isHidden = false
        pv1.isHidden = false
        pv1.snp.remakeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(pv1.snp.width).multipliedBy(9.0 / 16.0)
            make.left.equalToSuperview()
            if (layoutBeans.count >= 6) {
                make.top.equalToSuperview()
            } else if (layoutBeans.count >= 4) {
                make.top.equalToSuperview().offset(ScreenUtil.getScreenWidth() * 9.0 / 16.0 * 0.5 / 2.0)
            } else {
                make.top.equalToSuperview().offset(ScreenUtil.getScreenWidth() * 9.0 / 16.0 * 1.0 / 2.0)
            }
        }
        pv1.setVideoTrack(conferenceManager?.getRTCManager()?.getVideoTrack(trackId: layoutBeans[0].mediaStremTrackId))
        pv1.setParticipantBean(conferenceManager?.getParticipantBean(uuid: layoutBeans[0].participantUUID))
        if (layoutBeans[0].participantUUID == conferenceManager?.getParticipantUUID()) {
            let front = conferenceManager?.getRTCManager()?.isFrontFacing() ?? true
            let cameraEnabled = conferenceManager?.getRTCManager()?.isCameraEnabled() ?? true
            let mirror = true
            pv1.setMirror(front && cameraEnabled && mirror)
        }
        pv2.isHidden = false
        pv2.snp.remakeConstraints { make in
            make.width.equalToSuperview().dividedBy(2)
            make.height.equalTo(pv2.snp.width).multipliedBy(9.0 / 16.0)
            make.left.equalToSuperview()
            make.top.equalTo(pv1.snp.bottom)
        }
        pv2.setVideoTrack(conferenceManager?.getRTCManager()?.getVideoTrack(trackId: layoutBeans[1].mediaStremTrackId))
        pv2.setParticipantBean(conferenceManager?.getParticipantBean(uuid: layoutBeans[1].participantUUID))
        if (layoutBeans[1].participantUUID == conferenceManager?.getParticipantUUID()) {
            let front = conferenceManager?.getRTCManager()?.isFrontFacing() ?? true
            let cameraEnabled = conferenceManager?.getRTCManager()?.isCameraEnabled() ?? true
            let mirror = true
            pv2.setMirror(front && cameraEnabled && mirror)
        }
        pv3.isHidden = false
        pv3.snp.makeConstraints { make in
            make.width.equalToSuperview().dividedBy(2)
            make.height.equalTo(pv3.snp.width).multipliedBy(9.0 / 16.0)
            make.left.equalTo(pv2.snp.right)
            make.top.equalTo(pv2.snp.top)
        }
        pv3.setVideoTrack(conferenceManager?.getRTCManager()?.getVideoTrack(trackId: layoutBeans[2].mediaStremTrackId))
        pv3.setParticipantBean(conferenceManager?.getParticipantBean(uuid: layoutBeans[2].participantUUID))
        if (layoutBeans.count >= 4) {
            pv4.isHidden = false
            pv4.snp.remakeConstraints { make in
                make.width.equalToSuperview().dividedBy(2)
                make.height.equalTo(pv4.snp.width).multipliedBy(9.0 / 16.0)
                if (layoutBeans.count >= 5) {
                    make.left.equalToSuperview()
                } else {
                    make.left.equalToSuperview().offset(ScreenUtil.getScreenWidth() / 2.0 / 2.0)
                }
                make.top.equalTo(pv2.snp.bottom)
            }
            pv4.setVideoTrack(conferenceManager?.getRTCManager()?.getVideoTrack(trackId: layoutBeans[3].mediaStremTrackId))
            pv4.setParticipantBean(conferenceManager?.getParticipantBean(uuid: layoutBeans[3].participantUUID))
        }
        if (layoutBeans.count >= 5) {
            pv5.isHidden = false
            pv5.snp.remakeConstraints { make in
                make.width.equalToSuperview().dividedBy(2)
                make.height.equalTo(pv4.snp.width).multipliedBy(9.0 / 16.0)
                make.left.equalTo(pv4.snp.right)
                make.top.equalTo(pv4.snp.top)
            }
            pv5.setVideoTrack(conferenceManager?.getRTCManager()?.getVideoTrack(trackId: layoutBeans[4].mediaStremTrackId))
            pv5.setParticipantBean(conferenceManager?.getParticipantBean(uuid: layoutBeans[4].participantUUID))
        }
        if (layoutBeans.count >= 6) {
            pv6.isHidden = false
            pv6.snp.remakeConstraints { make in
                make.width.equalToSuperview().dividedBy(2)
                make.height.equalTo(pv4.snp.width).multipliedBy(9.0 / 16.0)
                if (layoutBeans.count >= 7) {
                    make.left.equalToSuperview()
                } else {
                    make.left.equalToSuperview().offset(ScreenUtil.getScreenWidth() / 2.0 / 2.0)
                }
                make.top.equalTo(pv4.snp.bottom)
            }
            pv6.setVideoTrack(conferenceManager?.getRTCManager()?.getVideoTrack(trackId: layoutBeans[5].mediaStremTrackId))
            pv6.setParticipantBean(conferenceManager?.getParticipantBean(uuid: layoutBeans[5].participantUUID))
        }
        if (layoutBeans.count >= 7) {
            pv7.isHidden = false
            pv7.snp.remakeConstraints { make in
                make.width.equalToSuperview().dividedBy(2)
                make.height.equalTo(pv4.snp.width).multipliedBy(9.0 / 16.0)
                make.left.equalTo(pv6.snp.right)
                make.top.equalTo(pv6.snp.top)
            }
            pv7.setVideoTrack(conferenceManager?.getRTCManager()?.getVideoTrack(trackId: layoutBeans[6].mediaStremTrackId))
            pv7.setParticipantBean(conferenceManager?.getParticipantBean(uuid: layoutBeans[6].participantUUID))
        }
    }
    
    private func updateParticipantViewsLandscape() {
        pvPortrait.isHidden = true
        pvLandscape.isHidden = true
        pvPrimary.isHidden = true
        pvSecondary.isHidden = true
        pv1.isHidden = true
        pv2.isHidden = true
        pv3.isHidden = true
        pv4.isHidden = true
        pv5.isHidden = true
        pv6.isHidden = true
        pv7.isHidden = true
        pv1Landscape.isHidden = true
        pv2Landscape.isHidden = true
        pv3Landscape.isHidden = true
        pv4Landscape.isHidden = true
        pv5Landscape.isHidden = true
        pv6Landscape.isHidden = true
        pv7Landscape.isHidden = true
        pvPrimary.setMirror(false)
        pvSecondary.setMirror(false)
        pv1.setMirror(false)
        pv2.setMirror(false)
        pv1Landscape.setMirror(false)
        pv2Landscape.setMirror(false)
        pvLandscape.isHidden = false
        let conferenceManager = (parent?.parent as? ConferenceViewController)?.conferenceManager
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
        if (AppUtil.findViewController(viewControllerType: ConferenceViewController.self)?.isPictureInPicture() == false) {
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
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.lockedTip.isHidden = false
        }
    }
    
    func hideLockedTip() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.lockedTip.isHidden = true
        }
    }
}
