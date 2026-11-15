#!/bin/bash
ROOT=$(cd "$(dirname "$0")"; pwd)
source "${ROOT}/ENV"
source "${ROOT}/util.sh"

cd "${ROOT}/dav1d"

if test -z "${NDK}"; then
    die "NDK not found. Please set NDK environment variable properly."
fi

HOST_PLATFORM=$(probe_host_platform)
FLAVOR=$(normalize_arch "$1")

BUILDDIR=builddir

if test -z "${FLAVOR}"; then
    die "No flavor selected. Valid architectures: neon tegra2 tegra3 arm64 x86 x86_64"
fi

TOOLCHAIN="${NDK}/toolchains/llvm/prebuilt/${HOST_PLATFORM}"

if [ "${FLAVOR}" == 'neon' ] || [ "${FLAVOR}" == 'tegra2' ] || [ "${FLAVOR}" == 'tegra3' ]; then
    CROSS_PREFIX="${TOOLCHAIN}/bin/arm-linux-androideabi-"
    if [ ! -e "${CROSS_PREFIX}ar" ]; then
        CROSS_PREFIX="${TOOLCHAIN}/bin/llvm-"
    fi

    CC="${TOOLCHAIN}/bin/armv7a-linux-androideabi21-clang"
    AR="${CROSS_PREFIX}ar"
    OBJCOPY="${CROSS_PREFIX}objcopy"
    STRIP="${CROSS_PREFIX}strip"
    CPU_FAMILY="arm"
    CPU="armv7-a"

    CFLAGS="-mfloat-abi=softfp"
    if [ "${FLAVOR}" == 'neon' ]; then
        CFLAGS+=" -mfpu=neon"
        CFLAGS+=" -mtune=cortex-a8"
        BUILDDIR=builddir/armeabi-v7a
    elif [ "${FLAVOR}" == 'tegra2' ]; then
        CFLAGS+=" -mfpu=vfpv3-d16"
        BUILDDIR=builddir/armeabi-v7a
    elif [ "${FLAVOR}" == 'tegra3' ]; then
        CFLAGS+=" -mfpu=neon"
        CFLAGS+=" -mtune=cortex-a8"
        CFLAGS+=" -mno-unaligned-access"
        BUILDDIR=builddir/armeabi-v7a
    fi
    CFLAGS+=" -fstack-protector"
    CFLAGS+=" -fstrict-aliasing"
    CFLAGS+=" -fPIC"

    LDFLAGS="-Wl,--fix-cortex-a8"
    LDFLAGS+=" -O2"
    LDFLAGS+=" -march=${CPU}"

elif [ "${FLAVOR}" == 'arm64' ]; then
    CROSS_PREFIX="${TOOLCHAIN}/bin/aarch64-linux-android-"
    if [ ! -e "${CROSS_PREFIX}ar" ]; then
        CROSS_PREFIX="${TOOLCHAIN}/bin/llvm-"
    fi

    CC="${TOOLCHAIN}/bin/aarch64-linux-android21-clang"
    AR="${CROSS_PREFIX}ar"
    OBJCOPY="${CROSS_PREFIX}objcopy"
    STRIP="${CROSS_PREFIX}strip"
    CPU_FAMILY="aarch64"
    CPU="armv8-a"

    CFLAGS="-fstack-protector -fstrict-aliasing -fPIC"
    LDFLAGS="-O2 -march=${CPU}"

    BUILDDIR=builddir/arm64-v8a

elif [ "${FLAVOR}" == 'x86' ]; then
    CROSS_PREFIX="${TOOLCHAIN}/bin/i686-linux-android-"
    if [ ! -e "${CROSS_PREFIX}ar" ]; then
        CROSS_PREFIX="${TOOLCHAIN}/bin/llvm-"
    fi

    CC="${TOOLCHAIN}/bin/i686-linux-android21-clang"
    AR="${CROSS_PREFIX}ar"
    OBJCOPY="${CROSS_PREFIX}objcopy"
    STRIP="${CROSS_PREFIX}strip"
    CPU_FAMILY="x86"
    CPU="atom"

    CFLAGS="-mtune=atom -msse3 -mssse3 -mfpmath=sse -fstrict-aliasing -fstack-protector-strong -O2 -fPIC"
    LDFLAGS="-O2"

    BUILDDIR=builddir/x86

elif [ "${FLAVOR}" == 'x86_64' ]; then
    CROSS_PREFIX="${TOOLCHAIN}/bin/x86_64-linux-android-"
    if [ ! -e "${CROSS_PREFIX}ar" ]; then
        CROSS_PREFIX="${TOOLCHAIN}/bin/llvm-"
    fi

    CC="${TOOLCHAIN}/bin/x86_64-linux-android21-clang"
    AR="${CROSS_PREFIX}ar"
    OBJCOPY="${CROSS_PREFIX}objcopy"
    STRIP="${CROSS_PREFIX}strip"
    CPU_FAMILY="x86_64"
    CPU="atom"

    CFLAGS="-mtune=atom -msse3 -mssse3 -mfpmath=sse -fstrict-aliasing -fstack-protector-strong -O2 -fPIC"
    LDFLAGS="-O2"

    BUILDDIR=builddir/x86_64
else
    die "Unsupported architecture: $1"
fi

CFLAGS+=" -Wno-deprecated-declarations -Wno-unused-variable -Wno-unused-function -Wno-error=incompatible-function-pointer-types -Wno-error=int-conversion -Wno-error=implicit-function-declaration"

export SYSROOT="${TOOLCHAIN}/sysroot"

function toArray() {
    local array="["
    for flag in ${1}; do
        array+="'$flag',"
    done
    array+="]"
    echo "$array" | sed 's/,]/]/g'
}

CFLAGS_ARRAY=$(toArray "${CFLAGS}")
LDFLAGS_ARRAY=$(toArray "${LDFLAGS}")

cat > cross_file.txt <<CROSS_EOF
[binaries]
c = '${CC}'
ar = '${AR}'
objcopy = '${OBJCOPY}'
strip = '${STRIP}'

[properties]
sys_root = '${SYSROOT}'
c_args = ${CFLAGS_ARRAY}
c_link_args = ${LDFLAGS_ARRAY}

[host_machine]
system = 'android'
cpu_family = '${CPU_FAMILY}'
cpu = '${CPU}'
endian = 'little'
CROSS_EOF

if [ -d "${BUILDDIR}" ]; then
    rm -rf "${BUILDDIR}"
fi

meson setup --default-library=static -Denable_tools=false -Denable_tests=false --cross-file=cross_file.txt "${BUILDDIR}" || \
meson --default-library static -Denable_tools=false -Denable_tests=false --cross-file=cross_file.txt "${BUILDDIR}"
dieOnError "ERROR: failed to configure dav1d for ${FLAVOR}"

ninja -C "${BUILDDIR}" -j${CPU_CORE:-4}
dieOnError "ERROR: failed to build dav1d for ${FLAVOR}"
