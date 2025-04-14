//
//  ConferenceViewController.swift
//  fastsdk
//
//  Created by Mac on 2024/4/1.
//

import Foundation
import WebRTC
import common
import permission
import rtc
import SnapKit
import ReplayKit
import TZImagePickerController
import PDFKit
import CoreTelephony

class ConferenceViewController: ViewController {
    public static let NOTIFICATION_NAME_ON_CONFERENCE_STATUS_UPDATE = "onConferenceStatusUpdate"
    public static let NOTIFICATION_PARAM_NAME_CONFERENCE_STATUS = "conferenceStatus"
    public static let NOTIFICATION_NAME_ON_PARTICIPANTS_UPDATE = "onParticipantsUpdate"
    public static let NOTIFICATION_PARAM_NAME_PARTICIPANTS = "participants"
    public static let NOTIFICATION_NAME_ON_MESSAGE = "onMessage"
    public static let NOTIFICATION_PARAM_NAME_MSG_BEAN = "msgBean"
    public static let NOTIFICATION_NAME_ON_CHAT_PERMISSION_CHANGED = "onChatPermissionChanged"
    public static let NOTIFICATION_PARAM_NAME_CHAT_PERMISSION = "chatPermission"
    public static let NOTIFICATION_NAME_ON_LIVING_CHAT_PERMISSION_CHANGED = "onLivingChatPermissionChanged"
    public static let NOTIFICATION_PARAM_NAME_LIVING_CHAT_PERMISSION = "livingChatPermission"
    
    public static let chatTargetAll = {
        var participantBean = rtc.ParticipantBean()
        participantBean.uuid = "chatTargetAll"
        participantBean.displayName = "所有人"
        return participantBean
    }()
    public static let chatTargetNo = {
        var participantBean = rtc.ParticipantBean()
        participantBean.uuid = "chatTargetNo"
        participantBean.displayName = "无"
        return participantBean
    }()
    public static let chatTargetPleaseSelect = {
        var participantBean = rtc.ParticipantBean()
        participantBean.uuid = "chatTargetPleaseSelect"
        participantBean.displayName = "请选择"
        return participantBean
    }()
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
    
    private let serverAddr: String
    private let conferenceRoomNum: String
    private let pwd: String?
    private let name: String
    private let micEnable: Bool
    private let cameraEnable: Bool
    
    private lazy var pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    private lazy var viewControllers: [UIViewController] = []
    /**
     UIPageViewController 当前页卡
     */
    private var curPosition = 0
    /**
     会议时长
     */
    private var duration = 0
    /**
     记录会议时长的定时器
     */
    private var durationTimer: Timer?
    /**
     页卡小圆点指示器
     */
    private lazy var pagePointIndicators  = {
        let view = UIView()
        return view
    }()
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
        stackView.addTarget(target: self, action: #selector(showConferenceInfoDialog))
        // 会议主题
        lbTheme.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        lbTheme.setContentHuggingPriority(.defaultLow, for: .horizontal)
        stackView.addArrangedSubview(lbTheme)
        // 会议号
        lbConferenceRoomNum.setContentCompressionResistancePriority(.required, for: .horizontal)
        lbConferenceRoomNum.setContentHuggingPriority(.required, for: .horizontal)
        stackView.addArrangedSubview(lbConferenceRoomNum)
        // 会议信息图标
        let ivInfo = UIImageView(image: UIImage(named: "conference_iv_info_src"))
        ivInfo.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        ivInfo.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        stackView.addArrangedSubview(ivInfo)
        return stackView
    }()
    private lazy var lbDuration = {
        let label = UILabel()
        label.text = "00:00:00"
        label.textColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.6)
        label.font =  UIFont.systemFont(ofSize: 10.screenAdapt())
        return label
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
        // 本地信号图片标识控件
        let btnSignal = UIButton()
        btnSignal.setImage(UIImage(named: "conference_iv_local_signal_src_5"), for: .normal)
        btnSignal.addTarget(self, action: #selector(showStatisticsDialog))
        titleBar.addSubview(btnSignal)
        btnSignal.snp.makeConstraints { make in
            make.width.height.equalTo(30.screenAdapt())
            make.left.equalToSuperview().offset(5.screenAdapt())
            make.centerY.equalToSuperview()
        }
        // 安全会议图片标识控件
        let ivSecurity = UIImageView(image: UIImage(named: "conference_iv_security_src"))
        titleBar.addSubview(ivSecurity)
        ivSecurity.snp.makeConstraints { make in
            make.width.height.equalTo(20.screenAdapt())
            make.left.equalTo(btnSignal.snp.right).offset(3.screenAdapt())
            make.centerY.equalTo(btnSignal.snp.centerY)
        }
        // 会议信息
        titleBar.addSubview(conferenceInfoView)
        conferenceInfoView.snp.makeConstraints { make in
            make.width.lessThanOrEqualToSuperview().multipliedBy(0.7)
            make.center.equalToSuperview()
        }
        // 会议时长
        titleBar.addSubview(lbDuration)
        lbDuration.sizeToFit()
        lbDuration.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-4.screenAdapt())
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
    private lazy var raiseHandView = {
        // 举手/取消举手
        let view = UIView()
        view.addTarget(target: self, action: #selector(raiseHand))
        // 点击事件交给父控件处理
        let ivRaiseHand = UIButton()
        ivRaiseHand.isUserInteractionEnabled = false
        ivRaiseHand.setImage(UIImage(named: "conference_iv_raise_hand_src"), for: .normal)
        view.addSubview(ivRaiseHand)
        ivRaiseHand.snp.makeConstraints { make in
            make.width.height.equalTo(30.screenAdapt())
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(8.screenAdapt())
        }
        // 点击事件交给父控件处理
        let lbRaiseHand = UIButton()
        lbRaiseHand.isUserInteractionEnabled = false
        lbRaiseHand.setTitle("举手", for: .normal)
        lbRaiseHand.setTitleColor(.text_color_ffffffff, for: .normal)
        lbRaiseHand.setTitle("取消举手", for: .selected)
        lbRaiseHand.setTitleColor(.text_color_ffffffff, for: .selected)
        lbRaiseHand.titleLabel?.font = .systemFont(ofSize: 13.screenAdapt())
        lbRaiseHand.titleLabel?.textAlignment = .center
        view.addSubview(lbRaiseHand)
        lbRaiseHand.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(16.screenAdapt())
            make.centerX.equalToSuperview()
            make.top.equalTo(ivRaiseHand.snp.bottom).offset(5.screenAdapt())
        }
        view.isHidden = true
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
    private lazy var lbUnreadCount = {
        let label = UILabel()
        label.layer.backgroundColor = UIColor(red: 255/255, green: 96/255, blue: 92/255, alpha: 1).cgColor
        label.layer.cornerRadius = 8.screenAdapt()
        label.font = .systemFont(ofSize: 8.screenAdapt())
        label.textColor = .text_color_ffffffff
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
        // 举手/取消举手
        bottomBar.addArrangedSubview(raiseHandView)
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
        lbUnreadCount.text = "\(unreadCount)"
        lbUnreadCount.isHidden = unreadCount == 0
        moreView.addSubview(lbUnreadCount)
        lbUnreadCount.snp.makeConstraints { make in
            make.width.height.equalTo(16.screenAdapt())
            make.top.equalTo(ivMore.snp.top).offset(-4.screenAdapt())
            make.right.equalTo(ivMore.snp.right).offset(8.screenAdapt())
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
    private lazy var ivChatText = {
        let imageView = UIImageView(image: UIImage(named: "conference_iv_chat_text_src"))
        imageView.addTarget(target: self, action: #selector(showChatTextInputHint))
        return imageView
    }()
    private lazy var btnChatTextInputHint = {
        let button = UIButton()
        button.setTitle("请输入消息...", for: .normal)
        button.setTitleColor(UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.6), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12.screenAdapt())
        button.addTarget(self, action: #selector(showChatTextInput))
        button.isHidden  = true
        return button
    }()
    private lazy var chatView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.6)
        view.layer.cornerRadius = 2.screenAdapt()
        // 表情聊天按钮
        let ivChatEmoji = UIImageView(image: UIImage(named: "conference_iv_chat_emoji_src"))
        ivChatEmoji.addTarget(target: self, action: #selector(showEmojiView))
        view.addSubview(ivChatEmoji)
        ivChatEmoji.snp.makeConstraints { make in
            make.width.height.equalTo(22.screenAdapt())
            make.left.equalToSuperview().offset(9.screenAdapt())
            make.centerY.equalToSuperview()
        }
        // 分割线
        let dividerView = UIView()
        dividerView.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.2)
        view.addSubview(dividerView)
        dividerView.snp.makeConstraints { make in
            make.width.equalTo(1.screenAdapt())
            make.height.equalTo(18.screenAdapt())
            make.left.equalTo(ivChatEmoji.snp.right).offset(10.screenAdapt())
            make.centerY.equalToSuperview()
        }
        // 文本聊天按钮
        view.addSubview(ivChatText)
        ivChatText.snp.makeConstraints { make in
            make.width.height.equalTo(22.screenAdapt())
            make.left.equalTo(dividerView.snp.right).offset(10.screenAdapt())
            make.centerY.equalToSuperview()
        }
        // 显示文本输入控件的提示按钮
        view.addSubview(btnChatTextInputHint)
        btnChatTextInputHint.snp.makeConstraints { make in
            make.width.equalTo(89.screenAdapt())
            make.height.equalTo(24.screenAdapt())
            make.left.equalTo(dividerView.snp.right).offset(3.screenAdapt())
            make.centerY.equalToSuperview()
        }
        return view
    }()
    private lazy var emojiView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.65)
        view.layer.cornerRadius = 1.screenAdapt()
        let ivEmojiOk = UIImageView(image: UIImage(named: "conference_iv_emoji_ok_src"))
        ivEmojiOk.addTarget(target: self, action: #selector(sendEmojiOk))
        view.addSubview(ivEmojiOk)
        ivEmojiOk.snp.makeConstraints { make in
            make.width.height.equalTo(24.screenAdapt())
            make.left.equalToSuperview().offset(10.screenAdapt())
            make.centerY.equalToSuperview()
        }
        let ivEmojiGood = UIImageView(image: UIImage(named: "conference_iv_emoji_good_src"))
        ivEmojiGood.addTarget(target: self, action: #selector(sendEmojiGood))
        view.addSubview(ivEmojiGood)
        ivEmojiGood.snp.makeConstraints { make in
            make.width.height.equalTo(24.screenAdapt())
            make.left.equalTo(ivEmojiOk.snp.right).offset(10.screenAdapt())
            make.centerY.equalToSuperview()
        }
        let ivEmojiApplaud = UIImageView(image: UIImage(named: "conference_iv_emoji_applaud_src"))
        ivEmojiApplaud.addTarget(target: self, action: #selector(sendEmojiApplaud))
        view.addSubview(ivEmojiApplaud)
        ivEmojiApplaud.snp.makeConstraints { make in
            make.width.height.equalTo(24.screenAdapt())
            make.left.equalTo(ivEmojiGood.snp.right).offset(10.screenAdapt())
            make.centerY.equalToSuperview()
        }
        view.alpha = 0
        return view
    }()
    private lazy var lbChatTarget = {
        let label = UILabel()
        label.text = "所有人"
        label.font = .systemFont(ofSize: 12.screenAdapt())
        label.textColor = .text_color_ff408cff
        label.addTarget(target: self, action: #selector(jump2SelectChatTarget))
        return label
    }()
    private lazy var delegateProxy = {
        weak var weakSelf = self
        return TextFieldDelegateProxy(onReturn: { textField, string in
            guard  let weakSelf = weakSelf else {
                return
            }
            guard let string = string else {
                return
            }
            weakSelf.sendMsg(text: string, chatTarget: weakSelf.chatTarget)
            textField.text = ""
        })
    }()
    private lazy var tfMsg = {
        let textField = BaseUITextField()
        textField.padding = UIEdgeInsets(top: 5.screenAdapt(), left: 10.screenAdapt(), bottom: 5.screenAdapt(), right: 10.screenAdapt())
        textField.backgroundColor = UIColor(red: 70/255, green: 70/255, blue: 70/255, alpha: 1)
        textField.layer.cornerRadius = 5.screenAdapt()
        textField.font = .systemFont(ofSize: 14.screenAdapt())
        textField.textColor = .text_color_ffffffff
        textField.placeholder = "请输入消息..."
        textField.setPlaceholderColor(.text_color_ffffffff)
        textField.returnKeyType = .send
        textField.delegate = delegateProxy
        return textField
    }()
    private lazy var chatTextInputView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 49/255, green: 49/255, blue: 49/255, alpha: 1)
        let lbSendTo = UILabel()
        lbSendTo.text = "发送至"
        lbSendTo.font = .systemFont(ofSize: 12.screenAdapt())
        lbSendTo.textColor = .text_color_ffffffff
        view.addSubview(lbSendTo)
        lbSendTo.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(22.screenAdapt())
            make.top.equalToSuperview().offset(5.screenAdapt())
        }
        // 聊天目标
        view.addSubview(lbChatTarget)
        lbChatTarget.snp.makeConstraints { make in
            make.left.equalTo(lbSendTo.snp.right).offset(5.screenAdapt())
            make.centerY.equalTo(lbSendTo.snp.centerY)
        }
        let ivSentTarget = UIImageView(image: UIImage(named: "conference_iv_sent_target_src"))
        view.addSubview(ivSentTarget)
        ivSentTarget.snp.makeConstraints { make in
            make.width.equalTo(11.screenAdapt())
            make.height.equalTo(5.screenAdapt())
            make.left.equalTo(lbChatTarget.snp.right).offset(3.screenAdapt())
            make.centerY.equalTo(lbChatTarget.snp.centerY)
        }
        view.addSubview(tfMsg)
        tfMsg.snp.makeConstraints { make in
            make.height.equalTo(40.screenAdapt())
            make.left.equalToSuperview().offset(20.screenAdapt())
            make.top.equalTo(lbSendTo.snp.bottom).offset(5.screenAdapt())
            make.right.equalToSuperview().offset(-20.screenAdapt())
        }
        view.isHidden = true
        return view
    }()
//    lazy var msgListView = {
//        let msgListView = MsgListView()
//        msgListView.isUserInteractionEnabled = false
//        return msgListView
//    }()
    private lazy var setMicDisabledViewCenter = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.6)
        // 圆角度数为宽高的一半即为圆形
        view.layer.cornerRadius = 48.screenAdapt() / 2
        view.alpha = 0
        view.addTarget(target: self, action: #selector(setMicDisabled))
        let imageView = UIImageView()
        view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(5.screenAdapt())
            make.top.equalToSuperview().offset(5.screenAdapt())
            make.right.equalToSuperview().offset(-5.screenAdapt())
            make.bottom.equalToSuperview().offset(-5.screenAdapt())
        }
        imageView.image = UIImage(named: "conference_iv_set_mic_disabled_src")
        return view
    }()
    private lazy var raiseHandCenterView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.6)
        // 圆角度数为宽高的一半即为圆形
        view.layer.cornerRadius = 48.screenAdapt() / 2
        view.alpha = 0
        view.addTarget(target: self, action: #selector(raiseHand))
        view.isHidden = true
        let imageView = UIImageView()
        view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(5.screenAdapt())
            make.top.equalToSuperview().offset(5.screenAdapt())
            make.right.equalToSuperview().offset(-5.screenAdapt())
            make.bottom.equalToSuperview().offset(-5.screenAdapt())
        }
        imageView.image = UIImage(named: "conference_iv_raise_hand_src")
        return view
    }()
    private lazy var lbSubtitles = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 17.screenAdapt())
        label.textColor = .text_color_ffffffff
        label.textAlignment = .center
        label.shadowColor = UIColor.black
        label.shadowOffset = CGSize(width: 2, height: 2)
        label.numberOfLines = 0
        return label
    }()
    private lazy var livingView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 18/255, green: 26/255, blue: 44/255, alpha: 173/255)
        view.isHidden = true
        let ivLiving = UIImageView(image: UIImage(named: "conference_iv_living_src"))
        view.addSubview(ivLiving)
        ivLiving.snp.makeConstraints { make in
            make.width.height.equalTo(12.screenAdapt())
            make.left.equalToSuperview().offset(5.screenAdapt())
            make.centerY.equalToSuperview()
        }
        let lbLiving = UILabel()
        lbLiving.text = "直播中"
        lbLiving.font = .systemFont(ofSize: 10.screenAdapt())
        lbLiving.textColor = .text_color_ffffffff
        view.addSubview(lbLiving)
        lbLiving.snp.makeConstraints { make in
            make.left.equalTo(ivLiving.snp.right).offset(5.screenAdapt())
            make.right.equalToSuperview().offset(-5.screenAdapt())
            make.centerY.equalToSuperview()
        }
        return view
    }()
    private lazy var recordingView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 18/255, green: 26/255, blue: 44/255, alpha: 173/255)
        view.isHidden = true
        let ivRecording = UIImageView(image: UIImage(named: "conference_iv_recording_src"))
        view.addSubview(ivRecording)
        ivRecording.snp.makeConstraints { make in
            make.width.height.equalTo(12.screenAdapt())
            make.left.equalToSuperview().offset(5.screenAdapt())
            make.centerY.equalToSuperview()
        }
        let lbRecording = UILabel()
        lbRecording.text = "录制中"
        lbRecording.font = .systemFont(ofSize: 10.screenAdapt())
        lbRecording.textColor = .text_color_ffffffff
        view.addSubview(lbRecording)
        lbRecording.snp.makeConstraints { make in
            make.left.equalTo(ivRecording.snp.right).offset(5.screenAdapt())
            make.right.equalToSuperview().offset(-5.screenAdapt())
            make.centerY.equalToSuperview()
        }
        return view
    }()
    /**
     隐藏 TitleBar 和 Bottom 的动画的定时器
     */
    private var animateTimer: Timer?
    private var setCameraEnanbledDebouncer = Debouncer(delay: 0.7)
    private var updateParticipantsThrottler = Throttler()
    private var requestLayoutThrottler = Throttler()
    private var pictureInPicture = true
    private var audioMode = false
    private lazy var chatTarget = ConferenceViewController.chatTargetNo
    private var unreadCount = 0
    var msgBeans = [MsgBean]()
    private lazy var callCenter = CTCallCenter()
    
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
        builder.setLogLevel(.none)
        conferenceManager = builder.build()
        conferenceManager.setOnConferenceListener(self)
        return conferenceManager
    }()
    private var notifyOpenAudioDialog: CommonDialog?
    
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
    
    deinit {
        MyShowLogger.instance.showLogger.debug("deinit")
        conferenceManager.quit()
        durationTimer?.invalidate()
        durationTimer = nil
        animateTimer?.invalidate()
        animateTimer = nil
    }
    
    // 重现statusBar相关方法
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        guard #available(iOS 13.0, *) else {
            return .default
        }
        guard let statusBarDark = statusBarDark() else {
            return .default
        }
        if (statusBarDark) {
            return .darkContent
        } else {
            return .lightContent
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        // 隐藏系统默认导航栏
        navigationController?.setNavigationBarHidden(true, animated: false)
        // 初始化 contentView
        self.view.addSubview(contentView)
        // 系统默认会给 autoresizing 约束，关闭 autoresizing
        contentView.translatesAutoresizingMaskIntoConstraints = false
        if (immersive()) {
            contentView.superview?.addConstraints([
                NSLayoutConstraint(item: contentView, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 0)
                , NSLayoutConstraint(item: contentView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 0)
                , NSLayoutConstraint(item: contentView, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: 0)
                , NSLayoutConstraint(item: contentView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: 0)
            ])
        } else {
            contentView.superview?.addConstraints([
                NSLayoutConstraint(item: contentView, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 0)
                , NSLayoutConstraint(item: contentView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 0)
                , NSLayoutConstraint(item: contentView, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: 0)
                , NSLayoutConstraint(item: contentView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: 0)
            ])
        }
////        if (statusBarColor() != nil) {
////            StatusBarUtil.setColor(color: statusBarColor()!)
////        }
//        // 初始化 Presenter
//        presenter = P.init()
//        presenter?.attachView(view: self as! P.V)
        initView()
        setListener()
        initData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // 关闭自动锁屏
        UIApplication.shared.isIdleTimerDisabled = true
        // 关闭侧滑关闭手势
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        // 允许屏幕旋转
        (UIApplication.shared.delegate as? AppDelegate)?.interfaceOrientationMask = UIInterfaceOrientationMask.all
        // 开始生成设备方向通知
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        // 添加设备方向改变观察者
        NotificationCenter.default.addObserver(self, selector: #selector(onOrientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
        // 添加状态栏方向改变观察者
        NotificationCenter.default.addObserver(self, selector: #selector(onOrientationChanged), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        // 添加应用进入后台观察者
        NotificationCenter.default.addObserver(self, selector: #selector(onBackground), name:UIApplication.didEnterBackgroundNotification, object: nil)
        // 添加应用回到前台观察者
        NotificationCenter.default.addObserver(self, selector: #selector(onForeground), name:UIApplication.willEnterForegroundNotification, object: nil)
        // 监听软键盘弹出和隐藏
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        //        // 添加音频设备切换观察者
        //        NotificationCenter.default.addObserver(self, selector: #selector(audioSessionRouteChange(_:)), name: AVAudioSession.routeChangeNotification, object: nil)
        // 通话状态监听
        callCenter.callEventHandler = { [weak self] call in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if (call.callState == CTCallStateDialing) {
                    // 拨号中
                    MyShowLogger.instance.showLogger.info("打电话测试: 拨号中")
                    // 发送通话中图片
                    if (!AppUtil.isBackground()) {
                        self.conferenceManager.getRTCManager()?.setCameraEnabled(enabled: false)
                        if let image = UIImage(named: "conference_iv_calling_src") {
                            self.conferenceManager.getRTCManager()?.startImageCapture(image)
                        }
                        (self.viewControllers[self.curPosition] as? ConferenceChildViewController)?.onLayout(conferenceManager: self.conferenceManager, layoutBeans: self.conferenceManager.getCurrentLayout() ?? [])
                    }
                } else if (call.callState == CTCallStateIncoming) {
                    // 响铃中
                    MyShowLogger.instance.showLogger.info("打电话测试: 响铃中")
                    // 发送通话中图片
                    if (!AppUtil.isBackground()) {
                        self.conferenceManager.getRTCManager()?.setCameraEnabled(enabled: false)
                        if let image = UIImage(named: "conference_iv_calling_src") {
                            self.conferenceManager.getRTCManager()?.startImageCapture(image)
                        }
                        (self.viewControllers[self.curPosition] as? ConferenceChildViewController)?.onLayout(conferenceManager: self.conferenceManager, layoutBeans: self.conferenceManager.getCurrentLayout() ?? [])
                    }
                } else if (call.callState == CTCallStateConnected) {
                    // 通话中
                    MyShowLogger.instance.showLogger.info("打电话测试: 通话中")
                } else if (call.callState == CTCallStateDisconnected) {
                    // 挂断
                    MyShowLogger.instance.showLogger.info("打电话测试: 挂断")
                    if (AppUtil.isBackground()) {
                        // 发送摄像头关闭图片
                        if let image = UIImage(named: "conference_iv_camera_disabled_src") {
                            self.conferenceManager.getRTCManager()?.startImageCapture(image)
                        }
                        (self.viewControllers[self.curPosition] as? ConferenceChildViewController)?.onLayout(conferenceManager: self.conferenceManager, layoutBeans: self.conferenceManager.getCurrentLayout() ?? [])
                    } else {
                        if self.setCameraDisabledView.subviews.count == 2
                            , let ivSetCameraDisabled = self.setCameraDisabledView.subviews[0] as? UIButton
                            , let lbSetCameraDisabled = self.setCameraDisabledView.subviews[1] as? UIButton
                            , "关闭视频" == lbSetCameraDisabled.title(for: .normal) {
                            // 开启摄像头
                            conferenceManager.getRTCManager()?.setCameraEnabled(enabled: true)
                        } else {
                            // 发送摄像头关闭图片
                            if let image = UIImage(named: "conference_iv_camera_disabled_src") {
                                self.conferenceManager.getRTCManager()?.startImageCapture(image)
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // 恢复自动锁屏
        UIApplication.shared.isIdleTimerDisabled = false
        // 恢复侧滑关闭手势
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        // 禁止屏幕旋转
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
        // 移除设备方向改变观察者
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        // 移除状态栏方向改变观察者
        NotificationCenter.default.removeObserver(self, name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        // 移除应用进入后台观察者
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        // 移除应用回到前台观察者
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        // 移除软键盘弹出和隐藏监听
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        //        // 添加音频设备切换观察者
        //        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
        //        // 停止生成设备方向通知
        //        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        //        // 注销通话状态监听
        //        callCenter.callEventHandler = nil
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
        viewControllers.append(ConferenceDefaultViewController())
        pageViewController.setViewControllers([viewControllers.first!], direction: .forward, animated: false)
        // 初始化时不能滑动
        setPageViewControllerScrollEnabled(false)
        // 标题栏
        contentView.addSubview(titleBarContainer)
        titleBarContainer.snp.makeConstraints { make in
            make.height.equalTo(54.screenAdapt() + StatusBarUtil.getHeight())
            make.left.top.right.equalToSuperview()
        }
        // 底部栏
        contentView.addSubview(bottomBarContainer)
        bottomBarContainer.snp.makeConstraints { make in
            make.height.equalTo(64.screenAdapt() + NavigationBarUtil.getHeight())
            make.left.right.bottom.equalToSuperview()
        }
        // 页卡指示器
        contentView.addSubview(pagePointIndicators)
        pagePointIndicators.snp.makeConstraints { make in
            make.width.equalTo(0)
            make.height.equalTo(6.screenAdapt())
//            make.bottom.equalTo(-72.screenAdapt())
            make.bottom.equalTo(bottomBarContainer.snp.top).offset(-8.screenAdapt())
            make.centerX.equalToSuperview()
        }
        // 翻转摄像头
        contentView.addSubview(btnSwitchCamera)
        btnSwitchCamera.snp.makeConstraints { make in
            make.width.height.equalTo(32.screenAdapt())
            make.left.equalToSuperview().offset(15.screenAdapt())
            make.top.equalToSuperview().offset(56.screenAdapt() + StatusBarUtil.getHeight() + 60.screenAdapt())
        }
        // 表情/文本聊天
        contentView.addSubview(chatView)
        chatView.snp.makeConstraints { make in
            make.width.equalTo(83.screenAdapt())
            make.height.equalTo(30.screenAdapt())
            make.left.equalToSuperview().offset(15.screenAdapt())
            make.bottom.equalToSuperview().offset(-64.screenAdapt() - NavigationBarUtil.getHeight() - 10.screenAdapt())
        }
        // 表情选择控件
        contentView.addSubview(emojiView)
        emojiView.snp.makeConstraints { make in
            make.width.equalTo(112.screenAdapt())
            make.height.equalTo(32.screenAdapt())
            make.left.equalToSuperview().offset(15.screenAdapt())
            make.bottom.equalTo(chatView.snp.top).offset(-7.screenAdapt())
        }
        // 聊天文本输入框
        contentView.addSubview(chatTextInputView)
        chatTextInputView.snp.makeConstraints { make in
            make.height.equalTo(75.screenAdapt() + NavigationBarUtil.getHeight())
            make.left.right.bottom.equalToSuperview()
        }
        // 消息列表
//        contentView.addSubview(msgListView)
//        msgListView.snp.makeConstraints { make in
//            make.height.equalTo(128.screenAdapt())
//            make.left.equalToSuperview().offset(15.screenAdapt())
//            make.right.equalToSuperview().offset(-100.screenAdapt())
//            make.bottom.equalTo(chatView.snp.top).offset(-46.screenAdapt())
//        }
        // 语音监测图标
        contentView.addSubview(setMicDisabledViewCenter)
        setMicDisabledViewCenter.snp.makeConstraints { make in
            make.width.height.equalTo(48.screenAdapt())
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-64.screenAdapt() - NavigationBarUtil.getHeight())
        }
        // 举手
        contentView.addSubview(raiseHandCenterView)
        raiseHandCenterView.snp.makeConstraints { make in
            make.width.height.equalTo(48.screenAdapt())
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-64.screenAdapt() - NavigationBarUtil.getHeight())
        }
        // 字幕
        contentView.addSubview(lbSubtitles)
        lbSubtitles.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(30.screenAdapt())
            make.right.equalToSuperview().offset(-30.screenAdapt())
            make.bottom.equalToSuperview().offset(-128.screenAdapt() - NavigationBarUtil.getHeight())
        }
        // 直播中标识
        contentView.addSubview(livingView)
        livingView.snp.makeConstraints { make in
            make.width.equalTo(60.screenAdapt())
            make.height.equalTo(20.screenAdapt())
            make.left.equalToSuperview().offset(15.screenAdapt())
            make.top.equalToSuperview().offset(56.screenAdapt() + StatusBarUtil.getHeight() + 0.screenAdapt())
        }
        // 录制中标识
        contentView.addSubview(recordingView)
        recordingView.snp.makeConstraints { make in
            make.width.equalTo(60.screenAdapt())
            make.height.equalTo(20.screenAdapt())
            make.left.equalToSuperview().offset(15.screenAdapt())
            make.top.equalToSuperview().offset(56.screenAdapt() + StatusBarUtil.getHeight() + 30.screenAdapt())
        }
        // 延迟隐藏
        animateTimer?.invalidate()
        animateTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { [weak self] _ in
            guard let self = self else { return }
            self.hideTitleBarAndBottomBar()
        })
    }
    
    func setListener() {
        // 点击空白处，隐藏功能区
        contentView.addTarget(target: self, action: #selector(showTitleBarAndBottomBar))
    }
    
    func initData() {
        // 创建定时器，记录会议时长
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.duration += 1
            let seconds = self.duration % 60
            let secondsText = seconds >= 10 ? "\(seconds)" : "0\(seconds)"
            let minute = (self.duration / 60) % 60
            let minuteText = minute >= 10 ? "\(minute)" : "0\(minute)"
            let hour = self.duration / 60 / 60
            let hourText = hour >= 10 ? "\(hour)" : "0\(hour)"
            self.lbDuration.text = "\(hourText):\(minuteText):\(secondsText)"
            
//            let usageCPU = AppUtil.getUsageCPU()
//            let usageMemory = AppUtil.getUsageMemory()
//            let formattedCPUUsage = String(format: "%.2f%%", usageCPU * 100)
//            let usageMemoryKB = usageMemory / 1024
//            let usageMemoryMB = usageMemory / 1024 / 1024
//            MyShowLogger.instance.showLogger.debug("入会时长：\(hourText):\(minuteText):\(secondsText), cpu占用: \(formattedCPUUsage), 内存占用: \(usageMemoryMB) MB.")
        }
        conferenceManager.join(conferenceRoomNum: conferenceRoomNum
                               , pwd: pwd ?? ""
                               , name: name)
    }
    
    open func immersive() -> Bool {
        return true
    }
    
    open func statusBarDark() -> Bool? {
        return nil;
    }
    
    open func showLoadingUI() {
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
    
    open func hideLoadingUI() {
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
    
    open func toast(text: String, duration: Duration = .short) {
        if (Thread.current.isMainThread) {
            Toast.makeText(parent: view, text: text).show()
        } else {
            DispatchQueue.main.async {
                Toast.makeText(parent: self.view, text: text).show()
            }
        }
    }
    
    @objc private func onOrientationChanged() {
        //        // 横竖屏切换时状态栏和底部栏高度会变化
        //        if (UIDevice.current.orientation == .portrait
        //            || UIDevice.current.orientation == .landscapeLeft
        //            || UIDevice.current.orientation == .landscapeRight) {
        //            Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
        //                self.titleBarContainer.snp.remakeConstraints { make in
        //                    make.height.equalTo(54.screenAdapt() + StatusBarUtil.getHeight())
        //                    make.left.equalToSuperview()
        //                    if (self.btnVolume.alpha == 0 || self.btnRaiseHand.alpha == 0) {
        //                        // TitleBar 和 BottomBar 已显示
        //                        make.top.equalToSuperview()
        //                    } else {
        //                        make.top.equalToSuperview().offset(-54.screenAdapt() - StatusBarUtil.getHeight())
        //                    }
        //                    make.right.equalToSuperview()
        //                }
        //                self.titleBar.snp.remakeConstraints { make in
        //                    make.height.equalTo(54.screenAdapt())
        //                    make.left.equalToSuperview()
        //                    make.top.equalToSuperview().offset(StatusBarUtil.getHeight())
        //                    make.right.equalToSuperview()
        //                }
        //                self.bottomBarContainer.snp.remakeConstraints { make in
        //                    make.height.equalTo(64.screenAdapt() + NavigationBarUtil.getHeight())
        //                    make.left.right.equalToSuperview()
        //                    if (self.btnVolume.alpha == 0 || self.btnRaiseHand.alpha == 0) {
        //                        // TitleBar 和 BottomBar 已显示
        //                        make.bottom.equalToSuperview()
        //                    } else {
        //                        make.bottom.equalToSuperview().offset(64.screenAdapt() + NavigationBarUtil.getHeight())
        //                    }
        //                }
        //            }
        //        }
        if (UIApplication.shared.statusBarOrientation == .landscapeLeft
            || UIApplication.shared.statusBarOrientation == .landscapeRight) {
            Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] timer in
                guard let self = self else { return }
                self.titleBarContainer.snp.remakeConstraints { make in
                    make.height.equalTo(54.screenAdapt())
                    make.left.top.right.equalToSuperview()
                }
                self.bottomBarContainer.snp.remakeConstraints { make in
                    make.height.equalTo(64.screenAdapt())
                    make.left.right.bottom.equalToSuperview()
                }
                self.setMicDisabledViewCenter.snp.remakeConstraints { make in
                    make.width.height.equalTo(48.screenAdapt())
                    make.right.equalToSuperview().offset(-15.screenAdapt() - ScreenUtil.getSafeInsetTop())
                    make.bottom.equalToSuperview().offset(-64.screenAdapt() - NavigationBarUtil.getHeight())
                }
                self.raiseHandCenterView.snp.remakeConstraints { make in
                    make.width.height.equalTo(48.screenAdapt())
                    make.right.equalToSuperview().offset(-15.screenAdapt() - ScreenUtil.getSafeInsetTop())
                    make.bottom.equalToSuperview().offset(-64.screenAdapt() - NavigationBarUtil.getHeight())
                }
                self.lbSubtitles.snp.remakeConstraints { make in
                    make.left.equalToSuperview().offset(30.screenAdapt())
                    make.right.equalToSuperview().offset(-30.screenAdapt())
                    make.bottom.equalToSuperview().offset(-64.screenAdapt() - NavigationBarUtil.getHeight())
                }
                // 延迟隐藏
                self.animateTimer?.invalidate()
                self.animateTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { [weak self] _ in
                    guard let self = self else { return }
                    self.hideTitleBarAndBottomBar()
                })
            }
        } else {
            Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] timer in
                guard let self = self else { return }
                self.titleBarContainer.snp.remakeConstraints { make in
                    make.height.equalTo(54.screenAdapt() + StatusBarUtil.getHeight())
                    make.left.top.right.equalToSuperview()
                }
                self.bottomBarContainer.snp.remakeConstraints { make in
                    make.height.equalTo(64.screenAdapt() + NavigationBarUtil.getHeight())
                    make.left.right.bottom.equalToSuperview()
                }
                self.setMicDisabledViewCenter.snp.remakeConstraints { make in
                    make.width.height.equalTo(48.screenAdapt())
                    make.centerX.equalToSuperview()
                    make.bottom.equalToSuperview().offset(-64.screenAdapt() - NavigationBarUtil.getHeight())
                }
                self.raiseHandCenterView.snp.remakeConstraints { make in
                    make.width.height.equalTo(48.screenAdapt())
                    make.centerX.equalToSuperview()
                    make.bottom.equalToSuperview().offset(-64.screenAdapt() - NavigationBarUtil.getHeight())
                }
                self.lbSubtitles.snp.makeConstraints { make in
                    make.left.equalToSuperview().offset(30.screenAdapt())
                    make.right.equalToSuperview().offset(-30.screenAdapt())
                    make.bottom.equalToSuperview().offset(-128.screenAdapt() - NavigationBarUtil.getHeight())
                }
                // 延迟隐藏
                self.animateTimer?.invalidate()
                self.animateTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { [weak self] _ in
                    guard let self = self else { return }
                    self.hideTitleBarAndBottomBar()
                })
            }
        }
    }
    
    private func orientationChange2All() {
        //        // 切到竖屏
        //        if #available(iOS 16.0, *) {
        //            setNeedsUpdateOfSupportedInterfaceOrientations()
        //            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
        //                return
        //            }
        //            let geometryPreferencesIOS = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
        //            windowScene.requestGeometryUpdate(geometryPreferencesIOS)
        //        } else {
        //            let orientation = UIInterfaceOrientation.portrait.rawValue
        //            UIDevice.current.setValue(orientation, forKey: "orientation")
        //        }
        // 允许屏幕旋转
        (UIApplication.shared.delegate as? AppDelegate)?.interfaceOrientationMask = UIInterfaceOrientationMask.all
        // 切到横屏
        if #available(iOS 16.0, *) {
            setNeedsUpdateOfSupportedInterfaceOrientations()
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                return
            }
            if (UIDevice.current.orientation == .portrait) {
                let geometryPreferencesIOS = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
                windowScene.requestGeometryUpdate(geometryPreferencesIOS)
            } else {
                let geometryPreferencesIOS = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscape)
                windowScene.requestGeometryUpdate(geometryPreferencesIOS)
            }
        } else {
            // 为啥这里是反的呀？
            var orientation = UIInterfaceOrientation.portrait.rawValue
            if (UIDevice.current.orientation == .portrait) {
                orientation = UIInterfaceOrientation.portrait.rawValue
            } else if (UIDevice.current.orientation == .landscapeLeft) {
                orientation = UIInterfaceOrientation.landscapeRight.rawValue
            } else if (UIDevice.current.orientation == .landscapeRight) {
                orientation = UIInterfaceOrientation.landscapeLeft.rawValue
            }
            UIDevice.current.setValue(orientation, forKey: "orientation")
        }
    }
    
    private func orientationChange2Landscape() {
        // 禁止屏幕旋转
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
    
    @objc private func onBackground() {
        if (audioMode) {
            // 发送语音模式图片
            MyShowLogger.instance.showLogger.debug("应用退到后台，语音模式")
            if let image = UIImage(named: "conference_iv_audio_mode_src") {
                self.conferenceManager.getRTCManager()?.startImageCapture(image)
            }
            return
        }
        if let currentCalls = callCenter.currentCalls
            , !currentCalls.isEmpty
            , let callState = currentCalls.first?.callState {
            if (callState == CTCallStateDialing || callState == CTCallStateIncoming || callState == CTCallStateConnected) {
//                MyShowLogger.instance.showLogger.debug("打电话测试: 通话中")
//                // 发送通话中图片
//                if let image = UIImage(named: "conference_iv_calling_src") {
//                    self.conferenceManager.getRTCManager()?.startImageCapture(image)
//                }
//                (self.viewControllers[self.curPosition] as? ConferenceChildViewController)?.onLayout(conferenceManager: self.conferenceManager, layoutBeans: self.conferenceManager.getCurrentLayout() ?? [])
                return
            }
        }
        // 发送摄像头关闭图片
        if let image = UIImage(named: "conference_iv_camera_disabled_src") {
            self.conferenceManager.getRTCManager()?.startImageCapture(image)
        }
        (self.viewControllers[self.curPosition] as? ConferenceChildViewController)?.onLayout(conferenceManager: self.conferenceManager, layoutBeans: self.conferenceManager.getCurrentLayout() ?? [])
    }
    
    @objc private func onForeground() {
        if (audioMode) {
            // 发送语音模式图片
            MyShowLogger.instance.showLogger.debug("应用回到前台，语音模式")
            if let image = UIImage(named: "conference_iv_audio_mode_src") {
                self.conferenceManager.getRTCManager()?.startImageCapture(image)
            }
            return
        }
        if let currentCalls = callCenter.currentCalls
            , !currentCalls.isEmpty
            , let callState = currentCalls.first?.callState {
            if (callState == CTCallStateDialing || callState == CTCallStateIncoming || callState == CTCallStateConnected) {
                MyShowLogger.instance.showLogger.debug("打电话测试: 通话中")
                // 发送通话中图片
                if let image = UIImage(named: "conference_iv_calling_src") {
                    self.conferenceManager.getRTCManager()?.startImageCapture(image)
                }
                (self.viewControllers[self.curPosition] as? ConferenceChildViewController)?.onLayout(conferenceManager: self.conferenceManager, layoutBeans: self.conferenceManager.getCurrentLayout() ?? [])
                return
            }
        }
        // 继续捕获摄像头
        if self.setCameraDisabledView.subviews.count == 2
            , let ivSetCameraDisabled = self.setCameraDisabledView.subviews[0] as? UIButton
            , let lbSetCameraDisabled = self.setCameraDisabledView.subviews[1] as? UIButton
            , "关闭视频" == lbSetCameraDisabled.title(for: .normal) {
            // 继续捕获摄像头
            conferenceManager.getRTCManager()?.setCameraEnabled(enabled: true)
        }
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        // 键盘变化高度
        let rect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? AnyObject)?.cgRectValue
        let height = rect?.size.height
        // 键盘变化时间
        let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Float) ?? 0.25
        if (height == nil) {
            return
        }
        // 动画修改约束
        chatTextInputView.snp.updateConstraints({ make in
            make.bottom.equalToSuperview().offset(-height!)
        })
        chatTextInputView.superview?.needsUpdateConstraints()
        chatTextInputView.superview?.updateConstraintsIfNeeded()
        UIView.animate(withDuration: TimeInterval(duration)) {
            self.chatTextInputView.superview?.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        // 键盘变化高度
        let rect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? AnyObject)?.cgRectValue
        let height = rect?.size.height
        // 键盘变化时间
        let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Float) ?? 0.25
        // 动画修改约束
        chatTextInputView.snp.updateConstraints({ make in
            make.bottom.equalToSuperview()
        })
        chatTextInputView.superview?.needsUpdateConstraints()
        chatTextInputView.superview?.updateConstraintsIfNeeded()
        UIView.animate(withDuration: TimeInterval(duration)) { [weak self] in
            guard let self = self else { return }
            self.chatTextInputView.superview?.layoutIfNeeded()
        }
    }
    
    private func setPageViewControllerScrollEnabled(_ scrollEnabled: Bool) {
        MyShowLogger.instance.showLogger.info("scrollEnabled--->\(scrollEnabled)")
        for v in pageViewController.view.subviews {
            if (v is UIScrollView) {
                (v as! UIScrollView).isScrollEnabled = scrollEnabled
            }
        }
        pagePointIndicators.isHidden = !scrollEnabled
    }
    
    private func hideTitleBarAndBottomBar() {
        // 标题栏
        titleBarContainer.snp.updateConstraints({ make in
            make.top.equalToSuperview().offset(-titleBarContainer.frame.size.height)
        })
        titleBarContainer.superview?.needsUpdateConstraints()
        titleBarContainer.superview?.updateConstraintsIfNeeded()
        UIView.animate(withDuration: 0.5) { [weak self] in
            guard let self = self else { return }
            self.titleBarContainer.superview?.layoutIfNeeded()
        }
        // 底部栏
        bottomBarContainer.snp.updateConstraints({ make in
            make.bottom.equalToSuperview().offset(bottomBarContainer.frame.size.height)
        })
        bottomBarContainer.superview?.needsUpdateConstraints()
        bottomBarContainer.superview?.updateConstraintsIfNeeded()
        UIView.animate(withDuration: 0.5) { [weak self] in
            guard let self = self else { return }
            self.bottomBarContainer.superview?.layoutIfNeeded()
        }
        // 翻转摄像头按钮和表情/文本聊天
        UIView.animate(withDuration: 0.5) { [weak self] in
            guard let self = self else { return }
            self.btnSwitchCamera.alpha = 0
            self.chatView.alpha = 0
            self.setMicDisabledViewCenter.alpha = 1
            self.raiseHandCenterView.alpha = 1
        }
    }
    
    @objc private func showTitleBarAndBottomBar() {
        if (emojiView.alpha != 0) {
            // 表情按钮没有隐藏的话，先隐藏表情按钮
            UIView.animate(withDuration: 0.5) { [weak self] in
                guard let self = self else { return }
                self.emojiView.alpha = 0
            }
            // 延迟隐藏
            animateTimer?.invalidate()
            animateTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: {  [weak self] _ in
                guard let self = self else { return }
                self.hideTitleBarAndBottomBar()
            })
            return
        }
        if (!btnChatTextInputHint.isHidden) {
            // 文本输入提示控件没有隐藏的话，先隐藏
            btnChatTextInputHint.isHidden = true
            // 显示文本输入按钮
            ivChatText.isHidden = false
            // 重新设置 chatView 宽度
            chatView.snp.updateConstraints { make in
                make.width.equalTo(83.screenAdapt())
            }
            // 延迟隐藏
            animateTimer?.invalidate()
            weak var weakSelf = self
            animateTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { [weak self] _ in
                guard let self = self else { return }
                self.hideTitleBarAndBottomBar()
            })
            return
        }
        if (!chatTextInputView.isHidden) {
            // 文本输入框没有隐藏的话，先隐藏
            chatTextInputView.isHidden = true
            self.setMicDisabledViewCenter.alpha = 1
            self.raiseHandCenterView.alpha = 1
            // 关闭软键盘
            self.view.endEditing(true)
            return
        }
        if (setMicDisabledViewCenter.alpha == 0 || raiseHandCenterView.alpha == 0) {
            // TitleBar 和 BottomBar 已显示
            animateTimer?.invalidate()
            hideTitleBarAndBottomBar()
            return
        }
        // 标题栏
        titleBarContainer.snp.updateConstraints({ make in
            make.top.equalToSuperview().offset(0)
        })
        titleBarContainer.superview?.needsUpdateConstraints()
        titleBarContainer.superview?.updateConstraintsIfNeeded()
        UIView.animate(withDuration: 0.5) { [weak self] in
            guard let self = self else { return }
            self.titleBarContainer.superview?.layoutIfNeeded()
        }
        // 底部栏
        bottomBarContainer.snp.updateConstraints({ make in
            make.bottom.equalToSuperview().offset(0)
        })
        bottomBarContainer.superview?.needsUpdateConstraints()
        bottomBarContainer.superview?.updateConstraintsIfNeeded()
        UIView.animate(withDuration: 0.5) { [weak self] in
            guard let self = self else { return }
            self.bottomBarContainer.superview?.layoutIfNeeded()
        }
        // 翻转摄像头按钮和表情/文本聊天
        UIView.animate(withDuration: 0.5) { [weak self] in
            guard let self = self else { return }
            self.btnSwitchCamera.alpha = 1
            self.chatView.alpha = 1
            self.setMicDisabledViewCenter.alpha = 0
            self.raiseHandCenterView.alpha = 0
        }
        // 延迟隐藏
        animateTimer?.invalidate()
        animateTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { [weak self] _ in
            guard let self = self else { return }
            self.hideTitleBarAndBottomBar()
        })
    }
    
    @objc private func showStatisticsDialog() {
        // 延迟隐藏
        animateTimer?.invalidate()
        animateTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { [weak self] _ in
            guard let self = self else { return }
            self.hideTitleBarAndBottomBar()
        })
//        present(StatisticsDialog(), animated: true)
    }
    
    @objc private func showConferenceInfoDialog() {
        // 延迟隐藏
        animateTimer?.invalidate()
        animateTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { [weak self] _ in
            guard let self = self else { return }
            self.hideTitleBarAndBottomBar()
        })
        let theme = lbTheme.text ?? ""
        let conferenceRoomNum = (lbConferenceRoomNum.text ?? "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        var pwd = ""
        if let password = self.pwd {
            pwd = password
        }
        if let guestPwd = conferenceManager.getConferenceStatus()?.guestPwd {
            pwd = guestPwd
        }
        var shareUrl: String? = ""
//        if (shareUrlBean?.results?.defaultShareAddr != nil && (shareUrlBean?.results?.defaultShareAddr?.count)! > 0) {
//            shareUrl = shareUrlBean?.results?.defaultShareAddr
//        } else if (shareUrlBean?.results?.subShareAddr?.isEmpty == false) {
//            shareUrl = shareUrlBean?.results?.subShareAddr?[0]?.shareAddress
//        }
//        ConferenceInfoDialog(theme: theme
//                             , conferenceRoomNum: conferenceRoomNum
//                             , pwd: pwd
//                             , shareUrl: shareUrl ?? "")
//        .show(viewController: self)
    }
    
    @objc private func quit() {
        CommonDialog(title: nil, message: "您确定想离开会议吗？"
                     , negativeButtonTextColor: .text_color_ff666666
                     , positiveButtonHandler: { [weak self] _ in
            MyShowLogger.instance.showLogger.debug("退出会议界面")
            guard let self = self else { return }
            self.conferenceManager.quit()
            durationTimer?.invalidate()
            durationTimer = nil
            self.navigationController?.popViewController(animated: true)
            MyShowLogger.instance.showLogger.debug("退出会议界面")
        }).show(uiViewController: self)
    }
    
    @objc private func setMicDisabled() {
        // 延迟隐藏
        animateTimer?.invalidate()
        animateTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { [weak self] _ in
            guard let self = self else { return }
            self.hideTitleBarAndBottomBar()
        })
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
            if setMicDisabledViewCenter.subviews.count == 1
                , let ivSetMicDisabledCenter = setMicDisabledViewCenter.subviews[0] as? UIImageView {
                ivSetMicDisabledCenter.image = UIImage(named: "conference_iv_set_mic_disabled_src")
            }
        } else {
            if setMicDisabledView.subviews.count == 2
                , let ivSetMicDisabled = setMicDisabledView.subviews[0] as? UIButton
                , let lbSetMicDisabled = setMicDisabledView.subviews[1] as? UIButton {
                ivSetMicDisabled.setImage(UIImage(named: "conference_iv_set_mic_disabled_src_selected"), for: .normal)
                lbSetMicDisabled.setTitle("解除静音", for: .normal)
            }
            if setMicDisabledViewCenter.subviews.count == 1
                , let ivSetMicDisabledCenter = setMicDisabledViewCenter.subviews[0] as? UIImageView {
                ivSetMicDisabledCenter.image = UIImage(named: "conference_iv_set_mic_disabled_src_selected")
            }
        }
    }
    
    @objc private func raiseHand() {
        let myParticipantBean = conferenceManager.getParticipantBeans().first { participantBean in
            return participantBean.uuid == conferenceManager.getParticipantUUID()
        }
        guard let myParticipantBean = myParticipantBean else {
            return
        }
        if (myParticipantBean.isRaisingHand()) {
            conferenceManager.lowerHand(onSuccess: { [weak self] in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if self.raiseHandView.subviews.count == 2
                        , let ivRaiseHand = self.raiseHandView.subviews[0] as? UIButton
                        , let lbRaiseHand = self.raiseHandView.subviews[1] as? UIButton {
                        ivRaiseHand.setImage(UIImage(named: "conference_iv_raise_hand_src"), for: .normal)
                        lbRaiseHand.setTitle("举手", for: .normal)
                    }
                    if self.raiseHandCenterView.subviews.count == 1
                        , let ivRaiseHandCenter = self.raiseHandCenterView.subviews[0] as? UIImageView {
                        ivRaiseHandCenter.image = UIImage(named: "conference_iv_raise_hand_src")
                    }
                }
            })
        } else {
            conferenceManager.raiseHand(onSuccess: { [weak self] in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if self.raiseHandView.subviews.count == 2
                        , let ivRaiseHand = self.raiseHandView.subviews[0] as? UIButton
                        , let lbRaiseHand = self.raiseHandView.subviews[1] as? UIButton {
                        ivRaiseHand.setImage(UIImage(named: "conference_iv_raise_hand_src_selected"), for: .normal)
                        lbRaiseHand.setTitle("取消举手", for: .normal)
                    }
                    if self.raiseHandCenterView.subviews.count == 1
                        , let ivRaiseHandCenter = self.raiseHandCenterView.subviews[0] as? UIImageView {
                        ivRaiseHandCenter.image = UIImage(named: "conference_iv_raise_hand_src_selected")
                    }
                }
            })
        }
    }
    
    @objc private func setCameraDisabled() {
        setCameraEnanbledDebouncer.debounce { [weak self] in
            guard let self = self else { return }
            // 延迟隐藏
            self.animateTimer?.invalidate()
            self.animateTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { [weak self] timer in
                guard let self = self else { return }
                self.hideTitleBarAndBottomBar()
            })
            if (self.audioMode) {
                // 语音模式下直接 return
                return
            }
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
                (self.viewControllers[self.curPosition] as? ConferenceChildViewController)?.onLayout(conferenceManager: self.conferenceManager, layoutBeans: self.conferenceManager.getCurrentLayout() ?? [])
            }
        }
    }
    
    @objc private func showPresentationDialog() {
        // 延迟隐藏
        animateTimer?.invalidate()
        animateTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { [weak self] _ in
            guard let self = self else { return }
            self.hideTitleBarAndBottomBar()
        })
        if (audioMode) {
            // 语音模式下直接 return
            return
        }
        if presentationView.subviews.count == 2
            , let ivPresentation = presentationView.subviews[0] as? UIButton
            , let lbPresentation = presentationView.subviews[1] as? UIButton {
            if ("停止共享" == lbPresentation.title(for: .normal)) {
                stopPresent()
                return
            }
        }
        //        if (presenting) {
        //            toast(text: "其他参会者正在内容共享，此时您无法进行内容共享")
        //            return
        //        }
        VerticalListDialog(items: [
            (text: "照片", textColor: nil, handler: {  [weak self] alertAction in
                guard let self = self else { return }
                self.presentImg()
            }), (text: "屏幕", textColor: nil, handler: { [weak self] alertAction in
                guard let self = self else { return }
                self.presentScreen()
            }), (text: "白板", textColor: nil, handler: { [weak self] alertAction in
                guard let self = self else { return }
                self.presentWhiteboard()
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
        viewControllers.append(ConferenceDefaultViewController())
        curPosition = 0
        pageViewController.setViewControllers([viewControllers[curPosition]], direction: .forward, animated: false)
        (viewControllers[curPosition] as? ConferenceChildViewController)?.onLayout(conferenceManager: conferenceManager, layoutBeans: conferenceManager.getCurrentLayout())
        if presentationView.subviews.count == 2
            , let ivPresentation = presentationView.subviews[0] as? UIButton
            , let lbPresentation = presentationView.subviews[1] as? UIButton {
            ivPresentation.setImage(UIImage(named: "conference_iv_presentation_src"), for: .normal)
            lbPresentation.setTitle("内容共享", for: .normal)
        }
        if let forceMcuLayout = conferenceManager.getConferenceStatus()?.forceMcuLayout {
            setPageViewControllerScrollEnabled(!forceMcuLayout)
        } else {
            setPageViewControllerScrollEnabled(false)
        }
        orientationChange2All()
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
            MyShowLogger.instance.showLogger.info(tag: "PresentationManager", "PresentationManager--->\(self.conferenceManager.getPresentationManager())")
            self.conferenceManager.getPresentationManager()?.startImageCapture(uiImage: imgs[0], onSuccess: { [weak self] in
                MyShowLogger.instance.showLogger.info("图片分享成功。")
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    for viewController in self.viewControllers {
                        viewController.removeFromParent()
                    }
                    self.viewControllers.removeAll()
                    self.viewControllers.append(ConferencePresentImgViewController(imgs: imgs))
                    self.curPosition = 0
                    self.pageViewController.setViewControllers([self.viewControllers[self.curPosition]], direction: .forward, animated: false)
                    (self.viewControllers[self.curPosition] as? ConferenceChildViewController)?.onLayout(conferenceManager: self.conferenceManager, layoutBeans: self.conferenceManager.getCurrentLayout() ?? [])
                    if self.presentationView.subviews.count == 2
                        , let ivPresentation = self.presentationView.subviews[0] as? UIButton
                        , let lbPresentation = self.presentationView.subviews[1] as? UIButton {
                        ivPresentation.setImage(UIImage(named: "conference_iv_presentation_src_selected"), for: .normal)
                        lbPresentation.setTitle("停止共享", for: .normal)
                    }
                    self.setPageViewControllerScrollEnabled(false)
                    self.orientationChange2Landscape()
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
                    self.viewControllers.append(ConferencePresentImgViewController(imgs: [uiImage]))
                    self.curPosition = 0
                    self.pageViewController.setViewControllers([self.viewControllers[self.curPosition]], direction: .forward, animated: false)
                    if self.presentationView.subviews.count == 2
                        , let ivPresentation = self.presentationView.subviews[0] as? UIButton
                        , let lbPresentation = self.presentationView.subviews[1] as? UIButton {
                        ivPresentation.setImage(UIImage(named: "conference_iv_presentation_src_selected"), for: .normal)
                        lbPresentation.setTitle("停止共享", for: .normal)
                    }
                    self.setPageViewControllerScrollEnabled(false)
                    self.orientationChange2Landscape()
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
                            self.viewControllers.append(ConferencePresentPDFViewController(url: url))
                            self.curPosition = 0
                            self.pageViewController.setViewControllers([self.viewControllers[self.curPosition]], direction: .forward, animated: false)
                            if self.presentationView.subviews.count == 2
                                , let ivPresentation = self.presentationView.subviews[0] as? UIButton
                                , let lbPresentation = self.presentationView.subviews[1] as? UIButton {
                                ivPresentation.setImage(UIImage(named: "conference_iv_presentation_src_selected"), for: .normal)
                                lbPresentation.setTitle("停止共享", for: .normal)
                            }
                            self.setPageViewControllerScrollEnabled(false)
                            self.orientationChange2Landscape()
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
                                self.viewControllers.append(ConferencePresentImgViewController(imgs: imgs))
                                self.curPosition = 0
                                self.pageViewController.setViewControllers([self.viewControllers[self.curPosition]], direction: .forward, animated: false)
                                if self.presentationView.subviews.count == 2
                                    , let ivPresentation = self.presentationView.subviews[0] as? UIButton
                                    , let lbPresentation = self.presentationView.subviews[1] as? UIButton {
                                    ivPresentation.setImage(UIImage(named: "conference_iv_presentation_src_selected"), for: .normal)
                                    lbPresentation.setTitle("停止共享", for: .normal)
                                }
                                self.setPageViewControllerScrollEnabled(false)
                                self.orientationChange2Landscape()
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
        // 延迟隐藏
        animateTimer?.invalidate()
        animateTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { [weak self] _ in
            guard let self = self else { return }
            self.hideTitleBarAndBottomBar()
        })
//        present(ConferenceParticipantsDialog(), animated: true)
    }
    
    @objc private func showMoreDialog() {
        // 延迟隐藏
        animateTimer?.invalidate()
        animateTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { [weak self] _ in
            guard let self = self else { return }
            self.hideTitleBarAndBottomBar()
        })
//        present(ConferenceMoreDialog(), animated: true)
    }
    
    @objc private func jump2SelectChatTarget() {
//        present(SelectChatTargetDialog(chatTarget: self.chatTarget, onResult: { [weak self] participantBean in
//            guard let self = self else { return }
//            self.chatTarget = participantBean
//            self.lbChatTarget.text = self.chatTarget.getShowName()
//        }), animated: true)
    }
    
    @objc private func switchCamera() {
        conferenceManager.getRTCManager()?.switchCamera()
        (self.viewControllers[self.curPosition] as? ConferenceChildViewController)?.onLayout(conferenceManager: self.conferenceManager, layoutBeans: self.conferenceManager.getCurrentLayout() ?? [])
    }
    
    /**
     显示表情选择控件
     */
    @objc private func showEmojiView() {
        if (emojiView.alpha == 0) {
            // 当前隐藏着就显示
            UIView.animate(withDuration: 0.5) { [weak self] in
                guard let self = self else { return }
                self.emojiView.alpha = 1
            }
            // 隐藏文本输入提示控件
            btnChatTextInputHint.isHidden = true
            // 显示文本输入按钮
            ivChatText.isHidden = false
            // 重新设置 chatView 宽度
            chatView.snp.updateConstraints { make in
                make.width.equalTo(83.screenAdapt())
                //                make.height.equalTo(30.screenAdapt())
                //                make.left.equalToSuperview().offset(8.screenAdapt())
                //                make.bottom.equalToSuperview().offset(-64.screenAdapt() - NavigationBarUtil.getHeight() - 10.screenAdapt())
            }
            // 取消隐藏各种功能按钮的事件
            animateTimer?.invalidate()
        } else {
            // 当前显示着就隐藏
            UIView.animate(withDuration: 0.5) { [weak self] in
                guard let self = self else { return }
                self.emojiView.alpha = 0
            }
            // 延迟隐藏
            animateTimer?.invalidate()
            animateTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { [weak self] _ in
                guard let self = self else { return }
                self.hideTitleBarAndBottomBar()
            })
        }
    }
    
    @objc private func sendEmojiOk() {
        sendMsg(text: "{emoji_ok}", chatTarget: ConferenceViewController.chatTargetAll)
    }
    
    @objc private func sendEmojiGood() {
        sendMsg(text: "{emoji_good}", chatTarget: ConferenceViewController.chatTargetAll)
    }
    
    @objc private func sendEmojiApplaud() {
        sendMsg(text: "{emoji_applause}", chatTarget: ConferenceViewController.chatTargetAll)
    }
    /**
     显示文本输入提示控件
     */
    @objc private func showChatTextInputHint() {
        btnChatTextInputHint.isHidden = false
        // 隐藏表情选择控件
        UIView.animate(withDuration: 0.5) { [weak self] in
            guard let self = self else { return }
            self.emojiView.alpha = 0
        }
        // 隐藏文本输入按钮
        ivChatText.isHidden = true
        // 重新设置 chatView 宽度
        chatView.snp.updateConstraints { make in
            make.width.equalTo(140.screenAdapt())
            //            make.height.equalTo(30.screenAdapt())
            //            make.left.equalToSuperview().offset(8.screenAdapt())
            //            make.bottom.equalToSuperview().offset(-64.screenAdapt() - NavigationBarUtil.getHeight() - 10.screenAdapt())
        }
        // 取消隐藏各种功能按钮的事件
        animateTimer?.invalidate()
    }
    /**
     显示文本输入控件
     */
    @objc private func showChatTextInput() {
        // 显示文本输入框
        chatTextInputView.isHidden = false
        // 标题栏
        titleBarContainer.snp.updateConstraints({ make in
            make.top.equalToSuperview().offset(-titleBarContainer.frame.size.height)
        })
        // 底部栏
        bottomBarContainer.snp.updateConstraints({ make in
            make.bottom.equalToSuperview().offset(bottomBarContainer.frame.size.height)
        })
        // 翻转摄像头按钮和表情/文本聊天
        self.btnSwitchCamera.alpha = 0
        self.chatView.alpha = 0
        self.setMicDisabledViewCenter.alpha = 0
        self.raiseHandCenterView.alpha = 0
        // 隐藏文本输入提示控件
        btnChatTextInputHint.isHidden = true
        // 显示文本输入按钮
        ivChatText.isHidden = false
        // 重新设置 chatView 宽度
        chatView.snp.updateConstraints { make in
            make.width.equalTo(83.screenAdapt())
            make.height.equalTo(30.screenAdapt())
            make.left.equalToSuperview().offset(8.screenAdapt())
            make.bottom.equalToSuperview().offset(-64.screenAdapt() - NavigationBarUtil.getHeight() - 10.screenAdapt())
        }
        tfMsg.text = ""
        // 当前聊天权限
        if (conferenceManager.getConferenceStatus()?.getChatPermission() == .notAllowed) {
            chatTarget = ConferenceViewController.chatTargetNo
            lbChatTarget.text = chatTarget.getShowName()
            tfMsg.placeholder = "全员禁言中，无法发送消息"
            tfMsg.isUserInteractionEnabled = false
        } else if (conferenceManager.getConferenceStatus()?.getChatPermission() == .free) {
            chatTarget = ConferenceViewController.chatTargetAll
            lbChatTarget.text = chatTarget.getShowName()
            tfMsg.placeholder = "请输入消息..."
            tfMsg.isUserInteractionEnabled = true
        } else if (conferenceManager.getConferenceStatus()?.getChatPermission() == .onlyPubIsAllowed) {
            chatTarget = ConferenceViewController.chatTargetAll
            lbChatTarget.text = chatTarget.getShowName()
            tfMsg.placeholder = "请输入消息..."
            tfMsg.isUserInteractionEnabled = true
        } else if (conferenceManager.getConferenceStatus()?.getChatPermission() == .onlyToHostIsAllowed) {
            let hostParticipantBeans = conferenceManager.getParticipantBeans().filter({ participantBean in
                return participantBean.isHost()
            })
            if (hostParticipantBeans.count == 0) {
                chatTarget = ConferenceViewController.chatTargetNo
                lbChatTarget.text = chatTarget.getShowName()
                tfMsg.placeholder = "会中无主持人，无法发送消息"
                tfMsg.isUserInteractionEnabled = false
            } else {
                chatTarget = hostParticipantBeans[0]
                lbChatTarget.text = chatTarget.getShowName()
                tfMsg.placeholder = "请输入消息..."
                tfMsg.isUserInteractionEnabled = true
            }
        }
    }
    
    func unselectSee(uuid: String) {
        conferenceManager.unselectSee(uuid: uuid, onSuccess: { [weak self] in
            guard let self = self else { return }
            (self.viewControllers[self.curPosition] as? ConferenceDefaultViewController)?.hideLockedTip()
            // 选看自己以及取消选看自己时，不会触发服务器推送 layout，所以自己主动更新一下布局
            (self.viewControllers[self.curPosition] as? ConferenceChildViewController)?.onLayout(conferenceManager: self.conferenceManager, layoutBeans: self.conferenceManager.getCurrentLayout() ?? [])
        })
    }
    
    func selectSee(uuid: String) {
        conferenceManager.selectSee(uuid: uuid, onSuccess: { [weak self] in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                Toast.makeText(parent: AppUtil.getTopViewController()?.view, text: "主屏已锁定").show()
//                (self.viewControllers[self.curPosition] as? ConferenceDefaultViewController)?.showLockedTip()
                let conferenceDefaultViewController = viewControllers.first { uiViewController in
                    return uiViewController is ConferenceDefaultViewController
                } as? ConferenceDefaultViewController
                conferenceDefaultViewController?.showLockedTip()
                // 选看自己以及取消选看自己时，不会触发服务器推送 layout，所以自己主动更新一下布局
                (self.viewControllers[self.curPosition] as? ConferenceChildViewController)?.onLayout(conferenceManager: self.conferenceManager, layoutBeans: self.conferenceManager.getCurrentLayout() ?? [])
            }
        }, onFailure: {  [weak self] error in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                Toast.makeText(parent: AppUtil.getTopViewController()?.view, text: error.msg).show()
            }
        })
    }
    
    func sendMsg(text: String, chatTarget: rtc.ParticipantBean) {
        if (text.isEmpty) {
            return
        }
        if (conferenceManager.getConferenceStatus()?.getChatPermission() == .notAllowed) {
            toast(text: "禁止聊天")
            return
        }
        if (chatTarget.uuid == ConferenceViewController.chatTargetNo.uuid) {
            toast(text: "禁止聊天")
            return
        }
        if (chatTarget.uuid == ConferenceViewController.chatTargetPleaseSelect.uuid) {
            toast(text: "请选择聊天目标")
            return
        }
        if (chatTarget.uuid == ConferenceViewController.chatTargetAll.uuid
            && conferenceManager.getConferenceStatus()?.getChatPermission() == .onlyToHostIsAllowed) {
            toast(text: "不允许发送公开表情")
            return
        }
        let msgBean = MsgBean(nickname: chatTarget.getShowName()
                          , uuid: conferenceManager.getParticipantUUID()
                          , is_private: chatTarget.uuid == ConferenceViewController.chatTargetAll.uuid ? 0 : 1
                          , text: text)
        msgBeans.append(msgBean)
//        msgListView.insert(msgBean: msgBean)
        if (chatTarget.uuid == ConferenceViewController.chatTargetAll.uuid) {
            conferenceManager.sendMsg(text: text)
        } else {
            conferenceManager.sendMsg(text: text, uuids: [chatTarget.uuid ?? ""])
        }
        NotificationCenter.default.post(name: NSNotification.Name(ConferenceViewController.NOTIFICATION_NAME_ON_MESSAGE), object: nil, userInfo: [ConferenceViewController.NOTIFICATION_PARAM_NAME_MSG_BEAN: msgBean])
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
    
    func isAudioMode() -> Bool {
        return audioMode
    }
    
    func setAudioMode(_ audioMode: Bool) {
        self.audioMode = audioMode
        if (audioMode) {
            // 停止共享
            conferenceManager.getPresentationManager()?.stop()
            if presentationView.subviews.count == 2
                , let ivPresentation = presentationView.subviews[0] as? UIButton
                , let lbPresentation = presentationView.subviews[1] as? UIButton {
                ivPresentation.setImage(UIImage(named: "conference_iv_presentation_src"), for: .normal)
                lbPresentation.setTitle("内容共享", for: .normal)
            }
            for viewController in viewControllers {
                viewController.removeFromParent()
            }
            viewControllers.removeAll()
//            viewControllers.append(ConferenceAudioModeViewController())
            curPosition = 0
            pageViewController.setViewControllers([self.viewControllers[self.curPosition]], direction: .forward, animated: false)
            // 禁用摄像头
            let setCameraEnabled = conferenceManager.getRTCManager()?.setCameraEnabled(enabled: false)
            if setCameraEnabled == true, let image = UIImage(named: "conference_iv_audio_mode_src") {
                // 发送语音模式图片
                conferenceManager.getRTCManager()?.startImageCapture(image)
            }
            setPageViewControllerScrollEnabled(false)
            orientationChange2Landscape()
            conferenceManager.getRTCManager()?.layout("0:0")
        } else {
            for viewController in viewControllers {
                viewController.removeFromParent()
            }
            viewControllers.removeAll()
            viewControllers.append(ConferenceDefaultViewController())
            curPosition = 0
            pageViewController.setViewControllers([self.viewControllers[self.curPosition]], direction: .forward, animated: false)
            (viewControllers[curPosition] as? ConferenceChildViewController)?.onLayout(conferenceManager: conferenceManager, layoutBeans: conferenceManager.getCurrentLayout())
            if self.setCameraDisabledView.subviews.count == 2
                , let ivSetCameraDisabled = self.setCameraDisabledView.subviews[0] as? UIButton
                , let lbSetCameraDisabled = self.setCameraDisabledView.subviews[1] as? UIButton
                , "关闭视频" == lbSetCameraDisabled.title(for: .normal) {
                // 开启摄像头
                conferenceManager.getRTCManager()?.setCameraEnabled(enabled: true)
            } else {
                // 发送摄像头关闭图片
                if let image = UIImage(named: "conference_iv_camera_disabled_src") {
                    self.conferenceManager.getRTCManager()?.startImageCapture(image)
                }
            }

            if let conferenceStatusBean = conferenceManager.getConferenceStatus()
                , let presenterUUID = conferenceStatusBean.presenterUUID
                , let forceMcuLayout = conferenceStatusBean.forceMcuLayout {
                if (conferenceStatusBean.presenterUUID == nil || presenterUUID.isEmpty) {
                    // 没有共享流
                    self.setPageViewControllerScrollEnabled(!forceMcuLayout)
                    orientationChange2All()
                    conferenceManager.getRTCManager()?.layout("1:5")
                } else {
                    // 有共享流
                    orientationChange2Landscape()
                    setPageViewControllerScrollEnabled(false)
                    conferenceManager.getRTCManager()?.layout("0:1")

                    if (viewControllers.count > curPosition) {
                        (viewControllers[curPosition] as? ConferenceChildViewController)?.onWhiteboardMarkPermissionChanged(
                            isWhiteboardAllowOtherMark: conferenceStatusBean.isWhiteboardAllowOtherMark()
                            , screenShare: conferenceStatusBean.screenshare)
                    }
                }
            } else {
                orientationChange2All()
                setPageViewControllerScrollEnabled(false)
                conferenceManager.getRTCManager()?.layout("1:5")
            }
        }
    }
    
    func getUnreadCount() -> Int {
        return unreadCount
    }
    
    func setUnreadCount(_ unreadCount: Int) {
        self.unreadCount = unreadCount
        lbUnreadCount.text = "\(unreadCount)"
        lbUnreadCount.isHidden = unreadCount == 0
    }
    
    func isPresentingWhiteboardByMyself() -> Bool {
        let conferencePresentImgViewController = viewControllers.first { vc in
            return vc is ConferencePresentImgViewController
        }
        if (conferencePresentImgViewController != nil) {
            return true
        }
        let conferencePresentPDFViewController = viewControllers.first { vc in
            return vc is ConferencePresentPDFViewController
        }
        if (conferencePresentPDFViewController != nil) {
            return true
        }
        return false
    }
    
    func setMicEnabled() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if (!PermissionType.AUDIO_RECORD.permissionChecker.isAuthorized()) {
//                let message = "麦克风被禁用，请在本机的“设置”—“隐私”—“麦克风”中允许\(AppUtil.getAppName() ?? "")访问您的麦克风"
//                CommonDialog(title: nil, message: message, negativeButtonText: "暂不", positiveButtonText: "去设置", positiveButtonHandler: { UIAlertAction in
//                    if let url = URL(string: UIApplication.openSettingsURLString) {
//                        UIApplication.shared.open(url, options: [:])
//                    }
//                }).show(uiViewController: self)
                return
            }
            guard let micEnabled = self.conferenceManager.getRTCManager()?.isMicEnabled() else {
                return
            }
            guard let setMicEnabled = self.conferenceManager.getRTCManager()?.setMicEnabled(enabled: true) else {
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
                if self.setMicDisabledViewCenter.subviews.count == 1
                    , let ivSetMicDisabledCenter = self.setMicDisabledViewCenter.subviews[0] as? UIImageView {
                    ivSetMicDisabledCenter.image = UIImage(named: "conference_iv_set_mic_disabled_src")
                }
            } else {
                if self.setMicDisabledView.subviews.count == 2
                    , let ivSetMicDisabled = self.setMicDisabledView.subviews[0] as? UIButton
                    , let lbSetMicDisabled = self.setMicDisabledView.subviews[1] as? UIButton {
                    ivSetMicDisabled.setImage(UIImage(named: "conference_iv_set_mic_disabled_src_selected"), for: .normal)
                    lbSetMicDisabled.setTitle("解除静音", for: .normal)
                }
                if self.setMicDisabledViewCenter.subviews.count == 1
                    , let ivSetMicDisabledCenter = self.setMicDisabledViewCenter.subviews[0] as? UIImageView {
                    ivSetMicDisabledCenter.image = UIImage(named: "conference_iv_set_mic_disabled_src_selected")
                }
            }
        }
    }
}

// MARK: - UIScrollViewDelegate
extension ConferenceViewController: UIScrollViewDelegate {
    
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
extension ConferenceViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if (!completed) {
            return
        }
        guard let curViewController = pageViewController.viewControllers?[0] else {
            return
        }
        curPosition = viewControllers.firstIndex(of: curViewController) ?? 0
        if (viewControllers[curPosition] is ConferenceDefaultViewController) {
            requestLayoutThrottler.throttle { [weak self] in
                guard let self = self else { return }
                self.conferenceManager.getRTCManager()?.layout("1:5")
            }
//        } else if (viewControllers[curPosition] is ConferenceGalleryViewController) {
//            let galleryParticipantBeans = conferenceManager.getParticipantBeans().filter { participantBean in
//                // 过滤自己
//                if (participantBean.uuid == self.conferenceManager.getParticipantUUID()) {
//                    return false
//                }
//                // 过滤等候室中的人
//                if (participantBean.isInWaitingRoom()) {
//                    return false
//                }
//                return true
//            }
//            // 多一个 ConferenceDefaultViewController，所以 -1
//            let fromIndex = (self.curPosition - 1) * 3
//            let toIndex = min(fromIndex + 3, galleryParticipantBeans.count)
//            if (fromIndex <= toIndex) {
//                let uuids = galleryParticipantBeans[fromIndex..<toIndex].map { participantBean in
//                    return participantBean.uuid ?? ""
//                }
//                requestLayoutThrottler.throttle { [weak self] in
//                    guard let self = self else { return }
//                    self.conferenceManager.getRTCManager()?.overrideLayout("0:3", uuids: uuids)
//                }
//            }
        }
        for i in 0..<pagePointIndicators.subviews.count {
            pagePointIndicators.subviews[i].backgroundColor = (i == curPosition) ? .main_color : .background_color_ffffffff
        }
    }
}

// MARK: - UIPageViewControllerDataSource
extension ConferenceViewController: UIPageViewControllerDataSource {
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

// MARK: - OnConferenceListener
extension ConferenceViewController: OnConferenceListener {
    
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
            if self.setMicDisabledViewCenter.subviews.count == 1
                , let ivSetMicDisabledCenter = self.setMicDisabledViewCenter.subviews[0] as? UIImageView {
                ivSetMicDisabledCenter.image = UIImage(named: "conference_iv_set_mic_disabled_src")
            }
        } else {
            if self.setMicDisabledView.subviews.count == 2
                , let ivSetMicDisabled = self.setMicDisabledView.subviews[0] as? UIButton
                , let lbSetMicDisabled = self.setMicDisabledView.subviews[1] as? UIButton {
                ivSetMicDisabled.setImage(UIImage(named: "conference_iv_set_mic_disabled_src_selected"), for: .normal)
                lbSetMicDisabled.setTitle("解除静音", for: .normal)
            }
            if self.setMicDisabledViewCenter.subviews.count == 1
                , let ivSetMicDisabledCenter = self.setMicDisabledViewCenter.subviews[0] as? UIImageView {
                ivSetMicDisabledCenter.image = UIImage(named: "conference_iv_set_mic_disabled_src_selected")
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
//        guard let participantCuids = conferenceParam.participantCuids else {
//            return
//        }
//        if (participantCuids.isEmpty) {
//            return
//        }
//        conferenceManager.outgoingCall(cuids: participantCuids, onSuccess:  {
//            MyShowLogger.instance.showLogger.info("邀请成功, participantCuids--->\(participantCuids)")
//        }, onFailure: { e in
//            MyShowLogger.instance.showLogger.info("邀请失败, error--->\(e)")
//        })
    }
    
    func updateSetMicDisabledViewAndRaiseHandView(myParticipantBean: ParticipantBean?) {
        guard let myParticipantBean = myParticipantBean else { return }
        if (conferenceManager.getRTCManager()?.isMicEnabled() == false) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                guard let conferenceStatusBean = self.conferenceManager.getConferenceStatus() else { return }
                if (myParticipantBean.isHost()) {
                    // 是主持人，无论什么情况都可以控制自己的 mic 开关
                    self.setMicDisabledView.isHidden = false
                    self.setMicDisabledViewCenter.isHidden = false
                    self.raiseHandView.isHidden = true
                    self.raiseHandCenterView.isHidden = true
                } else {
                    // 不是主持人
                    if (myParticipantBean.isServerMuted() && !conferenceStatusBean.isAllowUnmuteSelf()) {
                        // 被服务器静音，并且不允许自己解除静音，显示举手
                        self.setMicDisabledView.isHidden = true
                        self.setMicDisabledViewCenter.isHidden = true
                        self.raiseHandView.isHidden = false
                        self.raiseHandCenterView.isHidden = false
                    } else {
                        // 没有被服务器静音，或者允许自己解除静音，还是显示 mic 开关
                        self.setMicDisabledView.isHidden = false
                        self.setMicDisabledViewCenter.isHidden = false
                        self.raiseHandView.isHidden = true
                        self.raiseHandCenterView.isHidden = true
                    }
                }
            }
        }
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
            self.orientationChange2All()
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
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.dismissAllPresentedViewControllers { [weak self] in
                MyShowLogger.instance.showLogger.debug("退出会议界面")
                guard let self = self else { return }
                var message = "会议结束"
                if (e.msg == "Call disconnected") {
                    message = "被主持人移出会议。"
                }
                if (e.msg == "Disconnected by another participant") {
                    message = "其他参会者将你踢出了会议室。"
                }
                if (e.msg == "1434/guest not allowed") {
                    message = "禁止未登录用户入会。"
                }
                if (e.msg == "1402/up to meeting max calls") {
                    message = "超过会议最大呼叫数。"
                }
                if (e.msg == "User initiated disconnect") {
                    message = "主持人中断了会议。"
                }
                if (e.msg == "Timeout waiting for conference host to join or permit access to locked conference") {
                    message = "主持人超时未处理，将自动退出等候室。"
                }
                if (e.msg == "Request failed: forbidden (403)") {
                    message = "会议正在结束中"
                }
                if (e.msg == "1434/guest not allowed") {
                    message = "不允许访客入会"
                }
                if (e.msg == "1402/up to meeting max calls") {
                    message = "超过会议最大呼叫数"
                }
                if (e.msg == "1418/adhoc disabled") {
                    message = "会议室只用于预约，即时呼叫失败"
                }
                if (e.msg == "与服务器连接超时") {
                    message = "与服务器连接超时"
                }
                CommonDialog(title: nil, message: message, negativeButtonText: nil, positiveButtonHandler: { [weak self] _ in
                    guard let self = self else { return }
                    self.navigationController?.popViewController(animated: true)
                })
                .show(uiViewController: self, cancelable: false)
            }
        }
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
            if let living = conferenceStatusBean.living {
                self.livingView.isHidden = !living
            }
            if let recording = conferenceStatusBean.recording {
                self.recordingView.isHidden = !recording
            }
        }
        updateSetMicDisabledViewAndRaiseHandView(myParticipantBean: conferenceManager.getParticipantBean(uuid: conferenceManager.getParticipantUUID()))
        NotificationCenter.default.post(name: NSNotification.Name(ConferenceViewController.NOTIFICATION_NAME_ON_CONFERENCE_STATUS_UPDATE), object: nil, userInfo: [ConferenceViewController.NOTIFICATION_PARAM_NAME_CONFERENCE_STATUS: conferenceStatusBean])
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
        
        // 下面的代码是为了解决滑动过程中，有响应平台操作时，可能画面模式不对的问题，如果能保证正确响应，下面的代码应该可以去掉
        let containsPresentation = layoutBeans.contains { layoutBean in
            return layoutBean.ssrc == SdpUtil.PRESENTATION_VIDEO_RECEIVE_SSRC_ID
        }
        if (containsPresentation) {
            // 可能在滑动过程中，有人共享了双流
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if (self.pagePointIndicators.isHidden) {
                    self.curPosition = 0
                    self.pageViewController.setViewControllers([self.viewControllers[self.curPosition]], direction: .forward, animated: false)
                    self.orientationChange2Landscape()
                    self.setPageViewControllerScrollEnabled(false)
                    
                    if (self.viewControllers.count > self.curPosition) {
                        (viewControllers[self.curPosition] as? ConferenceChildViewController)?.onWhiteboardMarkPermissionChanged(
                            isWhiteboardAllowOtherMark: self.conferenceManager.getConferenceStatus()?.isWhiteboardAllowOtherMark() ?? false
                            , screenShare: self.conferenceManager.getConferenceStatus()?.screenshare
                            , fold: false)
                    }
                }
                if (layoutBeans.count > 2) {
                    self.conferenceManager.getRTCManager()?.layout("0:1")
                }
            }
        }
        if (conferenceManager.getConferenceStatus()?.forceMcuLayout == true) {
            // 可能在滑动过程中，设置了平台控分屏
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if (self.pagePointIndicators.isHidden) {
                    self.curPosition = 0
                    self.pageViewController.setViewControllers([self.viewControllers[self.curPosition]], direction: .forward, animated: false)
//                    self.orientationChange2Landscape()
                    self.setPageViewControllerScrollEnabled(false)
                }
//                if (layoutBeans.count > 2) {
//                    self.conferenceManager.getRTCManager()?.layout("0:1")
//                }
            }
        }
    }
    
    func onParticipantsUpdate(_ participantBeans: [rtc.ParticipantBean]) {
//        MyShowLogger.instance.showLogger.info("onParticipantsUpdate, participantBeans--->\(participantBeans)")
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
        updateSetMicDisabledViewAndRaiseHandView(myParticipantBean: myParticipantBean)
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
        viewControllers.forEach { viewController in
            (viewController as? ConferenceChildViewController)?.onParticipantsUpdate(conferenceManager: conferenceManager, participantBeans: participantBeans)
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.lbParticipants.text = "参会人(\(participantBeans.count))"
            // 修改聊天目标
            if (self.chatTarget.uuid != ConferenceViewController.chatTargetAll.uuid) {
                if (conferenceManager.getConferenceStatus()?.getChatPermission() == .free) {
                    let participantBean = participantBeans.first { participantBean in
                        return self.chatTarget.uuid == participantBean.uuid
                    }
                    if (participantBean == nil) {
                        // 当前聊天目标退出会议，聊天目标变成"请选择"
                        self.chatTarget = ConferenceViewController.chatTargetPleaseSelect
                        self.lbChatTarget.text = self.chatTarget.getShowName()
                    } else {
                        if (participantBean!.isInWaitingRoom()) {
                            // 当前聊天目标在等候室，聊天目标变成"请选择"
                            self.chatTarget = ConferenceViewController.chatTargetPleaseSelect
                            self.lbChatTarget.text = self.chatTarget.getShowName()
                        }
                    }
                } else if (conferenceManager.getConferenceStatus()?.getChatPermission() == .onlyToHostIsAllowed) {
                    let participantBean = participantBeans.first { participantBean in
                        return self.chatTarget.uuid == participantBean.uuid
                    }
                    if (participantBean == nil) {
                        // 当前聊天目标退出会议，聊天目标变成"请选择"
                        self.chatTarget = ConferenceViewController.chatTargetPleaseSelect
                        self.lbChatTarget.text = self.chatTarget.getShowName()
                    } else {
                        if (participantBean!.isInWaitingRoom() || !participantBean!.isHost()) {
                            // 当前聊天目标在等候室或者不是主持人了，聊天目标变成"请选择"
                            self.chatTarget = ConferenceViewController.chatTargetPleaseSelect
                            self.lbChatTarget.text = self.chatTarget.getShowName()
                        }
                    }
                }
            }
            // 仅允许参会人私聊主持人时，需要检查是否有人变成了主持人
            if (conferenceManager.getConferenceStatus()?.getChatPermission() == .onlyToHostIsAllowed) {
                let hostParticipantBeans = participantBeans.filter { participantBean in
                   return participantBean.isHost()
               }
               if (hostParticipantBeans.count == 0) {
                   self.tfMsg.placeholder = "会中无主持人，无法发送消息"
                   self.tfMsg.isUserInteractionEnabled = false
               } else {
                   self.tfMsg.placeholder = "请输入消息..."
                   self.tfMsg.isUserInteractionEnabled = true
               }
           }
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(ConferenceViewController.NOTIFICATION_NAME_ON_PARTICIPANTS_UPDATE), object: nil, userInfo: [ConferenceViewController.NOTIFICATION_PARAM_NAME_PARTICIPANTS: participantBeans])
        if (audioMode) {
            // 语音模式下直接 return
            return
        }
//        updateParticipantsThrottler.throttle { [weak self] in
//            guard let self = self else { return }
//            DispatchQueue.main.async { [weak self] in
//                guard let self = self else { return }
//                let galleryParticipantBeans = participantBeans.filter { participantBean in
//                    // 过滤自己
//                    if (participantBean.uuid == self.conferenceManager.getParticipantUUID()) {
//                        return false
//                    }
//                    // 过滤等候室中的人
//                    if (participantBean.isInWaitingRoom()) {
//                        return false
//                    }
//                    return true
//                }
//                let galleryCount = Int(ceil(Double(galleryParticipantBeans.count) / 3.0))
//                let curGalleryCount = self.viewControllers.filter { viewController in
//                    return viewController is ConferenceGalleryViewController
//                }.count
//                if (galleryCount > curGalleryCount) {
//                    for index in curGalleryCount..<galleryCount {
//                        self.viewControllers.append(ConferenceGalleryViewController())
//                    }
//                } else {
//                    let diff = curGalleryCount - galleryCount
//                    var i = 0
//                    for index in self.viewControllers.indices.reversed() {
//                        if (self.viewControllers[index] is ConferenceGalleryViewController && i < diff) {
//                            self.viewControllers.remove(at: index)
//                            i += 1
//                        }
//                    }
//                }
//                if viewControllers.count > curPosition, let viewController = self.viewControllers[self.curPosition] as? ConferenceGalleryViewController {
//                    // 多一个 ConferenceDefaultViewController，所以 -1
//                    if (self.curPosition > 0) {
//                        let fromIndex = (self.curPosition - 1) * 3
//                        let toIndex = min(fromIndex + 3, galleryParticipantBeans.count)
//                        if (fromIndex <= toIndex) {
//                            let uuids = galleryParticipantBeans[fromIndex..<toIndex].map { participantBean in
//                                return participantBean.uuid ?? ""
//                            }
//                            let curUuids = viewController.layoutBeans.filter({ layoutBean in
//                                return layoutBean.participantUUID != self.conferenceManager.getParticipantUUID()
//                            }).map { layoutBean in
//                                return layoutBean.participantUUID
//                            }
//                            if (uuids != curUuids) {
//                                self.conferenceManager.getRTCManager()?.overrideLayout("0:3", uuids: uuids)
//                            }
//                        }
//                    }
//                }
//                self.pagePointIndicators.subviews.forEach { view in
//                    view.removeFromSuperview()
//                }
//                // 多一个 ConferenceDefaultViewController，所以 +1
//                for i in 0..<self.viewControllers.count {
//                    let view = UIView()
//                    view.backgroundColor = (i == self.curPosition) ? Colors.MAIN_COLOR : Colors.BACKGROUND_COLOR_FFFFFFFF
//                    view.layer.cornerRadius = 3.screenAdapt()
//                    self.pagePointIndicators.addSubview(view)
//                    view.snp.makeConstraints { make in
//                        make.width.height.equalTo(6.screenAdapt())
//                        make.left.equalToSuperview().offset(6.screenAdapt() * CGFloat(i) + 3.screenAdapt() * CGFloat(i))
//                        make.centerY.equalToSuperview()
//                    }
//                }
//                self.pagePointIndicators.snp.updateConstraints { make in
//                    make.width.equalTo(6.screenAdapt() * CGFloat(self.viewControllers.count) + 3.screenAdapt() * CGFloat(self.viewControllers.count - 1))
//                }
//            }
//        }
    }
    
    func onPresentationStart(_ presentationStartBean: PresentationStartBean) {
        MyShowLogger.instance.showLogger.info("onPresentationStart， presentationStartBean--->\(presentationStartBean)")
        if (audioMode) {
            // 语音模式下直接 return
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.curPosition = 0
            self.pageViewController.setViewControllers([self.viewControllers[self.curPosition]], direction: .forward, animated: false)
            self.orientationChange2Landscape()
            self.setPageViewControllerScrollEnabled(false)
            self.conferenceManager.getRTCManager()?.layout("0:1")
        }
    }
    
    func onPresentationStop() {
        MyShowLogger.instance.showLogger.info("onPresentationStop")
        if (audioMode) {
            // 语音模式下直接 return
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            for viewController in self.viewControllers {
                viewController.removeFromParent()
            }
            self.viewControllers.removeAll()
            self.viewControllers.append(ConferenceDefaultViewController())
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
            if let forceMcuLayout = self.conferenceManager.getConferenceStatus()?.forceMcuLayout {
                self.setPageViewControllerScrollEnabled(!forceMcuLayout)
            } else {
                self.setPageViewControllerScrollEnabled(false)
            }
            self.orientationChange2All()
            self.conferenceManager.getRTCManager()?.layout("1:5")
        }
    }
    
    func onScreenPresentationStop() {
        for viewController in viewControllers {
            viewController.removeFromParent()
        }
        viewControllers.removeAll()
        viewControllers.append(ConferenceDefaultViewController())
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
        if let forceMcuLayout = conferenceManager.getConferenceStatus()?.forceMcuLayout {
            setPageViewControllerScrollEnabled(!forceMcuLayout)
        } else {
            setPageViewControllerScrollEnabled(false)
        }
        orientationChange2All()
        conferenceManager.getRTCManager()?.layout("1:5")
    }
    
    func onWhiteboardStart(_ whiteboardStartBean: WhiteboardStartBean) {
        MyShowLogger.instance.showLogger.info("onWhiteboardStart, whiteboardStartBean--->\(whiteboardStartBean)")
        if (viewControllers.count > curPosition) {
            (viewControllers[curPosition] as? ConferenceChildViewController)?.onWhiteboardStart(url: whiteboardStartBean.whiteboardBackgroundUrl)
        }
    }
    
    func onWhiteboardStop() {
        MyShowLogger.instance.showLogger.info("onWhiteboardStop")
        if (viewControllers.count > curPosition) {
            (viewControllers[curPosition] as? ConferenceChildViewController)?.onWhiteboardStop()
        }
    }
    
    func onWhiteboardAddLine(_ whiteboardAddLineBean: WhiteboardAddLineBean) {
        MyShowLogger.instance.showLogger.info("onWhiteboardAddLine, whiteboardAddLineBean--->\(whiteboardAddLineBean)")
        if (viewControllers.count > curPosition) {
            (viewControllers[curPosition] as? ConferenceChildViewController)?.onWhiteboardAddLine(whiteboardAddLineBean: whiteboardAddLineBean)
        }
    }
    
    func onWhiteboardDeleteLine(_ whiteboardDeleteLineBean: WhiteboardDeleteLineBean) {
        MyShowLogger.instance.showLogger.info("onWhiteboardDeleteLine, whiteboardDeleteLineBean--->\(whiteboardDeleteLineBean)")
        if (viewControllers.count > curPosition) {
            (viewControllers[curPosition] as? ConferenceChildViewController)?.onWhiteboardDeleteLine(whiteboardDeleteLineBean: whiteboardDeleteLineBean)
        }
    }
    
    func onWhiteboardMarkPermissionChanged(_ isWhiteboardAllowOtherMark: Bool, screenShare: Int?) {
        MyShowLogger.instance.showLogger.info("onWhiteboardMarkPermissionChanged, isWhiteboardAllowOtherMark--->\(isWhiteboardAllowOtherMark)")
        if (viewControllers.count > curPosition) {
            (viewControllers[curPosition] as? ConferenceChildViewController)?.onWhiteboardMarkPermissionChanged(
                isWhiteboardAllowOtherMark: isWhiteboardAllowOtherMark
                , screenShare: screenShare)
        }
    }
    
    func onWhiteboardClearLine() {
        MyShowLogger.instance.showLogger.info("onWhiteboardClearLine")
        if (viewControllers.count > curPosition) {
            (viewControllers[curPosition] as? ConferenceChildViewController)?.onWhiteboardClearLine()
        }
    }
    
    func onWhiteboardBackgroundUpdate(_ url: String) {
        MyShowLogger.instance.showLogger.info("onWhiteboardBackgroundUpdate: url--->\(url)")
        if (viewControllers.count > curPosition) {
            (viewControllers[curPosition] as? ConferenceChildViewController)?.onWhiteboardBackgroundUpdate(url: url)
        }
    }
    
    func onChatPermissionChanged(_ chatPermission: ChatPermission) {
        if (chatPermission == .notAllowed) {
            // 禁止聊天时，聊天目标变成无
            chatTarget = ConferenceViewController.chatTargetNo
        } else {
            // 权限变化时，重新选择聊天目标
            chatTarget = ConferenceViewController.chatTargetPleaseSelect
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.lbChatTarget.text = self.chatTarget.getShowName()
            if (chatPermission == .notAllowed) {
                self.tfMsg.placeholder = "全员禁言中，无法发送消息"
                self.tfMsg.isUserInteractionEnabled = false
            } else if (chatPermission == .free) {
                self.tfMsg.placeholder = "请输入消息..."
                self.tfMsg.isUserInteractionEnabled = true
            } else if (chatPermission == .onlyPubIsAllowed) {
                self.tfMsg.placeholder = "请输入消息..."
                self.tfMsg.isUserInteractionEnabled = true
            } else if (chatPermission == .onlyToHostIsAllowed) {
                let hostParticipantBeans = self.conferenceManager.getParticipantBeans().filter({ participantBean in
                    return participantBean.isHost()
                })
                if (hostParticipantBeans.count == 0) {
                    self.tfMsg.placeholder = "会中无主持人，无法发送消息"
                    self.tfMsg.isUserInteractionEnabled = false
                } else {
                    self.tfMsg.placeholder = "请输入消息..."
                    self.tfMsg.isUserInteractionEnabled = true
                }
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name(ConferenceViewController.NOTIFICATION_NAME_ON_CHAT_PERMISSION_CHANGED), object: nil, userInfo: [ConferenceViewController.NOTIFICATION_PARAM_NAME_CHAT_PERMISSION: chatPermission])
    }
    
    func onLivingChatPermissionChanged(_ livingChatPermission: LivingChatPermission) {
        NotificationCenter.default.post(name: NSNotification.Name(ConferenceViewController.NOTIFICATION_NAME_ON_LIVING_CHAT_PERMISSION_CHANGED), object: nil, userInfo: [ConferenceViewController.NOTIFICATION_PARAM_NAME_LIVING_CHAT_PERMISSION: livingChatPermission])
    }
    
    func onForceMCULayoutChanged(_ forceMCULayout: Bool) {
        MyShowLogger.instance.showLogger.info("onForceMCULayoutChanged, forceMCULayout--->\(forceMCULayout)")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.curPosition = 0
            self.pageViewController.setViewControllers([self.viewControllers[self.curPosition]], direction: .forward, animated: false)
            if (forceMCULayout) {
                setPageViewControllerScrollEnabled(false)
//                conferenceManager.getRTCManager()?.layout("0:1")
            } else {
                setPageViewControllerScrollEnabled(true)
                conferenceManager.getRTCManager()?.layout("1:5")
            }
        }
    }
    
    func onMessage(_ msgBean: MsgBean) {
        msgBeans.append(msgBean)
        unreadCount += 1
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
//            self.msgListView.insert(msgBean: msgBean)
            self.lbUnreadCount.text = "\(self.unreadCount)"
            self.lbUnreadCount.isHidden = self.unreadCount == 0
        }
        NotificationCenter.default.post(name: NSNotification.Name(ConferenceViewController.NOTIFICATION_NAME_ON_MESSAGE), object: nil, userInfo: [ConferenceViewController.NOTIFICATION_PARAM_NAME_MSG_BEAN: msgBean])
    }
    
    func onSubtitle(_ msgBean: MsgBean) {
        let attributedString = NSMutableAttributedString(string: msgBean.text ?? "")
        attributedString.addAttribute(NSAttributedString.Key.kern, value: 2.0, range: NSRange(location: 0, length: attributedString.length))
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.lbSubtitles.attributedText = attributedString
        }
    }
    
    func onServerAudioMuteChanged(_ myParticipantBean: ParticipantBean) {
        MyShowLogger.instance.showLogger.info("onServerAudioMuteChanged, myParticipantBean--->\(myParticipantBean)")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if (myParticipantBean.isServerMuted()) {
                guard let setMicEnabled = self.conferenceManager.getRTCManager()?.setMicEnabled(enabled: false) else {
                    return
                }
                if (!setMicEnabled) {
                    return
                }
                if self.setMicDisabledView.subviews.count == 2
                        , let ivSetMicDisabled = self.setMicDisabledView.subviews[0] as? UIButton
                        , let lbSetMicDisabled = self.setMicDisabledView.subviews[1] as? UIButton {
                    ivSetMicDisabled.setImage(UIImage(named: "conference_iv_set_mic_disabled_src_selected"), for: .normal)
                    lbSetMicDisabled.setTitle("解除静音", for: .normal)
                }
                if self.setMicDisabledViewCenter.subviews.count == 1
                    , let ivSetMicDisabledCenter = self.setMicDisabledViewCenter.subviews[0] as? UIImageView {
                    ivSetMicDisabledCenter.image = UIImage(named: "conference_iv_set_mic_disabled_src_selected")
                }
                updateSetMicDisabledViewAndRaiseHandView(myParticipantBean: myParticipantBean)
            } else {
                self.setMicDisabledView.isHidden = false
                self.setMicDisabledViewCenter.isHidden = false
                self.raiseHandView.isHidden = true
                self.raiseHandCenterView.isHidden = true
            }
        }
    }
    
    func onNotifyOpenAudio() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.notifyOpenAudioDialog?.dismiss()
            self.notifyOpenAudioDialog = CommonDialog(title: nil, message: "主持人请求您开启麦克风", positiveButtonText: "开启") { _ in
                guard let setMicEnabled = self.conferenceManager.getRTCManager()?.setMicEnabled(enabled: true) else {
                    return
                }
                if (!setMicEnabled) {
                    return
                }
                if self.setMicDisabledView.subviews.count == 2
                        , let ivSetMicDisabled = self.setMicDisabledView.subviews[0] as? UIButton
                        , let lbSetMicDisabled = self.setMicDisabledView.subviews[1] as? UIButton {
                    ivSetMicDisabled.setImage(UIImage(named: "conference_iv_set_mic_disabled_src"), for: .normal)
                    lbSetMicDisabled.setTitle("静音", for: .normal)
                }
                if self.setMicDisabledViewCenter.subviews.count == 1
                    , let ivSetMicDisabledCenter = self.setMicDisabledViewCenter.subviews[0] as? UIImageView {
                    ivSetMicDisabledCenter.image = UIImage(named: "conference_iv_set_mic_disabled_src")
                }
            }
            self.notifyOpenAudioDialog?.show(uiViewController: self)
        }
    }
    
    func onServerVideoMuteChanged(_ myParticipantBean: ParticipantBean) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if (myParticipantBean.isServerVideoMuted()) {
                self.toast(text: "您已被主持人关闭视频")
                guard let setCameraEnabled = self.conferenceManager.getRTCManager()?.setCameraEnabled(enabled: false) else {
                    return
                }
                if (!setCameraEnabled) {
                    return
                }
                if self.setCameraDisabledView.subviews.count == 2
                        , let ivSetCameraDisabled = self.setCameraDisabledView.subviews[0] as? UIButton
                        , let lbSetCameraDisabled = self.setCameraDisabledView.subviews[1] as? UIButton {
                    ivSetCameraDisabled.setImage(UIImage(named: "conference_iv_set_camera_disabled_src_selected"), for: .normal)
                    lbSetCameraDisabled.setTitle("开启视频", for: .normal)
                }
                // 发送摄像头关闭图片
                if let image = UIImage(named: "conference_iv_camera_disabled_src") {
                    self.conferenceManager.getRTCManager()?.startImageCapture(image)
                }
                (self.viewControllers[self.curPosition] as? ConferenceChildViewController)?.onLayout(conferenceManager: self.conferenceManager, layoutBeans: self.conferenceManager.getCurrentLayout() ?? [])
            }
        }
    }
    
    func onAllowRaiseHand() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.toast(text: "主持人已允许您发言")
            guard let setMicEnabled = self.conferenceManager.getRTCManager()?.setMicEnabled(enabled: true) else {
                return
            }
            if (!setMicEnabled) {
                return
            }
            if self.setMicDisabledView.subviews.count == 2
                , let ivSetMicDisabled = self.setMicDisabledView.subviews[0] as? UIButton
                , let lbSetMicDisabled = self.setMicDisabledView.subviews[1] as? UIButton {
                ivSetMicDisabled.setImage(UIImage(named: "conference_iv_set_mic_disabled_src"), for: .normal)
                lbSetMicDisabled.setTitle("静音", for: .normal)
            }
            if self.setMicDisabledViewCenter.subviews.count == 1
                , let ivSetMicDisabledCenter = self.setMicDisabledViewCenter.subviews[0] as? UIImageView {
                ivSetMicDisabledCenter.image = UIImage(named: "conference_iv_set_mic_disabled_src")
            }
            if self.raiseHandView.subviews.count == 2
                , let ivRaiseHand = self.raiseHandView.subviews[0] as? UIButton
                , let lbRaiseHand = self.raiseHandView.subviews[1] as? UIButton {
                ivRaiseHand.setImage(UIImage(named: "conference_iv_raise_hand_src"), for: .normal)
                lbRaiseHand.setTitle("举手", for: .normal)
            }
            if self.raiseHandCenterView.subviews.count == 1
                , let ivRaiseHandCenter = self.raiseHandCenterView.subviews[0] as? UIImageView {
                ivRaiseHandCenter.image = UIImage(named: "conference_iv_raise_hand_src")
            }
            self.setMicDisabledView.isHidden = false
            self.setMicDisabledViewCenter.isHidden = false
            self.raiseHandView.isHidden = true
            self.raiseHandCenterView.isHidden = true
        }
    }
    
    func onRejectRaiseHand() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.toast(text: "主持人已拒绝您发言")
            if self.raiseHandView.subviews.count == 2
                , let ivRaiseHand = self.raiseHandView.subviews[0] as? UIButton
                , let lbRaiseHand = self.raiseHandView.subviews[1] as? UIButton {
                ivRaiseHand.setImage(UIImage(named: "conference_iv_raise_hand_src"), for: .normal)
                lbRaiseHand.setTitle("举手", for: .normal)
            }
            if self.raiseHandCenterView.subviews.count == 1
                , let ivRaiseHandCenter = self.raiseHandCenterView.subviews[0] as? UIImageView {
                ivRaiseHandCenter.image = UIImage(named: "conference_iv_raise_hand_src")
            }
        }
    }
    
    func onCancelSelectSee(_ selectSeeUUID: String) {
        (self.viewControllers[self.curPosition] as? ConferenceDefaultViewController)?.hideLockedTip()
    }
}

// MARK: - TZImagePickerControllerDelegate
extension ConferenceViewController: TZImagePickerControllerDelegate {
    func imagePickerController(_ picker: TZImagePickerController!, didFinishPickingPhotos photos: [UIImage]!, sourceAssets assets: [Any]!, isSelectOriginalPhoto: Bool) {
        doPresentImg(photos)
    }
    
    func imagePickerController(_ picker: TZImagePickerController!, didFinishPickingPhotos photos: [UIImage]!, sourceAssets assets: [Any]!, isSelectOriginalPhoto: Bool, infos: [[AnyHashable : Any]]!) {
    }
}

extension ConferenceViewController: UIDocumentPickerDelegate {
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        doPresentICloud(urls)
    }
}
