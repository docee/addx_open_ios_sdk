# Copyright (c) Facebook, Inc. and its affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

podspec = Pod::Spec.new do |s|
  s.name = 'A4xYogaKit'
  s.version="1.18.9"
  s.license =  { :type => 'MIT', :file => "LICENSE" }
  s.homepage = 'https://facebook.github.io/yoga/'
  s.documentation_url = 'https://facebook.github.io/yoga/docs/'

  s.summary = 'Yoga is a cross-platform layout engine which implements Flexbox.'
  s.description = 'Yoga is a cross-platform layout engine enabling maximum collaboration within your team by implementing an API many designers are familiar with, and opening it up to developers across different platforms.'

  s.authors = 'Facebook'
  s.source = { :git => 'http://192.168.31.7:7990/scm/ios/yogakit.git', :tag => s.version.to_s }
  s.platform = :ios
  s.ios.deployment_target = '8.0'
  s.ios.frameworks = 'UIKit'
  s.module_name = 'A4xYogaKit'
  s.dependency 'Yoga', '~> 1.14'
  # Fixes the bug related the xcode 11 not able to find swift related frameworks.
  # https://github.com/Carthage/Carthage/issues/2825
  # https://twitter.com/krzyzanowskim/status/1151549874653081601?s=21
  s.pod_target_xcconfig = {"LD_VERIFY_BITCODE": "NO"}
  s.source_files = 'Source/*.{h,m,swift}'
  s.public_header_files = 'Source/{YGLayout,UIView+Yoga}.h'
  s.private_header_files = 'Source/YGLayout+Private.h'
end

# See https://github.com/facebook/yoga/pull/366
podspec.attributes_hash["readme"] = "README.md"
podspec
