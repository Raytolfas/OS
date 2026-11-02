import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: spotWin
    width: 480
    readonly property int rowCount: Math.min(6, spotlight.results.length)
    height: rowCount > 0 ? (42 + rowCount * 32 + 10) : 42
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    visible: true
    title: "Spotlight"
    color: "transparent"

    Component.onCompleted: {
        x = Math.round((Screen.width - width) / 2)
        y = Math.round(Screen.height * 0.24)
        searchInput.forceActiveFocus()
    }

    onActiveChanged: {
        if (!active) {
            spotlight.closeSpotlight()
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: "#ee11141a"
        border.color: "#22ffffff"
        border.width: 1

        Column {
            anchors.fill: parent

            Item {
                width: parent.width
                height: 42

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Canvas {
                        width: 14
                        height: 14
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            ctx.strokeStyle = "#8b95a5"
                            ctx.lineWidth = 1.5
                            ctx.beginPath()
                            ctx.arc(6, 6, 4.5, 0, Math.PI * 2)
                            ctx.stroke()
                            ctx.beginPath()
                            ctx.moveTo(9.5, 9.5)
                            ctx.lineTo(13, 13)
                            ctx.stroke()
                        }
                    }

                    TextField {
                        id: searchInput
                        Layout.fillWidth: true
                        placeholderText: "Search apps, math, or > command..."
                        placeholderTextColor: "#64748b"
                        color: "#f1f5f9"
                        font.pixelSize: 13
                        font.family: "Noto Sans"
                        leftPadding: 2
                        rightPadding: 2
                        topPadding: 0
                        bottomPadding: 0
                        background: Item {}
                        onTextChanged: {
                            spotlight.search(text)
                            resultsList.currentIndex = 0
                        }
                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Down) {
                                resultsList.incrementCurrentIndex()
                                event.accepted = true
                            } else if (event.key === Qt.Key_Up) {
                                resultsList.decrementCurrentIndex()
                                event.accepted = true
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                var items = spotlight.results
                                if (resultsList.currentIndex >= 0 && resultsList.currentIndex < items.length) {
                                    spotlight.execute(items[resultsList.currentIndex].cmd)
                                }
                                event.accepted = true
                            } else if (event.key === Qt.Key_Escape) {
                                spotlight.closeSpotlight()
                                event.accepted = true
                            }
                        }
                    }
                }
            }

            Rectangle {
                visible: spotWin.rowCount > 0
                width: parent.width
                height: 1
                color: "#16ffffff"
            }

            ListView {
                id: resultsList
                visible: spotWin.rowCount > 0
                width: parent.width - 8
                height: spotWin.rowCount * 32
                anchors.horizontalCenter: parent.horizontalCenter
                topMargin: 4
                clip: true
                spacing: 0
                model: spotlight.results
                currentIndex: 0

                delegate: Rectangle {
                    width: ListView.view.width
                    height: 32
                    radius: 5
                    property bool isSelected: ListView.isCurrentItem
                    color: isSelected ? "#1cffffff" : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 10
                        spacing: 8

                        Item {
                            width: 16
                            height: 16

                            Image {
                                anchors.fill: parent
                                source: modelData.icon
                                sourceSize.width: 16
                                sourceSize.height: 16
                                visible: modelData.icon !== ""
                                fillMode: Image.PreserveAspectFit
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: 6
                                height: 6
                                radius: 3
                                color: "#94a3b8"
                                visible: modelData.icon === ""
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.name
                            color: "#f1f5f9"
                            font.pixelSize: 13
                            elide: Text.ElideRight
                            font.family: "Noto Sans"
                        }

                        Text {
                            text: modelData.sub
                            color: "#64748b"
                            font.pixelSize: 11
                            font.family: "Noto Sans"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: resultsList.currentIndex = index
                        onClicked: spotlight.execute(modelData.cmd)
                    }
                }
            }
        }
    }
}
