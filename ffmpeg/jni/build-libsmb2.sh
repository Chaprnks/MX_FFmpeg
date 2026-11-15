#!/bin/bash
ROOT=$(cd "$(dirname "$0")"; pwd)
source "${ROOT}/ENV"
source "${ROOT}/util.sh"

cd "${ROOT}/libsmb2"

if test -z "${NDK}"; then
    die "NDK not found. Please set NDK environment variable properly."
fi

HOST_PLATFORM=$(probe_host_platform)
FLAVOR=$(normalize_arch "$1")

if test -z "${FLAVOR}"; then
    die "No flavor selected. Valid architectures: neon tegra2 tegra3 arm64 x86 x86_64"
fi

TOOLCHAIN="${NDK}/toolchains/llvm/prebuilt/${HOST_PLATFORM}"

if [ "${FLAVOR}" == 'neon' ] || [ "${FLAVOR}" == 'tegra2' ] || [ "${FLAVOR}" == 'tegra3' ]; then
    CROSS_PREFIX="${TOOLCHAIN}/bin/arm-linux-androideabi-"
    CLANG_TARGET="armv7a-none-linux-androideabi21"
    HOST="arm-linux-androideabi"
elif [ "${FLAVOR}" == 'arm64' ]; then
    CROSS_PREFIX="${TOOLCHAIN}/bin/aarch64-linux-android-"
    TRIPLE=aarch64-linux-android
    CLANG_TARGET="aarch64-none-linux-android21"
    HOST="aarch64-linux-android"
elif [ "${FLAVOR}" == 'x86' ]; then
    CROSS_PREFIX="${TOOLCHAIN}/bin/i686-linux-android-"
    CLANG_TARGET="i686-none-linux-android21"
    HOST="i686-linux-android"
elif [ "${FLAVOR}" == 'x86_64' ]; then
    CROSS_PREFIX="${TOOLCHAIN}/bin/x86_64-linux-android-"
    CLANG_TARGET="x86_64-none-linux-android21"
    HOST="x86_64-linux-android"
else
    die "Unsupported architecture: $1"
fi

if [ ! -e "${CROSS_PREFIX}ar" ]; then
    CROSS_PREFIX="${TOOLCHAIN}/bin/llvm-"
fi

WARN_FLAGS="-Wno-error=incompatible-function-pointer-types -Wno-error=int-conversion -Wno-error=implicit-function-declaration -Wno-error=implicit-int"

export SYSROOT="${TOOLCHAIN}/sysroot"
export CC="${TOOLCHAIN}/bin/clang -target ${CLANG_TARGET}"
export CXX="${TOOLCHAIN}/bin/clang++ -target ${CLANG_TARGET}"
export CFLAGS="-O2 -fPIC ${WARN_FLAGS}"
export RANLIB="${CROSS_PREFIX}ranlib"
export AR="${CROSS_PREFIX}ar"
export NM="${CROSS_PREFIX}nm"
export STRIP="${CROSS_PREFIX}strip"
export OBJDUMP="${CROSS_PREFIX}objdump"
export CPPFLAGS="-DMXTECHS"
export LDFLAGS="-Wl,-z,max-page-size=16384"

make distclean >/dev/null 2>&1 || true

if which autoreconf >/dev/null 2>&1; then
    sh ./bootstrap
fi

sh ./configure --enable-static=no \
            --disable-werror \
            --host=$HOST \
            --without-libkrb5 \
            --with-pic \
            --with-sysroot=$SYSROOT

if test "$?" != 0; then
    die "ERROR: failed to configure libsmb2.${FLAVOR}"
fi

echo "BUILDING libsmb2.${FLAVOR}"
make clean
make -j${CPU_CORE:-4}
if test "$?" != 0; then
    die "ERROR: failed to build libsmb2.${FLAVOR}"
fi

DST_DIR=$(get_dst_dir "${FLAVOR}")
ABI_DIR=$(get_abi_dir "${FLAVOR}")
echo "COPYING libsmb2.${FLAVOR} to ${DST_DIR}"
mkdir -p "${ROOT}/${DST_DIR}" "${ROOT}/build/${ABI_DIR}"
cp -f lib/.libs/libsmb2.so "${ROOT}/${DST_DIR}/"
cp -f lib/.libs/libsmb2.so "${ROOT}/build/${ABI_DIR}/"
