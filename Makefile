all: monitor.bin

monitor.bin: monitor.elf
	arm-none-eabi-objcopy -O binary $< $@

monitor.elf: monitor.S
	arm-none-eabi-as -mcpu=arm926ej-s -o monitor.o monitor.S
	arm-none-eabi-ld -Ttext=0x10000 -o $@ monitor.o

clean:
	rm -f *.o *.elf *.bin
