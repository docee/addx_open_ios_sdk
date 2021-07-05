//
//  WebRTCVideoWriter.swift
//  WebRTC-Demo
//
//  Created by Hao Shen on 6/9/20.
//  Copyright © 2020 Stas Seldin. All rights reserved.
//

import UIKit
import CoreVideo
import CoreMedia
import AVFoundation
import WebRTC
public struct Size {
    public let width:Float
    public let height:Float
    
    public init(width:Float, height:Float) {
        self.width = width
        self.height = height
    }
}


let NAL_UnDefine        = 0
let NAL_SLICE           = 1
let NAL_SLICE_DPA       = 2
let NAL_SLICE_DPB       = 3
let NAL_SLICE_DPC       = 4
let NAL_SLICE_IDR       = 5
let NAL_SEI             = 6
let NAL_SPS             = 7
let NAL_PPS             = 8
let NAL_AUD             = 9
let NAL_FILLER          = 12

class WebRTCVideoWriter: NSObject {
    private var url: URL?
    private var videoSize: Size?
    private var assetWriter: AVAssetWriter?
    private var videoWriteInput:AVAssetWriterInput?
    
    private var startTime:CMTime?
    private var isRecording:Bool = false
    private var videoEncodingIsFinished:Bool = false

    var mFormatDescription:CMFormatDescription? = nil
    
    func ffmpegMuxerH264ToMP4(h264file: String, mp4File: String) -> Bool{
        if h264file.count <= 0 || mp4File.count <= 0 {
            return false
        }
        return ADFFmpegMuxer.muxerMP4File(mp4File, withH264File: h264file, codecName: "h264")
    }
    func appendSampleBuffer(sampleBuffer: CMSampleBuffer){
        let frameTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        if (self.startTime == nil) {
            if (self.assetWriter!.status != .writing) {
                self.assetWriter!.startWriting()
            }
            self.assetWriter!.startSession(atSourceTime: frameTime)
            self.startTime = frameTime
        }
        guard (self.videoWriteInput!.isReadyForMoreMediaData) else {
            Log.vLog(level: .notice, "Had to drop a frame at time \(frameTime)")
            return
        }
    
        if !self.videoWriteInput!.append(sampleBuffer) {
            Log.vLog(level: .notice, "Problem appending sample buffer at time: \(frameTime)")
        }
    }

    func  finishWrite(_ completionCallback:(() -> Void)? = nil){
        self.isRecording = false
        if (self.assetWriter!.status == .completed || self.assetWriter!.status == .cancelled || self.assetWriter!.status == .unknown) {
                completionCallback?()
            return
        }
        if ((self.assetWriter!.status == .writing) && (!self.videoEncodingIsFinished)) {
            self.videoEncodingIsFinished = true
            self.videoWriteInput!.markAsFinished()
        }
        // Why can't I use ?? here for the callback?
        if let callback = completionCallback {
            self.assetWriter!.finishWriting(completionHandler: callback)
        } else {
            self.assetWriter!.finishWriting{}
            
        }
    }
    func createWriter(url: URL, videoSize:Size) -> Bool{
        self.url = url
        self.videoSize = videoSize
        do {
            try FileManager.default.removeItem(at: self.url!)
            
        } catch  {
            print("删除 url \(String(describing: self.url)) 失败")
        }
        do {
            var type = AVFileType.mp4
            if url.path.hasSuffix("mov") {
                type = AVFileType.mov
            }
             self.assetWriter = try AVAssetWriter.init(url: self.url!, fileType: type)
        } catch  {
            print("create movie writer faile")
        }
        
        if self.assetWriter == nil {
            return false
        }
        self.assetWriter!.movieFragmentInterval = CMTimeMakeWithSeconds(1.0, preferredTimescale: 1000)
        var localSettings:[String:AnyObject] = Dictionary.init()
        localSettings[AVVideoWidthKey] =  NSNumber.init(value: Float(videoSize.width))
        localSettings[AVVideoHeightKey] = NSNumber.init(value: Float(videoSize.height))
        localSettings[AVVideoCodecKey] =  AVVideoCodecH264 as NSString
        
        self.videoWriteInput = AVAssetWriterInput(mediaType:AVMediaType.video, outputSettings:localSettings)
        if self.videoWriteInput == nil {
            return false
        }
        self.videoWriteInput!.expectsMediaDataInRealTime = true
        
        if self.assetWriter!.canAdd(self.videoWriteInput!){
            self.assetWriter!.add(self.videoWriteInput!)
        }
        self.assetWriter!.add(self.videoWriteInput!)
        self.isRecording = true
        self.videoEncodingIsFinished = false
        return true
    }
}
