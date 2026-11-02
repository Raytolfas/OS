import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: consoleWindow
    width: 1280
    height: 720
    visibility: Window.FullScreen
    visible: true
    title: "Console Mode"
    color: "#0a0c10"

    property bool overlayOpen: false
    property int overlayIndex: 0

    Connections {
        target: consoleBackend
        function onGamepadAction(act) {
            if (act === "overlay") {
                consoleWindow.overlayOpen = !consoleWindow.overlayOpen
            } else if (consoleWindow.overlayOpen) {
                if (act === "up") {
                    consoleWindow.overlayIndex = Math.max(0, consoleWindow.overlayIndex - 1)
                } else if (act === "down") {
                    consoleWindow.overlayIndex = Math.min(4, consoleWindow.overlayIndex + 1)
                } else if (act === "accept") {
                    triggerOverlayAction(consoleWindow.overlayIndex)
                } else if (act === "back") {
                    consoleWindow.overlayOpen = false
                }
            } else {
                if (act === "left") {
                    libraryGrid.moveCurrentIndexLeft()
                } else if (act === "right") {
                    libraryGrid.moveCurrentIndexRight()
                } else if (act === "up") {
                    libraryGrid.moveCurrentIndexUp()
                } else if (act === "down") {
                    libraryGrid.moveCurrentIndexDown()
                } else if (act === "accept") {
                    launchCurrentItem()
                } else if (act === "back") {
                    consoleWindow.overlayOpen = true
                }
            }
        }
    }

    function launchCurrentItem() {
        var items = consoleBackend.libraryItems
        if (libraryGrid.currentIndex >= 0 && libraryGrid.currentIndex < items.length) {
            consoleBackend.launchTarget(items[libraryGrid.currentIndex].exec)
        }
    }

    function triggerOverlayAction(idx) {
        if (idx === 0) consoleBackend.toggleTurbo()
        else if (idx === 1) consoleBackend.toggleMangohud()
        else if (idx === 2) consoleBackend.toggleCas()
        else if (idx === 3) consoleBackend.adjustVolume(10)
        else if (idx === 4) consoleBackend.exitToDesktop()
    }

    Item {
        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Tab || event.key === Qt.Key_F1) {
                consoleWindow.overlayOpen = !consoleWindow.overlayOpen
                event.accepted = true
            } else if (consoleWindow.overlayOpen) {
                if (event.key === Qt.Key_Up) {
                    consoleWindow.overlayIndex = Math.max(0, consoleWindow.overlayIndex - 1)
                    event.accepted = true
                } else if (event.key === Qt.Key_Down) {
                    consoleWindow.overlayIndex = Math.min(4, consoleWindow.overlayIndex + 1)
                    event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    triggerOverlayAction(consoleWindow.overlayIndex)
                    event.accepted = true
                } else if (event.key === Qt.Key_Escape) {
                    consoleWindow.overlayOpen = false
                    event.accepted = true
                }
            } else {
                if (event.key === Qt.Key_Left) {
                    libraryGrid.moveCurrentIndexLeft()
                    event.accepted = true
                } else if (event.key === Qt.Key_Right) {
                    libraryGrid.moveCurrentIndexRight()
                    event.accepted = true
                } else if (event.key === Qt.Key_Up) {
                    libraryGrid.moveCurrentIndexUp()
                    event.accepted = true
                } else if (event.key === Qt.Key_Down) {
                    libraryGrid.moveCurrentIndexDown()
                    event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    launchCurrentItem()
                    event.accepted = true
                } else if (event.key === Qt.Key_Escape) {
                    consoleBackend.exitToDesktop()
                    event.accepted = true
                }
            }
        }

        Item {
            id: topBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 42

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                spacing: 18

                Image {
                    width: 16
                    height: 16
                    source: "file:///usr/share/icons/hicolor/512x512/apps/raytolfas-logo.png"
                    sourceSize.width: 32
                    sourceSize.height: 32
                    fillMode: Image.PreserveAspectFit
                }

                Repeater {
                    model: ["All", "Games", "Apps"]
                    delegate: Item {
                        width: tabLabel.implicitWidth + 8
                        height: 42
                        property bool active: consoleBackend.currentCategory === modelData

                        Text {
                            id: tabLabel
                            anchors.centerIn: parent
                            text: modelData
                            color: parent.active ? "#f1f5f9" : "#64748b"
                            font.pixelSize: 13
                            font.bold: parent.active
                            font.family: "Noto Sans"
                        }

                        Rectangle {
                            visible: parent.active
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: tabLabel.implicitWidth
                            height: 2
                            radius: 1
                            color: "#f1f5f9"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                consoleBackend.setCategory(modelData)
                                libraryGrid.currentIndex = 0
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Row {
                    visible: consoleBackend.turboActive
                    spacing: 5
                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: "#10b981"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Turbo"
                        color: "#10b981"
                        font.pixelSize: 11
                        font.family: "Noto Sans"
                    }
                }

                Text {
                    text: consoleBackend.batteryPct + "%"
                    color: "#94a3b8"
                    font.pixelSize: 12
                    font.family: "Noto Sans"
                }

                Text {
                    text: consoleBackend.timeStr
                    color: "#e2e8f0"
                    font.pixelSize: 12
                    font.bold: true
                    font.family: "Noto Sans"
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: "#14ffffff"
            }
        }

        GridView {
            id: libraryGrid
            anchors.top: topBar.bottom
            anchors.bottom: bottomBar.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 24
            cellWidth: 152
            cellHeight: 138
            clip: true
            model: consoleBackend.libraryItems
            currentIndex: 0

            delegate: Item {
                id: tileDelegate
                width: libraryGrid.cellWidth
                height: libraryGrid.cellHeight
                property bool isFocused: GridView.isCurrentItem

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: 8
                    color: tileDelegate.isFocused ? "#1d2432" : "#11151d"
                    border.color: tileDelegate.isFocused ? "#99ffffff" : "#16ffffff"
                    border.width: 1

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 16
                        spacing: 10

                        Item {
                            width: 38
                            height: 38
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
                                radius: 8
                                color: "#1cffffff"
                                visible: modelData.icon === ""

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.letter
                                    color: "#cbd5e1"
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
                            color: tileDelegate.isFocused ? "#ffffff" : "#cbd5e1"
                            font.pixelSize: 12
                            font.family: "Noto Sans"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: libraryGrid.currentIndex = index
                        onClicked: {
                            libraryGrid.currentIndex = index
                            consoleBackend.launchTarget(modelData.exec)
                        }
                    }
                }
            }
        }

        Item {
            id: bottomBar
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 34

            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: "#14ffffff"
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                spacing: 16

                Text {
                    text: "Enter / A  Launch    ·    Tab / Guide  Quick Menu    ·    Esc  Desktop"
                    color: "#64748b"
                    font.pixelSize: 11
                    font.family: "Noto Sans"
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 58
                    height: 22
                    radius: 5
                    color: menuBtn.containsMouse ? "#22ffffff" : "#12ffffff"

                    Text {
                        anchors.centerIn: parent
                        text: "Menu"
                        color: "#cbd5e1"
                        font.pixelSize: 11
                        font.family: "Noto Sans"
                    }

                    MouseArea {
                        id: menuBtn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: consoleWindow.overlayOpen = !consoleWindow.overlayOpen
                    }
                }

                Rectangle {
                    width: 64
                    height: 22
                    radius: 5
                    color: exitBtn.containsMouse ? "#28ef4444" : "#14ef4444"

                    Text {
                        anchors.centerIn: parent
                        text: "Desktop"
                        color: "#fca5a5"
                        font.pixelSize: 11
                        font.family: "Noto Sans"
                    }

                    MouseArea {
                        id: exitBtn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: consoleBackend.exitToDesktop()
                    }
                }
            }
        }

        Rectangle {
            id: quickOverlay
            z: 40
            visible: consoleWindow.overlayOpen
            anchors.top: topBar.bottom
            anchors.right: parent.right
            anchors.margins: 12
            width: 248
            height: overlayCol.implicitHeight + 20
            radius: 8
            color: "#f211151d"
            border.color: "#24ffffff"
            border.width: 1

            Column {
                id: overlayCol
                anchors.fill: parent
                anchors.margins: 10
                spacing: 2

                Text {
                    text: "Quick Settings"
                    color: "#94a3b8"
                    font.pixelSize: 11
                    font.bold: true
                    leftPadding: 8
                    bottomPadding: 4
                    font.family: "Noto Sans"
                }

                Repeater {
                    model: [
                        { title: "Turbo Mode", value: consoleBackend.turboActive ? "On" : "Off", active: consoleBackend.turboActive },
                        { title: "MangoHUD", value: consoleBackend.mangohudEnabled ? "On" : "Off", active: consoleBackend.mangohudEnabled },
                        { title: "CAS Sharpening", value: consoleBackend.casEnabled ? "On" : "Off", active: consoleBackend.casEnabled },
                        { title: "Volume", value: consoleBackend.volumeLevel + "%", active: false },
                        { title: "Return to Desktop", value: "", active: false }
                    ]

                    delegate: Rectangle {
                        width: overlayCol.width
                        height: 32
                        radius: 5
                        color: consoleWindow.overlayIndex === index ? "#1effffff" : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8

                            Text {
                                text: modelData.title
                                color: "#f1f5f9"
                                font.pixelSize: 12
                                font.family: "Noto Sans"
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                visible: modelData.value !== ""
                                text: modelData.value
                                color: modelData.active ? "#10b981" : "#64748b"
                                font.pixelSize: 11
                                font.bold: modelData.active
                                font.family: "Noto Sans"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: consoleWindow.overlayIndex = index
                            onClicked: {
                                consoleWindow.overlayIndex = index
                                triggerOverlayAction(index)
                            }
                        }
                    }
                }
            }
        }
    }
}
