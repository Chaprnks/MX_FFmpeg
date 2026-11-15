#!/bin/bash
ROOT=$(cd "$(dirname "$0")"; pwd)
source "${ROOT}/ENV"
source "${ROOT}/util.sh"

DISABLE_ILLEGAL_COMPONENTS=false

debug=false
for p in $*; do
  case "$p" in
    --debug )
      debug=true
      ;;
  esac
done

HOST_PLATFORM=$(probe_host_platform)
GCC_VER=4.9
CLANG_VER=3.8

FLAVOR=$(normalize_arch "$1")

case "$FLAVOR" in
	arm64)
		ARCH=arm64
		CPU=armv8-a
		LIB_MX="../libs/arm64-v8a"
		if [ -z "${CLANG_VER}" ]; then
			EXTRA_CFLAGS+=" -mvectorize-with-neon-quad"
		fi
		;;

	neon)
		ARCH=arm
		CPU=armv7-a
		LIB_MX="../libs/armeabi-v7a/neon"
		EXTRA_CFLAGS="-mfloat-abi=softfp -mfpu=neon -mtune=cortex-a8"
		EXTRA_LDFLAGS="-Wl,--fix-cortex-a8"
		if [ -z "${CLANG_VER}" ]; then
			EXTRA_CFLAGS+=" -mvectorize-with-neon-quad"
		fi
		;;

	tegra3)
		ARCH=arm
		CPU=armv7-a
		LIB_MX="../libs/armeabi-v7a/tegra3"
		if [ ! -d "$LIB_MX" ]; then
			LIB_MX="../libs/armeabi-v7a/neon"
		fi
		EXTRA_CFLAGS="-mfloat-abi=softfp -mfpu=neon -mtune=cortex-a8 -mno-unaligned-access"
		EXTRA_LDFLAGS="-Wl,--fix-cortex-a8"
		EXTRA_PARAMETERS="--disable-fast-unaligned"
		if [ -z "${CLANG_VER}" ]; then
			EXTRA_CFLAGS+=" -mvectorize-with-neon-quad"
		fi
		;;

	tegra2)
		ARCH=arm
		CPU=armv7-a
		LIB_MX="../libs/armeabi-v7a/vfpv3-d16"
		EXTRA_CFLAGS="-mfloat-abi=softfp -mfpu=vfpv3-d16"
		EXTRA_LDFLAGS="-Wl,--fix-cortex-a8"
		EXTRA_PARAMETERS="--disable-neon"
		;;

	x86_64)
		ARCH=x86_64
		CPU=atom
		LIB_MX="../libs/x86_64"
		EXTRA_CFLAGS="-mtune=atom -msse3 -mssse3 -mfpmath=sse"
		;;

	x86)
		ARCH=x86
		CPU=atom
		LIB_MX="../libs/x86"
		EXTRA_CFLAGS="-mtune=atom -msse3 -mssse3 -mfpmath=sse"
		;;

	*)
		echo "Unknown target: $1"
		exit 1
		;;
esac

INC_OPENSSL=../openssl-1.0.2s/include
INC_OPUS=../opus-1.1/include
INC_SPEEX=../speex-1.2rc1/include
INC_ZVBI=../zvbi-0.2.35/src
INC_ICONV=../modified_src/iconv
INC_MXV=../modified_src/mxv
INC_MXD=../modified_src/mxd
INC_USB=../modified_src/usb
INC_DOWNLOAD=../modified_src/download
INC_MODPLUG=../libmodplug/src
INC_LIBMXL2=../libxml2/include
INC_LIBSMB2=../libsmb2/include
INC_LIBDAV1D=../dav1d/include
INC_LIBMP3LAME=../lame-3.100

TOOLCHAIN="${NDK}/toolchains/llvm/prebuilt/${HOST_PLATFORM}"
if [ "$ARCH" == 'arm64' ]; then
    INC_LIBDAV1D_BUILD=../dav1d/builddir/arm64-v8a/include/dav1d
    CROSS_PREFIX="${TOOLCHAIN}/bin/aarch64-linux-android-"
    AS="${TOOLCHAIN}/bin/aarch64-linux-android21-clang"
    LD="${TOOLCHAIN}/bin/aarch64-linux-android21-clang"

    EXTRA_CFLAGS+=" -fstack-protector -fstrict-aliasing"
    EXTRA_LDFLAGS+=" -march=$CPU"

    if [ -n "${CLANG_VER}" ]; then
        CLANG_TARGET=aarch64-none-linux-android21
    fi

    if $debug; then
        OPTFLAGS="-O0"
        EXTRA_CFLAGS+=" -g"
    else
        OPTFLAGS="-O2"
    fi
    LINK_AGAINST=22-arm
elif [ "$ARCH" == 'arm' ]; then
    INC_LIBDAV1D_BUILD=../dav1d/builddir/armeabi-v7a/include/dav1d
    CROSS_PREFIX="${TOOLCHAIN}/bin/arm-linux-androideabi-"
    AS="${TOOLCHAIN}/bin/armv7a-linux-androideabi21-clang"
    LD="${TOOLCHAIN}/bin/armv7a-linux-android21-clang"
    if [ ! -e "$LD" ]; then
        LD="${TOOLCHAIN}/bin/armv7a-linux-androideabi21-clang"
    fi

    EXTRA_CFLAGS+=" -fstack-protector -fstrict-aliasing"
    EXTRA_LDFLAGS+=" -march=$CPU"

    if [ -n "${CLANG_VER}" ]; then
        CLANG_TARGET=armv7a-none-linux-androideabi21
    fi

    OPTFLAGS="-O2"
elif [ "$ARCH" == 'x86_64' ]; then
    INC_LIBDAV1D_BUILD=../dav1d/builddir/x86_64/include/dav1d
    CROSS_PREFIX="${TOOLCHAIN}/bin/x86_64-linux-android-"
    AS="${TOOLCHAIN}/bin/x86_64-linux-android21-clang"
    LD="${TOOLCHAIN}/bin/x86_64-linux-android21-clang"

    EXTRA_CFLAGS+=" -fstrict-aliasing"

    if [ -n "${CLANG_VER}" ]; then
        CLANG_TARGET=x86_64-none-linux-android21
        EXTRA_CFLAGS+=" -fstack-protector-strong "
    fi

    OPTFLAGS="-O2 -fpic"
    LINK_AGAINST=21-x86_64
elif [ "$ARCH" == 'x86' ]; then
    INC_LIBDAV1D_BUILD=../dav1d/builddir/x86/include/dav1d
    FFMPEG_CONFIGURATION="--disable-asm --disable-x86asm --disable-mmx --disable-mmxext --disable-inline-asm"
    CROSS_PREFIX="${TOOLCHAIN}/bin/i686-linux-android-"
    AS="${TOOLCHAIN}/bin/i686-linux-android21-clang"
    LD="${TOOLCHAIN}/bin/i686-linux-android21-clang"

    EXTRA_CFLAGS+=" -fstrict-aliasing"

    if [ -n "${CLANG_VER}" ]; then
        CLANG_TARGET=i686-none-linux-android21
        EXTRA_CFLAGS+=" -fstack-protector-strong "
    fi

    OPTFLAGS="-O2 -fpic"
    LINK_AGAINST=16-x86
fi

if [ ! -e "${CROSS_PREFIX}ar" ]; then
    CROSS_PREFIX="${TOOLCHAIN}/bin/llvm-"
fi

AR="${CROSS_PREFIX}ar"
NM="${CROSS_PREFIX}nm"
RANLIB="${CROSS_PREFIX}ranlib"
STRIP="${CROSS_PREFIX}strip"

if [ -n "${CLANG_VER}" ]; then
    CC="${TOOLCHAIN}/bin/clang -target $CLANG_TARGET"
    CXX="${TOOLCHAIN}/bin/clang++ -target $CLANG_TARGET"
    EXTRA_CFLAGS+=" -Wno-deprecated-declarations -Wno-unused-variable -Wno-unused-function -Wno-error=incompatible-function-pointer-types -Wno-error=int-conversion -Wno-error=implicit-function-declaration -Wno-error=implicit-int"
else
    EXTRA_CFLAGS+=" -mandroid -fpredictive-commoning -fipa-cp-clone -funswitch-loops -finline-limit=300 -finline-functions -fgcse-after-reload"
fi
SYSROOT="${TOOLCHAIN}/sysroot"
EXTRA_LDFLAGS+=" -Wl,-z,max-page-size=16384"

FFCOMMON="\
--enable-asm \
--disable-debug \
--disable-doc \
--disable-programs \
--disable-shared \
--disable-symver \
--enable-optimizations \
--enable-pic \
--enable-pthreads \
--enable-static \
"
FF_FEATURE_CLASS="\
--disable-avdevice \
--disable-devices \
--disable-filters \
--disable-muxers \
--disable-postproc \
--disable-swscale-alpha \
--enable-avfilter \
--enable-libmp3lame \
"
FF_FEATURE_DEMUXER="\
--disable-demuxer=jacosub \
--disable-demuxer=microdvd \
--disable-demuxer=mpl2 \
--disable-demuxer=pjs \
--disable-demuxer=realtext \
--disable-demuxer=sami \
--disable-demuxer=stl \
--disable-demuxer=subviewer \
--disable-demuxer=subviewer1 \
--disable-demuxer=vplayer \
--enable-demuxer=webvtt \
"
FF_FEATURE_MUXER="\
--disable-muxers \
--enable-muxer=webvtt \
--enable-muxer=srt \
--enable-muxer=mp3 \
--enable-muxer=dash \
--enable-muxer=mxv \
"
FF_FEATURE_DECODER="\
--disable-decoder=jacosub \
--disable-decoder=microdvd \
--disable-decoder=mpl2 \
--disable-decoder=pjs \
--disable-decoder=realtext \
--disable-decoder=sami \
--disable-decoder=srt \
--disable-decoder=stl \
--disable-decoder=subviewer \
--disable-decoder=subviewer1 \
--disable-decoder=vplayer \
"
FF_FEATURE_ENCODER="\
--disable-encoders \
--enable-encoder=webvtt \
--enable-encoder=srt \
--enable-libmp3lame \
--enable-encoder=libmp3lame \
--enable-encoder=aac \
--enable-encoder=text \
"
FF_FEATURE_FILTER="\
--enable-filter=transpose \
--enable-filter=vflip \
--enable-filter=hflip \
--enable-filter=scale \
--enable-filter=rotate \
--enable-filter=w3fdif \
--enable-filter=yadif \
"
FF_FEATURE_PROTOCOL="\
--disable-protocol=bluray \
--disable-protocol=data \
--disable-protocol=gopher \
--disable-protocol=md5 \
--disable-protocol=pipe \
--disable-protocol=udplite \
--disable-protocol=unix \
"
FF_FEATURE_MISC="\
--disable-bsf=dca_core \
"

ENABLE_ALL_DEMUXER_DECODER=true

FF_FEATURES=""
FF_FEATURES+=$FF_FEATURE_CLASS
FF_FEATURES+=$FF_FEATURE_MUXER
FF_FEATURES+=$FF_FEATURE_ENCODER
FF_FEATURES+=$FF_FEATURE_FILTER
FF_FEATURES+=$FF_FEATURE_PROTOCOL

if [ "$ENABLE_ALL_DEMUXER_DECODER" != true ]; then
  MX_WHITELIST="-DMX_WHITELIST"
  FF_FEATURES+=$FF_FEATURE_DEMUXER
  FF_FEATURES+=$FF_FEATURE_DECODER
  FF_FEATURES+=$FF_FEATURE_MISC
else
  MX_WHITELIST=""
fi

FF_OUTDEP="\
--enable-libmodplug \
--enable-libopus \
--enable-libspeex \
--enable-openssl \
--enable-zlib \
--enable-libxml2 \
--enable-libsmb2 \
--enable-jni \
--enable-usb \
--enable-libdav1d \
"

FFCOMPILER="\
--arch=$ARCH \
--cpu=$CPU \
--cross-prefix=$CROSS_PREFIX \
--ld=$LD \
--nm=$NM \
--ar=$AR \
--ranlib=$RANLIB \
--strip=$STRIP \
--as=$AS \
--target-os=android \
--enable-cross-compile \
--sysroot=${TOOLCHAIN}/sysroot \
$EXTRA_PARAMETERS \
"

EXTRA_CFLAGS+=" -I$INC_LIBMP3LAME -I$INC_ICONV -I$INC_MXV -I$INC_MXD -I$INC_USB -I$INC_DOWNLOAD -idirafter$INC_ZVBI -I$INC_OPENSSL -I$INC_OPUS -I$INC_SPEEX -I$INC_MODPLUG -I$INC_LIBMXL2 -I$INC_LIBSMB2 -I$INC_LIBDAV1D -I$INC_LIBDAV1D_BUILD -DNDEBUG -DMXTECHS $MX_WHITELIST -DFF_API_AVPICTURE=1 -DCONFIG_MXV_FROM_MXVP=1 -DMXD_BUILTIN -ftree-vectorize -ffunction-sections -funwind-tables -fomit-frame-pointer -no-canonical-prefixes -pipe"
EXTRA_LIBS=" -L$LIB_MX -lsmb2 -lmxutil -lmp3lame -lm -lc++_shared"

bash ./configure ${FFCOMPILER} \
            ${FFCOMMON} \
            ${FF_FEATURES} \
            ${FFMPEG_CONFIGURATION} \
            ${FF_OUTDEP} \
            --cc="$CC" \
            --cxx="$CXX" \
            --extra-cflags="$EXTRA_CFLAGS --sysroot ${SYSROOT}" \
            --extra-libs="$EXTRA_LIBS" \
            --extra-ldflags="$EXTRA_LDFLAGS" \
            --optflags="$OPTFLAGS"
