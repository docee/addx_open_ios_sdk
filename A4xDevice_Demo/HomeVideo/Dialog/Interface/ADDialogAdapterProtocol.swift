//
//  ADDialogAdapterProtocol.swift
//  AddxAi
//
//  Created by zhi kuiyu on 2019/1/31.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import Foundation
import UIKit


class ADDialogCell : UIView , ADDialogCellProtocol {
    var isSelected: Bool?
    var selectColor : UIColor? 
}

protocol ADDialogAdapterProtocol {
    var dataChangeBlock: (() -> Void)?{
        set get
    }
    var didSelectBlock: ((_ model : ADDialogModelProtocol , _ cell : ADDialogCell) -> Void)?{
        set get
    }
    var selectCellColor : UIColor? {
        set get
    }

    init(dataSource: [ADDialogModelProtocol]?)
    func ItemCount() -> Int;
    func createItemForRow(row : Int , isCreate : Bool) -> ADDialogCell?;
    func loadDataItemForRow(row : Int ,item : ADDialogCell);
    func getTypeForRow(row : Int) -> String
    func getPaddingInset() -> UIEdgeInsets;
    func onItemSelect(row : Int ,item : ADDialogCell , selected : Bool);
}

