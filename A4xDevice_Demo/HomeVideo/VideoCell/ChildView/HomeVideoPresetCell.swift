//
//  HomeVideoPresetCell.swift
//  AddxAi
//
//  Created by kzhi on 2019/11/21.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import Foundation
import UIKit
import A4xBaseSDK

enum HomeVideoPresetCellType {
    case none
    case add
    case delete
}

class HomeVideoPresetCell : UICollectionViewCell {
    var title : String?
    {
        didSet {
            self.titleV.text = title
        }
    }
    
    var imageUrl : String? {
        didSet {
            self.imageV.yy_setImage(with: URL(string: imageUrl ?? ""), options: .showNetworkActivity)
        }
    }
    
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.imageV.isHidden = false
        self.titleV.isHidden = false
        self.typeImageV.isHidden = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    var type : HomeVideoPresetCellType = .none {
        didSet {
            switch type {
            case .none:
                self.typeImageV.image = nil
                self.typeImageV.backgroundColor = UIColor.clear
            case .add:
                self.typeImageV.image = R.image.home_device_preset_add()
                self.typeImageV.backgroundColor = UIColor.clear
            case .delete:
                self.typeImageV.image = R.image.home_device_preset_remove()
                self.typeImageV.backgroundColor = UIColor.white
            }
        }
    }
    var videoRadio : CFloat = 1.8 {
        didSet {
            if oldValue != videoRadio {
                self.imageV.snp.updateConstraints { (make) in
                    make.height.equalTo(self.snp.width).multipliedBy(1 / videoRadio)
                }
            }
        }
    }
    
    lazy
    var typeImageV : UIImageView = {
        let temp = UIImageView()
        temp.layer.cornerRadius = 37.auto() / 2
        temp.clipsToBounds = true
        temp.contentMode = .center
        self.addSubview(temp)

        temp.snp.makeConstraints { (make) in
            make.center.equalTo(self.imageV.snp.center)
            make.size.equalTo(CGSize(width: 37.auto(), height: 37.auto()))
        }
        return temp
    }()
    
    private lazy
    var imageV : UIImageView = {
        let temp = UIImageView()
        temp.contentMode = .scaleAspectFill
        temp.backgroundColor = UIColor.hex(0xF5F6FA)
        temp.layer.cornerRadius = 11.auto()
        temp.clipsToBounds = true
        self.addSubview(temp)
        temp.snp.makeConstraints { (make) in
            make.width.equalTo(self.snp.width)
            make.top.equalTo(0)
            make.centerX.equalTo(self.snp.centerX)
            make.height.equalTo(self.snp.width).multipliedBy(1 / videoRadio)
        }
        
        return temp
    }()
    
    private lazy
    var titleV : UILabel = {
        let temp = UILabel()
        temp.textAlignment = .center
        temp.font = ADTheme.B3
        temp.textColor = ADTheme.C2
        self.addSubview(temp)
        temp.text = "发送发送"
        temp.snp.makeConstraints { (make) in
            make.top.equalTo(self.imageV.snp.bottom).offset(5.auto())
            make.width.lessThanOrEqualTo(self.snp.width)
            make.centerX.equalTo(self.snp.centerX)
        }
        
        return temp
    }()
    
}
