//
//  NSString+Helper.swift
//  SwiftTemplet
//
//  Created by hsf on 2018/8/28.
//  Copyright © 2018年 BN. All rights reserved.
//

import UIKit

public extension String{
    
    func valid() -> Bool! {
        let array = ["","nil","null"];
        if array.contains(self){
            return false;
        }
        return true;
    }
    
    func width(font : UIFont = UIFont.systemFont(ofSize: 14) , wordSpace : CGFloat = 0) -> CGFloat {
        if self.count == 0 {
            return 0
        }
        var attributes :  [NSAttributedString.Key : Any] = Dictionary()
        if wordSpace > 0 {
            attributes[NSAttributedString.Key.kern] = wordSpace
        }
       
        attributes[NSAttributedString.Key.font] = font

        let attrString = NSAttributedString(string: self, attributes: attributes)
        let bounds = attrString.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 0), options: .usesLineFragmentOrigin, context: nil)
        return bounds.width
    }
    
    func height(maxWidth : CGFloat , font : UIFont = UIFont.systemFont(ofSize: 14) , lineSpacing : CGFloat = 0 , wordSpace : CGFloat = 0) -> CGFloat {
        return self.size(maxWidth: maxWidth, font: font, lineSpacing: lineSpacing, wordSpace: wordSpace).height
    }
    
    func size(maxWidth : CGFloat , font : UIFont = UIFont.systemFont(ofSize: 14) , lineSpacing : CGFloat = 0 , wordSpace : CGFloat = 0) -> CGSize {
        if self.count == 0 {
            return CGSize.zero
        }
        
        var attributes :  [NSAttributedString.Key : Any] = Dictionary()
        if wordSpace > 0 {
            attributes[NSAttributedString.Key.kern] = wordSpace
        }
        
        if lineSpacing > 0 {
            let paragraphStyle:NSMutableParagraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = lineSpacing
            paragraphStyle.lineBreakMode = .byWordWrapping
            attributes[NSAttributedString.Key.paragraphStyle] = paragraphStyle
        }
        attributes[NSAttributedString.Key.font] = font
        
        let attrString = NSAttributedString(string: self, attributes: attributes)
        let bounds = attrString.boundingRect(with: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude), options: .usesFontLeading, context: nil)
        return bounds.size
    }
    
    func intValue() -> Int {
        return Int((self as NSString).intValue)
    }

    func floatValue() -> Float {
        return (self as NSString).floatValue
    }
    
    func cgFloatValue() -> CGFloat {
        return CGFloat(self.floatValue())
    }

    func doubleValue() -> Double {
        return (self as NSString).doubleValue
    }
    
    func reverse() -> String {
        return String(self.reversed())
    }
    /// range转换为NSRange
    func nsRange(from range: Range<String.Index>) -> NSRange {
        return NSRange(range, in: self)
    }
    
    /// NSRange转化为range
    func range(from nsRange: NSRange) -> Range<String.Index>? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(from16, offsetBy: nsRange.length, limitedBy: utf16.endIndex),
            let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self)
            else { return nil }
        return from ..< to
    }
    
    func dictValue() -> Dictionary<String, Any>!{
        return ((self as NSString).objcValue() as! Dictionary<String, Any>)
    }
    
    func arrayValue() -> Array<Any>!{
        
        let jsonData:Data = self.data(using: .utf8)!
        let array = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
        if array != nil {
            return (array as! Array);
        }
        return Array();
    }
    
    func jsonFileToJSONString() -> String {
        assert(self.contains(".geojson") == true);
        
        if self.contains(".geojson") == true {
            let array: Array = self.components(separatedBy: ".");
            let path = Bundle.main.path(forResource: array.first, ofType: array.last);
            if path == nil {
                return "";
            }
            if let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path!)) {
                
                if let jsonObj = try? JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions(rawValue: 0)) {
                    let jsonString = ((jsonObj as! NSDictionary).jsonValue()!).removingPercentEncoding!;
                    print(jsonString);
                    return jsonString;
                }
                return "";
            }
            return "";
        }
        return "";
    }
    
    static func timeNow() -> String {
        let fmt = DateFormatter.format(kDateFormat)
        let dateStr = fmt.string(from: Date());
        return dateStr;
        
    }
    
    func toTimeStamp() -> String {
        let dateStr = self;
        
        var fmtStr = kDateFormat;
        if dateStr.contains("-") && dateStr.contains(":") {
            fmtStr = kDateFormat;
            
        }
        else if dateStr.contains("-") && !dateStr.contains(":") {
            fmtStr = kDateFormat_one;
            
        }
        else if !dateStr.contains("-") && !dateStr.contains(":") {
            fmtStr = kDateFormat_two;
            
        }
       
        
        let fmt = DateFormatter.format(fmtStr);
        let date = fmt.date(from: dateStr);
        
        let intervl:Double = (date?.timeIntervalSince1970)!;
        let doubleInt = Int(intervl);
        let timeStamp = String(doubleInt);
        return timeStamp;
    }
    
    
    /// 字符串本身大于string
    func isCompareMore(_ string:String) -> Bool {
        return self.compare(string, options: .numeric, range: nil, locale: nil) == .orderedDescending
    }
    
    /// 字符串本身大于string
    func isCompare(_ string:String) -> Bool {
        if self == "" {
            return false
        }
        
        var strSelf = self
        if strSelf.contains(".") {
            strSelf = strSelf.replacingOccurrences(of: ".", with: "")
        }
        return strSelf.intValue() > string.intValue()
    }
    
    func trim() -> String{
        return self.trimmingCharacters(in: .whitespaces)
    }
}

extension NSString{
    
    /// 字符串转AnyObject
     @objc public func objcValue() -> AnyObject?{
        let jsonData = self.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: true)
        let obj:Any? = try? JSONSerialization.jsonObject(with: jsonData!, options: .allowFragments)
        if obj != nil {
            return obj! as AnyObject;
        }
        return self;
    }
    
    /// 字符串本身大于string
    public func isCompare(_ string:NSString) -> Bool {
        if self.isEqual(to: "") {
            return false
        }
        
        var strSelf = self
        if strSelf.contains(".") {
            strSelf = strSelf.replacingOccurrences(of: ".", with: "") as NSString
        }
        return strSelf.integerValue > string.integerValue;
    }
    
    
}


extension String {

    var containsEmoji: Bool {
        for c in self {
            if c.emoji {
                return true
            }
        }
        return false
    }

    var noEmojiString : String {
        var string : String = "";
        for c in self {
            if !c.emoji {
                string.append(c)
            }
        }
        return string
    }
    
    public var cLength : Int {
        var count : Int = 0
        for char in self {
            let lentthOfChar = "\(char)".lengthOfBytes(using: .utf8)
            // 英文
            if lentthOfChar == 1 {
                count = count + 1
            }// 中文
            else if lentthOfChar == 3 {
                count = count + 2
            }
        }
        return count
    }
    
    public func subCLength(length : Int) -> String {
        var string : String = ""
        var count : Int = 0
        for char in self {
            let lentthOfChar = "\(char)".lengthOfBytes(using: .utf8)
            // 英文
            if lentthOfChar == 1 {
                count = count + 1
            }// 中文
            else if lentthOfChar == 3 {
                count = count + 2
            }
            if count <= length {
                string.append(char)
            }
        }
        return string
    }
    
    
    func filterDoubleByte() -> String {
        let pattern = "[^\\x00-\\xff]"
        let regex = try! NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.dotMatchesLineSeparators)
        let modString = regex.stringByReplacingMatches(in: self, options: [], range: NSRange(location: 0, length: self.count), withTemplate: "")
        
        return modString
    }
}

extension Character {
    var emoji : Bool {
        for scalar in unicodeScalars {
            switch scalar.value {
            case 0x1F600...0x1F64F, // Emoticons
                 0x1F300...0x1F5FF, // Misc Symbols and Pictographs
                 0x1F680...0x1F6FF, // Transport and Map
                 0x2600...0x26FF,   // Misc symbols
                 0x2700...0x27BF,   // Dingbats
                 0xFE00...0xFE0F,   // Variation Selectors
                 0x1F900...0x1F9FF, // Supplemental Symbols and Pictographs
                 0x1F1E6...0x1F1FF: // Flags
                return true
            default:
                continue
            }
        }
        return false
    }
}
