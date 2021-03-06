Pod::Spec.new do |s|
  s.name         = "MKSocketSDK"    #存储库名称
  s.version      = "0.0.10"      #版本号，与tag值一致
  s.summary      = "SDK For Plug"  #简介
  s.description  = "SDK for config smart plug"  #描述
  s.homepage     = "https://github.com/MokoLife/mokoLifeSDK-iOS"      #项目主页，不是git地址
  s.license      = { :type => "MIT", :file => "LICENSE" }   #开源协议
  s.author             = { "lovexiaoxia" => "aadyx2007@163.com" }  #作者
  s.platform     = :ios, "9.0"                 #支持的平台和版本号
  s.ios.deployment_target = "9.0"
  s.frameworks   = "UIKit", "Foundation" #支持的框架
  s.source       = { :git => "https://github.com/MokoLife/mokoLifeSDK-iOS.git", :tag => "#{s.version}" }         #存储库的git地址，以及tag值
  s.requires_arc = true #是否支持ARC

  s.source_files = "SDK/MKSDKForDevice/*.{h,m}"

  s.dependency "CocoaAsyncSocket","~> 7.6.3"     #所依赖的第三方库，没有就不用写

end
