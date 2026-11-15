#!/bin/bash
ROOT=$(cd "$(dirname "$0")"; pwd)
source "${ROOT}/ENV"
source "${ROOT}/util.sh"

cd "${ROOT}"

if test -z "${NDK}"; then
    die "NDK not found. Please set NDK environment variable properly."
fi

FLAVOR=$(normalize_arch "${1:-arm64}")

if [ "${FLAVOR}" == 'arm' ] || [ "${FLAVOR}" == 'neon' ] || [ "${FLAVOR}" == 'tegra2' ] || [ "${FLAVOR}" == 'tegra3' ]; then
    TARGET_ABI=armeabi-v7a
    TARGET_ARCH=armv7-a
elif [ "${FLAVOR}" == 'arm64' ]; then
    TARGET_ABI=arm64-v8a
    TARGET_ARCH=armv8-a
elif [ "${FLAVOR}" == 'x86' ]; then
    TARGET_ABI=x86
    TARGET_ARCH=atom
elif [ "${FLAVOR}" == 'x86_64' ]; then
    TARGET_ABI=x86_64
    TARGET_ARCH=atom
else
    die "Unsupported architecture: ${1}"
fi

DST_DIR=$(get_dst_dir "${FLAVOR}")
ABI_DIR=$(get_abi_dir "${FLAVOR}")

rm -f "../obj/local/${TARGET_ABI}/libmp3lame.so"

"${NDK}/ndk-build" NDK_DEBUG=0 \
    -j${CPU_CORE:-4} \
    -e APP_PLATFORM=android-21 \
    -e APP_ABI=${TARGET_ABI} \
    -e APP_BUILD_SCRIPT=libmp3lame.mk \
    -e ARCH=${TARGET_ARCH} \
    -e NDK_APP_DST_DIR=lame-build
dieOnError "ERROR: failed to build libmp3lame for ${FLAVOR}"

mkdir -p "${ROOT}/${DST_DIR}" "${ROOT}/build/${ABI_DIR}"
cp -f "../obj/local/${TARGET_ABI}/libmp3lame.so" "${ROOT}/${DST_DIR}/"
cp -f "../obj/local/${TARGET_ABI}/libmp3lame.so" "${ROOT}/lame-3.100/"
cp -f "../obj/local/${TARGET_ABI}/libmp3lame.so" "${ROOT}/build/${ABI_DIR}/"
