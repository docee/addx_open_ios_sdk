//
//  ADVideoSharpDialogCell.swift
//  AddxAi
//
//  Created by kzhi on 2019/9/4.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import Foundation
import UIKit
import A4xBaseSDK

class ADVideoSharpDialogCell : UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.clear
        self.selectionStyle = .none
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var title : String? {
        didSet {
            self.titleLabel.text = self.title
        }
    }
    
    private lazy
    var titleLabel : UILabel = {
        let temp = UILabel()
        temp.font = UIFont.systemFont(ofSize: 15)
        temp.textAlignment = .center
        temp.backgroundColor = UIColor.clear
        temp.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        self.contentView.addSubview(temp)
        temp.snp.makeConstraints({ (make) in
            make.center.equalTo(self.contentView.snp.center)
        })
        return temp
    }()
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            self.titleLabel.textColor = ADTheme.Theme
        }else {
            self.titleLabel.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        }
    }
}
