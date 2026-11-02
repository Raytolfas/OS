import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: tpWindow
    width: 340
    height: 520
    minimumWidth: 280
    minimumHeight: 400
    visible: true
    title: "Trackpad"
    color: "#0b0d12"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            spacing: 8

            Rectangle {
                width: 6
                height: 6
                radius: 3
                color: "#10b981"
            }

            Text {
                text: "Desktop Mode"
                color: "#cbd5e1"
                font.pixelSize: 12
                font.family: "Noto Sans"
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 64
                height: 24
                radius: 5
                color: kbMouse.pressed ? "#26ffffff" : "#12ffffff"
                border.color: "#1affffff"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "Keyboard"
                    color: "#cbd5e1"
                    font.pixelSize: 11
                    font.family: "Noto Sans"
                }

                MouseArea {
                    id: kbMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: tp.openVirtualKeyboard()
                }
            }

            Rectangle {
                width: 58
                height: 24
                radius: 5
                color: undockMouse.pressed ? "#38ef4444" : "#18ef4444"
                border.color: "#30ef4444"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "Undock"
                    color: "#fca5a5"
                    font.pixelSize: 11
                    font.family: "Noto Sans"
                }

                MouseArea {
                    id: undockMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: tp.exitDesktopMode()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 8
            color: "#11151d"
            border.color: padArea.pressed ? "#38ffffff" : "#18ffffff"
            border.width: 1
            clip: true

            Item {
                anchors.top: parent.top
                anchors.bottom: bottomClickBar.top
                anchors.left: parent.left
                anchors.right: scrollStrip.left

                Rectangle {
                    id: touchDot
                    width: 10
                    height: 10
                    radius: 5
                    color: "#55ffffff"
                    visible: padArea.pressed
                }

                MouseArea {
                    id: padArea
                    anchors.fill: parent
                    property real lastX: 0
                    property real lastY: 0
                    property bool moved: false

                    onPressed: function(mouse) {
                        lastX = mouse.x
                        lastY = mouse.y
                        moved = false
                        touchDot.x = mouse.x - 5
                        touchDot.y = mouse.y - 5
                    }

                    onPositionChanged: function(mouse) {
                        if (!pressed) return
                        var dx = mouse.x - lastX
                        var dy = mouse.y - lastY
                        if (Math.abs(dx) > 1.5 || Math.abs(dy) > 1.5) {
                            moved = true
                        }
                        lastX = mouse.x
                        lastY = mouse.y
                        touchDot.x = mouse.x - 5
                        touchDot.y = mouse.y - 5
                        tp.moveCursor(dx, dy)
                    }

                    onReleased: {
                        if (!moved) {
                            tp.clickButton("left")
                        }
                    }
                }
            }

            Item {
                id: scrollStrip
                anchors.top: parent.top
                anchors.bottom: bottomClickBar.top
                anchors.right: parent.right
                width: 20

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    width: 2
                    height: parent.height * 0.35
                    radius: 1
                    color: scrollArea.pressed ? "#66ffffff" : "#22ffffff"
                }

                MouseArea {
                    id: scrollArea
                    anchors.fill: parent
                    property real lastY: 0

                    onPressed: function(mouse) {
                        lastY = mouse.y
                    }

                    onPositionChanged: function(mouse) {
                        if (!pressed) return
                        var dy = mouse.y - lastY
                        if (Math.abs(dy) > 10) {
                            tp.scrollVertical(dy)
                            lastY = mouse.y
                        }
                    }
                }
            }

            Item {
                id: bottomClickBar
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 30

                Rectangle {
                    anchors.top: parent.top
                    width: parent.width
                    height: 1
                    color: "#16ffffff"
                }

                Row {
                    anchors.fill: parent

                    Rectangle {
                        width: (parent.width - 1) / 2
                        height: parent.height
                        color: leftBtn.pressed ? "#1affffff" : "transparent"

                        MouseArea {
                            id: leftBtn
                            anchors.fill: parent
                            onClicked: tp.clickButton("left")
                        }
                    }

                    Rectangle {
                        width: 1
                        height: parent.height
                        color: "#16ffffff"
                    }

                    Rectangle {
                        width: (parent.width - 1) / 2
                        height: parent.height
                        color: rightBtn.pressed ? "#1affffff" : "transparent"

                        MouseArea {
                            id: rightBtn
                            anchors.fill: parent
                            onClicked: tp.clickButton("right")
                        }
                    }
                }
            }
        }
    }
}
