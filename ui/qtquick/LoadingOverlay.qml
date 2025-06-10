import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root

    property string message: "加载中..."
    property bool active: false

    // 通过opacity控制显示/隐藏，保持动画连续性
    opacity: active ? 1.0 : 0.0
    visible: opacity > 0

    color: "#99000000" // 半透明黑色背景

    Behavior on opacity {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    MouseArea {
        anchors.fill: parent
        // 拦截所有鼠标事件，防止用户点击下层控件
        enabled: root.active
        // cursorShape: Qt.SizeAllCursor // 这里似乎失效了, 没有显示
        onClicked: {

            // console.log("测试")
        }
        onPressed: {

            // console.log("测试")
        }
        onReleased: {

            // console.log("测试")
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 20

        // 现代化的旋转加载动画
        Item {
            Layout.alignment: Qt.AlignHCenter
            width: 60
            height: 60

            Rectangle {
                id: spinnerTrack
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: 4
                border.color: "#22FFFFFF"
            }

            ConicalGradient {
                anchors.fill: parent
                angle: 0

                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: "#0088FF"
                    }
                    GradientStop {
                        position: 0.5
                        color: "#80FFFFFF"
                    }
                    GradientStop {
                        position: 1.0
                        color: "#0088FF"
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    radius: width / 2
                    border.width: 4
                    border.color: "transparent"

                    // 圆形遮罩
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: spinnerTrack.width
                            height: spinnerTrack.height
                            radius: width / 2
                        }
                    }
                }

                RotationAnimation on rotation {
                    from: 0
                    to: 360
                    duration: 1500
                    loops: Animation.Infinite
                    running: root.active
                }
            }
        }

        // 加载文本
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.message
            color: "#FFFFFF"
            font.pixelSize: 16
            font.weight: Font.Medium
        }
    }
}
