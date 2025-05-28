# Uncomment the next line to define a global platform for your project
# platform :ios, '13.0'

target 'iOSSDKDemo' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for iOSSDKDemo
  # 约束布局
  pod 'SnapKit', '~> 5.6.0'
  # 图片选择
  pod 'TZImagePickerController'

end

target 'Presentation' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Presentation

end

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
       end
    end
  end
end
