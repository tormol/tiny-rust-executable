# Using Rust to make a 137-byte static AMD64 Linux binary

[![Build Status](https://api.cirrus-ci.com/github/tormol/tiny-rust-executable.svg)](https://cirrus-ci.com/github/tormol/tiny-rust-executable)

`elf.s` contains a custom ELF header, but no instructions.
All of the machine code comes out of `rustc`.
(While most of the operations originate from inline assembly, LLVM replaces the instructions with more compact ones!)

This project is built by running the `./build.sh` script instead of `cargo build`: Making the binary this small requires post-processing steps which cargo doesn't support.  
Requires nightly Rust because it uses inline assembly (through the `sc` crate) to make direct system calls.

[Blog post about this demo](http://mainisusuallyafunction.blogspot.com/2015/01/151-byte-static-linux-binary-in-rust.html), by Keegan McAllister who originally created it.

## Example

```sh
$ ./build.sh
Tested on rustc 1.85.0 (4d91de4e4 2025-02-17)
You have  rustc 1.85.0 (4d91de4e4 2025-02-17)

+ cargo build --release --verbose
    Updating crates.io index
     Locking 1 package to latest compatible version
  Downloaded sc v0.2.7
  Downloaded 1 crate (39.6KiB) in 0.88s
   Compiling sc v0.2.7
     Running `/home/tbm/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/bin/rustc --crate-name sc --edition=2015 /home/tbm/.cargo/registry/src/index.crates.io-1949cf8c6b5b557f/sc-0.2.7/src/lib.rs --error-format=json --json=diagnostic-rendered-ansi,artifacts,future-incompat --diagnostic-width=137 --crate-type lib --emit=dep-info,metadata,link -C opt-level=z -C panic=abort -C embed-bitcode=no --check-cfg 'cfg(docsrs,test)' --check-cfg 'cfg(feature, values())' -C metadata=de0ba5d176876c9c -C extra-filename=-e50ec66b37f4e2cb --out-dir /home/tbm/p/rust/tiny-rust-demo/target/release/deps -C strip=debuginfo -L dependency=/home/tbm/p/rust/tiny-rust-demo/target/release/deps --cap-lints allow -C relocation-model=static`
   Compiling tiny-rust-executable v0.5.1 (/home/tbm/p/rust/tiny-rust-demo)
     Running `/home/tbm/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/bin/rustc --crate-name tinyrust --edition=2015 tinyrust.rs --error-format=json --json=diagnostic-rendered-ansi,artifacts,future-incompat --diagnostic-width=137 --crate-type lib --emit=dep-info,metadata,link -C opt-level=z -C panic=abort -C embed-bitcode=no --check-cfg 'cfg(docsrs,test)' --check-cfg 'cfg(feature, values())' -C metadata=76aa331090f20463 -C extra-filename=-f769982e789cd78c --out-dir /home/tbm/p/rust/tiny-rust-demo/target/release/deps -C strip=debuginfo -L dependency=/home/tbm/p/rust/tiny-rust-demo/target/release/deps --extern sc=/home/tbm/p/rust/tiny-rust-demo/target/release/deps/libsc-e50ec66b37f4e2cb.rmeta -C relocation-model=static`
    Finished `release` profile [optimized] target(s) in 0.06s
++ ar t target/release/libtinyrust.rlib
++ grep '.o$'
+ OBJECT=tinyrust-f769982e789cd78c.tinyrust.35d04aaf99cb8b97-cgu.0.rcgu.o
+ ar x target/release/libtinyrust.rlib tinyrust-f769982e789cd78c.tinyrust.35d04aaf99cb8b97-cgu.0.rcgu.o
+ objdump -dr tinyrust-f769982e789cd78c.tinyrust.35d04aaf99cb8b97-cgu.0.rcgu.o

tinyrust-f769982e789cd78c.tinyrust.35d04aaf99cb8b97-cgu.0.rcgu.o:     file format elf64-x86-64


Disassembly of section .text.main:

0000000000000000 <main>:
   0:   6a 01                   push   $0x1
   2:   58                      pop    %rax
   3:   6a 07                   push   $0x7
   5:   5a                      pop    %rdx
   6:   be 08 00 40 00          mov    $0x400008,%esi
   b:   48 89 c7                mov    %rax,%rdi
   e:   0f 05                   syscall
  10:   6a 3c                   push   $0x3c
  12:   58                      pop    %rax
  13:   31 ff                   xor    %edi,%edi
  15:   0f 05                   syscall
  17:   0f 0b                   ud2
+ echo

+ ld --gc-sections -e main -T script.ld -o payload tinyrust-f769982e789cd78c.tinyrust.35d04aaf99cb8b97-cgu.0.rcgu.o
+ objcopy -j combined -O binary payload payload.bin
++ nm --format=posix payload
++ grep '^main '
++ awk '{print $3}'
+ ENTRY=400070
+ nasm -f bin -o tinyrust -D entry=0x400070 elf.s
+ chmod +x tinyrust
+ hexdump -C tinyrust
00000000  7f 45 4c 46 02 01 01 09  48 65 6c 6c 6f 21 0a 00  |.ELF....Hello!..|
00000010  02 00 3e 00 01 00 00 00  70 00 40 00 00 00 00 00  |..>.....p.@.....|
00000020  38 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |8...............|
00000030  00 00 00 00 38 00 38 00  01 00 00 00 07 00 00 00  |....8.8.........|
00000040  00 00 00 00 00 00 00 00  00 00 40 00 00 00 00 00  |..........@.....|
00000050  00 00 40 00 00 00 00 00  89 00 00 00 00 00 00 00  |..@.............|
00000060  89 00 00 00 00 00 00 00  00 10 00 00 00 00 00 00  |................|
00000070  6a 01 58 6a 07 5a be 08  00 40 00 48 89 c7 0f 05  |j.Xj.Z...@.H....|
00000080  6a 3c 58 31 ff 0f 05 0f  0b                       |j<X1.....|
00000089
+ wc -c tinyrust
137 tinyrust

$ ./tinyrust
Hello!
```

## License

Licensed under either of

* Apache License, Version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
* MIT license ([LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT)

at your option.

### Contribution

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in the work by you, as defined in the Apache-2.0 license, shall be dual licensed as above, without any additional terms or conditions.

## See Also

* [A 99-byte x86 (32-bit) Go executable](https://github.com/xaionaro-go/tinyhelloworld)
