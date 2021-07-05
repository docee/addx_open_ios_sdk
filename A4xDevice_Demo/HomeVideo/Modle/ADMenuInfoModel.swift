//
//  MenuInfoModel.swift
//  AddxAi
//
//  Created by zhi kuiyu on 2019/2/11.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import UIKit
import A4xBaseSDK

class ADMenuInfoModel: ADDialogModelProtocol {
    var identerType: String{
        return "MenuInfoModel"
    }
    var title : String?
    private var style : Int? = 0
    
    func cellStyle() -> ADVideoCellStyle {
        return ADVideoCellStyle(rawValue: style!) ?? .default
    }
    
    class func getMenuData() -> [ADMenuInfoModel] {
        var datas : [ADMenuInfoModel] = Array()
        
        let dModel : ADMenuInfoModel = ADMenuInfoModel()
//        dModel.title = R.string.localizable.default_common()
        dModel.style = ADVideoCellStyle.default.rawValue
        datas.append(dModel)

        let sModel : ADMenuInfoModel = ADMenuInfoModel()
        sModel.title = R.string.localizable.split_screen()
        sModel.style = ADVideoCellStyle.split.rawValue
        datas.append(sModel)
        return datas;
    }
}
