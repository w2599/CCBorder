export THEOS_PACKAGE_SCHEME=rootless
export TARGET = iphone:clang:13.7:13.0

THEOS_DEVICE_IP = 192.168.86.37

PACKAGE_VERSION=$(THEOS_PACKAGE_BASE_VERSION)

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CCBorder

CCBorder_FILES = Tweak.xm
CCBorder_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
