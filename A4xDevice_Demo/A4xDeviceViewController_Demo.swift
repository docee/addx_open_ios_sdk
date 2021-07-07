//
//  A4xDeviceViewController_Demo.swift
//  A4xBaseSDK_Demo
//
//  Created by addx-wjin on 2021/6/30.
//

import UIKit
import A4xBaseSDK
import A4xBindSDK
import A4xWebRTCSDK

class A4xDeviceViewController_Demo: A4xBaseViewController, UITableViewDataSource, UITableViewDelegate  {
    
    var dataSource: [A4xDeviceModel]? {
        didSet {
            tableView.reloadData()
        }
    }

    lazy var tableView: UITableView = {
        let temp = UITableView()
        if #available(iOS 11.0, *) {
            temp.contentInsetAdjustmentBehavior = .never
        }
        temp.dataSource = self
        temp.delegate = self
        temp.isScrollEnabled = false
        temp.backgroundColor = .clear
        temp.tableFooterView = UIView()
        temp.accessibilityIdentifier = "tableView"
        temp.showsVerticalScrollIndicator = false
        temp.separatorColor = .clear
        temp.sectionHeaderHeight = UITableView.automaticDimension
        temp.rowHeight = UITableView.automaticDimension
        return temp
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .white
        
        self.defaultNav()
        
        setupUI()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getDeviceList()
    }
    
    private func setupUI() {
        
        self.view.addSubview(tableView)
        tableView.backgroundColor = .clear
        tableView.snp.makeConstraints({ (make) in
            make.top.equalTo(self.navView!.snp.bottom)
            make.width.equalToSuperview()
            make.height.equalTo(self.view.height / 2)
            make.centerX.equalToSuperview()
        })
        
    }
    
    // 获取设备列表
    private func getDeviceList() {
        
        A4xBindManager.shared.getDeviceList { (code, list) in
            debugPrint("---------> getDeviceList code: \(code ?? -1)")
            if code == 0 {
                self.dataSource = list
            } else {
                debugPrint("---------> getDeviceList error code: \(code ?? -1)")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.auto()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "identifier"
        var tableCell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: identifier)
        tableCell?.selectionStyle = .none
        if (tableCell == nil) {
            tableCell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: identifier);
        }
        
        tableCell?.textLabel?.text = dataSource![indexPath.row].name ?? ""
        tableCell?.textLabel?.snp.makeConstraints({ (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(tableCell!.contentView.snp.left).offset(16.auto())
        })
        
        tableCell?.imageView?.image = thumbImage(deviceID: dataSource![indexPath.row].id ?? "")
        tableCell?.imageView?.snp.makeConstraints({ (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(tableCell!.contentView.snp.right).offset(-16.auto())
            make.size.equalTo(CGSize.init(width: 80.auto(), height: 40.auto()))
        })
        return tableCell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = A4xPlayerViewController_Demo()
        vc.deviceId = self.dataSource?[indexPath.row].id
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    //设置哪些行可以编辑
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
      
    // 设置单元格的编辑的样式
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle.delete
    }
    
    //设置点击删除之后的操作
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            let model = self.dataSource?[indexPath.row]
            
            // 解绑设备
            A4xBindManager.shared.removeDevice(by: model?.id ?? "") { (code, msg) in
                if code == 0 {
                    self.dataSource?.remove(at: indexPath.row)
                    tableView.reloadData()
                } else {
                    
                }
            }
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
}

// MARK: - UITableViewDataSource,UITableViewDelegate
extension A4xDeviceViewController_Demo{
    
    
}
