//
//  ADPresetDataModle.swift
//  AddxAi
//
//  Created by kzhi on 2019/11/28.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import Foundation
import A4xBaseSDK
import Disk
import A4xWebRTCSDK

//ADPresetRoteModel
enum ADPresetCmdType : String {
    case rotate = "rotate"
    case getCoordinate = "getCurCoordinate"
    case toCoordinate = "moveToCoordinate"
    case getFllowState = "getMotionTrackStatus"
    case setFllowState = "setMotionTrackStatus"
}

struct ADRresetRotate : Codable {
    var pitch : Float
    var yaw : Float
}

struct ADCoordinateType : Codable {
    var coordinate : String?
}
struct ADFllowStateType : Codable {
    var status : Int?
}

class ADPresetDataModle {
    // 预设位置最大添加数
    let maxCount : Int = 5
    var fllowInfos : [String : Bool] = [:] {
        didSet{
            A4xLog("ADPresetDataModle fllowInfos change \(fllowInfos)")
        }
    }
    
    var followTypes : [String : Bool] = [:] {
        didSet {
            A4xLog("ADPresetDataModle followTypes change \(followTypes)")
        }
    }
    
    func isFollow(deviceId: String) -> Bool {
        return fllowInfos[deviceId] ?? false
    }
    
    func isFollowType(deviceId: String) -> Bool {
        return followTypes[deviceId] ?? false
    }
    
    func data(deviceId: String) -> [ADPresetModel]? {
        return dataSource[deviceId]
    }
    
    var dataSource : [String : [ADPresetModel]] {
        set {
            try? Disk.save(newValue, to: .documents, as: "preset.json" )
        }
        get {
            let dataSourced = (try? Disk.retrieve("preset.json", from: Disk.Directory.documents, as: [String : [ADPresetModel]].self)) ?? [:]
            return dataSourced
        }
    }
    
    // 加载运动追踪状态
    private func loadMotionTrackStatus(deviceId : String? ,comple : @escaping (_ error : String?)->Void) {
        guard let devid = deviceId else {
            comple(R.string.localizable.unkonw_error())
            return
        }
        guard let device = A4xUserDataHandle.Handle?.getDevice(deviceId: devid) else {
            comple(R.string.localizable.unkonw_error())
            return
        }
        let type : Int? = nil
        
        // v2.3版本新逻辑
        A4xNetManager.execute(reqMoudelType: A4xNetMoudelType.Devices(.getuserconfig(deviceId: devid)), resModelType: A4xDeviceModel.self) { [weak self](result) in
            switch result {
            case .success(let modle):
                self?.followTypes[devid] = modle?.motionTrackMode ?? 0 > 0
                self?.fllowInfos[devid] = modle?.motionTrack ?? 0 > 0
                comple(nil)
            case .failure(let code,  _):
                comple(A4xAppErrorConfig(code: code).message())
            }
        }
        
        // v2.3版本暂废弃 - 2020.12.09
        //A4xPlayerManager.handle.sendCmd(device: device, action: ADPresetCmdType.getFllowState.rawValue, param: type, resultType: ADFllowStateType.self) { [weak self] (result, error) in
        //self?.fllowInfos[devid] = result?.status == 1
        //comple(error)
        //}
    }
    
    // 更新运动追踪状态
    func updateMotionTrackStatus(deviceId : String?, enable : Bool ,comple : @escaping (_ error : String?)->Void) {
        guard let devid = deviceId else {
            return
        }
        self.fllowInfos.removeValue(forKey: devid)
        
        // v2.3版本新逻辑
        A4xNetManager.execute(reqMoudelType: A4xNetMoudelType.Devices(.motionTrack(deviceId: devid, enable: enable)) , resModelType: A4xNetNormaiModel.self) { [weak self] (result) in
            switch result {
            case .success(_):
                self?.fllowInfos[devid] = enable
                comple(nil)
            case .failure(let code, _):
                if code == 10000 || code == 10001 {
                    comple(R.string.localizable.request_timeout_and_try())
                } else {
                    comple(A4xAppErrorConfig(code: code).message())
                }
            }
        }

        // v2.3版本暂废弃 - 2020.12.09
        //guard let device = A4xUserDataHandle.Handle?.getDevice(deviceId: devid) else {
        //return
        //}
        //A4xPlayerManager.handle.sendCmd(device: device, action: ADPresetCmdType.setFllowState.rawValue, param: ADFllowStateType(status: enable ? 1 : 0), resultType: Int.self) { [weak self] (result, error) in
        //if error == nil {
        //self?.fllowInfos[devid] = enable
        //}
        //comple(error)
        //}
    }
    
    // 摇杆控制统一处理 凹
    func rotate(deviceId : String? , x : Float , y : Float ,comple : @escaping (_ error : String?)->Void){
        guard let devid = deviceId else {
            return
        }
        guard let device = A4xUserDataHandle.Handle?.getDevice(deviceId: devid) else {
            return
        }
        // 摇杆过程中不移除追踪图标的状态 v2.3 - 2020.12.11 by wjin
        //self.fllowInfos.removeValue(forKey: devid)
        A4xPlayerManager.handle.sendCmd(device: device, action: ADPresetCmdType.rotate.rawValue, param: ADRresetRotate(pitch: y, yaw: -x), resultType: Int.self) { (result, error) in
            A4xLog("A4xPlayerManager.handle.sendCmd --- ")
            comple(error)
        }
    }
    
    //
    func send(deviceId : String? ,preset : ADPresetModel? ,comple : @escaping (_ error : String?)->Void){
        guard let devid = deviceId  else {
            return
        }
        guard let device = A4xUserDataHandle.Handle?.getDevice(deviceId: devid) else {
            return
        }
        // 摇杆过程中不移除追踪图标的状态 v2.3 - 2020.12.11 by wjin
        //self.fllowInfos.removeValue(forKey: devid)
        A4xPlayerManager.handle.sendCmd(device: device, action: ADPresetCmdType.toCoordinate.rawValue, param: ADCoordinateType(coordinate: preset?.coordinate), resultType: ADCoordinateType.self) { (result, error) in
            comple(error)
        }
     
    }
    
    // 判断是否超过最大预设位置添加数 凹
    func canAdd(deviceId: String?) -> (canAdd : Bool , errorStr : String?) {
        if self.data(deviceId: deviceId ?? "")?.count ?? 0 >= maxCount {
            return (false , R.string.localizable.more_pre_location(maxCount))
        }
        return (true , nil)
    }
    
    // 添加预设位置统一处理 凹
    func add(deviceId: String?, image: UIImage? , name: String? ,comple : @escaping (_ isError : Bool , _ tips : String?)->Void){
        guard let devid = deviceId ,let img = image ,let pName = name else {
            return
        }
        
        if self.data(deviceId: deviceId ?? "")?.count ?? 0 >= maxCount {
            comple(false , R.string.localizable.more_pre_location(maxCount))
            return
        }
        
        // 预设图片压缩 - 石虎
        //let imageData = img.compression(toSize: CGSize(width: 160, height: 160))?.pngData() ?? Data()
        let imageData = img.imageWithNewSize(size: CGSize(width: 120, height: 90))?.pngData() ?? Data()
 
        guard let device = A4xUserDataHandle.Handle?.getDevice(deviceId: devid) else {
            comple(false , R.string.localizable.unkonw_error())
            return
        }
        let s : String? = nil
        A4xPlayerManager.handle.sendCmd(device: device, action: ADPresetCmdType.getCoordinate.rawValue, param: s, resultType: ADCoordinateType.self) { [weak self] (result, error) in
            if result?.coordinate?.count ?? 0 > 0 {
                A4xNetManager.execute(reqMoudelType: A4xNetMoudelType.DeviceControl(.saveRotationPoint(deviceId: devid, coordinate: result?.coordinate ?? "", name: pName, imageData: imageData)), resModelType: ADPresetModel.self) { (result) in
                    switch result {
                    case .success(let modle):
                        // 添加预设位置成功
                        debugPrint("-----------> 添加预设位置成功")
                        self?.addPresetLocation(deviceId: devid, location: modle ?? ADPresetModel())
                        comple(true , R.string.localizable.add_preset_scuess())
                    case .failure(let code, _):
                        // 添加预设位置失败
                        comple(false , A4xAppErrorConfig(code: code).message())
                    }
                }
            }else {
                comple(false , error)
            }
        }
    }
    
    // 删除预设位置统一处理 凹
    func remove(deviceId : String? ,pointId : Int , comple : @escaping (_ isError : Bool , _ tips : String?) ->Void){
        guard let devid = deviceId  else {
            return
        }
        weak var weakSelf = self
        A4xNetManager.execute(reqMoudelType: A4xNetMoudelType.DeviceControl(.remove(deviceId: devid, id: pointId)), resModelType: A4xNetNormaiModel.self) { (result) in
            switch result {
            case .success(_):
                weakSelf?.deletePreset(deviceId: devid, presetId: pointId)
                comple(true , R.string.localizable.position_deleted())
            case .failure(let code, _):
                comple(false , A4xAppErrorConfig(code: code).message())
            }
        }
    }
    
    //
    func featch(deviceId : String? , comple : @escaping (_ error : String?)->Void){
        guard let devid = deviceId  else {
            return
        }
        fllowInfos.removeAll()
        weak var weakSelf = self
        A4xNetManager.execute(reqMoudelType: A4xNetMoudelType.DeviceControl(.all(deviceId: devid)), resModelType: ADPresetModelResponse.self) { (result) in
            switch result {
            case .success(let data):
                weakSelf?.dataSource[devid] = data?.list
                weakSelf?.loadMotionTrackStatus(deviceId: devid, comple: { (error) in
                    comple(nil)
                })
            case .failure(let code, _):
                comple(A4xAppErrorConfig(code: code).message())
            }
        }
    }
    
    //
    func addPresetLocation(deviceId : String , location : ADPresetModel){
        guard var deLocations = self.dataSource[deviceId] else {
            return
        }
        deLocations.append(location)
        self.dataSource[deviceId]  = deLocations

    }
    
    //
    func deletePreset(deviceId : String ,presetId : Int){
        guard let deLocations = self.dataSource[deviceId] else {
            return
        }
        guard deLocations.count > 0 else {
            return
        }
        let temp = deLocations.filter { (pre) -> Bool in
            if pre.id == presetId {
                return false
            }
            return true
        }
        self.dataSource[deviceId]  = temp
    }
    
    // 更新休眠状态
    func sleepToWakeUP(deviceId: String, enable: Bool, comple: @escaping (_ error: String?) -> Void) {
        A4xNetManager.execute(reqMoudelType: A4xNetMoudelType.Devices(.sleepToWakeUP(deviceId: deviceId, enable: enable)), resModelType: A4xNetNormaiModel.self) { (result) in
            switch result {
            case .success(_):
                comple(nil)
            case .failure(let code, _):
                if code == 10000 || code == 10001 {
                    comple(R.string.localizable.open_fail_retry())
                } else {
                    comple(A4xAppErrorConfig(code: code).message())
                }
            }
        }
    }
    
}
