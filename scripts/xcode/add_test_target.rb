#!/usr/bin/env ruby
# Adds the FairwayIQTests unit-test bundle target hosted by the app and
# registers it in the shared scheme's test action. Idempotent: safe to run
# again after the target exists. Requires the xcodeproj gem (pinned 1.27.0
# at introduction).

require "xcodeproj"

project_path = File.expand_path("../../FairwayIQ.xcodeproj", __dir__)
project = Xcodeproj::Project.open(project_path)

app_target = project.targets.find { |candidate| candidate.name == "FairwayIQ" }
abort "FairwayIQ target not found" unless app_target

test_target = project.targets.find { |candidate| candidate.name == "FairwayIQTests" }
unless test_target
  test_target = project.new_target(:unit_test_bundle, "FairwayIQTests", :ios, "26.2")
  test_target.add_dependency(app_target)

  test_group = project.main_group["FairwayIQTests"]
  abort "FairwayIQTests group not found" unless test_group
  test_target.add_file_references(test_group.files)

  test_target.build_configurations.each do |config|
    settings = config.build_settings
    settings["TEST_HOST"] = "$(BUILT_PRODUCTS_DIR)/FairwayIQ.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/FairwayIQ"
    settings["BUNDLE_LOADER"] = "$(TEST_HOST)"
    settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.dhruvsood.FairwayIQTests"
    settings["PRODUCT_NAME"] = "$(TARGET_NAME)"
    settings["SWIFT_VERSION"] = "5.0"
    settings["SWIFT_DEFAULT_ACTOR_ISOLATION"] = "MainActor"
    settings["SWIFT_APPROACHABLE_CONCURRENCY"] = "YES"
    settings["IPHONEOS_DEPLOYMENT_TARGET"] = "26.2"
    settings["GENERATE_INFOPLIST_FILE"] = "YES"
    settings["CODE_SIGN_STYLE"] = "Automatic"
    settings["SWIFT_EMIT_LOC_STRINGS"] = "NO"
    settings["TARGETED_DEVICE_FAMILY"] = "1,2"
  end

  attributes = project.root_object.attributes["TargetAttributes"] ||= {}
  attributes[test_target.uuid] = { "TestTargetID" => app_target.uuid }

  puts "added FairwayIQTests target"
end

project.save

scheme_path = File.join(Xcodeproj::XCScheme.shared_data_dir(project_path), "FairwayIQ.xcscheme")
scheme = Xcodeproj::XCScheme.new(scheme_path)
already_testable = scheme.test_action.testables.any? do |testable|
  testable.buildable_references.any? { |reference| reference.target_name == "FairwayIQTests" }
end
unless already_testable
  testable = Xcodeproj::XCScheme::TestAction::TestableReference.new(test_target)
  scheme.test_action.add_testable(testable)
  scheme.save!
  puts "registered FairwayIQTests in the shared scheme"
end

puts "saved #{project_path}"
