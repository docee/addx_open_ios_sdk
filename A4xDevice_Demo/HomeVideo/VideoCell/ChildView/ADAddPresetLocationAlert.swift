//
//  ADAddPresetLocationAlert.swift
//  AddxAi
//
//  Created by kzhi on 2019/11/22.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import Foundation
import UIKit
import A4xBaseSDK

class ADAddPresetLocationAlert : UIView  , A4xBaseAlertViewProtocol {
    var identifier: String
    var config: A4xBaseAlertConfig
    var onHiddenBlock: ((@escaping () -> Void) -> Void)?
    var awidth : CGFloat = 0
    let paddingvertical : CGFloat = 15.auto()
    var onEditDone : ((String?)->Void)?
    var lastYvalue : CGFloat = 0
    var image : UIImage? {
        didSet {
            self.imageV.image = image
        }
    }
    var moveYValue : CGFloat = 0
    
    public override init(frame: CGRect = CGRect.zero ) {
        self.config = A4xBaseAlertConfig()
        self.config.outBoundsHidden = false
        self.config.type = .alert(A4xBaseAlertAnimailType.scale)
        self.identifier = "A4xBindLocationSelectView"
        awidth = 300.auto()
        super.init(frame: frame)
        self.setUpView()
        addNotcation()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.removeNotcation()
        A4xLog("ADAddPresetLocationAlert deinit")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if !self.textField.isFirstResponder {
            lastYvalue = self.minY
        }
    }
    
    private func setUpView() {
        self.backgroundColor = UIColor.white
        self.layer.cornerRadius = 11.auto()
        self.clipsToBounds = true
        self.frame = CGRect(x: 0, y: 0, width: awidth, height:  300.auto() )
        self.leftView.isHidden = false
        self.rightView.isHidden = false
        self.imageV.isHidden = false
        self.textField.isHidden = false
    }
    
    private lazy
    var imageV : UIImageView = {
        let temp = UIImageView()
        temp.contentMode = .scaleToFill
        temp.image = R.image.user_login_bg()
        temp.clipsToBounds = true
        temp.layer.cornerRadius = 11.auto()
        temp.clipsToBounds = true
        self.addSubview(temp)

        temp.snp.makeConstraints { (make) in
            make.top.equalTo(18.auto())
            make.left.equalTo(18.auto())
            make.width.equalTo(self.snp.width).offset(-36.auto())
            make.height.equalTo(144.auto())
        }
        return temp
    }()
    
    private lazy
    var textField : A4xBaseTextField = {
        let temp = A4xBaseTextField()
        temp.maxLength = 16
        temp.inset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        temp.layer.cornerRadius = 6.auto()
        temp.layer.borderColor = UIColor.hex(0xDADBE0).cgColor
        temp.layer.borderWidth = 1
        temp.textColor = ADTheme.C1
        temp.placeholder = R.string.localizable.preset_location()
        self.addSubview(temp)
        
        temp.snp.makeConstraints { (make) in
            make.top.equalTo(self.imageV.snp.bottom).offset(20.auto())
            make.left.equalTo(18.auto())
            make.width.equalTo(self.snp.width).offset(-36.auto())
            make.height.equalTo(40.auto())
        }
        return temp
    }()
    
    
    private lazy var leftView : UIButton = {
        let temp = UIButton()
        temp.accessibilityIdentifier = "alert_left_button"
        temp.addTarget(self, action: #selector(leftButtonAction), for: .touchUpInside)
        temp.titleLabel?.font = ADTheme.B1
        temp.setTitleColor(UIColor.hex(0x2F3742), for: .normal)
        self.addSubview(temp)
        temp.setTitle(R.string.localizable.cancel(), for: .normal)

        temp.snp.makeConstraints { (make) in
            make.left.equalTo(0)
            make.bottom.equalTo(self.snp.bottom)
            make.width.equalTo(self.snp.width).multipliedBy(0.5)
            make.height.equalTo(50.auto())

        }
        return temp;
    }()
    
    private lazy var rightView : UIButton = {
        let temp = UIButton()
        temp.accessibilityIdentifier = "alert_right_button"
        temp.addTarget(self, action: #selector(rightButtonAction), for: .touchUpInside)
        temp.titleLabel?.font = ADTheme.B1
        temp.setTitleColor(ADTheme.Theme, for: .normal)
        temp.setTitle(R.string.localizable.done(), for: .normal)
        self.addSubview(temp)
        temp.snp.makeConstraints { (make) in
            make.right.equalTo(self.snp.right)
            make.bottom.equalTo(self.snp.bottom)
            make.width.equalTo(self.snp.width).multipliedBy(0.5)
            make.height.equalTo(50.auto())

        }
        return temp
    }()
    
    private func addNotcation() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(noti:)), name: UIResponder.keyboardWillShowNotification , object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(noti:)), name: UIResponder.keyboardWillHideNotification , object: nil)
    }
    
    private func removeNotcation(){
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillShow(noti : NSNotification){
        guard noti.userInfo != nil else {
            return
        }
        
        let keyBoardMiny = ( noti.userInfo![UIResponder.keyboardFrameEndUserInfoKey]  as? NSValue)?.cgRectValue.minY ?? 0
        let toFrameMiny = keyBoardMiny - self.height
        
        let animilTime = ( noti.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey]  as? NSNumber)?.floatValue ?? 0

        UIView.beginAnimations("keyshow", context: nil)
        UIView.setAnimationDuration(TimeInterval(animilTime))
        self.frame = CGRect(x: self.minX, y: toFrameMiny, width: self.width, height: self.height)
        UIView.commitAnimations()
    }
    
    @objc func keyboardWillHide(noti : NSNotification){
        let animilTime = ( noti.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey]  as? NSNumber)?.floatValue ?? 0

        UIView.beginAnimations("keyshow", context: nil)
        UIView.setAnimationDuration(TimeInterval(animilTime))
        self.frame = CGRect(x: self.minX, y: lastYvalue , width: self.width, height: self.height)
        UIView.commitAnimations()
    }
    

    @objc private
    func rightButtonAction(){
        var resultStr : String? = R.string.localizable.preset_location()
        
        if let str = self.textField.text , str.count > 0 {
            resultStr = str
        }
        self.onEditDone?(resultStr)

        
        let _ = self.textField.resignFirstResponder()
        self.onHiddenBlock? {}
    }
    
    @objc private
    func leftButtonAction(){
        let _ = self.textField.resignFirstResponder()
        self.onHiddenBlock? {}
    }
    
    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()
        
        
        ctx?.move(to: CGPoint(x: 0, y: self.height - 50.auto()))
        ctx?.addLine(to: CGPoint(x: self.width, y: self.height - 50.auto()))
        ctx?.move(to: CGPoint(x: self.width / 2 , y: self.height))
        ctx?.addLine(to: CGPoint(x: self.width / 2, y: self.height - 50.auto()))
        ctx?.setLineWidth(1)
        ctx?.setStrokeColor(UIColor.hex(0x000050, alpha: 0.1).cgColor)
        ctx?.drawPath(using: .stroke)

    }
}

