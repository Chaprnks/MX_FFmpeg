MY_DIR := $(call my-dir)

LOCAL_PATH := $(MY_DIR)/ffmpeg$(FFMPEG_SUFFIX)

# avutil
include $(CLEAR_VARS)
LOCAL_MODULE    := avutil
LOCAL_SRC_FILES := libavutil/libavutil.a
include $(PREBUILT_STATIC_LIBRARY)

# avcodec
include $(CLEAR_VARS)
LOCAL_MODULE    := avcodec
LOCAL_SRC_FILES := libavcodec/libavcodec.a
include $(PREBUILT_STATIC_LIBRARY)

# avformat
include $(CLEAR_VARS)
LOCAL_MODULE    := avformat
LOCAL_SRC_FILES := libavformat/libavformat.a
include $(PREBUILT_STATIC_LIBRARY)

# avfilter
include $(CLEAR_VARS)
LOCAL_MODULE    := avfilter
LOCAL_SRC_FILES := libavfilter/libavfilter.a
include $(PREBUILT_STATIC_LIBRARY)

# swscale
include $(CLEAR_VARS)
LOCAL_MODULE    := swscale
LOCAL_SRC_FILES := libswscale/libswscale.a
include $(PREBUILT_STATIC_LIBRARY)

# swresample
include $(CLEAR_VARS)
LOCAL_MODULE    := swresample
LOCAL_SRC_FILES := libswresample/libswresample.a
include $(PREBUILT_STATIC_LIBRARY)

# Merge all static libraries.
include $(CLEAR_VARS)

LIBS := $(MY_DIR)/libs

LOCAL_SRC_FILES := ../ffmpeg.refs.c
LOCAL_CFLAGS :=

LOCAL_LDLIBS := \
-Wl,--version-script=$(MY_DIR)/version_scripts/ffmpeg \
-Wl,--undefined-version \
-Wl,-z,max-page-size=16384 \
-L$(NDK_APP_DST_DIR) \
-lsmb2 \
-lmxutil \
-lmp3lame \
-lz \
-lm \
-ldl \
-llog \
$(LIBS_EXTRA)

include $(MY_DIR)/a-arch-$(TARGET_ARCH).mk

LOCAL_STATIC_LIBRARIES := avfilter avformat avcodec swresample swscale avutil

include $(BUILD_SHARED_LIBRARY)
