MY_DIR := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_PATH := $(MY_DIR)
SRC_REL := fribidi-0.19.7/lib

LOCAL_C_INCLUDES := \
$(LOCAL_PATH)/fribidi-0.19.7 \
$(LOCAL_PATH)/fribidi-0.19.7/lib

LOCAL_SRC_FILES := \
$(SRC_REL)/fribidi.c \
$(SRC_REL)/fribidi-arabic.c \
$(SRC_REL)/fribidi-bidi.c \
$(SRC_REL)/fribidi-bidi-types.c \
$(SRC_REL)/fribidi-deprecated.c \
$(SRC_REL)/fribidi-joining.c \
$(SRC_REL)/fribidi-joining-types.c \
$(SRC_REL)/fribidi-mem.c \
$(SRC_REL)/fribidi-mirroring.c \
$(SRC_REL)/fribidi-run.c \
$(SRC_REL)/fribidi-shape.c

LOCAL_CFLAGS := \
-DHAVE_CONFIG_H \
-DPIC

ifneq ($(findstring clang, $(NDK_TOOLCHAIN_VERSION)),)
	LOCAL_CFLAGS += \
	-Wno-switch \
	-Wno-enum-conversion
endif

include $(LOCAL_PATH)/a-arch-$(TARGET_ARCH).mk

LOCAL_ASFLAGS := $(LOCAL_CFLAGS)

LOCAL_MODULE := fribidi
include $(BUILD_SHARED_LIBRARY)
