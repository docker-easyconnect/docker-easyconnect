.PHONY: all clean

all: fake-hwaddr.so

fake-hwaddr.so: fake-hwaddr.c
	${CC} --shared -o fake-hwaddr.so fake-hwaddr.c -ldl -fPIC

clean:
	-rm fake-hwaddr.so
