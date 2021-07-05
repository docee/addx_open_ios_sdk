//
//  ADVideoSharpDialog.swift
//  AddxAi
//
//  Created by kzhi on 2019/9/4.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import UIKit
import A4xWebRTCSDK
import A4xBaseSDK

class ADVideoSharpDialog : UIView {
    
    var selectDataBlock : ((A4xVideoSharpType)->Void)?
    
    var dataSouces : [A4xVideoSharpType] = [] {
        didSet {
            self.tableView.reloadData()
            if self.selectData == nil {
                self.selectData = .standard
            }
        }
    }
    
    private
    var _selectData : A4xVideoSharpType?
    
    var selectData : A4xVideoSharpType? {
        set {
            
            _selectData = newValue
            if let sel = _selectData , let index = dataSouces.firstIndex(of: sel) {
                self.tableView.selectRow(at: IndexPath(row: index, section: 0), animated: true, scrollPosition: UITableView.ScrollPosition.none)
            }
        }
        get{
            return _selectData
        }
    }
    
    var bgArrowImage : UIImage? = UIImage(named: "video_sharp_arrow.png")
    var tableViewHeight : CGFloat = 110
    private
    lazy var bgArrawHeight : CGFloat = {
        return self.bgArrowImage?.size.height ?? 0
    }()
    
    override init(frame: CGRect = CGRect.zero) {
        
        super.init(frame: frame)
        self.tableView.isHidden = false
        self.tableView.addObserver(self, forKeyPath: "contentSize", options: [], context: nil)
       
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    deinit {
        print("ADVideoSharpDialog ==> deinit")
        self.tableView.removeObserver(self, forKeyPath: "contentSize")
    }
    
//    override var intrinsicContentSize: CGSize {
//        return CGSize(width: 100, height: bgArrawHeight + tableViewHeight )
//    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let  ctheight : CGFloat = tableView.contentSize.height
   
        self.tableView.frame = CGRect(x: 0, y: (self.height - ctheight) / 2 , width: self.width, height: ctheight)


    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
//        self.layer.anchorPoint = CGPoint(x: 0.5, y: 1)
//        var lastpoint = self.layer.position
//        lastpoint.y += self.frame.size.height / 2
//        self.layer.position = lastpoint
    }
    
    private
    lazy var tableView : UITableView = {
        let temp = UITableView(frame: CGRect.zero, style: UITableView.Style.plain);
        temp.backgroundColor = UIColor.clear
        temp.separatorInset = UIEdgeInsets.zero
        temp.rowHeight=UITableView.automaticDimension;
        temp.estimatedRowHeight = 30;
        temp.accessibilityIdentifier = "tableView"
        temp.separatorColor = UIColor.clear
        temp.delegate = self
        temp.dataSource = self
        self.addSubview(temp)
        return temp
    }()
    
//    override func draw(_ rect: CGRect) {
//        super.draw(rect)
//        if let img = bgArrowImage {
//            let imageSize = img.size
//            img.draw(in: CGRect(x: rect.midX - imageSize.width/2 , y: rect.maxY - imageSize.height, width: imageSize.width, height: imageSize.height))
//        }
//        let draRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.size.width, height: rect.size.height - bgArrawHeight)
//        
//        let path = UIBezierPath.init(roundedRect: draRect, byRoundingCorners: UIRectCorner.allCorners, cornerRadii: CGSize(width: 3, height: 3))
//        UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 0.8).setFill()
//        path.fill()
//    }
    
    
}


extension ADVideoSharpDialog : UITableViewDelegate , UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSouces.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "ADVideoSharpDialogCell") as? ADVideoSharpDialogCell
        if cell == nil {
            cell = ADVideoSharpDialogCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "ADVideoSharpDialogCell")
            
        }
        cell?.title = self.dataSouces[indexPath.row].name()
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currentSelect  = self.dataSouces[indexPath.row]
        if let last = self.selectData {
            if last == currentSelect {
                return
            }
        }
        self.selectData = currentSelect
        DispatchQueue.main.a4xAfter(1) {
            self.selectDataBlock?(currentSelect)
        }
    }
    
}
