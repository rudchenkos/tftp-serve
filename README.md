# tftp-serve - a simple TFTP server

A TFTP server with a simplified user interface. Works like a normal synchronous command line
program, does not require a global configuration file.


It takes a list of files to server from stdin in the following format:

```
<ftpname>:<filepath>
```

For example:
```
$ echo 'firmware:./build/firmware.bin' | tftp-serve 192.168.11.1
```

For more than one file, you can make a wrapper shell script like this:
```
tftp-serve 192.168.11.1 <<EOF
kernel:os/kernel.img
ramdisk:os/initramfs.img
uboot.bin:u-boot/u-boot.bin
EOF
```

Run `tftp-serve --help` to see all awailable options.

# Installation

```
$ stack install
```

The executable `tftp-serve` will be installed to `~/.local/bin`. You might want to add
that path to the environment variable `PATH`.

# The `tftp` dependency

This source includes a copy of the `tftp` library from Hackage with the
following changes:

- Set SO_REUSEADDR and SO_REUSEPORT on the listening socket
- Fixed minor build problems

The upstream library has not been updated since 2012, so as quick solution
I simply copied it and hacked it in-place.
