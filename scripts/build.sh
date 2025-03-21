#!/bin/bash
set -e
echo 'build script'
################## SETUP BEGIN
HOST_ARC=$( uname -m )
XCODE_ROOT=$( xcode-select -print-path )
BOOST_VER=1.76.0
################## SETUP END
DEVSYSROOT=$XCODE_ROOT/Platforms/iPhoneOS.platform/Developer
SIMSYSROOT=$XCODE_ROOT/Platforms/iPhoneSimulator.platform/Developer
MACSYSROOT=$XCODE_ROOT/Platforms/MacOSX.platform/Developer

BOOST_NAME=boost_${BOOST_VER//./_}
BUILD_DIR="$( cd "$( dirname "./" )" >/dev/null 2>&1 && pwd )"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ ! -f "$BUILD_DIR/frameworks.built" ]; then

if [[ $HOST_ARC == arm* ]]; then
	BOOST_ARC=arm
elif [[ $HOST_ARC == x86* ]]; then
	BOOST_ARC=x86
else
	BOOST_ARC=unknown
fi

if [ ! -f $BOOST_NAME.tar.bz2 ]; then
	curl -L https://dl.bintray.com/boostorg/release/$BOOST_VER/source/$BOOST_NAME.tar.bz2 -o $BOOST_NAME.tar.bz2
fi
if [ ! -d boost ]; then
	echo "extracting $BOOST_NAME.tar.bz2 ..."
	tar -xf $BOOST_NAME.tar.bz2
	mv $BOOST_NAME boost
fi

if [ ! -f boost/b2 ]; then
	pushd boost
	./bootstrap.sh
	popd
fi

# ############### ICU
if [ ! -d $SCRIPT_DIR/Pods/icu4c-iosx/product ]; then
	pushd $SCRIPT_DIR
	pod install --verbose
	popd
	mkdir $SCRIPT_DIR/Pods/icu4c-iosx/product/lib
fi
ICU_PATH=$SCRIPT_DIR/Pods/icu4c-iosx/product
# ############### ICU

pushd boost

echo patching boost...

if [ ! -f tools/build/src/tools/gcc.jam.orig ]; then
	cp -f tools/build/src/tools/gcc.jam tools/build/src/tools/gcc.jam.orig
else
	cp -f tools/build/src/tools/gcc.jam.orig tools/build/src/tools/gcc.jam
fi
patch tools/build/src/tools/gcc.jam $SCRIPT_DIR/gcc.jam.patch

if [ ! -f tools/build/src/tools/features/instruction-set-feature.jam.orig ]; then
	cp -f tools/build/src/tools/features/instruction-set-feature.jam tools/build/src/tools/features/instruction-set-feature.jam.orig
else
	cp -f tools/build/src/tools/features/instruction-set-feature.jam.orig tools/build/src/tools/features/instruction-set-feature.jam
fi
patch tools/build/src/tools/features/instruction-set-feature.jam $SCRIPT_DIR/instruction-set-feature.jam.patch

if false; then
if [ ! -f tools/build/src/build/configure.jam.orig ]; then
	cp -f tools/build/src/build/configure.jam tools/build/src/build/configure.jam.orig
else
	cp -f tools/build/src/build/configure.jam.orig tools/build/src/build/configure.jam
fi
patch tools/build/src/build/configure.jam $SCRIPT_DIR/configure.jam.patch
fi

#LIBS_TO_BUILD="--with-locale "
# LIBS_TO_BUILD="--with-atomic --with-chrono --with-container --with-context --with-contract --with-coroutine --with-date_time --with-exception --with-fiber --with-filesystem --with-graph --with-iostreams --with-json --with-locale --with-log --with-math --with-nowide --with-program_options --with-random --with-regex --with-serialization --with-stacktrace --with-system --with-test --with-thread --with-timer --with-type_erasure --with-wave"

LIBS_TO_BUILD="--with-context --with-filesystem --with-program_options --with-regex --with-system --with-thread"

B2_BUILD_OPTIONS="release link=static runtime-link=shared define=BOOST_SPIRIT_THREADSAFE"

if true; then
if [ -d bin.v2 ]; then
	rm -rf bin.v2
fi
if [ -d stage ]; then
	rm -rf stage
fi
fi

if true; then
if [[ -f tools/build/src/user-config.jam ]]; then
	rm -f tools/build/src/user-config.jam
fi
cp $ICU_PATH/frameworks/icudata.xcframework/macos-$HOST_ARC/libicudata.a $ICU_PATH/lib/
cp $ICU_PATH/frameworks/icui18n.xcframework/macos-$HOST_ARC/libicui18n.a $ICU_PATH/lib/
cp $ICU_PATH/frameworks/icuuc.xcframework/macos-$HOST_ARC/libicuuc.a $ICU_PATH/lib/
./b2 -j8 --stagedir=stage/macosx cxxflags="-std=c++17" -sICU_PATH="$ICU_PATH" toolset=darwin address-model=64 architecture=$BOOST_ARC $B2_BUILD_OPTIONS $LIBS_TO_BUILD
# ./b2 -j8 --stagedir=stage/macosx cxxflags="-std=c++17" toolset=darwin address-model=64 architecture=$BOOST_ARC $B2_BUILD_OPTIONS $LIBS_TO_BUILD
rm -rf bin.v2
fi

if true; then
if [[ -f tools/build/src/user-config.jam ]]; then
	rm -f tools/build/src/user-config.jam
fi
echo "MACOS work"

cat >> tools/build/src/user-config.jam <<EOF
using darwin : catalyst : clang++ -arch $HOST_ARC --target=$BOOST_ARC-apple-ios13-macabi -isysroot $MACSYSROOT/SDKs/MacOSX.sdk -I$MACSYSROOT/SDKs/MacOSX.sdk/System/iOSSupport/usr/include/ -isystem $MACSYSROOT/SDKs/MacOSX.sdk/System/iOSSupport/usr/include -iframework $MACSYSROOT/SDKs/MacOSX.sdk/System/iOSSupport/System/Library/Frameworks
: <striper> <root>$MACSYSROOT
: <architecture>$BOOST_ARC
;
EOF
cp $ICU_PATH/frameworks/icudata.xcframework/ios-$HOST_ARC-maccatalyst/libicudata.a $ICU_PATH/lib/
cp $ICU_PATH/frameworks/icui18n.xcframework/ios-$HOST_ARC-maccatalyst/libicui18n.a $ICU_PATH/lib/
cp $ICU_PATH/frameworks/icuuc.xcframework/ios-$HOST_ARC-maccatalyst/libicuuc.a $ICU_PATH/lib/
./b2 -j8 --stagedir=stage/catalyst cxxflags="-std=c++17" -sICU_PATH="$ICU_PATH" toolset=darwin-catalyst address-model=64 architecture=$BOOST_ARC $B2_BUILD_OPTIONS $LIBS_TO_BUILD
# ./b2 -j8 --stagedir=stage/catalyst cxxflags="-std=c++17" toolset=darwin-catalyst address-model=64 architecture=$BOOST_ARC $B2_BUILD_OPTIONS $LIBS_TO_BUILD

rm -rf bin.v2
fi

if true; then
if [[ -f tools/build/src/user-config.jam ]]; then
	rm -f tools/build/src/user-config.jam
fi
echo "Building for iPhoneOS"

cat >> tools/build/src/user-config.jam <<EOF
using darwin : ios : clang++ -arch arm64 -fembed-bitcode-marker -isysroot $DEVSYSROOT/SDKs/iPhoneOS.sdk
: <striper> <root>$DEVSYSROOT
: <architecture>arm <target-os>iphone
;
EOF
cp $ICU_PATH/frameworks/icudata.xcframework/ios-arm64/libicudata.a $ICU_PATH/lib/
cp $ICU_PATH/frameworks/icui18n.xcframework/ios-arm64/libicui18n.a $ICU_PATH/lib/
cp $ICU_PATH/frameworks/icuuc.xcframework/ios-arm64/libicuuc.a $ICU_PATH/lib/
./b2 -j8 --stagedir=stage/ios cxxflags="-std=c++17" -sICU_PATH="$ICU_PATH" toolset=darwin-ios address-model=64 instruction-set=arm64 architecture=arm binary-format=mach-o abi=aapcs target-os=iphone define=_LITTLE_ENDIAN define=BOOST_TEST_NO_MAIN $B2_BUILD_OPTIONS $LIBS_TO_BUILD
# ./b2 -j8 --stagedir=stage/ios cxxflags="-std=c++17" toolset=darwin-ios address-model=64 instruction-set=arm64 architecture=arm binary-format=mach-o abi=aapcs target-os=iphone define=_LITTLE_ENDIAN define=BOOST_TEST_NO_MAIN $B2_BUILD_OPTIONS $LIBS_TO_BUILD
# ./b2 -j8 --stagedir=stage/ios architecture=combined cxxflags="-std=c++17 -arch arm64 -arch armv7 -arch armv7s -isysroot $DEVSYSROOT/SDKs/iPhoneOS.sdk" toolset=clang define=_LITTLE_ENDIAN binary-format=mach-o abi=aapcs define=BOOST_TEST_NO_MAIN $B2_BUILD_OPTIONS $LIBS_TO_BUILD

rm -rf bin.v2
fi

if true; then
if [[ -f tools/build/src/user-config.jam ]]; then
	rm -f tools/build/src/user-config.jam
fi

echo "Building artifacts for iPhoneSimulator"
# cat >> tools/build/src/user-config.jam <<EOF
# using darwin : iossim : clang++ -arch $HOST_ARC -arch arm64 -fembed-bitcode-marker -isysroot $SIMSYSROOT/SDKs/iPhoneSimulator.sdk
# : <striper> <root>$SIMSYSROOT
# ;
# EOF
# using darwin : iossim : clang++ -arch arm64 -fembed-bitcode-marker -isysroot $SIMSYSROOT/SDKs/iPhoneSimulator.sdk
# : <striper> <root>$SIMSYSROOT
# : <architecture>arm <target-os>iphone
# # : <architecture> $BOOST_ARC <target-os>iphone
# : <architecture>$BOOST_ARC <target-os>iphone

# cp $ICU_PATH/frameworks/icudata.xcframework/ios-$HOST_ARC-simulator/libicudata.a $ICU_PATH/lib/
# cp $ICU_PATH/frameworks/icui18n.xcframework/ios-$HOST_ARC-simulator/libicui18n.a $ICU_PATH/lib/
# cp $ICU_PATH/frameworks/icuuc.xcframework/ios-$HOST_ARC-simulator/libicuuc.a $ICU_PATH/lib/
# ./b2 -j8 --stagedir=stage/iossim cxxflags="-std=c++17" -sICU_PATH="$ICU_PATH" toolset=darwin-iossim address-model=64 architecture=$BOOST_ARC target-os=iphone define=BOOST_TEST_NO_MAIN $B2_BUILD_OPTIONS $LIBS_TO_BUILD
./b2 -j8 --stagedir=stage/iossim architecture=combined cxxflags="-std=c++17 -arch i386 -arch arm64 -arch x86_64 -isysroot $SIMSYSROOT/SDKs/iPhoneSimulator.sdk" toolset=clang define=_LITTLE_ENDIAN binary-format=mach-o abi=aapcs define=BOOST_TEST_NO_MAIN $B2_BUILD_OPTIONS $LIBS_TO_BUILD

rm -rf bin.v2
fi


# rm -rf arm64 x86_64 universal
# ./bootstrap.sh --with-toolset=clang --with-libraries=thread,system,filesystem,program_options,serialization
# ./b2  cxxflags="-arch arm64" toolset=darwin -a
# mkdir -p arm64 && cp stage/lib/*.dylib arm64
# ./b2 toolset=clang cxxflags="-arch arm64 -arch x86_64" -a
# mkdir x86_64 && cp stage/lib/*.dylib x86_64
# mkdir universal
# for dylib in arm64/*; do
#   lipo -create -arch arm64 $dylib -arch x86_64 x86_64/$(basename $dylib) -output universal/$(basename $dylib);
# done




# if true; then
# if [[ -f tools/build/src/user-config.jam ]]; then
# 	rm -f tools/build/src/user-config.jam
# fi

# echo "iPhoneSimulator work arm"
# cat >> tools/build/src/user-config.jam <<EOF
# using darwin : iossim : clang++ -arch arm64 -fembed-bitcode-marker -isysroot $SIMSYSROOT/SDKs/iPhoneSimulator.sdk
# : <striper> <root>$SIMSYSROOT
# : <architecture>arm <target-os>iphone
# ;
# EOF
# echo "finised iPhoneSimulator work"

# # : <architecture> $BOOST_ARC <target-os>iphone

# # cp $ICU_PATH/frameworks/icudata.xcframework/ios-$HOST_ARC-simulator/libicudata.a $ICU_PATH/lib/
# # cp $ICU_PATH/frameworks/icui18n.xcframework/ios-$HOST_ARC-simulator/libicui18n.a $ICU_PATH/lib/
# # cp $ICU_PATH/frameworks/icuuc.xcframework/ios-$HOST_ARC-simulator/libicuuc.a $ICU_PATH/lib/
# # ./b2 -j8 --stagedir=stage/iossim cxxflags="-std=c++17" -sICU_PATH="$ICU_PATH" toolset=darwin-iossim address-model=64 architecture=$BOOST_ARC target-os=iphone define=BOOST_TEST_NO_MAIN $B2_BUILD_OPTIONS $LIBS_TO_BUILD
# ./b2 -j8 --stagedir=stage/iossimarm cxxflags="-std=c++17" toolset=darwin-iossim address-model=64 architecture=arm target-os=iphone binary-format=mach-o abi=aapcs define=_LITTLE_ENDIAN define=BOOST_TEST_NO_MAIN $B2_BUILD_OPTIONS $LIBS_TO_BUILD

# rm -rf bin.v2
# fi

echo installing boost...
if [ -d "$BUILD_DIR/frameworks" ]; then
    rm -rf "$BUILD_DIR/frameworks"
fi

mkdir "$BUILD_DIR/frameworks"

build_xcframework()
{
	xcodebuild -create-xcframework  -library stage/macosx/lib/lib$1.a -library stage/catalyst/lib/lib$1.a -library stage/ios/lib/lib$1.a -library stage/iossim/lib/lib$1.a -output "$BUILD_DIR/frameworks/$1.xcframework"
}
# -library stage/macosx/lib/lib$1.a -library stage/catalyst/lib/lib$1.a -library stage/ios/lib/lib$1.a
if true; then
# build_xcframework boost_atomic
# build_xcframework boost_chrono
# build_xcframework boost_container
build_xcframework boost_context
# build_xcframework boost_contract
# build_xcframework boost_coroutine
# build_xcframework boost_date_time
# build_xcframework boost_exception
# build_xcframework boost_fiber
build_xcframework boost_filesystem
# build_xcframework boost_graph
# build_xcframework boost_iostreams
# build_xcframework boost_json
# build_xcframework boost_locale
# build_xcframework boost_log
# build_xcframework boost_log_setup
# build_xcframework boost_math_c99
# build_xcframework boost_math_c99l
# build_xcframework boost_math_c99f
# build_xcframework boost_math_tr1
# build_xcframework boost_math_tr1l
# build_xcframework boost_math_tr1f
# build_xcframework boost_nowide
build_xcframework boost_program_options
# build_xcframework boost_random
build_xcframework boost_regex
# build_xcframework boost_serialization
# build_xcframework boost_wserialization
# build_xcframework boost_stacktrace_addr2line
# build_xcframework boost_stacktrace_basic
# build_xcframework boost_stacktrace_noop
build_xcframework boost_system
# build_xcframework boost_prg_exec_monitor
# build_xcframework boost_test_exec_monitor
# build_xcframework boost_unit_test_framework
build_xcframework boost_thread
# build_xcframework boost_timer
# build_xcframework boost_type_erasure
# build_xcframework boost_wave

    # s.vendored_frameworks =
	# "frameworks/boost_context.xcframework",
	#  "frameworks/boost_filesystem.xcframework",
	#  "frameworks/boost_program_options.xcframework",
	#  "frameworks/boost_regex.xcframework",
	#   "frameworks/boost_system.xcframework",
	#   "frameworks/boost_thread.xcframework"


mkdir "$BUILD_DIR/frameworks/Headers"
cp -R boost "$BUILD_DIR/frameworks/Headers/"
# mv boost "$BUILD_DIR/frameworks/Headers/"
touch "$BUILD_DIR/frameworks.built"
fi

rm -rf "$BUILD_DIR/boost"

popd

fi
