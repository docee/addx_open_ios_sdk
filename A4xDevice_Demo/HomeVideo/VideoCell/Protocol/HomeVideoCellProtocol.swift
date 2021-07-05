//
//  HomeVideoCellProtocol.swift
//  AddxAi
//
//  Created by zhi kuiyu on 2019/2/13.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import Foundation
import UIKit
import A4xBaseSDK

class HomeVideoBaseCell : UICollectionViewCell {
    var videoStyle : ADVideoCellStyle?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.videoStyle = .default
    }
    
    override var frame: CGRect {
        didSet {
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
