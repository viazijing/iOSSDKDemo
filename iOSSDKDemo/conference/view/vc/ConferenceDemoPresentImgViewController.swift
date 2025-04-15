//
//  ConferenceDemoPresentImgViewController.swift
//  iOSSDKDemo
//
//  Created by Mac on 2025/4/15.
//

import common
import permission
import rtc
import SnapKit
import UIKit

class ConferenceDemoPresentImgViewController: ConferenceChildViewController {
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
    
    override func onPictureInPictureUpdate(_ pictureInPicture: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            updateParticipantViews()
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
}

// MARK: - UIScrollViewDelegate
extension ConferenceDemoPresentImgViewController: UIScrollViewDelegate {
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
extension ConferenceDemoPresentImgViewController: UIPageViewControllerDelegate {
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
        guard let imageCapturerSource = (viewControllers[curPosition] as? ImgViewController)?.getImageCapturerSource() else {
            return
        }
        // 更新白板背景
        conferenceManager?.getPresentationManager()?.newWhiteboardBackground(imageCapturerSource)
        // 更新视频流画面
        conferenceManager?.getPresentationManager()?.updateImgeCapture(imageCapturerSource)
    }
}

// MARK: - UIPageViewControllerDataSource
extension ConferenceDemoPresentImgViewController: UIPageViewControllerDataSource {
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
