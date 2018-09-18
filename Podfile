source 'https://git.cloud.tencent.com/qcloud_u/cocopoads-repo'
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target 'TimeBank' do
  pod 'Pastel'
  pod 'Schedule', '~> 0.1'
  pod 'GrandTime'
  pod 'ZHRefresh'
  pod 'SwiftyUserDefaults', '4.0.0-alpha.1'
  pod 'Moya', '~> 11.0'
  pod 'PhoneNumberKit', '~> 2.1'
  pod 'KMNavigationBarTransition', '~> 1.1'
  pod 'CountryPickerView', '~> 2.1.0'
  pod 'IQKeyboardManagerSwift', '~> 6.0'
  pod 'ObjectMapper', '~> 3.2'
  pod 'moa', '~> 9.0'
  pod 'NVActivityIndicatorView', '~> 4.2'
  pod 'Reusable', '~> 4.0.2'
  pod 'ShadowView'
  pod 'Kingfisher'
  pod 'HydraAsync'
  pod 'SkeletonView'
  pod 'ViewAnimator'
  pod 'Tabman'
  pod 'SwiftWebVC', :git=>'https://github.com/tokenme/SwiftWebVC.git'
  pod 'EmptyDataSet-Swift'
  pod 'SnapKit'
  pod 'Presentr'
  pod 'swiftScan'
  pod 'SwipeCellKit', '2.4.3'
  pod 'TACCore'
  pod 'TACMessaging'
  pod 'TACCrash'
  pod 'FTPopOverMenu_Swift'
  pod 'PhotoSolution'
  pod 'Qiniu', '~> 7.1'
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

