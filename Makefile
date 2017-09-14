include $(THEOS)/makefiles/common.mk

export TARGET = simulator:clang
ARCHS = x86_64

TWEAK_NAME = noNotch
noNotch_FILES = Tweak.xm
noNotch_FRAMEWORKS = UIKit CoreGraphics
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
