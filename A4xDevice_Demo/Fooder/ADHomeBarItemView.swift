//
// Created by zhi kuiyu on 2019-01-30.
//

import UIKit
import A4xBaseSDK


typealias ItemSelect = (ADHomeBottomBarType) -> Void

class ADHomeBarItemView : UIControl {


    var barType : ADHomeBottomBarType?
    
    var selectBlock : ItemSelect?

    var selectImage : UIImage?

    var nameTitle : String? {
        didSet {
            self.titleLable.text = nameTitle
        }
    }
    
    var normailImage : UIImage? {
        didSet {
            self.iconImageView.image = normailImage
        }
    }
    
    var titleColor : UIColor?{
        didSet {
            self.titleLable.textColor = titleColor
        }
    }
 
    var hasNew : Bool = false {
        didSet {
            self.updatePoint.isHidden = !hasNew
        }
    }
    
    var selectTitleColor : UIColor?
    
    private lazy var iconImageView : UIImageView = {
        let tem: UIImageView = UIImageView()
        tem.contentMode = .scaleAspectFit
        tem.image = UIImage(named: "homepage_video")
        self.addSubview(tem)
        tem.snp.makeConstraints { make in
            make.centerX.equalTo(self.snp.centerX)
            make.top.equalTo(8)

        }
        return tem;
    }()

    private lazy var titleLable : UILabel = {
        let tem: UILabel = UILabel()
        tem.text = "video"
        tem.font = ADTheme.B2
        tem.textColor = UIColor.black
        self.addSubview(tem)

        tem.snp.makeConstraints { make in
            make.top.equalTo(self.iconImageView.snp.bottom).offset(3)
            make.centerX.equalTo(self.snp.centerX)
        }
        return tem;
    }()

    lazy var updatePoint : UIView = {
        let temp = UIView()
        temp.layer.cornerRadius = 4.auto()
        temp.isUserInteractionEnabled = false
        temp.clipsToBounds = true
        temp.backgroundColor = ADTheme.E1
        self.addSubview(temp)
        
        temp.snp.makeConstraints({ (make) in
            make.left.equalTo(self.iconImageView.snp.right).offset(-2.auto())
            make.width.equalTo(8.auto())
            make.height.equalTo(8.auto())
            make.top.equalTo(self.iconImageView.snp.top)
        })
        
        return temp
    }()
    
    override var isSelected: Bool {
        didSet {
            updateViewStyle(isSelect: isSelected)
        }
    }

    override var isHighlighted: Bool {
        didSet {
            if (isHighlighted && isHighlighted != oldValue){
                self.isSelected = true
                if self.selectBlock != nil {
                    self.selectBlock!(self.barType!)
                }
            }
        }
    }

    private func updateViewStyle (isSelect : Bool){
        if isSelect {
            self.iconImageView.image = self.selectImage
            self.titleLable.textColor = self.selectTitleColor
        }else {
            self.iconImageView.image = self.normailImage
            self.titleLable.textColor = self.titleColor
        }
    }

    convenience init(){
        self.init(frame: CGRect.zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.titleLable.isHidden = false
        self.iconImageView.isHidden = false
        self.updatePoint.isHidden = true
        self.clipsToBounds = true
        self.backgroundColor = UIColor.clear
        updateViewStyle(isSelect: false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
