//
//  ADDialogManager.swift
//  AddxAi
//
//  Created by zhi kuiyu on 2019/1/31.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import UIKit
import A4xBaseSDK

struct AniDirection: OptionSet {
    var rawValue: UInt
    static let Top          = AniDirection(rawValue: 1 << 0)
    static let Bottom       = AniDirection(rawValue: 1 << 1)
    static let Right        = AniDirection(rawValue: 1 << 2)
    static let Left         = AniDirection(rawValue: 1 << 3)
    static let Center       = AniDirection(rawValue: 1 << 4)
    
    public static func DefautDir() -> AniDirection {
        return [Top,Center]
    }
    
    public func OR (ain : AniDirection) -> AniDirection{
        return self.union(ain)
    }
    
    public func AND (ain : AniDirection) -> Bool{
        return self.contains(ain)
    }
}

enum ContentType {
    case Full
    case Left(width : Float)
    case Right(width : Float)
    case Center(width : Float)
}

let defaultHeight: Float = 400

class ADDialogManager: UIView {
    var currentShow : Bool = false ;
    var contentHeight : Float;
    var autoHiddenBlock : (() -> Void)?
    private var contentType : ContentType
    
    init(frame: CGRect = CGRect.zero , ContentType ct : ContentType = .Full , ContentHeight : Float = defaultHeight) {
        A4xLog("<---- ADDialogManager init")
        self.currentShow  = false
        self.contentType = ct
        self.contentHeight = ContentHeight
        super.init(frame: frame)
        self.clipsToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        A4xLog("----> ADDialogManager deinit")
    }
    
    func setRadio(radio : CGFloat , style : UIRectCorner){
        if radio == 0 {
            return
        }
        self.dialogListView?.setRadio(radio: radio, style: style)
    }
    
    var aniDir : AniDirection = AniDirection.DefautDir() {
        didSet {
            if !currentShow {
                dialogListView?.layer.anchorPoint = getFromPoint(dir: aniDir)
            }
        }
    }

    private lazy var dialogListView : ADDialogView? = {

        var temp = ADDialogView(frame: CGRect(x: 0, y: 0, width: self.width, height: CGFloat(self.contentHeight)))
        temp.maxHeight = CGFloat(self.contentHeight)
        temp.layer.anchorPoint = self.getFromPoint(dir: self.aniDir)
        self.addSubview(temp)
        
        weak var weakSelf = self
        
        temp.snp.makeConstraints({ (make) in
            make.top.equalTo(0)
            var type : ContentType = weakSelf?.contentType ?? .Full
            switch( type ){
                case .Full:
                    make.left.equalTo(0)
                    make.width.equalTo(weakSelf!.snp.width)
                case .Left(let width):
                    make.left.equalTo(0)
                    make.width.equalTo(width)
                case .Right(let width):
                    make.right.equalTo(weakSelf!.snp.right)
                    make.width.equalTo(width)
                case .Center(let width):
                    make.width.equalTo(width)
                    make.centerX.equalTo(weakSelf!.snp.centerX)
            }
            
        })
        return temp
    }()

    var adapter : ADDialogAdapterProtocol?{
        didSet{
            self.dialogListView?.adapter = adapter
        }
    }

    public func updateContentHeight (ContentHeight : Int = 300){
        self.dialogListView?.snp.updateConstraints { (make) in
            make.height.equalTo(ContentHeight)
        }
    }


    private func getFromPoint(dir : AniDirection) -> CGPoint {
        var yValuePos = -0.5
        var xValuePos = 0.5

        if dir.AND(ain: AniDirection.Top) {
            yValuePos = 1.5
        }

        if dir.AND(ain: .Left){
            xValuePos = 1.5
        }else if dir.AND(ain: .Right){
            xValuePos = -0.5
        }else if dir.AND(ain: .Center){
            xValuePos = 0.5
        }
        return CGPoint(x: xValuePos, y: yValuePos)
    }

    func showDialog(){
        if currentShow {
            return
        }
        currentShow = true
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: UIView.AnimationOptions.allowAnimatedContent, animations: {
            self.dialogListView?.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            self.backgroundColor = UIColor(white: 0.3, alpha: 0.1)
        })
    }

    func hiddenDialog(block : @escaping (() -> Void)){
        if !currentShow {
            return
        }
        currentShow = false

        UIView.animate(withDuration: 0.3, animations: {
            self.dialogListView?.layer.anchorPoint = self.getFromPoint(dir: self.aniDir)
            self.backgroundColor = UIColor(white: 0, alpha: 0)

        }) { (re) in
            self.dialogListView?.adapter = nil;
            block()
        }

    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    
        
        super.touchesBegan(touches, with: event)
        let touch = touches.first
        let point = touch?.location(in: self)
        if currentShow && self.dialogListView != nil {
            if self.dialogListView!.frame.contains(point!) {
                return
            }
            
            hiddenDialog {
                if (self.autoHiddenBlock != nil ) {
                    self.autoHiddenBlock!()
                }
            }
        }
    }

}
