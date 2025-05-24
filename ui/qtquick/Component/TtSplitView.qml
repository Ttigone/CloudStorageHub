import QtQuick
import QtQuick.Controls

SplitView {
    id: root
    property alias splitOrientation: root.orientation
    orientation: Qt.Horizontal
    // 添加自定义 handle 代理
    handle: Rectangle {
        id: handleItem
        implicitWidth: root.orientation === Qt.Horizontal ? 8 : root.width
        implicitHeight: root.orientation === Qt.Vertical ? 8 : root.height
        color: "transparent" // 透明背景
        property bool hovering: SplitHandle.hovered

        Item {
            anchors.centerIn: parent
            width: root.orientation === Qt.Horizontal ? 6 : 36
            height: root.orientation === Qt.Horizontal ? 36 : 6
            visible: handleItem.hovering || SplitHandle.pressed

            Rectangle {
                width: root.orientation === Qt.Horizontal ? 2 : parent.width
                height: root.orientation === Qt.Horizontal ? parent.height : 2

                // 正确处理锚点 - 使用三元运算符整体控制锚点
                anchors {
                    left: root.orientation === Qt.Horizontal ? parent.left : undefined
                    top: root.orientation === Qt.Vertical ? parent.top : undefined
                    verticalCenter: root.orientation
                                    === Qt.Horizontal ? parent.verticalCenter : undefined
                    horizontalCenter: root.orientation
                                      === Qt.Vertical ? parent.horizontalCenter : undefined
                }

                color: "#3498DB"
                opacity: 0.8
                radius: 1
            }

            Rectangle {
                width: root.orientation === Qt.Horizontal ? 2 : parent.width
                height: root.orientation === Qt.Horizontal ? parent.height : 2

                // 正确处理锚点
                anchors {
                    right: root.orientation === Qt.Horizontal ? parent.right : undefined
                    bottom: root.orientation === Qt.Vertical ? parent.bottom : undefined
                    verticalCenter: root.orientation
                                    === Qt.Horizontal ? parent.verticalCenter : undefined
                    horizontalCenter: root.orientation
                                      === Qt.Vertical ? parent.horizontalCenter : undefined
                }

                color: "#3498DB"
                opacity: 0.8
                radius: 1
            }
        }

        // 普通状态下的简单分隔线
        Rectangle {
            visible: !(handleItem.hovering || SplitHandle.pressed)
            width: root.orientation === Qt.Horizontal ? 1 : parent.width
            height: root.orientation === Qt.Horizontal ? parent.height : 1
            anchors.centerIn: parent
            color: "#DDDDDD"
        }

        // 添加动画效果
        states: [
            State {
                name: "hovered"
                when: handleItem.hovering && !SplitHandle.pressed
                PropertyChanges {
                    target: handleItem
                    implicitWidth: root.orientation === Qt.Horizontal ? 10 : root.width
                    implicitHeight: root.orientation === Qt.Vertical ? 10 : root.height
                }
            },
            State {
                name: "pressed"
                when: SplitHandle.pressed
                PropertyChanges {
                    target: handleItem
                    implicitWidth: root.orientation === Qt.Horizontal ? 10 : root.width
                    implicitHeight: root.orientation === Qt.Vertical ? 10 : root.height
                }
            }
        ]

        transitions: Transition {
            NumberAnimation {
                properties: "implicitWidth,implicitHeight"
                duration: 100
                easing.type: Easing.OutQuad
            }
        }

        // 鼠标经过时显示不同光标
        MouseArea {
            anchors.fill: parent
            anchors.margins: -4 // 增大点击区域
            cursorShape: root.orientation === Qt.Horizontal ? Qt.SplitHCursor : Qt.SplitVCursor
            enabled: false // 不处理事件，只改变光标
        }

        // 触摸区域指示器 - 仅在鼠标悬停时显示
        Rectangle {
            anchors.fill: parent
            color: "#3498DB"
            opacity: 0.1
            visible: handleItem.hovering || SplitHandle.pressed
        }
    }
}
