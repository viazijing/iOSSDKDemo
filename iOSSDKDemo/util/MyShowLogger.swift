//
//  MyShowLogger.swift
//  iOSSDKDemo
//
//  Created by Mac on 2025/4/11.
//  日志工具类
//

import Foundation
import common

class MyShowLogger {
    
    static let instance = MyShowLogger()
    
    private init() {}
    
    lazy var showLogger = {
        let showLogger = ShowLogger()
        // Log level.
        showLogger.setLogLevel(logLevel: .verbose)
        // Log file.
        let cachePaths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        if (cachePaths.count > 0) {
            do {
                try FileManager.default.createDirectory(atPath: cachePaths[0] + "/log/", withIntermediateDirectories: true)
                showLogger.setDir(dir: cachePaths[0] + "/log/")
            } catch {
            }
        }
        return showLogger
    }()
}
