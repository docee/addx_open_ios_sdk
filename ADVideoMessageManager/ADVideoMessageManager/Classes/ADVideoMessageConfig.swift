//
//  ADVideoMessageConfig.swift
//  ADVideoMessageManager
//
//  Created by kzhi on 2020/12/9.
//

import Foundation
import UIKit
public enum ADVideoMessageLoctionInView {
    case moveBar
    case content
    case messageNotip
}

public enum ADVideoMessageConfigStringType {
    case messageDateString(time : TimeInterval)
    case messageCountDestion(count : Int)
    case messageNoTipButton
}
public enum ADVideoMessageConfigImageType {
    case messageDateFormat
    case messageCountDestion(count : Int)
}

public enum ADVideoMessageConfigColorType {
    case theme
}

public class ADVideoMessageConfig {
    var loadStringBlock : ((_ type : ADVideoMessageConfigStringType) -> String)
    var loadImageBlock : ((_ type : ADVideoMessageConfigImageType) -> UIImage?)
    var loadColorBlock : ((_ type : ADVideoMessageConfigColorType) -> UIColor?)
    
    internal var enableChangeBlock : (()->Void)?
    
    public var messageContentClick: ((_ type : ADVideoMessageLoctionInView , _ msg : ADVideoMessageModel?)->Void)?
    public var messageCountClick: (()->Void)?

    public var pushShowTime : TimeInterval = 15
    
    public var enable : Bool = true {
        didSet {
            print("ADVideoMessageConfig enable \(enable)")
            enableChangeBlock?()
        }
    }

    public init(loadString : (@escaping (_ type : ADVideoMessageConfigStringType) -> String) , loadImage : (@escaping  (_ type : ADVideoMessageConfigImageType) -> UIImage?) = {_ in return nil} , loadColor : (@escaping  (_ type : ADVideoMessageConfigColorType) -> UIColor?) = {_ in return nil}) {
        self.loadImageBlock = loadImage
        self.loadStringBlock = loadString
        self.loadColorBlock = loadColor
    }
    
}
