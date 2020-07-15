# archbase

`archbase` uses an Arch Linux docker container to build a lean Arch Linux qcow2
base image from any distro.

## Dependencies

* a recent docker installation
* a kernel with `nbd` support (either builtin or as a loadable module)
* `qemu-img` and `qemu-nbd` from a recent QEMU
* `sfdisk` partitioning tool
* `mke2fs` (`e2fsprogs`) with ext4 support

## Synopsis

    sudo ./archbase -m https://mirror.one.com/archlinux

This will create an Arch Linux qcow2 image in `archlinux.qcow2`.

## License

`archbase` is licensed under the GNU General Public License v3.0 or later.
