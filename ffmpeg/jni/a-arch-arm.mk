# common flags

LOCAL_ARM_MODE := arm
LOCAL_MODULE := $(NAME)

LOCAL_CFLAGS += \
-D_FILE_OFFSET_BITS=64 \
-DANDROID \
-march=$(ARCH) \
-ftree-vectorize

# Tegra3
ifeq ($(UNALIGNED_ACCESS),0)
	LOCAL_CFLAGS += -mno-unaligned-access
	ifeq ($(OLD_FFMPEG),1)
		LOCAL_LDLIBS += -Wl,--no-warn-shared-textrel
	endif
endif

ifeq ($(findstring clang, $(NDK_TOOLCHAIN_VERSION)),)
	# GCC only.
	LOCAL_CFLAGS += \
	-mandroid \
	-fgcse-after-reload \
	-fpredictive-commoning \
	-fipa-cp-clone \
	-finline-functions
else
	# Clang only.
	LOCAL_CFLAGS += \
	-Wno-deprecated-register \
	-Wno-error=incompatible-function-pointer-types \
	-Wno-error=int-conversion \
	-Wno-error=implicit-function-declaration \
	-Wno-error=implicit-int

    ifeq ($(APP_OPTIM),debug)
        LOCAL_CFLAGS += -fno-inline-functions
        LOCAL_CFLAGS += -fstandalone-debug
    else
        LOCAL_CFLAGS += -finline-functions
    endif
endif

ifeq ($(APP_OPTIM),debug)
	LOCAL_CFLAGS += -DDEBUG
endif

LOCAL_CPPFLAGS += -Werror=return-type
LOCAL_LDFLAGS += -march=$(ARCH) -Wl,-z,max-page-size=16384

ifeq ($(ARCH),armv7-a)
	TARGET_ARCH_ABI := armeabi-v7a
	LOCAL_CFLAGS += -D__TARGET_ARCH_ARM=7
	LOCAL_LDFLAGS += -Wl,--fix-cortex-a8
else ifeq ($(ARCH),armv6)
	LOCAL_CFLAGS += -D__TARGET_ARCH_ARM=6
else
	LOCAL_CFLAGS += -mtune=xscale -D__TARGET_ARCH_ARM=5
endif

ifdef VFP
	LOCAL_CFLAGS += -mfpu=$(VFP) -mfloat-abi=softfp
else
	LOCAL_CFLAGS += -msoft-float
endif

ifeq ($(VFP),neon)
	LOCAL_ARM_NEON := true
	LOCAL_CFLAGS += -mtune=cortex-a8 -D__NEON__
	ifeq ($(findstring clang, $(NDK_TOOLCHAIN_VERSION)),)
		LOCAL_CFLAGS += -mvectorize-with-neon-quad
	endif
else
	LOCAL_ARM_NEON := false
endif
