import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: shellRoot
    width: 390
    height: 820
    minimumWidth: 340
    minimumHeight: 640
    visible: true
    title: "Raytolfas OS M1"
    color: "#090b10"

    property string currentView: "home"
    property bool shadeOpen: false

    Item {
        id: statusBar
        z: 30
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 28

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 8

            Text {
                text: m1.timeStr
                color: "#e2e8f0"
                font.pixelSize: 12
                font.bold: true
                font.family: "Noto Sans"
            }

            Item { Layout.fillWidth: true }

            Text {
                visible: m1.wifiEnabled
                text: "Wi-Fi"
                color: "#94a3b8"
                font.pixelSize: 11
                font.family: "Noto Sans"
            }

            Text {
                text: m1.batteryPct + "%"
                color: "#cbd5e1"
                font.pixelSize: 11
                font.family: "Noto Sans"
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: shellRoot.shadeOpen = !shellRoot.shadeOpen
        }
    }

    Item {
        id: homeView
        visible: shellRoot.currentView === "home"
        anchors.top: statusBar.bottom
        anchors.bottom: navBar.top
        anchors.left: parent.left
        anchors.right: parent.right

        MouseArea {
            anchors.fill: parent
            property real startY: 0
            onPressed: function(mouse) { startY = mouse.y }
            onReleased: function(mouse) {
                var dy = mouse.y - startY
                if (dy < -50) {
                    shellRoot.currentView = "drawer"
                } else if (dy > 50) {
                    shellRoot.shadeOpen = true
                }
            }
        }

        Column {
            id: clockHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: 28
            anchors.leftMargin: 24
            spacing: 2

            Text {
                text: m1.timeStr
                color: "#f8fafc"
                font.pixelSize: 42
                font.weight: Font.Light
                font.family: "Noto Sans"
            }

            Text {
                text: m1.dateStr
                color: "#94a3b8"
                font.pixelSize: 12
                font.family: "Noto Sans"
            }
        }

        GridView {
            id: homeGrid
            anchors.top: clockHeader.bottom
            anchors.bottom: bottomDock.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 28
            anchors.bottomMargin: 16
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            cellWidth: Math.floor(width / 4)
            cellHeight: 82
            interactive: false
            clip: true
            model: m1.appList.slice(0, 12)

            delegate: Item {
                width: homeGrid.cellWidth
                height: homeGrid.cellHeight

                Column {
                    anchors.centerIn: parent
                    width: parent.width - 8
                    spacing: 6

                    Item {
                        width: 42
                        height: 42
                        anchors.horizontalCenter: parent.horizontalCenter

                        Image {
                            anchors.fill: parent
                            source: modelData.icon
                            sourceSize.width: 48
                            sourceSize.height: 48
                            visible: modelData.icon !== ""
                            fillMode: Image.PreserveAspectFit
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            color: "#18ffffff"
                            border.color: "#1affffff"
                            border.width: 1
                            visible: modelData.icon === ""

                            Text {
                                anchors.centerIn: parent
                                text: modelData.letter
                                color: "#e2e8f0"
                                font.pixelSize: 16
                                font.bold: true
                                font.family: "Noto Sans"
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: modelData.name
                        color: "#cbd5e1"
                        font.pixelSize: 11
                        font.family: "Noto Sans"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: m1.launchApp(modelData.name, modelData.exec)
                }
            }
        }

        Rectangle {
            id: bottomDock
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 32
            height: 60
            radius: 14
            color: "#12ffffff"
            border.color: "#1affffff"
            border.width: 1

            Row {
                anchors.centerIn: parent
                spacing: Math.max(16, Math.floor((parent.width - 4 * 42) / 5))

                Repeater {
                    model: [
                        { id: "browser", label: "Web", icon: "file:///usr/share/icons/Papirus-Dark/48x48/apps/firefox.svg" },
                        { id: "files", label: "Files", icon: "file:///usr/share/icons/Papirus-Dark/48x48/apps/system-file-manager.svg" },
                        { id: "terminal", label: "Term", icon: "file:///usr/share/icons/Papirus-Dark/48x48/apps/utilities-terminal.svg" },
                        { id: "settings", label: "Settings", icon: "file:///usr/share/icons/hicolor/512x512/apps/raytolfas-logo.png" }
                    ]

                    delegate: Item {
                        width: 42
                        height: 42

                        Image {
                            id: dockImg
                            anchors.centerIn: parent
                            width: 36
                            height: 36
                            source: modelData.icon
                            sourceSize.width: 48
                            sourceSize.height: 48
                            fillMode: Image.PreserveAspectFit
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            color: "#1affffff"
                            visible: dockImg.status !== Image.Ready

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label[0]
                                color: "#f1f5f9"
                                font.pixelSize: 14
                                font.bold: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: m1.launchQuick(modelData.id)
                        }
                    }
                }
            }
        }
    }

    Item {
        id: drawerView
        visible: shellRoot.currentView === "drawer"
        anchors.top: statusBar.bottom
        anchors.bottom: navBar.top
        anchors.left: parent.left
        anchors.right: parent.right

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: 8
                color: "#14ffffff"
                border.color: "#1cffffff"
                border.width: 1

                TextField {
                    id: drawerSearch
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    placeholderText: "Search apps..."
                    placeholderTextColor: "#64748b"
                    color: "#f1f5f9"
                    font.pixelSize: 12
                    font.family: "Noto Sans"
                    verticalAlignment: TextInput.AlignVCenter
                    background: Item {}
                    onTextChanged: m1.filterApps(text)
                }
            }

            GridView {
                id: allAppsGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                cellWidth: Math.floor(width / 4)
                cellHeight: 78
                clip: true
                model: m1.appList

                delegate: Item {
                    width: allAppsGrid.cellWidth
                    height: allAppsGrid.cellHeight

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 8
                        spacing: 5

                        Item {
                            width: 40
                            height: 40
                            anchors.horizontalCenter: parent.horizontalCenter

                            Image {
                                anchors.fill: parent
                                source: modelData.icon
                                sourceSize.width: 48
                                sourceSize.height: 48
                                visible: modelData.icon !== ""
                                fillMode: Image.PreserveAspectFit
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 9
                                color: "#18ffffff"
                                visible: modelData.icon === ""

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.letter
                                    color: "#e2e8f0"
                                    font.pixelSize: 15
                                    font.bold: true
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: modelData.name
                            color: "#cbd5e1"
                            font.pixelSize: 11
                            font.family: "Noto Sans"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            m1.launchApp(modelData.name, modelData.exec)
                            shellRoot.currentView = "home"
                        }
                    }
                }
            }
        }
    }

    Item {
        id: tasksView
        visible: shellRoot.currentView === "tasks"
        anchors.top: statusBar.bottom
        anchors.bottom: navBar.top
        anchors.left: parent.left
        anchors.right: parent.right

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Recent"
                    color: "#94a3b8"
                    font.pixelSize: 12
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                    visible: m1.recentTasks.length > 0
                    text: "Clear all"
                    color: "#cbd5e1"
                    font.pixelSize: 11
                    MouseArea {
                        anchors.fill: parent
                        onClicked: m1.clearTasks()
                    }
                }
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 6
                clip: true
                model: m1.recentTasks

                delegate: Rectangle {
                    width: ListView.view.width
                    height: 44
                    radius: 8
                    color: "#12ffffff"
                    border.color: "#18ffffff"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12

                        Text {
                            text: modelData.name
                            color: "#f1f5f9"
                            font.pixelSize: 12
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "×"
                            color: "#94a3b8"
                            font.pixelSize: 16
                            MouseArea {
                                anchors.fill: parent
                                onClicked: m1.closeTask(modelData.name)
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.rightMargin: 36
                        onClicked: {
                            m1.launchApp(modelData.name, modelData.exec)
                            shellRoot.currentView = "home"
                        }
                    }
                }
            }

            Text {
                visible: m1.recentTasks.length === 0
                Layout.alignment: Qt.AlignCenter
                text: "No recent apps"
                color: "#64748b"
                font.pixelSize: 12
            }
        }
    }

    Rectangle {
        id: shadeBackdrop
        z: 35
        visible: shellRoot.shadeOpen
        anchors.fill: parent
        color: "#88000000"

        MouseArea {
            anchors.fill: parent
            onClicked: shellRoot.shadeOpen = false
        }
    }

    Rectangle {
        id: quickShade
        z: 40
        visible: shellRoot.shadeOpen
        anchors.top: statusBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        height: shadeCol.implicitHeight + 24
        radius: 10
        color: "#f411151d"
        border.color: "#22ffffff"
        border.width: 1

        Column {
            id: shadeCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            GridLayout {
                width: parent.width
                columns: 3
                columnSpacing: 6
                rowSpacing: 6

                QuickTile { label: "Wi-Fi"; active: m1.wifiEnabled; onTriggered: m1.toggleWifi() }
                QuickTile { label: "Bluetooth"; active: m1.btEnabled; onTriggered: m1.toggleBt() }
                QuickTile { label: "Turbo"; active: m1.turboEnabled; onTriggered: m1.toggleTurbo() }
                QuickTile { label: "Desktop"; active: m1.desktopMode; onTriggered: m1.toggleDesktopMode() }
                QuickTile { label: "DND"; active: m1.dndEnabled; onTriggered: m1.toggleDnd() }
                QuickTile { label: "Rotate"; active: m1.rotateEnabled; onTriggered: m1.toggleRotate() }
            }

            Column {
                width: parent.width
                spacing: 6

                RowLayout {
                    width: parent.width
                    spacing: 8
                    Text { text: "Brightness"; color: "#94a3b8"; font.pixelSize: 11; Layout.preferredWidth: 64 }
                    Slider {
                        Layout.fillWidth: true
                        from: 10
                        to: 100
                        value: m1.brightnessLevel
                        onMoved: m1.setBrightness(Math.round(value))
                    }
                }

                RowLayout {
                    width: parent.width
                    spacing: 8
                    Text { text: "Volume"; color: "#94a3b8"; font.pixelSize: 11; Layout.preferredWidth: 64 }
                    Slider {
                        Layout.fillWidth: true
                        from: 0
                        to: 100
                        value: m1.volumeLevel
                        onMoved: m1.setVolume(Math.round(value))
                    }
                }
            }
        }
    }

    Item {
        id: navBar
        z: 30
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 28

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 48
            anchors.rightMargin: 48

            Text {
                text: "‹"
                color: "#94a3b8"
                font.pixelSize: 18
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    onClicked: {
                        if (shellRoot.shadeOpen) shellRoot.shadeOpen = false
                        else shellRoot.currentView = "home"
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 72
                height: 4
                radius: 2
                color: "#99ffffff"

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -10
                    onClicked: {
                        shellRoot.shadeOpen = false
                        shellRoot.currentView = shellRoot.currentView === "home" ? "drawer" : "home"
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 11
                height: 11
                radius: 3
                color: "transparent"
                border.color: "#94a3b8"
                border.width: 1.4

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    onClicked: {
                        shellRoot.shadeOpen = false
                        shellRoot.currentView = shellRoot.currentView === "tasks" ? "home" : "tasks"
                    }
                }
            }
        }
    }

    component QuickTile: Rectangle {
        property string label: ""
        property bool active: false
        signal triggered()

        Layout.fillWidth: true
        Layout.preferredHeight: 34
        radius: 7
        color: active ? "#2838bdf8" : "#14ffffff"
        border.color: active ? "#5538bdf8" : "#18ffffff"
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: label
            color: active ? "#f8fafc" : "#94a3b8"
            font.pixelSize: 11
            font.bold: active
            font.family: "Noto Sans"
        }

        MouseArea {
            anchors.fill: parent
            onClicked: triggered()
        }
    }
}
