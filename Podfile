source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target 'TimeBank' do
  pod 'Pastel'
  pod 'Schedule', '~> 0.1'
  pod 'GrandTime'
  pod 'ZHRefresh'
  pod 'SwiftEntryKit', '~> 0.2'
  pod 'StatusAlert', '~> 0.10.1'
  pod 'SwiftyUserDefaults', '4.0.0-alpha.1'
  pod 'Moya', '~> 11.0'
  pod 'PhoneNumberKit', '~> 2.1'
  pod 'KMNavigationBarTransition', '~> 1.1'
  pod 'SnapKit', '~> 4.0.0'
  pod 'CountryPickerView', '~> 2.1.0'
  pod 'IQKeyboardManagerSwift', '~> 6.0'
  pod 'ObjectMapper', '~> 3.2'
  pod 'moa', '~> 9.0'
  pod 'Toucan', '~> 1.0'
  pod 'NVActivityIndicatorView', '~> 4.2'
  pod 'Reusable', '~> 4.0.2'
  pod 'ShadowView'
  pod 'Kingfisher'
  pod 'HydraAsync'
  pod 'SkeletonView'
  pod 'ViewAnimator'
  pod 'Tabman'
  pod 'SwiftWebVC', :git=>'https://github.com/tokenme/SwiftWebVC.git'
end

post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
    config.build_settings.delete('CODE_SIGNING_ALLOWED')
    config.build_settings.delete('CODE_SIGNING_REQUIRED')
  end
end

