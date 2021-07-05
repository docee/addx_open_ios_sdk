//
//  AddDeviceModel.swift
//  AddxAi
//
//  Created by zhi kuiyu on 2019/2/11.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import UIKit
import A4xBaseSDK

enum ADUserVipTypeEnum {
    case none(tip : String)
    case vip(tip : String)
    case protection(tierId : Int , tip : String)
}

enum ADUserSettingEnum {
    case vip
    case manager
    case language
    case location
    case about
    case help
    case scene
    case joinDevice
    case buildInfo
    case feedback
    case faq //helper_centers

    var rawValue : String {
        switch self {
        case .manager:
            return R.string.localizable.device_manager()
        case .about:
            return R.string.localizable.about_evaeye(ADTheme.APPName)
        case .help:
            return R.string.localizable.help_feedback()
        case .scene:
            return R.string.localizable.scene()
        case .language:
            return R.string.localizable.language()
        case .buildInfo:
            return R.string.localizable.app_build_info()
        case .location:
            return R.string.localizable.location_management()
        case .vip:
            return R.string.localizable.payment_cloud_save(ADTheme.APPName)
        case .feedback :
            return R.string.localizable.feedback()
        case .faq:
            return R.string.localizable.help_center()
        case .joinDevice:
            return R.string.localizable.join_friend_device()
        }
    }
    
    static func allCases() -> [[ADUserSettingEnum]] {
        var allcaseData : [ADUserSettingEnum] = [.manager, .joinDevice ,.language , .location ,.feedback, .faq, .about ]
        let buildInfo = A4xAppBuildConfig.buildInfo()
        if buildInfo.isDebug() {
            allcaseData.append(.buildInfo)
        }
        return [[.vip],allcaseData]
    }
}
