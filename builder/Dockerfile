# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2020 Samsung Electronics Co., Ltd. All Rights Reserved.
#
# Written by Klaus Jensen <k.jensen@samsung.com>

FROM archlinux:latest

LABEL maintainer="Klaus Jensen <its@irrelevant.dk>"

ARG mirror="https://mirrors.kernel.org/archlinux"

RUN set -eux; \
	echo "Server = $mirror/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist; \
	pacman --noconfirm -Syy; \
	pacman --noconfirm -S archlinux-keyring arch-install-scripts

COPY setup.sh /
COPY bootstrap.sh /
ENTRYPOINT ["./bootstrap.sh"]
CMD ["--help"]
