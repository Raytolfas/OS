#!/usr/bin/env python3
import sys, os, platform, subprocess, threading, json, urllib.request, urllib.error
from pathlib import Path
from PyQt6.QtCore import QObject, pyqtSignal, pyqtSlot, pyqtProperty, QUrl
from PyQt6.QtGui import QGuiApplication, QIcon
from PyQt6.QtQml import QQmlApplicationEngine

CURRENT_VERSION = "v26.10.0"
CURRENT_PATCH_VERSION = "v26.10.2"
UPDATE_ENDPOINT = "https://os.raytolfas.cc/update"

class ControlCenterBackend(QObject):
    stateChanged = pyqtSignal()

    def __init__(self):
        super().__init__()
        self._os_version = f"Raytolfas OS D1 ({CURRENT_VERSION})"
        self._kernel_version = platform.release()
        self._cpu_info = self._get_cpu()
        self._ram_info = self._get_ram()

        self._update_status = "Click 'Check for Updates' to scan for new releases"
        self._update_changelog = ""
        self._update_available = False
        self._update_checking = False
        self._download_url = ""
        self._update_progress = 0

        self._patch_status = "Select this tab to check for available system hotfixes"
        self._patch_changelog = ""
        self._patch_available = False
        self._patch_checking = False
        self._patch_url = ""
        self._patch_version = CURRENT_PATCH_VERSION
        self._patch_agreed = False

        self._waydroid_status = self._get_waydroid_status()
        self._current_theme = "dark"
        self._accent_color = "#0078D4"
        self._gamemode_active = self._check_gamemode()
        self._mangohud_active = self._check_mangohud()
        self._power_profile = self._get_power_profile()

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
        except Exception:
            pass
        return platform.processor() or "x86_64 Processor"

    def _get_ram(self):
        try:
            with open("/proc/meminfo") as f:
                for line in f:
                    if "MemTotal" in line:
                        kb = int(line.split()[1])
                        return f"{round(kb / 1024 / 1024, 1)} GB"
        except Exception:
            pass
        return "8.0 GB"

    def _get_waydroid_status(self):
        try:
            out = subprocess.check_output(["waydroid", "status"], stderr=subprocess.DEVNULL, text=True)
            if "RUNNING" in out:
                return "Active (Container running)"
            return "Stopped (On-demand)"
        except Exception:
            return "Ready to use"

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
            except Exception:
                pass
        return False

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

    @pyqtProperty(bool, notify=stateChanged)
    def patch_agreed(self): return self._patch_agreed

    @pyqtProperty(str, notify=stateChanged)
    def waydroid_status(self): return self._waydroid_status

    @pyqtProperty(str, notify=stateChanged)
    def current_theme(self): return self._current_theme

    @pyqtProperty(str, notify=stateChanged)
    def accent_color(self): return self._accent_color

    @pyqtProperty(bool, notify=stateChanged)
    def gamemode_active(self): return self._gamemode_active

    @pyqtProperty(bool, notify=stateChanged)
    def mangohud_active(self): return self._mangohud_active

    @pyqtProperty(str, notify=stateChanged)
    def current_power_profile(self): return self._power_profile

    @pyqtSlot(bool)
    def set_patch_agreed(self, agreed):
        self._patch_agreed = agreed
        self.stateChanged.emit()

    @pyqtSlot()
    def check_for_updates(self):
        if self._update_checking:
            return
        self._update_checking = True
        self._update_status = "Connecting to update server..."
        self.stateChanged.emit()
        threading.Thread(target=self._fetch_manifest, daemon=True).start()

    @pyqtSlot()
    def check_for_patches(self):
        if self._patch_checking:
            return
        self._patch_checking = True
        self._patch_status = "Scanning for available patches..."
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

                if remote_ver and remote_ver != CURRENT_VERSION:
                    self._update_available = True
                    self._download_url = dl_url
                    self._update_status = f"New global release available: {remote_ver}!"
                    self._update_changelog = f"Release notes:\n{changelog}" if changelog else ""
                else:
                    self._update_available = False
                    self._update_status = "Raytolfas OS is up to date."

                patch_ver = data.get("patch_version", "")
                p_url = data.get("patch_url", "")
                p_changelog = data.get("patch_changelog", "")

                if patch_ver and patch_ver != CURRENT_PATCH_VERSION:
                    self._patch_available = True
                    self._patch_url = p_url
                    self._patch_status = f"New patch available: {patch_ver}!"
                    self._patch_changelog = f"Patch contents:\n{p_changelog}" if p_changelog else ""
                else:
                    self._patch_available = False
                    self._patch_status = "All system patches are up to date."

        except urllib.error.URLError:
            self._update_available = False
            self._update_status = "Update server (os.raytolfas.cc/update) is unreachable or network is offline."
            self._patch_available = False
            self._patch_status = "Failed to connect to patch server (os.raytolfas.cc/update)."
        except Exception as e:
            self._update_available = False
            self._update_status = f"Error: {e}"
            self._patch_available = False
            self._patch_status = f"Error: {e}"

        self._update_checking = False
        self._patch_checking = False
        self.stateChanged.emit()

    @pyqtSlot()
    def download_update(self):
        url = self._download_url or "https://os.raytolfas.cc"
        subprocess.Popen(["xdg-open", url])

    @pyqtSlot()
    def choose_and_apply_iso(self):
        if self._update_checking:
            return
        iso_file = self._pick_iso_file()
        if iso_file and os.path.isfile(iso_file):
            self._update_checking = True
            self._update_progress = 0
            self._update_status = f"Upgrading system from {os.path.basename(iso_file)}..."
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
        except Exception:
            pass
        try:
            from PyQt6.QtWidgets import QFileDialog
            fn, _ = QFileDialog.getOpenFileName(None, "Select Raytolfas OS ISO Image", str(Path.home()), "ISO Images (*.iso)")
            if fn:
                return fn
        except Exception:
            pass
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
        self._update_status = "Connecting to download release ISO..."
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
                    self._update_status = f"Downloading release ISO: {percent}% ({mb_down} / {mb_total} MB)..."
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
            self._update_status = "Applying system upgrade from ISO... Please do not power off."
            self._update_progress = 100
            self.stateChanged.emit()
            proc = subprocess.run(
                ["pkexec", "raytolfas-upgrade-iso", iso_path],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True
            )
            if proc.returncode == 0:
                self._update_status = "System upgraded successfully from ISO! Please reboot your PC."
                self._update_available = False
            else:
                out = proc.stdout.strip() if proc.stdout else ""
                self._update_status = f"Upgrade failed: {out[-120:] if len(out) > 120 else out}"
        except Exception as e:
            self._update_status = f"Error during upgrade: {e}"
        self._update_checking = False
        self.stateChanged.emit()

    @pyqtSlot()
    def download_patch(self):
        url = self._patch_url or "https://os.raytolfas.cc"
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
            self._patch_status = "Installing patch into system..."
            self.stateChanged.emit()
            proc = subprocess.run(
                ["pkexec", "apt-get", "install", "-y", "--allow-downgrades", target_deb],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True
            )
            if proc.returncode == 0:
                self._patch_status = f"Patch {self._patch_version} installed successfully! Please reboot."
                self._patch_available = False
            else:
                self._patch_status = f"Installation error (code {proc.returncode})"
        except Exception as e:
            self._patch_status = f"Error installing patch: {e}"
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
        else:
            scheme = "FluentLight"
            look = "org.raytolfas.light"

        subprocess.Popen(["plasma-apply-colorscheme", scheme], stderr=subprocess.DEVNULL)
        subprocess.Popen(["plasma-apply-lookandfeel", "-a", look], stderr=subprocess.DEVNULL)
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
            for cmd in [
                ["kwriteconfig6", "--file", "kdeglobals", "--group", "General", "--key", "AccentColor", rgb_str],
                ["kwriteconfig5", "--file", "kdeglobals", "--group", "General", "--key", "AccentColor", rgb_str]
            ]:
                subprocess.Popen(cmd, stderr=subprocess.DEVNULL)
            subprocess.Popen(["qdbus", "org.kde.KWin", "/KWin", "reconfigure"], stderr=subprocess.DEVNULL)
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
    def launch_spectacle(self):
        subprocess.Popen(["spectacle", "-r"], stderr=subprocess.DEVNULL)

    @pyqtSlot()
    def launch_spectacle_record(self):
        if Path("/usr/bin/vokoscreenNG").exists():
            subprocess.Popen(["vokoscreenNG"], stderr=subprocess.DEVNULL)
        else:
            subprocess.Popen(["spectacle"], stderr=subprocess.DEVNULL)

    @pyqtSlot()
    def setup_android_libndk(self):
        subprocess.Popen(["pkexec", "raytolfas-waydroid-setup"], stderr=subprocess.DEVNULL)

def main():
    app = QGuiApplication(sys.argv)
    app.setApplicationName("Raytolfas Control Center")

    icon_path = "/usr/share/icons/hicolor/512x512/apps/raytolfas-logo.png"
    if os.path.exists(icon_path):
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
