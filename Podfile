source 'https://git.cloud.tencent.com/qcloud_u/cocopoads-repo'
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target 'TimeBank' do
  pod 'TMMSDK', :git=>'https://github.com/tokenme/TMMSDK.git', :tag=>'0.3.8'
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
  pod 'ShadowView', '~> 1.3'
  pod 'Kingfisher', '~> 4.10'
  pod 'HydraAsync'
  pod 'SkeletonView', :git=>'https://github.com/tokenme/SkeletonView.git', :tag=>'1.4.1'
  pod 'ViewAnimator', '~> 2.2'
  pod 'Tabman', '~> 1.10'
  pod 'EmptyDataSet-Swift', '~> 4.2'
  pod 'Presentr'
  pod 'swiftScan', :git=>'https://github.com/tokenme/swiftScan.git', :tag=>'1.1.7'
  pod 'SwipeCellKit'
  pod 'TACCore'
  pod 'TACMessaging'
  pod 'TACCrash'
  pod 'PhotoSolution', '~> 1.0.2'
  pod 'Qiniu'
  pod 'Charts'
  pod 'SKWebAPI'
  pod 'Siren'
  pod 'SwiftRater'
  pod 'DropDown'
  pod 'DynamicBlurView'
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

pre_install do |installer|
    puts "[TAC]-Running post installer"
    xcodeproj_file_name = "placeholder"
    Dir.foreach("./") do |file|
        if file.include?("xcodeproj")
            xcodeproj_file_name = file
        end
    end
    puts "[TAC]-project file is #{xcodeproj_file_name}"
    project = Xcodeproj::Project.open(xcodeproj_file_name)
    project.targets.each do |target|
        shell_script_after_build_phase_name = "[TAC] Run After Script"
        shell_script_before_build_phase_name = "[TAC] Run Before Script"
        puts "[TAC]-target.product_type is #{target.product_type}"
          if target.product_type.include?("application")
              should_insert_after_build_phases = 0
              should_insert_before_build_phases=0
              after_build_phase = nil
              before_build_phase = nil
              target.shell_script_build_phases.each do |bp|
                    if !bp.name.nil? and bp.name.include?(shell_script_after_build_phase_name)
                        should_insert_after_build_phases = 1
                        after_build_phase = bp
                    end
                    if !bp.name.nil? and bp.name.include?(shell_script_before_build_phase_name)
                        should_insert_before_build_phases = 1
                        before_build_phase = bp
                    end
              end


              if should_insert_after_build_phases == 1
                  puts "[TAC]-Build phases with the same name--#{shell_script_after_build_phase_name} has already existed"
              else
                  after_build_phase = target.new_shell_script_build_phase
                  puts "[TAC]-installing run afger build phases-- #{after_build_phase}"

              end
              after_build_phase.name = shell_script_after_build_phase_name
              after_build_phase.shell_script = "
              if [ -f \"${SRCROOT}/Pods/TACCore/Scripts/tac.run.all.after.sh\" ]; then
                  bash \"${SRCROOT}/Pods/TACCore/Scripts/tac.run.all.after.sh\"
              fi
              "
              after_build_phase.shell_path = '/bin/sh'
              if should_insert_before_build_phases == 1
                  puts "[TAC]-Build phases with the same name--#{shell_script_before_build_phase_name} has already existed"
                  else
                  before_build_phase = target.new_shell_script_build_phase
                  target.build_phases.insert(0,target.build_phases.pop)
                  puts "[TAC]-installing run before build phases-- #{before_build_phase}"

              end
              before_build_phase.name = shell_script_before_build_phase_name
              before_build_phase.shell_script = "
              if [ -f \"${SRCROOT}/Pods/TACCore/Scripts/tac.run.all.before.sh\" ]; then
                  bash \"${SRCROOT}/Pods/TACCore/Scripts/tac.run.all.before.sh\"
                  fi
                  "
              before_build_phase.shell_path = '/bin/sh'
         end
    end
    puts "[TAC]-Saving projects"
    project.save()
end

post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
    config.build_settings.delete('CODE_SIGNING_ALLOWED')
    config.build_settings.delete('CODE_SIGNING_REQUIRED')
  end
end

