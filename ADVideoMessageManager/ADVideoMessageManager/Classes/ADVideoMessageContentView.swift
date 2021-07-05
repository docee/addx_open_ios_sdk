//
//  ADVideoMessageContentView.swift
//  ADVideoMessageManager
//
//  Created by kzhi on 2020/12/9.
//

import UIKit
import AutoInch
import YYWebImage

class ADVideoMessageContentView : UIView {
    var message : ADVideoMessageModel? {
        didSet{
            updateLayout()
        }
    }
    convenience init(){
        self.init(frame: CGRect.zero)
    }
    
    public  var messageContentHiddenBlock :(()->Void)?
    
    public  var canShowNoTipButton : Bool = true
    public  var noTipButtonIsVisable : Bool = true
    
    public  var moveHeightChangeDistance : CGFloat = 0
    public  var moveTopChangeDistance : CGFloat = 0
    
    public  var defaultMinX : CGFloat = 0

    private let noTipButtonHeight : CGFloat = 40.auto()
    private let noTipButtonMargenTop : CGFloat = 15.auto()

    private let imageMargenTop : CGFloat = 8.auto()
    private let imageMargenLeft : CGFloat = 8.auto()
    
    private let infoMargenTop : CGFloat = 9.auto()
    private let infoMargenLeft : CGFloat = 8.auto()
    private let infoMargenRight : CGFloat = 8.auto()

    private let dateInfoMargenTop : CGFloat = 5.auto()
    private let deviceNameMargenTop : CGFloat = 3.auto()
    
    
    private let galleryBarMargenTop : CGFloat = 16.auto()
    private let galleryBarMargenBotton : CGFloat = 8.auto()
    private let galleryBarSize : CGSize = CGSize(width: 34.0.auto(), height: 4.0.auto())

    private let imageSize : CGSize = CGSize(width: 113.0.auto(), height: 62.0.auto())

    var viewSize : CGSize = CGSize.zero {
        didSet {
            if oldValue != viewSize {
                self.updateLayout()
            }
        }
    }
    
    override var frame: CGRect {
        didSet {
            viewSize = frame.size
            if viewSize.height < 50 && viewSize.height > 0{
                print("--")
            }
        }
    }
    
    var moveOffset : CGFloat = 0
    
    func moveBarTranform(yvalue : CGFloat , isMoveBar : Bool) {
        var newHeight = self.sizeThatFits(CGSize(width: self.frame.width, height: 1000)).height

        moveOffset = min(moveOffset + yvalue, noTipButtonHeight + noTipButtonMargenTop)
        
        let isChangeHeight = isMoveBar && moveOffset > 0
        if isChangeHeight {
            //print("---------------------- \(moveOffset)")
            var toDistance = CGFloat(moveHeightChangeDistance + yvalue)
            if toDistance >= (noTipButtonHeight + noTipButtonMargenTop) {
                toDistance = noTipButtonHeight + noTipButtonMargenTop
            }
            moveHeightChangeDistance = toDistance //接收到的是高度变化
        }else {
            newHeight = self.frame.height
            moveTopChangeDistance += yvalue
            if moveTopChangeDistance > self.defaultMinX {
                moveTopChangeDistance = self.defaultMinX
            }
            //print("----------------------\(moveOffset) \(moveTopChangeDistance) --   \(yvalue) -- \(newHeight) --\(self.frame.width)")
        }
        
        
//        if isMoveBar {
//            if moveTopChangeDistance > -self.frame.height {//需要隐藏
//                var toDistance = CGFloat(moveHeightChangeDistance + yvalue)
//                if toDistance >= 0 {
//                    if toDistance >= (noTipButtonHeight + noTipButtonMargenTop) {
//                        toDistance = noTipButtonHeight + noTipButtonMargenTop
//                    }
//                    moveHeightChangeDistance = toDistance //接收到的是高度变化
//                    let newHeight = self.sizeThatFits(CGSize(width: self.frame.width, height: 1000)).height
//                    self.frame = CGRect(x: self.frame.minX, y: self.defaultMinX, width: self.frame.width, height: newHeight)
//                    return
//                }else {
//                    moveHeightChangeDistance = 0
//                }
//            }
//        }
//
//        moveTopChangeDistance += yvalue
//        if moveTopChangeDistance > 0 {
//            moveTopChangeDistance = 0
//        }
        
        self.frame = CGRect(x: self.frame.minX, y: self.defaultMinX + moveTopChangeDistance, width: self.frame.width, height: newHeight)

    }
    
    func updateBarVisable(isMoveBar : Bool){
        defer {
            self.moveBarTranform(yvalue: 0, isMoveBar: isMoveBar)
            moveOffset = isMoveBar ? moveHeightChangeDistance : 0
        }
        
        if isMoveBar {
            if moveHeightChangeDistance > 0 {
                let progress = CGFloat(moveHeightChangeDistance) / CGFloat(noTipButtonHeight + noTipButtonMargenTop)
                if progress <  0.5 {
                    moveHeightChangeDistance = 0
                }else {
                    moveHeightChangeDistance = noTipButtonHeight + noTipButtonMargenTop
                }
            }
        }
        
        if abs(moveOffset) < self.frame.height / 3 || moveOffset > 0  {
            moveTopChangeDistance = 0
        }else if moveOffset < 0 {
            moveTopChangeDistance = -self.defaultMinX - self.frame.height
            messageContentHiddenBlock?()
        }
    }
    
    func moveTohidden(){
        moveOffset = 0
        moveHeightChangeDistance = 0
        moveTopChangeDistance = -self.defaultMinX - self.frame.height
        messageContentHiddenBlock?()
        self.moveBarTranform(yvalue: 0, isMoveBar: false)
    }
    
    func showBar(){
        if moveHeightChangeDistance == noTipButtonHeight + noTipButtonMargenTop {
            return
        }
        moveOffset = noTipButtonHeight + noTipButtonMargenTop
        moveHeightChangeDistance = noTipButtonHeight + noTipButtonMargenTop
        moveTopChangeDistance = 0
        self.moveBarTranform(yvalue: 0, isMoveBar: true)
        moveOffset = 0
    }
    
    func reset() {
        moveOffset = 0
        moveTopChangeDistance = 0
        moveHeightChangeDistance = 0
    }
    
    func locationView(ofPoint point : CGPoint) -> ADVideoMessageLoctionInView {
        if self.isMoveBar(point: point) {
            return .moveBar
        }else if self.noTipButton.frame.contains(point) {
            return .messageNotip
        }else if point.y < self.noTipButton.frame.minY && point.y > 0 {
            return .content
        }
        return .content
    }
    
    func isMoveBar(point : CGPoint) -> Bool {
        let gaTop = self.galleryBarView.frame.minY - 20
        let gaBottom = self.galleryBarView.frame.maxY + 20
        if point.y >= gaTop && gaBottom >= point.y {
            return true
        }
        return false
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        updateInfo()
        var totalHeight : CGFloat = 0
        
        totalHeight += imageMargenTop
        totalHeight += self.titleNameLable.sizeThatFits(CGSize(width: size.width - imageSize.width - imageMargenLeft - infoMargenLeft - infoMargenRight, height: size.height)).height
        totalHeight += self.deviceNameLabel.sizeThatFits(CGSize(width: size.width - imageSize.width - imageMargenLeft - infoMargenLeft - infoMargenRight, height: size.height)).height
        
        totalHeight += dateInfoMargenTop
        totalHeight += self.messageTimeLabel.sizeThatFits(CGSize(width: size.width - imageSize.width - imageMargenLeft - infoMargenLeft - infoMargenRight, height: size.height)).height

        totalHeight = max(totalHeight, imageMargenTop + imageSize.height )
        totalHeight += moveTopChangeDistance
        totalHeight += moveHeightChangeDistance

        
        
        totalHeight += galleryBarMargenTop
        totalHeight += galleryBarSize.height
        totalHeight += galleryBarMargenBotton
        return CGSize(width: size.width, height: totalHeight)
    }
    
    func updateInfo(){
        guard let config = ADVideoMessageManager.shared.config else {
            return
        }
        
        self.messageTimeLabel.text = config.loadStringBlock(.messageDateString(time: Date().timeIntervalSince1970))
        if let urlString = message?.image , let url = URL(string: urlString) {
            self.msgImageV.yy_setImage(with: url, placeholder: UIImage.adNamed(named: "message_default_bg"))
        }else {
            self.msgImageV.image = UIImage.adNamed(named: "message_default_bg")
        }
        self.deviceNameLabel.text = message?.deviceTitle // 添加push 通知名字
        let tagInfo = message?.eventInfoList?.joined(separator: "\n")
        self.titleNameLable.text = tagInfo ?? message?.pushInfo
        self.noTipButton.setTitle(config.loadStringBlock(.messageNoTipButton), for: .normal)
        if let color : UIColor = config.loadColorBlock(.theme) {
            self.noTipButton.backgroundColor = color
        }
    }
    
    
    func updateLayout() {
        updateInfo()
        self.msgImageV.frame = CGRect(x: imageMargenLeft, y: imageMargenTop, width: imageSize.width, height: imageSize.height)
        let infoWidth = self.frame.width - self.msgImageV.frame.maxX - infoMargenLeft - infoMargenRight
        let infoLeft =  self.msgImageV.frame.maxX + infoMargenLeft
        let titleNameSize = self.titleNameLable.sizeThatFits(CGSize(width: infoWidth, height: 200))
        
        self.titleNameLable.frame = CGRect(x: infoLeft, y: infoMargenTop, width: titleNameSize.width, height: titleNameSize.height)
        
        let deviceNameSize = self.deviceNameLabel.sizeThatFits(CGSize(width: infoWidth, height: 200))

        self.deviceNameLabel.frame = CGRect(x: infoLeft, y: self.titleNameLable.frame.maxY + deviceNameMargenTop , width: deviceNameSize.width, height: deviceNameSize.height)
        
        let messageTimeSize = self.messageTimeLabel.sizeThatFits(CGSize(width: infoWidth, height: 200))

        self.messageTimeLabel.frame = CGRect(x: infoLeft, y: self.deviceNameLabel.frame.maxY + dateInfoMargenTop, width: messageTimeSize.width , height: messageTimeSize.height)
        
        if canShowNoTipButton {
            self.noTipButton.isHidden = false
            let maxYValue = max(self.messageTimeLabel.frame.maxY, self.msgImageV.frame.maxY)
            
            self.noTipButton.frame = CGRect(x: imageMargenLeft, y: maxYValue + noTipButtonMargenTop, width: self.frame.width - imageMargenLeft - infoMargenRight , height: noTipButtonHeight)
            var progress = CGFloat(moveHeightChangeDistance) / CGFloat(noTipButtonHeight + noTipButtonMargenTop)
            progress = max(0, progress)
            if progress < 0.8 {
                progress = progress * progress * 0.8
            }
            noTipButton.alpha = progress 
        }else {
            self.noTipButton.isHidden = true
        }
        
        self.galleryBarView.frame = CGRect(x: self.bounds.midX - galleryBarSize.width / 2, y: self.frame.height - galleryBarMargenBotton - galleryBarSize.height, width: galleryBarSize.width, height: galleryBarSize.height)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        // shadowCode
        self.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.14).cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 1)
        self.layer.shadowOpacity = 1
        self.layer.shadowRadius = 7.auto()
        self.layer.cornerRadius = 9.auto()

    }
    
    lazy var bgLayer : CALayer = {
        // fillCode
        let bgLayer1 = CALayer()
        bgLayer1.frame = self.bounds
        bgLayer1.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1).cgColor
        self.layer.addSublayer(bgLayer1)
        
        return bgLayer1
    }()
    
    lazy var msgImageV : UIImageView = {
        let temp = UIImageView()
        temp.image = UIImage.adNamed(named: "message_default_bg")
        temp.contentMode = .scaleToFill
        temp.layer.cornerRadius = 8.auto()
        temp.clipsToBounds = true
        self.addSubview(temp)
        return temp
    }()
    
    
    lazy var titleNameLable : UILabel = {
        let label = UILabel()
        let attrString = NSMutableAttributedString(string: "发现有人经过")
        label.numberOfLines = 0
        let attr: [NSAttributedString.Key : Any] = [.font: UIFont.systemFont(ofSize: 16.auto(), weight: .medium),.foregroundColor: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)]
        attrString.addAttributes(attr, range: NSRange(location: 0, length: attrString.length))
        label.attributedText = attrString
        self.addSubview(label)
        
        return label
    }()
    
    
    lazy var deviceNameLabel : UILabel = {
        let label = UILabel()
        let attrString = NSMutableAttributedString(string: "家门口的摄像头")
        label.numberOfLines = 0
        let attr: [NSAttributedString.Key : Any] = [.font: UIFont.systemFont(ofSize: 13.auto(), weight: .regular),.foregroundColor: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)]
        attrString.addAttributes(attr, range: NSRange(location: 0, length: attrString.length))
        label.attributedText = attrString
        self.addSubview(label)

        return label
    }()
    
    lazy var messageTimeLabel : UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 13.auto(), weight: .regular)
        label.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        label.text = "下午15:23，2020.01.10"
        self.addSubview(label)

        return label

    }()
    
    
    lazy var galleryBarView : UIView = {
        let layerView = UIView()
        layerView.isUserInteractionEnabled = false
        layerView.layer.backgroundColor = UIColor(red: 0.76, green: 0.76, blue: 0.76, alpha: 1).cgColor
        layerView.layer.cornerRadius = 2.auto()
        self.addSubview(layerView)
        
        return layerView
    }()
    
    lazy var noTipButton : UIButton = {
        let temp = UIButton()
        temp.backgroundColor = UIColor(red: 0.35, green: 0.77, blue: 0.65, alpha: 1)
        self.addSubview(temp)
        temp.isUserInteractionEnabled = false

        temp.layer.cornerRadius = self.noTipButtonHeight / 2
        temp.clipsToBounds = true
        temp.setTitle("15分钟内通知勿扰", for: .normal)
        return temp
    }()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
