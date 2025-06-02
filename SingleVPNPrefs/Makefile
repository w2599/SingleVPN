INSTALL_TARGET_PROCESSES := Preferences

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME := SingleVPNPrefs

SingleVPNPrefs_FILES += SingleVPNRootListController.m
SingleVPNPrefs_FILES += SingleVPNColorCell.m
SingleVPNPrefs_FILES += ../UIColor+.m
SingleVPNPrefs_CFLAGS += -fobjc-arc

SingleVPNPrefs_LDFLAGS += -FFrameworks

SingleVPNPrefs_FRAMEWORKS += UIKit
SingleVPNPrefs_PRIVATE_FRAMEWORKS += Preferences
SingleVPNPrefs_INSTALL_PATH += /Library/PreferenceBundles

include $(THEOS_MAKE_PATH)/bundle.mk