# Teeny-Mon(itor)

A to be minimalist monitor program for my testing purposes. current for ARM only.

## Requirements and building

You need ``qemu-system-arm``, ``arm-none-eabi-``(gcc?) and a brain. 

```bash
make            to build the code
make clean      to clean our garbage and results
```

to test:

```bash
qemu-system-arm -M versatilepb -cpu arm1176 -kernel monitor.bin -nographic
```

## resources and attribution
- https://wiki.osdev.org/ARM_Integrator-CP_Bare_Bones
- https://wiki.osdev.org/ARM_Integrator-CP_PL110_Dirty
- 






## Extra notes

These notes belong to a project im working on. i needed a monitor program and the following notes might turn into a seperate manual/tutorial at some point.

```bash
strings dump.bin | grep -Ei "squashfs|cramfs|rootfs|zlib|uImage|ELF"
hexdump -C dump.bin | grep '78 01'
Header	Meaning
78 01	No compression / low compression
78 9C	Default compression
78 DA	Best compression
```
```bash
hexdump -C dump.bin | grep '78 01'
00007dc0  a6 88 fb 15 80 8f ec 0f  12 ab 78 01 ca 16 04 76  |..........x....v|
...

```bash
printf "%d\n" 0x7dCA
32202
dd if=dump.bin of=zlib_try.bin bs=1 skip=32202
```
or:
```bash
skip=$((0xA500))

dd if=dump.bin of=zlib_try.bin bs=1 skip=$((0x7DCA))

zlib-flate -uncompress < zlib_try.bin > decomp.bin
```

### Succes
```bash
dd if=dump.bin of=zlib_try.bin bs=1 skip=$((0x31e34))
844236+0 records in
844236+0 records out
844236 bytes (844 kB, 824 KiB) copied, 0.33602 s, 2.5 MB/s
```
or not, empty :(



### Decomp

Here is a snipped of real code, I try to investigate
```bash
30a5a5f000000a00d0120014021e0000
e814001200000000cc1200140100fc06
c01700128f9503007411001200000000
4a0100ea430100ea430100ea430100ea
430100ea0000a0e1420100ea420100ea
```

```bash
 dd if=dump.bin of=zlib_try.bin bs=1 count=$((0x50))

arm-none-eabi-objdump -b binary -m arm -D zlib_try.bin
```
```bash
00000000 <.data>:
   0:   f0a5a530                        @ <UNDEFINED> instruction: 0xf0a5a530
   4:   000a0000        andeq   r0, sl, r0
   8:   140012d0        strne   r1, [r0], #-720 @ 0xfffffd30
   c:   00001e02        andeq   r1, r0, r2, lsl #28
  10:   120014e8        andne   r1, r0, #232, 8 @ 0xe8000000
  14:   00000000        andeq   r0, r0, r0
  18:   140012cc        strne   r1, [r0], #-716 @ 0xfffffd34
  1c:   06fc0001        ldrbteq r0, [ip], r1
  20:   120017c0        andne   r1, r0, #192, 14        @ 0x3000000
  24:   0003958f        andeq   r9, r3, pc, lsl #11
  28:   12001174        andne   r1, r0, #116, 2
  2c:   00000000        andeq   r0, r0, r0
  30:   ea00014a        b       0x560
  34:   ea000143        b       0x548
  38:   ea000143        b       0x54c
  3c:   ea000143        b       0x550
  40:   ea000143        b       0x554
  44:   e1a00000        nop                     @ (mov r0, r0)
  48:   ea000142        b       0x558
  4c:   ea000142        b       0x55c
```


### Test qemu

```bash
qemu-system-arm -M versatilepb -cpu arm1176 -kernel instructions.bin -nographic -S -gdb tcp::1234
```

use ``arm-none-eabi-gdb``

inside gdb, now use:
```bash
target remote localhost:1234
set architecture arm
set disassemble-next-line on
break *0x30  # Set a breakpoint at the jump instruction (e.g., 0x30).
continue     # Start execution.
step         # Step through instructions.
```
another way is:
```bash
qemu-system-arm -M versatilepb -cpu arm1176 -kernel instructions.bin -nographic -S -gdb tcp::1234 -semihosting-config enable=on,target=native
set $pc=0x30  # Set the program counter to the desired address.
continue      # Start execution from the new address.
```


### Qemu arm

Building custom arm, as I needed it, or you alter hardware?

```bash
git clone https://gitlab.com/qemu-project/qemu.git
cd qemu

mkdir build
cd build
../configure --target-list=arm-softmmu \
             --enable-slirp \
             --enable-fdt \
             --enable-gtk \
             --enable-sdl \
             --disable-fuse
             
make -j$(nproc)
```

### patch bytes

to patch bytes in a file one could use a hexeditor or:
```bash
echo -ne "\xE1\xA0\x00\x00" | dd of=test.bin bs=1 seek=$((0x0000)) conv=notrunc
```

where seek is a hex adress (0x0000 in this example) and the bytes are ``E1 A0 00 00``

### make symbols/elf

Not tested yet, but to fake make symbols on a raw binary
Use objcopy to wrap the binary in an ELF file:
```bash
arm-none-eabi-objcopy -I binary -O elf32-littlearm -B arm instructions.bin instructions.elf
```

Use objcopy to specify a starting address (e.g., 0x10000):
```bash
arm-none-eabi-objcopy --set-section-flags .data=alloc,load --change-section-address .data=0x10000 instructions.elf
```

Again, how to run now with elf file:
```bash
qemu-system-arm -M versatilepb -cpu arm1176 -kernel instructions.elf -nographic -S -gdb tcp::1234
```

do the gdb thing:
```bash
target remote localhost:1234
break *0x10000  # Set a breakpoint at the start of the binary.
continue        # Start execution.
step            # Step through instructions.
```

### set pc and step

extra tips with gdb:
```bash
target remote localhost:1234
set architecture arm
set $pc=0x10000  # Set the program counter to the start of the binary.
x/10i $pc        # Examine the instructions at the current PC.
stepi            # Step through instructions one by one.

x/10xb $pc       # for examining the memory of pc in hex

x/16xb 0x10000   #examine 16 bytes at 0x10000
```


### first jumpy

WHile researching my binairy. it first real noteworthy jump when here:
 
``break *0x59c``
```bash
0x560:       mov     sp, #128, 16    @ 0x800000
   0x564:       ldr     r0, [pc, #52]   @ 0x5a0
   0x568:       ldr     r1, [r0]
   0x56c:       orr     r1, r1, #128    @ 0x80
   0x570:       str     r1, [r0]
   0x574:       ldr     r1, [pc, #40]   @ 0x5a4
   0x578:       mov     r2, #64, 16     @ 0x400000
   0x57c:       mov     r4, r2
   0x580:       ldr     r3, [pc, #32]   @ 0x5a8
   0x584:       sub     r3, r3, r1
   0x588:       lsr     r3, r3, #2
   0x58c:       ldr     r0, [r1], #4
   0x590:       str     r0, [r2], #4
   0x594:       subs    r3, r3, #1
   0x598:       bne     0x58c
   0x59c:       mov     pc, r4            # became 0x400000
   0x5a0:       strne   r1, [r0], #-392 @ 0xfffffe78
   0x5a4:       andeq   r0, r0, r12, ror r5
   0x5a8:       andseq  r10, pc, r0
```

### 0x400000

```bash
    0x400000:    mov     r4, r2            r2 into r4
    0x400004:    ldr     r3, [pc, #32]   @ 0x40002c (0x00)    load that into r3
    0x400008:    sub     r3, r3, r1    # subtract r3 with r1 and store in r3
    0x40000c:    lsr     r3, r3, #2    #shift two bytes (divide by 4), how many chunks

    0x400010:    ldr     r0, [r1], #4    # load byte from location r1 into r0
    0x400014:    str     r0, [r2], #4    # store the bytes from r0 to where R2 points at
    0x400018:    subs    r3, r3, #1      # 

    0x40001c:    bne     0x400010
    0x400020:    mov     pc, r4
    0x400024:    strne   r1, [r0], #-392 @ 0xfffffe78
```

``break *0x40001c``

```bash
0x40002c:       0x00    0xa0    0x1f    0x00    0x4c    0x10    0x9f    0xe5
0x400034:       0x80    0x2a
```

So basicly sofar ive found some jump to various functions and one of them, the 0x40000 one is copying a bunch of data from 1 location to another. it is pulling the info from further in the file, including how many chunks. it copies 4bytes a time.