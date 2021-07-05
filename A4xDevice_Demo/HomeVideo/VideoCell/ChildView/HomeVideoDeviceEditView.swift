//
//  HomeVIdeoDeviceEditView.swift
//  AddxAi
//
//  Created by kzhi on 2019/11/21.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import Foundation
import UIKit
import A4xBaseSDK

protocol HomeVideoDeviceEditViewProtocol : class {
    func deviceLocationClose(ofView : HomeVideoDeviceEditView )
    func deviceLocationEdit (ofView : HomeVideoDeviceEditView , type : ADHomeVideoPresetTypeModle)
    func deviceLocationClick(ofView : HomeVideoDeviceEditView , location : ADPresetModel? , type : HomeVideoPresetCellType)
}

class HomeVideoDeviceEditView: UIView {
    var videoRatio : CGFloat = 1.8
    weak var `protocol` : HomeVideoDeviceEditViewProtocol? = nil
    var isAdmin : Bool = false
    var presetListData : [ADPresetModel]?{
        didSet {
            _presetListData = presetListData
            if editEnable {
                let temp : [ADPresetModel] = _presetListData ?? []
                if temp.count < 5 {
                    var modle = ADPresetModel()
                    modle.id = -1
                    if temp.count > 0 {
                        _presetListData?.append(modle)
                    } else {
                        _presetListData?.insert(modle, at: 0)
                    }
                }
            }
            
            self.collectView.reloadData()
            if (_presetListData?.count ?? 0) > 0 || self.isAdmin {
                self.collectView.hiddNoDataView()
            } else {
                var value = ADNoDataValue()
                value.error = R.string.localizable.no_position()
                value.image = R.image.no_move_location()
                value.retry = false
               let nodatav = self.collectView.showNoDataView(value: value)
                nodatav?.imageMaxSize = 70
            }
     
        }
    }
    
    var _presetListData : [ADPresetModel]?
    
    var tableViewDataSource : [ADPresetModel] {
//        if editEnable {
//            var temp : [ADPresetModel] = _presetListData ?? []
//            if temp.count == 0 {
//                var modle = ADPresetModel()
//                modle.id = -1
//                temp.insert(modle, at: 0)
//                return temp
//            }
//        }
        return _presetListData ?? []
    }
    

    var itemActionBlock : ((ADPresetModel? , HomeVideoPresetCellType)->Void)?
    
    var colseVideoBlock : (()->Void)?
    var editModleBlock : ((ADHomeVideoPresetTypeModle)->Void)?
    
    var editEnable : Bool = false {
        didSet {
            // 切换语言更新
            self.editBtn.normailTitle = R.string.localizable.delete()
            self.editBtn.selectTitle = R.string.localizable.done()
            self.closeBtn.normailTitle = R.string.localizable.close()
            self.editBtn.isHidden = !editEnable
        }
    }
    
    var editModle : Bool = false {
        didSet {
            A4xLog("---------> presetListData editModle")
            self.collectView.reloadData()
            editBtn.isSelected = editModle
        }
    }
    
    
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.editBtn.isHidden = false
        self.closeBtn.isHidden = false
        self.collectView.isHidden = false
        self.backgroundColor = UIColor.white
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy
    var editBtn : A4xBaseImageTextButton = {
        let temp = A4xBaseImageTextButton()
        temp.normailImage = R.image.edit_location_delete()
        temp.selectimage = R.image.edit_location_done()
        temp.normailTitle = R.string.localizable.delete()
        temp.selectTitle = R.string.localizable.done()
        temp.addTarget(self, action: #selector(editButtonAction(sender:)), for: .touchUpInside)
        self.addSubview(temp)
        
        temp.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 44.auto(), height: 64.auto()))
            make.left.equalTo(15.auto())
            make.top.equalTo(2.auto())
        }
        
        return temp
    }()
    
    private lazy
    var closeBtn : A4xBaseImageTextButton = {
        let temp = A4xBaseImageTextButton()
        temp.normailTitle = R.string.localizable.close()
        temp.normailImage = R.image.home_device_preset_close()
        temp.addTarget(self, action: #selector(closeButtonAction), for: .touchUpInside)
        self.addSubview(temp)
        
        temp.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 44.auto(), height: 64.auto()))
            make.right.equalTo(self.snp.right).offset(-15.auto())
            make.top.equalTo(2.auto())
        }
        
        return temp
    }()
    
    lazy var collectView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 6.auto()
        layout.itemSize = CGSize(width: 97.auto(), height: 77.auto())
        
        let temp = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        temp.dataSource = self
        temp.delegate = self
        temp.showsHorizontalScrollIndicator = false
        temp.backgroundColor = UIColor.clear
        
        
        temp.register(HomeVideoPresetCell.self, forCellWithReuseIdentifier: "HomeVideoPresetCell")
        self.addSubview(temp)
        temp.snp.makeConstraints({ (make) in
            make.top.equalTo(self.editBtn.snp.bottom).offset(15.auto())
            make.centerX.equalTo(self.snp.centerX)
            make.width.equalTo(self.snp.width).offset(-30)
            make.bottom.equalTo(self.snp.bottom).offset(-10)
        })
        
        return temp
    }()
    
    @objc private
    func editButtonAction(sender : UIButton){
        sender.isSelected = !sender.isSelected
        editModle = sender.isSelected
        self.editModleBlock?(editModle ? .delete : .edit)
        self.protocol?.deviceLocationEdit(ofView: self, type: editModle ? .delete : .edit)
    }
    
    @objc private
    func closeButtonAction(){
        editBtn.isSelected = false
        editModle = false
        self.colseVideoBlock?()
        self.protocol?.deviceLocationClose(ofView: self)
    }
}


extension HomeVideoDeviceEditView : UICollectionViewDataSource , UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tableViewDataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HomeVideoPresetCell", for: indexPath)
        let modleData = tableViewDataSource[indexPath.row]
        if let c : HomeVideoPresetCell = cell as? HomeVideoPresetCell {
            if modleData.id == -1 {
                c.type = .add
                c.imageUrl = nil
                c.title = R.string.localizable.pre_position_add()
            } else {
                if editModle {
                    c.type = .delete
                }else {
                    c.type = .none
                }
                c.imageUrl = modleData.imageUrl
                c.title = modleData.name
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let modleData = tableViewDataSource[indexPath.row]
        if editModle {
            if modleData.id == -1  {
                self.itemActionBlock?(nil , .add)
                self.protocol?.deviceLocationClick(ofView: self, location: nil, type: .add)
                return
            }
            //_presetListData?.remove(at: indexPath.row - 1)
            _presetListData?.remove(at: indexPath.row)
            self.collectView.deleteItems(at: [indexPath])
            self.itemActionBlock?(modleData ,.delete )
            self.protocol?.deviceLocationClick(ofView: self, location: modleData, type: .delete)

        }else {
            if modleData.id == -1 {
                self.itemActionBlock?(nil , .add)
                self.protocol?.deviceLocationClick(ofView: self, location: nil, type: .add)
            } else {
                self.itemActionBlock?(modleData ,  .none)
                self.protocol?.deviceLocationClick(ofView: self, location: modleData, type: .none)
            }
        }
        
    }
    
}
