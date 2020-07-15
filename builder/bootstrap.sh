#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2020 Samsung Electronics Co., Ltd. All Rights Reserved.
#
# Written by Klaus Jensen <k.jensen@samsung.com>

set -euo pipefail

INSTALLDIR="/install"

PACKAGES=(
  # base system
  base sudo grub openssh polkit linux haveged cloud-init cloud-utils
)

USAGE="usage: archbuild COMMAND [OPTION...]

Commands:
  build     bootstrap an Arch Linux installation on a device
  shell     drop to shell

Options for the 'build' command:
  -d, --target-dev      block device to install grub on
  -p, --extra-packages  extra packages to add"

_build() {
  short="d:,p:"
  long="target-dev:,extra-packages:"

  if ! tmp=$(getopt -o "+${short}" --long "$long" -n "${BASH_SOURCE[0]}" -- "$@"); then
    exit 1
  fi

  eval set -- "$tmp"
  unset tmp

  while true; do
    case "$1" in
      '-d' | '--target-dev' )
        export TARGET_DEV="$2"; shift 2
        ;;

      '-p' | '--extra-packages' )
        if ! IFS=',' read -r -a PACKAGES_EXTRA <<<"$2"; then
          >&2 echo "could not read packages"
          exit 1
        fi

        PACKAGES=( "${PACKAGES[@]}" "${PACKAGES_EXTRA[@]}" )

        shift 2
        ;;

      '--' )
        shift; break
        ;;

      * )
        echo "$USAGE" >&2
        exit 1
        ;;
    esac
  done

  if [[ ! -v TARGET_DEV ]]; then
    >&2 echo "target-dev must be specified"
    exit 1
  fi

  echo "bootstrap.sh: executing pacstrap"
  pacstrap "$INSTALLDIR" --noprogressbar "${PACKAGES[@]}"

  echo "bootstrap.sh: generating fstab"
  echo "LABEL=rootfs / ext4 rw,relatime 0 1" >"${INSTALLDIR}/etc/fstab"

  cp "/setup.sh" "${INSTALLDIR}/setup.sh"
  arch-chroot "$INSTALLDIR" "/setup.sh"
}

_main() {
  subcmd="$1"; shift

  case "$subcmd" in
    "shell" )
      arch-chroot "$INSTALLDIR" /bin/bash
      ;;

    "build" )
      _build "$@"
      ;;

    * )
      echo "$USAGE" >&2
      exit 1
      ;;
  esac
}

_main "$@"
