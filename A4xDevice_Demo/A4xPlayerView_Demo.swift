//
//  A4xPlayerView.swift
//  A4xBaseSDK_Demo
//
//  Created by addx-wjin on 2021/7/1.
//

import UIKit
import A4xBaseSDK
import A4xWebRTCSDK

protocol A4xPlayerView_DemoProtocol : class {
    func videoReconnectAction()
}


class A4xPlayerView_Demo: UIImageView {
    
    weak var `protocol` : A4xPlayerView_DemoProtocol? = nil
    
    var showVideoSpeed : Bool = false
    
    var videoSpeed : String? {
        didSet {
           
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.noneStyle()
        self.isUserInteractionEnabled = true

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    weak var videoView: UIView? {
        didSet {
            if oldValue != nil && oldValue?.superview != nil {
                oldValue?.removeFromSuperview()
            }
            
            if let view = videoView {
                view.backgroundColor = UIColor.clear
                self.insertSubview(view, at: 0)
                view.frame = self.bounds
                view.translatesAutoresizingMaskIntoConstraints = true
            }
        }
    }
    
    /// 视频播放状态
    var videoState: A4xPlayerStateType = .none(thumb: nil) {
        didSet {
            A4xLog("videoState: \(videoState)")
            self.videoStateUpdate()
        }
    }
    
 
    //MARK:- view 创建
    lazy var playBtn: UIButton = {
        let temp = UIButton()
        temp.setImage(bundleImageFromImageName("video_play@3x"), for: UIControl.State.normal)
        temp.addTarget(self, action: #selector(connectionVideoAction), for: .touchUpInside)
        self.addSubview(temp)
        temp.snp.makeConstraints({ (make) in
            make.centerX.equalTo(self.snp.centerX)
            make.centerY.equalTo(self.snp.centerY)
        })
        return temp
    }()

    func videoStateUpdate() {
        switch self.videoState {
        case .none(thumb: let img):
            self.image = img
            noneStyle()
        case .loading(thumb: let img):
            loadingStyle()
            self.image = img
        case .playing:
            playingStyle()
        case .paused(thumb: let img):
            pausedStyle()
            self.image = img
        case .finish:
            doneStyle()
        case .error( let error , _ ,let img ,let action  ,let tipIcon,_):
            errorStyle(error: error, thumb: img, reconnect: action?.title(), tipIcon: tipIcon)
            self.image = img
        case .unuse(thumb: let img, isFock: _):
            self.image = img
            break
        case .updating(let error, let img, let reconnect, let tipIcon):
            errorStyle(error: error, thumb: img, reconnect: reconnect, tipIcon: tipIcon)
            self.image = img
        case .pausedp2p(thumb: let img):
            self.image = img
            pausedStyle()
        }
    }
    
    private func noneStyle() {
        self.playBtn.isHidden = false
    }
    
    private func loadingStyle() {
       
    }
    
    private func playingStyle() {
        
        self.playBtn.isHidden = true
        self.videoView?.isHidden = false
    }
    
    private func doneStyle() {
        self.playBtn.isHidden = false
    }
    
    private func errorStyle(error : String ,thumb : UIImage?, reconnect : String? , tipIcon : UIImage?) {
        self.playBtn.isHidden = false
        
        if reconnect?.count ?? 0 > 0 {

        }
        
        if showVideoSpeed {
           
        }
    }
    
    private func pausedStyle() {
        self.playBtn.isHidden = false
    }
    
    @objc func connectionVideoAction() {
        self.protocol?.videoReconnectAction()
    }
    
    deinit {
        A4xLog("ADActivityZoneVideoControl deinit")
    }
    
}
