CC      = powerpc64le-linux-gnu-gcc
LD      = powerpc64le-linux-gnu-ld
OBJCOPY = powerpc64le-linux-gnu-objcopy

CFLAGS  = -nostdlib -ffreestanding -O2 -mcpu=power9
LDFLAGS = -T link.ld

all: firmware.hex

firmware.o: firmware.c
	$(CC) $(CFLAGS) -c firmware.c -o firmware.o

firmware.elf: firmware.o link.ld
	$(LD) $(LDFLAGS) firmware.o -o firmware.elf

firmware.bin: firmware.elf
	$(OBJCOPY) -O binary firmware.elf firmware.bin

firmware.hex: firmware.bin
	hexdump -v -e '1/8 "%016x\n"' firmware.bin > firmware.hex

clean:
	rm -f firmware.o firmware.elf firmware.bin firmware.hex

.PHONY: all clean
