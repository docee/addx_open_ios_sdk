//
//  DataChannelConfig.swift
//  WebRTC-Demo
//
//  Created by Hao Shen on 6/4/20.
//  Copyright © 2020 Stas Seldin. All rights reserved.
//

import Foundation

extension Date{
    static func timeStamp() -> String {
        let time = String(Int(Date().timeIntervalSince1970))
        return time
    }
}

class DataChannelRequestResponseModel: NSObject {
    var requestID           : String?
    var returnValue         : String?
    var responseData        : Data?         //utf8
    var resultData          : Data?
}

public class DataChannelRequestModel: NSObject {
    var requestID           : String?
    var connectionID        : String?
    var action              : String?
    var requestData         : Data?         //utf8
    var responseData        : Data?         //utf8
    var response            : DataChannelRequestResponseModel?
    var finishBlock         : ((_ result:ADDXWebRTCRRequestResult) -> ())?
    var ID                  : String?{
        get{
            if requestID != nil && connectionID != nil {
                return requestID! + connectionID!
            }else{
                return nil
            }
        }
    }
    
}

struct BaseRequestParamsModel<ParamType : Codable>:Codable {
    var requestID       : String?
    var connectionID    : String?
    var timeStamp       : Int64?
    var action          : String?
    var size            : String?
    var parameters      : ParamType?
}

struct BaseResponseModel<Result : Codable>:Codable {
    var action          : String?
    var timeStamp       : Int64?
    var returnValue     : Int?
    var data            : Result?
}

//play live
struct StartPlayLiveRequestParamsModel:Codable {
    var requestID : String?
    var connectionID : String?
    var timeStamp    : Int64?
    var action       : String?
    var size         : String?
}

struct StartPlayLiveResponseModel:Codable {
    var requestID : String?
    var connectionID : String?
    var timeStamp    : Int64?
    var returnValue  : Int?
}

struct StopPlayLiveRequestParamsModel:Codable {
    var requestID : String?
    var connectionID : String?
    var timeStamp    : Int64?
    var action       : String?
}

struct StopPlayLiveResponseModel:Codable {
    var requestID : String?
    var connectionID : String?
    var timeStamp    : Int64?
    var returnValue  : Int?
}

//play sd video
struct PlaySDVidoRequestParameters: Codable{
    var startTime: Int64?
}

struct StartPlaySDVideoRequestParamsModel:Codable {
    var requestID : String?
    var connectionID : String?
    var timeStamp    : Int64?
    var action       : String?
    var size         : String?
    var parameters:PlaySDVidoRequestParameters?
}

struct StartPlaySDVideoResponseModel:Codable {
    var requestID : String?
    var connectionID : String?
    var timeStamp    : Int64?
    var returnValue  : Int?
}

struct StopPlaySDVideoRequestParamsModel:Codable {
    var requestID : String?
    var connectionID : String?
    var timeStamp    : Int?
    var action       : String?
}

struct StopPlaySDVideoResponseModel:Codable {
    var requestID : String?
    var connectionID : String?
    var timeStamp    : Int64?
    var returnValue  : Int?
}

//get sd video list
struct GetSDVidoListRequestParameters: Codable{
    var startTime: Int64?
    var stopTime: Int64?
}

struct GetSDVideoListRequestParamsModel:Codable {
    var requestID : String?
    var connectionID : String?
    var timeStamp    : Int64?
    var action       : String?
    var parameters:GetSDVidoListRequestParameters?
    
}

struct GetSDVideoSliceModel: Codable {
    var startTime : Int?
    var endTime : Int?
}

struct GetSDVideoListDataModel: Codable {
    var videoSlices : [GetSDVideoSliceModel]
    var earliestVideoSlice : GetSDVideoSliceModel?
}

struct GetSDVideoListResponseModel: Codable {
    var requestID : String?
    var connectionID : String?
    var timeStamp    : Int64?
    var returnValue  : Int?
    var data:GetSDVideoListDataModel?
}

// setting
struct SetWhiteLightRequestParameters: Codable{
    var value: Int?
}

struct SetWhiteLightRequestParamsModel: Codable {
    var requestID : String?
    var connectionID : String?
    var timeStamp    : Int64?
    var action       : String?
    var parameters:SetWhiteLightRequestParameters?
}

struct SetLiveResolutionRequestParameters: Codable{
    var value: String?
}

struct SetLiveResolutionRequestParamsModel: Codable {
    var requestID : String?
    var connectionID : String?
    var timeStamp    : Int64?
    var action       : String?
    var parameters:SetLiveResolutionRequestParameters?
}

struct TriggerAlarmnRequestParamsModel: Codable {
    var requestID : String?
    var connectionID : String?
    var timeStamp    : Int64?
    var action       : String?
}
struct SetingResponseModel:Codable {
    var requestID : String?
    var connectionID : String?
    var timeStamp    : Int64?
    var returnValue  : Int?
}

//get status
struct GetStatusRequestParamsModel:Codable {
    var requestID : String?
    var connectionID : String?
    var timeStamp    : Int64?
    var action       : String?
}

struct GetStatusDataModel: Codable {
    var whiteLight : Int?
    var liveResolution : String?
}

struct GetStatusResponseModel: Codable {
    var requestID : String?
    var connectionID : String?
    var timeStamp    : Int64?
    var returnValue  : Int?
    var data         : GetStatusDataModel?
}

struct ParameResponseModel: Codable {
    var requestID       : String?
    var connectionID    : String?
    var timeStamp       : Int64?
    var returnValue     : Int?
}

struct ParameRequestModel: Codable {
    var requestID       : String?
    var connectionID    : String?
    var timeStamp       : Int64?
    var action          : String?
}

struct ReplaySeekRequestParamModel: Codable {
    var seekTime    : Int64?

}

struct ReplaySeekRequestModel:Codable {
    var action          : String?
    var timeStamp       : Int64?
    var parameters      : ReplaySeekRequestParamModel?
}

struct ReplaySeekResponseModel: Codable {
    var action          : String?
    var timeStamp       : Int64?
    var returnValue     : Int?
}

enum DataChannelRequestAction: String, CodingKey {
    case startLive              = "startLive"
    case stopLive               = "stopLive"
    case startPlaySdVideo       = "startPlaySdVideo"
    case stopPlaySdVideo        = "stopPlaySdVideo"
    case getSdVideoList         = "getSdVideoList"
    case getSdHasVideoDays      = "getSdHasVideoDays"
    case triggerAlarm           = "triggerAlarm"
    case setLiveResolution      = "setLiveResolution"
    case setWhiteLight          = "setWhiteLight"
    case getStatus              = "getStatus"
    case replaySeek             = "replaySeek"
}

class DataChannelAppRequest: NSObject {
    
    private class func md5(strs: String) ->String!{
      let str = strs.cString(using: String.Encoding.utf8)
      let strLen = CUnsignedInt(strs.lengthOfBytes(using: String.Encoding.utf8))
      let digestLen = Int(CC_MD5_DIGEST_LENGTH)
      let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
      CC_MD5(str!, strLen, result)
      let hash = NSMutableString()
      for i in 0 ..< digestLen {
          hash.appendFormat("%02x", result[i])
      }
      result.deinitialize(count: digestLen)
      return String(format: hash as String)
    }
    
    private class func getUUID() -> String {
       let uuidRef = CFUUIDCreate(nil)
       let uuidStringRef = CFUUIDCreateString(nil,uuidRef)
       return uuidStringRef! as String
    }
    
    private class func generateRequestID() -> String{
        let requestID = self.getUUID()
        return requestID
    }
    
    private class func generateConnectID(requestId:String, model: ADDXWebRTCTicketModel) -> String{
        let nameStr = model.name ?? ""
        var connectID = model.groupId! + ":" + model.role! + ":" + model.clientId! + ":" + nameStr + ":" + String(model.dataChannelOpenTime)
        Log.vLog(level: .notice, " connectID:  \(connectID)")
        connectID = self.md5(strs: connectID)
        return connectID
    }
    
    //创建播放请求json配置
    //开始播放：请求ID，连接标识ID（group ID），全局时间戳（UTC时间）；参数：开始时间（UTC时间）
    class func createRequestModel(ticketModel: ADDXWebRTCTicketModel, action: String) -> DataChannelRequestModel {
        let requestID = self.generateRequestID()
        let connectionID = self.generateConnectID(requestId: requestID, model: ticketModel)
        let model = DataChannelRequestModel()
        model.requestID = requestID
        model.connectionID = connectionID
        model.action = action
        return model
    }
    
    class func startPlayLiveRequest(ticketModel: ADDXWebRTCTicketModel, liveResoolutionType: ADDXWebRTCPlayerVideoSharpType) -> DataChannelRequestModel{
        let requestID = self.generateRequestID()
        let connectionID = self.generateConnectID(requestId: requestID, model: ticketModel)
        var liveResoolution = "1280x720"
        switch liveResoolutionType {
        case .hb:
            liveResoolution = "1920x1080"
            break
        case .standard:
            liveResoolution = "1280x720"
            break
        case .smooth:
            liveResoolution = "640x480"
            break
        case .auto:
            liveResoolution = "auto"
            break
        }
        var paramsModel = StartPlayLiveRequestParamsModel()
        paramsModel.requestID = requestID
        paramsModel.connectionID = connectionID
        paramsModel.timeStamp = Int64(Date.timeStamp())
        paramsModel.action = DataChannelRequestAction.startLive.rawValue
        paramsModel.size = liveResoolution
        
        let encoder = JSONEncoder()
        let data = try? encoder.encode(paramsModel)
        let model = DataChannelRequestModel()
        model.requestData = data
        model.requestID = requestID
        model.connectionID = connectionID
        model.action = paramsModel.action
        return model
    }
    
    //停止播放：请求ID，连接标识ID（group ID），全局时间戳（UTC时间）；参数：开始时间（UTC时间）
    class func stopPlayLiveRequest(ticketModel: ADDXWebRTCTicketModel) -> DataChannelRequestModel{
        let requestID = self.generateRequestID()
        let connectionID = self.generateConnectID(requestId: requestID, model: ticketModel)
        var paramsModel = StopPlayLiveRequestParamsModel()
        paramsModel.requestID = requestID
        paramsModel.connectionID = connectionID
        paramsModel.timeStamp = Int64(Date.timeStamp())
        paramsModel.action = DataChannelRequestAction.stopLive.rawValue
        
        let encoder = JSONEncoder()
        let data = try? encoder.encode(paramsModel)
        let model = DataChannelRequestModel()
        model.requestData = data
        model.requestID = requestID
        model.connectionID = connectionID
        model.action = paramsModel.action
        return model
    }
    
    //开始播放：请求ID，连接标识ID（group ID），全局时间戳（UTC时间）；参数：开始时间（UTC时间）
    class func startPlaySdVideoRequest(ticketModel: ADDXWebRTCTicketModel, startTime: Int64) -> DataChannelRequestModel {
        let requestID = self.generateRequestID()
        let connectionID = self.generateConnectID(requestId: requestID, model: ticketModel)
        var paramsModel = StartPlaySDVideoRequestParamsModel()
        paramsModel.requestID = requestID
        paramsModel.connectionID = connectionID
        paramsModel.timeStamp = Int64(Date.timeStamp())
        paramsModel.action = DataChannelRequestAction.startPlaySdVideo.rawValue
        var parameters = PlaySDVidoRequestParameters()
        parameters.startTime =  startTime
        paramsModel.parameters = parameters
        
        let encoder = JSONEncoder()
        let data = try? encoder.encode(paramsModel)
        let model = DataChannelRequestModel()
        model.requestData = data
        model.requestID = requestID
        model.connectionID = connectionID
        model.action = paramsModel.action
        return model
    }
    
    // 自定义请求
    class func loadRequestData<ParamType : Codable>(ticketModel: ADDXWebRTCTicketModel, action : String, param: ParamType?)-> DataChannelRequestModel {
        let requestID = self.generateRequestID()
        let connectionID = self.generateConnectID(requestId: requestID, model: ticketModel)
        
        var paramsModel = BaseRequestParamsModel<ParamType>()
        paramsModel.requestID = requestID
        paramsModel.connectionID = connectionID
        paramsModel.timeStamp = Int64(Date.timeStamp())
        paramsModel.action = action
        paramsModel.parameters = param

        let encoder = JSONEncoder()
        let data = try? encoder.encode(paramsModel)
        
        let model = DataChannelRequestModel()
        model.requestData = data
        model.requestID = requestID
        model.connectionID = connectionID
        model.action = action
        
        return model
    }
    
    //停止播放：请求ID，连接标识ID（group ID），全局时间戳（UTC时间）；参数：开始时间（UTC时间）
    class func stopPlaySdVideoRequest(ticketModel: ADDXWebRTCTicketModel) -> DataChannelRequestModel {
        let requestID = self.generateRequestID()
        let connectionID = self.generateConnectID(requestId: requestID, model: ticketModel)
        var paramsModel = StopPlayLiveRequestParamsModel()
        paramsModel.requestID = requestID
        paramsModel.connectionID = connectionID
        paramsModel.timeStamp = Int64(Date.timeStamp())
        paramsModel.action = DataChannelRequestAction.stopPlaySdVideo.rawValue
        
        let encoder = JSONEncoder()
        let data = try? encoder.encode(paramsModel)
        let model = DataChannelRequestModel()
        model.requestData = data
        model.requestID = requestID
        model.connectionID = connectionID
        model.action = paramsModel.action
        return model
    }
    
    //查询：请求ID，连接标识ID（group ID），全局时间戳（UTC时间）；参数：开始时间（UTC时间），结束时间（UTC时间)
    class func getSdVideoListRequest(ticketModel: ADDXWebRTCTicketModel, startTime: Int64, stopTime: Int64) -> DataChannelRequestModel {
        let requestID = self.generateRequestID()
        let connectionID = self.generateConnectID(requestId: requestID, model: ticketModel)
        var paramsModel = GetSDVideoListRequestParamsModel()
        paramsModel.requestID = requestID
        paramsModel.connectionID = connectionID
        paramsModel.timeStamp = Int64(Date.timeStamp())
        paramsModel.action = DataChannelRequestAction.getSdVideoList.rawValue
        var parameters = GetSDVidoListRequestParameters()
        parameters.startTime =  startTime
        parameters.stopTime =  stopTime
        paramsModel.parameters = parameters
        
        let encoder = JSONEncoder()
        let data = try? encoder.encode(paramsModel)
        let model = DataChannelRequestModel()
        model.requestData = data
        model.requestID = requestID
        model.connectionID = connectionID
        model.action = paramsModel.action
        Log.vLog(level: .notice, "DataChannel getSDVideoListRequest: \(String(data: model.requestData!, encoding: .utf8) ?? "")")
        return model
    }
    
    //设置：请求ID，连接标识ID（group ID），全局时间戳（UTC时间）；参数：设置值
    //设置白光灯
    class func setWhiteLightRequest(ticketModel: ADDXWebRTCTicketModel, enable: Bool) -> DataChannelRequestModel {
        let requestID = self.generateRequestID()
        let connectionID = self.generateConnectID(requestId: requestID, model: ticketModel)
        var value = 1
        if enable {
            value = 2
        }
        var paramsModel = SetWhiteLightRequestParamsModel()
        paramsModel.requestID = requestID
        paramsModel.connectionID = connectionID
        paramsModel.timeStamp = Int64(Date.timeStamp())
        paramsModel.action = DataChannelRequestAction.setWhiteLight.rawValue
        var parameters = SetWhiteLightRequestParameters()
        parameters.value =  value
        paramsModel.parameters = parameters
        
        let encoder = JSONEncoder()
        let data = try? encoder.encode(paramsModel)
        let model = DataChannelRequestModel()
        model.requestData = data
        model.requestID = requestID
        model.connectionID = connectionID
        model.action = paramsModel.action
        return model
    }
    
    //设置画质
    class func setLiveResolutionRequest(ticketModel: ADDXWebRTCTicketModel, liveResoolutionType: ADDXWebRTCPlayerVideoSharpType) -> DataChannelRequestModel{
        let requestID = self.generateRequestID()
        let connectionID = self.generateConnectID(requestId: requestID, model: ticketModel)
        var liveResoolution = "1280x720"
        switch liveResoolutionType {
        case .hb:
            liveResoolution = "1920x1080"
            break
        case .standard:
            liveResoolution = "1280x720"
            break
        case .smooth:
            liveResoolution = "640x480"
            break
        case .auto:
            liveResoolution = "auto"
            break
        }
        var paramsModel = SetLiveResolutionRequestParamsModel()
        paramsModel.requestID = requestID
        paramsModel.connectionID = connectionID
        paramsModel.timeStamp = Int64(Date.timeStamp())
        paramsModel.action = DataChannelRequestAction.setLiveResolution.rawValue
        var parameters = SetLiveResolutionRequestParameters()
        parameters.value =  liveResoolution
        paramsModel.parameters = parameters
        
        let encoder = JSONEncoder()
        let data = try? encoder.encode(paramsModel)
        let model = DataChannelRequestModel()
        model.requestData = data
        model.requestID = requestID
        model.connectionID = connectionID
        model.action = paramsModel.action
        return model
    }
    
    //警告
    class func triggerAlarmRequest(ticketModel: ADDXWebRTCTicketModel) -> DataChannelRequestModel {
        let requestID = self.generateRequestID()
        let connectionID = self.generateConnectID(requestId: requestID, model: ticketModel)
        var paramsModel = TriggerAlarmnRequestParamsModel()
        paramsModel.requestID = requestID
        paramsModel.connectionID = connectionID
        paramsModel.timeStamp = Int64(Date.timeStamp())
        paramsModel.action = DataChannelRequestAction.triggerAlarm.rawValue
        
        let encoder = JSONEncoder()
        let data = try? encoder.encode(paramsModel)
        let model = DataChannelRequestModel()
        model.requestData = data
        model.requestID = requestID
        model.connectionID = connectionID
        model.action = paramsModel.action
        
        return model
    }
    
    //获取状态：请求ID，连接标识ID（group ID），全局时间戳（UTC时间)
    class func getStatusRequest(ticketModel: ADDXWebRTCTicketModel, timeStamp: TimeInterval) -> DataChannelRequestModel {
        let requestID = self.generateRequestID()
        let connectionID = self.generateConnectID(requestId: requestID, model: ticketModel)
        var paramsModel = TriggerAlarmnRequestParamsModel()
        paramsModel.requestID = requestID
        paramsModel.connectionID = connectionID
        paramsModel.timeStamp = Int64(Date.timeStamp())
        paramsModel.action = DataChannelRequestAction.getStatus.rawValue
        
        let encoder = JSONEncoder()
        let data = try? encoder.encode(paramsModel)
        let model = DataChannelRequestModel()
        model.requestData = data
        model.requestID = requestID
        model.connectionID = connectionID
        model.action = paramsModel.action
        return model
    }
}

class DataChannelCameraResponse: NSObject {
    class func responseRequestID(response: Data) -> (String?, String?) {
        var requestID: String?
        var connectionID: String?
        let startLiveModel = self.paramResponseParam(response: response)
        if startLiveModel != nil {
            requestID = startLiveModel!.requestID
            connectionID = startLiveModel!.connectionID
            return (requestID, connectionID)
        }
        Log.vLog(level: .error, "未解析到requestID,connectionID 数据")
        return (requestID,connectionID)
    }
    
    class func paramResponseModel(response: Data, model: DataChannelRequestModel) {
        switch DataChannelRequestAction(rawValue: model.action ?? "") {
        case .startLive:
            let startLiveModel = self.startPlayLiveResponseParam(response: response)
            if startLiveModel != nil {
                model.response?.requestID = startLiveModel?.requestID
                model.response?.returnValue = String(startLiveModel!.returnValue!)
            }
            break
        case .stopLive:
            let stopLiveModel = self.stopPlayLiveResponseParam(response: response)
            if stopLiveModel != nil {
                model.response?.requestID = stopLiveModel?.requestID
                model.response?.returnValue = String(stopLiveModel!.returnValue!)
            }
            break
        case .getSdHasVideoDays:
            debugPrint("-----------> paramResponseModel func getSdHasVideoDays")
            break
        case .startPlaySdVideo:
            let startSDVideoModel = self.startPlaySdVideoResponseParam(response: response)
            if startSDVideoModel != nil {
                model.response?.requestID = startSDVideoModel?.requestID
                model.response?.returnValue = String(startSDVideoModel!.returnValue!)
            }
            break
        case .stopPlaySdVideo:
            let stopSDVideoModel = self.stopPlaySdVideoResponseParam(response: response)
            if stopSDVideoModel != nil {
                model.response?.requestID = stopSDVideoModel?.requestID
                model.response?.returnValue = String(stopSDVideoModel!.returnValue!)
            }
            break
        case .getSdVideoList:
            let getSDVideoListModel = self.getSdVideoListResponseParam(response: response)
            if getSDVideoListModel != nil {
                model.response?.requestID = getSDVideoListModel?.requestID
                model.response?.returnValue = String(getSDVideoListModel!.returnValue!)
                if getSDVideoListModel!.data != nil{
                    let encoder = JSONEncoder()
                    let data = try? encoder.encode(getSDVideoListModel!.data)
                    model.response?.resultData = data
                }
            }
            break
        case .triggerAlarm, .setLiveResolution,.setWhiteLight:
            let setModel = self.setResponseParam(response: response)
            if setModel != nil {
                model.response?.requestID = setModel?.requestID
                model.response?.returnValue = String(setModel!.returnValue!)
            }
            break
        case .getStatus:
            let getStatusModel = self.getStatusResponseParam(response: response)
            if getStatusModel != nil {
                model.response?.requestID = getStatusModel?.requestID
                model.response?.returnValue = String(getStatusModel!.returnValue!)
                if getStatusModel!.data != nil{
                    let encoder = JSONEncoder()
                    let data = try? encoder.encode(getStatusModel!.data)
                    model.response?.resultData = data
                }
            }
            break
        case .replaySeek:
            break
        default:
            Log.vLog(level: .error, "未解析到datachannel 数据")
            break
        }
    }
    class func paramResponse(response: Data, model: DataChannelRequestModel) {
        model.response = DataChannelRequestResponseModel()
        model.response?.responseData = response
        self.paramResponseModel(response: response, model: model)
        
    }
    class func paramResponseParam(response: Data) -> ParameResponseModel? {
        let decoder = JSONDecoder()
        let responseModel = try? decoder.decode(ParameResponseModel.self, from: response)
        if responseModel != nil {
           Log.vLog(level: .notice, "paramResponseParam func responseModel: \(responseModel!)")
        }
        return responseModel
    }
    
    class func startPlayLiveResponseParam(response: Data) -> StartPlayLiveResponseModel? {
        let decoder = JSONDecoder()
        let responseModel = try? decoder.decode(StartPlayLiveResponseModel.self, from: response)
        if responseModel != nil {
            Log.vLog(level: .notice, "startPlayLiveResponseParam func responseModel: \(responseModel!)")
        }
        return responseModel
    }
    
    class func stopPlayLiveResponseParam(response: Data) -> StopPlayLiveResponseModel? {
        let decoder = JSONDecoder()
        let responseModel = try? decoder.decode(StopPlayLiveResponseModel.self, from: response)
        if responseModel != nil{
           Log.vLog(level: .warning, "stopPlayLiveResponseParam func responseModel: \(responseModel!)")
        }
        return responseModel
    }
    
    class func startPlaySdVideoResponseParam(response: Data) -> StartPlaySDVideoResponseModel? {
        let decoder = JSONDecoder()
        let responseModel = try? decoder.decode(StartPlaySDVideoResponseModel.self, from: response)
        if responseModel != nil {
            Log.vLog(level: .notice, "startPlaySdVideoResponseParam func responseModel: \(responseModel!)")
        }
        return responseModel
    }
    
    class func stopPlaySdVideoResponseParam(response: Data) -> StopPlaySDVideoResponseModel? {
        let decoder = JSONDecoder()
        let responseModel = try? decoder.decode(StopPlaySDVideoResponseModel.self, from: response)
        if responseModel != nil {
            Log.vLog(level: .warning, "stopPlaySdVideoResponseParam func responseModel: \(responseModel!)")
        }
        return responseModel
    }
    
    class func getSdVideoListResponseParam(response: Data) -> GetSDVideoListResponseModel? {
        let decoder = JSONDecoder()
        let responseModel = try? decoder.decode(GetSDVideoListResponseModel.self, from: response)
        if responseModel != nil {
            Log.vLog(level: .notice, "getSdVideoListResponseParam func responseModel: \(responseModel!)")
        }
        return responseModel
    }
    
    class func setResponseParam(response: Data) -> SetingResponseModel? {
        let decoder = JSONDecoder()
        let responseModel = try? decoder.decode(SetingResponseModel.self, from: response)
        if responseModel != nil {
            Log.vLog(level: .notice, "setResponseParam func responseModel: \(responseModel!)")
        }
        return responseModel
    }
    
    class func getStatusResponseParam(response: Data) -> GetStatusResponseModel? {
        let decoder = JSONDecoder()
        let responseModel = try? decoder.decode(GetStatusResponseModel.self, from: response)
        if responseModel != nil {
            Log.vLog(level: .notice, "getStatusResponseParam func responseModel: \(responseModel!)")
        }
        return responseModel
    }

}


class DataChannelCameraRequest: NSObject {
    
    class func responseAction(response: Data) -> String? {
        var action: String?
        let requsetModel = self.paramRequestParam(response: response)
        if requsetModel != nil {
            action = requsetModel!.action
            return action
        }
        Log.vLog(level: .error, "responseAction func 未解析到action 数据")
        return action
    }
    
    class func paramRequestParam(response: Data) -> ParameRequestModel? {
        let decoder = JSONDecoder()
        let requestModel = try? decoder.decode(ParameRequestModel.self, from: response)
        if requestModel != nil {
            Log.vLog(level: .notice, "paramRequestParam func requestModel: \(requestModel!)")
        }
        return requestModel
    }
}

class DataChannelAppResponse: NSObject {
    
    class func paramResponseModel(model: DataChannelRequestModel) {
    switch DataChannelRequestAction(rawValue: model.action ?? "") {
    case .replaySeek:
        self.replaySeekReponse(model: model)
        break
    default:
        break
        }
    }
    
    class func replaySeekReponse(model: DataChannelRequestModel) {
        var paramsModel = ReplaySeekResponseModel()
        paramsModel.timeStamp = Int64(Date.timeStamp())
        paramsModel.action = DataChannelRequestAction.replaySeek.rawValue
        paramsModel.returnValue = 0
        model.action = paramsModel.action
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(paramsModel) else{
            return
        }
        model.requestData = data
        Log.vLog(level: .warning, "DataChannel app replaySeekReponse: \(String(data: data, encoding: .utf8) ?? "")")
    }
}
