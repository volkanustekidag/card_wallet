#!/usr/bin/env ruby
# Writes the pubspec.yaml version (e.g. 2.0.0+43) into every iOS target's
# MARKETING_VERSION / CURRENT_PROJECT_VERSION.
#
# Runner reads $(FLUTTER_BUILD_NAME)/$(FLUTTER_BUILD_NUMBER) from Info.plist,
# but the widget extension and the Watch app use their own build settings.
# App Store Connect rejects/warns when an embedded bundle's version differs
# from the host app (ITMS-90473), so keep them in lockstep.
#
# Usage: ruby tools/sync_ios_versions.rb   (requires the xcodeproj gem)

require "xcodeproj"

root = File.expand_path("..", __dir__)
line = File.readlines(File.join(root, "pubspec.yaml")).find { |l| l.start_with?("version:") }
abort "version: not found in pubspec.yaml" unless line
name, number = line.split(":", 2).last.strip.split("+")
abort "pubspec version must look like 1.2.3+45" if name.nil? || number.nil?

project = Xcodeproj::Project.open(File.join(root, "ios", "Runner.xcodeproj"))
project.targets.each do |target|
  target.build_configurations.each do |config|
    config.build_settings["CURRENT_PROJECT_VERSION"] = number
    config.build_settings["MARKETING_VERSION"] = name unless target.name == "Runner"
  end
end
project.save
puts "iOS targets set to #{name} (#{number})"
