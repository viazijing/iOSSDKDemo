//
//  ConferenceDemoPresentPDFViewController.swift
//  iOSSDKDemo
//
//  Created by Mac on 2025/4/15.
//  会中自己共享 PDF 时的界面
//

import common
import permission
import rtc
import SnapKit
import UIKit
import PDFKit

class ConferenceDemoPresentPDFViewController: ConferenceChildViewController {
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
    private let url: URL
    /**
     UIPageViewController 当前页卡
     */
    private var curPosition = 0
    private lazy var viewControllers: [UIViewController] = []
    
    init(url: URL) {
        self.url = url
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
        
        guard let pdfDocument = PDFDocument(url: url) else {
            MyShowLogger.instance.showLogger.info("pdf 分享失败，pdf is nil.")
            return
        }
        guard pdfDocument.pageCount > 0 else {
            MyShowLogger.instance.showLogger.info("pdf 分享失败，pageCount count is zero.")
            return
        }
        // 最多预加载三张
        for i in 0..<min(pdfDocument.pageCount, 3) {
            guard let pdfPage = pdfDocument.page(at: i) else {
                MyShowLogger.instance.showLogger.info("pdf 分享失败，pdfPage is nil.")
                return
            }
            // 分享的图片尺寸为 1280*720
            let targetSize = CGSize(width: 1280, height: 720)
            // 获取 pdf 原始宽高
            let pageSize = pdfPage.bounds(for: .mediaBox).size
            // 计算缩放比
            let scale = min(targetSize.width / pageSize.width, targetSize.height / pageSize.height)
            let scaledSize = CGSize(width: pageSize.width * scale, height: pageSize.height * scale)
            // 计算偏移量以居中显示
            let offset = CGPoint(x: (targetSize.width - scaledSize.width) / 2, y: (targetSize.height - scaledSize.height) / 2)
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            var uiImage = renderer.image { context in
                // 绘制白色背景
                UIColor.white.setFill()
                context.cgContext.fill(CGRect(x: offset.x, y: offset.y, width: scaledSize.width, height: scaledSize.height))
                // 将坐标系进行转换，将 pdf 坐标系转换为图像坐标系
                context.cgContext.translateBy(x: offset.x, y: targetSize.height - offset.y)
                context.cgContext.scaleBy(x: scale, y: -scale)
                // 绘制 pdf 内容
                pdfPage.draw(with: .mediaBox, to: context.cgContext)
            }
            // 压缩
            if let data = uiImage.compressImageToTargetSize(targetSize: 1024 * 1024 * 2),
               let compress = UIImage(data: data) {
                uiImage = compress
            }
            let imgViewController = ImgViewController(img: uiImage)
            imgViewController.setImageCapturerSource(uiImage)
            viewControllers.append(imgViewController)
        }
        pageViewController.setViewControllers([viewControllers.first!], direction: .forward, animated: false)
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
        let conferenceViewController = AppUtil.findViewController(viewControllerType: ConferenceDemoViewController.self)
        let conferenceManager = conferenceViewController?.conferenceManager
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
        pv2Landscape.isHidden = true
        pv2Landscape.setMirror(false)
        pvLandscape.isHidden = false
        let conferenceViewController = AppUtil.findViewController(viewControllerType: ConferenceDemoViewController.self)
        let conferenceManager = conferenceViewController?.conferenceManager
        if (conferenceViewController?.isPictureInPicture() == false) {
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
    
    override func onPictureInPictureUpdate(_ pictureInPicture: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            updateParticipantViews()
        }
    }
}

// MARK: - UIScrollViewDelegate
extension ConferenceDemoPresentPDFViewController: UIScrollViewDelegate {
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
extension ConferenceDemoPresentPDFViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if (!completed) {
            return
        }
        let curViewController = pageViewController.viewControllers?[0]
        if (curViewController == nil) {
            return
        }
        curPosition = viewControllers.firstIndex(of: curViewController!) ?? 0
        let conferenceViewController = AppUtil.findViewController(viewControllerType: ConferenceDemoViewController.self)
        let conferenceManager = conferenceViewController?.conferenceManager
        guard var imageCapturerSource = (self.viewControllers[self.curPosition] as? ImgViewController)?.getImageCapturerSource() else {
            return
        }
        // 合并保存
        var result = imageCapturerSource
        // 压缩
        if let data = result.compressImageToTargetSize(targetSize: 1024 * 1024 * 2),
           let compress = UIImage(data: data) {
            result = compress
        }
        // 更新白板背景
        conferenceManager?.getPresentationManager()?.newWhiteboardBackground(result)
        // 更新视频流画面
        conferenceManager?.getPresentationManager()?.updateImgeCapture(result)
        // 滑到最后了，继续预加载三张
        guard let pdfDocument = PDFDocument(url: url) else {
            MyShowLogger.instance.showLogger.info("pdf 分享失败，pdf is nil.")
            return
        }
        guard pdfDocument.pageCount > 0 else {
            MyShowLogger.instance.showLogger.info("pdf 分享失败，pageCount count is zero.")
            return
        }
        if (curPosition == (viewControllers.count - 1) && viewControllers.count < pdfDocument.pageCount) {
            // 最多预加载三张
            for i in 0..<min(pdfDocument.pageCount, 3) {
                guard let pdfPage = pdfDocument.page(at: viewControllers.count + i) else {
                    MyShowLogger.instance.showLogger.info("pdf 分享失败，pdfPage is nil.")
                    return
                }
                // 分享的图片尺寸为 1280*720
                let targetSize = CGSize(width: 1280, height: 720)
                // 获取 pdf 原始宽高
                let pageSize = pdfPage.bounds(for: .mediaBox).size
                // 计算缩放比
                let scale = min(targetSize.width / pageSize.width, targetSize.height / pageSize.height)
                let scaledSize = CGSize(width: pageSize.width * scale, height: pageSize.height * scale)
                // 计算偏移量以居中显示
                let offset = CGPoint(x: (targetSize.width - scaledSize.width) / 2, y: (targetSize.height - scaledSize.height) / 2)
                let renderer = UIGraphicsImageRenderer(size: targetSize)
                var uiImage = renderer.image { context in
                    // 绘制白色背景
                    UIColor.white.setFill()
                    context.cgContext.fill(CGRect(x: offset.x, y: offset.y, width: scaledSize.width, height: scaledSize.height))
                    // 将坐标系进行转换，将 pdf 坐标系转换为图像坐标系
                    context.cgContext.translateBy(x: offset.x, y: targetSize.height - offset.y)
                    context.cgContext.scaleBy(x: scale, y: -scale)
                    // 绘制 pdf 内容
                    pdfPage.draw(with: .mediaBox, to: context.cgContext)
                }
                // 压缩
                if let data = uiImage.compressImageToTargetSize(targetSize: 1024 * 1024 * 2),
                   let compress = UIImage(data: data) {
                    uiImage = compress
                }
                let imgViewController = ImgViewController(img: uiImage)
                imgViewController.setImageCapturerSource(uiImage)
                viewControllers.append(imgViewController)
            }
        }
    }
}

// MARK: - UIPageViewControllerDataSource
extension ConferenceDemoPresentPDFViewController: UIPageViewControllerDataSource {
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

