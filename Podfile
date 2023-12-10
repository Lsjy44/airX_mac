# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'
platform :macos, '13.1'

target 'AirXmac' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for AirXmac
  pod 'Alamofire'
  pod 'GoogleSignIn'
  pod 'GoogleSignInSwiftSupport'
  pod 'Starscream', '~> 4.0.0'
  
  target 'AirXmacTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'AirXmacUITests' do
    # Pods for testing
  end
end

post_install do |installer|
  puts "Postinstall"
  installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
          xcconfig_path = config.base_configuration_reference.real_path
          xcconfig = File.read(xcconfig_path)
          xcconfig_mod = xcconfig.gsub(/DT_TOOLCHAIN_DIR/, "TOOLCHAIN_DIR")
          File.open(xcconfig_path, "w") { |file| file << xcconfig_mod }
        end
    end
end
