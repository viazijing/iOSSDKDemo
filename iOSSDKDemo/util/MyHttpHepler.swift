//
//  MyHttpHepler.swift
//  fastsdk
//
//  Created by Mac on 2024/7/3.
//

import Foundation
import net

class MyHttpHepler {
    static let instance = MyHttpHepler()
    
    private init() {}
    
    lazy var httpHelper = {
        let httpHelper = HttpHelper()
//        httpHelper.addInterceptor(interceptor: TokenInterceptor())
//        httpHelper.addInterceptor(interceptor: MyLogInterceptor(logger: { log in
//            MyShowLogger.instance.showLogger.verbose(tag: "网络请求", "\(log)")
//        }))
        return httpHelper
    }()
}
