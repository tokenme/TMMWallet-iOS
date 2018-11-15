source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target 'TimeBank' do
  pod 'TMMSDK', :git=>'https://github.com/tokenme/TMMSDK.git', :tag=>'0.5.0'
  pod 'Pastel', :git=>'https://github.com/cruisediary/Pastel.git', :tag=>'0.5.1'
  pod 'Schedule', '~> 1.0'
  pod 'GrandTime'
  pod 'ZHRefresh', :git=>'https://github.com/tokenme/ZHRefresh.git', :tag=>'0.2.1'
  pod 'SwiftyUserDefaults', '4.0.0-alpha.1'
  pod 'Moya'
  pod 'PhoneNumberKit'
  pod 'KMNavigationBarTransition'
  pod 'CountryPickerView'
  pod 'IQKeyboardManagerSwift'
  pod 'ObjectMapper'
  pod 'moa', '~> 10.0'
  pod 'BTNavigationDropdownMenu'
  pod 'Reusable'
  pod 'Kingfisher', '~> 4.10'
  pod 'HydraAsync'
  pod 'SkeletonView', :git=>'https://github.com/tokenme/SkeletonView.git', :tag=>'1.4.1'
  pod 'ViewAnimator', '~> 2.2'
  pod 'Tabman', '~> 1.10'
  pod 'EmptyDataSet-Swift', '~> 4.2'
  pod 'Presentr'
  pod 'swiftScan', :git=>'https://github.com/tokenme/swiftScan.git', :tag=>'1.1.7'
  pod 'SwipeCellKit'
  pod 'AssetsPickerViewController', :git=>'https://github.com/DragonCherry/AssetsPickerViewController.git', :tag=>'2.5.2'
  pod 'Qiniu'
  pod 'Charts'
  pod 'Siren'
  pod 'SwiftRater'
  pod 'DropDown'
  pod 'DynamicBlurView'
  pod 'MKRingProgressView'
  pod 'BiometricAuthentication'
  pod 'IKEventSource', :git=>'https://github.com/inaka/EventSource.git', :tag=>'2.2.0'
  pod 'FlexibleSteppedProgressBar', :git=>'https://github.com/tokenme/FlexibleSteppedProgressBar.git', :tag=>'0.5.1'
  pod 'SnapKit'
  pod 'Haptica'
  pod 'Peep'
  pod 'mob_sharesdk'
  pod 'mob_sharesdk/ShareSDKUI'
  pod 'mob_sharesdk/ShareSDKPlatforms/QQ'
  pod 'mob_sharesdk/ShareSDKPlatforms/SinaWeibo'
  pod 'mob_sharesdk/ShareSDKPlatforms/WeChat'
  pod 'mob_sharesdk/ShareSDKPlatforms/Facebook'
  pod 'mob_sharesdk/ShareSDKPlatforms/Line'
  pod 'mob_sharesdk/ShareSDKPlatforms/Twitter'
  pod 'mob_sharesdk/ShareSDKPlatforms/Telegram'
  pod 'mob_sharesdk/ShareSDKConfigFile'
  pod 'mob_sharesdk/ShareSDKExtension'
end

post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
    config.build_settings.delete('CODE_SIGNING_ALLOWED')
    config.build_settings.delete('CODE_SIGNING_REQUIRED')
  end
end

