//
//  ADDialogMenuAdapter.swift
//  AddxAi
//
//  Created by zhi kuiyu on 2019/2/11.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import UIKit
import A4xBaseSDK

class ADDialogMenuAdapter: ADDialogAdapterProtocol {
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
        
        let _modle: ADDialogModelProtocol =  dataSources![row]
      
        if  ((_modle as? ADMenuInfoModel) != nil) {
            return ADDialogMenuItem(frame: CGRect.zero);
        }
        return nil;
    }
    
    func loadDataItemForRow(row : Int ,item : ADDialogCell){
        let _modle: ADDialogModelProtocol =  dataSources![row]
        
        if let modle = _modle as? ADMenuInfoModel {
            let modleView : ADDialogMenuItem = item as! ADDialogMenuItem
            modleView.dataModel = modle
        }
    }
    
    func getTypeForRow(row : Int) -> String{
        return dataSources![row].identerType
    }
    
    func getPaddingInset() -> UIEdgeInsets{
        return UIEdgeInsets.zero
    }
    
    func onItemSelect(row: Int, item: ADDialogCell, selected: Bool) {
        if selected {
            let _modle: ADDialogModelProtocol =  dataSources![row]
            self.didSelectBlock?(_modle,item)
        }
    }
    
}
