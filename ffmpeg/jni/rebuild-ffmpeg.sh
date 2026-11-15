#!/bin/bash
set -o pipefail
ROOT=$(cd "$(dirname "$0")"; pwd)
source "${ROOT}/ENV"
source "${ROOT}/util.sh"

cd "${ROOT}"

log_file=rebuild-ffmpeg.log
rm -f "${log_file}"

debug_flag=""
for p in $*; do
  case "$p" in
    --debug )
      debug_flag="--debug"
      ;;
  esac
done

target="${1}"
DEFAULT_TARGETS=(neon arm64 x86 x86_64)

if [[ -z "${target}" || "${target}" == 'all' ]]; then
    targets=(${DEFAULT_TARGETS[*]})
else
    norm_target=$(normalize_arch "${target}")
    for item in ${DEFAULT_TARGETS[*]} tegra2 tegra3; do
        if [[ "${norm_target}" == "${item}" ]]; then
            targets=("${norm_target}")
            break
        fi
    done

    if [[ ${#targets[@]} -eq 0 ]]; then
        die "Unsupported architecture: ${target}"
    fi
fi

build_target(){
    local arch="$1"
    local dbg="$2"

    ./build-libmp3lame.sh "${arch}"
    dieOnError "Failed to build libmp3lame for ${arch}"

    ./build-openssl.sh "${arch}"
    dieOnError "Failed to build openssl for ${arch}"

    ./build-libsmb2.sh "${arch}"
    dieOnError "Failed to build libsmb2 for ${arch}"

    ./build-libdav1d.sh "${arch}"
    dieOnError "Failed to build libdav1d for ${arch}"

    ./build.sh mxutil release build "${arch}"
    dieOnError "Failed to build mxutil for ${arch}"

    ./build.sh fribidi release build "${arch}"
    dieOnError "Failed to build fribidi for ${arch}"

    ./build-ffmpeg.sh "${arch}" ${dbg}
    dieOnError "Failed to build ffmpeg for ${arch}"
}

for item in ${targets[*]}; do
    echo "Build ${item}"
    build_target "${item}" "${debug_flag}" 2>&1 | tee -a "${log_file}"
    dieOnError "Build failed for ${item}"
    if [[ -z "${SKIP_COPY}" ]]; then
        copy_target "${item}" smb2 2>&1 | tee -a "${log_file}"
        copy_target "${item}" mp3lame 2>&1 | tee -a "${log_file}"
        copy_target "${item}" mxutil 2>&1 | tee -a "${log_file}"
        copy_target "${item}" fribidi 2>&1 | tee -a "${log_file}"
        copy_target "${item}" c++_shared 2>&1 | tee -a "${log_file}"
    fi
done
