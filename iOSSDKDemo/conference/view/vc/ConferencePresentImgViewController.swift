//
//  ConferenceImgShareViewController.swift
//  zj-phone
//
//  Created by Mac on 2023/6/8.
//  会中自己分享图片时的界面
//

import common
import permission
import rtc
import SnapKit
import UIKit

class ConferencePresentImgViewController: ConferenceChildViewController {
    lazy var pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    private lazy var pvLandscape = {
        let view = UIView()
        // 白板在下面，所以让 participantView 不可交互，事件往下传递
        view.isUserInteractionEnabled = false
        return view
    }()
    private lazy var pv2Landscape = {
        let participantView = ParticipantView()
        participantView.isHidden = true
        // 白板在下面，所以让 participantView 不可交互，事件往下传递
        participantView.isUserInteractionEnabled = false
        return participantView
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
            let uiImage = self.imgs[self.curPosition]
            let screenshot = drawingBoardView.screenshot()
            // 合并更新
            let result = self.mergeUIImage(uiImage1: uiImage, uiImage2: screenshot)
            // 更新视频流画面
            conferenceManager?.getPresentationManager()?.updateImgeCapture(result)
        }
        drawingBoardView.onRemoveLineListener = { [weak self] pathInfo in
            guard let self = self else { return }
            guard let id = pathInfo.id else {
                return
            }
            let conferenceManager = (self.parent?.parent as? ConferenceViewController)?.conferenceManager
            conferenceManager?.getPresentationManager()?.removeLine(id: id, onSuccess: {
            }, onFailure: { error in
            })
            let uiImage = self.imgs[self.curPosition]
            let screenshot = drawingBoardView.screenshot()
            // 合并更新
            let result = self.mergeUIImage(uiImage1: uiImage, uiImage2: screenshot)
            // 更新视频流画面
            conferenceManager?.getPresentationManager()?.updateImgeCapture(result)
        }
        return drawingBoardView
    }()
    private lazy var whiteBoardFuncBar = {
        let whiteBoardFuncBar = WhiteBoardFuncBar()
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(viewDragged(_:)))
        whiteBoardFuncBar.addGestureRecognizer(panGestureRecognizer)
        whiteBoardFuncBar.onUnfoldListener = { [weak self] unfold in
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
                let uiImage = self.imgs[self.curPosition]
                let screenshot = self.drawingBoardView.screenshot()
                // 合并更新
                let result = self.mergeUIImage(uiImage1: uiImage, uiImage2: screenshot)
                // 更新视频流画面
                conferenceManager?.getPresentationManager()?.updateImgeCapture(result)
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
                let uiImage = self.imgs[self.curPosition]
                let screenshot = self.drawingBoardView.screenshot()
                // 合并更新
                let result = self.mergeUIImage(uiImage1: uiImage, uiImage2: screenshot)
                // 更新视频流画面
                conferenceManager?.getPresentationManager()?.updateImgeCapture(result)
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
                let uiImage = self.imgs[self.curPosition]
                let screenshot = self.drawingBoardView.screenshot()
                // 合并更新
                let result = self.mergeUIImage(uiImage1: uiImage, uiImage2: screenshot)
                // 更新视频流画面
                conferenceManager?.getPresentationManager()?.updateImgeCapture(result)
                break
            }
        }
        whiteBoardFuncBar.onDownloadClickListener = { [weak self] in
            PhotoLibraryPermissionChecker().request { [weak self] in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    let uiImage = self.imgs[self.curPosition]
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
    private let imgs: Array<UIImage>
    /**
     UIPageViewController 当前页卡
     */
    private var curPosition = 0
    private lazy var viewControllers: [UIViewController] = []
    
    init(imgs: [UIImage]) {
        self.imgs = imgs
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
    }
    
    override func initView() {
        // 共享图片
        for v in pageViewController.view.subviews {
            if (v is UIScrollView) {
                // 代理 UIPageViewController 的 UIScrollView，处理第一个页卡和最后一个页卡的果冻回弹效果
                (v as! UIScrollView).delegate = self
            }
        }
        pageViewController.delegate = self
        pageViewController.dataSource = self
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.view.snp.makeConstraints { make in
            make.left.top.right.bottom.equalToSuperview()
        }
        for img in imgs {
            let imgViewController = ImgViewController(img: img)
            imgViewController.setImageCapturerSource(img)
            viewControllers.append(imgViewController)
        }
        pageViewController.setViewControllers([viewControllers.first!], direction: .forward, animated: false)
        // 白板
        // 设置为透明背景，用底图做背景
        drawingBoardView.setBgColor(.clear)
        view.addSubview(drawingBoardView)
        drawingBoardView.snp.makeConstraints { make in
            // 宽大于高时，以高为基准进行缩放
            make.height.equalToSuperview()
            make.width.equalTo(drawingBoardView.snp.height).multipliedBy(16.0/9.0)
            make.center.equalToSuperview()
        }
        view.addSubview(whiteBoardFuncBar)
        whiteBoardFuncBar.snp.makeConstraints { make in
            make.width.height.equalTo(45.screenAdapt())
            make.left.equalToSuperview().offset(45.screenAdapt())
            make.centerY.equalToSuperview()
        }
        if let unfold = whiteBoardFuncBar.isUnfold() {
            drawingBoardView.isUserInteractionEnabled = unfold
        }
        // 视频画面
        view.addSubview(pvLandscape)
        pvLandscape.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalToSuperview()
        }
        pvLandscape.addSubview(pv2Landscape)
        pv2Landscape.snp.makeConstraints { make in
            make.width.equalToSuperview().dividedBy(6)
            make.height.equalTo(pv2Landscape.snp.width).multipliedBy(9.0 / 16.0)
            make.left.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    override func setListener() {
    }
    
    override func initData() {
        // 该界面只需要一个小画面
        let conferenceManager = (self.parent?.parent as? ConferenceViewController)?.conferenceManager
        conferenceManager?.getRTCManager()?.layout("0:1")
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
            //        let presentationLayoutBean = layoutBeans.first { layoutBean in
            //            return layoutBean.ssrc == SdpUtil.PRESENTATION_VIDEO_SEND_SSRC_ID
            //            || layoutBean.ssrc == SdpUtil.PRESENTATION_VIDEO_RECEIVE_SSRC_ID
            //        }
            //        if (presentationLayoutBean == nil) {
            //            // 没有演讲流的时候，才会显示自己
            //            if let myLayoutBean = conferenceManager?.getMyLayoutBean() {
            //                self.layoutBeans.append(myLayoutBean)
            //            }
            //        }
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
                if (self.pv2Landscape.getParticipantBean()?.uuid == participantBean.uuid) {
                    self.pv2Landscape.setParticipantBean(participantBean)
                }
            }
        }
    }
    
    private func updateParticipantViews() {
        if (layoutBeans.count == 0) {
            return
        }
        pvLandscape.isHidden = true
        //            self.pv1Landscape.isHidden = true
        pv2Landscape.isHidden = true
        //            self.pv1Landscape.setMirror(false)
        pv2Landscape.setMirror(false)
        pvLandscape.isHidden = false
        let conferenceManager = (parent?.parent as? ConferenceViewController)?.conferenceManager
        //            if (self.layoutBeans.count >= 1) {
        //                self.pv1Landscape.isHidden = false
        //                self.pv1Landscape.setVideoTrack(conferenceManager?.getRTCManager()?.getVideoTrack(trackId: self.layoutBeans[0].mediaStremTrackId))
        //                self.pv1Landscape.setParticipantBean(conferenceManager?.getParticipantBean(uuid: self.layoutBeans[0].participantUUID))
        //            }
        if (AppUtil.findViewController(viewControllerType: ConferenceViewController.self)?.isPictureInPicture() == false) {
            // 横屏时，小画面都属于画中画，如果关闭了画中画模式，则除了第一个大画面显示，后面的小画面都不显示了，直接 return
            return
        }
        if (layoutBeans.count >= 1) {
            pv2Landscape.isHidden = false
            pv2Landscape.setVideoTrack(conferenceManager?.getRTCManager()?.getVideoTrack(trackId: layoutBeans[0].mediaStremTrackId))
            pv2Landscape.setParticipantBean(conferenceManager?.getParticipantBean(uuid: layoutBeans[0].participantUUID))
            if (layoutBeans[0].participantUUID == conferenceManager?.getParticipantUUID()) {
                let front = conferenceManager?.getRTCManager()?.isFrontFacing() ?? true
                let cameraEnabled = conferenceManager?.getRTCManager()?.isCameraEnabled() ?? true
                let mirror = true
                pv2Landscape.setMirror(front && cameraEnabled && mirror)
            }
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
            pathInfo.lineType = .added
            self.drawingBoardView.addPath(pathInfo: pathInfo)
            let conferenceManager = (self.parent?.parent as? ConferenceViewController)?.conferenceManager
            let uiImage = self.imgs[self.curPosition]
            let screenshot = drawingBoardView.screenshot()
            // 合并更新
            let result = self.mergeUIImage(uiImage1: uiImage, uiImage2: screenshot)
            // 更新视频流画面
            conferenceManager?.getPresentationManager()?.updateImgeCapture(result)
        }
    }
    
    override func onWhiteboardDeleteLine(whiteboardDeleteLineBean: WhiteboardDeleteLineBean) {
        guard let id = whiteboardDeleteLineBean.id else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let conferenceManager = (self.parent?.parent as? ConferenceViewController)?.conferenceManager
            self.drawingBoardView.remove(id: id)
            let uiImage = self.imgs[self.curPosition]
            let screenshot = drawingBoardView.screenshot()
            // 合并更新
            let result = self.mergeUIImage(uiImage1: uiImage, uiImage2: screenshot)
            // 更新视频流画面
            conferenceManager?.getPresentationManager()?.updateImgeCapture(result)
        }
    }
    
    override func onWhiteboardClearLine() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.drawingBoardView.clearAllLine()
        }
    }
    
    override func onPictureInPictureUpdate(_ pictureInPicture: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            updateParticipantViews()
        }
    }
}

// MARK: - UIScrollViewDelegate
extension ConferencePresentImgViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetX = scrollView.contentOffset.x
        // 处理第一个页卡时往右滑的果冻回弹效果
        if (curPosition == 0 && offsetX < scrollView.frame.width) {
            scrollView.contentOffset.x = scrollView.frame.width
            return
        }
        // 处理最后一个页卡时往左滑的果冻回弹效果
        if (curPosition == viewControllers.count - 1) && (offsetX > scrollView.frame.width) {
            scrollView.contentOffset.x = scrollView.frame.width
            return
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        // 重写该方法，使 UIScrollView 在第一个页卡和最后一个页卡时不会反弹
    }
}

// MARK: - UIPageViewControllerDelegate
extension ConferencePresentImgViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if (!completed) {
            return
        }
        let curViewController = pageViewController.viewControllers?[0]
        if (curViewController == nil) {
            return
        }
        curPosition = viewControllers.firstIndex(of: curViewController!) ?? 0
        
        let conferenceManager = (parent?.parent as? ConferenceViewController)?.conferenceManager
        guard let imageCapturerSource = (self.viewControllers[self.curPosition] as? ImgViewController)?.getImageCapturerSource() else {
            return
        }
        // 更新白板背景
        conferenceManager?.getPresentationManager()?.newWhiteboardBackground(imageCapturerSource)
        // 更新视频流画面
        conferenceManager?.getPresentationManager()?.updateImgeCapture(imageCapturerSource)
    }
}

// MARK: - UIPageViewControllerDataSource
extension ConferencePresentImgViewController: UIPageViewControllerDataSource {
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        viewControllers.count
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let index = viewControllers.firstIndex(of: viewController)
        if (index == nil || index == 0) {
            return nil
        }
        return viewControllers[index! - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let index = viewControllers.firstIndex(of: viewController)
        if (index == nil || index == viewControllers.count - 1) {
            return nil
        }
        return viewControllers[index! + 1]
    }
}
