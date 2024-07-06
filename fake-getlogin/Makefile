.PHONY: all clean

all: fake-getlogin.so

fake-getlogin.so: fake-getlogin.c
	${CC} --shared -o fake-getlogin.so fake-getlogin.c -ldl -fPIC

clean:
	-rm fake-getlogin.so
