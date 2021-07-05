//
//  ADMessageHelper.swift
//  ADVideoMessageManager
//
//  Created by kzhi on 2020/12/9.
//

import UIKit

extension UIImage {
    static func adNamed(named : String) -> UIImage? {
        let frameworkBundle : Bundle = Bundle(for: ADVideoMessageContentView.self)
        if let url = frameworkBundle.url(forResource: "ADVideoMessageManager", withExtension: "bundle") {
            let bundle = Bundle(url: url)
            return UIImage(named: named, in: bundle, compatibleWith: nil)
        }else {
            NSLog("ADVideoMessage bundle load error")
            return nil
        }
    }
    
}
