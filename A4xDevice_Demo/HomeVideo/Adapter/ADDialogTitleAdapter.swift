//
//  ADDialogAdapter.swift
//  AddxAi
//
//  Created by zhi kuiyu on 2019/1/31.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import UIKit
import A4xBaseSDK

class ADDialogTitleAdapter: ADDialogAdapterProtocol {
    var selectCellColor: UIColor?
    
    var didSelectBlock: ((ADDialogModelProtocol, ADDialogCell) -> Void)?
    
    
    private var _dataChangeBlock : (() -> Void)?
    
    var dataSources : Array<ADDialogModelProtocol>?{
        didSet {
            if (_dataChangeBlock == nil){
                _dataChangeBlock!()
            }
        }
    }
    
    var dataChangeBlock: (() -> Void)?{
        set{
            _dataChangeBlock = newValue
        }
        get{
            return _dataChangeBlock;
        }
    }
    
    init() {
        A4xLog("<---- ADDialogTitleAdapter init")
    }
    
    required init(dataSource: [ADDialogModelProtocol]?) {
        self.dataSources = dataSource
        A4xLog("<---- ADDialogTitleAdapter init")
    }
    
    deinit {
        A4xLog("----> ADDialogTitleAdapter deinit")
    }
    
    func ItemCount() -> Int {
        return self.dataSources?.count ?? 0
    }
    
    func createItemForRow(row : Int , isCreate : Bool) -> ADDialogCell?{
        return ADDialogTitleInfoItem(frame: CGRect.zero);
    }
    
    func loadDataItemForRow(row : Int ,item : ADDialogCell){
        let _modle: ADDialogModelProtocol =  dataSources![row]
        
        if let model = _modle as? ADAddressFilterModle {
            let modleView : ADDialogTitleInfoItem = item as! ADDialogTitleInfoItem
            modleView.name = model.showName
            modleView.selectModle =  A4xUserDataHandle.Handle!.locationType == model.filterType
        }
    }
    
    func getTypeForRow(row : Int) -> String{
        return dataSources![row].identerType
    }
    
    func getPaddingInset() -> UIEdgeInsets{
        return UIEdgeInsets.zero
    }
    
    func onItemSelect(row: Int, item: ADDialogCell, selected: Bool) {
        let _modle: ADDialogModelProtocol? =  dataSources![row]
        self.didSelectBlock?(_modle! ,item)
    }
}
