import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Dialog {
    id: messageDialog

    property var parentWindow: null

    // 🔥 添加兼容 QtQuick.Dialogs.MessageDialog 的属性
    property string message: ""
    property alias text: messageDialog.message // 兼容 text 属性
    property int buttons: 0 // 兼容 buttons 属性，但在自定义实现中不使用

    property bool showDeleteButton: false
    property bool showOpenFolderButton: false

    signal deleteRequested
    signal openFolderRequested
    signal cancelled

    modal: true
    title: "提示"

    width: 450
    height: Math.min(300, contentHeight + 200)

    function show() {
        open()
    }

    signal accepted
    signal rejected

    background: Rectangle {
        color: "#FFFFFF"
        radius: 12
        border.width: 1
        border.color: "#E0E6ED"

        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 8
            radius: 24
            samples: 49
            color: "#40000000"
            transparentBorder: true
        }

        // 添加微妙的渐变
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: "#FFFFFF"
            }
            GradientStop {
                position: 1.0
                color: "#FAFBFC"
            }
        }
    }

    header: Item {
        height: 40

        Rectangle {
            anchors.fill: parent
            color: "#F8F9FA"
            radius: 12

            // 只保留顶部圆角
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 12
                color: "#F8F9FA"
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            // 🔥 警告图标
            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: "#FFF3CD"
                border.width: 2
                border.color: "#F0AD4E"

                Text {
                    anchors.centerIn: parent
                    text: "⚠️"
                    font.pixelSize: 16
                }
            }

            // 标题文本
            Text {
                Layout.fillWidth: true
                text: messageDialog.title
                font.pixelSize: 18
                font.weight: Font.Medium
                color: "#2C3E50"
            }
        }
    }

    contentItem: Rectangle {
        color: "transparent"

        ScrollView {
            id: scrollView
            anchors.fill: parent
            anchors.margins: 2

            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AlwaysOn

            ScrollBar.vertical.background: Rectangle {
                implicitWidth: 8
                color: "#F0F1F2"
                radius: 4
            }

            ScrollBar.vertical.contentItem: Rectangle {
                implicitWidth: 8
                radius: 4
                color: scrollView.ScrollBar.vertical.hovered ? "#BDC3C7" : "#D5DBDB"

                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }
            }

            Text {
                width: messageDialog.width - 80
                text: messageDialog.message
                wrapMode: Text.WordWrap
                color: "#34495E"
                font.pixelSize: 14
                lineHeight: 1.5
            }
        }
    }

    footer: Rectangle {
        height: 40
        color: "#F8F9FA"
        radius: 12

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 12
            color: "#F8F9FA"
        }

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: "#E9ECEF"
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 2
            spacing: 6

            Item {
                Layout.fillWidth: true
            }

            Button {
                text: "取消"
                implicitWidth: 80
                implicitHeight: 36

                background: Rectangle {
                    radius: 8
                    color: parent.hovered ? "#E9ECEF" : "#F8F9FA"
                    border.width: 1
                    border.color: parent.hovered ? "#CED4DA" : "#DEE2E6"

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
                }

                contentItem: Text {
                    text: parent.text
                    color: "#6C757D"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                  // 点击取消
                    messageDialog.cancelled()
                    messageDialog.rejected()
                    messageDialog.close()
                }

                onPressed: scale = 0.95
                onReleased: scale = 1.0

                Behavior on scale {
                    NumberAnimation {
                        duration: 100
                    }
                }
            }

            Button {
                visible: showDeleteButton
                text: "删除记录"
                implicitWidth: 90
                implicitHeight: 36

                background: Rectangle {
                    id: deleteBg
                    radius: 8
                    property color baseColor: "#E74C3C"
                    property color hoverColor: "#C0392B"
                    color: parent.hovered ? hoverColor : baseColor

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }

                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: Qt.lighter(deleteBg.color, 1.1)
                        }
                        GradientStop {
                            position: 1.0
                            color: deleteBg.color
                        }
                    }
                }
                contentItem: RowLayout {
                    spacing: 6

                    Text {
                        text: "🗑️"
                        font.pixelSize: 12
                    }

                    Text {
                        text: "删除记录"
                        color: "#FFFFFF"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }
                }
                onClicked: {
                    messageDialog.deleteRequested()
                    messageDialog.accepted()
                    messageDialog.close()
                }
                onPressed: scale = 0.95
                onReleased: scale = 1.0
                Behavior on scale {
                    NumberAnimation {
                        duration: 100
                    }
                }
            }
        }
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 300
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "scale"
                from: 0.8
                to: 1.0
                duration: 300
                easing.type: Easing.OutBack
                easing.overshoot: 1.2
            }
            NumberAnimation {
                property: "y"
                from: y - 20
                to: y
                duration: 300
                easing.type: Easing.OutCubic
            }
        }
    }

    exit: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 200
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                property: "scale"
                from: 1.0
                to: 0.9
                duration: 200
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                property: "y"
                from: y
                to: y + 10
                duration: 200
                easing.type: Easing.InCubic
            }
        }
    }

    Overlay.modal: Rectangle {
        color: "#80000000"
        opacity: messageDialog.opacity

        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }
    }

    Item {
        id: keyHandler
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: {
            messageDialog.cancelled()
            messageDialog.close()
        }

        Keys.onReturnPressed: {
            if (showDeleteButton) {
                // deleteRequested()
                messageDialog.deleteRequested()
            } else if (showOpenFolderButton) {
                // openFolderRequested()
                messageDialog.openFolderRequested()
            }
            // close()
            messageDialog.close()
        }
    }
}
