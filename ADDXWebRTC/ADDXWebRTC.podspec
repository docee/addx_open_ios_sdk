#
# Be sure to run `pod lib lint KYHomeModel.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ADDXWebRTC'
  s.version          = '0.2.2'
  s.summary          = 'A short description of ADDXWebRTC.'


  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/ADDXWebRTC/ADDXWebRTC'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ADDXWebRTC' => 'wjin@a4x.ai' }
  s.source           = { :git => 'http://192.168.31.7:7990/scm/swclien/webrtc-ios-demo.git', :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'

  # s.source_files = 'ADDXWebRTC/**/*'
  #二级目录
  s.subspec 'ADDXWebRTC' do |addxwebrtc|
    addxwebrtc.source_files = 'ADDXWebRTC/ADDXWebRTC/*.{swift,h,m,mm}'
    addxwebrtc.public_header_files = 'ADDXWebRTC/ADDXWebRTC/ADDXGenerateImage.h'
  end
  #二级目录
  s.subspec 'Extensions' do |extensons|
    extensons.source_files = 'ADDXWebRTC/Extensions/*.{swift}'
  end
  #二级目录
  s.subspec 'Services' do |services|
    services.source_files = 'ADDXWebRTC/Services/*.{swift,h,mm}'
    services.public_header_files = 'ADDXWebRTC/Services/ADDXWebRTC-Bridging-Header.h','ADDXWebRTC/Services/ADFFmpegMuxer.h'
    #三级目录
    services.subspec 'WebSocketProvider' do |websocketprovider|
      websocketprovider.source_files = 'ADDXWebRTC/Services/WebSocketProvider/*.{swift}'
    end
    #三级目录
    services.subspec 'GPAC4iOS' do |gpac4ios|
      gpac4ios.source_files = 'ADDXWebRTC/Services/GPAC4iOS/*.{swift,h,mm,m}'
      gpac4ios.private_header_files = 'ADDXWebRTC/Services/GPAC4iOS/*.{h}'
      #gpac4ios.exclude_files = 'ADDXWebRTC/Services/TS2MP4/*.{a}'
    end
    #三级目录
    services.subspec 'TS2MP4' do |ts2mp4|
      ts2mp4.source_files = 'ADDXWebRTC/Services/TS2MP4/*.{swift,h,mm,m}'
      ts2mp4.public_header_files = ['ADDXWebRTC/Services/TS2MP4/ADMediaAssetExportSession.h','ADDXWebRTC/Services/TS2MP4/KMMedia.h','ADDXWebRTC/Services/TS2MP4/KMMediaAsset.h','ADDXWebRTC/Services/TS2MP4/KMMediaFormat.h','ADDXWebRTC/Services/TS2MP4/KMMediaAsset.h','ADDXWebRTC/Services/TS2MP4/KMMediaAssetExportSession.h']
      #ts2mp4.exclude_files = 'ADDXWebRTC/Services/TS2MP4/*.{a}'
    end
    #三级目录
    services.subspec 'ffmpeg' do |ffmpeg|
      ffmpeg.private_header_files = ['ADDXWebRTC/Services/ffmpeg/include/**/*.{h}']
    end
    #三级目录
    services.subspec 'openssl' do |openssl|
      openssl.private_header_files = ['ADDXWebRTC/Services/openssl/include/**/*.{h}']
    end
    #三级目录
    services.subspec 'IJKMediaPlayer' do |ijkplayer|
      ijkplayer.source_files = ['ADDXWebRTC/Services/IJKMediaPlayer/*.{h,mm,m}','ADDXWebRTC/Services/IJKMediaPlayer/**/*.{h,mm,m,c}','ADDXWebRTC/Services/ijkmedia/ijkplayer/ijkavformat/*.{h,c}','ADDXWebRTC/Services/ijkmedia/ijkplayer/ijkavutil/*.{h,c,cpp}','ADDXWebRTC/Services/ijkmedia/ijkplayer/pipeline/*.{h,c}','ADDXWebRTC/Services/ijkmedia/ijkplayer/*.{h,c}','ADDXWebRTC/Services/ijkmedia/ijksdl/*.{h,c}','ADDXWebRTC/Services/ijkmedia/ijksdl/dummy/*.{h,c}','ADDXWebRTC/Services/ijkmedia/ijksdl/ffmpeg/**/*.{h,c}','ADDXWebRTC/Services/ijkmedia/ijksdl/gles2/**/*.{h,c,m}']
      #ijkplayer.private_header_files = ['ADDXWebRTC/Services/IJKMediaPlayer/*.{h}']
      ijkplayer.public_header_files = ['ADDXWebRTC/Services/IJKMediaPlayer/IJKMediaPlayback.h','ADDXWebRTC/Services/IJKMediaPlayer/IJKMPMoviePlayerController.h','ADDXWebRTC/Services/IJKMediaPlayer/IJKFFOptions.h','ADDXWebRTC/Services/IJKMediaPlayer/IJKFFMoviePlayerController.h','ADDXWebRTC/Services/IJKMediaPlayer/IJKAVMoviePlayerController.h','ADDXWebRTC/Services/IJKMediaPlayer/IJKMediaModule.h','ADDXWebRTC/Services/IJKMediaPlayer/IJKMediaPlayer.h','ADDXWebRTC/Services/IJKMediaPlayer/IJKNotificationManager.h','ADDXWebRTC/Services/IJKMediaPlayer/IJKKVOController.h','ADDXWebRTC/Services/IJKMediaPlayer/IJKSDLGLViewProtocol.h','ADDXWebRTC/Services/IJKMediaPlayer/IJKFFMonitor.h']
      ijkplayer.exclude_files = ['ADDXWebRTC/Services/ijkmedia/ijkplayer/ijkavformat/ijkioandroidio.c','ADDXWebRTC/Services/ijkmedia/ijkplayer/ijkavformat/ijkmediadatasource.c','ADDXWebRTC/Services/ijkmedia/ijksdl/ijksdl_extra_log.h','ADDXWebRTC/Services/ijkmedia/ijksdl/ijksdl_extra_log.c']
      ijkplayer.requires_arc = false
      ijkplayer.requires_arc = ['ADDXWebRTC/Services/IJKMediaPlayer/*','ADDXWebRTC/Services/IJKMediaPlayer/ijkmedia/ijkplayer/ios/pipeline/*','ADDXWebRTC/Services/IJKMediaPlayer/ijkmedia/ijkplayer/ios/*','ADDXWebRTC/Services/IJKMediaPlayer/ijkmedia/ijksdl/ios/*','ADDXWebRTC/Services/ijkmedia/ijkplayer/ijkavformat/*','ADDXWebRTC/Services/ijkmedia/ijkplayer/ijkavutil/*','ADDXWebRTC/Services/ijkmedia/ijkplayer/pipeline/*','ADDXWebRTC/Services/ijkmedia/ijkplayer/*','ADDXWebRTC/Services/ijkmedia/ijksdl/*','ADDXWebRTC/Services/ijkmedia/ijksdl/dummy/*','ADDXWebRTC/Services/ijkmedia/ijksdl/ffmpeg/**/*','ADDXWebRTC/Services/ijkmedia/ijksdl/gles2/**/*']
    end

  end
  s.vendored_frameworks    =  'Frameworks/frameworks/WebRTC.framework' #,'Frameworks/frameworks/FFmpeg.framework'
  #s.xcconfig     = { 'LIBRARY_SEARCH_PATHS' => "${PODS_ROOT}/#{s.name}/Frameworks/frameworks/FFmpeg.framework" }
  #s.xcconfig     = { 'LIBRARY_SEARCH_PATHS' => "${PODS_ROOT}/#{s.name}/Frameworks/frameworks/WebRTC.framework" }
  s.xcconfig     = { 
    #'LIBRARY_SEARCH_PATHS' => [
    #    "${PODS_ROOT}/#{s.name}/Frameworks/frameworks/WebRTC.framework"
    #],
    'HEADER_SEARCH_PATHS' => [
        "${PODS_ROOT}/../ADDXWebRTC/ADDXWebRTC/Services/ffmpeg/include",
        "${PODS_ROOT}/../ADDXWebRTC/ADDXWebRTC/Services/openssl/include",
        "${PODS_ROOT}/../ADDXWebRTC/ADDXWebRTC/Services/IJKMediaPlayer/ijkmedia",
        "${PODS_ROOT}/../ADDXWebRTC/ADDXWebRTC/Services/ijkmedia"
    ],
    'ENABLE_BITCODE' => 'NO'
  }
 

#  s.dependency 'GoogleWebRTC'
  s.dependency 'Starscream'
  s.frameworks = 'VideoToolBox'
# LIBRARY_SEARCH_PATHS
  s.vendored_libraries  = 'ADDXWebRTC/Services/TS2MP4/*.{a}', 'ADDXWebRTC/Services/GPAC4iOS/*.{a}','ADDXWebRTC/Services/ffmpeg/lib/*.{a}','ADDXWebRTC/Services/openssl/lib/*.{a}'
# s.vendored_library = 'ADDXWebRTC/Services/TS2MP4/*.a' , 'ADDXWebRTC/Services/GPAC4iOS/*.a'
  s.libraries =  'iconv', 'z'
#, '${PODS_ROOT}/ADDXWebRTC/ADDXWebRTC/ADDXWebRTC/Services/TS2MP4/libTS2MP4', '${PODS_ROOT}/ADDXWebRTC/ADDXWebRTC/ADDXWebRTC/Services/GPAC4iOS/libGPAC4iOS'
  s.dependency 'XCGLogger', '~> 7.0.1'
  s.dependency 'YYWebImage', '~>1.0.5'
end
