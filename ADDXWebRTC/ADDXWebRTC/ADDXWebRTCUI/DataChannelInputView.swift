//
//  DataChannelInputView.swift
//  WebRTC-Demo
//
//  Created by Hao Shen on 5/25/20.
//  Copyright © 2020 Stas Seldin. All rights reserved.
//

import UIKit

let buttonWidth = 50.0
let buttonHeight = 40.0
let sideSpace = 10.0
let topSpace = 5.0
let defaultMinViewHight = 100.0
let sucessColor = UIColor.green
let failColor = UIColor.red
let receiveColor = UIColor.blue
class DataChannelInputView: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    /// 声明一个 发送消息的Block
    var sendTextBlock: ((String) -> ())?
    private var sendedText = NSMutableAttributedString();
    
    //显示发送和接受的消息
    private var sendedTextListView: UITextView?
    //发送消息输入框
    private var inputTextView: UITextField?
    //发送消息按钮
    private var sendButton: UIButton?
    //保持当前view在键盘出现之前的位置
    private var originFrame: CGRect?
    
    
    override init(frame: CGRect) {
        var newFrame = frame
        if newFrame.size.height < CGFloat(defaultMinViewHight){
            newFrame.size.height = CGFloat(defaultMinViewHight)
        }
        self.originFrame = CGRect.zero
        super.init(frame: newFrame)
        self.reloadSubViews()
        self.registerNotification()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.reloadSubViews()
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        self.reloadSubViews()
    }
    deinit {
        self.releaseNotification()
    }
    func reloadSubViews() -> Void {
        var x : CGFloat?
        var y : CGFloat?
        var width : CGFloat?
        var height : CGFloat?
        
        x = CGFloat(sideSpace)
        y = CGFloat(Double(self.frame.size.height) - topSpace - buttonHeight)
        width = CGFloat(Double(self.frame.size.width) - buttonWidth - 3*sideSpace)
        height = CGFloat(buttonHeight)
        
        if self.inputTextView == nil {
            let textView = UITextField.init(frame: CGRect.init(x:x! , y:y!, width:width! , height:height! ))
            self.addSubview(textView)
            textView.layer.cornerRadius = 5.0
            textView.clipsToBounds = true
            textView.backgroundColor = UIColor.white
            textView.placeholder = "请输入"
            self.inputTextView = textView;
        }
        self.inputTextView?.frame = CGRect.init(x:x! , y:y!, width:width! , height:height!)
        
        x = CGFloat(Double(self.frame.size.width) - sideSpace - buttonWidth)
        y = CGFloat(Double(self.frame.size.height) - topSpace - buttonHeight)
        width = CGFloat(buttonWidth)
        height = CGFloat(buttonHeight)
        
        if self.sendButton == nil{
            let button = UIButton.init(type: .custom)
            button.frame = CGRect.init(x: x!, y:y! , width: width!, height: height!)
            button.setTitle("发送", for: .normal)
            button.addTarget(self, action: #selector(sendButtonClicked), for: .touchUpInside)
            button.layer.cornerRadius = 5.0
            button.clipsToBounds = true
            button.backgroundColor = UIColor.red
            self.addSubview(button)
            self.sendButton = button
        }
        self.sendButton?.frame = CGRect.init(x:x! , y:y!, width:width! , height:height!)

        
        x = CGFloat(sideSpace)
        y = CGFloat(topSpace)
        width = CGFloat(Double(self.frame.size.width)  - 2*sideSpace)
        height = CGFloat(Double(self.frame.size.height) - 2*topSpace - buttonHeight)
        
        if self.sendedTextListView == nil{
            let sendtextListView = UITextView.init(frame: CGRect.init(x:x! , y:y!, width: width!, height:height!))
            self.addSubview(sendtextListView)
            sendtextListView.backgroundColor = UIColor.clear
            sendtextListView.isEditable = false
            self.sendedTextListView = sendtextListView;
        }
        self.sendedTextListView?.frame = CGRect.init(x:x! , y:y!, width:width! , height:height!)

    }
    
    
    @objc func sendButtonClicked(sender: UIButton) -> Void {
        let message = self.inputTextView!.text
        if message!.count > 0 {
            sendTextBlock?(message!)
        }
        
    }

    func updateSendedMessage(message:String , sucess: Bool, receive: Bool) -> Void {
        var color = failColor
        if sucess {
            color = sucessColor
        }
        if receive {
            color = receiveColor
        }
        let attributeString = NSAttributedString(string: message+"\n", attributes: [NSAttributedString.Key.font:UIFont.systemFont(ofSize: 13.5),NSAttributedString.Key.foregroundColor : color])
        self.sendedText.append(attributeString)
        DispatchQueue.main.async {
            self.sendedTextListView?.attributedText = self.sendedText
        }
    }
    
    func registerNotification(){
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyBoardWillShow(_ :)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyBoardWillHide(_ :)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }
    
    //MARK:键盘通知相关操作
    @objc func keyBoardWillShow(_ notification:Notification){

        DispatchQueue.main.async {
            if self.originFrame == CGRect.zero {
                self.originFrame = self.frame
            }
            let user_info = notification.userInfo
            let keyboardRect = (user_info?[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            let y = keyboardRect.origin.y
            let y2 = CGFloat(self.originFrame!.origin.y + self.originFrame!.size.height)
            let offset_y = (Int(y2) > Int(y)) ? (self.originFrame!.maxY - y):(0)
            var frame = self.originFrame
            frame?.origin.y -= offset_y
            UIView.animate(withDuration: 0.25, animations: {
                self.frame = frame!
            })
        }
    }

    @objc func keyBoardWillHide(_ notification:Notification){
        DispatchQueue.main.async {
            self.frame = self.originFrame!
        }
    }
    
    func releaseNotification(){
        NotificationCenter.default.removeObserver(self)
    }
}
