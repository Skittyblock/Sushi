export TARGET = iphone:clang::13.0
export ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

SUBPROJECTS = tweak prefs

include $(THEOS_MAKE_PATH)/aggregate.mk
