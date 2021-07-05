INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Sushi
Sushi_FILES = $(wildcard *.x) $(wildcard *.m)
Sushi_PRIVATE_FRAMEWORKS = MediaRemote
Sushi_CFLAGS = -fobjc-arc -I../headers

include $(THEOS_MAKE_PATH)/tweak.mk
