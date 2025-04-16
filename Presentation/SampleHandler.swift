//
//  SampleHandler.swift
//  Presentation
//
//  Created by Mac on 2025/4/15.
//

import ReplayKit
import rtc

class SampleHandler: RTCSampleHandler {
    
    public override init() {
        super.init()
        groupUserDefaultsHelper = GroupUserDefaultsHelper(groupId: "group.com.viazijing.iossdkdemo")
    }
    
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
        // 录屏开始
        super.broadcastStarted(withSetupInfo: setupInfo)
    }
    
    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
        // 录屏暂停
        super.broadcastPaused()
    }
    
    override func broadcastResumed() {
        // User has requested to resume the broadcast. Samples delivery will resume.
        // 录屏继续
        super.broadcastResumed()
    }
    
    override func broadcastFinished() {
        // User has requested to finish the broadcast.
        // 录屏停止
        super.broadcastFinished()
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        super.processSampleBuffer(sampleBuffer, with: sampleBufferType)
    }
}
