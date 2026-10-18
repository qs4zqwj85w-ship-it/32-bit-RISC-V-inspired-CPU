import struct, sys
d = open(sys.argv[1], 'rb').read()
d += b'\0' * (-len(d) % 4)
words = [w for (w,) in struct.iter_unpack('<I', d)]
if len(words) > 1024: sys.exit("program too big for 4 KiB memory")
open(sys.argv[2], 'w').write(''.join(f'{w:08x}\n' for w in words))
