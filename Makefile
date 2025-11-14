flags :=
FASMENV=

.PHONY: clean run

all: bin/pong.bin

bin:
	mkdir -p bin

bin/pong.bin: pong.asm | bin
	fasm $^ $@

run:
	qemu-system-i386 -hda ./bin/pong.bin -m 512

dump:
	objdump -M intel -D -M i8086 -b binary -m i8086 ./bin/pong.bin

clean:
	rm -rf bin/*.o bin/*.bin