//
//  ADMessageCountView.swift
//  ADVideoMessageManager
//
//  Created by kzhi on 2020/12/9.
//

import UIKit
import AutoInch
class ADMessageCountView : UIView {
    private let imageSize : CGSize = CGSize(width: 28.auto(), height: 28.auto())
    private let imageInset : UIEdgeInsets = UIEdgeInsets(top: 14.auto(), left: 16.auto(), bottom: 14.auto(), right: 16.auto())
    
    private let infoInset : UIEdgeInsets = UIEdgeInsets(top: 19.auto(), left: 0.auto(), bottom: 19.auto(), right: 10.auto())
    
    convenience init() {
        self.init(frame : .zero)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.layer.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1).cgColor
        // shadowCode
        self.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.14).cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 1)
        self.layer.shadowOpacity = 1
        self.layer.shadowRadius = 7
        self.layer.cornerRadius = 8
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        }
    }
    
    var messageCount : Int = 0 {
        didSet {
            updateLayout()
        }
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        updateInfo()
        
        let messageWidth = self.bounds.width - imageSize.width - imageInset.left - imageInset.right - infoInset.left - infoInset.right
        let msgHeight = self.messageView.sizeThatFits(CGSize(width: messageWidth, height: 200)).height

        
        let showImageHeight = imageSize.height + imageInset.top + imageInset.bottom
        let showInfoHeight = msgHeight + infoInset.top + infoInset.bottom
        
        let showHeight = max(showImageHeight, showInfoHeight)
        return CGSize(width: size.width, height: showHeight)
    }
    
    
    func updateInfo(){
        if let manConf = ADVideoMessageManager.shared.config {
            self.messageView.text = manConf.loadStringBlock(.messageCountDestion(count: messageCount))
        }
    }
    
    func updateLayout(){
        updateInfo()
        
        self.imageView.frame = CGRect(x: imageInset.left, y: self.bounds.midY  - imageSize.height / 2, width: imageSize.height, height: imageSize.height)
        let messageWidth = self.bounds.width - imageSize.width - imageInset.left - imageInset.right - infoInset.left - infoInset.right
        let msgHeight = self.messageView.sizeThatFits(CGSize(width: messageWidth, height: 200)).height
        
        self.messageView.frame = CGRect(x: self.imageView.frame.maxX + imageInset.right + infoInset.left, y: self.bounds.midY - msgHeight / 2, width: messageWidth, height: msgHeight)
    }
    
    
    lazy var imageView : UIImageView = {
        let temp = UIImageView()
        self.addSubview(temp)
        temp.contentMode = .scaleAspectFit
        temp.image = UIImage.adNamed(named: "new_message")
        return temp
    }()
    
    lazy var messageView : UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        label.text = "共有23条摄像机通知"
        self.addSubview(label)
        
        return label
    }()
}
