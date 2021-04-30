Pod::Spec.new do |s|
    s.name         = "Flipper-Boost-iOSX"
    s.version      = "1.76.0.1.4"
    s.summary      = "Boost C++ libraries"
    s.homepage     = "https://github.com/priteshrnandgaonkar/boost-iosx"
    s.license      = "Boost Software License"
    s.author       = { "Pritesh Nandgaonkar" => "prit91@fb.com" }
    s.ios.deployment_target = "10.0"
    s.osx.pod_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.ios.pod_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
    s.static_framework = true
    s.source       = { :git => "https://github.com/priteshrnandgaonkar/boost-iosx.git", :tag => "#{s.version}" }

    s.header_mappings_dir = "frameworks/Headers"

    s.source_files = "frameworks/Headers/**/*.{h,hpp,ipp}"
    s.vendored_frameworks = "frameworks/boost_context.xcframework",  "frameworks/boost_filesystem.xcframework", "frameworks/boost_program_options.xcframework", "frameworks/boost_regex.xcframework", "frameworks/boost_system.xcframework", "frameworks/boost_thread.xcframework"

end
