//
//  ViewController.swift
//  iOSSDKDemo
//
//  Created by Mac on 2025/4/11.
//

import UIKit

import SnapKit
import common
import permission

class ViewController: UIViewController {
    
    // UI Elements
    private lazy var lbServerAddr: UILabel = {
        let label = UILabel()
        label.text = "服务器地址"
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    
    private lazy var tfServerAddr: UITextField = {
        let textField = UITextField()
        textField.placeholder = "请输入服务器地址"
//        textField.text = "https://"
        textField.text = "https://line2.51vmr.cn"
        textField.borderStyle = .roundedRect
        return textField
    }()
    
    private lazy var lbConferenceRoomNum: UILabel = {
        let label = UILabel()
        label.text = "会议室号码"
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    
    private lazy var tfConferenceRoomNum: UITextField = {
        let textField = UITextField()
        textField.placeholder = "请输入会议室号码"
        textField.text = "8007788"
        textField.borderStyle = .roundedRect
        return textField
    }()
    
    private lazy var lbPwd: UILabel = {
        let label = UILabel()
        label.text = "密码"
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    
    private lazy var tfPwd: UITextField = {
        let textField = UITextField()
        textField.placeholder = "请输入会议室密码"
        textField.text = ""
        textField.borderStyle = .roundedRect
        textField.isSecureTextEntry = true  // 使输入框内容隐藏
        return textField
    }()
    
    private lazy var lbName: UILabel = {
        let label = UILabel()
        label.text = "参会者名字"
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    
    private lazy var tfName: UITextField = {
        let textField = UITextField()
        textField.placeholder = "请输入参会者名字"
        textField.text = "iOS Demo"
        textField.borderStyle = .roundedRect
        return textField
    }()
    
    private lazy var joinButton: UIButton = {
        let button = UIButton()
        button.setTitle("加入会议", for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 5
        button.addTarget(self, action: #selector(joinConference), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view background color
        view.backgroundColor = .white
        
        // Configure and add the UI elements
        initView()
        setListener()
        initData()
    }
    
    private func initView() {
        view.addSubview(lbServerAddr)
        lbServerAddr.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.left.equalTo(view).offset(16)
        }
        view.addSubview(tfServerAddr)
        
        tfServerAddr.snp.makeConstraints { make in
            make.top.equalTo(lbServerAddr.snp.bottom).offset(8)
            make.left.right.equalTo(view).inset(16)
            make.height.equalTo(44)
        }
        
        view.addSubview(lbConferenceRoomNum)
        lbConferenceRoomNum.snp.makeConstraints { make in
            make.top.equalTo(tfServerAddr.snp.bottom).offset(20)
            make.left.equalTo(view).offset(16)
        }
        
        view.addSubview(tfConferenceRoomNum)
        tfConferenceRoomNum.snp.makeConstraints { make in
            make.top.equalTo(lbConferenceRoomNum.snp.bottom).offset(8)
            make.left.right.equalTo(view).inset(16)
            make.height.equalTo(44)
        }
        
        view.addSubview(lbPwd)
        lbPwd.snp.makeConstraints { make in
            make.top.equalTo(tfConferenceRoomNum.snp.bottom).offset(20)
            make.left.equalTo(view).offset(16)
        }
        view.addSubview(tfPwd)
        tfPwd.snp.makeConstraints { make in
            make.top.equalTo(lbPwd.snp.bottom).offset(8)
            make.left.right.equalTo(view).inset(16)
            make.height.equalTo(44)
        }
        
        view.addSubview(lbName)
        lbName.snp.makeConstraints { make in
            make.top.equalTo(tfPwd.snp.bottom).offset(20)
            make.left.equalTo(view).offset(16)
        }
        
        view.addSubview(tfName)
        tfName.snp.makeConstraints { make in
            make.top.equalTo(lbName.snp.bottom).offset(8)
            make.left.right.equalTo(view).inset(16)
            make.height.equalTo(44)
        }
        
        view.addSubview(joinButton)
        joinButton.snp.makeConstraints { make in
            make.top.equalTo(tfName.snp.bottom).offset(30)
            make.left.right.equalTo(view).inset(16)
            make.height.equalTo(50)
        }
    }
    
    private func setListener() {
    }
    
    private func initData() {
        PermissionUtil.request(permissionTypes: .AUDIO_RECORD, .CAMERA, success: {
//            DispatchQueue.main.async { [weak self] in
//                guard let self = self else { return }
//                self.ivSetMicDisabled.setImage(UIImage(named: "join_conference_iv_set_mic_disabled_src"), for: .normal)
//                self.ivMicDisabled.isHidden = true
//                self.ivSetCameraDisabled.setImage(UIImage(named: "join_conference_iv_set_camera_disabled_src"), for: .normal)
//                self.ivCameraDisabled.isHidden = true
//                self.conferenceManager.getRTCManager()?.startPreview()
//            }
        }, failure: { permisstionTypes in
//            var cameraPermissionIsAuthorized = true
//            for permissionType in permisstionTypes {
//                if (permissionType == PermissionType.AUDIO_RECORD) {
//                    DispatchQueue.main.async { [weak self] in
//                        guard let self = self else { return }
//                        self.ivSetMicDisabled.setImage(UIImage(named: "join_conference_iv_set_mic_disabled_src_selected"), for: .normal)
//                        self.ivMicDisabled.isHidden = false
//                    }
//                }
//                if (permissionType == PermissionType.CAMERA) {
//                    cameraPermissionIsAuthorized = false
//                    DispatchQueue.main.async { [weak self] in
//                        guard let self = self else { return }
//                        self.ivSetMicDisabled.setImage(UIImage(named: "join_conference_iv_set_camera_disabled_src_selected"), for: .normal)
//                        self.ivCameraDisabled.isHidden = false
//                    }
//                }
//            }
//            // 麦克风权限不允许，但是摄像头权限允许，还是可以预览的
//            if (cameraPermissionIsAuthorized) {
////                DispatchQueue.main.async { [weak self] in
////                    guard let self = self else { return }
//                    self.conferenceManager.getRTCManager()?.startPreview()
////                }
//            }
        })
    }
    
    // Action for Join Button
    @objc private func joinConference() {
        // Handle the logic for joining the conference
        print("Joining Conference")
        guard let serverAddr = tfServerAddr.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            Toast.makeText(parent: view, text: "请输入服务器地址").show()
            return
        }
        guard let conferenceRoomNum = tfConferenceRoomNum.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            Toast.makeText(parent: view, text: "请输入会议室号码").show()
            return
        }
        let pwd = tfPwd.text
        guard let name = tfName.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            Toast.makeText(parent: view, text: "请输入参会者名字").show()
            return
        }
        let micEnable = PermissionType.AUDIO_RECORD.permissionChecker.isAuthorized()
        let cameraEnable = PermissionType.CAMERA.permissionChecker.isAuthorized()
        navigationController?.pushViewController(ConferenceViewController(serverAddr: serverAddr
                                                                          , conferenceRoomNum: conferenceRoomNum
                                                                          , pwd: pwd
                                                                          , name: name
                                                                          , micEnable: micEnable
                                                                          , cameraEnable: cameraEnable), animated: true)
    }
}



