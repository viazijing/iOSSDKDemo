# iOS入会>概述
## 主要功能
| 功能                | 描述  |
| ------------------- | ---- |
| 发起呼叫             | 呼入一个会议 |
| 接收合成视频画面      | 接收平台发送的合成视频画面 |
| 接收多路视频画面      | 接收平台发送的多路视频画面 |
| 开启/关闭摄像头      | 打开或者关闭本地的摄像头 |
| 开启/关闭麦克风      | 打开或者关闭本地的麦克风 |
| 切换摄像头      | 切换本地前后摄像头 |
| 挂断             | 离开会议 |
| 发起内容共享      | 本端发起内容共享，进行桌面共享、文件共享 |
| 接收内容共享      | 接受他人的内容共享画面 |
| 通话数据统计      | 获取会议中实时的媒体通讯参数数据 |

## 兼容性说明
| 平台                | 兼容性  |
| ------------------- | ---- |
| iOS            |     iOS 13.0|

# iOS入会>快速开始
## 前提条件

- `iOS 13.0+`真机 (iPhone或iPad)。
- 请确保你的项目设置有效的开发者签名。
```code
注意: 请使用真机运行实例代码,模拟器可能因为功能缺失而无法运行示例代码。
```

## SDK集成说明

- 下载` iOS-SDK `，并解压

- 将 frameworks 中的 `rtc.framework`，`WebRTC.framework` ，`common.framework` ，`net.framework` 拖拽到工程中的 Frameworks 文件夹，选择 Copy items if needed。
  ![](../static/_images/ios/1.png)

- TARGETS 中选择项目，General 中 Frameworks,Librariees and Embedded Content 中刚才添加的 `rtc.framework`，`WebRTC.framework` ，`common.framework` ，`net.framework` 的 Embed 都设置为 Embed & Sign
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

# iOS入会>SDK开发指南

## ConferenceManager.Builder
|                             方法                             |          功能          |
| :----------------------------------------------------------: | :--------------------: |
|             <a href="">setScheme</a>             |         设置入会地址的 scheme         |
|              <a href="">setHost</a>              | 设置入会地址的 host |
|         <a href="">setPort</a>         |        设置入会地址的 port        |
|        <a href="">setAccount</a>         |      设置入会时 account，登录后入会可设置      |
|    <a href="">setOneTimeToken</a>     |      被邀请入会时设置      |
|      <a href="">setGroupId</a>      |        需要共享屏幕功能时设置        |
| <a href="">setLogLevel</a> | 设置 WebRTC 日志级别 |
|      <a href="">setDevId</a>      |  设置开发者 id  |
|      <a href="">setDevToken</a>      |  设置开发者 token  |
|      <a href=""> build </a>      |  创建 ConferenceManager  |

## ConferenceManager

### 设置监听器
public func setOnConferenceListener(_ onConferenceListener: OnConferenceListener)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">onConferenceListener</a> | 会中事件监听器     |

### 加入会议
public func join(conferenceRoomNum: String, pwd: String, name: String)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">conferenceRoomNum</a> | 会议室号码     |
| <a href="">pwd</a> | 入会密码     |
| <a href="">name</a> | 参会人名称 |

### 主持会议
public func host(conferenceRoomNum: String, pwd: String, name: String)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">conferenceRoomNum</a> | 会议室号码     |
| <a href="">pwd</a> | 主持密码     |
| <a href="">name</a> | 参会人名称 |

### 仅投屏入会
public func onlyPresentation(conferenceRoomNum: String, pwd: String, name: String)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">conferenceRoomNum</a> | 会议室号码     |
| <a href="">pwd</a> | 入会密码     |
| <a href="">name</a> | 参会人名称 |

### 退出会议
public func quit()

### 获取视频相关功能管理者实例
public func getRTCManager() -> RTCManager?

### 获取二路流相关功能管理者实例
public func getPresentationManager() -> PresentationManager?

### 获取主持会议相关功能管理者实例
public func getHostManager() -> HostManager?

### 获取会中唯一标识
public func getParticipantUUID() -> String

### 获取参会人
public func getParticipantBean(uuid: String) -> ParticipantBean?

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">uuid</a> | 参会人唯一标识 |

### 获取参会人列表
public func getParticipantBeans() -> [ParticipantBean]

### 获取自己视频画面
public func getMyLayoutBean() -> LayoutBean?

### 获取当前平台推荐布局
public func getCurrentLayout() -> [LayoutBean]

### 获取当前会议室状态
public func getConferenceStatus() -> ConferenceStatusBean?

### 获取会中统计，每 1s 回调一次
public func getStatistics(callback: (([RTCStatisticsBean]) -> Void)?)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">callback</a> | 接收会中统计的回调 |

### 停止获取会中统计
public func stopGetStatistics()

### 获取当前正在选看的参会人的唯一标识
public func getSelectSeeUUID() -> String?

### 选看指定参会人
public func selectSee(uuid: String, onSuccess: (() -> Void)? = nil, onFailure: ((ViaZijingError) -> Void)? = nil)
选看成功后，layout 返回的布局中，选看的参会人一直是第一个大画面。

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">uuid</a> | 参会人唯一标识 |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 取消选看指定参会人
public func unselectSee(uuid: String, onSuccess: (() -> Void)? = nil, onFailure: ((ViaZijingError) -> Void)? = nil)
取消选看后 layout 恢复平台推荐布局。

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">uuid</a> | 参会人唯一标识 |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 发送文本消息
public func sendMsg(text: String, uuids: [String] = [], onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">text</a> | 文本消息内容 |
| <a href="">uuids</a> | 接收消息的参会人的唯一标识集合，若为空集，则是发送给所有人。 |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 举手
public func raiseHand(onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)
被服务器静音后，如果想取消静音状态，需要举手，待会控同意后才能取消静音。

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 放下手
public func lowerHand(onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)
客户端主动取消举手状态。

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 邀请其他人入会
public func outgoingCall(cuids: [String], onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)
该功能为登录后使用，获取通讯录后才能获取其他成员的 cuid。

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">cuids</a> | 被邀请人的 cuid 集合，注意是 cuid，非会中的 uuid。 |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 上传日志
public static func uploadLog(url: String, onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">url</a> | 上传地址 |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

## RTCManager
媒体相关

### 开始预览
public func startPreview()
该方法用于入会前本地预览

### 停止预览
public func getVideoTrack(trackId: String) -> RTCVideoTrack?

### 获取指定视轨
public func getVideoTrack(trackId: String) -> RTCVideoTrack?
在 onLayout 回调中，会返回 LayoutBean 集合，可以根据 LayoutBean 的 trackId 调用该方法获取对应视轨，用于展示视频流。

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">trackId</a> | 视轨唯一标识 |

### 获取麦克风是否开启
public func isMicEnabled() -> Bool

### 设置麦克风是否开启
public func setMicEnabled(enabled: Bool) -> Bool
返回 true 表示设置成功，返回 false 表示设置失败。

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">enabled</a> | true 为开启，false 为关闭。 |

### 获取摄像头是否开启
public func isCameraEnabled() -> Bool

### 设置摄像头是否开启
public func setCameraEnabled(enabled: Bool) -> Bool
返回 true 表示设置成功，返回 false 表示设置失败。

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">enabled</a> | true 为开启，false 为关闭。 |

### 获取当前是否为前置摄像头
public func isFrontFacing() -> Bool
返回 true 表示为前置摄像头，返回 false 表示为后置摄像头。

### 切换前后摄像头
public func switchCamera()

### 开始发送图片
public func startImageCapture(_ image: UIImage)
关闭摄像头后，如果其他参会人看到指定图片，调用该接口。

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">image</a> | 作为视频流的图片 |

### 请求推荐布局
public func layout(_ layout: String, onSuccess: (() -> Void)? = nil, onFailure: ((ViaZijingError) -> Void)? = nil)
请求推荐布局后，后续平台如果有布局变化会继续推送。

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">layout</a> | "m:n"，其中 m 为大画面数量，n 为小画面数量，如 "1:5"。 |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 请求指定布局
public func overrideLayout(_ layout: String, uuids: [String], onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)
请求指定布局后，后续平台如果有布局变化不会继续推送，一直保持指定布局。

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">layout</a> | "m:n"，其中 m 为大画面数量，n 为小画面数量，如 "1:5"。 |
| <a href="">uuids</a> | 指定参会人的 uuid 集合，长度等于 m+n。 |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

## PresentationManager
共享流相关

### 共享屏幕
public func startScreenCapture(preferredExtension: String, onSuccess: @escaping (() -> Void), onFailure: @escaping ((ViaZijingError) -> Void))
该方法会向系统发送录屏请求，最终由用户确认是否开始录屏。

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">preferredExtension</a> | 推荐的录屏进程的 Bundle Id |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调，需要注意在向系统发起录屏请求后，用户取消的这个状态是无法检测到的。 |

### 共享白板
public func startWhiteboardCapture(uiImage: UIImage, allowOtherMark: Bool = true, onSuccess: @escaping (() -> Void), onFailure: @escaping ((ViaZijingError) -> Void))

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">uiImage</a> | 白板底图 |
| <a href="">allowOtherMark</a> | true 为允许其他人批注，false 为不允许。 |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 共享图片
public func startImageCapture(uiImage: UIImage, allowOtherMark: Bool = true, onSuccess: @escaping (() -> Void), onFailure: @escaping ((ViaZijingError) -> Void))

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">uiImage</a> | 图片底图 |
| <a href="">allowOtherMark</a> | true 为允许其他人批注，false 为不允许。 |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 停止共享
public func stop()

### 更新共享图片时的底图
public func newWhiteboardBackground(_ uiImage: UIImage)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">uiImage</a> | 图片底图 |

### 更新共享图片时的视频流
public func updateImgeCapture(_ uiImage: UIImage)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">uiImage</a> | 图片底图 |

### 添加笔画
public func addLine(width: Int, height: Int, lineWidth: Int, lineColor: UIColor, path: UIBezierPath, onSuccess: ((Int) -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">width</a> | 底图宽度 |
| <a href="">height</a> | 底图高度 |
| <a href="">lineWidth</a> | 笔画宽度 |
| <a href="">lineColor</a> | 笔画颜色 |
| <a href=""> path </a> | 笔画路径 |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 删除笔画
public func removeLine(id: Int, onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">id</a> | 笔画 id |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 清空笔画
public func clearLine(onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 设置是否允许其他人批注
public func setAllowOtherMark(allowOtherMark: Bool, onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">allowOtherMark</a> | true 为允许其他人批注，false 为不允许。 |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

## HostManager
会控相关

### 申请成为主持人
public func applyHost(pwd: String, onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">pwd</a> | 主持密码 |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 全体静音
public func muteAll(onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 取消全体静音
public func unmuteAll(onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 允许所有等候室中的参会人入会
public func allowAllWaiting(onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 拒绝所有等候室中的参会人入会
public func rejectAllWaiting(onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 拒绝所有举手的参会人的举手状态
public func rejectAllRaisingHand(onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 锁定会议
public func lock(onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)
锁定会议后，新入会的参会人不会直接进入会议，而是进入等候室，需主持人允许后方可进入。

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 取消锁定会议
public func unlock(onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 开始直播
public func startLive(onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 停止直播
public func stopLive(onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 开始录制
public func startRecord(onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)
录制为云端录制，非本地录制。

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 停止录制
public func stopRecord(onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 结束会议
public func finishConference(onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 静音指定参会人
public func mute(uuid: String, onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">uuid</a> | 参会人唯一标识 |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 取消静音指定参会人
public func unmute(uuid: String, onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">uuid</a> | 参会人唯一标识 |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 取消指定参会人举手状态
public func clearRaiseHand(uuid: String, onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">uuid</a> | 参会人唯一标识 |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 设置参会人名称
public func setName(uuid: String, name: String, onSuccess: (() -> Void)? = nil, onFailure: ((ViaZijingError) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">uuid</a> | 参会人唯一标识 |
| <a href="">name</a> | 参会人名称 |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 设置参会人为观众
public func setGuest(uuid: String, onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">uuid</a> | 参会人唯一标识 |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 设置参会人为主持人
public func setHost(uuid: String, onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">uuid</a> | 参会人唯一标识 |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 设置参会人为主会场
public func setMainMeetingPlace(uuid: String, onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">uuid</a> | 参会人唯一标识 |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 取消设置参会人为主会场
public func setCancelMainMeetingPlace(uuid: String, onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">uuid</a> | 参会人唯一标识 |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 设置参会人为嘉宾
public func setDistinguishedGuest(uuid: String, onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">uuid</a> | 参会人唯一标识 |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 取消设置参会人为嘉宾
public func setCancelDistinguishedGuest(uuid: String, onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">uuid</a> | 参会人唯一标识 |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 设置参会人为焦点
public func focus(uuid: String, onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">uuid</a> | 参会人唯一标识 |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 取消设置参会人为焦点
public func unfocus(uuid: String, onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">uuid</a> | 参会人唯一标识 |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 允许等候室中的指定参会人入会
public func allowWaiting(uuid: String, onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">uuid</a> | 参会人唯一标识 |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 移出指定参会人
public func remove(uuid: String, onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">uuid</a> | 参会人唯一标识 |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 设置聊天权限
public func setChatPermission(_ chatPermission: ChatPermission, onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">chatPermission</a> | 聊天权限 |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 设置直播聊天权限
public func setLivingChatPermission(_ livingChatPermission: LivingChatPermission, onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">livingChatPermission</a> | 直播聊天权限 |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |

### 设置是否允许未登录用户入会
public func setAllowGuestCall(_ allow: Bool, onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil)

|                          参数                          |         描述         |
| :----------------------------------------------------: | :------------------: |
| <a href="">allow</a> | true 为允许所有用户入会，false 为仅登录用户入会 |
| <a href="">onSuccess</a> | 成功回调 |
| <a href="">onFailure</a> | 失败回调 |
