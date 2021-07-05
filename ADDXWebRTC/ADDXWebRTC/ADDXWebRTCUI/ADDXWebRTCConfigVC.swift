//
//  ConfigViewController.swift
//  WebRTC-Demo
//
//  Created by Hao Shen on 5/22/20.
//  Copyright © 2020 Stas Seldin. All rights reserved.
//

import UIKit

public class ADDXWebRTCConfigVC: UIViewController {

    public  var settingBlock: (() -> ())?

    private var groupIDtf: UITextField!
    private var roleftf: UITextField!
    private var idTf: UITextField!
    private var recipientClientIdTf: UITextField!
    private var scrollview: UIScrollView!
    private var enterBtn: UIButton!

    private var currentTF: UITextField?
    private var originFrame:CGRect?
    
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.registerNotification()
    }
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.releaseNotification()
    }
    
    private func loadSubViews(){
        self.view.backgroundColor = UIColor.lightGray
        let sc = UIScrollView.init(frame: self.view.bounds)
        self.view.addSubview(sc)
        var arm1 = UIView.AutoresizingMask.init(arrayLiteral: .flexibleLeftMargin,.flexibleTopMargin,.flexibleRightMargin,.flexibleWidth)
        sc.autoresizingMask = arm1
        sc.contentSize = CGSize.init(width: 0, height: 390)
        self.scrollview = sc
        
        let groupIDLabel = UILabel.init(frame: CGRect.init(x: 60, y: 116, width: 70, height: 21))
        groupIDLabel.text = "groupID"
        groupIDLabel.textAlignment = .right
        self.scrollview.addSubview(groupIDLabel)
        arm1 = UIView.AutoresizingMask.init(arrayLiteral: .flexibleLeftMargin,.flexibleTopMargin)
        groupIDLabel.autoresizingMask = arm1
        
        let roleLabel = UILabel.init(frame: CGRect.init(x: 62, y: 166, width: 68, height: 21))
        roleLabel.text = "role"
        roleLabel.textAlignment = .right
        self.scrollview.addSubview(roleLabel)
        arm1 = UIView.AutoresizingMask.init(arrayLiteral: .flexibleLeftMargin,.flexibleTopMargin)
        roleLabel.autoresizingMask = arm1
        
        let iDLabel = UILabel.init(frame: CGRect.init(x: 62, y: 221, width: 70, height: 21))
        iDLabel.text = "id"
        iDLabel.textAlignment = .right
        self.scrollview.addSubview(iDLabel)
        arm1 = UIView.AutoresizingMask.init(arrayLiteral: .flexibleLeftMargin,.flexibleTopMargin)
        iDLabel.autoresizingMask = arm1
        
        let rercipientClientIDLabel = UILabel.init(frame: CGRect.init(x: 5, y: 281, width: 132, height: 21))
        rercipientClientIDLabel.text = "rercipientClientID"
        rercipientClientIDLabel.textAlignment = .right
        self.scrollview.addSubview(rercipientClientIDLabel)
        arm1 = UIView.AutoresizingMask.init(arrayLiteral: .flexibleLeftMargin,.flexibleTopMargin)
        rercipientClientIDLabel.autoresizingMask = arm1
        
        let groupIDtf = UITextField.init(frame: CGRect.init(x: 157, y: 110, width: 138, height: 34))
        self.scrollview.addSubview(groupIDtf)
        arm1 = UIView.AutoresizingMask.init(arrayLiteral: .flexibleLeftMargin,.flexibleTopMargin,.flexibleWidth,.flexibleRightMargin)
        groupIDtf.autoresizingMask = arm1
        groupIDtf.borderStyle = .roundedRect
        self.groupIDtf = groupIDtf
        self.groupIDtf.delegate = self
        
        let roleftf = UITextField.init(frame: CGRect.init(x: 157, y: 166, width: 138, height: 34))
        self.scrollview.addSubview(roleftf)
        arm1 = UIView.AutoresizingMask.init(arrayLiteral: .flexibleLeftMargin,.flexibleTopMargin,.flexibleWidth,.flexibleRightMargin)
        roleftf.autoresizingMask = arm1
        roleftf.borderStyle = .roundedRect
        self.roleftf = roleftf
        self.roleftf.delegate = self

        let idTf = UITextField.init(frame: CGRect.init(x: 157, y: 217, width: 138, height: 34))
        self.scrollview.addSubview(idTf)
        arm1 = UIView.AutoresizingMask.init(arrayLiteral: .flexibleLeftMargin,.flexibleTopMargin,.flexibleWidth,.flexibleRightMargin)
        idTf.autoresizingMask = arm1
        idTf.borderStyle = .roundedRect
        self.idTf = idTf
        self.idTf.delegate = self
        
        let recipientClientIdTf = UITextField.init(frame: CGRect.init(x: 157, y: 277, width: 138, height: 34))
        self.scrollview.addSubview(recipientClientIdTf)
        arm1 = UIView.AutoresizingMask.init(arrayLiteral: .flexibleLeftMargin,.flexibleTopMargin,.flexibleWidth,.flexibleRightMargin)
        recipientClientIdTf.autoresizingMask = arm1
        recipientClientIdTf.borderStyle = .roundedRect
        self.recipientClientIdTf = recipientClientIdTf
        self.recipientClientIdTf.delegate = self

        let btn = UIButton.init(type: .custom)
        btn.frame = CGRect.init(x: 99, y: 353, width: 150, height: 45)
        btn.setTitle("进入直播", for: .normal)
        btn.backgroundColor = UIColor.red
        btn.addTarget(self, action: #selector(enterRoomBtn(_:)), for: .touchUpInside)
        self.enterBtn = btn
        self.scrollview.addSubview(btn)
        arm1 = UIView.AutoresizingMask.init(arrayLiteral: .flexibleLeftMargin,.flexibleTopMargin,.flexibleRightMargin)
        btn.autoresizingMask = arm1

        
        let backbtn = UIButton.init(type: .custom)
        backbtn.frame = CGRect.init(x: 12, y: 20, width: 52, height: 52)
        backbtn.setImage(UIImage.init(named: "icon_back_write"), for: .normal)
        backbtn.addTarget(self, action: #selector(backBtnClicked), for: .touchUpInside)
        self.view .addSubview(backbtn)
        
    }
    @objc func backBtnClicked(sender: UIButton) -> Void {
        if self.navigationController != nil {
            if self.navigationController?.viewControllers.first == self{
                self.navigationController?.dismiss(animated: true, completion: {
                    
                })
            }else{
                self.navigationController?.popViewController(animated: true)
            }
        }else{
            self.dismiss(animated: true) {
                
            }
        }
    }
//    public override var shouldAutorotate:Bool{
//        return false
//
//    }
//    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
//        return .landscapeLeft
//    }
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.loadSubViews()
        let capture = WebRTCVideoCapture.init()
        debugPrint(capture)
        // Do any additional setup after loading the view.
        self.currentTF = nil
        self.originFrame = CGRect.zero
        self.groupIDtf.text = "v-master"
        self.roleftf.text = "viewer"
        self.idTf.text = "viewer003"
        self.recipientClientIdTf.text = "v-master"

        self.scrollview.contentSize = CGSize.init(width: 0.0, height: 390)
        let tgr = UITapGestureRecognizer.init(target: self, action: #selector(touchTGRClicked))
        self.view.addGestureRecognizer(tgr)
    }


    @IBAction func enterRoomBtn(_ sender: Any) {
        let roomViewController = ADDXWebRTCVideoVC()
        roomViewController._groupId  = self.groupIDtf.text ?? "group001"
        roomViewController._roleId  = self.roleftf.text ?? "viewer"
        roomViewController._clientId  = self.idTf.text ?? "viewer003"
        roomViewController._recipientClientId  = self.recipientClientIdTf.text ?? "master008"
        roomViewController.settingBtnClickedBlock = {
            self.settingBlock?()
        }
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.navigationController?.pushViewController(roomViewController, animated: true)
    }
    @objc func touchTGRClicked(tgr:UITapGestureRecognizer){
        self.view.endEditing(true)
    }
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    func registerNotification(){
        self.originFrame = CGRect.zero
        
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
                self.originFrame = self.currentTF?.frame
            }
            debugPrint(self.originFrame!)
            let user_info = notification.userInfo
            let keyboardRect = (user_info?[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            let y = keyboardRect.origin.y
            let y2 = CGFloat(self.originFrame!.origin.y + self.originFrame!.size.height)
            let offset_y = (Int(y2) > Int(y)) ? (self.originFrame!.maxY - y):(0)
            var frame = CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
            frame.origin.y -= offset_y
            UIView.animate(withDuration: 0.25, animations: {
                self.view.frame = frame
            })
        }
    }

    @objc func keyBoardWillHide(_ notification:Notification){
        var frame = self.view.frame
        frame.origin.y = 0.0
        DispatchQueue.main.async {
            self.view.frame = frame
        }
        self.originFrame = CGRect.zero
    }
    
    func releaseNotification(){
        NotificationCenter.default.removeObserver(self)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension ADDXWebRTCConfigVC: UITextFieldDelegate{
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        debugPrint(textField)
        self.currentTF = textField
    }
    
}
