//
//  ADHomeViewModel.swift
//  AddxAi
//
//  Created by zhi kuiyu on 2019/2/14.
//  Copyright © 2019 addx.ai. All rights reserved.
//

import Foundation
import UIKit
import ZKDownload
import ADDXWebRTC
import A4xBaseSDK


enum downloadType {
    case m3u8
    case mp4
}

class ADHomeViewModel: NSObject {
    let pageSize : Int = 20
    //var resoucesModels : [A4xLibraryVideoModel] = Array()
    var resoucesPage : Int = 0
    var resoucesTotal : Int = 0
    var resourceHasMore : Bool = false
    
    // m3u8 下载
    //var resoucesADM3U8Models : [(ADM3U8DownloadModel,Int)] = [] //模型和下载子数量
    //var resoucesADM3U8ModelsDic : [String :(ADM3U8DownloadModel, Int)] = [:] //tag组模型和下载子数量
    var adM3U8DownloadTagDic : [String: Int] = [:] //tag组字典 // 统计tag各个数量
    var adM3U8DownloadTagArr : [String] = [] // m3u8 根据tag数判断下载数量
    var adM3U8DownloadDoneCountArr: [(String,Int)] = [] // 总m3u8已经下载量，按照tag分组
    var adM3U8UnitCount: Int = 0 // m3u8单元

    //var adM3U8Model: ADM3U8DownloadModel?
    //var tsURLHandler: TsURLHandler?
    
    // 声明队列
    private let operationQueue: OperationQueue  = {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.qualityOfService = .utility
        return operationQueue
    }()
    
    // 合并
    //private var combineCompletion: CombineCompletion?
    private let dispatchQueue = DispatchQueue(label: "m3u8_combine")
    
    /// current is share
    private var shareURL : String?
    
    private var shareResouse : ((Bool , MediaType? ,String? ,@escaping (()->Void))->Void)?
    private var shareStatus: Bool?
    
    override init() {
    }
    
//    func getLocationsModel(result : @escaping ([ADDialogModelProtocol]?) -> Void){
        //        weak var weakSelf = self
//        getUserLocations { (_, error) in
//            //            result(weakSelf?.loadLocation())
//        }
//        result(self.loadLocation())
        
//    }
    
//    private func loadLocation() -> [ADAddressFilterModle]?{
//        var resultArray : [ADAddressFilterModle] = Array()
//        resultArray.append(ADAddressAllModle())
//        let locat : [ADAddressFilterModle]? = A4xUserDataHandle.Handle?.locationsModel
//        if locat != nil {
//            resultArray += locat!
//        }
//        resultArray += [ADAddressShareModle()]
//        return resultArray;
//    }
    
    // 获取用户设备列表
    func getDevices(resultb: @escaping (_ deviceModels: [A4xDeviceModel]?, _ errorString: String?) -> Void) -> Void {
        A4xNetManager.execute(reqMoudelType: A4xNetMoudelType.Devices(.listuserdevices), resModelType: A4xBaseDeviceListModel.self) { (result) in
            switch result {
            case let .success(model):
                A4xUserDataHandle.Handle?.deviceModels = model?.list
                resultb(model?.list, nil)
            case .failure(let code,_):
                resultb(nil, A4xAppErrorConfig(code: code).message()) // R.string.localizable.failed_get_infomation(code)
            }
        }
    }
    
    func getUserLocations(resultBlock: @escaping (_ shouldAdd : Bool ,_ error : String?) -> Void) {
        A4xNetManager.execute(reqMoudelType: A4xNetMoudelType.Location(.locationList), resModelType: [A4xLocationModel].self) { (result) in
            switch result {
            case let .success(models):
                A4xUserDataHandle.Handle?.locationsModel = models ?? []
                let count = models?.count ?? 0 == 0
                resultBlock(count , nil)
            case .failure(let code, _):
                resultBlock(false , A4xAppErrorConfig(code: code).message())
            }
            
        }
    }
    
    func closeUserDisturb(resultBlock : @escaping (_ isScuess : Bool ,_ error : String?) -> Void ){
        A4xNetManager.execute(reqMoudelType: A4xNetMoudelType.Account(.deleteUserPushShield), resModelType: Bool.self) { (result) in
            switch result {
            case let .success(models):
                A4xUserDataHandle.Handle?.disturbModle = nil
                resultBlock(true , nil)
            case .failure(let code, _):
                resultBlock(true , A4xAppErrorConfig(code: code).message())
            }
        }
    }
    
    func getUserDisturbInfo(resultBlock : @escaping (_ isScuess : Bool ,_ error : String?) -> Void) {
//        let dis = A4xAccountDisturbModel(shield: true, timeSlot: 60, timeSet: Date().timeIntervalSince1970)
//        A4xUserDataHandle.Handle?.disturbModle = dis
//        A4xNetManager.execute(reqMoudelType: A4xNetMoudelType.Account(.getUserPushShield), resModelType: A4xAccountDisturbModel.self) { (result) in
//            switch result {
//            case let .success(models):
//                A4xUserDataHandle.Handle?.disturbModle = models
//                resultBlock(true , nil)
//            case .failure(let code, _):
//
//                resultBlock(false , A4xAppErrorConfig(code: code).message())
//            }
//        }
    }
    
    func openUserDisturbEnable(duration : Int , resultBlock : @escaping (_ isScuess : Bool ,_ error : String?) -> Void) {
        A4xNetManager.execute(reqMoudelType: A4xNetMoudelType.Account(.updateDisturb(time: duration)), resModelType: A4xAccountDisturbModel.self) { (result) in
            switch result {
            case let .success(models):
                A4xUserDataHandle.Handle?.disturbModle = models
                resultBlock(true , nil)
            case .failure(let code, _):
                resultBlock(false , A4xAppErrorConfig(code: code).message())
            }
        }
    }
    
    // 唤醒设备
    func sleepToWakeUP(deviceId: String, enable: Bool, comple: @escaping (_ error: String?) -> Void) {
        A4xNetManager.execute(reqMoudelType: A4xNetMoudelType.Devices(.sleepToWakeUP(deviceId: deviceId, enable: enable)), resModelType: A4xNetNormaiModel.self) { [weak self] (result) in
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

extension ADHomeViewModel {
    
}

extension ADHomeViewModel {
    func deleteResouces(sIds : [Int] , result: @escaping (_ error : String?)->Void) {
        A4xNetManager.execute(reqMoudelType: A4xNetMoudelType.Library(.delete(libaryIds: sIds)), resModelType: A4xNetNormaiModel.self) { (res) in
            switch res {
            case .success(_):
                result(nil);
            case .failure(let code, _):
                result(A4xAppErrorConfig(code: code) .message());
            }
            
        }
    }
    
//    func getResources(isMore: Bool, date : Date , filter : ADFilterMoodel?, result: @escaping ([A4xLibraryVideoModel]?, _ hasMore : Bool , _ total : Int? ,_ error : String? ) -> Void) {
//
//        if !isMore {
//            self.resoucesPage = 0
//            self.resoucesModels.removeAll()
//        }
//        let mark : Int = filter?.isSelect(other: .mark) ?? false ? 1 : 0
//        let unread : Int = filter?.isSelect(other: .unread) ?? false ? 1 : 0
//        weak var weakSelf = self
//        let timeBetween = date.dayBetween
//        let tags : [String] = filter?.tags() ?? []
//
//        A4xLog("shihu == filter?.resources2 【请求数据】 = \(filter?.resources2 ?? [:])")
//        // library/selectlibrary  （ // activityZone）
//        A4xNetManager.execute(reqMoudelType: A4xNetMoudelType.Library(.selectlibrary(start: timeBetween.0 , end: timeBetween.1 , mark: mark, miss: unread, deviceId: filter?.devices(), page: self.resoucesPage, pageSize: self.pageSize ,tags: tags ,serialNumberToActivityZone: filter?.resources2)), resModelType: ADLibaryResouceResponse.self) { (data) in
//            switch data {
//            case let .success(modle):
//                let list = modle?.list
//                let total = modle?.total
//                if let strongSelf = weakSelf {
//                    strongSelf.resoucesTotal = total ?? 0
//                    let showMax = (strongSelf.resoucesPage + 1) * strongSelf.pageSize
//                    strongSelf.resourceHasMore = showMax < strongSelf.resoucesTotal
//                    strongSelf.resoucesPage += 1
//                    result(list ,strongSelf.resourceHasMore ,total, nil )
//                }
//
//            case .failure(let code, _):
//                result(nil , true , 0, R.string.localizable.failed_get_infomation(code))
//            }
//        }
//    }
//
//    func getHasResourcesTimes(start : TimeInterval , end : TimeInterval , filter : ADFilterMoodel? ,result : @escaping ((Set<String>) -> Void)) {
//        let mark : Int = filter?.isSelect(other: .mark) ?? false ? 1 : 0
//        let unread : Int = filter?.isSelect(other: .unread) ?? false ? 1 : 0
//        let tags : [String] = filter?.tags() ?? []
//
//        A4xNetManager.execute(reqMoudelType: A4xNetMoudelType.Library(.librarystatus(start: start, end: end , mark: mark , miss: unread , deviceId: filter?.devices() , tags: tags)), resModelType: ADLibaryDateResponse.self) { (res) in
//            var set : Set<String> = Set()
//            switch res {
//            case let .success(modle):
//                let list = modle?.list
//                list?.forEach({ (m) in
//                    if let date = m.date  {
//                        set.insert(date)
//                    }
//                })
//            case .failure(_, _):
//                A4xLog("")
//            }
//            result(set)
//        }
//    }
}

extension ADHomeViewModel: ADFFmpegMuxerDelegate {
    
    // 将m3u8链接拆分成子链接
    private func parseM3u(file: URL) throws {
//        adM3U8Model = ADM3U8DownloadModel()
//        let m3uName: String = file.deletingPathExtension().lastPathComponent
//        adM3U8Model?.url = file
//
//        let uri: URL = file.deletingLastPathComponent()
//        adM3U8Model?.uri = uri
//        adM3U8Model?.name = m3uName
//
//        guard let adUri = adM3U8Model?.uri else { throw WLError.m3uFileContentInvalid }
//        let m3uStr = try String(contentsOf: file)
//        let arr = m3uStr.components(separatedBy: "\n")
//        if let handler = tsURLHandler {
//            adM3U8Model?.tsArr = arr.compactMap { handler($0, adUri) }
//        } else {
//            adM3U8Model?.tsArr = arr
//                .filter { $0.range(of: ".ts") != nil } // $0.hasSuffix(".ts")
//                .map { $0.range(of: "http") != nil ? URL.init(string: $0)! : adUri.appendingPathComponent($0)} //adUri.appendingPathComponent($0)
//        }
//        if adM3U8Model?.tsArr?.isEmpty ?? true { throw WLError.m3uFileContentInvalid }
//        if adM3U8Model?.totalSize == 0 {
//            self.adM3U8Model?.totalSize = adM3U8Model?.tsArr?.count
//        }
    }
    
    // 计算m3u8的单位子任务下载量
    func m3u8DownLoadCount(by arr: [String]) {
        var tmpCount: [String : Int] = [:]
        for item in arr {
            if let x = tmpCount[item] {
                tmpCount[item] = x + 1
                continue
            }
            tmpCount[item] = 1
        }
        adM3U8DownloadTagDic = tmpCount
    }
    
//    // 合并任务入口
//    func ts2Conbine(task: Task, completion: CombineCompletion? = nil) -> Self {
////        combineCompletion = completion
////        operationQueue.addOperation {
////            self.doCombine(task: task)
////        }
//        return self
//    }
    
    // 合并操作
    private func doCombine(task: Task) {
//        let tagsArr = task.tags.allObjects
//        var model: ADM3U8DownloadModel?
//        if tagsArr.count > 0 {
//            let tag: String = tagsArr[0] as? String ?? "normalTasks"
//            model = resoucesADM3U8ModelsDic[tag]?.0
//        }
//
//        guard let name = model?.name,
//              let tsArr = model?.tsArr else { return }
//
//        let saveUrl = URL.init(string: task.filePath())
//        let savePath = saveUrl?.deletingLastPathComponent().urlStringValue ?? ""
//        // 获取路径下全部ts文件路径
//        //let tsFilePathArr = self.getAllFilePath(savePath, fileType: "ts")
//
//        // 合并路径
//        let combineFilePath = URL.init(string: task.manager?.configure.savePath ?? "")?.appendingPathComponent("Camera_\(name)").appendingPathExtension("ts").urlStringValue
//        FileManager.default.createFile(atPath: combineFilePath ?? "", contents: nil, attributes: nil)
//        let tsFilePaths = tsArr.map { savePath + $0.lastPathComponent }
//
//        dispatchQueue.async {
//            let fileHandle = FileHandle(forUpdatingAtPath: combineFilePath ?? "")
//            defer { fileHandle?.closeFile() }
//            // 合并ts核心操作
//            for tsFilePath in tsFilePaths {
//                if FileManager.default.fileExists(atPath: tsFilePath) {
//                    let data = try! Data(contentsOf: URL(fileURLWithPath: tsFilePath))
//                    fileHandle?.write(data)
//                }
//            }
//
//            do {
//                // 删除合并子任务目录及所有ts文件
//                try FileManager.default.removeItem(atPath: savePath)
//            } catch {
//                DispatchQueue.main.async {
//                    self.handleCompletion(of: "combine",
//                                          completion: self.combineCompletion,
//                                          result: .failure(.handleCacheFailed(error)))
//                }
//            }
//
//            DispatchQueue.main.async {
//                self.handleCompletion(of: "combine",
//                                      completion: self.combineCompletion,
//                                      result: .success(URL.init(string: combineFilePath ?? "")!))
//            }
//        }
    }
    
    // 完成合并回调 - 可封装成通用
//    func handleCompletion<T>(of task: String, completion: ((Result<T>) -> ())?, result: Result<T>) {
//        completion?(result)
//        switch result {
//        case .failure(let error):
//            operationQueue.cancelAllOperations()
//            debugPrint("---------> combine success \(error)")
//        case .success(let value):
//            operationQueue.isSuspended = false
//            debugPrint("---------> combine success \(value)")
//        }
//
//        if operationQueue.operationCount == 0 {
//            debugPrint("---------> combine done ")
//        }
//    }
    
    // 获取指定路径下，指定类型的所有文件
    func getAllFilePath(_ dirPath: String, fileType: String) -> [String]? {
        var filePaths: [String] = []
        do {
            let array = try FileManager.default.contentsOfDirectory(atPath: dirPath)
            for fileName in array {
                var isDir: ObjCBool = true
                let fullPath = "\(dirPath)\(fileName)"
                if FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDir) {
                    if !isDir.boolValue {
                        let fullUrl = URL.init(string: fullPath)
                        let pathExtension = fullUrl?.pathExtension
                        if ((pathExtension?.hasPrefix(fileType)) != nil) {
                            filePaths.append(fullPath)
                        }
                    }
                }
            }
        } catch let error as NSError {
            print("get file path error: \(error)")
        }
        return filePaths
    }
    
    // 转码
//    func ts2Mp4(videoPath: String, completion: CombineCompletion? = nil) -> Self {
//        combineCompletion = completion
//        let inputUrl = URL.init(fileURLWithPath: videoPath)
//        let newInputUrlURL = inputUrl.deletingPathExtension().appendingPathExtension("mp4")
//        let inputFileName = newInputUrlURL.lastPathComponent
//        let fileRootPath = "\(inputUrl.deletingLastPathComponent())".substring(from: 7)
//        let outputfilePath = "\(fileRootPath)Camera_\(inputFileName)"
//        ADFFmpegMuxer.sharedInstance().adFFmpegMuxerDelegate = self
//        ADFFmpegMuxer.sharedInstance().ts2Mp4(videoPath, outputPath: outputfilePath)
//        debugPrint("------------> ts2Mp4 end")
//        return self
//    }
    
    // 转码代理函数
    func ts2Mp4Result(_ status: KMMediaAssetExportSessionStatus, outputPath: String) {
        debugPrint("------------> 转码结果:\(status.rawValue)")
        if status == .completed {
            if (FileManager.default.fileExists(atPath: outputPath)) {
                if self.shareStatus ?? false {
                    if let resoublock = self.shareResouse {
                        resoublock(true ,.video, outputPath) {
                            do {
                                A4xLog("begin removeItem")
                                try FileManager.default.removeItem(at: URL(fileURLWithPath: outputPath))
                            } catch {
                                A4xLog("remove error")
                            }
                        }
                    }
                } else {
//                    self.saveVideoToPhotoAlbum(outputPath) { (res, info) in
//                        //saveComple(res,info)
//                    }
                }
            }
        }
    }
}


extension ADHomeViewModel{
    
    // 重置下载信息
    public func downloadReset() {
//        resoucesADM3U8Models.removeAll()
//        resoucesADM3U8ModelsDic.removeAll()
//        adM3U8DownloadDoneCountArr.removeAll()
//        adM3U8DownloadTagDic.removeAll()
//        adM3U8DownloadTagArr.removeAll()
//        adM3U8UnitCount = 0
    }
    
    /// download source
    ///
    /// - Parameter models: sources models
    public func downloadSource(models : [A4xLibraryVideoModel] ){
//        var normalTasks : Array<Dictionary<String,Any>> = Array()
//        var m3u8Tasks : Array<Dictionary<String,Any>> = Array()
//        downloadReset()
//        var m3u8Dic: [String : (ADM3U8DownloadModel,Int)] = [:]
//        for (_, data) in models.enumerated() { // 正式逻辑
//            if data.getMediaType() == .m3u8 { // 正式逻辑
//                //      for (index, data) in models.enumerated() { // 测试逻辑
//                //            if index % 2 == 0 { // 测试逻辑
//                // ts 拆分数组处理
//                do {
//                    // https://bucket-qa-video.metamorph.caifudamofang.com/5f31ee4d7e6346778ed9dcd819d2babb/360p/playback.m3u8
//                    //try parseM3u(file: URL.init(string: "https://dco4urblvsasc.cloudfront.net/811/81095_ywfZjAuP/game/1000kbps.m3u8")!)//
//                    try parseM3u(file: URL.init(string: data.source!)!)//
//                    adM3U8Model?.tsArr?.forEach({ (url) in
//                        let mediaType : MediaType = .video
//                        let m3uName: String = url.deletingPathExtension().lastPathComponent
//                        let info : Dictionary<String,Any> = [FKTaskInfoFileName: m3uName, FKTaskInfoURL : url.urlStringValue, FKTaskInfoUserInfo : ["sourceid" : data.cID! ], FKTaskInfoTags : ["m3u8Tasks_\(adM3U8Model?.name ?? "normal")"], FKTaskInfoDescribe : data.cName ?? "unknow" , FKTaskInfoMediaType : mediaType.rawValue]
//                        m3u8Tasks.append(info)
//                    })
//
//                    m3u8Dic["m3u8Tasks_\(adM3U8Model?.name ?? "normal")"] = (adM3U8Model ?? ADM3U8DownloadModel(), adM3U8Model?.tsArr?.count ?? 0)
//                    let repeatArr = resoucesADM3U8Models.filter { $0.0.name == adM3U8Model?.name}
//                    if repeatArr.count == 0 {
//                        resoucesADM3U8Models.append((adM3U8Model ?? ADM3U8DownloadModel(),adM3U8Model?.tsArr?.count ?? 0))
//                    }
//                } catch {
//                    debugPrint("------------> m3u8 解析失败")
//                }
//            } else {
//                let mediaType : MediaType = data.getType() == .video ? .video : .audio
//
//                let info : Dictionary<String,Any> = [FKTaskInfoURL : data.source!, FKTaskInfoUserInfo : ["sourceid" : data.cID! ], FKTaskInfoTags : ["normalTasks"], FKTaskInfoDescribe : data.cName ?? "unknow" , FKTaskInfoMediaType : mediaType.rawValue,]
//                normalTasks.append(info)
//            }
//        }
//
//        resoucesADM3U8ModelsDic = m3u8Dic
//        Downloader.shared().addTasks(with: m3u8Tasks)
//        Downloader.shared().addTasks(with: normalTasks)
//        Downloader.shared().startWithAll()
    }
    
    
    /// add download listener
    ///
    /// - Parameters:
    ///   - result: current download info (_ downloadIndex : Int , _ total: Int , _ progress : Float , _ describe : String)
    ///   - manageComple: download comple block
    ///   - taskResult: task progress
//    public func addDownloadListenter (result : @escaping (_ downloadIndex : Int , _ total: Int , _ progress : Float , _ describe : String) -> Void ,
//                                      manageComple : @escaping (Bool) -> Void,
//                                      taskResult  : @escaping (Bool) -> Void){
//        var compleNumber : Int32 = 0
//        weak var weakSelf = self
//
//        Downloader.shared().queueUpdateBlock = {(tasks,total,wait,complete, error) in
//            A4xLog(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
//            A4xLog("task \(tasks) \nwait \(wait)\ntotal \(total)\ncomplete \(complete)\nerror \(error)")
//            A4xLog("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
//            let task = tasks.first
//            let name : String? = task?.describe
//
//            // 计算整体m3u8任务数量
//            let totalValue = weakSelf?.resoucesADM3U8Models.reduce(0) {
//                $0 + $1.1
//            }
//
//            let tagsArr = tasks.first?.tags.allObjects
//            if tagsArr?.count ?? 0 > 0 {
//                let tag: String = tagsArr?[0] as? String ?? "normalTasks"
//                weakSelf?.adM3U8DownloadTagArr.append(tag) // 根据tag数判断下载数量
//                weakSelf?.m3u8DownLoadCount(by: weakSelf?.adM3U8DownloadTagArr ?? []) // 统计tag数量
//
//                if tag.hasPrefix("m3u8Tasks") {
//                    // 判断具体标签是否下载完毕，下载完毕 +1、合并、存储
//
//                    // 当前tag标签子任务总数
//                    let unitSum: Int = weakSelf?.resoucesADM3U8ModelsDic[tag]?.1 ?? 0
//                    // 子任务已经下载数 old
//                    //let singleDoneCount: Int = weakSelf?.adM3U8DownloadTagDic[tag] ?? 0
//                    // 子任务已经下载数 new
//                    let saveUrl = URL.init(string: task?.filePath() ?? "unknow")
//                    let savePath = saveUrl?.deletingLastPathComponent().urlStringValue ?? ""
//                    let arr = weakSelf?.getAllFilePath(savePath, fileType: "ts")
//                    let singleDoneCount: Int = (arr?.count ?? 0) + 1
//
//                    // 子任务是否下载完毕
//                    let unitAchieve: Int = unitSum - singleDoneCount > 0 ? 0 : 1
//                    // 子任务全部下载完毕
//                    if unitAchieve == 1 {
//                        weakSelf?.adM3U8UnitCount += 1
//                    }
//
//                    // 判断tag 子任务已经下载是否存在
//                    let repeatArr = weakSelf?.adM3U8DownloadDoneCountArr.filter { $0.0 == tag}
//                    if repeatArr?.count == 0 {
//                        // 新的 tag
//                        weakSelf?.adM3U8DownloadDoneCountArr.append((tag,singleDoneCount - (unitAchieve == 0 ? 1 : 0)))
//                    } else {
//                        // 已有的 tag 下载数量更新
//                        weakSelf?.adM3U8DownloadDoneCountArr.removeAll {
//                            $0.0 == tag
//                        }
//                        weakSelf?.adM3U8DownloadDoneCountArr.append((tag,singleDoneCount - (unitAchieve == 0 ? 1 : 0)))
//                    }
//
//                    // 累加所有tag的数量
//                    let m3u8DoneCount = weakSelf?.adM3U8DownloadDoneCountArr.reduce(0) {
//                        $0 + $1.1
//                    }
//
//                    // 展示层回调
//                    task?.progressBlock = { progres in
//                        // 下载进度计算：（已下载子任务数 + 当前任务进度) / 总单元任务数
//                        let subProgress = (Float(singleDoneCount - 1) + Float(progres.progress.fractionCompleted)) / Float(unitSum)
//                        // 下载中任务数、下载总任务数、下载进度
//                        result(Int(complete + 1) - (m3u8DoneCount ?? 0) + (weakSelf?.adM3U8UnitCount ?? 0), Int(total) - (totalValue ?? 0) + (weakSelf?.resoucesADM3U8Models.count ?? 0), subProgress, name ?? "unknow")
//                    }
//
//                } else {
//                    // mp4 处理
//
//                    // 累加所有tag的数量
//                    let m3u8DoneCount = weakSelf?.adM3U8DownloadDoneCountArr.reduce(0) {
//                        $0 + $1.1
//                    }
//
//                    // 展示层回调
//                    task?.progressBlock = { progres in
//
//                        result(Int(complete + 1) - (m3u8DoneCount ?? 0) + (weakSelf?.adM3U8UnitCount ?? 0), Int(total) - (totalValue ?? 0) + (weakSelf?.resoucesADM3U8Models.count ?? 0), Float(progres.progress.fractionCompleted) , name ?? "unknow")
//                    }
//                }
//
//                // m3u8 和 mp4 通用逻辑
//            } else {
//                // old
//                task?.progressBlock = { progres in
//                    result(Int(complete + 1) , Int(total), Float(progres.progress.fractionCompleted) , name ?? "unknow")
//                }
//            }
//
//            tasks.first?.statusBlock = { task in
//                if task.status == .unknowError {
//                    taskResult(false)
//                    weakSelf?.taskError(task: task)
//                    A4xLog("===================tasks error======================")
//                } else if task.status == .finish {
//                    A4xLog("===================tasks finish======================")
//                    let tagsArr = task.tags.allObjects
//                    if tagsArr.count > 0 {
//                        let tag: String = tagsArr[0] as? String ?? "normalTasks"
//                        if tag.hasPrefix("m3u8Tasks") {
//                            // m3u8 处理
//
//                            // 判断task子任务是否全下载完成
//                            // 是，合成ts、转码、保存到相册
//
//                            // 当前tag标签子任务总数
//                            let unitSum: Int = weakSelf?.resoucesADM3U8ModelsDic[tag]?.1 ?? 0
//                            // 子任务已经下载数 old
//                            //let singleDoneCount: Int = weakSelf?.adM3U8DownloadTagDic[tag] ?? 0
//                            // 子任务已经下载数 new
//                            let saveUrl = URL.init(string: task.filePath())
//                            let savePath = saveUrl?.deletingLastPathComponent().urlStringValue ?? ""
//                            let arr = weakSelf?.getAllFilePath(savePath, fileType: "ts")
//                            let singleDoneCount: Int = arr?.count ?? 0
//
//                            debugPrint("----------------->task m3u8Tasks 总任务数:\(unitSum) 已经完成子任务:\(singleDoneCount)")
//                            debugPrint("----------------->task m3u8Tasks 还剩子任务:\(unitSum - singleDoneCount)")
//                            //debugPrint("----------------->task m3u8Tasks 任务位置:\(task.filePath())")
//                            if unitSum - singleDoneCount == 0 {
//                                // 开始合成
//                                weakSelf?.ts2Conbine(task: task) { (result) in
//                                    switch result {
//                                    case .success(let url):
//                                        print("[Combine Success] " + url.path)
//                                        weakSelf?.shareStatus = task.userInfo?["share"] as? Bool ?? false
//                                        weakSelf?.ts2Mp4(videoPath: url.path)
//                                    case .failure(let error):
//                                        print("[Combine Failure] " + error.localizedDescription)
//                                    }
//                                }
//                                compleNumber += 1
//                            }
//                            // 否，继续等待
//                        } else {
//                            // mp4 处理
//                            compleNumber += 1
//                            weakSelf?.taskDone(task: task, saveComple: { (falg, message) in
//                                taskResult(falg)
//                            })
//                        }
//                    } else {
//                        // old
//                        compleNumber += 1
//                        // Downloader.shared().remove(task.url)
//                        weakSelf?.taskDone(task: task, saveComple: { (falg, message) in
//                            taskResult(falg)
//                        })
//                    }
//                } else {
//                    A4xLog("===================tasks status \(task.status)======================")
//                }
//            }
//        }
//
//        Downloader.shared().downloadEndBlock = {
//            A4xLog("===================downloadEndBlock======================")
//            DispatchQueue.main.a4xAfter(0.05, execute: {
//                Downloader.shared().removeWithAll()
//                manageComple(compleNumber > 0)
//            })
//        }
//    }
    
    
    /// remove download listener
    public func removeDownloadListenter() {
        Downloader.shared().queueUpdateBlock = {(tasks,total,wait,complete, error) in
        }
        Downloader.shared().downloadEndBlock = {}
    }
    
    /// stop all cancel and end tasks
    public func stopDownLoad() {
        Downloader.shared().cancelWithAll()
        Downloader.shared().removeWithAll()
    }
    
    
    /// share resource
    ///
    /// - Parameter modles: resource
//    public func shareDownloads(modles : [A4xLibraryVideoModel] , block : @escaping (Bool ,MediaType? ,String?,(@escaping ()->Void))->Void )  {
//        guard modles.count > 0 else {
//            block(false, nil , nil){}
//            return
//        }
//        let shareModel = modles.first
//        guard shareModel?.source != nil else {
//            block(false, nil , nil){}
//            return
//        }
//
//        self.shareResouse = block
//        self.shareURL = shareModel?.source
//        let task =  Downloader.shared().acquire(shareModel!.source!)
//        if let task = task {
//            var userInfo = task.userInfo ?? [:]
//            userInfo["share"] = true
//            userInfo["sourceid"] = shareModel?.cID! ?? "unkownid"
//            task.userInfo = userInfo
//            Downloader.shared().moveTaskFirst(task.url)
//        }else {
//            var tasks : Array<Dictionary<String,Any>> = Array()
//
//            self.downloadReset()
//            var m3u8Dic: [String : (ADM3U8DownloadModel,Int)] = [:]
//            if shareModel?.getMediaType() == .m3u8 {
//                // ts 拆分数组处理
//                do {
//                    try parseM3u(file: URL.init(string: (shareModel?.source!)!)!)
//                    adM3U8Model?.tsArr?.forEach({ (url) in
//                        let mediaType : MediaType = .video
//                        let m3uName: String = url.deletingPathExtension().lastPathComponent
//                        let info : Dictionary<String,Any> = [FKTaskInfoFileName: m3uName, FKTaskInfoURL : url.urlStringValue, FKTaskInfoUserInfo : ["share": true,"sourceid" : shareModel?.cID! ?? "unkownid"], FKTaskInfoTags : ["m3u8Tasks_\(adM3U8Model?.name ?? "normal")"], FKTaskInfoDescribe : shareModel?.cName ?? "unknow" , FKTaskInfoMediaType : mediaType.rawValue]
//                        tasks.append(info)
//                    })
//
//                    m3u8Dic["m3u8Tasks_\(adM3U8Model?.name ?? "normal")"] = (adM3U8Model ?? ADM3U8DownloadModel(), adM3U8Model?.tsArr?.count ?? 0)
//                    let repeatArr = resoucesADM3U8Models.filter { $0.0.name == adM3U8Model?.name}
//                    if repeatArr.count == 0 {
//                        resoucesADM3U8Models.append((adM3U8Model ?? ADM3U8DownloadModel(),adM3U8Model?.tsArr?.count ?? 0))
//                    }
//                } catch {
//
//                }
//            } else {
//                let mediaType : MediaType = shareModel?.getType() == .video ? .video : .audio
//                let info : Dictionary<String,Any> = [FKTaskInfoURL : shareModel!.source! , FKTaskInfoUserInfo : ["share" : true , "sourceid" : shareModel?.cID! ?? "unkownid"] , FKTaskInfoTags : ["normalTasks"], FKTaskInfoDescribe : shareModel?.cName ?? "unknow" , FKTaskInfoMediaType : mediaType]
//                tasks.append(info)
//            }
//
//            resoucesADM3U8ModelsDic = m3u8Dic
//            Downloader.shared().addTasks(with: tasks)
//            Downloader.shared().startWithAll()
//        }
        
//    }
    
    /// cancel share
//    public func shareCancel() {
//        guard let shareURL = self.shareURL else {
//            return
//        }
//        let task =  Downloader.shared().acquire(shareURL)
//
//        if let userIndo = task?.userInfo as? Dictionary<String,Any> {
//            if let isShare = userIndo["share"] as? Bool {
//                if isShare {
//                    Downloader.shared().cancel(shareURL)
//                }
//            }
//        }
//    }
    
    
    /// download error files
    ///
    /// - Parameter task: task
//    private func taskError(task : Task) {
//        DispatchQueue.global().async {
//            var shouldShare : Bool = false
//            if let shareURL = self.shareURL {
//                if task.url == shareURL {
//                    shouldShare = true
//                }
//            }
//            if let resoublock = self.shareResouse {
//                if shouldShare {
//                    resoublock(false , nil , nil) {}
//                }
//            }
//        }
//    }
    
    /// download done save files
    ///
    /// - Parameter task: task
//    private func taskDone(task : Task, saveComple : @escaping (Bool , String) -> Void) {
//        DispatchQueue.global().async {
//            let shouldShare : Bool = task.userInfo?["share"] as? Bool ?? false
//
//            if !shouldShare {
//                if (FileManager.default.fileExists(atPath: task.filePath())) {
//                    if task.mediaType == .video {
//                        // 判断是否是CB系列，是，转码；否，不转直接存
//                        if A4xUserDataHandle.Handle?.getDevice(deviceId: (task.userInfo?["sourceid"])! as! String)?.isDeviceCGB() ?? false {
//                            debugPrint("---------> CB 系列视频")
//                            // 视频转码处理
//                            let inputUrl = URL.init(fileURLWithPath: task.filePath())
//                            let inputFileName = inputUrl.lastPathComponent
//                            let fileRootPath = "\(inputUrl.deletingLastPathComponent())".substring(from: 7)
//                            let outputfilePath = "\(fileRootPath)Camera_\(inputFileName)"
//                            let isDone = ADFFmpegMuxer.turnMp4Video(task.filePath(),outputPath: outputfilePath)
//                            debugPrint("--------->turnMp4Video start:\(isDone)")
//                            if isDone == true {
//                                debugPrint("--------->turnMp4Video end:\(isDone)")
//                                // 删除转码前视频路径
//                                do {
//                                    A4xLog("---------> begin remove")
//                                    try FileManager.default.removeItem(at: URL(fileURLWithPath:task.filePath()))
//                                } catch {
//                                    A4xLog("---------> remove error")
//                                }
//                                self.saveVideoToPhotoAlbum(outputfilePath) { (res, info) in
//                                    saveComple(res,info)
//                                }
//                            }
//                        } else {
//                            self.saveVideoToPhotoAlbum(task.filePath()) { (res, info) in
//                                saveComple(res,info)
//                            }
//                        }
//                    } else {
//                        A4xBasePhotoManager.default().save(imagePath: task.filePath(), result: { (rest, error) in
//                            if rest {
//                                if !shouldShare {
//                                    do {
//                                        A4xLog("begin removeItem")
//                                        try FileManager.default.removeItem(at: URL(fileURLWithPath: task.filePath()))
//                                        saveComple(true , R.string.localizable.image_save_to_ablum())
//                                    }catch {
//                                        A4xLog("remove error")
//                                        saveComple(false , R.string.localizable.download_file_fail_and_try())
//                                    }
//                                }
//                            }else {
//                                A4xLog("save photo error")
//                                saveComple(false , R.string.localizable.download_file_fail_and_try())
//
//                            }
//                        })
//                    }
//
//                }
//            }
//
//            if shouldShare {
//                if let resoublock = self.shareResouse {
//                    // 分享视频转码处理
//                    // 判断是否是CB系列，是，转码；否，不转直接存
//                    if A4xUserDataHandle.Handle?.getDevice(deviceId: (task.userInfo?["sourceid"])! as! String)?.isDeviceCGB() ?? false {
//                        debugPrint("---------> CB 系列视频")
//                        // 视频转码处理
//                        let inputUrl = URL.init(fileURLWithPath: task.filePath())
//                        let inputFileName = inputUrl.lastPathComponent
//                        let fileRootPath = "\(inputUrl.deletingLastPathComponent())".substring(from: 7)
//                        let outputfilePath = "\(fileRootPath)Camera_\(inputFileName)"
//                        let isDone = ADFFmpegMuxer.turnMp4Video(task.filePath(),outputPath: outputfilePath)
//                        debugPrint("--------->turnMp4Video start:\(isDone)")
//                        if isDone == true {
//                            debugPrint("--------->turnMp4Video end:\(isDone)")
//                            // 删除转码前视频路径
//                            do {
//                                A4xLog("---------> begin remove")
//                                try FileManager.default.removeItem(at: URL(fileURLWithPath:task.filePath()))
//                            } catch {
//                                A4xLog("---------> remove error")
//                            }
//
//                            resoublock(true ,task.mediaType , outputfilePath) {
//                                do {
//                                    A4xLog("begin removeItem")
//                                    try FileManager.default.removeItem(at: URL(fileURLWithPath: task.filePath()))
//                                }catch {
//                                    A4xLog("remove error")
//                                }
//                            }
//                        }
//                    } else {
//                        resoublock(true ,task.mediaType , task.filePath()) {
//                            do {
//                                A4xLog("begin removeItem")
//                                try FileManager.default.removeItem(at: URL(fileURLWithPath: task.filePath()))
//                            }catch {
//                                A4xLog("remove error")
//                            }
//                        }
//                    }
//                }
//            }
//
//        }
//    }
    
    // 保存视频到相册
//    private func saveVideoToPhotoAlbum(_ videoPath: String, saveComple: @escaping (Bool , String) -> Void) {
//        A4xBasePhotoManager.default().save(videoPath: videoPath, result: { (rest, error) in
//            if rest {
//                do {
//                    A4xLog("begin removeItem")
//                    try FileManager.default.removeItem(at: URL(fileURLWithPath: videoPath))
//                    saveComple(true , R.string.localizable.image_save_to_ablum())
//                } catch {
//                    A4xLog("remove error")
//                    saveComple(false , R.string.localizable.download_file_fail_and_try())
//                }
//            } else {
//                A4xLog("save photo error")
//                saveComple(false , R.string.localizable.download_file_fail_and_try())
//            }
//        })
//    }
    
}
