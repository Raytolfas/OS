SHELL := /bin/bash

.PHONY: help kernel plasma-rootfs initramfs iso qemu all

help:
	@echo "Raytolfas OS D1"
	@echo "Targets:"
	@echo "  make kernel         - build Linux kernel into build/kernel"
	@echo "  make plasma-rootfs  - build KDE Plasma rootfs into /var/lib/raytolfas/plasma-rootfs"
	@echo "  make initramfs      - build live boot initramfs"
	@echo "  make iso            - assemble and build bootable live ISO image"
	@echo "  make qemu           - boot the generated ISO in QEMU"
	@echo "  make all            - build kernel + rootfs + ISO"

kernel:
	bash ./scripts/linux/build-kernel.sh

plasma-rootfs:
	bash ./scripts/linux/build-plasma-rootfs.sh

initramfs:
	bash ./scripts/linux/build-live-initramfs.sh

iso:
	bash ./scripts/linux/build-iso.sh

qemu:
	bash ./scripts/linux/run-qemu.sh

all: kernel plasma-rootfs iso
