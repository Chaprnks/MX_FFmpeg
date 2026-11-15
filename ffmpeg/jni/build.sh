#!/bin/bash
TARGET=$1
COPY=0
BUILD=0
PROFILE=0
PLATFORM=21
DEBUG_BUILD=0

if [ -z "${ENV_DEBUG_BUILD}" ] || [ "${ENV_DEBUG_BUILD}" == '0' ]; then
  DEBUG_BUILD=0
else
  DEBUG_BUILD=1
fi

E_VERBOSE=0

if [ -z "${ENV_MX_LOG}" ] || [ "${ENV_MX_LOG}" == '0' ]; then
  E_MX_LOG_ENABLE=0
else
  E_MX_LOG_ENABLE=1
fi

if [ -z "${ENV_MX_UNIT_TEST}" ] || [ "${ENV_MX_UNIT_TEST}" == '0' ]; then
  E_MX_UNIT_TEST=0
else
  E_MX_UNIT_TEST=1
fi

echo "DEBUG_BUILD=${DEBUG_BUILD} E_MX_LOG_ENABLE=${E_MX_LOG_ENABLE} E_MX_UNIT_TEST=${E_MX_UNIT_TEST}"

ROOT=$(cd "$(dirname "$0")"; pwd)
source "${ROOT}/ENV"
source "${ROOT}/util.sh"

MAKE="${NDK}/ndk-build"

prepare()
{
	rm -rf ../obj/local
}

prepare_mips()
{
	rm -rf ../obj/local
}

prepare_x86()
{
	rm -rf ../obj/local
}

prepare_x86_64()
{
	rm -rf ../obj/local
}

mips32r2()
{
  RELEASE_DIR=$(get_release_dir mips)
	if [ $BUILD -eq 1 ]; then
		echo -ne '\nBUILDING '$TARGET'.MIPS32 rev.2...\n\n'
		prepare_mips
		"$MAKE" NDK_DEBUG=$DEBUG_BUILD \
				  -j${CPU_CORE:-4} \
				  -e APP_ABI=mips \
				  -e MX_DEBUG=$DEBUG_BUILD \
				  -e MX_LOG_ENABLE=$E_MX_LOG_ENABLE \
				  -e MX_UNIT_TEST=$E_MX_UNIT_TEST \
				  -e VERBOSE_MODE=$E_VERBOSE \
				  -e APP_PLATFORM=android-$PLATFORM \
				  -e LINK_AGAINST=15-mips \
				  -e APP_BUILD_SCRIPT=a-$TARGET.mk \
				  -e ARCH=mips32r2 \
				  -e NDK_APP_DST_DIR=libs/mips \
				  -e NDK_BH_DIR=blackHole/libs/mips \
				  -e LIB_RELEASE_DIR=$RELEASE_DIR \
				  -e NAME=$TARGET \
				  -e PROFILE=$PROFILE
		dieOnError
	fi
}

x86_64()
{
  RELEASE_DIR=$(get_release_dir x86_64)
	if [ $BUILD -eq 1 ]; then
		echo -ne '\nBUILDING '$TARGET'.x86_64...\n\n'
		prepare_x86_64
		"$MAKE" NDK_DEBUG=$DEBUG_BUILD \
				  -j${CPU_CORE:-4} \
				  -e APP_ABI=x86_64 \
				  -e MX_DEBUG=$DEBUG_BUILD \
				  -e MX_LOG_ENABLE=$E_MX_LOG_ENABLE \
				  -e MX_UNIT_TEST=$E_MX_UNIT_TEST \
				  -e VERBOSE_MODE=$E_VERBOSE \
				  -e APP_PLATFORM=android-$PLATFORM \
				  -e LINK_AGAINST=21-x86_64 \
				  -e APP_BUILD_SCRIPT=a-$TARGET.mk \
				  -e ARCH=atom \
				  -e NDK_APP_DST_DIR=libs/x86_64 \
				  -e NDK_BH_DIR=blackHole/libs/x86_64 \
				  -e LIB_RELEASE_DIR=$RELEASE_DIR \
				  -e NAME=$TARGET \
				  -e PROFILE=$PROFILE
		dieOnError
		mkdir -p "${ROOT}/build/x86_64"
		cp -f libs/x86_64/*.so "${ROOT}/build/x86_64/" 2>/dev/null || true
	fi
}

x86()
{
  RELEASE_DIR=$(get_release_dir x86)
	if [ $BUILD -eq 1 ]; then
		echo -ne '\nBUILDING '$TARGET'.x86 Atom...\n\n'
		prepare_x86
		"$MAKE" NDK_DEBUG=$DEBUG_BUILD \
				  -j${CPU_CORE:-4} \
				  -e APP_ABI=x86 \
				  -e MX_DEBUG=$DEBUG_BUILD \
				  -e MX_LOG_ENABLE=$E_MX_LOG_ENABLE \
				  -e MX_UNIT_TEST=$E_MX_UNIT_TEST \
				  -e VERBOSE_MODE=$E_VERBOSE \
				  -e APP_PLATFORM=android-$PLATFORM \
				  -e LINK_AGAINST=16-x86 \
				  -e APP_BUILD_SCRIPT=a-$TARGET.mk \
				  -e ARCH=atom \
				  -e NDK_APP_DST_DIR=libs/x86 \
				  -e NDK_BH_DIR=blackHole/libs/x86 \
				  -e LIB_RELEASE_DIR=$RELEASE_DIR \
				  -e NAME=$TARGET \
				  -e PROFILE=$PROFILE
		dieOnError
		mkdir -p "${ROOT}/build/x86"
		cp -f libs/x86/*.so "${ROOT}/build/x86/" 2>/dev/null || true
	fi
}

x86_sse2()
{
  RELEASE_DIR=$(get_release_dir x86)
	if [ $BUILD -eq 1 ]; then
		echo -ne '\nBUILDING '$TARGET'.x86 SSE2...\n\n'
		prepare_x86
		"$MAKE" NDK_DEBUG=$DEBUG_BUILD \
				  -j${CPU_CORE:-4} \
				  -e APP_ABI=x86 \
				  -e MX_DEBUG=$DEBUG_BUILD \
				  -e MX_LOG_ENABLE=$E_MX_LOG_ENABLE \
				  -e MX_UNIT_TEST=$E_MX_UNIT_TEST \
				  -e VERBOSE_MODE=$E_VERBOSE \
				  -e APP_PLATFORM=android-$PLATFORM \
				  -e LINK_AGAINST=16-x86 \
				  -e APP_BUILD_SCRIPT=a-$TARGET.mk \
				  -e ARCH=i686 \
				  -e NDK_APP_DST_DIR=libs/x86-sse2 \
				  -e NDK_BH_DIR=blackHole/libs/x86-sse2 \
				  -e LIB_RELEASE_DIR=$RELEASE_DIR \
				  -e NAME=$TARGET \
				  -e PROFILE=$PROFILE
		dieOnError
	fi
}

arm64()
{
  RELEASE_DIR=$(get_release_dir arm64)
	if [ $BUILD -eq 1 ]; then
		echo -ne '\nBUILDING '$TARGET'.arm64...\n\n'
		prepare
		"$MAKE" NDK_DEBUG=$DEBUG_BUILD \
				  -j${CPU_CORE:-4} \
				  -e APP_ABI=arm64-v8a \
				  -e MX_DEBUG=$DEBUG_BUILD \
				  -e MX_LOG_ENABLE=$E_MX_LOG_ENABLE \
				  -e MX_UNIT_TEST=$E_MX_UNIT_TEST \
				  -e VERBOSE_MODE=$E_VERBOSE \
				  -e APP_PLATFORM=android-$PLATFORM \
				  -e LINK_AGAINST=22-arm64 \
				  -e APP_BUILD_SCRIPT=a-$TARGET.mk \
				  -e ARCH=armv8-a \
				  -e VFP=neon \
				  -e NDK_APP_DST_DIR=libs/arm64-v8a \
				  -e NDK_BH_DIR=blackHole/libs/arm64-v8a \
				  -e LIB_RELEASE_DIR=$RELEASE_DIR \
				  -e NAME=$TARGET \
				  -e PROFILE=$PROFILE
		dieOnError
		mkdir -p "${ROOT}/build/arm64-v8a"
		cp -f libs/arm64-v8a/*.so "${ROOT}/build/arm64-v8a/" 2>/dev/null || true
	fi

	if [ $COPY -eq 1 ]; then
		mkdir -p libs/output/videoplayer/arm64-v8a/
		cp libs/arm64-v8a/lib$TARGET.so libs/output/videoplayer/arm64-v8a/
	fi
}

neon()
{
  RELEASE_DIR=$(get_release_dir neon)
	if [ $BUILD -eq 1 ]; then
		echo -ne '\nBUILDING '$TARGET'.neon...\n\n'
		echo "debug build: $DEBUG_BUILD log enabled: $E_MX_LOG_ENABLE"
		prepare
		"$MAKE" NDK_DEBUG=$DEBUG_BUILD \
				  -j${CPU_CORE:-4} \
				  -e APP_ABI=armeabi-v7a \
				  -e MX_DEBUG=$DEBUG_BUILD \
				  -e MX_LOG_ENABLE=$E_MX_LOG_ENABLE \
				  -e MX_UNIT_TEST=$E_MX_UNIT_TEST \
				  -e VERBOSE_MODE=$E_VERBOSE \
				  -e APP_PLATFORM=android-$PLATFORM \
				  -e LINK_AGAINST=16-arm \
				  -e APP_BUILD_SCRIPT=a-$TARGET.mk \
				  -e ARCH=armv7-a \
				  -e VFP=neon \
				  -e NDK_APP_DST_DIR=libs/armeabi-v7a/neon \
				  -e NDK_BH_DIR=blackHole/libs/armeabi-v7a \
				  -e LIB_RELEASE_DIR=$RELEASE_DIR \
				  -e NAME=$TARGET \
				  -e PROFILE=$PROFILE
		dieOnError
		mkdir -p "${ROOT}/build/armeabi-v7a"
		cp -f libs/armeabi-v7a/neon/*.so "${ROOT}/build/armeabi-v7a/" 2>/dev/null || true
	fi

	if [ $COPY -eq 1 ]; then
		mkdir -p libs/output/videoplayer/armeabi-v7a/
		cp libs/armeabi-v7a/neon/lib$TARGET.so libs/output/videoplayer/armeabi-v7a/
	fi
}

tegra3()
{
  RELEASE_DIR=$(get_release_dir tegra3)
	if [ $BUILD -eq 1 ]; then
		echo -ne '\nBUILDING '$TARGET'.tegra3...\n\n'
		prepare
		"$MAKE" NDK_DEBUG=$DEBUG_BUILD \
				  -j${CPU_CORE:-4} \
				  -e APP_ABI=armeabi-v7a \
				  -e MX_DEBUG=$DEBUG_BUILD \
				  -e MX_LOG_ENABLE=$E_MX_LOG_ENABLE \
				  -e MX_UNIT_TEST=$E_MX_UNIT_TEST \
				  -e VERBOSE_MODE=$E_VERBOSE \
				  -e APP_PLATFORM=android-$PLATFORM \
				  -e LINK_AGAINST=16-arm \
				  -e APP_BUILD_SCRIPT=a-$TARGET.mk \
				  -e ARCH=armv7-a \
				  -e VFP=neon \
				  -e UNALIGNED_ACCESS=0 \
				  -e NDK_APP_DST_DIR=libs/armeabi-v7a/tegra3 \
				  -e NDK_BH_DIR=blackHole/libs/armeabi-v7a/tegra3 \
				  -e LIB_RELEASE_DIR=$RELEASE_DIR \
				  -e NAME=$TARGET \
				  -e PROFILE=$PROFILE
		dieOnError
	fi

	if [ $COPY -eq 1 ]; then
		mkdir -p libs/output/videoplayer/armeabi-v7a/
		cp libs/armeabi-v7a/tegra3/lib$TARGET.so libs/output/videoplayer/armeabi-v7a/
	fi
}

tegra2()
{
  RELEASE_DIR=$(get_release_dir tegra2)
	if [ $BUILD -eq 1 ]; then
		prepare
		echo -ne '\nBUILDING '$TARGET'.tegra2...\n\n'
		"$MAKE" NDK_DEBUG=$DEBUG_BUILD \
				  -j${CPU_CORE:-4} \
				  -e APP_ABI=armeabi-v7a \
				  -e MX_DEBUG=$DEBUG_BUILD \
				  -e MX_LOG_ENABLE=$E_MX_LOG_ENABLE \
				  -e MX_UNIT_TEST=$E_MX_UNIT_TEST \
				  -e VERBOSE_MODE=$E_VERBOSE \
				  -e APP_PLATFORM=android-$PLATFORM \
				  -e LINK_AGAINST=16-arm \
				  -e APP_BUILD_SCRIPT=a-$TARGET.mk \
				  -e ARCH=armv7-a \
				  -e VFP=vfpv3-d16 \
				  -e NDK_APP_DST_DIR=libs/armeabi-v7a/vfpv3-d16 \
				  -e NDK_BH_DIR=blackHole/libs/armeabi-v7a/vfpv3-d16 \
				  -e LIB_RELEASE_DIR=$RELEASE_DIR \
				  -e NAME=$TARGET \
				  -e PROFILE=$PROFILE
		dieOnError
	fi

	if [ $COPY -eq 1 ]; then
		mkdir -p libs/output/videoplayer/armeabi-v7a
		cp libs/armeabi-v7a/vfpv3-d16/lib$TARGET.so libs/output/videoplayer/armeabi-v7a
	fi
}

v7a()
{
  RELEASE_DIR=$(get_release_dir neon)
	if [ $BUILD -eq 1 ]; then
		prepare
		echo -ne '\nBUILDING '$TARGET'.v7a...\n\n'
		"$MAKE" NDK_DEBUG=$DEBUG_BUILD \
				  -j${CPU_CORE:-4} \
				  -e APP_ABI=armeabi-v7a \
				  -e MX_DEBUG=$DEBUG_BUILD \
				  -e MX_LOG_ENABLE=$E_MX_LOG_ENABLE \
				  -e MX_UNIT_TEST=$E_MX_UNIT_TEST \
				  -e VERBOSE_MODE=$E_VERBOSE \
				  -e APP_PLATFORM=android-$PLATFORM \
				  -e LINK_AGAINST=16-arm \
				  -e APP_BUILD_SCRIPT=a-$TARGET.mk \
				  -e ARCH=armv7-a \
				  -e VFP=vfp \
				  -e NDK_APP_DST_DIR=libs/armeabi-v7a \
				  -e NDK_BH_DIR=blackHole/libs/armeabi-v7a \
				  -e LIB_RELEASE_DIR=$RELEASE_DIR \
				  -e NAME=$TARGET \
				  -e PROFILE=$PROFILE
		dieOnError
	fi

	if [ $COPY -eq 1 ]; then
		mkdir -p libs/output/videoplayer/armeabi-v7a
		cp libs/armeabi-v7a/lib$TARGET.so libs/output/videoplayer/armeabi-v7a
	fi
}

for p in $*; do
	case "$p" in
		copy)
			COPY=1 ;;
		build)
			BUILD=1 ;;
		release)
			DEBUG_BUILD=0 ;;
		debug)
			DEBUG_BUILD=1 ;;
		mips)
			mips32r2 ;;
		x86_64|amd64)
			x86_64 ;;
		x86|i686)
			x86 ;;
		x86_sse2)
			x86_sse2 ;;
		arm64|arm64-v8a|aarch64)
			arm64 ;;
		neon|armeabi-v7a|arm)
			neon ;;
		tegra3)
			tegra3 ;;
		tegra2)
			tegra2 ;;
		v7a)
			v7a ;;
		profile)
			PROFILE=1 ;;
		21)
			PLATFORM=21 ;;
	esac
done
