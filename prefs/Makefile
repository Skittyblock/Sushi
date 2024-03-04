TARGET = iphone:clang::12.0 # need to set lower deployment target for skittyprefs

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = Sushi
Sushi_FILES = $(wildcard *.m) $(wildcard SkittyPrefs/*.m)
Sushi_INSTALL_PATH = /Library/PreferenceBundles
Sushi_PRIVATE_FRAMEWORKS = Preferences
Sushi_CFLAGS = -fobjc-arc -I../headers

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/$(BUNDLE_NAME).plist$(ECHO_END)
