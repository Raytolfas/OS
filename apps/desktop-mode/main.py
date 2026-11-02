#!/usr/bin/env python3
import os
import sys
import subprocess
from PyQt6.QtCore import QObject, pyqtSignal, pyqtProperty, pyqtSlot, QUrl, QPoint
from PyQt6.QtGui import QGuiApplication, QCursor
from PyQt6.QtQml import QQmlApplicationEngine


class TouchpadBackend(QObject):
    stateChanged = pyqtSignal()

    def __init__(self):
        super().__init__()
        self._sensitivity = 1.6
        self._uinput = None
        self._init_uinput()

    def _init_uinput(self):
        try:
            import evdev
            from evdev import UInput, ecodes
            cap = {
                ecodes.EV_REL: (ecodes.REL_X, ecodes.REL_Y, ecodes.REL_WHEEL),
                ecodes.EV_KEY: (ecodes.BTN_LEFT, ecodes.BTN_RIGHT, ecodes.BTN_MIDDLE),
            }
            self._uinput = UInput(cap, name="Desktop-Mode-Touchpad")
        except Exception:
            self._uinput = None

    @pyqtProperty(float, notify=stateChanged)
    def sensitivity(self):
        return self._sensitivity

    @pyqtSlot(float)
    def setSensitivity(self, val):
        self._sensitivity = max(0.5, min(4.0, val))
        self.stateChanged.emit()

    @pyqtSlot(float, float)
    def moveCursor(self, dx, dy):
        mx = int(round(dx * self._sensitivity))
        my = int(round(dy * self._sensitivity))
        if mx == 0 and my == 0:
            return
        if self._uinput is not None:
            try:
                from evdev import ecodes
                self._uinput.write(ecodes.EV_REL, ecodes.REL_X, mx)
                self._uinput.write(ecodes.EV_REL, ecodes.REL_Y, my)
                self._uinput.syn()
                return
            except Exception:
                pass
        pos = QCursor.pos()
        QCursor.setPos(QPoint(pos.x() + mx, pos.y() + my))

    @pyqtSlot(str)
    def clickButton(self, button):
        if self._uinput is not None:
            try:
                from evdev import ecodes
                code = ecodes.BTN_LEFT
                if button == "right":
                    code = ecodes.BTN_RIGHT
                elif button == "middle":
                    code = ecodes.BTN_MIDDLE
                self._uinput.write(ecodes.EV_KEY, code, 1)
                self._uinput.syn()
                self._uinput.write(ecodes.EV_KEY, code, 0)
                self._uinput.syn()
                return
            except Exception:
                pass
        btn_num = "1"
        if button == "middle":
            btn_num = "2"
        elif button == "right":
            btn_num = "3"
        subprocess.Popen(f"xdotool click {btn_num}", shell=True, stderr=subprocess.DEVNULL)

    @pyqtSlot(float)
    def scrollVertical(self, dy):
        step = 1 if dy < 0 else -1
        if self._uinput is not None:
            try:
                from evdev import ecodes
                self._uinput.write(ecodes.EV_REL, ecodes.REL_WHEEL, step)
                self._uinput.syn()
                return
            except Exception:
                pass

    @pyqtSlot()
    def openVirtualKeyboard(self):
        subprocess.Popen("(command -v qdbus6 >/dev/null 2>&1 && qdbus6 org.kde.kwin /VirtualKeyboard org.kde.kwin.VirtualKeyboard.forceActivate) || qdbus org.kde.kwin /VirtualKeyboard org.kde.kwin.VirtualKeyboard.forceActivate", shell=True, stderr=subprocess.DEVNULL)

    @pyqtSlot()
    def exitDesktopMode(self):
        subprocess.Popen("/usr/bin/raytolfas-desktop-mode disable", shell=True)
        QGuiApplication.quit()


def main():
    app = QGuiApplication(sys.argv)
    app.setApplicationName("Desktop Mode Touchpad")
    engine = QQmlApplicationEngine()
    backend = TouchpadBackend()
    engine.rootContext().setContextProperty("tp", backend)
    qml_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "Touchpad.qml")
    engine.load(QUrl.fromLocalFile(qml_path))
    if not engine.rootObjects():
        sys.exit(1)
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
