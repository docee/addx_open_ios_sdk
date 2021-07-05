//
// Created by zhi kuiyu on 2019-01-30.
//

import Foundation
import UIKit
import SnapKit
import A4xBaseSDK

// ----------------------------------------------------------------

enum ADHomeHeaderAlignment {
    case left
    case center
}

typealias ADHomeHeaderShowBlock = (Bool) -> Void
typealias ADHomeHeaderDoubleBlock = () -> Void

class ADHomeHeaderInfo : UIControl {
    var headerShowBlock :   ADHomeHeaderShowBlock?
    var doubleCilck     :   ADHomeHeaderDoubleBlock?
    var alignment       : ADHomeHeaderAlignment = .center {
        didSet {
            switch self.alignment {
            case .left:
                self.titleLabel.snp.remakeConstraints({ [weak self](make) in
                    guard let self = self else {
                        return
                    }
                    make.bottom.equalTo(self.snp.bottom)
                    make.left.equalTo(0)
                    make.height.equalTo(44.auto())
                    make.width.lessThanOrEqualTo(self.snp.width).offset(-70.auto())
                })
            case .center:
                self.titleLabel.snp.remakeConstraints({ [weak self] (make) in
                    guard let self = self else {
                        return
                    }
                    make.bottom.equalTo(self.snp.bottom)
                    make.centerX.equalTo(self.snp.centerX).offset(-3.auto())
                    make.height.equalTo(44.auto())
                    make.width.lessThanOrEqualTo(self.snp.width).offset(-70.auto())
                })
            }
        }
    }
    
    enum HeaderMenuType{
        case Show
        case Hidden
    }

    var headerShowType : HeaderMenuType? = .Hidden
    
    var title : String? {
        didSet {
            self.titleLabel.text = title
        }
    }
    
    var titleType : HeaderCenterType = .Arrow {
        didSet {
            if titleType == .Arrow {
                self.isUserInteractionEnabled = true
                self.arrowImage.isHidden = false
            }else {
                self.isUserInteractionEnabled = false
                self.arrowImage.isHidden = true
            }
        }
    }

    func updateType(ani : Bool){
        if ani {
            UIView.animate(withDuration: 0.3) {
                if (self.headerShowType == .Show){
                    self.arrowImage.transform = CGAffineTransform.init(rotationAngle: CGFloat.pi)
                }else {
                    self.arrowImage.transform = CGAffineTransform.identity
                }
            }
        }else {
            if (self.headerShowType == .Show){
                self.arrowImage.transform = CGAffineTransform.init(rotationAngle: CGFloat.pi)
            }else {
                self.arrowImage.transform = CGAffineTransform.identity
            }
        }
    }

    func hiddenMeuns(ani : Bool) {
        self.headerShowType = .Hidden;
        updateType(ani: ani)
    }

    func showMeuns(ani : Bool) {
        self.headerShowType = .Show;
        updateType(ani: ani)
    }
    
    lazy
    var titleLabel : UILabel = {
        let temp = UILabel()
        temp.font = ADTheme.H3
        temp.textColor = ADTheme.C1
        temp.text = "Beijing' Home"
        self.addSubview(temp)

        temp.setContentHuggingPriority(UILayoutPriority.required, for: NSLayoutConstraint.Axis.horizontal)
        temp.snp.makeConstraints({ (make) in
            make.bottom.equalTo(self.snp.bottom)
            make.centerX.equalTo(self.snp.centerX).offset(-3.auto())
            make.height.equalTo(44.auto())
            make.width.lessThanOrEqualTo(self.snp.width).offset(-70.auto())
        })
        return temp
    }()

    private lazy var arrowImage : UIImageView = {
        let temp = UIImageView()
        temp.image = UIImage(named: "homepage_head_arrow")
        self.addSubview(temp)

        temp.snp.makeConstraints({ (make) in
            make.left.equalTo(self.titleLabel.snp.right).offset(-3)
            make.centerY.equalTo(self.titleLabel.snp.centerY).offset(1)
        })

        return temp

    }()

    @objc
    private func clickAction(id : UIView){
        self.headerShowType = self.headerShowType == .Show ? .Hidden : .Show;
        updateType(ani: true)
        if (self.headerShowBlock != nil){
            self.headerShowBlock!(self.headerShowType == .Show)
        }
    }

    convenience init(){
        self.init(frame: CGRect.zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.titleLabel.isHidden = false
        self.arrowImage.isHidden = false
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else {
            return
        }
        guard doubleCilck != nil else {
            self.oneClickAction()
            return
        }
        
        let delaytime: TimeInterval = 0.15
        if touch.tapCount > 1 {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(doubleClickAction), object: nil)
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(oneClickAction), object: nil)
//            A4xLog("ADHomeHeaderInfo perform doubleClickAction")
            self.perform(#selector(doubleClickAction), with: nil, afterDelay: delaytime)
        } else {
//            A4xLog("ADHomeHeaderInfo perform oneClickAction")
            self.perform(#selector(oneClickAction), with: nil, afterDelay: delaytime)
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var lastTime : TimeInterval = 0
    
    @objc
    private func doubleClickAction() {
        A4xLog("ADHomeHeaderInfo doubleClick ")
        let curda = Date().timeIntervalSince1970
        let last = lastTime
        lastTime = curda
        A4xLog(String(format: "ADHomeHeaderInfo oneClick %.2f", (curda - last)))

        if curda - last < 0.5 {
            A4xLog("ADHomeHeaderInfo doubleClick too shot")
            return
        }
        self.doubleCilck?()
    }
    
    @objc
    private func oneClickAction() {
        let curda = Date().timeIntervalSince1970
        let last = lastTime
        lastTime = curda
        
        A4xLog(String(format: "ADHomeHeaderInfo oneClick %.2f", (curda - last)))

        if (curda - last) < 0.5 {
            A4xLog("ADHomeHeaderInfo oneClick too shot")
            return
        }
        self.headerShowType = self.headerShowType == .Show ? .Hidden : .Show;
        updateType(ani: true)
        if (self.headerShowBlock != nil){
            self.headerShowBlock!(self.headerShowType == .Show)
        }
    }
      
}
