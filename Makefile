prefix=/dat/sys

CC=arm-apple-darwin9-gcc
LD=$(CC) 

FRAMEWORKS =  -framework CoreFoundation
FRAMEWORKS += -framework Foundation 
FRAMEWORKS += -framework UIKit 
FRAMEWORKS += -framework CoreAudio 
FRAMEWORKS += -framework OpenAL 
FRAMEWORKS += -framework CoreGraphics 
FRAMEWORKS += -framework OpenGLES 
FRAMEWORKS += -framework AudioToolbox 
FRAMEWORKS += -framework QuartzCore

LDFLAGS=-L"${prefix}/usr/lib" -F"${prefix}/System/Library/Frameworks" -bind_at_load -lobjc -lstdc++ $(FRAMEWORKS)

CFLAGS =  -O2 -I. -IParsers -IUtil -IGameObjects -IEngine -IEngine/Protocols -IEngine/Objects 
CFLAGS += -IEngine/ThemeSupport -IEngine/Transitions -IRenderers -IRenderers/UIElements 
CFLAGS += -IEngine/SoundSupport -IRenderers/UIElements/Effects
CFLAGS += -IEngine/FontSupport 
CFLAGS += -I"${prefix}/usr/include" -I"${prefix}/include" -include TapMania_Prefix.pch 
#CFLAGS += -DDEBUG	# comment for production

CPPFLAGS = $(CFLAGS)

SPECIFIC_CFLAGS = -std=c99 -fobjc-exceptions

SRC_DIRS =  Engine Engine/Transitions Engine/Objects Engine/ThemeSupport Engine/SoundSupport Engine/FontSupport
SRC_DIRS += Renderers Renderers/UIElements Renderers/UIElements/Effects GameObjects Parsers Util

MFILES = $(foreach dir,$(SRC_DIRS),$(wildcard $(dir)/*.m))
CFILES = $(foreach dir,$(SRC_DIRS),$(wildcard $(dir)/*.c))
CPPFILES = $(foreach dir,$(SRC_DIRS),$(wildcard $(dir)/*.cpp))

OBJS =  $(MFILES:.m=.o)
COBJS = $(CFILES:.c=.o)
CPPOBJS = $(CPPFILES:.cpp=.o)

LIBS_DIR = libs
STATICLIBS = $(foreach dir,$(LIBS_DIR),$(wildcard $(dir)/*.a))

TOBUILD =  $(CPPFILES:.cpp=.cppd)
TOBUILD += $(MFILES:.m=.md)
TOBUILD += $(CFILES:.c=.cd)

all: app tar deploy 

deploy:
	scp tm.tar mobile@192.168.0.143:
	ssh mobile@192.168.0.143 'sh redeploy.sh'

tar:
	tar cf tm.tar TapMania.app

app: tapmania bin production 

bin:
	$(LD) $(LDFLAGS) -v -o TapMania $(STATICLIBS) $(OBJS) $(COBJS) $(CPPOBJS) main.o
	rm -rf TapMania.app
	mkdir TapMania.app
	cp Default.png TapMania.app/
	cp TapManiaIcon.png TapMania.app/
	cp -R Data/* TapMania.app/
	cp *.plist TapMania.app/
	cp TapMania TapMania.app/

tapmania: $(TOBUILD) main.md

production:
	find TapMania.app/ -name ".svn" -type d | xargs rm -rf

%.md: %.m
	@echo "[+] Compile a .m file: $<"
	$(CC) -c $(CFLAGS) $(SPECIFIC_CFLAGS) $< -o $(<:.m=.o)

%.cd: %.c
	@echo "[+] Compile a .c file: $<"
	$(CC) -c $(CFLAGS) $(SPECIFIC_CFLAGS) $< -o $(<:.c=.o)

%.cppd: %.cpp
	@echo "[+] Compile a .cpp file: $<"
	$(CC) -c $(CPPFLAGS) $< -o $(<:.cpp=.o)

clean:
	rm -f $(OBJS) main.o TapMania
	rm -rf TapMania.app
