//
//  ADUserAgreementAlert.swift
//  AddxAi
//
//  Created by kzhi on 2020/2/7.
//  Copyright © 2020 addx.ai. All rights reserved.
//

import Foundation
import yoga
import A4xYogaKit
import A4xBaseSDK

class ADOpenDisturbingAlert : UIView  , A4xBaseAlertViewProtocol {
    var config: A4xBaseAlertConfig
    var onHiddenBlock: ((@escaping () -> Void) -> Void)?
    var identifier: String
    var awidth : CGFloat = 0
    var onRightButtonAction : ((Bool)-> Void)?
    
    public override init(frame: CGRect = CGRect.zero ) {
        self.config = A4xBaseAlertConfig()
        self.config.type = .alert(A4xBaseAlertAnimailType.scale)
        self.identifier = "A4xBindLocationSelectView"
        awidth = (UIApplication.shared.keyWindow?.width ?? 375) * 0.8
        super.init(frame: frame)

        self.layer.cornerRadius = 5
        self.layer.backgroundColor = UIColor.white.cgColor
        self.yoga.isEnabled = true
        self.yoga.width = YGValue(awidth)
        self.yoga.alignItems = .center
        
        self.descLabel .isHidden = false
        self.checkBoxV.isHidden = false
        self.notipLabel.isHidden = false
        self.leftButton.isHidden = false
        self.rightButton.isHidden = false
        
        self.yoga.applyLayout(preservingOrigin: true, dimensionFlexibility: YGDimensionFlexibility.flexibleHeight)
        self.leftButton.addBorder(toSide: UIView.ViewSide.Top, withColor: ADTheme.C5, andThickness: 0.5)
        self.leftButton.addBorder(toSide: UIView.ViewSide.Right, withColor: ADTheme.C5, andThickness: 0.5)
        self.rightButton.addBorder(toSide: UIView.ViewSide.Top, withColor: ADTheme.C5, andThickness: 0.5)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        A4xLog("ADUserAgreementAlert \(type(of: self))")
    }
    
    
    lazy var buttonGroup : UIView = {
        let temp  = UIView()
        self.addSubview(temp)
        
        temp.yoga.isEnabled = true
        temp.yoga.flexDirection = .row
        temp.yoga.marginTop = YGValue(13)
        temp.yoga.width = YGValue(value: 100, unit: YGUnit.percent)
        return temp
    }()
    
    lazy var leftButton : UIButton = {
        let temp = UIButton()
        temp.titleLabel?.font = ADTheme.B1
        temp.setTitle(R.string.localizable.cancel(), for: UIControl.State.normal)
        temp.setTitleColor(ADTheme.C1, for: UIControl.State.normal)
        temp.addTarget(self, action: #selector(leftButtonAction), for: .touchUpInside)
        buttonGroup.addSubview(temp)
        
        temp.yoga.isEnabled = true
        temp.yoga.width = YGValue(value: 50, unit: YGUnit.percent)
        temp.yoga.height = YGValue(50)
        return temp
    }()
      
    lazy var rightButton : UIButton = {
        let temp = UIButton()
        
        temp.titleLabel?.font = ADTheme.B1
        temp.setTitle(R.string.localizable.confirm_open(), for: UIControl.State.normal)
        temp.setTitleColor(ADTheme.Theme, for: UIControl.State.normal)
        temp.addTarget(self, action: #selector(rightActionButton), for: .touchUpInside)
        buttonGroup.addSubview(temp)
        
        temp.yoga.isEnabled = true
        temp.yoga.width = YGValue(value: 50, unit: YGUnit.percent)
        temp.yoga.height = YGValue(50)

        return temp
    }()
    
    private
    lazy var descLabel : UILabel = {
        let temp = UILabel()
        temp.font = ADTheme.B1
        temp.textColor = ADTheme.C1
        temp.numberOfLines = 0
        temp.lineBreakMode = .byWordWrapping
        temp.textAlignment = .center
        self.addSubview(temp)
        var attrString = NSMutableAttributedString(string: R.string.localizable.do_not_disturb_15min_describ())
        let param = NSMutableParagraphStyle()
        param.lineSpacing = 2
        param.alignment = .center
        let attr: [NSAttributedString.Key : Any] = [.font: ADTheme.B1 ,.foregroundColor: ADTheme.C1 ,.paragraphStyle : param ]
        attrString.addAttributes(attr, range: NSRange(location: 0, length: attrString.length))
        temp.attributedText = attrString;
        temp.yoga.isEnabled = true
        temp.yoga.alignContent = .center
        temp.yoga.width = YGValue(value: 70, unit: YGUnit.percent)
        temp.yoga.marginTop = YGValue(30)
        return temp
    }()
    
    lazy var checkViewGroup : UIView = {
        let temp = UIView()
        self.addSubview(temp)
        
        temp.yoga.isEnabled = true
        temp.yoga.maxWidth = YGValue(value: 90, unit: YGUnit.percent)
        temp.yoga.marginTop = YGValue(15)
        temp.yoga.flexDirection = .row
        temp.yoga.alignItems = .center
        temp.yoga.alignContent = .center
        return temp
    }()
    
    lazy var checkBoxV : A4xBaseCheckBoxButton = {
        var temp = A4xBaseCheckBoxButton()
        temp.accessibilityIdentifier = "ad_check_box"
        temp.backgroundColor = UIColor.clear
        temp.setImage(image: R.image.checkbox_unselect(), state: ADCheckBoxState.normail)
        temp.setImage(image: R.image.checkbox_select(), state: ADCheckBoxState.selected)
        
        temp.addTarget(self, action: #selector(checkBoxAction(sender:)), for: UIControl.Event.touchUpInside)
        checkViewGroup.addSubview(temp)
        
        temp.yoga.isEnabled = true
        temp.yoga.width = YGValue(30)
        temp.yoga.height = YGValue(40)
        
        return temp
    }()
    
    lazy var notipLabel : UILabel = {
        let temp = UILabel()
        temp.font = ADTheme.B1
        temp.textColor = ADTheme.C3
        temp.text = R.string.localizable.not_show_tips_any_more()
        temp.numberOfLines = 0
        temp.lineBreakMode = .byWordWrapping
        checkViewGroup.addSubview(temp)

        temp.yoga.isEnabled = true

        return temp
    }()
    
    @objc
    func checkBoxAction(sender : UIButton){
        checkBoxV.boxState = checkBoxV.boxState.negate()
    }
    @objc private
    func rightActionButton() {
        self.onHiddenBlock? {}
        var isSelect : Bool = false
        if case .selected = checkBoxV.boxState {
            isSelect = true
        }
        self.onRightButtonAction?(isSelect)
    }
    
    @objc private
    func leftButtonAction() {
        self.onHiddenBlock? {}
    }
    
}
