# DEFINES := -DMEASURE_TIME_DMA
# DEFINES := -DMEASURE_TIME_COPYHI
# DEFINES := -DMEASURE_TIME_PROCESS
DEFINES :=

APP_CFLAGS := -Wall -Wextra -lstdc++ -std=c++11 -Wno-pedantic -Wno-c++98-compat -Wno-c++98-compat-pedantic -pthread

all:
	gcc -o control control.cpp $(APP_CFLAGS)
	g++ -o streamer streamer.cpp $(APP_CFLAGS) $(DEFINES)

clean:
	rm -f control streamer
