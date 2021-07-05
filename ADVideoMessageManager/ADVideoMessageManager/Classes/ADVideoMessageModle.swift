//
//  ADVideoMessageModle.swift
//  ADVideoMessageManager
//
//  Created by kzhi on 2020/12/9.
//

import Foundation
//{
//  "id": 2924129,
//  "videoUrl": "videoURl",
//  "timestamp": 1607915072,
//  "serialNumber": "7819097212940196d6076162ef2e5d2d",
//  "imageUrl": "https:imageURl",
//  "deviceName": "Vicoo智能摄像机",
//  "adminName": "Jason",
//  "pushInfo": "发现有人"
//}
public struct ADVideoMessageModel: Codable {
    public var id : Int? //资源id
    public var missing : Int? //资源读取
    public var mark : Int? //资源读取
    public var type : Int? //资源类型
    public var from : Int? //资源类型
    public var time : TimeInterval? //时间
    public var cName : String? //设备名称
    public var cID : String? //设备id
    public var date : String?//截屏
    public var image : String?//截屏
    public var source : String?
    public var tags : String?
    public var managerName : String?
    public var period : Float?
    public var locationId : Int?
    public var locationName : String?
    public var videoURL : URL?
    public var adminId : Int64?
    public var pushInfo : String?
    public var traceId : String?
    public var fileSize: Int?
    public var eventInfoList: [String]?
    public var deviceTitle: String?
  
    enum CodingKeys: String, CodingKey {
        case id   //资源id
        case missing //资源读取
        case mark = "marked"//资源读取
        case time = "timestamp"   //时间
        case cName = "deviceName" //设备名称
        case cID = "serialNumber"     //设备id
        case image = "imageUrl"   //缩略图
        case source = "videoUrl"  //视频url
        case date
        case managerName = "adminName"
        case period
        case locationId
        case locationName
        case adminId
        case tags
        case pushInfo
        case eventInfoList
        case fileSize
        case traceId
        case deviceTitle //设备名称 带区域
    }
}
