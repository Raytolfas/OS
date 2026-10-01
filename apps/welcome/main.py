#!/usr/bin/env python3
import sys, os, subprocess
from pathlib import Path
from PyQt6.QtCore import QObject, pyqtSlot, QUrl
from PyQt6.QtGui import QGuiApplication, QIcon
from PyQt6.QtQml import QQmlApplicationEngine

MARKER = Path.home() / ".config" / "raytolfas" / "welcome_done"

class Backend(QObject):
    @pyqtSlot()
    def finish_welcome(self):
        try:
            MARKER.parent.mkdir(parents=True, exist_ok=True)
            MARKER.touch()
        except Exception as e:
            print("Could not write marker:", e)

def main():
    if "--force" not in sys.argv and MARKER.exists():
        sys.exit(0)

    app = QGuiApplication(sys.argv)
    app.setApplicationName("Raytolfas OS Welcome")
    
    icon_path = "/usr/share/icons/hicolor/512x512/apps/raytolfas-logo.png"
    if os.path.exists(icon_path):
        app.setWindowIcon(QIcon(icon_path))

    backend = Backend()
    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("backend", backend)

    qml_file = Path(__file__).parent / "Welcome.qml"
    engine.load(QUrl.fromLocalFile(str(qml_file)))

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())

if __name__ == "__main__":
    main()
