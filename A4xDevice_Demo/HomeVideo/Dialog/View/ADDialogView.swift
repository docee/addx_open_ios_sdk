//
//  ADDialogHomeTitleView.swift
//  AddxAi
//
//  Created by zhi kuiyu on 2019/1/31.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import UIKit
import A4xBaseSDK


enum ADShareArrow {
    case left
    case right
    case center
}


class ADShareView : UIView {
    static let shareViewHeight : Float = 0
    var colors : [CGColor]? {
        didSet {
            if let layer : CAGradientLayer = self.layer as? CAGradientLayer{
                layer.colors = colors
            }
        }
    }
    
    func setColors(values : (UIColor , Double) ... , top : ADShareArrow = .center , bottom : ADShareArrow = .center){
        if let layer : CAGradientLayer = self.layer as? CAGradientLayer{
            var colors : [CGColor] = []
            var locations : [NSNumber] = []
            
            values.forEach { (color, location) in
                colors.append(color.cgColor)
                locations.append(NSNumber(value: location))
            }
            layer.colors = colors
            layer.locations = locations

            var startPoints : CGPoint
            switch top {
            case .left:
                startPoints = CGPoint(x: 0, y: 0)
            case .right:
                startPoints = CGPoint(x: 1, y: 0)
            case .center:
                startPoints = CGPoint(x: 0.5, y: 0)
            }
            
            var endPoints : CGPoint
            switch bottom {
            case .left:
                endPoints = CGPoint(x: 0, y: 1)
            case .right:
                endPoints = CGPoint(x: 1, y: 1)
            case .center:
                endPoints = CGPoint(x: 0.5, y: 1)
            }
            
            layer.startPoint = startPoints
            layer.endPoint = endPoints
        }
        
    }
    
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
}


class ADDialogView : UIView , ADDialogListProtocol ,UITableViewDelegate , UITableViewDataSource {
    var maxHeight : CGFloat = 300
    private var currentHeight : CGFloat = -1
    private var maskLayer : CAShapeLayer?
    private var viewRadio : CGFloat = 0
    private var radioStyle : UIRectCorner?

    var adapter : ADDialogAdapterProtocol?{
        didSet{
            self.reloadData()
            adapter?.dataChangeBlock = {
                self.tableView.reloadData()
            }
        }
    }
    
    override init(frame: CGRect = CGRect.zero) {
        A4xLog("<----  ADDialogView init")
        
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        self.tableView.isHidden = false
        self.tableView.addObserver(self, forKeyPath: "contentSize", options: [], context: nil)
        
        self.topSharelay.isHidden = false
    }
    
    
    func setRadio(radio : CGFloat , style : UIRectCorner){
        if radio == 0 {
            return
        }
        self.viewRadio = radio
        self.radioStyle = style
        self.maskLayer = CAShapeLayer()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if self.maskLayer != nil {
            self.maskLayer?.frame = self.bounds
        }
        let size = CGSize(width: self.viewRadio, height: self.viewRadio)
        let maskPath = UIBezierPath(roundedRect: self.maskLayer!.bounds, byRoundingCorners: self.radioStyle!, cornerRadii: size)
        self.maskLayer?.path = maskPath.cgPath
        self.layer.mask = self.maskLayer
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let  ctheight : CGFloat = tableView.contentSize.height + CGFloat(ADShareView.shareViewHeight)
        if (currentHeight == ctheight){
            return
        }
        currentHeight = ctheight;
        weak var weakSelf = self
        self.snp.updateConstraints { (make) in
            make.height.equalTo(min(weakSelf!.maxHeight, currentHeight))
        }
        let ise = self.maxHeight > currentHeight
        self.tableView.isScrollEnabled = !ise
    }
    
    deinit{
        self.tableView.removeObserver(self, forKeyPath: "contentSize")
        A4xLog("---->  ADDialogView deinit")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var topSharelay : ADShareView = {
        let temp = ADShareView()
        temp.backgroundColor = UIColor.white
        self.addSubview(temp)
        temp.colors = [ADTheme.C5.withAlphaComponent(0.1).cgColor , UIColor.clear.cgColor]

        temp.snp.makeConstraints({ (make) in
            make.top.equalTo(self.snp.top);
            make.left.equalTo(self.snp.left);
            make.right.equalTo(self.snp.right);
            make.height.equalTo(CGFloat(ADShareView.shareViewHeight))
        })
        return temp
    }()
    
    lazy var tableView : UITableView = {
        let temp = UITableView(frame: CGRect.zero, style: UITableView.Style.plain);
        temp.delegate = self
        temp.dataSource = self
        temp.showsVerticalScrollIndicator = false
        temp.backgroundColor = UIColor.clear
        temp.separatorColor = ADTheme.C5
        temp.estimatedRowHeight = 48.auto();
        temp.rowHeight=UITableView.automaticDimension;
        temp.tableFooterView = UIView()
        self.addSubview(temp)
        temp.separatorInset = .zero

     
        temp.snp.makeConstraints({ (make) in
            make.top.equalTo(CGFloat(ADShareView.shareViewHeight));
            make.left.equalTo(self.snp.left);
            make.right.equalTo(self.snp.right);
            make.bottom.equalTo(self.snp.bottom)
        })
        return temp
    }()
    
    
    private func reloadData(){
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return adapter?.ItemCount() ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier : String = adapter?.getTypeForRow(row: indexPath.row) ?? "default"
        var tableCell = tableView.dequeueReusableCell(withIdentifier: identifier)
        if (tableCell == nil){
            tableCell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: identifier);
            tableCell?.selectedBackgroundView = UIView()
//            tableCell?.selectedBackgroundView?.backgroundColor = self.adapter?.selectCellColor
            let childView : ADDialogCell? =  adapter?.createItemForRow(row: indexPath.row, isCreate: true)
            
            if childView != nil {
                childView!.tag = 1000
                childView?.selectColor = self.adapter?.selectCellColor
                tableCell?.addSubview(childView!)
                
                childView?.snp.makeConstraints({ (make) in
                    make.edges.equalTo(tableCell?.snp.edges ?? 0)
                })
            }
        }
        
        let childView = tableCell?.viewWithTag(1000)
        if (childView != nil && childView is ADDialogCell){
            let temp = childView as! ADDialogCell
            adapter?.loadDataItemForRow(row: indexPath.row, item: temp)
        }
        return tableCell!;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tableCell : UITableViewCell? = tableView.cellForRow(at: indexPath)
        let childView = tableCell?.viewWithTag(1000)
        
        if (childView is ADDialogCell){
            let temp = childView as! ADDialogCell
            temp.isSelected = true
            adapter?.onItemSelect(row: indexPath.row, item: temp, selected: true)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let count = adapter?.ItemCount() ?? 0
        if count == indexPath.row + 1 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: cell.width, bottom: 0, right: 0)
        }else {
            cell.separatorInset = .zero
        }
        cell.layoutMargins = .zero
        cell.preservesSuperviewLayoutMargins = false
    }
    
//    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
//        let tableCell : UITableViewCell? = tableView.cellForRow(at: indexPath)
//        let childView = tableCell?.viewWithTag(1000)
//
//        if (childView is ADDialogCell){
//            let temp = childView as! ADDialogCell
//            temp.isSelected = false
//        }
//    }

}
