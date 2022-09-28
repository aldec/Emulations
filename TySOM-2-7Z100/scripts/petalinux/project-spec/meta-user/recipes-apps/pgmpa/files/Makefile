APP = pgmpa

# Add any other object files to this list below
APP_OBJS = pgmpa.o
#LDFLAGS=-Wl,--hash-style=gnu

all: build

build: $(APP)
	
$(APP): $(APP_OBJS)
	$(CC) -o $@ $(APP_OBJS) $(LDFLAGS) $(LDLIBS)
clean:
	rm -f $(APP) *.o

