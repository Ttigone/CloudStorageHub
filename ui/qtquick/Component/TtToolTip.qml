import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

ToolTip {
    id: root

    // 样式属性
    property color backgroundColor: "#1E293B"
    property color textColor: "#FFFFFF"
    property real cornerRadius: 6
    property bool showArrow: true
    property string arrowPosition: "auto" // "auto", "top", "bottom", "left", "right"

    padding: 8

    // 内部属性
    readonly property string actualArrowPosition: {
        if (arrowPosition === "auto") {
            // 根据工具提示相对于目标的位置推断箭头位置
            var yPosition = root.y
            var targetItem = root.parent
            if (!targetItem)
                return "top"

            if (yPosition > targetItem.y + targetItem.height) {
                return "top" // 显示在下方，箭头指向上方
            } else if (yPosition + root.height < targetItem.y) {
                return "bottom" // 显示在上方，箭头指向下方
            } else if (root.x > targetItem.x + targetItem.width) {
                return "left" // 显示在右侧，箭头指向左侧
            } else {
                return "right" // 显示在左侧，箭头指向右侧
            }
        }
        return arrowPosition
    }

    // 延迟显示
    delay: 500

    // 完全自定义外观
    contentItem: Text {
        text: root.text
        font.pixelSize: 12
        color: root.textColor
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
    }

    background: Item {
        // 主背景
        Rectangle {
            id: tooltipBackground
            anchors.fill: parent
            color: root.backgroundColor
            radius: root.cornerRadius

            // 阴影效果
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 2
                radius: 8
                samples: 17
                color: "#40000000"
            }
        }

        // 箭头指示器 - 只在showArrow为true时显示
        Canvas {
            id: arrow
            visible: root.showArrow

            // 箭头大小
            width: 12
            height: 6

            // 箭头位置和旋转根据方向自动调整
            states: [
                State {
                    name: "top"
                    when: root.actualArrowPosition === "top"
                    PropertyChanges {
                        target: arrow
                        x: (parent.width - width) / 2
                        y: -height + 1
                        rotation: 0
                    }
                },
                State {
                    name: "bottom"
                    when: root.actualArrowPosition === "bottom"
                    PropertyChanges {
                        target: arrow
                        x: (parent.width - width) / 2
                        y: parent.height - 1
                        rotation: 180
                    }
                },
                State {
                    name: "left"
                    when: root.actualArrowPosition === "left"
                    PropertyChanges {
                        target: arrow
                        x: -height + 1
                        y: (parent.height - width) / 2
                        width: 6
                        height: 12
                        rotation: 270
                    }
                },
                State {
                    name: "right"
                    when: root.actualArrowPosition === "right"
                    PropertyChanges {
                        target: arrow
                        x: parent.width - 1
                        y: (parent.height - width) / 2
                        width: 6
                        height: 12
                        rotation: 90
                    }
                }
            ]

            // 绘制箭头
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                ctx.fillStyle = root.backgroundColor

                // 绘制三角形
                ctx.beginPath()
                if (actualArrowPosition === "left"
                        || actualArrowPosition === "right") {
                    // 水平箭头
                    ctx.moveTo(0, height / 2)
                    ctx.lineTo(width, 0)
                    ctx.lineTo(width, height)
                } else {
                    // 垂直箭头
                    ctx.moveTo(width / 2, 0)
                    ctx.lineTo(0, height)
                    ctx.lineTo(width, height)
                }
                ctx.closePath()
                ctx.fill()

                // 可选：添加高光效果
                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.3)
                ctx.lineWidth = 1
                ctx.beginPath()
                if (actualArrowPosition === "left"
                        || actualArrowPosition === "right") {
                    ctx.moveTo(0, height / 2)
                    ctx.lineTo(width, 0)
                } else {
                    ctx.moveTo(width / 2, 0)
                    ctx.lineTo(0, height)
                }
                ctx.stroke()
            }
        }
    }

    // 平滑的出现/消失动画
    enter: Transition {
        NumberAnimation {
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 200
            easing.type: Easing.OutQuad
        }
    }

    exit: Transition {
        NumberAnimation {
            property: "opacity"
            from: 1.0
            to: 0.0
            duration: 150
            easing.type: Easing.InQuad
        }
    }
}
