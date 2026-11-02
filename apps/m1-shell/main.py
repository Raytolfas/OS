#!/usr/bin/env python3
import os
import sys
import glob
import json
import subprocess
import configparser
from datetime import datetime
from PyQt6.QtCore import QObject, pyqtSignal, pyqtProperty, pyqtSlot, QUrl, QTimer
from PyQt6.QtGui import QGuiApplication
from PyQt6.QtQml import QQmlApplicationEngine


class M1Backend(QObject):
    stateChanged = pyqtSignal()
    appsChanged = pyqtSignal()
    tasksChanged = pyqtSignal()

    def __init__(self):
        super().__init__()
        self._time_str = "12:00"
        self._date_str = "Monday, Oct 27"
        self._battery_pct = 100
        self._wifi_enabled = True
        self._bt_enabled = True
        self._turbo_enabled = False
        self._desktop_mode = False
        self._dnd_enabled = False
        self._rotate_enabled = True
        self._volume = 75
        self._brightness = 85
        self._cpu_usage = "8%"
        self._ram_usage = "1.4 GB"
        self._apps = []
        self._filtered_apps = []
        self._recent_tasks = []
        self._search_query = ""

        self._load_applications()
        self._refresh_system_state()

        self._timer = QTimer(self)
        self._timer.timeout.connect(self._refresh_system_state)
        self._timer.start(3000)

    def _run_cmd(self, cmd):
        try:
            r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=3)
            return r.stdout.strip()
        except Exception:
            return ""

    def _resolve_icon(self, icon_name):
        if not icon_name:
            return ""
        if os.path.isabs(icon_name) and os.path.exists(icon_name):
            return "file://" + icon_name
        search_paths = [
            f"/usr/share/icons/.Fluent-base/scalable/apps/{icon_name}.svg",
            f"/usr/share/icons/.Fluent-base/scalable/devices/{icon_name}.svg",
            f"/usr/share/icons/.Fluent-base/scalable/places/{icon_name}.svg",
            f"/usr/share/icons/Fluent-dark/32/actions/{icon_name}.svg",
            f"/usr/share/icons/Papirus-Dark/48x48/apps/{icon_name}.svg",
            f"/usr/share/icons/Papirus-Dark/48x48/devices/{icon_name}.svg",
            f"/usr/share/icons/Papirus-Dark/32x32/actions/{icon_name}.svg",
            f"/usr/share/icons/breeze-dark/apps/48/{icon_name}.svg",
            f"/usr/share/icons/breeze-dark/devices/64/{icon_name}.svg",
            f"/usr/share/icons/breeze-dark/actions/32/{icon_name}.svg",
            f"/usr/share/icons/breeze/apps/48/{icon_name}.svg",
            f"/usr/share/icons/hicolor/scalable/apps/{icon_name}.svg",
            f"/usr/share/icons/hicolor/512x512/apps/{icon_name}.png",
            f"/usr/share/icons/hicolor/256x256/apps/{icon_name}.png",
            f"/usr/share/icons/hicolor/128x128/apps/{icon_name}.png",
            f"/usr/share/icons/hicolor/48x48/apps/{icon_name}.png",
            f"/usr/share/pixmaps/{icon_name}.svg",
            f"/usr/share/pixmaps/{icon_name}.png",
        ]
        for p in search_paths:
            if os.path.exists(p):
                return "file://" + p
        return ""

    def _load_applications(self):
        apps = []
        seen = set()
        dirs = ["/usr/share/applications", os.path.expanduser("~/.local/share/applications")]
        for d in dirs:
            if not os.path.isdir(d):
                continue
            for path in sorted(glob.glob(os.path.join(d, "*.desktop"))):
                try:
                    cp = configparser.ConfigParser(interpolation=None)
                    cp.read(path, encoding="utf-8")
                    if "Desktop Entry" not in cp:
                        continue
                    entry = cp["Desktop Entry"]
                    if entry.get("NoDisplay", "false").lower() == "true":
                        continue
                    if entry.get("Hidden", "false").lower() == "true":
                        continue
                    name = entry.get("Name", "").strip()
                    exec_cmd = entry.get("Exec", "").strip()
                    icon = entry.get("Icon", "").strip()
                    categories = entry.get("Categories", "")
                    if not name or not exec_cmd or name in seen:
                        continue
                    clean_exec = exec_cmd.split("%")[0].strip()
                    seen.add(name)
                    is_android = "Waydroid" in categories or "waydroid" in clean_exec.lower()
                    apps.append({
                        "name": name,
                        "exec": clean_exec,
                        "icon": self._resolve_icon(icon),
                        "letter": name[0].upper(),
                        "isAndroid": is_android,
                        "category": "Android" if is_android else "System"
                    })
                except Exception:
                    continue
        apps.sort(key=lambda x: x["name"].lower())
        self._apps = apps
        self._filtered_apps = list(apps)
        self.appsChanged.emit()

    def _refresh_system_state(self):
        now = datetime.now()
        self._time_str = now.strftime("%H:%M")
        self._date_str = now.strftime("%A, %b %d")

        for bat_cap in glob.glob("/sys/class/power_supply/BAT*/capacity"):
            try:
                with open(bat_cap, "r") as f:
                    self._battery_pct = int(f.read().strip())
                break
            except Exception:
                pass

        self._turbo_enabled = os.path.exists("/tmp/raytolfas-turbo.active")
        self._desktop_mode = os.path.exists("/tmp/raytolfas-desktop-mode.active")

        try:
            with open("/proc/meminfo", "r") as f:
                lines = f.readlines()
            mem_total = 0
            mem_avail = 0
            for ln in lines:
                if ln.startswith("MemTotal:"):
                    mem_total = int(ln.split()[1])
                elif ln.startswith("MemAvailable:"):
                    mem_avail = int(ln.split()[1])
            if mem_total > 0:
                used_gb = (mem_total - mem_avail) / (1024 * 1024)
                self._ram_usage = f"{used_gb:.1f} GB"
        except Exception:
            pass

        try:
            with open("/proc/loadavg", "r") as f:
                load1 = float(f.read().split()[0])
            cores = os.cpu_count() or 4
            pct = min(100, max(1, int((load1 / cores) * 100)))
            self._cpu_usage = f"{pct}%"
        except Exception:
            pass

        self.stateChanged.emit()

    @pyqtProperty(str, notify=stateChanged)
    def timeStr(self):
        return self._time_str

    @pyqtProperty(str, notify=stateChanged)
    def dateStr(self):
        return self._date_str

    @pyqtProperty(int, notify=stateChanged)
    def batteryPct(self):
        return self._battery_pct

    @pyqtProperty(bool, notify=stateChanged)
    def wifiEnabled(self):
        return self._wifi_enabled

    @pyqtProperty(bool, notify=stateChanged)
    def btEnabled(self):
        return self._bt_enabled

    @pyqtProperty(bool, notify=stateChanged)
    def turboEnabled(self):
        return self._turbo_enabled

    @pyqtProperty(bool, notify=stateChanged)
    def desktopMode(self):
        return self._desktop_mode

    @pyqtProperty(bool, notify=stateChanged)
    def dndEnabled(self):
        return self._dnd_enabled

    @pyqtProperty(bool, notify=stateChanged)
    def rotateEnabled(self):
        return self._rotate_enabled

    @pyqtProperty(int, notify=stateChanged)
    def volumeLevel(self):
        return self._volume

    @pyqtProperty(int, notify=stateChanged)
    def brightnessLevel(self):
        return self._brightness

    @pyqtProperty(str, notify=stateChanged)
    def cpuUsage(self):
        return self._cpu_usage

    @pyqtProperty(str, notify=stateChanged)
    def ramUsage(self):
        return self._ram_usage

    @pyqtProperty("QVariantList", notify=appsChanged)
    def appList(self):
        return self._filtered_apps

    @pyqtProperty("QVariantList", notify=tasksChanged)
    def recentTasks(self):
        return self._recent_tasks

    @pyqtSlot(str)
    def filterApps(self, query):
        q = query.strip().lower()
        self._search_query = q
        if not q:
            self._filtered_apps = list(self._apps)
        else:
            self._filtered_apps = [a for a in self._apps if q in a["name"].lower() or q in a["category"].lower()]
        self.appsChanged.emit()

    @pyqtSlot(str, str)
    def launchApp(self, name, exec_cmd):
        if not exec_cmd:
            return
        try:
            subprocess.Popen(exec_cmd, shell=True, start_new_session=True)
            self._recent_tasks = [t for t in self._recent_tasks if t["name"] != name]
            self._recent_tasks.insert(0, {
                "name": name,
                "exec": exec_cmd,
                "time": datetime.now().strftime("%H:%M")
            })
            self.tasksChanged.emit()
        except Exception:
            pass

    @pyqtSlot(str)
    def launchQuick(self, target):
        mapping = {
            "terminal": ("Konsole", "konsole"),
            "files": ("Dolphin", "dolphin"),
            "browser": ("Browser", "firefox"),
            "settings": ("Control Center", "python3 /usr/share/raytolfas/control-center/main.py"),
            "waydroid": ("Android Runtime", "waydroid show-full-ui")
        }
        if target in mapping:
            title, cmd = mapping[target]
            self.launchApp(title, cmd)

    @pyqtSlot(str)
    def closeTask(self, name):
        self._recent_tasks = [t for t in self._recent_tasks if t["name"] != name]
        self.tasksChanged.emit()

    @pyqtSlot()
    def clearTasks(self):
        self._recent_tasks = []
        self.tasksChanged.emit()

    @pyqtSlot()
    def toggleWifi(self):
        self._wifi_enabled = not self._wifi_enabled
        state = "on" if self._wifi_enabled else "off"
        subprocess.Popen(f"nmcli radio wifi {state}", shell=True)
        self.stateChanged.emit()

    @pyqtSlot()
    def toggleBt(self):
        self._bt_enabled = not self._bt_enabled
        state = "unblock" if self._bt_enabled else "block"
        subprocess.Popen(f"rfkill {state} bluetooth", shell=True)
        self.stateChanged.emit()

    @pyqtSlot()
    def toggleTurbo(self):
        subprocess.Popen("/usr/bin/raytolfas-turbo toggle", shell=True)
        self._turbo_enabled = not self._turbo_enabled
        self.stateChanged.emit()

    @pyqtSlot()
    def toggleDesktopMode(self):
        subprocess.Popen("/usr/bin/raytolfas-desktop-mode toggle", shell=True)
        self._desktop_mode = not self._desktop_mode
        self.stateChanged.emit()

    @pyqtSlot()
    def toggleDnd(self):
        self._dnd_enabled = not self._dnd_enabled
        self.stateChanged.emit()

    @pyqtSlot()
    def toggleRotate(self):
        self._rotate_enabled = not self._rotate_enabled
        self.stateChanged.emit()

    @pyqtSlot()
    def launchConsoleMode(self):
        subprocess.Popen("/usr/bin/raytolfas-console-mode", shell=True, start_new_session=True)

    @pyqtSlot(int)
    def setVolume(self, val):
        self._volume = max(0, min(100, val))
        subprocess.Popen(f"pactl set-sink-volume @DEFAULT_SINK@ {self._volume}%", shell=True)
        self.stateChanged.emit()

    @pyqtSlot(int)
    def setBrightness(self, val):
        self._brightness = max(10, min(100, val))
        self.stateChanged.emit()


def main():
    app = QGuiApplication(sys.argv)
    app.setApplicationName("Raytolfas OS M1")
    engine = QQmlApplicationEngine()
    backend = M1Backend()
    engine.rootContext().setContextProperty("m1", backend)
    qml_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "M1Shell.qml")
    engine.load(QUrl.fromLocalFile(qml_path))
    if not engine.rootObjects():
        sys.exit(1)
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
