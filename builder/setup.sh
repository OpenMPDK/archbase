#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2020 Samsung Electronics Co., Ltd. All Rights Reserved.
#
# Written by Klaus Jensen <k.jensen@samsung.com>

SERVICES=(
  "sshd" "haveged"
  "systemd-networkd" "systemd-resolved"
)

# locales
echo "en_US.UTF-8 UTF-8" >/etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >/etc/locale.conf

cat <<EOF >/etc/cloud/cloud.cfg.d/90_datasource.cfg
# generated by archbase
datasource_list: [ NoCloud, ConfigDrive, DigitalOcean ]
EOF

SERVICES=( "${SERVICES[@]}"
  # cloud-init
  "cloud-init-local"
  "cloud-init"
  "cloud-config"
  "cloud-final"
)

cat <<EOF >/etc/systemd/system/mount-shared-kernel-dir.service
# This neat trick makes it easy to boot a custom kernel with QEMU and have the
# guest mount the kernel build dir locally such that modules can be loaded.
#
# Cribbed and slightly modified from a systemd unit-file created by Omar
# Sandoval:
#
#    https://github.com/osandov/osandov-linux/blob/master/scripts/vm-modules-mounter.service
#
#
# MIT License
#
# Copyright (c) 2021 Omar Sandoval
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is furnished
# to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
# OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
# OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[Unit]
Description=Mount shared kernel build dir
DefaultDependencies=no
After=systemd-remount-fs.service
Before=local-fs-pre.target systemd-modules-load.service systemd-udevd.service kmod-static-nodes.service umount.target
Conflicts=umount.target
RefuseManualStop=true
ConditionPathExists=!/lib/modules/%v/kernel

[Install]
WantedBy=local-fs-pre.target

[Service]
Type=oneshot
RemainAfterExit=yes
# Mount with x-initrd.mount so that systemd will ignore these mounts, because
# we want to unmount them ourselves.
ExecStart=/bin/mount -t tmpfs -o mode=755,strictatime,x-mount.mkdir,x-initrd.mount tmpfs /lib/modules/%v
ExecStart=/bin/mount -t 9p -o trans=virtio,ro,x-mount.mkdir,x-initrd.mount kernel_dir /lib/modules/%v/build
ExecStart=/bin/ln -s build/modules.order /lib/modules/%v/modules.order
ExecStart=/bin/ln -s build/modules.builtin /lib/modules/%v/modules.builtin
ExecStart=/bin/ln -s build /lib/modules/%v/kernel
ExecStart=/bin/depmod %v
# Lazy unmount to deal with stuff like udevd which keeps the mount busy.
ExecStopPost=/bin/sh -c 'if mountpoint -q /lib/modules/%v/build; then umount -l /lib/modules/%v/build; fi'
ExecStopPost=/bin/sh -c 'if mountpoint -q /lib/modules/%v; then umount -l /lib/modules/%v; fi'
ExecStopPost=/usr/bin/find /lib/modules -mindepth 1 -maxdepth 1 -type d -empty -delete
ExecReload=/bin/depmod %v
EOF

SERVICES=( "${SERVICES[@]}"
  # early kernel modules mounter
  "mount-shared-kernel-dir"
)

# enable various systemd services
systemctl daemon-reload

for service in "${SERVICES[@]}"; do
  systemctl enable "$service"
done

# setup grub
cat << "EOF" > /etc/default/grub
GRUB_DEFAULT=0
GRUB_TIMEOUT=3
GRUB_DISTRIBUTOR="Arch"
GRUB_TERMINAL="console serial"
GRUB_SERIAL_COMMAND="serial --speed=115200"
GRUB_GFXMODE=auto
GRUB_GFXPAYLOAD_LINUX=keep
GRUB_CMDLINE_LINUX_DEFAULT=""
GRUB_CMDLINE_LINUX="console=ttyS0,115200"
GRUB_DISABLE_RECOVERY=true
EOF

grub-install --target=i386-pc "$TARGET_DEV"
grub-mkconfig -o /boot/grub/grub.cfg

# rebuild initramfs to include virtio drivers
sed -i -e 's/^MODULES=.*$/MODULES=(virtio_rng virtio_pci virtio_blk virtio_net)/' /etc/mkinitcpio.conf
mkinitcpio -n -p linux
