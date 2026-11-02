#!/usr/bin/env python3
import os
import sys
import glob
import time
import threading
import subprocess
import configparser
from datetime import datetime
from PyQt6.QtCore import QObject, pyqtSignal, pyqtProperty, pyqtSlot, QUrl, QTimer
from PyQt6.QtGui import QGuiApplication
from PyQt6.QtQml import QQmlApplicationEngine


class ConsoleBackend(QObject):
    stateChanged = pyqtSignal()
    itemsChanged = pyqtSignal()
    gamepadAction = pyqtSignal(str)

    def __init__(self):
        super().__init__()
        self._time_str = "12:00"
        self._battery_pct = 100
        self._turbo_active = os.path.exists("/tmp/raytolfas-turbo.active")
        self._mangohud_enabled = os.environ.get("MANGOHUD", "1") == "1"
        self._cas_enabled = os.environ.get("ENABLE_VKBASALT", "1") == "1"
        self._volume = 80
        self._controller_name = "Keyboard / Gamepad Ready"
        self._items = []
        self._category = "All"

        self._load_items()
        self._refresh_status()

        self._timer = QTimer(self)
        self._timer.timeout.connect(self._refresh_status)
        self._timer.start(3000)

        self._gp_thread = threading.Thread(target=self._poll_gamepad, daemon=True)
        self._gp_thread.start()

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
            f"/usr/share/pixmaps/{icon_name}.svg",
            f"/usr/share/pixmaps/{icon_name}.png",
        ]
        for p in search_paths:
            if os.path.exists(p):
                return "file://" + p
        return ""

    def _load_items(self):
        games = []
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
                    name = entry.get("Name", "").strip()
                    exec_cmd = entry.get("Exec", "").strip()
                    icon = entry.get("Icon", "").strip()
                    cats = entry.get("Categories", "")
                    if not name or not exec_cmd or name in seen:
                        continue
                    if "Console Mode" in name:
                        continue
                    clean_exec = exec_cmd.split("%")[0].strip()
                    seen.add(name)
                    is_game = any(k in cats for k in ("Game", "Emulator")) or any(k in name.lower() for k in ("steam", "proton", "lutris", "heroic", "minecraft", "waydroid"))
                    item = {
                        "name": name,
                        "exec": clean_exec,
                        "icon": self._resolve_icon(icon),
                        "letter": name[0].upper(),
                        "tag": "GAME" if is_game else "APP",
                        "isGame": is_game
                    }
                    if is_game:
                        games.append(item)
                    else:
                        apps.append(item)
                except Exception:
                    continue
        self._all_items = games + apps
        self._items = list(self._all_items)
        self.itemsChanged.emit()

    def _refresh_status(self):
        self._time_str = datetime.now().strftime("%H:%M")
        self._turbo_active = os.path.exists("/tmp/raytolfas-turbo.active")
        for bat_cap in glob.glob("/sys/class/power_supply/BAT*/capacity"):
            try:
                with open(bat_cap, "r") as f:
                    self._battery_pct = int(f.read().strip())
                break
            except Exception:
                pass
        self.stateChanged.emit()

    def _poll_gamepad(self):
        try:
            import evdev
            from evdev import ecodes
        except Exception:
            return
        while True:
            try:
                devices = [evdev.InputDevice(p) for p in evdev.list_devices()]
                gamepads = []
                for dev in devices:
                    caps = dev.capabilities()
                    if ecodes.EV_KEY in caps and (ecodes.BTN_SOUTH in caps[ecodes.EV_KEY] or ecodes.BTN_GAMEPAD in caps[ecodes.EV_KEY]):
                        gamepads.append(dev)
                if not gamepads:
                    time.sleep(2.0)
                    continue
                gp = gamepads[0]
                self._controller_name = gp.name
                self.stateChanged.emit()
                for event in gp.read_loop():
                    if event.type == ecodes.EV_KEY and event.value == 1:
                        if event.code in (ecodes.BTN_SOUTH, ecodes.BTN_A):
                            self.gamepadAction.emit("accept")
                        elif event.code in (ecodes.BTN_EAST, ecodes.BTN_B):
                            self.gamepadAction.emit("back")
                        elif event.code in (ecodes.BTN_MODE, ecodes.BTN_START, ecodes.BTN_SELECT):
                            self.gamepadAction.emit("overlay")
                        elif event.code == ecodes.BTN_DPAD_LEFT:
                            self.gamepadAction.emit("left")
                        elif event.code == ecodes.BTN_DPAD_RIGHT:
                            self.gamepadAction.emit("right")
                        elif event.code == ecodes.BTN_DPAD_UP:
                            self.gamepadAction.emit("up")
                        elif event.code == ecodes.BTN_DPAD_DOWN:
                            self.gamepadAction.emit("down")
                    elif event.type == ecodes.EV_ABS:
                        if event.code == ecodes.ABS_HAT0X:
                            if event.value < 0:
                                self.gamepadAction.emit("left")
                            elif event.value > 0:
                                self.gamepadAction.emit("right")
                        elif event.code == ecodes.ABS_HAT0Y:
                            if event.value < 0:
                                self.gamepadAction.emit("up")
                            elif event.value > 0:
                                self.gamepadAction.emit("down")
            except Exception:
                time.sleep(2.0)

    @pyqtProperty(str, notify=stateChanged)
    def timeStr(self):
        return self._time_str

    @pyqtProperty(int, notify=stateChanged)
    def batteryPct(self):
        return self._battery_pct

    @pyqtProperty(bool, notify=stateChanged)
    def turboActive(self):
        return self._turbo_active

    @pyqtProperty(bool, notify=stateChanged)
    def mangohudEnabled(self):
        return self._mangohud_enabled

    @pyqtProperty(bool, notify=stateChanged)
    def casEnabled(self):
        return self._cas_enabled

    @pyqtProperty(int, notify=stateChanged)
    def volumeLevel(self):
        return self._volume

    @pyqtProperty(str, notify=stateChanged)
    def controllerName(self):
        return self._controller_name

    @pyqtProperty(str, notify=itemsChanged)
    def currentCategory(self):
        return self._category

    @pyqtProperty("QVariantList", notify=itemsChanged)
    def libraryItems(self):
        return self._items

    @pyqtSlot(str)
    def setCategory(self, cat):
        self._category = cat
        if cat == "Games":
            self._items = [i for i in self._all_items if i["isGame"]]
            if not self._items:
                self._items = list(self._all_items)
        elif cat == "Apps":
            self._items = [i for i in self._all_items if not i["isGame"]]
        else:
            self._items = list(self._all_items)
        self.itemsChanged.emit()

    @pyqtSlot(str)
    def launchTarget(self, exec_cmd):
        if not exec_cmd:
            return
        env = os.environ.copy()
        env["MANGOHUD"] = "1" if self._mangohud_enabled else "0"
        env["ENABLE_VKBASALT"] = "1" if self._cas_enabled else "0"
        subprocess.Popen(exec_cmd, shell=True, env=env, start_new_session=True)

    @pyqtSlot()
    def toggleTurbo(self):
        subprocess.Popen("/usr/bin/raytolfas-turbo toggle", shell=True)
        self._turbo_active = not self._turbo_active
        self.stateChanged.emit()

    @pyqtSlot()
    def toggleMangohud(self):
        self._mangohud_enabled = not self._mangohud_enabled
        self.stateChanged.emit()

    @pyqtSlot()
    def toggleCas(self):
        self._cas_enabled = not self._cas_enabled
        self.stateChanged.emit()

    @pyqtSlot(int)
    def adjustVolume(self, delta):
        self._volume = max(0, min(100, self._volume + delta))
        subprocess.Popen(f"pactl set-sink-volume @DEFAULT_SINK@ {self._volume}%", shell=True)
        self.stateChanged.emit()

    @pyqtSlot()
    def exitToDesktop(self):
        QGuiApplication.quit()


def main():
    app = QGuiApplication(sys.argv)
    app.setApplicationName("Console Mode")
    engine = QQmlApplicationEngine()
    backend = ConsoleBackend()
    engine.rootContext().setContextProperty("consoleBackend", backend)
    qml_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ConsoleMode.qml")
    engine.load(QUrl.fromLocalFile(qml_path))
    if not engine.rootObjects():
        sys.exit(1)
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
