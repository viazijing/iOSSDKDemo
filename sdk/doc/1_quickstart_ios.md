# iOS入会>快速开始
## 前提条件

- `iOS 13.0+`真机 (iPhone或iPad)。
- 请确保你的项目设置有效的开发者签名。
```code
注意: 请使用真机运行实例代码,模拟器可能因为功能缺失而无法运行示例代码。
```

## SDK集成说明

- 下载` iOS-SDK `，并解压

- 将 frameworks 中的 `rtc.framework`，`WebRTC.framework` ，`common.framework` ，`net.framework` ，`Zip.framework` 拖拽到工程中的 Frameworks 文件夹，选择 Copy items if needed。
  ![](../static/_images/ios/1.png)

- TARGETS 中选择项目，General 中 Frameworks,Librariees and Embedded Content 中刚才添加的 `rtc.framework`，`WebRTC.framework` ，`common.framework` ，`net.framework` ，`Zip.framework` 的 Embed 都设置为 Embed & Sign
  ![](../static/_images/ios/2.png)

- 在`Info.plist` 中添加麦克风、相机使用权限
```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSCameraUsageDescription</key>
    <string>本应用在进行视频通话时需要您授权使用本机的摄像头功能。</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>本应用在进行音视频通话时需要您授权使用本机的麦克风功能。</string>
    <key>UIApplicationSceneManifest</key>
    ...
</dict>
</plist>
```

  ![](../static/_images/ios/3.png)

## 加入会议

```swift
class ViewController: UIViewController {
        
    /**
     ConferenceManager 设置为全局变量，否则会被回收
     */
    private var conferenceManager: ConferenceManager?
    
    @objc func joinConference() {
        let serverAddr = "https://cloud.51vmr.cn"
        var url: URL?
        if (serverAddr.hasPrefix("http")) {
            url = URL(string: serverAddr)
        } else {
            url = URL(string: "https://\(serverAddr)")
        }
        let builder = ConferenceManager.Builder()
        if let scheme = url?.scheme {
            builder.setScheme(scheme)
        }
        if let host = url?.host {
            builder.setHost(host)
        }
        if let port = url?.port {
            builder.setPort(port)
        }
        conferenceManager = builder.build()
        conferenceManager?.join(conferenceRoomNum: "会议室号码", pwd: "会议室密码", name: "参会者名称")
    }

}
```

## 退出会议

```swift
class ViewController: UIViewController {
    
    /**
     ConferenceManager 设置为全局变量，否则会被回收
     */
    private var conferenceManager: ConferenceManager?
    
    @objc func quitConference() {
        conferenceManager?.quit()
    }

}
```

## 接收回调信息
示例中列出部分回调，全部回调请参考 demo。

```swift
class ViewController: UIViewController {
    
    /**
     ConferenceManager 设置为全局变量，否则会被回收
     */
    private var conferenceManager: ConferenceManager?
    
    @objc func joinConference() {
        ...
        conferenceManager = builder.build()
        conferenceManager?.setOnConferenceListener(self)
        conferenceManager?.join(conferenceRoomNum: "会议室号码", pwd: "会议室密码", name: "参会者名称")
    ...
    }

}

extension ViewController: OnConferenceListener {
    /**
     成功加入会议时回调，但此时还没有建立媒体通讯
     */
    func onConnected() {
    }
    
    /**
     媒体通讯成功建立时回调，该回调后即可正常调用媒体相关功能
     */
    func onCallSuccess() {
    }
    
    /**
     退出会议时回调
     @param e：退会原因，被服务器退出会议或者因网络问题退出会议时返回对应信息，正常退出时 e 为 nil
     */
    func onDisconnected(_ e: ViaZijingError?) {
    }
    
    /**
     会议室状态更新时回调
     @param conferenceStatusBean：当前会议室状态
     */
    func onConferenceStatusUpdate(_ conferenceStatusBean: ConferenceStatusBean) {
    }
    
    /**
     本地预览开启时回调
     @param layoutBean：本地视频画面
     */
    func onStartPreview(layoutBean: LayoutBean) {
    }
    
    /**
     平台推荐布局变化时回调
     @param layoutBeans：当前推荐布局，不包含本地画面
     */
    func onLayout(_ layoutBeans: [LayoutBean]) {
    }
    
    /**
     会中参会人更新时回调
     @param participantBeans：当前会中参会人列表
     */
    func onParticipantsUpdate(_ participantBeans: [ParticipantBean]) {
    }
}

```
