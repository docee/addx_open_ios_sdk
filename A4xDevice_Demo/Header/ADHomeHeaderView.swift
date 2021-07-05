//
// Created by zhi kuiyu on 2019-01-30.
//

import Foundation
import UIKit
import A4xBaseSDK

enum HeaderPostion {
    case Left
    case Center
    case Right
}

enum HeaderCenterType {
    case Arrow
    case Normail
}

typealias ADHomeHeaderBlock = (_ type : HeaderPostion , _ show  : Bool) -> Void

class ADHomeHeaderView: UIView {
    var headInfoClickBlock: ADHomeHeaderBlock? {
        didSet {
            weak var weakSelf = self
            self.infoView.headerShowBlock = {(result ) in
                if weakSelf?.headInfoClickBlock != nil {
                    weakSelf?.headInfoClickBlock?(HeaderPostion.Center,result)
                }
            }
        }
    }
    var headInfoDoubleClickBlock : (()->Void)? {
        didSet {
            weak var weakSelf = self
            self.infoView.doubleCilck = {
                weakSelf?.headInfoDoubleClickBlock?()
            }
        }
    }

    var leftImage: UIImage? {
        didSet {
            if leftImage == nil {
                self.leftView.isHidden = true
            }else {
                self.leftView.setImage(leftImage, for: UIControl.State.normal)
                self.leftView.isHidden = false
            }
        }
    }
    
    var rightImage: UIImage? {
        didSet {
            if rightImage == nil {
                self.rightView.isHidden = true
            }else {
                self.rightView.setImage(rightImage, for: UIControl.State.normal)
                self.rightView.isHidden = false
            }
        }
    }

    var title: String? {
        didSet {
            self.infoView.title = title
        }
    }
    
    var titleType: HeaderCenterType = .Arrow {
        didSet {
            self.infoView.titleType = self.titleType
        }
    }
    
    var titleInfoShow: Bool? {
        didSet {
            if let s = titleInfoShow {
                self.infoView.headerShowType = s ? .Show : .Hidden
                self.infoView.updateType(ani : false);
            }
        }
    }
    
    @objc func headerInfoClickActin(sender: UIButton) {
        if self.headInfoClickBlock != nil {
            self.headInfoClickBlock!(HeaderPostion.Center, true)
        }
    }
    
    @objc func headerAddClickActin(sender: UIButton){
        self.titleInfoShow = false
        if self.headInfoClickBlock != nil {
            self.headInfoClickBlock!(HeaderPostion.Right, true)
        }
    }
    
    @objc func headerMenuClickActin(sender: UIButton) {
        self.titleInfoShow = false
        if self.headInfoClickBlock != nil {
            self.headInfoClickBlock!(HeaderPostion.Left,true)
        }
    }
    
    private lazy var leftView: UIButton = {
        var temp: UIButton = UIButton()
        self.addSubview(temp)
        temp.setImage(UIImage(named: "homepage_head_menus"), for: UIControl.State.normal)
        temp.addTarget(self, action: #selector(headerMenuClickActin(sender:)), for: UIControl.Event.touchUpInside)
        temp.imageView?.contentMode = .scaleAspectFit
        temp.snp.makeConstraints({ (make) in
            make.bottom.equalTo(self.snp.bottom)
            make.height.equalTo(44.auto())
            make.width.equalTo(44.auto())
            make.left.equalTo(0)
        })
        return temp
    }()

     lazy var rightView: UIButton = {
        var temp: UIButton = UIButton()
        self.addSubview(temp)
        temp.setImage(UIImage(named: "homepage_head_add"), for: UIControl.State.normal)
        temp.imageView?.contentMode = .scaleAspectFit
        temp.addTarget(self, action: #selector(headerAddClickActin(sender:)), for: UIControl.Event.touchUpInside)
        temp.snp.makeConstraints({ (make) in
            make.bottom.equalTo(self.snp.bottom)
            make.height.equalTo(44.auto())
            make.width.equalTo(44.auto())
            make.right.equalTo(self.snp.right)
        })
        return temp
    }()

    lazy var infoView: ADHomeHeaderInfo = {
        var temp : ADHomeHeaderInfo = ADHomeHeaderInfo()
        self.addSubview(temp)
        
        temp.snp.makeConstraints({ (make) in
            make.bottom.equalTo(self.snp.bottom)
            make.height.equalTo(44.auto())
            make.width.lessThanOrEqualTo(self.snp.width).offset(88)
            make.centerX.equalTo(self.snp.centerX)
        })
        return temp
    }()

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        self.infoView.isHidden = false
        
       
    }
  
    deinit {
        A4xLog(self)
    }
 
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
