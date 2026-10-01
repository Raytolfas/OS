import QtQuick
import QtQuick.Controls

ApplicationWindow {
    id: root
    width: 780
    height: 500
    visible: true
    title: "Raytolfas OS Welcome"
    color: "#080c14"
    flags: Qt.Window | Qt.FramelessWindowHint

    MouseArea {
        anchors.fill: parent
        property point lastMousePos: Qt.point(0, 0)
        onPressed: (mouse) => { lastMousePos = Qt.point(mouse.x, mouse.y) }
        onPositionChanged: (mouse) => {
            if (pressedButtons & Qt.LeftButton) {
                var dx = mouse.x - lastMousePos.x
                var dy = mouse.y - lastMousePos.y
                root.x += dx
                root.y += dy
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: "#1e293b"
        border.width: 1
        radius: 16
        z: 10
    }

    Item {
        anchors.fill: parent
        clip: true

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: -100
            width: 600
            height: 400
            radius: 300
            color: "#0078D4"
            opacity: 0.15
        }

        Canvas {
            id: waveCanvas
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 240
            property real step: 0

            Timer {
                interval: 20
                running: true
                repeat: true
                onTriggered: {
                    waveCanvas.step += 0.035
                    waveCanvas.requestPaint()
                }
            }

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                ctx.beginPath()
                ctx.moveTo(0, height)
                for (var x = 0; x <= width; x += 6) {
                    var y1 = Math.sin(x * 0.015 + step) * 22 + Math.cos(x * 0.025 + step * 0.7) * 14 + 110
                    ctx.lineTo(x, y1)
                }
                ctx.lineTo(width, height)
                ctx.closePath()

                var grad1 = ctx.createLinearGradient(0, 60, 0, height)
                grad1.addColorStop(0, "rgba(0, 120, 212, 0.25)")
                grad1.addColorStop(1, "rgba(2, 28, 56, 0.70)")
                ctx.fillStyle = grad1
                ctx.fill()

                ctx.beginPath()
                ctx.moveTo(0, height)
                for (var x2 = 0; x2 <= width; x2 += 6) {
                    var y2 = Math.sin(x2 * 0.02 + step * 1.3) * 18 + Math.cos(x2 * 0.01 + step * 0.9) * 12 + 135
                    ctx.lineTo(x2, y2)
                }
                ctx.lineTo(width, height)
                ctx.closePath()

                var grad2 = ctx.createLinearGradient(0, 80, 0, height)
                grad2.addColorStop(0, "rgba(0, 200, 255, 0.45)")
                grad2.addColorStop(0.5, "rgba(0, 120, 212, 0.50)")
                grad2.addColorStop(1, "rgba(8, 12, 20, 0.90)")
                ctx.fillStyle = grad2
                ctx.fill()
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 14
            width: 28
            height: 28
            radius: 14
            color: closeMouse.containsMouse ? "#334155" : "transparent"
            z: 20

            Text {
                anchors.centerIn: parent
                text: "\u2715"
                color: closeMouse.containsMouse ? "#ffffff" : "#94a3b8"
                font.pixelSize: 13
            }
            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    backend.finish_welcome()
                    root.close()
                }
            }
        }

        Column {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -20
            spacing: 16
            z: 15

            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 96
                height: 96
                source: "file:///usr/share/icons/hicolor/512x512/apps/raytolfas-logo.png"
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Raytolfas OS D1"
                color: "#ffffff"
                font.pixelSize: 32
                font.bold: true
                font.family: "Noto Sans"
            }

            Item { width: 1; height: 16 }

            Rectangle {
                id: startBtn
                anchors.horizontalCenter: parent.horizontalCenter
                width: 190
                height: 46
                radius: 23
                color: startMouse.containsMouse ? "#1084d8" : "#0078D4"
                scale: startMouse.pressed ? 0.96 : (startMouse.containsMouse ? 1.03 : 1.0)

                Behavior on scale { NumberAnimation { duration: 120 } }
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "Start"
                    color: "#ffffff"
                    font.pixelSize: 16
                    font.bold: true
                    font.family: "Noto Sans"
                }

                MouseArea {
                    id: startMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        backend.finish_welcome()
                        root.close()
                    }
                }
            }
        }
    }
}
