#!/usr/bin/env python3
import sys, os, re, shutil, platform, subprocess, threading, json, urllib.request, urllib.error
from pathlib import Path
from PyQt6.QtCore import QObject, pyqtSignal, pyqtSlot, pyqtProperty, QUrl
from PyQt6.QtGui import QGuiApplication, QIcon
from PyQt6.QtQml import QQmlApplicationEngine

CURRENT_VERSION = "v26.11.0"
CURRENT_PATCH_VERSION = "v26.11.0"
UPDATE_ENDPOINT = "https://os.raytolfas.cc/update"

def _parse_ver(v):
    nums = re.findall(r"\d+", str(v))
    return tuple(int(x) for x in nums) if nums else (0,)

def _is_newer(remote, current):
    if not remote:
        return False
    return _parse_ver(remote) > _parse_ver(current)

class ControlCenterBackend(QObject):
    stateChanged = pyqtSignal()

    def __init__(self):
        super().__init__()
        self._os_version = self._get_os_version()
        self._plasma_version = self._get_plasma_version()
        self._kernel_version = platform.release()
        self._cpu_info = self._get_cpu()
        self._ram_info = self._get_ram()

        self._update_status = "Ready to check for updates"
        self._update_changelog = ""
        self._update_available = False
        self._update_checking = False
        self._download_url = ""
        self._update_progress = 0

        self._patch_status = "Ready to check for hotfixes"
        self._patch_changelog = ""
        self._patch_available = False
        self._patch_checking = False
        self._patch_url = ""
        self._patch_version = CURRENT_PATCH_VERSION

        self._snapshot_status = self._get_snapshot_status()
        self._snapshot_busy = False

        self._waydroid_status = self._get_waydroid_status()
        self._proton_version = self._get_proton_version()
        self._proton_updating = False

        self._current_theme = "dark"
        self._accent_color = "#0078D4"
        self._panel_style = "docked"
        self._window_buttons = "right"
        self._cursor_theme = "Bibata-Modern-Classic"
        self._blur_level = "balanced"
        self._minimize_effect = "magiclamp"
        self._anim_speed = "fluid"
        self._clean_status = "Ready to optimize memory and clear cache"
        self._clean_busy = False
        self._gamemode_active = self._check_gamemode()
        self._mangohud_active = self._check_mangohud()
        self._power_profile = self._get_power_profile()
        self._turbo_active = self._check_turbo()
        self._dev_status = self._get_dev_status()
        self._dev_busy = False
        self._snapshots_list = self._get_snapshots_list()

    def _check_turbo(self):
        try:
            out = subprocess.check_output(["raytolfas-turbo", "status"], stderr=subprocess.DEVNULL, text=True).strip()
            return out == "on"
        except Exception:
            return False

    def _get_dev_status(self):
        try:
            out = subprocess.check_output(["raytolfas-dev", "status"], stderr=subprocess.DEVNULL, text=True).strip()
            return json.loads(out)
        except Exception:
            return {"rust": "Not installed", "python": "Python 3", "node": "Not installed", "cpp": "Build Tools", "docker": "Not installed"}

    def _get_snapshots_list(self):
        try:
            out = subprocess.check_output(["btrfs-auto-snapshot", "list-names"], stderr=subprocess.DEVNULL, text=True).strip()
            res = []
            for s in out.splitlines():
                s = s.strip()
                if not s:
                    continue
                parts = s.split("-")
                date_str = ""
                if len(parts) >= 3 and len(parts[1]) == 8:
                    d, t = parts[1], parts[2]
                    date_str = f"{d[0:4]}-{d[4:6]}-{d[6:8]} {t[0:2]}:{t[2:4]}"
                label = parts[-1] if len(parts) > 3 else "snapshot"
                res.append({"name": s, "date": date_str or s, "label": label})
            return res
        except Exception:
            return []

    def _get_os_version(self):
        try:
            with open("/etc/os-release") as f:
                for line in f:
                    if line.startswith("PRETTY_NAME="):
                        val = line.split("=", 1)[1].strip().strip('"')
                        if val:
                            return val
        except OSError:
            return f"Raytolfas OS D1 ({CURRENT_VERSION})"
        return f"Raytolfas OS D1 ({CURRENT_VERSION})"

    def _get_snapshot_status(self):
        try:
            fstype = subprocess.check_output(["findmnt", "-n", "-o", "FSTYPE", "/"], stderr=subprocess.DEVNULL, text=True).strip()
            if fstype != "btrfs":
                return f"Root is {fstype} (Btrfs required for snapshots)"
            out = subprocess.check_output(["btrfs-auto-snapshot", "list-names"], stderr=subprocess.DEVNULL, text=True).strip()
            snaps = [s for s in out.splitlines() if s.strip()]
            if snaps:
                return f"{len(snaps)} snapshot(s) • Latest: {snaps[0]}"
            return "No snapshots yet"
        except Exception:
            return "Ready"

    def _get_proton_version(self):
        ver_file = Path("/opt/GE-Proton/version")
        if ver_file.exists():
            try:
                lines = ver_file.read_text().strip().splitlines()
                if lines:
                    parts = lines[0].split()
                    return parts[-1] if len(parts) > 1 else lines[0]
            except OSError:
                return "GE-Proton (x86_64)"
        if Path("/opt/GE-Proton").exists():
            return "GE-Proton (x86_64)"
        return "Wine / DXVK"

    def _get_power_profile(self):
        try:
            out = subprocess.check_output(["powerprofilesctl", "get"], stderr=subprocess.DEVNULL, text=True)
            return out.strip()
        except Exception:
            return "balanced"

    def _get_cpu(self):
        try:
            with open("/proc/cpuinfo") as f:
                for line in f:
                    if "model name" in line:
                        return line.split(":", 1)[1].strip()
        except OSError:
            return platform.processor() or "x86_64 Processor"
        return platform.processor() or "x86_64 Processor"

    def _get_ram(self):
        try:
            with open("/proc/meminfo") as f:
                for line in f:
                    if "MemTotal" in line:
                        kb = int(line.split()[1])
                        return f"{round(kb / 1024 / 1024, 1)} GB"
        except (OSError, ValueError, IndexError):
            return "8.0 GB"
        return "8.0 GB"

    def _get_waydroid_status(self):
        try:
            out = subprocess.check_output(["waydroid", "status"], stderr=subprocess.DEVNULL, text=True)
            if "RUNNING" in out:
                return "Running"
            return "Stopped"
        except Exception:
            return "On-demand"

    def _check_gamemode(self):
        try:
            out = subprocess.check_output(["gamemoded", "-s"], stderr=subprocess.DEVNULL, text=True)
            return "active" in out.lower()
        except Exception:
            return False

    def _check_mangohud(self):
        env_file = Path.home() / ".config" / "environment.d" / "99-raytolfas-gaming.conf"
        if env_file.exists():
            try:
                content = env_file.read_text()
                return "MANGOHUD=1" in content
            except OSError:
                return False
        return True

    def _get_plasma_version(self):
        try:
            out = subprocess.check_output(["plasmashell", "--version"], stderr=subprocess.DEVNULL, text=True).strip()
            if out:
                ver = out.split()[-1]
                return f"KDE Plasma {ver} (Wayland)"
        except Exception:
            pass
        return "KDE Plasma 6 (Wayland)"

    def _kwrite(self, cfg_file, group, key, val):
        for name in ("kwriteconfig6", "kwriteconfig5"):
            path = shutil.which(name)
            if path:
                subprocess.Popen([path, "--file", cfg_file, "--group", group, "--key", key, val], stderr=subprocess.DEVNULL)

    def _qdbus(self, args):
        for name in ("qdbus6", "qdbus"):
            path = shutil.which(name)
            if path:
                subprocess.Popen([path] + args, stderr=subprocess.DEVNULL)
                return

    @pyqtProperty(str, notify=stateChanged)
    def plasma_version(self): return self._plasma_version

    @pyqtProperty(str, notify=stateChanged)
    def os_version(self): return self._os_version

    @pyqtProperty(str, notify=stateChanged)
    def current_raw_version(self): return CURRENT_VERSION

    @pyqtProperty(str, notify=stateChanged)
    def current_patch_version(self): return CURRENT_PATCH_VERSION

    @pyqtProperty(str, notify=stateChanged)
    def kernel_version(self): return self._kernel_version

    @pyqtProperty(str, notify=stateChanged)
    def cpu_info(self): return self._cpu_info

    @pyqtProperty(str, notify=stateChanged)
    def ram_info(self): return self._ram_info

    @pyqtProperty(str, notify=stateChanged)
    def update_status(self): return self._update_status

    @pyqtProperty(str, notify=stateChanged)
    def update_changelog(self): return self._update_changelog

    @pyqtProperty(bool, notify=stateChanged)
    def update_available(self): return self._update_available

    @pyqtProperty(bool, notify=stateChanged)
    def update_checking(self): return self._update_checking

    @pyqtProperty(int, notify=stateChanged)
    def update_progress(self): return self._update_progress

    @pyqtProperty(str, notify=stateChanged)
    def patch_status(self): return self._patch_status

    @pyqtProperty(str, notify=stateChanged)
    def patch_changelog(self): return self._patch_changelog

    @pyqtProperty(bool, notify=stateChanged)
    def patch_available(self): return self._patch_available

    @pyqtProperty(bool, notify=stateChanged)
    def patch_checking(self): return self._patch_checking

    @pyqtProperty(str, notify=stateChanged)
    def patch_version(self): return self._patch_version

    @pyqtProperty(str, notify=stateChanged)
    def snapshot_status(self): return self._snapshot_status

    @pyqtProperty(bool, notify=stateChanged)
    def snapshot_busy(self): return self._snapshot_busy

    @pyqtProperty(str, notify=stateChanged)
    def waydroid_status(self): return self._waydroid_status

    @pyqtProperty(str, notify=stateChanged)
    def proton_version(self): return self._proton_version

    @pyqtProperty(bool, notify=stateChanged)
    def proton_updating(self): return self._proton_updating

    @pyqtProperty(str, notify=stateChanged)
    def current_theme(self): return self._current_theme

    @pyqtProperty(str, notify=stateChanged)
    def accent_color(self): return self._accent_color

    @pyqtProperty(str, notify=stateChanged)
    def panel_style(self): return self._panel_style

    @pyqtProperty(str, notify=stateChanged)
    def window_buttons(self): return self._window_buttons

    @pyqtProperty(str, notify=stateChanged)
    def cursor_theme(self): return self._cursor_theme

    @pyqtProperty(str, notify=stateChanged)
    def blur_level(self): return self._blur_level

    @pyqtProperty(str, notify=stateChanged)
    def minimize_effect(self): return self._minimize_effect

    @pyqtProperty(str, notify=stateChanged)
    def anim_speed(self): return self._anim_speed

    @pyqtProperty(str, notify=stateChanged)
    def clean_status(self): return self._clean_status

    @pyqtProperty(bool, notify=stateChanged)
    def clean_busy(self): return self._clean_busy

    @pyqtProperty(bool, notify=stateChanged)
    def gamemode_active(self): return self._gamemode_active

    @pyqtProperty(bool, notify=stateChanged)
    def mangohud_active(self): return self._mangohud_active

    @pyqtProperty(str, notify=stateChanged)
    def current_power_profile(self): return self._power_profile

    @pyqtProperty(bool, notify=stateChanged)
    def turbo_active(self): return self._turbo_active

    @pyqtProperty(list, notify=stateChanged)
    def snapshots_list(self): return self._snapshots_list

    @pyqtProperty(str, notify=stateChanged)
    def dev_rust_status(self): return self._dev_status.get("rust", "Not installed")

    @pyqtProperty(str, notify=stateChanged)
    def dev_python_status(self): return self._dev_status.get("python", "Not installed")

    @pyqtProperty(str, notify=stateChanged)
    def dev_node_status(self): return self._dev_status.get("node", "Not installed")

    @pyqtProperty(str, notify=stateChanged)
    def dev_cpp_status(self): return self._dev_status.get("cpp", "Not installed")

    @pyqtProperty(str, notify=stateChanged)
    def dev_docker_status(self): return self._dev_status.get("docker", "Not installed")

    @pyqtProperty(bool, notify=stateChanged)
    def dev_busy(self): return self._dev_busy

    @pyqtSlot()
    def check_for_updates(self):
        if self._update_checking:
            return
        self._update_checking = True
        self._update_status = "Checking..."
        self.stateChanged.emit()
        threading.Thread(target=self._fetch_manifest, daemon=True).start()

    @pyqtSlot()
    def check_for_patches(self):
        if self._patch_checking:
            return
        self._patch_checking = True
        self._patch_status = "Checking..."
        self.stateChanged.emit()
        threading.Thread(target=self._fetch_manifest, daemon=True).start()

    def _fetch_manifest(self):
        try:
            req = urllib.request.Request(
                UPDATE_ENDPOINT,
                headers={"User-Agent": f"RaytolfasOS/{CURRENT_VERSION} ({platform.machine()})"}
            )
            with urllib.request.urlopen(req, timeout=4) as response:
                data = json.loads(response.read().decode("utf-8"))

                remote_ver = data.get("version", "")
                dl_url = data.get("download_url", "")
                changelog = data.get("changelog", "")

                if _is_newer(remote_ver, CURRENT_VERSION):
                    self._update_available = True
                    self._download_url = dl_url
                    self._update_status = f"Update available: {remote_ver}"
                    self._update_changelog = changelog if changelog else ""
                else:
                    self._update_available = False
                    self._update_changelog = ""
                    self._update_status = "System is up to date"

                patch_ver = data.get("patch_version", "")
                p_url = data.get("patch_url", "")
                p_changelog = data.get("patch_changelog", "")

                if _is_newer(patch_ver, CURRENT_PATCH_VERSION):
                    self._patch_available = True
                    self._patch_url = p_url
                    self._patch_version = patch_ver
                    self._patch_status = f"Hotfix available: {patch_ver}"
                    self._patch_changelog = p_changelog if p_changelog else ""
                else:
                    self._patch_available = False
                    self._patch_changelog = ""
                    self._patch_status = "No new patches"

        except urllib.error.URLError:
            self._update_available = False
            self._update_status = "Server unreachable"
            self._patch_available = False
            self._patch_status = "Server unreachable"
        except Exception as e:
            self._update_available = False
            self._update_status = f"Error: {e}"
            self._patch_available = False
            self._patch_status = f"Error: {e}"

        self._update_checking = False
        self._patch_checking = False
        self.stateChanged.emit()

    @pyqtSlot()
    def create_snapshot(self):
        if self._snapshot_busy:
            return
        self._snapshot_busy = True
        self._snapshot_status = "Creating snapshot..."
        self.stateChanged.emit()
        threading.Thread(target=self._run_snapshot_cmd, args=("manual", "user"), daemon=True).start()

    @pyqtSlot()
    def rollback_snapshot(self):
        if self._snapshot_busy:
            return
        self._snapshot_busy = True
        self._snapshot_status = "Restoring latest snapshot..."
        self.stateChanged.emit()
        threading.Thread(target=self._run_snapshot_cmd, args=("rollback", "latest"), daemon=True).start()

    def _run_snapshot_cmd(self, action, arg):
        try:
            proc = subprocess.run(
                ["pkexec", "btrfs-auto-snapshot", action, arg],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True
            )
            out = proc.stdout.strip() if proc.stdout else ""
            if proc.returncode == 0:
                if action == "rollback":
                    self._snapshot_status = out or "Rollback scheduled. Please reboot."
                else:
                    self._snapshot_status = self._get_snapshot_status()
            else:
                self._snapshot_status = out or "Snapshot command failed"
        except Exception as e:
            self._snapshot_status = f"Error: {e}"
        self._snapshot_busy = False
        self.stateChanged.emit()

    @pyqtSlot()
    def update_proton_ge(self):
        if self._proton_updating:
            return
        self._proton_updating = True
        self._proton_version = "Checking GitHub for latest GE-Proton..."
        self.stateChanged.emit()
        threading.Thread(target=self._perform_proton_update, daemon=True).start()

    def _perform_proton_update(self):
        try:
            proc = subprocess.run(
                ["pkexec", "raytolfas-proton-update"],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True
            )
            if proc.returncode == 0:
                self._proton_version = self._get_proton_version()
            else:
                out = proc.stdout.strip() if proc.stdout else "Update failed"
                self._proton_version = out.splitlines()[-1] if out else "Update failed"
        except Exception as e:
            self._proton_version = f"Error: {e}"
        self._proton_updating = False
        self.stateChanged.emit()

    @pyqtSlot()
    def download_update(self):
        url = self._download_url or "https://os.raytolfas.com"
        subprocess.Popen(["xdg-open", url])

    @pyqtSlot()
    def choose_and_apply_iso(self):
        if self._update_checking:
            return
        iso_file = self._pick_iso_file()
        if iso_file and os.path.isfile(iso_file):
            self._update_checking = True
            self._update_progress = 0
            self._update_status = f"Upgrading from {os.path.basename(iso_file)}..."
            self.stateChanged.emit()
            threading.Thread(target=self._perform_iso_upgrade, args=(iso_file,), daemon=True).start()

    def _pick_iso_file(self):
        try:
            proc = subprocess.run(
                ["kdialog", "--getopenfilename", str(Path.home()), "*.iso | ISO Images (*.iso)"],
                stdout=subprocess.PIPE,
                text=True
            )
            if proc.returncode == 0 and proc.stdout.strip():
                return proc.stdout.strip()
        except OSError:
            return self._pick_iso_file_qt()
        return self._pick_iso_file_qt()

    def _pick_iso_file_qt(self):
        try:
            from PyQt6.QtWidgets import QFileDialog
            fn, _ = QFileDialog.getOpenFileName(None, "Select Raytolfas OS ISO", str(Path.home()), "ISO Images (*.iso)")
            if fn:
                return fn
        except Exception:
            return None
        return None

    @pyqtSlot()
    def download_and_apply_iso(self):
        if self._update_checking:
            return
        url = self._download_url
        if not url:
            return
        self._update_checking = True
        self._update_progress = 0
        self._update_status = "Downloading ISO..."
        self.stateChanged.emit()
        threading.Thread(target=self._perform_download_and_upgrade, args=(url,), daemon=True).start()

    def _perform_download_and_upgrade(self, url):
        try:
            target_dir = Path.home() / "Downloads"
            target_dir.mkdir(parents=True, exist_ok=True)
            iso_name = url.split("/")[-1] if "/" in url else "raytolfas-release.iso"
            if not iso_name.endswith(".iso"):
                iso_name = "raytolfas-release.iso"
            target_iso = target_dir / iso_name

            def reporthook(blocknum, blocksize, totalsize):
                if totalsize > 0:
                    percent = min(100, int(blocknum * blocksize * 100 / totalsize))
                    mb_down = round(blocknum * blocksize / (1024 * 1024), 1)
                    mb_total = round(totalsize / (1024 * 1024), 1)
                    self._update_status = f"Downloading: {percent}% ({mb_down} / {mb_total} MB)"
                    self._update_progress = percent
                    self.stateChanged.emit()

            urllib.request.urlretrieve(url, str(target_iso), reporthook=reporthook)
            self._perform_iso_upgrade(str(target_iso))
        except Exception as e:
            self._update_status = f"Download error: {e}"
            self._update_checking = False
            self.stateChanged.emit()

    def _perform_iso_upgrade(self, iso_path):
        try:
            self._update_status = "Applying system upgrade..."
            self._update_progress = 100
            self.stateChanged.emit()
            proc = subprocess.run(
                ["pkexec", "raytolfas-upgrade-iso", iso_path],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True
            )
            if proc.returncode == 0:
                self._os_version = self._get_os_version()
                self._snapshot_status = self._get_snapshot_status()
                self._update_status = "Upgrade complete. Reboot required."
                self._update_available = False
            else:
                out = proc.stdout.strip() if proc.stdout else ""
                self._update_status = f"Upgrade failed: {out[-100:] if len(out) > 100 else out}"
        except Exception as e:
            self._update_status = f"Upgrade error: {e}"
        self._update_checking = False
        self.stateChanged.emit()

    @pyqtSlot()
    def download_patch(self):
        url = self._patch_url or "https://os.raytolfas.com"
        if url.endswith(".deb"):
            if self._patch_checking:
                return
            self._patch_checking = True
            self._patch_status = "Downloading patch..."
            self.stateChanged.emit()
            threading.Thread(target=self._perform_patch_install, args=(url,), daemon=True).start()
        else:
            subprocess.Popen(["xdg-open", url])

    def _perform_patch_install(self, url):
        try:
            target_deb = "/tmp/raytolfas_patch.deb"
            urllib.request.urlretrieve(url, target_deb)
            self._patch_status = "Installing patch..."
            self.stateChanged.emit()
            proc = subprocess.run(
                ["pkexec", "apt-get", "install", "-y", "--allow-downgrades", target_deb],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True
            )
            if proc.returncode == 0:
                self._os_version = self._get_os_version()
                self._snapshot_status = self._get_snapshot_status()
                self._patch_status = f"Patch {self._patch_version} installed. Reboot required."
                self._patch_available = False
            else:
                self._patch_status = f"Install error ({proc.returncode})"
        except Exception as e:
            self._patch_status = f"Error: {e}"
        self._patch_checking = False
        self.stateChanged.emit()

    @pyqtSlot(str)
    def set_power_profile(self, profile):
        self._power_profile = profile
        subprocess.Popen(["powerprofilesctl", "set", profile], stderr=subprocess.DEVNULL)
        self.stateChanged.emit()

    @pyqtSlot(str)
    def apply_theme(self, theme_name):
        self._current_theme = theme_name
        if theme_name == "dark":
            scheme = "FluentDark"
            look = "org.raytolfas.desktop"
            icons = "Papirus-Dark"
        else:
            scheme = "FluentLight"
            look = "org.raytolfas.light"
            icons = "Papirus-Light"

        subprocess.Popen(["plasma-apply-colorscheme", scheme], stderr=subprocess.DEVNULL)
        subprocess.Popen(["plasma-apply-lookandfeel", "-a", look], stderr=subprocess.DEVNULL)
        self._kwrite("kdeglobals", "Icons", "Theme", icons)
        for chg in ("/usr/lib/x86_64-linux-gnu/plasma-changeicons", "/usr/libexec/plasma-changeicons"):
            if os.path.exists(chg):
                subprocess.Popen([chg, icons], stderr=subprocess.DEVNULL)
                break
        self.stateChanged.emit()

    @pyqtSlot(str)
    def apply_accent_color(self, hex_color):
        self._accent_color = hex_color
        hex_clean = hex_color.lstrip("#")
        if len(hex_clean) == 6:
            r = int(hex_clean[0:2], 16)
            g = int(hex_clean[2:4], 16)
            b = int(hex_clean[4:6], 16)
            rgb_str = f"{r},{g},{b}"
            self._kwrite("kdeglobals", "General", "AccentColor", rgb_str)
            self._qdbus(["org.kde.KWin", "/KWin", "reconfigure"])
        self.stateChanged.emit()

    @pyqtSlot()
    def toggle_mangohud(self):
        self._mangohud_active = not self._mangohud_active
        env_dir = Path.home() / ".config" / "environment.d"
        env_dir.mkdir(parents=True, exist_ok=True)
        env_file = env_dir / "99-raytolfas-gaming.conf"
        val = "1" if self._mangohud_active else "0"
        env_file.write_text(f"MANGOHUD={val}\n")
        self.stateChanged.emit()

    @pyqtSlot()
    def toggle_gamemode(self):
        self._gamemode_active = not self._gamemode_active
        if self._gamemode_active:
            subprocess.Popen(["gamemoded", "-r"], stderr=subprocess.DEVNULL)
        self.stateChanged.emit()

    @pyqtSlot()
    def setup_android_libndk(self):
        subprocess.Popen(["pkexec", "raytolfas-waydroid-setup"], stderr=subprocess.DEVNULL)

    @pyqtSlot()
    def toggle_turbo(self):
        try:
            subprocess.run(["raytolfas-turbo", "toggle"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            self._turbo_active = self._check_turbo()
        except Exception:
            pass
        self.stateChanged.emit()

    @pyqtSlot(str)
    def install_dev(self, target):
        if self._dev_busy:
            return
        self._dev_busy = True
        self.stateChanged.emit()
        def _bg():
            try:
                subprocess.run(["raytolfas-dev", target], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                self._dev_status = self._get_dev_status()
            except Exception:
                pass
            self._dev_busy = False
            self.stateChanged.emit()
        threading.Thread(target=_bg, daemon=True).start()

    @pyqtSlot()
    def refresh_snapshots(self):
        self._snapshots_list = self._get_snapshots_list()
        self._snapshot_status = self._get_snapshot_status()
        self.stateChanged.emit()

    @pyqtSlot(str)
    def delete_snapshot_named(self, snap_name):
        if self._snapshot_busy:
            return
        self._snapshot_busy = True
        self.stateChanged.emit()
        def _bg():
            try:
                subprocess.run(["pkexec", "btrfs-auto-snapshot", "delete", snap_name], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                self._snapshots_list = self._get_snapshots_list()
                self._snapshot_status = self._get_snapshot_status()
            except Exception:
                pass
            self._snapshot_busy = False
            self.stateChanged.emit()
        threading.Thread(target=_bg, daemon=True).start()

    @pyqtSlot(str)
    def rollback_snapshot_named(self, snap_name):
        if self._snapshot_busy:
            return
        self._snapshot_busy = True
        self._snapshot_status = f"Restoring {snap_name}..."
        self.stateChanged.emit()
        def _bg():
            try:
                proc = subprocess.run(["pkexec", "btrfs-auto-snapshot", "rollback", snap_name], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
                out = proc.stdout.strip() if proc.stdout else ""
                self._snapshot_status = out or "Rollback set. Please reboot."
            except Exception as e:
                self._snapshot_status = f"Error: {e}"
            self._snapshot_busy = False
            self.stateChanged.emit()
        threading.Thread(target=_bg, daemon=True).start()

    @pyqtSlot()
    def launch_console_mode(self):
        subprocess.Popen(["/usr/bin/raytolfas-console-mode"], start_new_session=True)

    @pyqtSlot()
    def open_desktop_touchpad(self):
        subprocess.Popen(["/usr/bin/raytolfas-desktop-mode", "touchpad"], start_new_session=True)

    @pyqtSlot()
    def launch_m1_shell(self):
        subprocess.Popen(["/usr/bin/raytolfas-mobile-test"], start_new_session=True)

    @pyqtSlot()
    def launch_spotlight(self):
        subprocess.Popen(["/usr/bin/raytolfas-spotlight"], start_new_session=True)

    @pyqtSlot()
    def run_benchmark(self):
        subprocess.Popen(["konsole", "-e", "/usr/bin/raytolfas-bench"], start_new_session=True)

    @pyqtSlot()
    def run_system_clean(self):
        if self._clean_busy:
            return
        self._clean_busy = True
        self._clean_status = "Cleaning caches and optimizing RAM..."
        self.stateChanged.emit()
        def _bg():
            try:
                proc = subprocess.run(["pkexec", "/usr/bin/raytolfas-clean"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
                out = proc.stdout.strip() if proc.stdout else ""
                self._clean_status = out.splitlines()[-1] if out else "System memory and caches optimized"
            except Exception as e:
                self._clean_status = f"Optimization error: {e}"
            self._clean_busy = False
            self.stateChanged.emit()
        threading.Thread(target=_bg, daemon=True).start()

    @pyqtSlot(str)
    def set_panel_style(self, style):
        self._panel_style = style
        floating = "true" if style == "floating" else "false"
        height = 34 if style == "compact" else (42 if style == "floating" else 40)
        js = f"var p = panels(); for (var i = 0; i < p.length; i++) {{ p[i].floating = {floating}; p[i].height = {height}; }}"
        self._qdbus(["org.kde.plasmashell", "/PlasmaShell", "org.kde.PlasmaShell.evaluateScript", js])
        self.stateChanged.emit()

    @pyqtSlot(str)
    def set_window_buttons(self, side):
        self._window_buttons = side
        if side == "left":
            left_val, right_val = "XIA", ""
        else:
            left_val, right_val = "", "IAX"
        self._kwrite("kwinrc", "org.kde.kdecoration2", "ButtonsOnLeft", left_val)
        self._kwrite("kwinrc", "org.kde.kdecoration2", "ButtonsOnRight", right_val)
        self._qdbus(["org.kde.KWin", "/KWin", "reconfigure"])
        self.stateChanged.emit()

    @pyqtSlot(str)
    def set_cursor_theme(self, theme):
        self._cursor_theme = theme
        self._kwrite("kcminputrc", "Mouse", "cursorTheme", theme)
        if shutil.which("plasma-apply-cursortheme"):
            subprocess.Popen(["plasma-apply-cursortheme", theme], stderr=subprocess.DEVNULL)
        self.stateChanged.emit()

    @pyqtSlot(str)
    def set_blur_level(self, level):
        self._blur_level = level
        strength_map = {"subtle": "4", "balanced": "9", "deep": "13", "ultra": "15"}
        val = strength_map.get(level, "9")
        self._kwrite("kwinrc", "Effect-blur", "BlurStrength", val)
        self._qdbus(["org.kde.KWin", "/KWin", "reconfigure"])
        self.stateChanged.emit()

    @pyqtSlot(str)
    def set_minimize_effect(self, effect):
        self._minimize_effect = effect
        ml_val = "true" if effect == "magiclamp" else "false"
        sc_val = "true" if effect == "scale" else "false"
        self._kwrite("kwinrc", "Plugins", "magiclampEnabled", ml_val)
        self._kwrite("kwinrc", "Plugins", "scaleEnabled", sc_val)
        self._qdbus(["org.kde.KWin", "/KWin", "reconfigure"])
        self.stateChanged.emit()

    @pyqtSlot(str)
    def set_anim_speed(self, speed):
        self._anim_speed = speed
        factor_map = {"instant": "0", "fast": "0.5", "fluid": "0.85", "relaxed": "1.25"}
        val = factor_map.get(speed, "0.85")
        self._kwrite("kdeglobals", "KDE", "AnimationDurationFactor", val)
        self._qdbus(["org.kde.KWin", "/KWin", "reconfigure"])
        self.stateChanged.emit()

def main():
    app = QGuiApplication(sys.argv)
    app.setApplicationName("Control Center")

    papirus_icon = "/usr/share/icons/Papirus-Dark/48x48/apps/tweaks-app.svg"
    fluent_icon = "/usr/share/icons/.Fluent-base/scalable/apps/tweaks-app.svg"
    icon_path = "/usr/share/icons/hicolor/512x512/apps/raytolfas-logo.png"
    if os.path.exists(papirus_icon):
        app.setWindowIcon(QIcon(papirus_icon))
    elif os.path.exists(fluent_icon):
        app.setWindowIcon(QIcon(fluent_icon))
    elif os.path.exists(icon_path):
        app.setWindowIcon(QIcon(icon_path))

    backend = ControlCenterBackend()
    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("backend", backend)

    qml_file = Path(__file__).parent / "ControlCenter.qml"
    engine.load(QUrl.fromLocalFile(str(qml_file)))

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())

if __name__ == "__main__":
    main()
