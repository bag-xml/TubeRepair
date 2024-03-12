TARGET := iphone:clang:latest:7.0
export TARGET=iphone:clang:6.0
ARCHS= armv7

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = tuberepair-pref

tuberepair-pref_FILES = YTRRootListController.m
tuberepair-pref_FRAMEWORKS = UIKit
tuberepair-pref_PRIVATE_FRAMEWORKS = Preferences
tuberepair-pref_INSTALL_PATH = /Library/PreferenceBundles
tuberepair-pref_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
