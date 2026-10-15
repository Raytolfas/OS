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

                NavButton {
                    text: "Personalization"
                    iconText: "\u2728"
                    active: stackLayout.currentIndex === 4
                    onClicked: stackLayout.currentIndex = 4
                }

                NavButton {
                    text: "Gaming & Tools"
                    iconText: "\u25b6"
                    active: stackLayout.currentIndex === 5
                    onClicked: stackLayout.currentIndex = 5
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
                                text: "https://os.raytolfas.cc"
                                color: "#0078D4"
                                font.pixelSize: 13
                                font.bold: true
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Qt.openUrlExternally("https://os.raytolfas.cc")
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
                        height: Math.max(260, updateCol.implicitHeight + 48)
                        color: "#0f172a"
                        radius: 12
                        border.color: "#1e293b"

                        Column {
                            id: updateCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
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

                            Rectangle {
                                width: parent.width
                                height: 6
                                radius: 3
                                color: "#1e293b"
                                visible: backend.update_checking && backend.update_progress > 0

                                Rectangle {
                                    width: parent.width * (backend.update_progress / 100.0)
                                    height: parent.height
                                    radius: 3
                                    color: "#0078D4"
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
                        spacing: 12

                        Rectangle {
                            width: 170
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
                            color: dlUpgradeMouse.containsMouse ? "#1084d8" : "#0078D4"
                            visible: backend.update_available

                            Text {
                                anchors.centerIn: parent
                                text: backend.update_checking ? "Upgrading..." : "Download & Upgrade"
                                color: "#ffffff"
                                font.pixelSize: 14
                                font.bold: true
                            }
                            MouseArea {
                                id: dlUpgradeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !backend.update_checking
                                cursorShape: Qt.PointingHandCursor
                                onClicked: backend.download_and_apply_iso()
                            }
                        }

                        Rectangle {
                            width: 210
                            height: 42
                            radius: 8
                            color: localIsoMouse.containsMouse ? "#334155" : "#1e293b"
                            border.color: "#475569"

                            Text {
                                anchors.centerIn: parent
                                text: "Upgrade from Local ISO..."
                                color: "#ffffff"
                                font.pixelSize: 14
                                font.bold: true
                            }
                            MouseArea {
                                id: localIsoMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !backend.update_checking
                                cursorShape: Qt.PointingHandCursor
                                onClicked: backend.choose_and_apply_iso()
                            }
                        }

                        Rectangle {
                            width: 150
                            height: 42
                            radius: 8
                            color: dlMouse.containsMouse ? "#334155" : "#1e293b"
                            border.color: "#475569"
                            visible: backend.update_available

                            Text {
                                anchors.centerIn: parent
                                text: "Open in Browser"
                                color: "#94a3b8"
                                font.pixelSize: 13
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
                                text: backend.patch_checking ? "Installing..." : "Install Patch"
                                color: "#ffffff"
                                font.pixelSize: 14
                                font.bold: true
                            }
                            MouseArea {
                                id: patchDlMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !backend.patch_checking
                                cursorShape: Qt.PointingHandCursor
                                onClicked: backend.download_patch()
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
                        text: "Personalization & Themes"
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

                        Column {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 12

                            Text {
                                text: "Desktop Style"
                                color: "#ffffff"
                                font.pixelSize: 15
                                font.bold: true
                            }

                            Row {
                                spacing: 14

                                Rectangle {
                                    width: 140
                                    height: 38
                                    radius: 8
                                    color: backend.current_theme === "dark" ? "#0078D4" : "#1e293b"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Fluent Dark"
                                        color: "#ffffff"
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: backend.apply_theme("dark")
                                    }
                                }

                                Rectangle {
                                    width: 140
                                    height: 38
                                    radius: 8
                                    color: backend.current_theme === "light" ? "#0078D4" : "#1e293b"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Fluent Light"
                                        color: "#ffffff"
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: backend.apply_theme("light")
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 110
                        color: "#0f172a"
                        radius: 12
                        border.color: "#1e293b"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 12

                            Text {
                                text: "Accent Color"
                                color: "#ffffff"
                                font.pixelSize: 15
                                font.bold: true
                            }

                            Row {
                                spacing: 14

                                Repeater {
                                    model: ["#0078D4", "#8b5cf6", "#10b981", "#ef4444", "#f59e0b"]
                                    Rectangle {
                                        width: 34
                                        height: 34
                                        radius: 17
                                        color: modelData
                                        border.color: backend.accent_color === modelData ? "#ffffff" : "transparent"
                                        border.width: 2
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: backend.apply_accent_color(modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 100
                        color: "#0f172a"
                        radius: 12
                        border.color: "#1e293b"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 12

                            Text {
                                text: "Capture & Recording"
                                color: "#ffffff"
                                font.pixelSize: 15
                                font.bold: true
                            }

                            Row {
                                spacing: 14

                                Rectangle {
                                    width: 170
                                    height: 38
                                    radius: 8
                                    color: "#1e293b"
                                    border.color: "#475569"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Take Screenshot"
                                        color: "#ffffff"
                                        font.pixelSize: 13
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: backend.launch_spectacle()
                                    }
                                }

                                Rectangle {
                                    width: 170
                                    height: 38
                                    radius: 8
                                    color: "#1e293b"
                                    border.color: "#475569"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Record Screen"
                                        color: "#ffffff"
                                        font.pixelSize: 13
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: backend.launch_spectacle_record()
                                    }
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
                        text: "Gaming & Performance"
                        color: "#ffffff"
                        font.pixelSize: 24
                        font.bold: true
                    }

                    Rectangle {
                        width: parent.width
                        height: 140
                        color: "#0f172a"
                        radius: 12
                        border.color: "#1e293b"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 12

                            Text {
                                text: "Gaming Optimizations"
                                color: "#ffffff"
                                font.pixelSize: 15
                                font.bold: true
                            }

                            Row {
                                spacing: 14

                                Rectangle {
                                    width: 180
                                    height: 38
                                    radius: 8
                                    color: backend.gamemode_active ? "#10b981" : "#1e293b"
                                    border.color: "#475569"
                                    Text {
                                        anchors.centerIn: parent
                                        text: backend.gamemode_active ? "GameMode Active" : "Enable GameMode"
                                        color: "#ffffff"
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: backend.toggle_gamemode()
                                    }
                                }

                                Rectangle {
                                    width: 180
                                    height: 38
                                    radius: 8
                                    color: backend.mangohud_active ? "#10b981" : "#1e293b"
                                    border.color: "#475569"
                                    Text {
                                        anchors.centerIn: parent
                                        text: backend.mangohud_active ? "MangoHUD On" : "Enable MangoHUD"
                                        color: "#ffffff"
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: backend.toggle_mangohud()
                                    }
                                }
                            }

                            Text {
                                text: "Supports gamescope, GameMode governor and MangoHUD FPS/frametime overlay."
                                color: "#94a3b8"
                                font.pixelSize: 12
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 120
                        color: "#0f172a"
                        radius: 12
                        border.color: "#1e293b"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 12

                            Text {
                                text: "Power & Battery Profile"
                                color: "#ffffff"
                                font.pixelSize: 15
                                font.bold: true
                            }

                            Row {
                                spacing: 14

                                Rectangle {
                                    width: 140
                                    height: 38
                                    radius: 8
                                    color: backend.current_power_profile === "power-saver" ? "#10b981" : "#1e293b"
                                    border.color: "#475569"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Power Saver"
                                        color: "#ffffff"
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: backend.set_power_profile("power-saver")
                                    }
                                }

                                Rectangle {
                                    width: 140
                                    height: 38
                                    radius: 8
                                    color: backend.current_power_profile === "balanced" ? "#0078D4" : "#1e293b"
                                    border.color: "#475569"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Balanced"
                                        color: "#ffffff"
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: backend.set_power_profile("balanced")
                                    }
                                }

                                Rectangle {
                                    width: 140
                                    height: 38
                                    radius: 8
                                    color: backend.current_power_profile === "performance" ? "#ef4444" : "#1e293b"
                                    border.color: "#475569"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Performance"
                                        color: "#ffffff"
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: backend.set_power_profile("performance")
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 140
                        color: "#0f172a"
                        radius: 12
                        border.color: "#1e293b"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 12

                            Text {
                                text: "Subsystems & Input"
                                color: "#ffffff"
                                font.pixelSize: 15
                                font.bold: true
                            }

                            Row {
                                spacing: 14

                                Rectangle {
                                    width: 220
                                    height: 38
                                    radius: 8
                                    color: "#0078D4"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Configure ARM (libndk)"
                                        color: "#ffffff"
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: backend.setup_android_libndk()
                                    }
                                }
                            }

                            Text {
                                text: "Mouse side buttons (Mouse 4 & 5) mapped to Back/Forward navigation."
                                color: "#94a3b8"
                                font.pixelSize: 12
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
