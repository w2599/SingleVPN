TARGET := iphone:clang:16.5:15.0


include $(THEOS)/makefiles/common.mk

SUBPROJECTS += SingleVPNPrefs

include $(THEOS_MAKE_PATH)/aggregate.mk

TWEAK_NAME := SingleVPN

SingleVPN_FILES += SingleVPN.x
SingleVPN_FILES += UIColor+.m
SingleVPN_CFLAGS += -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "sbreload"