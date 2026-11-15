LOCAL_PATH := $(call my-dir)
LAME_REL := lame-3.100/libmp3lame

include $(CLEAR_VARS)

LOCAL_MODULE := mp3lame

LOCAL_CFLAGS += \
-Dieee754_float32_t=float \
-DSTDC_HEADERS \
-DHAVE_STDINT_H \
-DHAVE_INTTYPES_H \
-Wno-error=incompatible-function-pointer-types \
-Wno-error=int-conversion \
-Wno-error=implicit-function-declaration \
-Wno-error=implicit-int

LOCAL_C_INCLUDES := \
$(LOCAL_PATH)/$(LAME_REL) \
$(LOCAL_PATH)/$(LAME_REL)/vector \
$(LOCAL_PATH)/lame-3.100/include

LOCAL_SRC_FILES := \
$(LAME_REL)/vector/xmm_quantize_sub.c \
$(LAME_REL)/bitstream.c \
$(LAME_REL)/encoder.c \
$(LAME_REL)/fft.c \
$(LAME_REL)/gain_analysis.c \
$(LAME_REL)/id3tag.c \
$(LAME_REL)/lame.c \
$(LAME_REL)/mpglib_interface.c \
$(LAME_REL)/newmdct.c \
$(LAME_REL)/presets.c \
$(LAME_REL)/psymodel.c \
$(LAME_REL)/quantize.c \
$(LAME_REL)/quantize_pvt.c \
$(LAME_REL)/reservoir.c \
$(LAME_REL)/set_get.c \
$(LAME_REL)/tables.c \
$(LAME_REL)/takehiro.c \
$(LAME_REL)/util.c \
$(LAME_REL)/vbrquantize.c \
$(LAME_REL)/VbrTag.c \
$(LAME_REL)/version.c

LOCAL_LDLIBS := -lm
LOCAL_LDFLAGS := \
-Wl,--version-script=$(LOCAL_PATH)/version_scripts/lame \
-Wl,--undefined-version \
-Wl,-z,max-page-size=16384

include $(BUILD_SHARED_LIBRARY)
