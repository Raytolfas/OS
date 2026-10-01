#!/usr/bin/env python3
import sys, os, platform, subprocess, threading, json, urllib.request, urllib.error
from pathlib import Path
from PyQt6.QtCore import QObject, pyqtSignal, pyqtSlot, pyqtProperty, QUrl
from PyQt6.QtGui import QGuiApplication, QIcon
from PyQt6.QtQml import QQmlApplicationEngine

CURRENT_VERSION = "v26.10.0"
CURRENT_PATCH_VERSION = "v26.10.0"
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

        self._patch_status = "Select this tab to check for available system hotfixes"
        self._patch_changelog = ""
        self._patch_available = False
        self._patch_checking = False
        self._patch_url = ""
        self._patch_version = CURRENT_PATCH_VERSION
        self._patch_agreed = False

        self._waydroid_status = self._get_waydroid_status()

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

    @pyqtProperty(str, notify=stateChanged)
    def patch_status(self): return self._patch_status

    @pyqtProperty(str, notify=stateChanged)
    def patch_changelog(self): return self._patch_changelog

    @pyqtProperty(bool, notify=stateChanged)
    def patch_available(self): return self._patch_available

    @pyqtProperty(bool, notify=stateChanged)
    def patch_checking(self): return self._patch_checking

    @pyqtProperty(bool, notify=stateChanged)
    def patch_agreed(self): return self._patch_agreed

    @pyqtProperty(str, notify=stateChanged)
    def waydroid_status(self): return self._waydroid_status

    @pyqtSlot(bool)
    def set_patch_agreed(self, agreed):
        self._patch_agreed = agreed
        self.stateChanged.emit()
        if agreed:
            self.check_for_patches()

    @pyqtSlot()
    def check_for_updates(self):
        self._update_checking = True
        self._update_status = "Connecting to os.raytolfas.cc/update..."
        self._update_changelog = ""
        self._update_available = False
        self.stateChanged.emit()

        threading.Thread(target=self._fetch_updates, daemon=True).start()

    @pyqtSlot()
    def check_for_patches(self):
        if not self._patch_agreed:
            return
        self._patch_checking = True
        self._patch_status = "Searching for patches on os.raytolfas.cc/update..."
        self._patch_changelog = ""
        self._patch_available = False
        self.stateChanged.emit()

        threading.Thread(target=self._fetch_updates, daemon=True).start()

    def _fetch_updates(self):
        try:
            req = urllib.request.Request(
                UPDATE_ENDPOINT,
                headers={"User-Agent": f"RaytolfasOS/{CURRENT_VERSION}"}
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
        url = self._download_url or "https://raytolfas.com"
        subprocess.Popen(["xdg-open", url])

    @pyqtSlot()
    def download_patch(self):
        url = self._patch_url or "https://raytolfas.com"
        subprocess.Popen(["xdg-open", url])

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
