//
//  ViewController.swift
//  ADVideoMessageManager
//
//  Created by Kuiyu Zhi on 12/08/2020.
//  Copyright (c) 2020 Kuiyu Zhi. All rights reserved.
//

import UIKit
import SnapKit
import ADVideoMessageManager

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.testBgImageV.isHidden = false
        // Do any additional setup after loading the view, typically from a nib.
        if let wind = UIApplication.shared.delegate?.window as? UIView {
            ADVideoMessageManager.shared.inView = wind
            ADVideoMessageManager.shared.config = ADVideoMessageConfig(loadString: { (typ) -> String in
                switch typ {
                case .messageDateString(time: let time):
                    return "15:23，2020.01.10"
                case .messageCountDestion(count: let count):
                    return String(format: "共有%d条摄像机通知", count)
                }
            })
            
            
        }
        ADVideoMessageManager.shared.config?.messageContentClick = {(type,modle) in
            print(type)
            print(modle)
        }
        ADVideoMessageManager.shared.config?.messageCountClick = {
            print("messageCountClick")
        }
        
        self.perform(#selector(self.newMessage), with: nil, afterDelay: 3)

        
    }
    
    @objc
    func newMessage(){
        ADVideoMessageManager.shared.recordMessage(dict: [:])
        self.perform(#selector(self.newMessage), with: nil, afterDelay: 3)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    lazy var testBgImageV : UIImageView = {
        let temp = UIImageView()
        temp.image = UIImage(named: "demo.jpge")
        self.view.addSubview(temp)
        temp.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view.snp.edges)
            
        }
        
        return temp
    }()
    
}

