TARGET := iphone:clang:latest:15.0

ARCHS := arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := AllWallpapers

AllWallpapers_FILES := \
    Tweak.xm \
    MCMBridge.m \
    AllWallpapersViewController.m

AllWallpapers_CFLAGS := \
    -fobjc-arc \
    -Wno-deprecated-declarations

AllWallpapers_FRAMEWORKS := \
    UIKit \
    Foundation

AllWallpapers_PRIVATE_FRAMEWORKS := \
    Preferences

AllWallpapers_LIBRARIES := \
    c++

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Preferences 2>/dev/null || true"
