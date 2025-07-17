#!/usr/bin/env ruby
require 'xcodeproj'

# Path to the Pods project
pods_project_path = 'Pods/Pods.xcodeproj'

# Path to the Runner project
runner_project_path = 'Runner.xcodeproj'

# Open the Pods project
pods_project = Xcodeproj::Project.open(pods_project_path)

# Apply recommended settings to the Pods project itself
pods_project.build_configurations.each do |config|
  # Apply Xcode recommended project settings
  config.build_settings['CLANG_ANALYZER_LOCALIZABILITY_NONLOCALIZED'] = 'YES'
  config.build_settings['CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING'] = 'YES'
  config.build_settings['CLANG_WARN_BOOL_CONVERSION'] = 'YES'
  config.build_settings['CLANG_WARN_COMMA'] = 'YES'
  config.build_settings['CLANG_WARN_CONSTANT_CONVERSION'] = 'YES'
  config.build_settings['CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS'] = 'YES'
  config.build_settings['CLANG_WARN_EMPTY_BODY'] = 'YES'
  config.build_settings['CLANG_WARN_ENUM_CONVERSION'] = 'YES'
  config.build_settings['CLANG_WARN_INFINITE_RECURSION'] = 'YES'
  config.build_settings['CLANG_WARN_INT_CONVERSION'] = 'YES'
  config.build_settings['CLANG_WARN_NON_LITERAL_NULL_CONVERSION'] = 'YES'
  config.build_settings['CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF'] = 'YES'
  config.build_settings['CLANG_WARN_OBJC_LITERAL_CONVERSION'] = 'YES'
  config.build_settings['CLANG_WARN_RANGE_LOOP_ANALYSIS'] = 'YES'
  config.build_settings['CLANG_WARN_STRICT_PROTOTYPES'] = 'YES'
  config.build_settings['CLANG_WARN_SUSPICIOUS_MOVE'] = 'YES'
  config.build_settings['CLANG_WARN_UNREACHABLE_CODE'] = 'YES'
  config.build_settings['CLANG_WARN__DUPLICATE_METHOD_MATCH'] = 'YES'
  config.build_settings['ENABLE_STRICT_OBJC_MSGSEND'] = 'YES'
  config.build_settings['GCC_NO_COMMON_BLOCKS'] = 'YES'
  config.build_settings['GCC_WARN_64_TO_32_BIT_CONVERSION'] = 'YES'
  config.build_settings['GCC_WARN_ABOUT_RETURN_TYPE'] = 'YES'
  config.build_settings['GCC_WARN_UNDECLARED_SELECTOR'] = 'YES'
  config.build_settings['GCC_WARN_UNINITIALIZED_AUTOS'] = 'YES'
  config.build_settings['GCC_WARN_UNUSED_FUNCTION'] = 'YES'
  config.build_settings['GCC_WARN_UNUSED_VARIABLE'] = 'YES'
  config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'YES'
  config.build_settings['DEAD_CODE_STRIPPING'] = 'YES'
  config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
 end

# Update build settings for all targets in Pods project
pods_project.targets.each do |target|
  target.build_configurations.each do |config|
    # Update to recommended settings
    config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'YES'
    config.build_settings['DEAD_CODE_STRIPPING'] = 'YES'
    config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO' # Disable sandboxing for build scripts
    
    # Enable Module Verifier for targets that define Clang modules
    if ['app_links', 'connectivity_plus', 'Flutter', 'flutter_secure_storage'].include?(target.name) ||
       target.name.include?('privacy') || target.name.include?('module')
      config.build_settings['CLANG_ENABLE_MODULE_DEBUGGING'] = 'YES'
      config.build_settings['CLANG_MODULES_AUTOLINK'] = 'YES'
    end
    
    # Disable Code Signing for specific targets
    if ['app_links', 'connectivity_plus', 'flutter_secure_storage'].include?(target.name)
      config.build_settings['CODE_SIGN_IDENTITY'] = ''
      config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
    end
  end
end

# Save the Pods project
pods_project.save

# Now handle the Runner project settings
begin
  runner_project = Xcodeproj::Project.open(runner_project_path)
  
  # Apply recommended settings to the Runner project itself
  runner_project.build_configurations.each do |config|
    config.build_settings['CLANG_ANALYZER_LOCALIZABILITY_NONLOCALIZED'] = 'YES'
    config.build_settings['CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING'] = 'YES'
    config.build_settings['CLANG_WARN_BOOL_CONVERSION'] = 'YES'
    config.build_settings['CLANG_WARN_COMMA'] = 'YES'
    config.build_settings['CLANG_WARN_CONSTANT_CONVERSION'] = 'YES'
    config.build_settings['CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS'] = 'YES'
    config.build_settings['CLANG_WARN_EMPTY_BODY'] = 'YES'
    config.build_settings['CLANG_WARN_ENUM_CONVERSION'] = 'YES'
    config.build_settings['CLANG_WARN_INFINITE_RECURSION'] = 'YES'
    config.build_settings['CLANG_WARN_INT_CONVERSION'] = 'YES'
    config.build_settings['CLANG_WARN_NON_LITERAL_NULL_CONVERSION'] = 'YES'
    config.build_settings['CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF'] = 'YES'
    config.build_settings['CLANG_WARN_OBJC_LITERAL_CONVERSION'] = 'YES'
    config.build_settings['CLANG_WARN_RANGE_LOOP_ANALYSIS'] = 'YES'
    config.build_settings['CLANG_WARN_STRICT_PROTOTYPES'] = 'YES'
    config.build_settings['CLANG_WARN_SUSPICIOUS_MOVE'] = 'YES'
    config.build_settings['CLANG_WARN_UNREACHABLE_CODE'] = 'YES'
    config.build_settings['CLANG_WARN__DUPLICATE_METHOD_MATCH'] = 'YES'
    config.build_settings['ENABLE_STRICT_OBJC_MSGSEND'] = 'YES'
    config.build_settings['GCC_NO_COMMON_BLOCKS'] = 'YES'
    config.build_settings['GCC_WARN_64_TO_32_BIT_CONVERSION'] = 'YES'
    config.build_settings['GCC_WARN_ABOUT_RETURN_TYPE'] = 'YES'
    config.build_settings['GCC_WARN_UNDECLARED_SELECTOR'] = 'YES'
    config.build_settings['GCC_WARN_UNINITIALIZED_AUTOS'] = 'YES'
    config.build_settings['GCC_WARN_UNUSED_FUNCTION'] = 'YES'
    config.build_settings['GCC_WARN_UNUSED_VARIABLE'] = 'YES'
    config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
  end
  
  # Find the Runner target
  runner_target = runner_project.targets.find { |t| t.name == 'Runner' }
  
  if runner_target
    runner_target.build_configurations.each do |config|
      # Remove Embed Swift Standard Libraries Setting as shown in the first screenshot
      config.build_settings.delete('EMBEDDED_CONTENT_CONTAINS_SWIFT')
      config.build_settings.delete('ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES')
      
      # Add other recommended settings with $(inherited) flag to avoid overriding CocoaPods settings
      config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = '$(inherited)'
      config.build_settings['DEAD_CODE_STRIPPING'] = '$(inherited)'
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
    end
  end
  
  # Save the Runner project
  runner_project.save
rescue => e
  puts "Error updating Runner project: #{e.message}"
end

puts "Project settings updated successfully!"
