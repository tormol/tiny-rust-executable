#!/usr/bin/env bash
set -e

echo $#
cargo_out_dir="target/release"
if [ $# -eq 1 ]; then
   extra_cargo_args="--target $1"
   cargo_out_dir="target/$1/release"
elif [ $# -ge 2 ]; then
   echo "Too many arguments" >&2
   exit 1
fi

for d in rustc cargo ar ld objcopy nasm hexdump; do
    which $d >/dev/null || (echo "Can't find $d, needed to build" >&2; exit 1)
done

printf "Tested on rustc 1.46.0-nightly (346aec9b0 2020-07-11)\nYou have  "
rustc --version
echo

set -x

cargo build --release --verbose $extra_cargo_args

# tinyrust.tinyrust.3a1fbbbh-cgu.0.rcgu.o
OBJECT=$(ar t "$cargo_out_dir"/libtinyrust.rlib | grep '.o$')
ar x "$cargo_out_dir"/libtinyrust.rlib "$OBJECT"

objdump -dr "$OBJECT"
echo

ld --gc-sections -e main -T script.ld -o payload "$OBJECT"
objcopy -j combined -O binary payload payload.bin

ENTRY=$(nm --format=posix payload | grep '^main ' | awk '{print $3}')
nasm -f bin -o tinyrust -D entry=0x$ENTRY elf.s

chmod +x tinyrust
hexdump -C tinyrust
wc -c tinyrust
