# common flags

LOCAL_ARM_MODE := arm
LOCAL_MODULE := $(NAME)

LOCAL_CFLAGS += \
-D_FILE_OFFSET_BITS=64 \
-DANDROID \
-march=$(ARCH) \
-finline-functions \
-ftree-vectorize

ifeq ($(findstring clang, $(NDK_TOOLCHAIN_VERSION)),)
	# GCC only.
	LOCAL_CFLAGS += \
	-mandroid \
	-fgcse-after-reload \
	-fpredictive-commoning \
	-fipa-cp-clone
else
	# Clang only.
	LOCAL_CFLAGS += \
	-Wno-deprecated-register \
	-Wno-error=incompatible-function-pointer-types \
	-Wno-error=int-conversion \
	-Wno-error=implicit-function-declaration \
	-Wno-error=implicit-int
endif

ifeq ($(APP_OPTIM),debug)
	LOCAL_CFLAGS += -DDEBUG
endif

LOCAL_CPPFLAGS += -Werror=return-type
LOCAL_LDFLAGS += -march=$(ARCH) -Wl,-z,max-page-size=16384

TARGET_ARCH_ABI := arm64-v8a
LOCAL_CFLAGS += -D__TARGET_ARCH_ARM=8 -D__AARCH64__

ifeq ($(VFP),neon)
	LOCAL_ARM_NEON := true
	LOCAL_CFLAGS += -mtune=generic -D__NEON__
	ifeq ($(findstring clang, $(NDK_TOOLCHAIN_VERSION)),)
		LOCAL_CFLAGS += -mvectorize-with-neon-quad
	endif
else
	LOCAL_ARM_NEON := false
endif
