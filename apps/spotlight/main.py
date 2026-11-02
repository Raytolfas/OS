#!/usr/bin/env python3
import os
import sys
import math
import glob
import subprocess
import configparser
from PyQt6.QtCore import QObject, pyqtSignal, pyqtProperty, pyqtSlot, QUrl
from PyQt6.QtGui import QGuiApplication
from PyQt6.QtQml import QQmlApplicationEngine


class SpotlightBackend(QObject):
    resultsChanged = pyqtSignal()

    def __init__(self):
        super().__init__()
        self._apps = []
        self._results = []
        self._system_actions = [
            {"name": "Turbo Mode", "sub": "Performance", "cmd": "/usr/bin/raytolfas-turbo toggle", "keywords": "turbo performance boost game"},
            {"name": "Clean System & RAM", "sub": "Maintenance", "cmd": "pkexec /usr/bin/raytolfas-clean", "keywords": "clean ram cache optimize memory"},
            {"name": "Control Center", "sub": "Settings", "cmd": "/usr/bin/raytolfas-control-center", "keywords": "control center settings theme update"},
            {"name": "Console Mode", "sub": "Session", "cmd": "/usr/bin/raytolfas-console-mode", "keywords": "console mode gamepad"},
            {"name": "Desktop Mode Trackpad", "sub": "Display", "cmd": "/usr/bin/raytolfas-desktop-mode touchpad", "keywords": "desktop mode dock trackpad"},
            {"name": "Create Btrfs Snapshot", "sub": "Recovery", "cmd": "pkexec /usr/bin/btrfs-auto-snapshot create spotlight", "keywords": "snapshot backup btrfs restore"},
            {"name": "System Benchmark", "sub": "Diagnostics", "cmd": "konsole -e /usr/bin/raytolfas-bench", "keywords": "bench benchmark speed cpu disk"},
        ]
        self._load_apps()

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
            f"/usr/share/icons/Papirus-Dark/32x32/apps/{icon_name}.svg",
            f"/usr/share/icons/Papirus-Dark/48x48/apps/{icon_name}.svg",
            f"/usr/share/icons/Papirus-Dark/48x48/devices/{icon_name}.svg",
            f"/usr/share/icons/Papirus-Dark/32x32/actions/{icon_name}.svg",
            f"/usr/share/icons/breeze-dark/apps/48/{icon_name}.svg",
            f"/usr/share/icons/breeze-dark/devices/64/{icon_name}.svg",
            f"/usr/share/icons/breeze-dark/actions/32/{icon_name}.svg",
            f"/usr/share/icons/breeze/apps/48/{icon_name}.svg",
            f"/usr/share/icons/hicolor/scalable/apps/{icon_name}.svg",
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

    def _load_apps(self):
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
                    if not name or not exec_cmd or name in seen:
                        continue
                    clean_exec = exec_cmd.split("%")[0].strip()
                    seen.add(name)
                    apps.append({
                        "name": name,
                        "sub": "Application",
                        "cmd": clean_exec,
                        "icon": self._resolve_icon(icon),
                    })
                except Exception:
                    continue
        apps.sort(key=lambda x: x["name"].lower())
        self._apps = apps

    def _try_math(self, expr):
        cleaned = expr.strip().lstrip("=").strip().replace("^", "**")
        if not cleaned or not any(c.isdigit() for c in cleaned):
            return None
        allowed_chars = set("0123456789+-*/().% ")
        safe_dict = {"sqrt": math.sqrt, "sin": math.sin, "cos": math.cos, "pi": math.pi, "abs": abs, "round": round}
        try:
            if all(c in allowed_chars for c in cleaned) or any(fn in cleaned for fn in safe_dict):
                val = eval(cleaned, {"__builtins__": {}}, safe_dict)
                if isinstance(val, (int, float)):
                    if isinstance(val, float) and val.is_integer():
                        val = int(val)
                    elif isinstance(val, float):
                        val = round(val, 6)
                    return str(val)
        except Exception:
            return None
        return None

    @pyqtProperty("QVariantList", notify=resultsChanged)
    def results(self):
        return self._results

    @pyqtSlot(str)
    def search(self, query):
        q = query.strip()
        if not q:
            self._results = []
            self.resultsChanged.emit()
            return

        out = []
        if q.startswith(">"):
            shell_cmd = q[1:].strip()
            if shell_cmd:
                out.append({
                    "name": shell_cmd,
                    "sub": "Run in Terminal",
                    "cmd": f"konsole -e bash -lc '{shell_cmd}; exec bash'",
                    "icon": ""
                })
            self._results = out
            self.resultsChanged.emit()
            return

        ql = q.lower()
        math_res = self._try_math(q)
        if math_res is not None and math_res != q:
            out.append({
                "name": f"= {math_res}",
                "sub": "Copy result",
                "cmd": f"__copy__:{math_res}",
                "icon": ""
            })

        for act in self._system_actions:
            if ql in act["name"].lower() or ql in act["keywords"]:
                out.append({
                    "name": act["name"],
                    "sub": act["sub"],
                    "cmd": act["cmd"],
                    "icon": ""
                })

        starts = [a for a in self._apps if a["name"].lower().startswith(ql)]
        contains = [a for a in self._apps if ql in a["name"].lower() and a not in starts]
        for app in starts + contains:
            out.append(app)
            if len(out) >= 8:
                break

        self._results = out[:8]
        self.resultsChanged.emit()

    @pyqtSlot(str)
    def execute(self, cmd):
        if not cmd:
            return
        if cmd.startswith("__copy__:"):
            val = cmd.split(":", 1)[1]
            clipboard = QGuiApplication.clipboard()
            if clipboard is not None:
                clipboard.setText(val)
            QGuiApplication.quit()
            return
        subprocess.Popen(cmd, shell=True, start_new_session=True)
        QGuiApplication.quit()

    @pyqtSlot()
    def closeSpotlight(self):
        QGuiApplication.quit()


def main():
    app = QGuiApplication(sys.argv)
    app.setApplicationName("Spotlight")
    engine = QQmlApplicationEngine()
    backend = SpotlightBackend()
    engine.rootContext().setContextProperty("spotlight", backend)
    qml_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "Spotlight.qml")
    engine.load(QUrl.fromLocalFile(qml_path))
    if not engine.rootObjects():
        sys.exit(1)
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
