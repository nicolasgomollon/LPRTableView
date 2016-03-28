Pod::Spec.new do |s|
  s.name = 'LPRTableView'
  s.version = '1.0.0'
  s.summary = 'A drop-in replacement for UITableView and UITableViewController that supports long-press reordering of cells.'
  s.homepage = 'https://github.com/nicolasgomollon/LPRTableView'
  s.platform = :ios, '8.0'
  s.author = 'Nicolas Gomollon'
  s.license = 'MIT'
  s.source = { :git => 'https://github.com/nicolasgomollon/LPRTableView.git', :tag => s.version }
  s.source_files = 'LPRTableView/*.swift'
  s.requires_arc = true
end
