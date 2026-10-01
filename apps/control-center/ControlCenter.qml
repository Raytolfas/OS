import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: appWindow
    width: 860
    height: 560
    minimumWidth: 720
    minimumHeight: 480
    visible: true
    title: "Raytolfas OS Control Center"
    color: "#0a0e17"

    Row {
        anchors.fill: parent

        Rectangle {
            width: 230
            height: parent.height
            color: "#070a10"
            border.color: "#161f30"
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Row {
                    spacing: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                    Image {
                        width: 38
                        height: 38
                        source: "file:///usr/share/icons/hicolor/512x512/apps/raytolfas-logo.png"
                        fillMode: Image.PreserveAspectFit
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            text: "Raytolfas OS"
                            color: "#ffffff"
                            font.pixelSize: 16
                            font.bold: true
                            font.family: "Noto Sans"
                        }
                        Text {
                            text: "Control Center"
                            color: "#0078D4"
                            font.pixelSize: 11
                            font.family: "Noto Sans"
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#1e293b"
                }

                NavButton {
                    text: "About"
                    iconText: "\u2139"
                    active: stackLayout.currentIndex === 0
                    onClicked: stackLayout.currentIndex = 0
                }

                NavButton {
                    text: "Updates"
                    iconText: "\u21bb"
                    active: stackLayout.currentIndex === 1
                    onClicked: {
                        stackLayout.currentIndex = 1
                        backend.check_for_updates()
                    }
                }

                NavButton {
                    text: "Compatibility"
                    iconText: "\u2699"
                    active: stackLayout.currentIndex === 2
                    onClicked: stackLayout.currentIndex = 2
                }

                NavButton {
                    text: "Patches (OTA)"
                    iconText: "\u25c8"
                    active: stackLayout.currentIndex === 3
                    onClicked: {
                        stackLayout.currentIndex = 3
                        if (backend.patch_agreed) {
                            backend.check_for_patches()
                        }
                    }
                }
            }
        }

        StackLayout {
            id: stackLayout
            width: parent.width - 230
            height: parent.height
            currentIndex: 0

            Item {
                Column {
                    anchors.fill: parent
                    anchors.margins: 36
                    spacing: 20

                    Text {
                        text: "System Information"
                        color: "#ffffff"
                        font.pixelSize: 24
                        font.bold: true
                    }

                    Rectangle {
                        width: parent.width
                        height: 220
                        color: "#0f172a"
                        radius: 12
                        border.color: "#1e293b"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 12

                            InfoRow { label: "Distribution:"; value: "Raytolfas OS D1" }
                            InfoRow { label: "Version:"; value: backend.os_version }
                            InfoRow { label: "Linux Kernel:"; value: backend.kernel_version }
                            InfoRow { label: "Graphics:"; value: "KDE Plasma 6 (X11 / Wayland)" }
                            InfoRow { label: "Processor:"; value: backend.cpu_info }
                            InfoRow { label: "Memory:"; value: backend.ram_info }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 52
                        color: "#0f172a"
                        radius: 8
                        border.color: "#1e293b"

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            spacing: 8
                            Text { text: "Official Website:"; color: "#94a3b8"; font.pixelSize: 13 }
                            Text {
                                text: "https://raytolfas.com"
                                color: "#0078D4"
                                font.pixelSize: 13
                                font.bold: true
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Qt.openUrlExternally("https://raytolfas.com")
                                }
                            }
                        }
                    }
                }
            }

            Item {
                Column {
                    anchors.fill: parent
                    anchors.margins: 36
                    spacing: 20

                    Text {
                        text: "System Updates"
                        color: "#ffffff"
                        font.pixelSize: 24
                        font.bold: true
                    }

                    Rectangle {
                        width: parent.width
                        height: 260
                        color: "#0f172a"
                        radius: 12
                        border.color: "#1e293b"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 24
                            spacing: 16

                            Row {
                                spacing: 12
                                Text { text: "Update Server:"; color: "#94a3b8"; font.pixelSize: 14 }
                                Text { text: "os.raytolfas.cc/update"; color: "#0078D4"; font.pixelSize: 14; font.bold: true }
                            }

                            Row {
                                spacing: 12
                                Text { text: "Current Version:"; color: "#94a3b8"; font.pixelSize: 14 }
                                Text { text: backend.os_version; color: "#ffffff"; font.pixelSize: 14; font.bold: true }
                            }

                            Rectangle {
                                width: parent.width
                                height: 1
                                color: "#1e293b"
                            }

                            Row {
                                spacing: 12
                                Rectangle {
                                    width: 14; height: 14; radius: 7
                                    color: backend.update_available ? "#eab308" : (backend.update_checking ? "#0078D4" : "#22c55e")
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: backend.update_status
                                    color: "#ffffff"
                                    font.pixelSize: 15
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Text {
                                text: backend.update_changelog
                                color: "#94a3b8"
                                font.pixelSize: 13
                                wrapMode: Text.WordWrap
                                width: parent.width
                                visible: backend.update_changelog !== ""
                            }
                        }
                    }

                    Row {
                        spacing: 16

                        Rectangle {
                            width: 190
                            height: 42
                            radius: 8
                            color: checkMouse.containsMouse ? "#334155" : "#1e293b"
                            border.color: "#475569"

                            Text {
                                anchors.centerIn: parent
                                text: "Check for Updates"
                                color: "#ffffff"
                                font.pixelSize: 14
                                font.bold: true
                            }
                            MouseArea {
                                id: checkMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: backend.check_for_updates()
                            }
                        }

                        Rectangle {
                            width: 200
                            height: 42
                            radius: 8
                            color: dlMouse.containsMouse ? "#1084d8" : "#0078D4"
                            visible: backend.update_available

                            Text {
                                anchors.centerIn: parent
                                text: "Download Update"
                                color: "#ffffff"
                                font.pixelSize: 14
                                font.bold: true
                            }
                            MouseArea {
                                id: dlMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: backend.download_update()
                            }
                        }
                    }
                }
            }

            Item {
                Column {
                    anchors.fill: parent
                    anchors.margins: 36
                    spacing: 20

                    Text {
                        text: "Compatibility Subsystems"
                        color: "#ffffff"
                        font.pixelSize: 24
                        font.bold: true
                    }

                    Rectangle {
                        width: parent.width
                        height: 120
                        color: "#0f172a"
                        radius: 12
                        border.color: "#1e293b"

                        Row {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 16

                            Rectangle {
                                width: 52; height: 52; radius: 10
                                color: "#0078D4"
                                Text { anchors.centerIn: parent; text: "APK"; font.pixelSize: 15; font.bold: true; color: "#ffffff" }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4
                                Text { text: "Android Subsystem (Waydroid)"; color: "#ffffff"; font.pixelSize: 16; font.bold: true }
                                Text { text: "Run Android (.apk) applications with ARM/x86 translation"; color: "#94a3b8"; font.pixelSize: 13 }
                                Text { text: "Status: " + backend.waydroid_status; color: "#38bdf8"; font.pixelSize: 12 }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 120
                        color: "#0f172a"
                        radius: 12
                        border.color: "#1e293b"

                        Row {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 16

                            Rectangle {
                                width: 52; height: 52; radius: 10
                                color: "#7c3aed"
                                Text { anchors.centerIn: parent; text: "EXE"; font.pixelSize: 15; font.bold: true; color: "#ffffff" }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4
                                Text { text: "Windows Compatibility (Proton-GE)"; color: "#ffffff"; font.pixelSize: 16; font.bold: true }
                                Text { text: "Run Windows (.exe) games and software via Wine/DXVK"; color: "#94a3b8"; font.pixelSize: 13 }
                                Text { text: "Version: GE-Proton11-7 (x86_64)"; color: "#a78bfa"; font.pixelSize: 12 }
                            }
                        }
                    }
                }
            }

            Item {
                Column {
                    anchors.fill: parent
                    anchors.margins: 36
                    spacing: 20

                    Text {
                        text: "System Patches (OTA)"
                        color: "#ffffff"
                        font.pixelSize: 24
                        font.bold: true
                    }

                    Rectangle {
                        width: parent.width
                        height: 280
                        color: "#0f172a"
                        radius: 12
                        border.color: "#1e293b"
                        visible: !backend.patch_agreed

                        Column {
                            anchors.fill: parent
                            anchors.margins: 24
                            spacing: 16

                            Row {
                                spacing: 12
                                Rectangle {
                                    width: 44; height: 44; radius: 8
                                    color: "#f59e0b"
                                    Text { anchors.centerIn: parent; text: "!"; font.pixelSize: 22; font.bold: true; color: "#000000" }
                                }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4
                                    Text { text: "System Hotfix Mode"; color: "#ffffff"; font.pixelSize: 16; font.bold: true }
                                    Text { text: "Quick fixes and testing components between major releases"; color: "#94a3b8"; font.pixelSize: 13 }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 1
                                color: "#1e293b"
                            }

                            Text {
                                text: "Hotfix patches are delivered directly from the update server to test fixes for drivers, system services, and desktop components between major versions. Please confirm your consent to proceed."
                                color: "#cbd5e1"
                                font.pixelSize: 13
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }

                            Item { width: 1; height: 8 }

                            Rectangle {
                                width: 220
                                height: 42
                                radius: 8
                                color: agreeMouse.containsMouse ? "#1084d8" : "#0078D4"

                                Text {
                                    anchors.centerIn: parent
                                    text: "I Understand and Agree"
                                    color: "#ffffff"
                                    font.pixelSize: 14
                                    font.bold: true
                                }
                                MouseArea {
                                    id: agreeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: backend.set_patch_agreed(true)
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 260
                        color: "#0f172a"
                        radius: 12
                        border.color: "#1e293b"
                        visible: backend.patch_agreed

                        Column {
                            anchors.fill: parent
                            anchors.margins: 24
                            spacing: 16

                            Row {
                                spacing: 12
                                Text { text: "Patch Server:"; color: "#94a3b8"; font.pixelSize: 14 }
                                Text { text: "os.raytolfas.cc/update"; color: "#0078D4"; font.pixelSize: 14; font.bold: true }
                            }

                            Row {
                                spacing: 12
                                Text { text: "Current Revision:"; color: "#94a3b8"; font.pixelSize: 14 }
                                Text { text: backend.current_patch_version; color: "#ffffff"; font.pixelSize: 14; font.bold: true }
                            }

                            Rectangle {
                                width: parent.width
                                height: 1
                                color: "#1e293b"
                            }

                            Row {
                                spacing: 12
                                Rectangle {
                                    width: 14; height: 14; radius: 7
                                    color: backend.patch_available ? "#eab308" : (backend.patch_checking ? "#0078D4" : "#22c55e")
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: backend.patch_status
                                    color: "#ffffff"
                                    font.pixelSize: 15
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Text {
                                text: backend.patch_changelog
                                color: "#94a3b8"
                                font.pixelSize: 13
                                wrapMode: Text.WordWrap
                                width: parent.width
                                visible: backend.patch_changelog !== ""
                            }
                        }
                    }

                    Row {
                        spacing: 16
                        visible: backend.patch_agreed

                        Rectangle {
                            width: 190
                            height: 42
                            radius: 8
                            color: patchCheckMouse.containsMouse ? "#334155" : "#1e293b"
                            border.color: "#475569"

                            Text {
                                anchors.centerIn: parent
                                text: "Check for Patches"
                                color: "#ffffff"
                                font.pixelSize: 14
                                font.bold: true
                            }
                            MouseArea {
                                id: patchCheckMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: backend.check_for_patches()
                            }
                        }

                        Rectangle {
                            width: 190
                            height: 42
                            radius: 8
                            color: patchDlMouse.containsMouse ? "#1084d8" : "#0078D4"
                            visible: backend.patch_available

                            Text {
                                anchors.centerIn: parent
                                text: "Install Patch"
                                color: "#ffffff"
                                font.pixelSize: 14
                                font.bold: true
                            }
                            MouseArea {
                                id: patchDlMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: backend.download_patch()
                            }
                        }
                    }
                }
            }
        }
    }

    component NavButton: Rectangle {
        property string text: ""
        property string iconText: ""
        property bool active: false
        signal clicked()

        width: parent.width
        height: 42
        radius: 8
        color: active ? "#0078D4" : (navMouse.containsMouse ? "#1e293b" : "transparent")

        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 14
            spacing: 12
            Text {
                text: iconText
                color: active ? "#ffffff" : "#94a3b8"
                font.pixelSize: 15
            }
            Text {
                text: parent.parent.text
                color: active ? "#ffffff" : "#e2e8f0"
                font.pixelSize: 14
                font.bold: active
                font.family: "Noto Sans"
            }
        }

        MouseArea {
            id: navMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    component InfoRow: Row {
        property string label: ""
        property string value: ""
        spacing: 12
        Text { width: 180; text: label; color: "#94a3b8"; font.pixelSize: 14 }
        Text { text: value; color: "#ffffff"; font.pixelSize: 14; font.bold: true }
    }
}
