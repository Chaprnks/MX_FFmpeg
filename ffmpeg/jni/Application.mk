NDK_TOOLCHAIN_VERSION := clang
APP_PLATFORM ?= android-21
APP_SUPPORT_FLEXIBLE_PAGE_SIZES := true
APP_STL := c++_shared

ifeq ($(MX_DEBUG),1)
APP_OPTIM := debug
else
APP_OPTIM := release
endif
APP_STRIP_MODE := none
