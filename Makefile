SHELLCHECK_EXCLUDE :=
MIRROR ?= https://mirrors.kernel.org/archlinux

check:
	shellcheck -x archbase builder/*.sh

builder:
	docker build --tag archbuild --build-arg mirror=$(MIRROR) builder/

.PHONY: check builder
