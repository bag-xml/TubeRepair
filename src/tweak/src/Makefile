TARGET := iphone:clang:latest:7.0
export TARGET=iphone:clang:6.0
ARCHS= armv7 armv7s

INSTALL_TARGET_PROCESSES = SpringBoard


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TubeRepair-Tweak

TubeRepair-Tweak_FILES = Tweak.x
TubeRepair-Tweak_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += tuberepair-pref
include $(THEOS_MAKE_PATH)/aggregate.mk
