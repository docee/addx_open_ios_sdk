//
//  RandomData.swift
//  A4xBaseExtensionKit
//
//  Created by zhi kuiyu on 2019/1/28.
//

import Foundation
import UIKit

class Test{
    
}

public extension String{
    static func kRandom(_ count: Int = 5, _ isLetter: Bool = false) -> String {
        let ch = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        var ranStr = ""
        for _ in 0..<count {
            let index = Int(arc4random_uniform(UInt32(ch.count)))
            ranStr.append(ch[ch.index(ch.startIndex, offsetBy: index)])
        }
        return ranStr
    }
    
    static func kRandom(Words words: Int = 2 , isCap : Bool = true) -> String {

        let frameworkBundle : Bundle = Bundle(for: Test.self)
        let url = frameworkBundle.url(forResource: "A4xBaseExtensionKit", withExtension: "bundle")
        let bundle = Bundle(url: url!)

        let text : String? = try? String(contentsOfFile: bundle!.path(forResource: "words", ofType: "txt")!)

        let array  = text?.split(separator: "\n")
        
        var resultString : String? = ""
        
        for _ in (0 ..< words) {
            let rs:String = String(array?[Int.kRandom(min: 0, max: array!.count - 1)] ?? "error")
            resultString?.append(isCap ? rs.capitalized : rs)
            resultString?.append(" ")
        }
        
        return resultString!
    }
}

public extension Int {
    static func kRandom ( min : Int = 0 , max : Int = 1000) -> Int {
        let sum : Int =  max - min + 1 ;
        let randomNumber:Int = Int(arc4random()) % sum + min
        return randomNumber;
    }
}

public extension Float {
    static func kRandom(lower: Float = 0, _ upper: Float = 100) -> Float {
        return (Float(arc4random()) / 0xFFFFFFFF) * (upper - lower) + lower
    }
}

public extension Double {
    static func kRandom(lower: Double = 0, _ upper: Double = 100) -> Double {
        return (Double(arc4random()) / 0xFFFFFFFF) * (upper - lower) + lower
    }
 
}

public extension CGFloat {
    /// SwiftRandom extension
    static func kRandom(lower: CGFloat = 0, _ upper: CGFloat = 1) -> CGFloat {
        return CGFloat(Float(arc4random()) / Float(UINT32_MAX)) * (upper - lower) + lower
    }
}


public extension NSDate {
   
    /// SwiftRandom extension
    static func kRandom() -> Date {
        let randomTime = TimeInterval(arc4random_uniform(UInt32.max))
        return Date(timeIntervalSince1970: randomTime)
    }
}


extension UIColor {
    //返回随机颜色
    static func kRandom() -> UIColor {
        let red = CGFloat(arc4random()%256)/255.0
        let green = CGFloat(arc4random()%256)/255.0
        let blue = CGFloat(arc4random()%256)/255.0
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
    
}

public extension Bool {
    static func kRandom() -> Bool {
        return Int.kRandom(min: 0, max: 1) == 0
    }
}

public extension Date {
    static func kRandomDate(minDay : Int = -2 , maxDay : Int = 2) -> Date {
        let time =  Date.kRandomInterval(minDay: minDay, maxDay: maxDay)
        return Date(timeIntervalSince1970: time)
    }
    
    static func kRandomInterval(minDay : Int = -2 , maxDay : Int = 2) -> TimeInterval{
        let timei = Date().timeIntervalSince1970
        let dayTime = 24 * 60 * 60
        let result = timei + Int.kRandom(min: minDay * dayTime , max: maxDay * dayTime).toDouble
        return result
    }
}
