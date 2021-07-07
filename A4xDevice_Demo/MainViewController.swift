//
//  MainViewController.swift
//  A4xBaseSDK_Demo
//
//  Created by addx-wjin on 2021/6/22.
//

import UIKit
import A4xBaseSDK
import A4xBindSDK
import A4xDeviceSetSDK

class MainViewController: UIViewController {
    
    lazy var btn1: UIButton = {
        let btn = UIButton()
        btn.setTitle("绑定设备", for: .normal)
        btn.setTitleColor(UIColor.red, for: .normal)
        return btn
    }()
    
    lazy var btn2: UIButton = {
        let btn = UIButton()
        btn.setTitle("绑定好友分享设备", for: .normal)
        btn.setTitleColor(UIColor.red, for: .normal)
        return btn
    }()
    
    lazy var btn3: UIButton = {
        let btn = UIButton()
        btn.setTitle("查看设备", for: .normal)
        btn.setTitleColor(UIColor.red, for: .normal)
        return btn
    }()
    
    lazy var btn4: UIButton = {
        let btn = UIButton()
        btn.setTitle("相机管理", for: .normal)
        btn.setTitleColor(UIColor.red, for: .normal)
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = .white
        
        self.initA4xBaseSDK_Demo()
       
        self.setupUI()
        
        btn1.addAction { [weak self] (btn) in
            self?.a4xBind_Demo()
        }
        
        btn2.addAction { [weak self] (btn) in
            self?.a4xBindFriend_Demo()
        }
        
        btn3.addAction { [weak self] (btn) in
            self?.a4xDeviceList_Demo()
        }
        
        btn4.addAction { [weak self] (btn) in
            self?.a4xCameraList_Demo()
        }
        
        // 图片、mp3相关资源包
        let bundlePath = Bundle.main.path(forResource: "A4xSDK", ofType: "bundle")
        let hostingBundle = Bundle.init(path: bundlePath!)
        debugPrint("------------> hostingBundle: \(hostingBundle?.bundlePath ?? "")")
    }
    
    func setupUI() {
        
        self.view.addSubview(btn1)
        self.view.addSubview(btn2)
        self.view.addSubview(btn3)
        self.view.addSubview(btn4)
        
        btn1.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.view.snp.centerY).offset(-160.auto())
            make.size.equalTo(CGSize.init(width: 200.auto(), height: 50.auto()))
        }
        
        btn2.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(btn1.snp.bottom).offset(16.auto())
            make.size.equalTo(CGSize.init(width: 200.auto(), height: 50.auto()))
        }
        
        btn3.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(btn2.snp.bottom).offset(16.auto())
            make.size.equalTo(CGSize.init(width: 200.auto(), height: 50.auto()))
        }
        
        btn4.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(btn3.snp.bottom).offset(16.auto())
            make.size.equalTo(CGSize.init(width: 200.auto(), height: 50.auto()))
        }
        
    }
    
    func initA4xBaseSDK_Demo() {
        
        //{"countryNo":"CN","email":"12345djfsk@163.com","language":"zh","phone":"13812345678","tenantId":"netvue","userId":"zyj_test_1624962274"}
        //{"code":0,"message":"Success","data":{"token":"Bearer eyJhbGciOiJIUzUxMiJ9.eyJ0aGlyZFVzZXJJZCI6Inp5al90ZXN0XzE2MjQ5NjIyNzQiLCJhY2NvdW50SWQiOiJ0ZXN0QWNjb3VudF8xODYxMyIsInNlZWQiOiJmYjhhYTEyZDI3OTg0YTFkOWE1YzM5Mzg2MGNkN2FkZiIsImV4cCI6MjYyNDk2MjI3NCwidXNlcklkIjo4NjR9.qPsQkNQg0bxq6wOKffyt1YKRAM1FhMYSE7v227njitNXCU5RwnmKNSIxk140csi_zqOAUkFHML8TQ8i3ggj-IA"}}
        
        let a4xBaseConfig = A4xBaseConfig()
        a4xBaseConfig.appToken = "Bearer eyJhbGciOiJIUzUxMiJ9.eyJ0aGlyZFVzZXJJZCI6Inp5al90ZXN0XzE2MjQ5NjIyNzQiLCJhY2NvdW50SWQiOiJ0ZXN0QWNjb3VudF8xODYxMyIsInNlZWQiOiJmYjhhYTEyZDI3OTg0YTFkOWE1YzM5Mzg2MGNkN2FkZiIsImV4cCI6MjYyNDk2MjI3NCwidXNlcklkIjo4NjR9.qPsQkNQg0bxq6wOKffyt1YKRAM1FhMYSE7v227njitNXCU5RwnmKNSIxk140csi_zqOAUkFHML8TQ8i3ggj-IA"
        a4xBaseConfig.countryNo = "CN"
        a4xBaseConfig.tenantId = "netvue"
        a4xBaseConfig.netEnvironment = .DEV
        a4xBaseConfig.enableDebug = true
        a4xBaseConfig.language = "zh"
        a4xBaseConfig.userId = "zyj_test_1624962274"

        A4xBaseManager.shared.startWithConfig(config: a4xBaseConfig, comple: { (code, msg) in
            debugPrint("---------> code: \(code) msg: \(msg)")
        })
    }
    
    // 绑定
    func a4xBind_Demo() {
        let bindConfig = A4xBindConfig()
        // 设置跳转ViewController
        bindConfig.a4xBindJumpVCName = "MainViewController"
        A4xBindManager.shared.setBindConfig(by: bindConfig)
        let vc = A4xBindRootViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func a4xBindFriend_Demo() {
        let vc = A4xBindManager.shared.addFriendDeviceVC() ?? A4xBindRootViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // 查看已绑定设备
    func a4xDeviceList_Demo() {
        let vc = A4xDeviceViewController_Demo()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    /**
     * 修改相机设置
     * 1.需要 import A4xDeviceSetSDK
     * 2.获取到所有的相机设备 A4xBindManager.shared.getDeviceList
     * 3.进去设置页面 push to A4xDeviceSetSettingViewController().deviceId
     */
    func a4xCameraList_Demo() {
        let vc = A4xDeviceSetViewController_Demo()
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

