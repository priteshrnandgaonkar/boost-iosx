Pod::Spec.new do |s|
    s.name         = "Flipper-Boost-iOSX"
    s.version      = "1.76.0.1.3"
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
    s.vendored_frameworks = "frameworks/boost_atomic.xcframework", "frameworks/boost_chrono.xcframework", "frameworks/boost_container.xcframework", "frameworks/boost_context.xcframework", "frameworks/boost_contract.xcframework", "frameworks/boost_coroutine.xcframework", "frameworks/boost_date_time.xcframework", "frameworks/boost_exception.xcframework", "frameworks/boost_fiber.xcframework", "frameworks/boost_filesystem.xcframework", "frameworks/boost_graph.xcframework", "frameworks/boost_iostreams.xcframework", "frameworks/boost_json.xcframework", "frameworks/boost_locale.xcframework", "frameworks/boost_log.xcframework", "frameworks/boost_log_setup.xcframework", "frameworks/boost_nowide.xcframework", "frameworks/boost_program_options.xcframework", "frameworks/boost_random.xcframework", "frameworks/boost_regex.xcframework", "frameworks/boost_serialization.xcframework", "frameworks/boost_stacktrace_basic.xcframework", "frameworks/boost_prg_exec_monitor.xcframework", "frameworks/boost_test_exec_monitor.xcframework", "frameworks/boost_unit_test_framework.xcframework", "frameworks/boost_thread.xcframework", "frameworks/boost_timer.xcframework", "frameworks/boost_type_erasure.xcframework", "frameworks/boost_system.xcframework", "frameworks/boost_wave.xcframework"

end
