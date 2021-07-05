//
//  ADLiveVideoPresetCell.swift
//  AddxAi
//
//  Created by kzhi on 2019/11/30.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import UIKit
import A4xBaseSDK

enum LiveVideoPresetCellType {
    case none
    case add
    case delete
}

class ADLiveVideoPresetCell : UICollectionViewCell {
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
            self.imageV.backgroundColor = UIColor.white

            switch type {
            case .none:
                self.typeImageV.image = nil
                self.typeImageV.backgroundColor = UIColor.clear
                self.titleV.isHidden = false
                self.titleV.snp.updateConstraints { (make) in
                    make.centerY.equalTo(self.snp.centerY)
                }
                self.typeImageV.isHidden = true
                self.titleV.isHidden = false
            case .add:
                self.imageV.backgroundColor = ADTheme.Theme
                self.typeImageV.image = R.image.home_device_preset_add()?.tinColor(color: UIColor.white)
                self.typeImageV.backgroundColor = UIColor.clear
                self.titleV.isHidden = false
                self.typeImageV.isHidden = false
                self.titleV.snp.updateConstraints { (make) in
                    make.centerY.equalTo(self.snp.centerY).offset(7.auto())
                }
                self.typeImageV.snp.updateConstraints { (make) in
                    make.centerY.equalTo(self.imageV.snp.centerY).offset(-7.auto())
                }
            case .delete:
                self.typeImageV.image = R.image.home_device_preset_remove()
                self.typeImageV.backgroundColor = UIColor.white
                self.titleV.isHidden = true
                self.typeImageV.isHidden = false
                self.typeImageV.snp.updateConstraints { (make) in
                    make.centerY.equalTo(self.imageV.snp.centerY)
                }
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
            make.centerX.equalTo(self.imageV.snp.centerX)
            make.centerY.equalTo(self.imageV.snp.centerY)
            make.size.equalTo(CGSize(width: 37.auto(), height: 37.auto()))
        }
        return temp
    }()
    
    private lazy
    var imageV : UIImageView = {
        let temp = UIImageView()
        temp.contentMode = .scaleAspectFill
        temp.backgroundColor = ADTheme.Theme
        temp.layer.cornerRadius = 11.auto()
        temp.clipsToBounds = true
        self.addSubview(temp)
        temp.snp.makeConstraints { (make) in
            make.width.equalTo(self.snp.width)
            make.top.equalTo(0)
            make.left.equalTo(0)
            make.height.equalTo(self.snp.height)
        }
        
        return temp
    }()
    
    private lazy
    var titleV : UILabel = {
        let temp = UILabel()
        temp.textAlignment = .center
        temp.font = ADTheme.B3
        temp.textColor = UIColor.white
        self.addSubview(temp)
        temp.text = "发送发送"
        temp.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.snp.centerY)
            make.width.lessThanOrEqualTo(self.snp.width)
            make.centerX.equalTo(self.snp.centerX)
        }
        
        return temp
    }()
    
}
