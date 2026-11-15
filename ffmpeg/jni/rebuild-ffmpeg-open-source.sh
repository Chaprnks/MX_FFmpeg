#!/bin/bash
ROOT=$(cd "$(dirname "$0")"; pwd)
cd "${ROOT}"
source ./shell_util.sh
source ./ENV

if [ -z "${NDK}" ] || [ ! -d "${NDK}" ]; then
    if [ -z "${ANDROID_HOME}" ]; then
        home=$(guessAndroidSdk)
        export ANDROID_HOME="$home"
    fi
    NDK_VERSION=27.2.12479018
    if [ -d "${ANDROID_HOME}/ndk/${NDK_VERSION}" ]; then
        export NDK="${ANDROID_HOME}/ndk/${NDK_VERSION}"
    else
        latest_ndk=$(ls -1d "${ANDROID_HOME}/ndk/"* 2>/dev/null | sort -V | tail -n 1)
        export NDK="${latest_ndk}"
    fi
fi

export SKIP_COPY=true
./rebuild-ffmpeg.sh "${1:-all}"
