#!/bin/bash
ROOT=$(cd "$(dirname "$0")"; pwd)
source "${ROOT}/ENV"
source "${ROOT}/util.sh"

cd "${ROOT}"

build_type=release
debug_flag=""
for p in $*; do
  case "$p" in
    --debug )
      debug_flag="--debug"
      build_type=debug
      ;;
  esac
done

FLAVOR=$(normalize_arch "$1")
if test -z "${FLAVOR}"; then
    die "No architecture specified. Valid architectures: armeabi-v7a (neon), arm64-v8a (arm64), x86, x86_64"
fi

DST_DIR=$(get_dst_dir "${FLAVOR}")
ABI_DIR=$(get_abi_dir "${FLAVOR}")

# Ensure prerequisite libraries are built if missing (e.g., when build-ffmpeg.sh is called directly)
if [ ! -f "${ROOT}/${DST_DIR}/libmp3lame.so" ]; then
    echo "Building prerequisite libmp3lame for ${FLAVOR}..."
    ./build-libmp3lame.sh "${FLAVOR}"
    dieOnError "ERROR: failed to build libmp3lame for ${FLAVOR}"
fi

if [ ! -f "${ROOT}/${DST_DIR}/libssl.a" ] || [ ! -f "${ROOT}/openssl-1.0.2s/libssl.a" ]; then
    echo "Building prerequisite openssl for ${FLAVOR}..."
    ./build-openssl.sh "${FLAVOR}"
    dieOnError "ERROR: failed to build openssl for ${FLAVOR}"
else
    cp -f "${ROOT}/${DST_DIR}/libssl.a" "${ROOT}/openssl-1.0.2s/" 2>/dev/null || true
    cp -f "${ROOT}/${DST_DIR}/libcrypto.a" "${ROOT}/openssl-1.0.2s/" 2>/dev/null || true
fi

if [ ! -f "${ROOT}/${DST_DIR}/libsmb2.so" ]; then
    echo "Building prerequisite libsmb2 for ${FLAVOR}..."
    ./build-libsmb2.sh "${FLAVOR}"
    dieOnError "ERROR: failed to build libsmb2 for ${FLAVOR}"
fi

if [ ! -f "${ROOT}/dav1d/builddir/${ABI_DIR}/src/libdav1d.a" ]; then
    echo "Building prerequisite libdav1d for ${FLAVOR}..."
    ./build-libdav1d.sh "${FLAVOR}"
    dieOnError "ERROR: failed to build libdav1d for ${FLAVOR}"
fi

if [ ! -f "${ROOT}/${DST_DIR}/libmxutil.so" ]; then
    echo "Building prerequisite mxutil for ${FLAVOR}..."
    ./build.sh mxutil "${build_type}" build "${FLAVOR}"
    dieOnError "ERROR: failed to build mxutil for ${FLAVOR}"
fi

if [ ! -f "${ROOT}/${DST_DIR}/libfribidi.so" ]; then
    echo "Building prerequisite fribidi for ${FLAVOR}..."
    ./build.sh fribidi "${build_type}" build "${FLAVOR}"
    dieOnError "ERROR: failed to build fribidi for ${FLAVOR}"
fi

cd "${ROOT}/ffmpeg"

make clean >/dev/null 2>&1 || true
rm -f compat/strtod.d compat/strtod.o config.h config.asm

echo "=====================CONFIGURE FFMPEG FOR ${FLAVOR}====================="
make distclean >/dev/null 2>&1 || true
../config-ffmpeg.sh "${FLAVOR}" $debug_flag
if test "$?" != 0; then
    die "ERROR: failed to configure ffmpeg for ${FLAVOR}"
fi

make clean >/dev/null 2>&1 || true
make -j${CPU_CORE:-4}
if test "$?" != 0; then
    die "ERROR: failed to compile ffmpeg static libraries for ${FLAVOR}"
fi
cd "${ROOT}"

./build.sh ffmpeg.mx "${build_type}" build "${FLAVOR}"
if test "$?" != 0; then
    die "ERROR: failed to link libffmpeg.mx.so for ${FLAVOR}"
fi

mkdir -p "${ROOT}/build/${ABI_DIR}"
cp -f "${ROOT}/${DST_DIR}/"*.so "${ROOT}/build/${ABI_DIR}/" 2>/dev/null || true

if [[ -z "${SKIP_MXUTIL}" ]]; then
    copy_target "${FLAVOR}" ffmpeg.mx
fi
