![Raytolfas OS Banner](https://capsule-render.vercel.app/api?type=waving&height=300&color=a250ff&section=header&reversal=false&text=Raytolfas+OS&textBg=false&fontColor=fff&fontSize=70&fontAlign=50&fontAlignY=50&animation=fadeIn&rotate=0&strokeWidth=0&descSize=20&descAlign=50&descAlignY=60)

# Raytolfas OS

[![Linux](https://badgen.net/badge/Linux/kernel?color=FCC624&icon=linux)](https://kernel.org)
[![KDE Plasma](https://badgen.net/badge/KDE/Plasma?color=1D99F3)](https://kde.org)
[![Wayland](https://badgen.net/badge/Display/Wayland?color=153F75)](https://wayland.freedesktop.org)
[![Waydroid](https://badgen.net/badge/Container/Waydroid?color=3DDC84)](https://waydro.id)
[![Proton-GE](https://badgen.net/badge/Compatibility/Proton-GE?color=66C0F4)](https://github.com/GloriousEggroll/proton-ge-custom)
[![Limine](https://badgen.net/badge/Bootloader/Limine?color=111111)](https://limine-bootloader.org/)

Desktop Linux distribution built with KDE Plasma on Wayland, featuring out-of-the-box Windows (`.exe`) and Android (`.apk`) runtime support, powered by the Limine bootloader.

## Download:
[Releases](https://github.com/Raytolfas/OS/releases)

## Key Features

- **Compatibility:** Integrated Proton-GE and pre-configured Waydroid container.
- **Boot & Installer:** Limine bootloader with a customized Calamares installer.
- **System Utilities:** Built-in `Welcome` and `Control Center`.

## Repository Layout

```text
├── apps/     # Native apps (Welcome, Control Center)
├── assets/   # Wallpapers, sound themes, logos
├── boot/     # Limine configs and boot manifests
├── config/   # Calamares installer & Polkit security rules
├── kernel/   # Kernel build fragments and configs
└── scripts/  # Build pipeline for initramfs, rootfs, and ISO
```

## Building from Source

### Prerequisites

```bash
sudo apt update && sudo apt install -y \
  build-essential libncurses-dev bison flex libssl-dev libelf-dev xorriso curl git
```

### Build Targets

```bash
# Build iso
make iso

# Test in qemu:
make qemu
```

## License

Distributed under the [GPL-3.0 License](LICENSE).
