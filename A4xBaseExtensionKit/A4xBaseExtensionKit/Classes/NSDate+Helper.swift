//
//  Date+Helper.swift
//  SwiftTemplet
//
//  Created by dev on 2018/12/11.
//  Copyright © 2018年 BN. All rights reserved.
//

import UIKit

public let kDate_minute : Double = 60
public let kDate_hour : Double  = 3600
public let kDate_day : Double   = 86400
public let kDate_week : Double   = 604800
public let kDate_year : Double   = 31556926

public let kDateFormat = "yyyy-MM-dd HH:mm:ss"
public let kDateFormat_one = "yyyyMMdd"
public let kDateFormat_two = "yyyyMMdd"
public let kDateFormat_year_month = "yyyyMM"
public let kDateFormat_three = "yyyy-MM-dd HH:mm"
public let kDateFormat_12 = "a hh:mm"
public let kDateFormat_24 = "HH:mm"//"a HH:mm"
public let kDateFormat_month_DES = "MMM"
public let kDateFormat_month = "MM"

public extension DateFormatter {
    
    static var kyDatalocal : Locale = Locale.current
    
    static func format(_ formatStr:String) -> DateFormatter {
     
        let fmt = DateFormatter()
        fmt.dateFormat = formatStr
        fmt.locale = kyDatalocal
        fmt.timeZone = NSTimeZone.local
        return fmt
    }
    
    static func format(_ date:Date, fmt:String) -> String {
        let formatter = DateFormatter.format(fmt)
        return formatter.string(from: date)
    }
    
    static func format(dateStr:String, fmt:String) -> Date? {
        let fmt = DateFormatter.format(fmt)
        return fmt.date(from: dateStr)
    }
    
    static func format(_ interval:TimeInterval, fmt:String) -> String? {
        let timeInterval: TimeInterval = TimeInterval(interval)
        let date = Date(timeIntervalSince1970: timeInterval)
        return DateFormatter.format(date, fmt: fmt)
    }
    
    static func format(_ interval:String, fmt:String) -> String? {
        return DateFormatter.format(interval.doubleValue(), fmt: fmt)
    }
}


public extension Date {
//    var begin: Date {
//        get {
//            let calendar = Calendar.current
//            var dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self)
//            dateComponents.hour = 0
//            dateComponents.second = 0
//            dateComponents.minute = 0
//            return calendar.date(from: dateComponents) ?? self
//        }
//    }
//    
//    var end: Date {
//        get {
//            let calendar = Calendar.current
//            var dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self)
//            dateComponents.hour = 23
//            dateComponents.second = 59
//            dateComponents.minute = 59
//            return calendar.date(from: dateComponents) ?? self
//        }
//    }
//    
//    var dayBetween: (TimeInterval , TimeInterval) {
//        get {
//            let start : TimeInterval = self.begin.timeIntervalSince1970
//            let end : TimeInterval = self.begin.timeIntervalSince1970 + 24 * 60 * 60
//            return (start , end)
//        }
//    }
//    
//    var monthBetween: (TimeInterval , TimeInterval , Int) {
//        get {
//            let calendar = Calendar.current
//            
//            let rang  = calendar.range(of: .day, in: .month, for: self)
//            let dayCounts = rang?.count ?? 0
//            
//            
//            var dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self)
//            dateComponents.day = 1
//            dateComponents.hour = 0
//            dateComponents.minute = 0
//            dateComponents.second = 0
//            let start = calendar.date(from: dateComponents)?.timeIntervalSince1970 ?? self.timeIntervalSince1970
//            
//            let end = start + Double(dayCounts) * 24 * 60 * 60
//            
//            return (start , end , dateComponents.month ?? 1)
//        }
//    }
//    
//    func string(formatStr: String) -> String {
//        let formatter = DateFormatter.format(formatStr)
//        let dateStr = formatter.string(from: self as Date)
//        return dateStr
//    }
//    
//    func dateBefore(_ interval: TimeInterval) -> Date{
//        let aTimeInterval = self.timeIntervalSinceReferenceDate - interval
//        return Date(timeIntervalSinceReferenceDate: aTimeInterval)
//    }
//    
//    func time12String() -> String {
//        let formatter = DateFormatter.format(kDateFormat_12)
//        return formatter.string(from: self)
//    }
//    
//    func time24String() -> String {
//        let formatter = DateFormatter.format(kDateFormat_24)
//        return formatter.string(from: self)
//    }
//    
//    func dateString() -> String {
//        let formatter = DateFormatter.format(kDateFormat_one)
//        return formatter.string(from: self)
//    }
//    
//    func monthString() -> String {
//        let formatter = DateFormatter.format(kDateFormat_year_month)
//        return formatter.string(from: self)
//    }
//    
//    func dateBefore(_ interval: TimeInterval, fmt:String) -> String{
//        let newDate = self.dateBefore(interval)
//        return newDate.string(formatStr: fmt)
//    }
//    
//    func monthstr() -> String {
//        let formatter = DateFormatter.format(kDateFormat_month_DES)
//        let dateStr = formatter.string(from: self as Date)
//        return dateStr
//    }
//    
//    func monthdes() -> String {
//        let formatter = DateFormatter.format(kDateFormat_month)
//        let dateStr = formatter.string(from: self as Date)
//        return dateStr
//    }
//    
//    func agoInfo() -> String {
//        var interval = Date().timeIntervalSinceNow - self.timeIntervalSinceNow
//
//        var info = "\(Int(interval/kDate_day))" + "天"
//        interval = interval.truncatingRemainder(dividingBy: kDate_day)
//        
//        info += "\(Int(interval/kDate_hour))" + "小时"
//        interval = interval.truncatingRemainder(dividingBy: kDate_hour)
//        
//        info += "\(Int(interval/kDate_minute))" + "分钟"
//        interval = interval.truncatingRemainder(dividingBy: kDate_minute)
//        
//        info += "\(Int(interval))" + "秒之前"
//        
//        return info
//    }
//    
//    func hourInfoBetween(_ date: Date,_ type: Int) -> Double {
//        var diff = self.timeIntervalSinceNow - date.timeIntervalSinceNow
//        switch type {
//            case 1://分钟
//                diff = fabs(diff/60)
//
//            case 2://小时
//                diff = fabs(diff/3600)
//
//            case 3://天
//                diff = fabs(diff/86400)
//
//            default://秒
//                diff = fabs(diff)
//        }
//        return diff
//    }
//    
//    func daysInBetween(_ date: Date) -> Double {
//        return hourInfoBetween(date, 3)
//    }
//    
//    func hoursInBetween(_ date: Date) -> Double {
//        return hourInfoBetween(date, 2)
//    }
//    
//    func minutesInBetween(_ date: Date) -> Double {
//        return hourInfoBetween(date, 1)
//    }
//    
//    func secondsInBetween(_ date: Date) -> Double {
//        return hourInfoBetween(date, 0)
//    }
//    
//    //MARK: - 获取日期各种值
//    //MARK: (年，月，日)
//    func dates() -> (Int , Int , Int) {
//        let calendar = NSCalendar.current
//        let com = calendar.dateComponents([.year,.month,.day], from: self)
//        return (com.year! , com.month! , com.day!)
//    }
//    //MARK: 年
//    func year() -> Int {
//        let calendar = NSCalendar.current
//        let com = calendar.dateComponents([.year,.month,.day], from: self)
//        return com.year!
//    }
//    //MARK: 月
//    func month() -> Int {
//        let calendar = NSCalendar.current
//        let com = calendar.dateComponents([.year,.month,.day], from: self)
//        return com.month!
//        
//    }
//    //MARK: 日
//    func day() -> Int {
//        let calendar = NSCalendar.current
//        let com = calendar.dateComponents([.year,.month,.day], from: self)
//        return com.day!
//    }
//    
//    //MARK: 星期几
//    func weekDay() -> Int {
//        let interval = Int(self.timeIntervalSince1970)
//        let days = Int(interval/86400) // 24*60*60
//        let weekday = ((days + 4)%7+7)%7
//        return weekday == 0 ? 7 : weekday
//    }
//    //MARK: 当月天数
//    func countOfDaysInMonth() -> Int {
//        let calendar = Calendar(identifier:Calendar.Identifier.gregorian)
//        let range = (calendar as NSCalendar?)?.range(of: NSCalendar.Unit.day, in: NSCalendar.Unit.month, for: self)
//        return (range?.length)!
//        
//    }
//    //MARK: 当月第一天是星期几
//    func firstWeekDay() ->Int {
//        //1.Sun. 2.Mon. 3.Thes. 4.Wed. 5.Thur. 6.Fri. 7.Sat.
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM-"
//        formatter.locale = DateFormatter.kyDatalocal
//        formatter.timeZone = NSTimeZone.local
//        
//        let str = "\(formatter.string(from: self))01"
//        formatter.dateFormat = kDateFormat_one
//        let date =  formatter.date(from: str)
//        
//        let calendar = Calendar(identifier:Calendar.Identifier.gregorian)
//        let com = calendar.dateComponents([.weekday], from: date ?? Date())
//
//        return (com.weekday ?? 1) - 1
//    }
//    
//    func getMorningDate() -> Date? {
//        let calendar = Calendar(identifier:Calendar.Identifier.gregorian)
//        let components = calendar.dateComponents([.year,.month,.day], from: self)
//        return calendar.date(from: components)
//    }
//    
//    //MARK: 上个月
//    func beforeMonth() -> Date? {
//        //1.Sun. 2.Mon. 3.Thes. 4.Wed. 5.Thur. 6.Fri. 7.Sat.
//        let calendar = Calendar(identifier:Calendar.Identifier.gregorian)
//        var com : DateComponents = calendar.dateComponents([.year,.month], from: self)
//        com.month = (com.month ?? 1) - 1
//        return calendar.date(from: com)
//    }
//    
//    //MARK: 上个月
//    func nextMonth() -> Date? {
//        //1.Sun. 2.Mon. 3.Thes. 4.Wed. 5.Thur. 6.Fri. 7.Sat.
//        let calendar = Calendar(identifier:Calendar.Identifier.gregorian)
//        var com : DateComponents = calendar.dateComponents([.year,.month], from: self)
//        com.month = (com.month ?? 11) + 1
//        return calendar.date(from: com)
//    }
//    
//    //MARK: - 日期的一些比较
//    //是否是今天
//    func isToday()->Bool {
//        let calendar = NSCalendar.current
//        let com = calendar.dateComponents([.year,.month,.day], from: self)
//        let comNow = calendar.dateComponents([.year,.month,.day], from: Date())
//        return com.year == comNow.year && com.month == comNow.month && com.day == comNow.day
//    }
//    
//    //是否是这个月
//    func isThisMonth()->Bool {
//        let calendar = NSCalendar.current
//        let com = calendar.dateComponents([.year,.month,.day], from: self)
//        let comNow = calendar.dateComponents([.year,.month,.day], from: Date())
//        return com.year == comNow.year && com.month == comNow.month
//    }
// 
//    func updateTime() -> (Bool,String) {
//        let calendar = NSCalendar.current
//        let components: Set<Calendar.Component> = [.year,.month,.day,.hour, .minute]
//        let currentCom = calendar.dateComponents(components, from: self)
//        let todayCom = calendar.dateComponents(components, from: Date())
//
//        var isToday: Bool = false
//        var formatter: DateFormatter?
//        if currentCom.year != todayCom.year {
//            formatter = DateFormatter.format("yyyy-MM-dd hh:mma")
//            isToday = false
//        } else if currentCom.month != todayCom.month {
//            formatter = DateFormatter.format("MM-dd hh:mma")
//            isToday = false
//        } else if currentCom.day != todayCom.day {
//            formatter = DateFormatter.format("MM-dd hh:mma")
//            isToday = false
//        } else {
//            formatter = DateFormatter.format("hh:mma")
//            isToday = true
//        }
//        return (isToday , formatter!.string(from: self))
//    }
}
