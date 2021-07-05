#
# Be sure to run `pod lib lint A4xSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'A4xSDK'
  s.version          = '0.1.0'
  s.summary          = 'A short description of A4xSDK.'


  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/A4xSDK/A4xSDK'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'A4xSDK' => 'wjin@a4x.ai' }
  s.source           = { :git => 'http://192.168.31.7:7990/scm/swclien/a4xsdk.git', :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'
  
  s.source_files = 'A4xSDK/*.{swift}'
  #二级目录
  #s.subspec 'A4xSDK' do |a4xadk|
  #a4xadk.source_files = 'A4xSDK/*.{swift}'
  #end
  s.resource_bundles = {
    'A4xSDK' => ['A4xSDK/Assets/*.xcassets']
  }
  s.resource  = "A4xSDK.bundle"
  s.vendored_frameworks    =  'Frameworks/*.framework'
  s.xcconfig     = { 
    'ENABLE_BITCODE' => 'NO'
  }

end
