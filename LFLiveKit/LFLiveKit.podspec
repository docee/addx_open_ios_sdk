
Pod::Spec.new do |s|

  s.name         = "LFLiveKit"
  s.version      = "2.6.1"
  s.summary      = "LaiFeng ios Live. LFLiveKit."
  s.homepage     = "https://github.com/chenliming777"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "chenliming" => "chenliming777@qq.com" }
  s.platform     = :ios, "7.0"
  s.ios.deployment_target = "7.0"
  s.source       = { :git => "https://github.com/LaiFengiOS/LFLiveKit.git", :tag => "#{s.version}" }
  s.source_files  = "LFLiveKit/**/*.{h,m,mm,cpp,c}"
  s.public_header_files = ['LFLiveKit/*.h', 'LFLiveKit/objects/*.h', 'LFLiveKit/configuration/*.h', 'LFLiveKit/capture/*.h']

  s.frameworks   = "UIKit", "AVFoundation", "CoreTelephony", "CoreMedia",  "Foundation", "AudioToolbox", "Security", "VideoToolbox", "SystemConfiguration",  "CoreVideo", "CoreGraphics", "CFNetwork"

  s.libraries = "c++", 'iconv', 'z', 'bz2'

  s.vendored_frameworks = 'LFLiveKit/lib/*.framework'
  s.vendored_library = 'LFLiveKit/EasyPusherLib/*.a' , 'LFLiveKit/lib/*.a'
  s.requires_arc = true
end
