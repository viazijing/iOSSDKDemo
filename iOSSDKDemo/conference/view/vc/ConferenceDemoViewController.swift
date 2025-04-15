//
//  ConferenceDemoViewController.swift
//  iOSSDKDemo
//
//  Created by Mac on 2025/4/14.
//

import Foundation
import UIKit
import permission
import rtc
import common
import TZImagePickerController
import PDFKit

class ConferenceDemoViewController: ViewController {
    
    private let serverAddr: String
    private let conferenceRoomNum: String
    private let pwd: String?
    private let name: String
    private let micEnable: Bool
    private let cameraEnable: Bool
    
    /**
     使用 contentView 替代 view，更好的控制状态栏等
     */
    private lazy var contentView = {
        let view = UIView()
        view.backgroundColor = .background_color_fff7f8fb
        return view
    }()
    private lazy var loadingBackgroundView = UIView()
    private lazy var loadingView = UIActivityIndicatorView()
    private lazy var pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    private lazy var viewControllers: [UIViewController] = []
    /**
     UIPageViewController 当前页卡
     */
    private var curPosition = 0
    private lazy var lbTheme = {
        let label = UILabel()
        label.textColor = .text_color_ffffffff
        label.font =  UIFont.systemFont(ofSize: 16.screenAdapt())
        label.textAlignment = .center
        return label
    }()
    private lazy var lbConferenceRoomNum = {
        let label = UILabel()
        label.textColor = .text_color_ffffffff
        label.font =  UIFont.systemFont(ofSize: 16.screenAdapt())
        label.textAlignment = .center
        return label
    }()
    private lazy var conferenceInfoView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8.screenAdapt()
        // 会议主题
        lbTheme.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        lbTheme.setContentHuggingPriority(.defaultLow, for: .horizontal)
        stackView.addArrangedSubview(lbTheme)
        // 会议号
        lbConferenceRoomNum.setContentCompressionResistancePriority(.required, for: .horizontal)
        lbConferenceRoomNum.setContentHuggingPriority(.required, for: .horizontal)
        stackView.addArrangedSubview(lbConferenceRoomNum)
        return stackView
    }()
    private lazy var titleBarContainer = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.6)
        // 标题栏
        let titleBar = UIView()
        view.addSubview(titleBar)
        titleBar.snp.makeConstraints { make in
            make.height.equalTo(54.screenAdapt())
            make.left.right.bottom.equalToSuperview()
        }
        // 会议信息
        titleBar.addSubview(conferenceInfoView)
        conferenceInfoView.snp.makeConstraints { make in
            make.width.lessThanOrEqualToSuperview().multipliedBy(0.7)
            make.center.equalToSuperview()
        }
        // 退出会议按钮
        let btnHangUp = UIButton()
        btnHangUp.setTitle("挂断", for: .normal)
        btnHangUp.setTitleColor(.text_color_ffff605c, for: .normal)
        btnHangUp.titleLabel?.font = UIFont.systemFont(ofSize: 16.screenAdapt())
        btnHangUp.sizeToFit()
        btnHangUp.addTarget(self, action: #selector(quit))
        titleBar.addSubview(btnHangUp)
        btnHangUp.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-15.screenAdapt())
            make.centerY.equalToSuperview()
        }
        return view
    }()
    private lazy var setMicDisabledView = {
        let view = UIView()
        view.addTarget(target: self, action: #selector(setMicDisabled))
        // 点击事件交给父控件处理
        let ivSetMicDisabled = UIButton()
        ivSetMicDisabled.isUserInteractionEnabled = false
        ivSetMicDisabled.setImage(UIImage(named: "conference_iv_set_mic_disabled_src"), for: .normal)
        view.addSubview(ivSetMicDisabled)
        ivSetMicDisabled.snp.makeConstraints { make in
            make.width.height.equalTo(30.screenAdapt())
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(8.screenAdapt())
        }
        // 点击事件交给父控件处理
        let lbSetMicDisabled = UIButton()
        lbSetMicDisabled.isUserInteractionEnabled = false
        lbSetMicDisabled.setTitle("静音", for: .normal)
        lbSetMicDisabled.setTitleColor(.text_color_ffffffff, for: .normal)
        lbSetMicDisabled.titleLabel?.font = .systemFont(ofSize: 13.screenAdapt())
        lbSetMicDisabled.titleLabel?.textAlignment = .center
        view.addSubview(lbSetMicDisabled)
        lbSetMicDisabled.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(16.screenAdapt())
            make.centerX.equalToSuperview()
            make.top.equalTo(ivSetMicDisabled.snp.bottom).offset(5.screenAdapt())
        }
        return view
    }()
    private lazy var setCameraDisabledView = {
        let view = UIView()
        view.addTarget(target: self, action: #selector(setCameraDisabled))
        // 点击事件交给父控件处理
        let ivSetCameraDisabled = UIButton()
        ivSetCameraDisabled.isUserInteractionEnabled = false
        ivSetCameraDisabled.setImage(UIImage(named: "conference_iv_set_camera_disabled_src"), for: .normal)
        view.addSubview(ivSetCameraDisabled)
        ivSetCameraDisabled.snp.makeConstraints { make in
            make.width.height.equalTo(30.screenAdapt())
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(8.screenAdapt())
        }
        // 点击事件交给父控件处理
        let lbSetCameraDisabled = UIButton()
        lbSetCameraDisabled.isUserInteractionEnabled = false
        lbSetCameraDisabled.setTitle("关闭视频", for: .normal)
        lbSetCameraDisabled.setTitleColor(.text_color_ffffffff, for: .normal)
        lbSetCameraDisabled.titleLabel?.font = .systemFont(ofSize: 13.screenAdapt())
        lbSetCameraDisabled.titleLabel?.textAlignment = .center
        view.addSubview(lbSetCameraDisabled)
        lbSetCameraDisabled.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(16.screenAdapt())
            make.centerX.equalToSuperview()
            make.top.equalTo(ivSetCameraDisabled.snp.bottom).offset(5.screenAdapt())
        }
        return view
    }()
    private lazy var presentationView = {
        let view = UIView()
        view.addTarget(target: self, action: #selector(showPresentationDialog))
        // 点击事件交给父控件处理
        let ivPresentation = UIButton()
        ivPresentation.isUserInteractionEnabled = false
        ivPresentation.setImage(UIImage(named: "conference_iv_presentation_src"), for: .normal)
        view.addSubview(ivPresentation)
        ivPresentation.snp.makeConstraints { make in
            make.width.height.equalTo(30.screenAdapt())
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(8.screenAdapt())
        }
        // 点击事件交给父控件处理
        let lbPresentation = UIButton()
        lbPresentation.isUserInteractionEnabled = false
        lbPresentation.setTitle("内容共享", for: .normal)
        lbPresentation.setTitleColor(.text_color_ffffffff, for: .normal)
        lbPresentation.titleLabel?.font = .systemFont(ofSize: 13.screenAdapt())
        lbPresentation.titleLabel?.textAlignment = .center
        view.addSubview(lbPresentation)
        lbPresentation.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(16.screenAdapt())
            make.centerX.equalToSuperview()
            make.top.equalTo(ivPresentation.snp.bottom).offset(5.screenAdapt())
        }
        return view
    }()
    private lazy var lbParticipants = {
        let label = UILabel()
        label.text = "参会人"
        label.textColor = .text_color_ffffffff
        label.font = .systemFont(ofSize: 13.screenAdapt())
        label.textAlignment = .center
        return label
    }()
    private lazy var bottomBarContainer = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.6)
        // 底部栏
        let bottomBar = UIStackView()
        bottomBar.distribution = .fillEqually
        view.addSubview(bottomBar)
        bottomBar.snp.makeConstraints { make in
            //            make.height.equalTo(64.screenAdapt() + NavigationBarUtil.getHeight())
            make.left.right.top.bottom.equalToSuperview()
        }
        // 关闭/开启麦克风
        bottomBar.addArrangedSubview(setMicDisabledView)
        // 关闭/开启摄像头
        bottomBar.addArrangedSubview(setCameraDisabledView)
        // 内容共享
        bottomBar.addArrangedSubview(presentationView)
        // 参会人
        let participantsView = UIView()
        participantsView.addTarget(target: self, action: #selector(showParticipantsDialog))
        bottomBar.addArrangedSubview(participantsView)
        let ivParticipants = UIImageView()
        ivParticipants.image = UIImage(named: "conference_iv_participants_src")
        participantsView.addSubview(ivParticipants)
        ivParticipants.snp.makeConstraints { make in
            make.width.height.equalTo(30.screenAdapt())
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(8.screenAdapt())
        }
        participantsView.addSubview(lbParticipants)
        lbParticipants.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(16.screenAdapt())
            make.centerX.equalToSuperview()
            make.top.equalTo(ivParticipants.snp.bottom).offset(5.screenAdapt())
        }
        // 更多
        let moreView = UIView()
        moreView.addTarget(target: self, action: #selector(showMoreDialog))
        bottomBar.addArrangedSubview(moreView)
        let ivMore = UIImageView()
        ivMore.image = UIImage(named: "conference_iv_more_src")
        moreView.addSubview(ivMore)
        ivMore.snp.makeConstraints { make in
            make.width.height.equalTo(30.screenAdapt())
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(8.screenAdapt())
        }
        let lbMore = UILabel()
        lbMore.text = "更多"
        lbMore.textColor = .text_color_ffffffff
        lbMore.font = .systemFont(ofSize: 13.screenAdapt())
        lbMore.textAlignment = .center
        moreView.addSubview(lbMore)
        lbMore.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(16.screenAdapt())
            make.centerX.equalToSuperview()
            make.top.equalTo(ivMore.snp.bottom).offset(5.screenAdapt())
        }
        return view
    }()
    private lazy var btnSwitchCamera = {
        let button = UIButton()
        button.setImage(UIImage(named: "conference_iv_switch_camera_src"), for: .normal)
        button.setImage(UIImage(named: "conference_iv_switch_camera_src_pressed"), for: .highlighted)
        button.addTarget(self, action: #selector(switchCamera))
        return button
    }()
    lazy var conferenceManager: ConferenceManager = {
        let builder = ConferenceManager.Builder()
        var url: URL?
        if (serverAddr.hasPrefix("http")) {
            url = URL(string: serverAddr)
        } else {
            url = URL(string: "https://\(serverAddr)")
        }
        if let scheme = url?.scheme {
            builder.setScheme(scheme)
        }
        if let host = url?.host {
            builder.setHost(host)
        }
        if let port = url?.port {
            builder.setPort(port)
        }
//        if let userInfo = UserDefaults.standard.string(forKey: UserDefaultsKey.USER_INFO), let data = userInfo.data(using: .utf8)  {
//            if let loginResultsBean = try? JSONDecoder().decode(LoginResultsBean.self, from: data), let account = loginResultsBean.account {
//                builder.setAccount(account)
//            }
//        }
//        if let groupId = ConfigUtil.getGroupId() {
//            builder.setGroupId(groupId)
//        }
//        builder.setUpdateBandwidthAfterAck(false)
//        builder.setLogLevel(.none)
        conferenceManager = builder.build()
        conferenceManager.setOnConferenceListener(self)
        return conferenceManager
    }()
    private var pictureInPicture = true
    
    // 重现statusBar相关方法
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        guard #available(iOS 13.0, *) else {
            return .default
        }
        return .default
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        // 隐藏系统默认导航栏
        navigationController?.setNavigationBarHidden(true, animated: false)
        // 初始化 contentView
        self.view.addSubview(contentView)
        // 系统默认会给 autoresizing 约束，关闭 autoresizing
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.superview?.addConstraints([
            NSLayoutConstraint(item: contentView, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 0)
            , NSLayoutConstraint(item: contentView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 0)
            , NSLayoutConstraint(item: contentView, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: 0)
            , NSLayoutConstraint(item: contentView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: 0)
        ])
        initView()
        setListener()
        initData()
    }
    
    init(serverAddr: String
         , conferenceRoomNum: String
         , pwd: String?
         , name: String
         , micEnable: Bool
         , cameraEnable: Bool) {
        self.serverAddr = serverAddr
        self.conferenceRoomNum = conferenceRoomNum
        self.pwd = pwd
        self.name = name
        self.micEnable = cameraEnable
        self.cameraEnable = cameraEnable
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // 关闭自动锁屏
        UIApplication.shared.isIdleTimerDisabled = true
        // 关闭侧滑关闭手势
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        // 切到横屏
        (UIApplication.shared.delegate as? AppDelegate)?.interfaceOrientationMask = UIInterfaceOrientationMask.landscape
        // 切到横屏
        if #available(iOS 16.0, *) {
            setNeedsUpdateOfSupportedInterfaceOrientations()
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                return
            }
            let geometryPreferencesIOS = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscape)
            windowScene.requestGeometryUpdate(geometryPreferencesIOS)
        } else {
            // 为啥这里是反的呀？
            var orientation = UIInterfaceOrientation.landscapeLeft.rawValue
            if (UIDevice.current.orientation == .landscapeLeft) {
                orientation = UIInterfaceOrientation.landscapeRight.rawValue
            } else if (UIDevice.current.orientation == .landscapeRight) {
                orientation = UIInterfaceOrientation.landscapeLeft.rawValue
            }
            UIDevice.current.setValue(orientation, forKey: "orientation")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // 恢复自动锁屏
        UIApplication.shared.isIdleTimerDisabled = false
        // 恢复侧滑关闭手势
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        // 切回竖屏
        (UIApplication.shared.delegate as? AppDelegate)?.interfaceOrientationMask = UIInterfaceOrientationMask.portrait
        // 切回竖屏
        if #available(iOS 16.0, *) {
            setNeedsUpdateOfSupportedInterfaceOrientations()
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                return
            }
            windowScene.requestGeometryUpdate(UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscapeLeft))
            windowScene.requestGeometryUpdate(UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait))
        } else {
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        }
    }
    
    func initView() {
        PermissionUtil.request(permissionTypes: .AUDIO_RECORD, .CAMERA, success: {
        }, failure: { permisstionTypes in
        })
        contentView.backgroundColor = UIColor(red: 19/255, green: 19/255, blue: 19/255, alpha: 1.0)
        for v in pageViewController.view.subviews {
            if (v is UIScrollView) {
                // 代理 UIPageViewController 的 UIScrollView，处理第一个页卡和最后一个页卡的果冻回弹效果
                (v as! UIScrollView).delegate = self
            }
        }
        pageViewController.delegate = self
        pageViewController.dataSource = self
        addChild(pageViewController)
        contentView.addSubview(pageViewController.view)
        pageViewController.view.snp.makeConstraints { make in
            make.left.top.right.bottom.equalToSuperview()
        }
        viewControllers.append(ConferenceDemoDefaultViewController())
        pageViewController.setViewControllers([viewControllers.first!], direction: .forward, animated: false)
        // 标题栏
        contentView.addSubview(titleBarContainer)
        titleBarContainer.snp.makeConstraints { make in
            make.height.equalTo(54.screenAdapt())
            make.left.top.right.equalToSuperview()
        }
        // 底部栏
        contentView.addSubview(bottomBarContainer)
        bottomBarContainer.snp.makeConstraints { make in
            make.height.equalTo(64.screenAdapt())
            make.left.right.bottom.equalToSuperview()
        }
        // 翻转摄像头
        contentView.addSubview(btnSwitchCamera)
        btnSwitchCamera.snp.makeConstraints { make in
            make.width.height.equalTo(32.screenAdapt())
            make.left.equalToSuperview().offset(15.screenAdapt())
            make.top.equalToSuperview().offset(56.screenAdapt() + 60.screenAdapt())
        }
    }
    
    func setListener() {
        // 点击空白处，隐藏功能区
        contentView.addTarget(target: self, action: #selector(showTitleBarAndBottomBar))
    }
    
    func initData() {
        lbConferenceRoomNum.text = "(\(conferenceRoomNum))"
        conferenceManager.join(conferenceRoomNum: conferenceRoomNum
                               , pwd: pwd ?? ""
                               , name: name)
    }
    
    private func toast(text: String, duration: Duration = .short) {
        if (Thread.current.isMainThread) {
            Toast.makeText(parent: view, text: text).show()
        } else {
            DispatchQueue.main.async {
                Toast.makeText(parent: self.view, text: text).show()
            }
        }
    }
    
    private func showLoadingUI() {
        if (Thread.current.isMainThread) {
            // 背景变暗
            loadingBackgroundView.frame = view.frame
            loadingBackgroundView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.16)
            view.addSubview(loadingBackgroundView)
            // 小菊花
            loadingView.frame.size = CGSize(width: 100.screenAdapt(), height: 100.screenAdapt())
            loadingView.center = view.center
            loadingView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
            loadingView.layer.cornerRadius = 8.screenAdapt()
            loadingView.color = .white
            loadingView.style = .whiteLarge
            loadingView.startAnimating()
            view.addSubview(loadingView)
        } else {
            DispatchQueue.main.async {
//                // 背景变暗
                self.loadingBackgroundView.frame = self.view.frame
                self.loadingBackgroundView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.16)
                self.view.addSubview(self.loadingBackgroundView)
                // 小菊花
                self.loadingView.frame.size = CGSize(width: 100.screenAdapt(), height: 100.screenAdapt())
                self.loadingView.center = self.view.center
                self.loadingView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
                self.loadingView.layer.cornerRadius = 8.screenAdapt()
                self.loadingView.color = .white
                self.loadingView.style = .whiteLarge
                self.loadingView.startAnimating()
                self.view.addSubview(self.loadingView)
            }
        }
    }
    
    private func hideLoadingUI() {
        if (Thread.current.isMainThread) {
            loadingView.removeFromSuperview()
            loadingBackgroundView.removeFromSuperview()
        } else {
            DispatchQueue.main.async {
                self.loadingView.stopAnimating()
                self.loadingView.removeFromSuperview()
                self.loadingBackgroundView.removeFromSuperview()
            }
        }
    }
    
    private func hideTitleBarAndBottomBar() {
        // 标题栏
        titleBarContainer.isHidden = true
        // 底部栏
        bottomBarContainer.isHidden = true
        // 翻转摄像头按钮
        btnSwitchCamera.isHidden = true
    }
    
    @objc private func showTitleBarAndBottomBar() {
        if (!titleBarContainer.isHidden || !bottomBarContainer.isHidden || !btnSwitchCamera.isHidden) {
            hideTitleBarAndBottomBar()
            return
        }
        // 标题栏
        titleBarContainer.isHidden = false
        // 底部栏
        bottomBarContainer.isHidden = false
        // 翻转摄像头按钮
        btnSwitchCamera.isHidden = false
    }
    
    @objc private func quit() {
        CommonDialog(title: nil, message: "您确定想离开会议吗？"
                     , negativeButtonTextColor: .text_color_ff666666
                     , positiveButtonHandler: { [weak self] _ in
            guard let self = self else { return }
            self.conferenceManager.quit()
            self.navigationController?.popViewController(animated: true)
        }).show(uiViewController: self)
    }
    
    @objc private func switchCamera() {
        conferenceManager.getRTCManager()?.switchCamera()
        if (viewControllers.count > curPosition) {
            (viewControllers[curPosition] as? ConferenceChildViewController)?.onLayout(conferenceManager: conferenceManager, layoutBeans: conferenceManager.getCurrentLayout() ?? [])
        }
    }
    
    @objc private func setMicDisabled() {
        if (!PermissionType.AUDIO_RECORD.permissionChecker.isAuthorized()) {
            let message = "麦克风被禁用，请在本机的“设置”—“隐私”—“麦克风”中允许\(AppUtil.getAppName() ?? "")访问您的麦克风"
            CommonDialog(title: nil, message: message, negativeButtonText: "暂不", positiveButtonText: "去设置", positiveButtonHandler: { UIAlertAction in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:])
                }
            }).show(uiViewController: self)
            return
        }
        let myParticipantBean = conferenceManager.getParticipantBeans().first { participantBean in
            return participantBean.uuid == conferenceManager.getParticipantUUID()
        }
        guard let myParticipantBean = myParticipantBean else {
            return
        }
        if (myParticipantBean.isServerMuted()) {
            // 被服务端静音
            if let conferenceStatusBean = conferenceManager.getConferenceStatus() {
                if (!myParticipantBean.isHost() && !conferenceStatusBean.isAllowUnmuteSelf()) {
                    // 不是主持人，且不允许自己解除静音时，return
                    return
                }
            }
        }
        guard let micEnabled = conferenceManager.getRTCManager()?.isMicEnabled() else {
            return
        }
        guard let setMicEnabled = conferenceManager.getRTCManager()?.setMicEnabled(enabled: !micEnabled) else {
            return
        }
        if (!setMicEnabled) {
            return
        }
        if (conferenceManager.getRTCManager()?.isMicEnabled() == true) {
            if setMicDisabledView.subviews.count == 2
                , let ivSetMicDisabled = setMicDisabledView.subviews[0] as? UIButton
                , let lbSetMicDisabled = setMicDisabledView.subviews[1] as? UIButton {
                ivSetMicDisabled.setImage(UIImage(named: "conference_iv_set_mic_disabled_src"), for: .normal)
                lbSetMicDisabled.setTitle("静音", for: .normal)
            }
        } else {
            if setMicDisabledView.subviews.count == 2
                , let ivSetMicDisabled = setMicDisabledView.subviews[0] as? UIButton
                , let lbSetMicDisabled = setMicDisabledView.subviews[1] as? UIButton {
                ivSetMicDisabled.setImage(UIImage(named: "conference_iv_set_mic_disabled_src_selected"), for: .normal)
                lbSetMicDisabled.setTitle("解除静音", for: .normal)
            }
        }
    }
    
    @objc private func setCameraDisabled() {
        if (!PermissionType.CAMERA.permissionChecker.isAuthorized()) {
            let message = "相机被禁用，请在本机的“设置”—“隐私”—“相机”中允许\(AppUtil.getAppName() ?? "")访问您的相机"
            CommonDialog(title: nil, message: message, negativeButtonText: "暂不", positiveButtonText: "去设置", positiveButtonHandler: { UIAlertAction in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:])
                }
            }).show(uiViewController: self)
            return
        }
        let myParticipantBean = self.conferenceManager.getParticipantBeans().first { participantBean in
            return participantBean.uuid == self.conferenceManager.getParticipantUUID()
        }
        guard let myParticipantBean = myParticipantBean else {
            return
        }
        if (myParticipantBean.isServerVideoMuted()) {
            toast(text: "开启失败，主持人已禁止您开启视频")
            return
        }
        guard let cameraEnabled = self.conferenceManager.getRTCManager()?.isCameraEnabled() else {
            return
        }
        guard let setCameraEnabled = self.conferenceManager.getRTCManager()?.setCameraEnabled(enabled: !cameraEnabled) else {
            return
        }
        if (!setCameraEnabled) {
            return
        }
        if self.setCameraDisabledView.subviews.count == 2
            , let ivSetCameraDisabled = self.setCameraDisabledView.subviews[0] as? UIButton
            , let lbSetCameraDisabled = self.setCameraDisabledView.subviews[1] as? UIButton {
            if (self.conferenceManager.getRTCManager()?.isCameraEnabled() == true) {
                ivSetCameraDisabled.setImage(UIImage(named: "conference_iv_set_camera_disabled_src"), for: .normal)
                lbSetCameraDisabled.setTitle("关闭视频", for: .normal)
            } else {
                ivSetCameraDisabled.setImage(UIImage(named: "conference_iv_set_camera_disabled_src_selected"), for: .normal)
                lbSetCameraDisabled.setTitle("开启视频", for: .normal)
                // 发送摄像头关闭图片
                if let image = UIImage(named: "conference_iv_camera_disabled_src") {
                    self.conferenceManager.getRTCManager()?.startImageCapture(image)
                }
            }
            if (viewControllers.count > curPosition) {
                (viewControllers[curPosition] as? ConferenceChildViewController)?.onLayout(conferenceManager: conferenceManager, layoutBeans: conferenceManager.getCurrentLayout() ?? [])
            }
        }
    }
    
    @objc private func showPresentationDialog() {
        if presentationView.subviews.count == 2
            , let ivPresentation = presentationView.subviews[0] as? UIButton
            , let lbPresentation = presentationView.subviews[1] as? UIButton {
            if ("停止共享" == lbPresentation.title(for: .normal)) {
                stopPresent()
                return
            }
        }
        VerticalListDialog(items: [
            (text: "照片", textColor: nil, handler: {  [weak self] alertAction in
                guard let self = self else { return }
                self.presentImg()
            }), (text: "屏幕", textColor: nil, handler: { [weak self] alertAction in
                guard let self = self else { return }
                self.presentScreen()
//            }), (text: "白板", textColor: nil, handler: { [weak self] alertAction in
//                guard let self = self else { return }
//                self.presentWhiteboard()
            }), (text: "iCloud", textColor: nil, handler: { [weak self] alertAction in
                guard let self = self else { return }
                self.presentICloud()
            })
        ]).show(viewController: self)
    }
    
    private func stopPresent() {
        conferenceManager.getPresentationManager()?.stop()
        for viewController in viewControllers {
            viewController.removeFromParent()
        }
        viewControllers.removeAll()
        viewControllers.append(ConferenceDemoDefaultViewController())
        curPosition = 0
        pageViewController.setViewControllers([viewControllers[curPosition]], direction: .forward, animated: false)
        (viewControllers[curPosition] as? ConferenceChildViewController)?.onLayout(conferenceManager: conferenceManager, layoutBeans: conferenceManager.getCurrentLayout())
        if presentationView.subviews.count == 2
            , let ivPresentation = presentationView.subviews[0] as? UIButton
            , let lbPresentation = presentationView.subviews[1] as? UIButton {
            ivPresentation.setImage(UIImage(named: "conference_iv_presentation_src"), for: .normal)
            lbPresentation.setTitle("内容共享", for: .normal)
        }
    }
    
    private func presentImg() {
        guard let tzImagePickerController = TZImagePickerController(maxImagesCount: 3, columnNumber: 3, delegate: self, pushPhotoPickerVc: true) else {
            return
        }
        tzImagePickerController.allowPickingOriginalPhoto = false
        tzImagePickerController.allowPickingVideo = false
        tzImagePickerController.modalPresentationStyle = .overFullScreen
        self.navigationController?.present(tzImagePickerController, animated: true)
    }
    
    private func doPresentImg(_ uiImages: [UIImage]) {
        if (uiImages.count <= 0) {
            return
        }
        showLoadingUI()
        Thread { [weak self] in
            guard let self = self else { return }
            var imgs = [UIImage]()
            for i in 0..<uiImages.count {
                let photo = uiImages[i]
                // 分享的图片尺寸为 1280*720
                let targetSize = CGSize(width: 1280, height: 720)
                // 获取照片原始宽高
                let photoSize = photo.size
                // 计算缩放比
                let scale = min(targetSize.width / photoSize.width, targetSize.height / photoSize.height)
                let scaledSize = CGSize(width: photoSize.width * scale, height: photoSize.height * scale)
                let renderer = UIGraphicsImageRenderer(size: targetSize)
                var uiImage = renderer.image { context in
                    // 绘制白色背景
                    UIColor.white.setFill()
                    context.cgContext.fill(CGRect(origin: .zero, size: targetSize))
                    // 绘制照片内容
                    let origin = CGPoint(x: (targetSize.width - scaledSize.width) / 2, y: (targetSize.height - scaledSize.height) / 2)
                    photo.draw(in: CGRect(origin: origin, size: scaledSize))
                }
                // 压缩
                if let data = uiImage.compressImageToTargetSize(targetSize: 1024 * 1024 * 2),
                   let compress = UIImage(data: data) {
                    uiImage = compress
                }
                imgs.append(uiImage)
            }
            self.conferenceManager.getPresentationManager()?.startImageCapture(uiImage: imgs[0], onSuccess: { [weak self] in
                MyShowLogger.instance.showLogger.info("图片分享成功。")
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    for viewController in self.viewControllers {
                        viewController.removeFromParent()
                    }
                    self.viewControllers.removeAll()
                    self.viewControllers.append(ConferenceDemoPresentImgViewController(imgs: imgs))
                    self.curPosition = 0
                    self.pageViewController.setViewControllers([self.viewControllers[self.curPosition]], direction: .forward, animated: false)
                    (self.viewControllers[self.curPosition] as? ConferenceChildViewController)?.onLayout(conferenceManager: self.conferenceManager, layoutBeans: self.conferenceManager.getCurrentLayout() ?? [])
                    if self.presentationView.subviews.count == 2
                        , let ivPresentation = self.presentationView.subviews[0] as? UIButton
                        , let lbPresentation = self.presentationView.subviews[1] as? UIButton {
                        ivPresentation.setImage(UIImage(named: "conference_iv_presentation_src_selected"), for: .normal)
                        lbPresentation.setTitle("停止共享", for: .normal)
                    }
                    self.hideLoadingUI()
                }
            }, onFailure: { [weak self] error in
                MyShowLogger.instance.showLogger.info("图片分享失败，e--->\(error)")
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.toast(text: "图片分享失败")
                    self.hideLoadingUI()
                }
            })
        }.start()
    }
    
    private func presentScreen() {
        //        showLoadingUI()
//        conferenceManager.getPresentationManager()?.startScreenCapture(preferredExtension: ConfigUtil.getPreferredExtension() ?? "", onSuccess: { [weak self] in
//            MyShowLogger.instance.showLogger.info("startScreenCapture success")
//            DispatchQueue.main.async { [weak self] in
//                guard let self = self else { return }
//                for viewController in self.viewControllers {
//                    viewController.removeFromParent()
//                }
//                self.viewControllers.removeAll()
//                self.viewControllers.append(ConferencePresentScreenViewController())
//                self.curPosition = 0
//                self.pageViewController.setViewControllers([self.viewControllers[self.curPosition]], direction: .forward, animated: false)
//                if self.presentationView.subviews.count == 2
//                    , let ivPresentation = self.presentationView.subviews[0] as? UIButton
//                    , let lbPresentation = self.presentationView.subviews[1] as? UIButton {
//                    ivPresentation.setImage(UIImage(named: "conference_iv_presentation_src_selected"), for: .normal)
//                    lbPresentation.setTitle("停止共享", for: .normal)
//                }
//                self.setPageViewControllerScrollEnabled(false)
//                self.orientationChange2Landscape()
//                // 返回桌面
//                let toBackgroundControl = UIControl()
//                toBackgroundControl.sendAction(#selector(NSXPCConnection.suspend), to: UIApplication.shared, for: nil)
//                self.hideLoadingUI()
//            }
//        }, onFailure: { [weak self] error in
//            MyShowLogger.instance.showLogger.info("startScreenCapture failure")
//            DispatchQueue.main.async { [weak self] in
//                guard let self = self else { return }
//                self.hideLoadingUI()
//            }
//        })
    }
    
    private func presentWhiteboard() {
        showLoadingUI()
        Thread { [weak self] in
            guard let self = self else { return }
            var uiImage: UIImage?
            let cachePaths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
            var path: String?
            if (cachePaths.count > 0) {
                path = "\(cachePaths[0])/whiteboard.png"
            }
            if (FileManager.default.fileExists(atPath: path ?? "")) {
                uiImage = UIImage(contentsOfFile: path!)
            } else {
                let rect = CGRect(x: 0, y: 0, width: 1280, height: 720)
                UIGraphicsBeginImageContext(rect.size)
                let context = UIGraphicsGetCurrentContext()
                context?.setFillColor(UIColor.white.cgColor)
                context?.fill(rect)
                uiImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                // 压缩
                if let data = uiImage?.jpegData(compressionQuality: 0.2), let compress = UIImage(data: data) {
                    let url = URL(fileURLWithPath: path ?? "")
                    try? data.write(to: url)
                    uiImage = compress
                }
            }
            guard let uiImage = uiImage else {
                MyShowLogger.instance.showLogger.info("白板分享失败，创建图片失败。")
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.hideLoadingUI()
                }
                return
            }
            self.conferenceManager.getPresentationManager()?.startWhiteboardCapture(uiImage: uiImage, onSuccess: { [weak self] in
                MyShowLogger.instance.showLogger.info("白板分享成功。")
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    for viewController in self.viewControllers {
                        viewController.removeFromParent()
                    }
                    self.viewControllers.removeAll()
                    self.viewControllers.append(ConferenceDemoPresentImgViewController(imgs: [uiImage]))
                    self.curPosition = 0
                    self.pageViewController.setViewControllers([self.viewControllers[self.curPosition]], direction: .forward, animated: false)
                    if self.presentationView.subviews.count == 2
                        , let ivPresentation = self.presentationView.subviews[0] as? UIButton
                        , let lbPresentation = self.presentationView.subviews[1] as? UIButton {
                        ivPresentation.setImage(UIImage(named: "conference_iv_presentation_src_selected"), for: .normal)
                        lbPresentation.setTitle("停止共享", for: .normal)
                    }
                    self.hideLoadingUI()
                }
            }, onFailure: { [weak self] error in
                MyShowLogger.instance.showLogger.info("白板分享失败，e--->\(error)")
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.toast(text: "白板分享失败")
                    self.hideLoadingUI()
                }
            })
        }.start()
    }
    
    private func presentICloud() {
        let documentPickerViewController = UIDocumentPickerViewController(documentTypes: ["public.image", "com.adobe.pdf"], in: .import)
        documentPickerViewController.delegate = self
        documentPickerViewController.modalPresentationStyle = .formSheet
        self.navigationController?.present(documentPickerViewController, animated: true)
    }
    
    private func doPresentICloud(_ urls: [URL]) {
        if (urls.count <= 0) {
            return
        }
        showLoadingUI()
        Thread { [weak self] in
            guard let self = self else { return }
            let url = urls[0]
            url.startAccessingSecurityScopedResource()
            let fileCoordinator = NSFileCoordinator()
            var error: NSError?
            fileCoordinator.coordinate(readingItemAt: url, options: .resolvesSymbolicLink, error: &error) { url in
                guard let fileType = url.lastPathComponent.split(separator: ".").last else {
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.hideLoadingUI()
                    }
                    return
                }
                MyShowLogger.instance.showLogger.info("fileType--->\(fileType)")
                if (fileType.lowercased() == "pdf") {
                    guard let pdfDocument = PDFDocument(url: url) else {
                        MyShowLogger.instance.showLogger.info("pdf 分享失败，pdf is nil.")
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            self.hideLoadingUI()
                        }
                        return
                    }
                    guard pdfDocument.pageCount > 0 else {
                        MyShowLogger.instance.showLogger.info("pdf 分享失败，pageCount count is zero.")
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            self.hideLoadingUI()
                        }
                        return
                    }
                    var imgs = [UIImage]()
                    for i in 0..<pdfDocument.pageCount {
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
                        imgs.append(uiImage)
                        break
                    }
                    self.conferenceManager.getPresentationManager()?.startImageCapture(uiImage: imgs[0], onSuccess: { [weak self] in
                        MyShowLogger.instance.showLogger.info("pdf 分享成功。")
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            for viewController in self.viewControllers {
                                viewController.removeFromParent()
                            }
                            self.viewControllers.removeAll()
                            self.viewControllers.append(ConferenceDemoPresentPDFViewController(url: url))
                            self.curPosition = 0
                            self.pageViewController.setViewControllers([self.viewControllers[self.curPosition]], direction: .forward, animated: false)
                            if self.presentationView.subviews.count == 2
                                , let ivPresentation = self.presentationView.subviews[0] as? UIButton
                                , let lbPresentation = self.presentationView.subviews[1] as? UIButton {
                                ivPresentation.setImage(UIImage(named: "conference_iv_presentation_src_selected"), for: .normal)
                                lbPresentation.setTitle("停止共享", for: .normal)
                            }
                            self.hideLoadingUI()
                        }
                    }, onFailure: { [weak self] error in
                        MyShowLogger.instance.showLogger.info("pdf 分享失败，e--->\(error)")
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            self.toast(text: "pdf 分享失败")
                            self.hideLoadingUI()
                        }
                    })
                } else if (fileType.lowercased() == "jpg" || fileType.lowercased() == "jpeg" || fileType.lowercased() == "png") {
                    do {
                        let data = try Data(contentsOf: url)
                        guard let image = UIImage(data: data) else {
                            MyShowLogger.instance.showLogger.info("图片分享失败，img is nil.")
                            DispatchQueue.main.async { [weak self] in
                                guard let self = self else { return }
                                self.hideLoadingUI()
                            }
                            return
                        }
                        var imgs = [UIImage]()
                        // 分享的图片尺寸为 1280*720
                        let targetSize = CGSize(width: 1280, height: 720)
                        // 获取照片原始宽高
                        let photoSize = image.size
                        // 计算缩放比
                        let scale = min(targetSize.width / photoSize.width, targetSize.height / photoSize.height)
                        let scaledSize = CGSize(width: photoSize.width * scale, height: photoSize.height * scale)
                        let renderer = UIGraphicsImageRenderer(size: targetSize)
                        var uiImage = renderer.image { context in
                            // 绘制白色背景
                            UIColor.white.setFill()
                            context.cgContext.fill(CGRect(origin: .zero, size: targetSize))
                            // 绘制照片内容
                            let origin = CGPoint(x: (targetSize.width - scaledSize.width) / 2, y: (targetSize.height - scaledSize.height) / 2)
                            image.draw(in: CGRect(origin: origin, size: scaledSize))
                        }
                        // 压缩
                        if let data = uiImage.compressImageToTargetSize(targetSize: 1024 * 1024 * 2),
                           let compress = UIImage(data: data) {
                            uiImage = compress
                        }
                        imgs.append(uiImage)
                        self.conferenceManager.getPresentationManager()?.startImageCapture(uiImage: imgs[0], onSuccess: { [weak self] in
                            MyShowLogger.instance.showLogger.info("图片分享成功。")
                            DispatchQueue.main.async { [weak self] in
                                guard let self = self else { return }
                                for viewController in self.viewControllers {
                                    viewController.removeFromParent()
                                }
                                self.viewControllers.removeAll()
                                self.viewControllers.append(ConferenceDemoPresentImgViewController(imgs: imgs))
                                self.curPosition = 0
                                self.pageViewController.setViewControllers([self.viewControllers[self.curPosition]], direction: .forward, animated: false)
                                if self.presentationView.subviews.count == 2
                                    , let ivPresentation = self.presentationView.subviews[0] as? UIButton
                                    , let lbPresentation = self.presentationView.subviews[1] as? UIButton {
                                    ivPresentation.setImage(UIImage(named: "conference_iv_presentation_src_selected"), for: .normal)
                                    lbPresentation.setTitle("停止共享", for: .normal)
                                }
                                self.hideLoadingUI()
                            }
                        }, onFailure: { [weak self] error in
                            MyShowLogger.instance.showLogger.info("图片分享失败，e--->\(error)")
                            DispatchQueue.main.async { [weak self] in
                                guard let self = self else { return }
                                self.toast(text: "图片分享失败")
                                self.hideLoadingUI()
                            }
                        })
                    } catch {
                        
                    }
                }
            }
            url.stopAccessingSecurityScopedResource()
        }.start()
    }
    
    @objc private func showParticipantsDialog() {
    }
    
    @objc private func showMoreDialog() {
        VerticalListDialog(items: [
            (text: pictureInPicture ? "关闭画中画" : "开启画中画", textColor: nil, handler: {  [weak self] alertAction in
                guard let self = self else { return }
                setPictureInPicture(!pictureInPicture)
            })
        ]).show(viewController: self)
    }
    
    func isPictureInPicture() -> Bool {
        return pictureInPicture
    }
    
    func setPictureInPicture(_ pictureInPicture: Bool) {
        self.pictureInPicture = pictureInPicture
        if (viewControllers.count > curPosition) {
            (viewControllers[curPosition] as? ConferenceChildViewController)?.onPictureInPictureUpdate(pictureInPicture)
        }
    }

}

// MARK: - OnConferenceListener
extension ConferenceDemoViewController: OnConferenceListener {
    
    private func initMicEnable() {
        if (micEnable) {
            return
        }
        guard let setMicEnabled = self.conferenceManager.getRTCManager()?.setMicEnabled(enabled: false) else {
            return
        }
        if (!setMicEnabled) {
            return
        }
        if (self.conferenceManager.getRTCManager()?.isMicEnabled() == true) {
            if self.setMicDisabledView.subviews.count == 2
                , let ivSetMicDisabled = self.setMicDisabledView.subviews[0] as? UIButton
                , let lbSetMicDisabled = self.setMicDisabledView.subviews[1] as? UIButton {
                ivSetMicDisabled.setImage(UIImage(named: "conference_iv_set_mic_disabled_src"), for: .normal)
                lbSetMicDisabled.setTitle("静音", for: .normal)
            }
        } else {
            if self.setMicDisabledView.subviews.count == 2
                , let ivSetMicDisabled = self.setMicDisabledView.subviews[0] as? UIButton
                , let lbSetMicDisabled = self.setMicDisabledView.subviews[1] as? UIButton {
                ivSetMicDisabled.setImage(UIImage(named: "conference_iv_set_mic_disabled_src_selected"), for: .normal)
                lbSetMicDisabled.setTitle("解除静音", for: .normal)
            }
        }
    }
    
    private func initCameraEnable() {
        if (cameraEnable) {
            return
        }
        guard let setCameraEnabled = self.conferenceManager.getRTCManager()?.setCameraEnabled(enabled: false) else {
            return
        }
        if (!setCameraEnabled) {
            return
        }
        if self.setCameraDisabledView.subviews.count == 2
            , let ivSetCameraDisabled = self.setCameraDisabledView.subviews[0] as? UIButton
            , let lbSetCameraDisabled = self.setCameraDisabledView.subviews[1] as? UIButton {
            if (self.conferenceManager.getRTCManager()?.isCameraEnabled() == true) {
                ivSetCameraDisabled.setImage(UIImage(named: "conference_iv_set_camera_disabled_src"), for: .normal)
                lbSetCameraDisabled.setTitle("关闭视频", for: .normal)
            } else {
                ivSetCameraDisabled.setImage(UIImage(named: "conference_iv_set_camera_disabled_src_selected"), for: .normal)
                lbSetCameraDisabled.setTitle("开启视频", for: .normal)
                // 发送摄像头关闭图片
                if let image = UIImage(named: "conference_iv_camera_disabled_src") {
                    self.conferenceManager.getRTCManager()?.startImageCapture(image)
                }
            }
            (self.viewControllers[self.curPosition] as? ConferenceChildViewController)?.onLayout(conferenceManager: self.conferenceManager, layoutBeans: self.conferenceManager.getCurrentLayout() ?? [])
        }
    }
    
    private func inviteParticipants() {
    }
    
    func dismissAllPresentedViewControllers(completion: (() -> Void)?) {
        if let presentedViewController = self.presentedViewController {
            presentedViewController.dismiss(animated: false) {
                self.dismissAllPresentedViewControllers(completion: completion)
            }
        } else {
            completion?()
        }
    }
    
    func onConnected() {
        MyShowLogger.instance.showLogger.info("onConnected")
    }
    
    func onCallSuccess() {
        MyShowLogger.instance.showLogger.info("onCallSuccess")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.initMicEnable()
            self.initCameraEnable()
            self.inviteParticipants()
        }
    }
    
    func onDisconnected(_ e: ViaZijingError?) {
        guard let e = e else {
            MyShowLogger.instance.showLogger.info("正常退出")
            return
        }
        MyShowLogger.instance.showLogger.error("onDisconnected, e--->\(e.msg)")
        conferenceManager.quit()
//        DispatchQueue.main.async { [weak self] in
//            guard let self = self else { return }
//            self.dismissAllPresentedViewControllers { [weak self] in
//                MyShowLogger.instance.showLogger.debug("退出会议界面")
//                guard let self = self else { return }
//                var message = "会议结束"
//                if (e.msg == "Call disconnected") {
//                    message = "被主持人移出会议。"
//                }
//                if (e.msg == "Disconnected by another participant") {
//                    message = "其他参会者将你踢出了会议室。"
//                }
//                if (e.msg == "1434/guest not allowed") {
//                    message = "禁止未登录用户入会。"
//                }
//                if (e.msg == "1402/up to meeting max calls") {
//                    message = "超过会议最大呼叫数。"
//                }
//                if (e.msg == "User initiated disconnect") {
//                    message = "主持人中断了会议。"
//                }
//                if (e.msg == "Timeout waiting for conference host to join or permit access to locked conference") {
//                    message = "主持人超时未处理，将自动退出等候室。"
//                }
//                if (e.msg == "Request failed: forbidden (403)") {
//                    message = "会议正在结束中"
//                }
//                if (e.msg == "1434/guest not allowed") {
//                    message = "不允许访客入会"
//                }
//                if (e.msg == "1402/up to meeting max calls") {
//                    message = "超过会议最大呼叫数"
//                }
//                if (e.msg == "1418/adhoc disabled") {
//                    message = "会议室只用于预约，即时呼叫失败"
//                }
//                if (e.msg == "与服务器连接超时") {
//                    message = "与服务器连接超时"
//                }
//                CommonDialog(title: nil, message: message, negativeButtonText: nil, positiveButtonHandler: { [weak self] _ in
//                    guard let self = self else { return }
//                    self.navigationController?.popViewController(animated: true)
//                })
//                .show(uiViewController: self, cancelable: false)
//            }
//        }
    }
    
    func onConferenceStatusUpdate(_ conferenceStatusBean: rtc.ConferenceStatusBean) {
        MyShowLogger.instance.showLogger.info("onConferenceStatusUpdate, conferenceStatusBean--->\(conferenceStatusBean)")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let conferenceTheme = conferenceStatusBean.conferenceTheme {
                self.lbTheme.text = conferenceTheme
            }
            if let conferenceRoomNum = conferenceStatusBean.conferenceRoomNum {
                self.lbConferenceRoomNum.text = "(\(conferenceRoomNum))"
            }
        }
    }
    
    func onStartPreview(layoutBean: LayoutBean) {
        MyShowLogger.instance.showLogger.info("onStartPreview")
        if (viewControllers.count > curPosition) {
            (viewControllers[curPosition] as? ConferenceChildViewController)?.onLayout(conferenceManager: conferenceManager, layoutBeans: [layoutBean])
        }
    }
    
    func onLayout(_ layoutBeans: [LayoutBean]) {
        MyShowLogger.instance.showLogger.info("onLayout, layoutBeans--->\(layoutBeans)")
        if (viewControllers.count > curPosition) {
            (viewControllers[curPosition] as? ConferenceChildViewController)?.onLayout(conferenceManager: conferenceManager, layoutBeans: layoutBeans)
        }
    }
    
    func onParticipantsUpdate(_ participantBeans: [rtc.ParticipantBean]) {
        MyShowLogger.instance.showLogger.info("onParticipantsUpdate, participantBeans--->\(participantBeans)")
        var participantBeans = participantBeans
        participantBeans = participantBeans.sorted { o1, o2 in
            // 自己排在第一个
            if (o1.uuid == conferenceManager.getParticipantUUID() && o2.uuid != conferenceManager.getParticipantUUID()) {
                return true
            }
            return false
        }
        let myParticipantBean = participantBeans.first { participantBean in
            return participantBean.uuid == conferenceManager.getParticipantUUID()
        }
        if let myParticipantBean = myParticipantBean {
            if (!myParticipantBean.isHost()) {
                // 访客身份，过滤等候室的参会人
                participantBeans = participantBeans.filter({ participantBean in
                    if (participantBean.isInWaitingRoom()) {
                        if (participantBean.uuid == conferenceManager.getParticipantUUID()) {
                            return true
                        } else {
                            return false
                        }
                    }
                    return true
                })
            }
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.lbParticipants.text = "参会人(\(participantBeans.count))"
        }
        viewControllers.forEach { viewController in
            (viewController as? ConferenceChildViewController)?.onParticipantsUpdate(conferenceManager: conferenceManager, participantBeans: participantBeans)
        }
    }
    
    func onPresentationStart(_ presentationStartBean: PresentationStartBean) {
        MyShowLogger.instance.showLogger.info("onPresentationStart， presentationStartBean--->\(presentationStartBean)")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.conferenceManager.getRTCManager()?.layout("0:1")
        }
    }
    
    func onPresentationStop() {
        MyShowLogger.instance.showLogger.info("onPresentationStop")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            for viewController in self.viewControllers {
                viewController.removeFromParent()
            }
            self.viewControllers.removeAll()
            self.viewControllers.append(ConferenceDemoDefaultViewController())
            self.curPosition = 0
            self.pageViewController.setViewControllers([self.viewControllers[self.curPosition]], direction: .forward, animated: false)
            let currentLayout = self.conferenceManager.getCurrentLayout()
            (self.viewControllers[self.curPosition] as? ConferenceChildViewController)?.onLayout(conferenceManager: conferenceManager, layoutBeans: currentLayout)
            if self.presentationView.subviews.count == 2
                , let ivPresentation = self.presentationView.subviews[0] as? UIButton
                , let lbPresentation = self.presentationView.subviews[1] as? UIButton {
                ivPresentation.setImage(UIImage(named: "conference_iv_presentation_src"), for: .normal)
                lbPresentation.setTitle("内容共享", for: .normal)
            }
            self.conferenceManager.getRTCManager()?.layout("1:5")
        }
    }
    
    func onScreenPresentationStop() {
        MyShowLogger.instance.showLogger.info("onScreenPresentationStop")
        for viewController in viewControllers {
            viewController.removeFromParent()
        }
        viewControllers.removeAll()
        viewControllers.append(ConferenceDemoDefaultViewController())
        curPosition = 0
        pageViewController.setViewControllers([viewControllers[curPosition]], direction: .forward, animated: false)
        let currentLayout = conferenceManager.getCurrentLayout()
        (viewControllers[curPosition] as? ConferenceChildViewController)?.onLayout(conferenceManager: conferenceManager, layoutBeans: currentLayout)
        if presentationView.subviews.count == 2
            , let ivPresentation = presentationView.subviews[0] as? UIButton
            , let lbPresentation = presentationView.subviews[1] as? UIButton {
            ivPresentation.setImage(UIImage(named: "conference_iv_presentation_src"), for: .normal)
            lbPresentation.setTitle("内容共享", for: .normal)
        }
        conferenceManager.getRTCManager()?.layout("1:5")
    }
    
    func onWhiteboardStart(_ whiteboardStartBean: WhiteboardStartBean) {
        MyShowLogger.instance.showLogger.info("onWhiteboardStart, whiteboardStartBean--->\(whiteboardStartBean)")
    }
    
    func onWhiteboardStop() {
        MyShowLogger.instance.showLogger.info("onWhiteboardStop")
    }
    
    func onWhiteboardAddLine(_ whiteboardAddLineBean: WhiteboardAddLineBean) {
        MyShowLogger.instance.showLogger.info("onWhiteboardAddLine, whiteboardAddLineBean--->\(whiteboardAddLineBean)")
    }
    
    func onWhiteboardDeleteLine(_ whiteboardDeleteLineBean: WhiteboardDeleteLineBean) {
        MyShowLogger.instance.showLogger.info("onWhiteboardDeleteLine, whiteboardDeleteLineBean--->\(whiteboardDeleteLineBean)")
    }
    
    func onWhiteboardMarkPermissionChanged(_ isWhiteboardAllowOtherMark: Bool, screenShare: Int?) {
        MyShowLogger.instance.showLogger.info("onWhiteboardMarkPermissionChanged, isWhiteboardAllowOtherMark--->\(isWhiteboardAllowOtherMark)")
    }
    
    func onWhiteboardClearLine() {
        MyShowLogger.instance.showLogger.info("onWhiteboardClearLine")
    }
    
    func onWhiteboardBackgroundUpdate(_ url: String) {
        MyShowLogger.instance.showLogger.info("onWhiteboardBackgroundUpdate: url--->\(url)")
    }
    
    func onChatPermissionChanged(_ chatPermission: ChatPermission) {
        MyShowLogger.instance.showLogger.info("onChatPermissionChanged, chatPermission--->\(chatPermission)")
    }
    
    func onLivingChatPermissionChanged(_ livingChatPermission: LivingChatPermission) {
        MyShowLogger.instance.showLogger.info("onLivingChatPermissionChanged, livingChatPermission--->\(livingChatPermission)")
    }
    
    func onForceMCULayoutChanged(_ forceMCULayout: Bool) {
        MyShowLogger.instance.showLogger.info("onForceMCULayoutChanged, forceMCULayout--->\(forceMCULayout)")
    }
    
    func onMessage(_ msgBean: MsgBean) {
        MyShowLogger.instance.showLogger.info("onMessage, msgBean--->\(msgBean)")
    }
    
    func onSubtitle(_ msgBean: MsgBean) {
        MyShowLogger.instance.showLogger.info("onSubtitle, msgBean--->\(msgBean)")
    }
    
    func onServerAudioMuteChanged(_ myParticipantBean: ParticipantBean) {
        MyShowLogger.instance.showLogger.info("onServerAudioMuteChanged, myParticipantBean--->\(myParticipantBean)")
    }
    
    func onNotifyOpenAudio() {
        MyShowLogger.instance.showLogger.info("onNotifyOpenAudio")
    }
    
    func onServerVideoMuteChanged(_ myParticipantBean: ParticipantBean) {
        MyShowLogger.instance.showLogger.info("onServerVideoMuteChanged, myParticipantBean--->\(myParticipantBean)")
    }
    
    func onAllowRaiseHand() {
        MyShowLogger.instance.showLogger.info("onAllowRaiseHand")
    }
    
    func onRejectRaiseHand() {
        MyShowLogger.instance.showLogger.info("onRejectRaiseHand")
    }
    
    func onCancelSelectSee(_ selectSeeUUID: String) {
        MyShowLogger.instance.showLogger.info("onCancelSelectSee, selectSeeUUID--->\(selectSeeUUID)")
    }
}

// MARK: - UIScrollViewDelegate
extension ConferenceDemoViewController: UIScrollViewDelegate {
    
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
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // 先禁止滑动，防止滑动过快
        for v in pageViewController.view.subviews {
            if (v is UIScrollView) {
                (v as! UIScrollView).isScrollEnabled = false
            }
        }
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] timer in
            guard let self = self else { return }
            if let forceMcuLayout = self.conferenceManager.getConferenceStatus()?.forceMcuLayout {
                for v in self.pageViewController.view.subviews {
                    if (v is UIScrollView) {
                        (v as! UIScrollView).isScrollEnabled = !forceMcuLayout
                    }
                }
            } else {
                for v in self.pageViewController.view.subviews {
                    if (v is UIScrollView) {
                        (v as! UIScrollView).isScrollEnabled = false
                    }
                }
            }
        }
    }
}

// MARK: - UIPageViewControllerDelegate
extension ConferenceDemoViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if (!completed) {
            return
        }
        guard let curViewController = pageViewController.viewControllers?[0] else {
            return
        }
        curPosition = viewControllers.firstIndex(of: curViewController) ?? 0
    }
}

// MARK: - UIPageViewControllerDataSource
extension ConferenceDemoViewController: UIPageViewControllerDataSource {
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return viewControllers.count
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = viewControllers.firstIndex(of: viewController) else {
            return nil
        }
        if (index == 0) {
            return nil
        }
        return viewControllers[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = viewControllers.firstIndex(of: viewController) else {
            return nil
        }
        if (index == viewControllers.count - 1) {
            return nil
        }
        return viewControllers[index + 1]
    }
}

// MARK: - TZImagePickerControllerDelegate
extension ConferenceDemoViewController: TZImagePickerControllerDelegate {
    func imagePickerController(_ picker: TZImagePickerController!, didFinishPickingPhotos photos: [UIImage]!, sourceAssets assets: [Any]!, isSelectOriginalPhoto: Bool) {
        doPresentImg(photos)
    }
    
    func imagePickerController(_ picker: TZImagePickerController!, didFinishPickingPhotos photos: [UIImage]!, sourceAssets assets: [Any]!, isSelectOriginalPhoto: Bool, infos: [[AnyHashable : Any]]!) {
    }
}

extension ConferenceDemoViewController: UIDocumentPickerDelegate {
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        doPresentICloud(urls)
    }
}
