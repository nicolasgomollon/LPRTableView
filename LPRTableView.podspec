Pod::Spec.new do |spec|
  spec.name = "LPRTableView"
  spec.version = "1.0.1"
  spec.summary = "A drop-in replacement for UITableView and UITableViewController that supports long-press reordering of cells."
  spec.homepage = "https://github.com/nicolasgomollon/LPRTableView"
  spec.platform = :ios, "12.0"
  spec.swift_versions = ["5.0"]
  spec.author = "Nicolas Gomollon"
  spec.license = "MIT"
  spec.source = { :git => "https://github.com/nicolasgomollon/LPRTableView.git", :tag => "#{spec.version}" }
  spec.source_files = "*.swift"
  spec.exclude_files = "ReorderTest/**"
end