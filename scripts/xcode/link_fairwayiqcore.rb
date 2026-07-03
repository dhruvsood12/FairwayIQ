#!/usr/bin/env ruby
# Links the root-level FairwayIQCore Swift package into the FairwayIQ app
# target. Idempotent: safe to run again after the reference exists.
# Requires the xcodeproj gem (pinned 1.27.0 at introduction).

require "xcodeproj"

project_path = File.expand_path("../../FairwayIQ.xcodeproj", __dir__)
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |candidate| candidate.name == "FairwayIQ" }
abort "FairwayIQ target not found" unless target

package_reference = project.root_object.package_references.find do |reference|
  reference.isa == "XCLocalSwiftPackageReference"
end
unless package_reference
  package_reference = project.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
  package_reference.relative_path = "."
  project.root_object.package_references << package_reference
  puts "added local package reference"
end

product_dependency = target.package_product_dependencies.find do |dependency|
  dependency.product_name == "FairwayIQCore"
end
unless product_dependency
  product_dependency = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  product_dependency.product_name = "FairwayIQCore"
  target.package_product_dependencies << product_dependency
  puts "added FairwayIQCore product dependency"
end

linked = target.frameworks_build_phase.files.any? do |build_file|
  build_file.product_ref&.product_name == "FairwayIQCore"
end
unless linked
  build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  build_file.product_ref = product_dependency
  target.frameworks_build_phase.files << build_file
  puts "linked FairwayIQCore in the frameworks phase"
end

project.save
puts "saved #{project_path}"
