TARGET := iphone:clang:latest:15.0
ARCHS := arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := AllWallpapers

AllWallpapers_FILES := Tweak.xm
AllWallpapers_CFLAGS := -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 PosterBoard 2>/dev/null || true"
