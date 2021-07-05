//
//  WebRTCVideoCapture.swift
//  WebRTC-Demo
//
//  Created by Hao Shen on 5/27/20.
//  Copyright © 2020 Stas Seldin. All rights reserved.
//

import Foundation
import UIKit
import WebRTC

struct NaluUnit
{
    enum NaluUnitType {
        case undefine
        case slice
        case sliceDPA
        case sliceDPB
        case sliceDPC
        case sliceIDR
        case sei
        case sps
        case pps
        case aud
        case filter
    }
    let type: NaluUnitType //IDR or INTER：note：SequenceHeader is IDR too
    let size: Int //note: don't contain startCode
    var data: Data?//note: don't contain startCode
}


class WebRTCVideoCapture: NSObject {
    //编码的串行队列
    var captureImageFinishBlock: ((_ image:UIImage) -> ())?
    
    private let encodeQueue = DispatchQueue(label: "encodeQueue")
    private let capturePicQueue = DispatchQueue(label: "captureQueue")
    
    private var size:Size = Size.init(width: 0, height: 0)
    private var isRecording = false
    private var startTime:CMTime?
    private var lastFrameSecond: Double = -1.0
    private let MAX_Encode_Waite_Frame = 3
    private var current_can_encode_frame = 3
    //ms 单位
    private var startCaptureTime = -1
    private var endCaptureTime = -1
    
    private var encoder:RTCVideoEncoder?
    
    override init() {
        super.init()
    }
    //添加图片截取
    func captureImage( frame: RTCVideoFrame){
        Log.vLog(level: .notice, "captureImage 调用开始截屏")

        autoreleasepool {
            //异步调用,以免截图阻塞webrtc回调时间过长
            self.capturePicQueue.async {
            let tmpFrame = frame.newI420()
            //self.encodeQueue.sync { [weak self] in
                Log.vLog(level: .notice, tmpFrame)
                Log.vLog(level: .notice, "captureImage 开始截屏")
                //kCVPixelFormatType_420YpCbCr8PlanarFullRange I420
                //kCVPixelFormatType_420YpCbCr8BiPlanarFullRange NV12 CIImage支持
                
                let pixelBuffer = self.getNV12YUVPixelBuffer(frame: frame)
                Log.vLog(level: .notice, "captureImage 开始截屏 Buffer")
                if pixelBuffer == nil{
                    Log.vLog(level: .error, "captureImage 截屏失败 无法创建NV12 数据")
                    return
                }
                Log.vLog(level: .notice, "captureImage 开始截屏 CIImage")

                let coreImage = CIImage.init(cvPixelBuffer: pixelBuffer!)
                let ciContext = CIContext.init()
                let cgImage = ciContext.createCGImage(coreImage, from: coreImage.extent)
                Log.vLog(level: .notice, "captureImage 开始截屏 CIImage create")

                if cgImage != nil {
                    let image = UIImage.init(cgImage: cgImage!)
                    Log.vLog(level: .notice, "captureImage 截屏完成: \(image)")
                    self.captureImageFinishBlock?(image)
                    Log.vLog(level: .notice, "captureImage image.size: \(image.size)")
                } else {
                    Log.vLog(level: .error, "captureImage 截屏失败 无法转NV12成Image")
                }
            //}
        }
        }
    }
    
    private var writeHandle:FileHandle?
    private var url: URL?
    private var tmpH264Url: URL?
    private var videoWriter: WebRTCVideoWriter?
    //添加视频录制支持
    func configCaptureVideoInfo(url:URL, size:Size, fileType:AVFileType = AVFileType.mp4, liveVideo:Bool = false, settings:[String:AnyObject]? = nil) -> Bool{
        self.size = size
        self.url = url
        self.videoWriter = WebRTCVideoWriter.init()
        if self.videoWriter == nil {
            return false
        }
        var sucess = false
        sucess = self.videoWriter!.createWriter(url: url, videoSize: size)
        if !sucess {
            self.videoWriter = nil
        }
        return sucess
    }
    
    func startVideoCapture() -> Bool{
        self.isRecording = true
        
        return self.isRecording
    }
    
    private var currentFrameSecondTime:Double = -1.0
    func encodeFrame(frame: RTCVideoFrame) {
        if self.videoWriter == nil {
            return
        }
        autoreleasepool {
            let rtccvpixbuffer:RTCCVPixelBuffer = frame.buffer as! RTCCVPixelBuffer
            let pixelBuffer = rtccvpixbuffer.pixelBuffer
            let presentTime = CMTime.init(value: frame.timeStampNs, timescale: CMTimeScale(powf(10.0, 9.0)))
            var sampleBuffer: CMSampleBuffer? = nil
            var timimgInfo: CMSampleTimingInfo = CMSampleTimingInfo.init(duration: CMTime.indefinite, presentationTimeStamp: presentTime, decodeTimeStamp: CMTime.indefinite)
            var videoInfo: CMVideoFormatDescription? = nil

            CMVideoFormatDescriptionCreateForImageBuffer(allocator: nil,
                                                         imageBuffer: pixelBuffer,
                                                         formatDescriptionOut: &videoInfo)
            CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                               imageBuffer: pixelBuffer,
                                               dataReady: true,
                                               makeDataReadyCallback: nil,
                                               refcon: nil,
                                               formatDescription: videoInfo!,
                                               sampleTiming: &timimgInfo,
                                               sampleBufferOut: &sampleBuffer)
            if sampleBuffer == nil{
                return
            }
            self.encodeQueue.async {
                if !self.isRecording{
                    return
                }
                
                self.videoWriter?.appendSampleBuffer(sampleBuffer: sampleBuffer!)
            }
        }
    }
    func stopVideoCapture(_ completionCallback:((_ sucess: Bool, _ fileUrl:URL?) -> Void)? = nil){
        if !self.isRecording{
            completionCallback?(false,self.url)
            return
        }
        if self.videoWriter == nil {
            completionCallback?(false,self.url)
            return
        }
        self.encodeQueue.async {
            self.isRecording = false
            self.videoWriter?.finishWrite({
                completionCallback?(true, self.url)
            })
        }
            
    }
    private var firstFrameTime:Int64 = -1
    private var hasWriteFirstKeyFrame:Bool = false
    func startH264VideoCapture(url:URL) -> Bool{
        self.tmpH264Url = url
        self.firstFrameTime = -1
        self.hasWriteFirstKeyFrame = false
        //同步设置
        self.encodeQueue.sync {
            do {
                try FileManager.default.removeItem(at: url)
            } catch  {
                Log.vLog(level: .error, "startH264VideoCapture 删除H264目录失败: \(url)")
            }
           let create =  FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
            if create {
                do {
                    try self.writeHandle = FileHandle.init(forWritingTo: url)
                } catch {
                    Log.vLog(level: .error, "startH264VideoCapture 创建h264写文件hadle失败")
                }
                self.isRecording = true
            }else{
                Log.vLog(level: .error, "startH264VideoCapture 创建h264文件失败")
                self.isRecording = false
                self.writeHandle = nil
            }
        }
        if self.writeHandle == nil {
            self.isRecording = false
            return false
        }
        return self.isRecording
    }
    
    func writeH264Image(image: RTCEncodedImage) {
        if self.writeHandle == nil {
            return
        }
        autoreleasepool {
            //写文件
            let data = NSData.init(data: image.buffer)
            let frameType = image.frameType
            let frametime = image.timeStamp
            
            self.encodeQueue.async {
                if !self.isRecording{
                    return
                }
                if self.writeHandle != nil {
                    if self.hasWriteFirstKeyFrame {
                        self.writeHandle?.write(data as Data)
                    }else{
                        if frameType == .videoFrameKey {
                            self.writeHandle?.write(data as Data)
                            self.hasWriteFirstKeyFrame = true
                            self.firstFrameTime =  Int64(Double(frametime) * 100.0 / 9.0)
                        }
                    }
                }
            }
        }
    }
    func stopH264VideoCapture(_ completionCallback:((_ firstFrameTime: Int64, _ fileUrl:URL?) -> Void)? = nil){
        if !self.isRecording{
            completionCallback?(self.firstFrameTime,self.tmpH264Url)
            return
        }
        if self.writeHandle == nil {
            completionCallback?(self.firstFrameTime,self.tmpH264Url)
            return
        }
        self.encodeQueue.async {
            self.isRecording = false
            //停止写 关闭文件
            self.writeHandle?.closeFile()
            self.writeHandle = nil
            completionCallback?(self.firstFrameTime,self.tmpH264Url)
            self.firstFrameTime = -1
            self.hasWriteFirstKeyFrame = false
            self.tmpH264Url = nil
        }
    }
    
    func getNV12YUVPixelBuffer(frame: RTCVideoFrame) -> CVPixelBuffer?{
        let width = frame.width
        let height = frame.height
        var pixelBuffer:CVPixelBuffer? = nil
        let result = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(width),
                                         Int(height),
                                         kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
                                         nil,
                                         &pixelBuffer)
        if result != kCVReturnSuccess {
            Log.vLog(level: .error, "getNV12YUVPixelBuffer 创建buffer失败")
            return pixelBuffer
        }
        if pixelBuffer == nil {
            Log.vLog(level: .error, "getNV12YUVPixelBuffer 创建buffer失败")
            return pixelBuffer
        }
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let yuvbuffer = frame.buffer.toI420()
        let yDestPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer!, 0)
        
        var k = 0
        for  i in 0...height-1 {
            for  j in 0...width-1 {
                yDestPlane!.storeBytes(of: yuvbuffer.dataY[Int(j + i * yuvbuffer.strideY)], toByteOffset: k, as: UInt8.self)
                k += 1
            }
        }
        k = 0
        let uvDestPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer!, 1)
        for  i in 0...height/2 - 1 {
            for  j in 0...width/2 - 1 {
                uvDestPlane!.storeBytes(of: yuvbuffer.dataU[Int(j + i * yuvbuffer.strideU)], toByteOffset: k, as: UInt8.self)
                k += 1
                uvDestPlane!.storeBytes(of: yuvbuffer.dataV[Int(j + i * yuvbuffer.strideV)], toByteOffset: k, as: UInt8.self)
                k += 1
            }
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        return pixelBuffer!
    }
    
    func getI420YUVPixelBuffer(frame: RTCVideoFrame) -> CVPixelBuffer?{
        let width = frame.width
        let height = frame.height
        var pixelBuffer:CVPixelBuffer?
        let result = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(width),
                                         Int(height),
                                         kCVPixelFormatType_420YpCbCr8PlanarFullRange,
                                         nil,
                                         &pixelBuffer)
        if result != kCVReturnSuccess {
            Log.vLog(level: .error, "getI420YUVPixelBuffer 创建buffer失败")
            return pixelBuffer
        }
        
        if pixelBuffer == nil {
            Log.vLog(level: .error, "getI420YUVPixelBuffer 创建buffer失败")
            return pixelBuffer
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let yuvbuffer = frame.buffer.toI420()
        let yDestPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer!, 0)
        
        var k = 0
        for  i in 0...height-1 {
            for  j in 0...width-1 {
                yDestPlane!.storeBytes(of: yuvbuffer.dataY[Int(j + i * yuvbuffer.strideY)], toByteOffset: k, as: UInt8.self)
                k += 1
            }
        }
        
        k = 0
        let uDestPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer!, 1)
        for  i in 0...height/2 - 1 {
            for  j in 0...width/2 - 1 {
                uDestPlane!.storeBytes(of: yuvbuffer.dataU[Int(j + i * yuvbuffer.strideU)], toByteOffset: k, as: UInt8.self)
                k += 1
                
            }
        }
        
        k = 0
        let vDestPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer!, 2)
        for  i in 0...height/2 - 1 {
            for  j in 0...width/2 - 1 {
                vDestPlane!.storeBytes(of: yuvbuffer.dataV[Int(j + i * yuvbuffer.strideV)], toByteOffset: k, as: UInt8.self)
                k += 1
            }
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        return pixelBuffer!
    }
}


extension Date {
    
    /// 获取当前 秒级 时间戳 - 10位
    var timeStamp : Int {
        let timeInterval: TimeInterval = self.timeIntervalSince1970
        let timeStamp = Int(timeInterval)
        return (timeStamp)
    }
    
    /// 获取当前 毫秒级 时间戳 - 13位
    var milliStamp : Int64 {
        let timeInterval: TimeInterval = self.timeIntervalSince1970
        let millisecond = CLongLong(round(timeInterval*1000))
        return (millisecond)
    }
}

