Pod::Spec.new do |spec|
  spec.name = 'AHLaunchCtl'
  spec.version = '0.2.1'
  spec.license = 'MIT'
  spec.summary = 'An LaunchD framework for OSX Cocoa apps'
  spec.homepage = 'https://github.com/eahrold/AHLaunchCtl'
  spec.authors  = { 'Eldon Ahrold' => 'eldonahrold@gmail.com' }
  spec.source   = { :git => 'https://github.com/eahrold/AHLaunchCtl.git', :tag => "v#{spec.version}", :submodules => true}
  spec.requires_arc = true
  spec.osx.deployment_target = '10.8'
  spec.frameworks = 'SystemConfiguration','ServiceManagement','Security'
  spec.public_header_files = 'AHLaunchCtl/*.h'
  spec.source_files = 'AHLaunchCtl/*.{h,m}'
end
