#!/bin/bash
ROOT=$(cd "$(dirname "$0")"; pwd)
source "${ROOT}/ENV"
source "${ROOT}/util.sh"

cd "${ROOT}/openssl-1.0.2s"

if test -z "${NDK}"; then
    die "NDK not found. Please set NDK environment variable properly."
fi

HOST_PLATFORM=$(probe_host_platform)
FLAVOR=$(normalize_arch "$1")

if test -z "${FLAVOR}"; then
    die "No flavor selected. Valid architectures: neon tegra2 tegra3 arm64 x86 x86_64"
fi

TOOLCHAIN="${NDK}/toolchains/llvm/prebuilt/${HOST_PLATFORM}"
EXTRA_OPENSSL_OPTS="no-shared no-tests"

if [ "${FLAVOR}" == 'neon' ] || [ "${FLAVOR}" == 'tegra2' ] || [ "${FLAVOR}" == 'tegra3' ]; then
    CROSS_PREFIX="${TOOLCHAIN}/bin/arm-linux-androideabi-"
    TARGET=android-armv7
    CLANG_TARGET="armv7a-none-linux-androideabi21"
elif [ "${FLAVOR}" == 'arm64' ]; then
    CROSS_PREFIX="${TOOLCHAIN}/bin/aarch64-linux-android-"
    TARGET=android64-aarch64
    TRIPLE=aarch64-linux-android
    CLANG_TARGET="aarch64-none-linux-android21"
elif [ "${FLAVOR}" == 'x86' ]; then
    CROSS_PREFIX="${TOOLCHAIN}/bin/i686-linux-android-"
    TARGET=android-x86
    CLANG_TARGET="i686-none-linux-android21"
    EXTRA_OPENSSL_OPTS+=" no-asm"
elif [ "${FLAVOR}" == 'x86_64' ]; then
    CROSS_PREFIX="${TOOLCHAIN}/bin/x86_64-linux-android-"
    TARGET=android
    CLANG_TARGET="x86_64-none-linux-android21"
    EXTRA_OPENSSL_OPTS+=" no-asm"
else
    die "Unsupported architecture: $1"
fi

if [ ! -e "${CROSS_PREFIX}ar" ]; then
    CROSS_PREFIX="${TOOLCHAIN}/bin/llvm-"
fi

WARN_FLAGS="-Wno-error=incompatible-function-pointer-types -Wno-error=int-conversion -Wno-error=implicit-function-declaration -Wno-error=implicit-int -Wno-unused-command-line-argument"

export PERL5LIB=.
export ANDROID_SYSROOT="${TOOLCHAIN}/sysroot"
export CC="${TOOLCHAIN}/bin/clang -target ${CLANG_TARGET} ${WARN_FLAGS}"
export CXX="${TOOLCHAIN}/bin/clang++ -target ${CLANG_TARGET} ${WARN_FLAGS}"
export RANLIB="${CROSS_PREFIX}ranlib"
export AR="${CROSS_PREFIX}ar"
export NM="${CROSS_PREFIX}nm"

perl ./Configure ${TARGET} ${EXTRA_OPENSSL_OPTS}
if test "$?" != 0; then
    die "ERROR: failed to configure openssl.${FLAVOR}"
fi
touch Makefile

echo "BUILDING openssl.${FLAVOR}"
make clean
make build_libs -j${CPU_CORE:-4}
if test "$?" != 0; then
    die "ERROR: failed to build openssl.${FLAVOR}"
fi

DST_DIR=$(get_dst_dir "${FLAVOR}")
echo "COPYING openssl.${FLAVOR} to ${DST_DIR}"
mkdir -p "${ROOT}/${DST_DIR}"
cp -f libssl.a "${ROOT}/${DST_DIR}/"
cp -f libcrypto.a "${ROOT}/${DST_DIR}/"
