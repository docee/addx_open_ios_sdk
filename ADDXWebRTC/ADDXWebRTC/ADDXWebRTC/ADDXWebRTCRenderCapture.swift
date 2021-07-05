//
//  ADDXWebRTCRenderCapture.swift
//  ADAutoView
//
//  Created by Hao Shen on 6/30/20.
//

import Foundation
import UIKit
import WebRTC

#if arch(arm64)
class ADDXWebRTCRenderCapture: RTCMTLVideoView {
    let videoCapture = WebRTCVideoCapture.init()
    var captureImage = false
    var captureVideo = false
    var videoSize = Size.init(width: 0, height: 0)
    var lastFrameTime:Int64 = 0
    var grabImageDataFinishBlock: (() -> ())?
    var frameIndex: Int64 = -1
    var lastframeIndex: Int64 = -1
    
    var renderFirstFrameBlock : (()->Void)?
    
    func resetRender() {
        frameIndex = -1
        lastframeIndex = -1
    }
    
    func isRendering() -> Bool {
        if self.frameIndex < 0 {
            return false
        }
        if self.frameIndex > self.lastFrameTime {
            self.lastFrameTime = self.frameIndex
            return true
        }
        return false
    }
    
    func startCaptureImage(_ grabImageDataFinishCallback:(() -> Void)? = nil,_ completionCallback:((_ image: UIImage) -> Void)? = nil){
        self.grabImageDataFinishBlock = nil
        self.grabImageDataFinishBlock = grabImageDataFinishCallback
        self.startCaptureImage(completionCallback)
    }
    
    // 开始截屏
    func startCaptureImage(_ completionCallback:((_ image: UIImage) -> Void)? = nil){
        if self.captureImage {
            self.grabImageDataFinishBlock = nil
            return
        }
        self.videoCapture.captureImageFinishBlock = completionCallback
        self.captureImage = true
    }
    
    //将解码视频帧编码mp4
    func startCaptureVideo(path: URL) -> Bool{
        if self.videoSize.width * self.videoSize.width <= 0 {
            Log.vLog(level: .warning, "Render 视频尺寸未知")
            return false
        }
        var sucess = true
        sucess = self.videoCapture.configCaptureVideoInfo(url: path, size: self.videoSize)
        if sucess {
           sucess = self.videoCapture.startVideoCapture()
        }else{
            Log.vLog(level: .warning, "Render 配置编码器失败")
        }
        if sucess {
            self.captureVideo = true
        }else{
            Log.vLog(level: .error, "Render 启动录制失败")
        }
        
        return sucess
    }
    func stopCaptureVideo(_ completionCallback:((_ sucess: Bool, _ fileUrl:URL?) -> Void)? = nil){
        self.captureVideo = false
        self.videoCapture.stopVideoCapture { (suceess, url) in
            Log.vLog(level: .notice, "Render 保存视频完成")
            completionCallback?(suceess,url)
        }
    }
    //将h264视频流保存h264文件，
    func startCaptureH264Video(path: URL) -> Bool{
        if self.videoSize.width * self.videoSize.width <= 0 {
            Log.vLog(level: .warning, "Render 视频尺寸未知")
            return false
        }
        var sucess = true
        sucess = self.videoCapture.startH264VideoCapture(url: path)
        if sucess {
           sucess = self.videoCapture.startVideoCapture()
        }else{
            Log.vLog(level: .error, "Render 配置编码器失败")
        }
        if sucess {
            self.captureVideo = true
        }else{
            Log.vLog(level: .error, "Render 启动录制失败")
        }
        
        return sucess
    }
    func stopCaptureH264Video(_ completionCallback:((_ firstFrameTime: Int64, _ fileUrl:URL?) -> Void)? = nil){
        self.captureVideo = false
        self.videoCapture.stopH264VideoCapture { (firstFrameTime, url) in
            Log.vLog(level: .notice, "Render 保存视频完成")
            completionCallback?(firstFrameTime,url)
        }
    }
    override func setSize(_ size: CGSize) {
        self.videoSize = Size.init(width: Float(size.width), height: Float(size.height))
    }
    
    override func renderFrame(_ frame: RTCVideoFrame?) {
        self.frameIndex = self.frameIndex + 1
        if self.frameIndex == 1 {
            // 直播拿到首帧
            debugPrint("-----------> renderFrame1 func 直播拿到首帧")
            Log.vLog(level: .alert, "renderFrame func first alert2 💚❤️ step14-2")
            renderFirstFrameBlock?()
        }
        
        if self.captureImage {
            self.captureImage = false
            if frame != nil {
                self.grabImageDataFinishBlock?()
                self.grabImageDataFinishBlock = nil
                self.videoSize = Size.init(width: Float(frame!.width), height: Float(frame!.height))
                self.videoCapture.captureImage(frame: frame!)
            } else {
                Log.vLog(level: .error, "Render 待截取成图片的帧为空")
            }
        }else if self.captureVideo {
            //暂时不通过此种方式录像, 而是通过processEncode回调编码流录像
            //hevc编码方式下encodeFrame会导致app播放卡住1-2sec
            /*
            if frame != nil {
                self.videoSize = Size.init(width: Float(frame!.width), height: Float(frame!.height))
                self.videoCapture.encodeFrame(frame: frame!)
            } else {
                Log.vLog(level: .error, "Render 待编码帧为空")
            }
            */
        }
    }
    override func needProcessEncodeImage() -> Bool {
        return self.captureVideo
    }
    override func processEncode(_ image: RTCEncodedImage?) {
        if image == nil {
            return
        }
        self.videoCapture.writeH264Image(image: image!)
    }
}
#else
class ADDXWebRTCRenderCapture: RTCEAGLVideoView {
    let videoCapture = WebRTCVideoCapture.init()
    var captureImage = false
    var captureVideo = false
    var videoSize = Size.init(width: 0, height: 0)
    var lastFrameTime:Int64 = 0
    var grabImageDataFinishBlock: (() -> ())?
    var frameIndex: Int64 = -1
    var lastframeIndex: Int64 = -1
    
    
    var renderFirstFrameBlock : (()->Void)?
    
    func resetRender() {
        frameIndex = -1
        lastframeIndex = -1
    }
    
    
    func isRendering() -> Bool {
        if self.frameIndex < 0 {
            return false
        }
        if self.frameIndex > self.lastFrameTime {
            self.lastFrameTime = self.frameIndex
            return true
        }
        return false
    }
    
    func startCaptureImage(_ grabImageDataFinishCallback:(() -> Void)? = nil,_ completionCallback:((_ image: UIImage) -> Void)? = nil){
        self.grabImageDataFinishBlock = nil
        self.grabImageDataFinishBlock = grabImageDataFinishCallback
        self.startCaptureImage(completionCallback)
    }
    
    // 开始截屏
    func startCaptureImage(_ completionCallback:((_ image: UIImage) -> Void)? = nil){
        if self.captureImage {
            self.grabImageDataFinishBlock = nil
            return
        }
        self.videoCapture.captureImageFinishBlock = completionCallback
        self.captureImage = true
    }
    
    //将解码视频帧编码mp4
    func startCaptureVideo(path: URL) -> Bool{
        if self.videoSize.width * self.videoSize.width <= 0 {
            Log.vLog(level: .warning, "Render 视频尺寸未知")
            return false
        }
        var sucess = true
        sucess = self.videoCapture.configCaptureVideoInfo(url: path, size: self.videoSize)
        if sucess {
           sucess = self.videoCapture.startVideoCapture()
        }else{
            Log.vLog(level: .error, "Render 配置编码器失败")
        }
        if sucess {
            self.captureVideo = true
        }else{
            Log.vLog(level: .error, "Render 启动录制失败")
        }
        
        return sucess
    }
    
    func stopCaptureVideo(_ completionCallback:((_ sucess: Bool, _ fileUrl:URL?) -> Void)? = nil){
        self.captureVideo = false
        self.videoCapture.stopVideoCapture { (suceess, url) in
            Log.vLog(level: .notice, "Render 保存视频完成")
            completionCallback?(suceess,url)
        }
    }
    
    //将h264视频流保存h264文件，
    func startCaptureH264Video(path: URL) -> Bool{
        if self.videoSize.width * self.videoSize.width <= 0 {
            Log.vLog(level: .warning, "Render 视频尺寸未知")
            return false
        }
        var sucess = true
        sucess = self.videoCapture.startH264VideoCapture(url: path)
        if sucess {
            self.captureVideo = true
        }else{
            Log.vLog(level: .error, "Render 启动录制失败")
        }
        
        return sucess
    }
    
    func stopCaptureH264Video(_ completionCallback:((_ firstFrameTime: Int64, _ fileUrl:URL?) -> Void)? = nil){
        self.captureVideo = false
        self.videoCapture.stopH264VideoCapture { (firstFrameTime, url) in
            Log.vLog(level: .notice, "Render 保存视频完成")
            completionCallback?(firstFrameTime,url)
        }
    }
    
    override func setSize(_ size: CGSize) {
        self.videoSize = Size.init(width: Float(size.width), height: Float(size.height))
    }
    
    override func renderFrame(_ frame: RTCVideoFrame?) {
        if frame == nil {
            return
        }
        
        if self.lastFrameTime == frame!.timeStampNs {
            return
        }
        
        self.frameIndex = self.frameIndex + 1
        if self.frameIndex == 1 {
            // 直播拿到首帧
            debugPrint("-----------> renderFrame2 func 直播拿到首帧")
            renderFirstFrameBlock?()
            Log.vLog(level: .alert, "renderFrame func first alert1 💚❤️ step14-2")
        }
        self.lastFrameTime = frame!.timeStampNs

        if self.captureImage {
            self.captureImage = false
            self.grabImageDataFinishBlock?()
            self.grabImageDataFinishBlock = nil
            self.videoSize = Size.init(width: Float(frame!.width), height: Float(frame!.height))
            self.videoCapture.captureImage(frame: frame!)
            
        }else if self.captureVideo {
            self.videoSize = Size.init(width: Float(frame!.width), height: Float(frame!.height))
            self.videoCapture.encodeFrame(frame: frame!)
            
        }
    }
    
    override func needProcessEncodeImage() -> Bool {
        return self.captureVideo
    }
    
    override func processEncode(_ image: RTCEncodedImage?) {
        if image == nil {
            return
        }
        self.videoCapture.writeH264Image(image: image!)
    }
}

#endif

class ADDXWebRTCMediaProcess: NSObject {
    class func  mergeAudio(audioURL: URL, audioFirstFrameTime:CMTime , moviePathUrl: URL, movieFirstFrameTime: CMTime,_ completionCallback:((_ sucess: Bool) -> Void)? = nil) {
        var savePathUrl = moviePathUrl.deletingLastPathComponent()
        savePathUrl = savePathUrl.appendingPathComponent("tempTest")
        savePathUrl = savePathUrl.appendingPathExtension(moviePathUrl.pathExtension)
        let composition = AVMutableComposition()
        let trackVideo:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: CMPersistentTrackID())!
        let trackAudio:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: CMPersistentTrackID())!
        
        let videoAsset = AVURLAsset(url: moviePathUrl, options: nil)
        let audioAsset = AVURLAsset(url: audioURL, options: nil)

        let videos = videoAsset.tracks(withMediaType: AVMediaType.video)
        let audios = audioAsset.tracks(withMediaType: AVMediaType.audio)

        if videos.count > 0 && audios.count > 0{
            let assetTrackVideo:AVAssetTrack = videos[0]
            let assetTrackAudio:AVAssetTrack = audios[0]
            let audioDuration:CMTime = assetTrackAudio.timeRange.duration
            let audioStart:CMTime = audioFirstFrameTime
            let audioEnd:CMTime = CMTimeAdd(audioStart, audioDuration)

            let videoDuration:CMTime = assetTrackVideo.timeRange.duration
            let videoStart:CMTime = movieFirstFrameTime
            let videoEnd:CMTime = CMTimeAdd(videoStart, videoDuration)

            let mediaStart:CMTime = CMTimeMaximum(audioStart, videoStart)
            let mediaEnd:CMTime = CMTimeMinimum(audioEnd, videoEnd)
            
            let mediaCropDuration = CMTimeSubtract(mediaEnd, mediaStart)
            var audioCropDuration = mediaCropDuration
            var videoCropDuration = mediaCropDuration
            var audioCropStart = CMTimeSubtract(mediaStart, audioStart)
            var videoCropStart = CMTimeSubtract(mediaStart, videoStart)
            
            do {
                Log.vLog(level: .notice, "Render ADDXWebRTCMediaProcess crop compute video track crop start \(videoCropStart)   duration \(videoCropDuration)")
                
                if videoCropStart.seconds < 0 || videoCropStart.seconds >= videoDuration.seconds || videoCropDuration.seconds > videoDuration.seconds || videoCropDuration.seconds <= 0 {
                    videoCropStart = CMTime.zero
                    videoCropDuration = videoDuration
                }
                
                Log.vLog(level: .notice, "Render ADDXWebRTCMediaProcess video track real crop start \(videoCropStart)   duration \(videoCropDuration)")
                try  trackVideo.insertTimeRange(CMTimeRangeMake(start: videoCropStart, duration: videoCropDuration), of: assetTrackVideo, at: CMTime.zero)
            } catch  {

            }
            
            do {
                Log.vLog(level: .notice, "Render ADDXWebRTCMediaProcess crop compute audio track crop start \(audioCropStart)   duration \(audioCropDuration)")

                if audioCropStart.seconds < 0 || audioCropStart.seconds >= audioDuration.seconds || audioCropDuration.seconds > audioDuration.seconds || audioCropDuration.seconds <= 0 {
                    audioCropStart = CMTime.zero
                    audioCropDuration = audioDuration
                }
                Log.vLog(level: .notice, "Render ADDXWebRTCMediaProcess audio track  real crop start \(audioCropStart)   duration \(audioCropDuration)")
                try trackAudio.insertTimeRange(CMTimeRangeMake(start: audioCropStart, duration: audioCropDuration), of: assetTrackAudio, at: CMTime.zero)
            } catch  {

            }
        }
        let assetExport: AVAssetExportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough)!
        var type = AVFileType.mp4
        if moviePathUrl.path.hasSuffix("mov") {
            type = AVFileType.mov
        }
        assetExport.outputFileType = type
        assetExport.outputURL = savePathUrl
        assetExport.shouldOptimizeForNetworkUse = true
        assetExport.exportAsynchronously {
            switch assetExport.status {
            case AVAssetExportSession.Status.completed:
                do {
                    try FileManager.default.removeItem(atPath: moviePathUrl.path)
                } catch  {
                    Log.vLog(level: .error, "Render ADDXWebRTCMediaProcess 删除文件失败  \(moviePathUrl)")
                }
                do {
                    try FileManager.default.removeItem(atPath: audioURL.path)
                } catch  {
                    Log.vLog(level: .error, "Render ADDXWebRTCMediaProcess 删除文件失败  \(audioURL)")
                }
                do {
                    try  FileManager.default.moveItem(at: savePathUrl, to: moviePathUrl)

                } catch  {
                    Log.vLog(level: .error, "Render ADDXWebRTCMediaProcess 移动文件失败  \(savePathUrl) to \(moviePathUrl)")
                }
                Log.vLog(level: .notice, "Render ADDXWebRTCMediaProcess success")
                do {
                    try FileManager.default.removeItem(atPath: savePathUrl.path)
                } catch  {
                    Log.vLog(level: .error, "Render ADDXWebRTCMediaProcess 删除文件失败  \(savePathUrl)")
                }
                completionCallback?(true)
                break
            case  AVAssetExportSession.Status.exporting:
                Log.vLog(level: .error, "Render ADDXWebRTCMediaProcess exporting ---- \(String(describing: assetExport.error))")
                break
            case  AVAssetExportSession.Status.failed:
                Log.vLog(level: .error, "Render ADDXWebRTCMediaProcess failed ---- \(String(describing: assetExport.error))")
                completionCallback?(false)
                break
            case AVAssetExportSession.Status.cancelled:
                Log.vLog(level: .error, "Render ADDXWebRTCMediaProcess cancelled ---- \(String(describing: assetExport.error))")
                completionCallback?(false)
                break
            default:
                Log.vLog(level: .error, "Render ADDXWebRTCMediaProcess unknow error -----")
                completionCallback?(false)
                break
            }
            
        }
    }

}
