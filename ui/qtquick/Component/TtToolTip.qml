// import QtQuick
// import QtQuick.Controls
// import QtQuick.Layouts
// import Qt5Compat.GraphicalEffects

// ToolTip {
//     id: root

//     // 样式属性
//     property color backgroundColor: "#1E293B"
//     property color textColor: "#FFFFFF"
//     property real cornerRadius: 6
//     property bool showArrow: true
//     property string arrowPosition: "auto" // "auto", "top", "bottom", "left", "right"

//     property real arrowSize: 8 // 箭头大小
//     property color arrowColor: backgroundColor // 箭头颜色，默认与背景色一致

//     padding: 8

//     // 内部属性
//     readonly property string actualArrowPosition: {
//         if (arrowPosition === "auto") {
//             // 根据工具提示相对于目标的位置推断箭头位置
//             var yPosition = root.y
//             var targetItem = root.parent
//             if (!targetItem)
//                 return "top"

//             if (yPosition > targetItem.y + targetItem.height) {
//                 return "top" // 显示在下方，箭头指向上方
//             } else if (yPosition + root.height < targetItem.y) {
//                 return "bottom" // 显示在上方，箭头指向下方
//             } else if (root.x > targetItem.x + targetItem.width) {
//                 return "left" // 显示在右侧，箭头指向左侧
//             } else {
//                 return "right" // 显示在左侧，箭头指向右侧
//             }
//         }
//         return arrowPosition
//     }

//     // 延迟显示
//     delay: 500

//     // 完全自定义外观
//     contentItem: Text {
//         text: root.text
//         font.pixelSize: 12
//         color: root.textColor
//         wrapMode: Text.WordWrap
//         horizontalAlignment: Text.AlignHCenter
//     }

//     background: Item {
//         // 主背景
//         Rectangle {
//             id: tooltipBackground
//             anchors.fill: parent
//             color: root.backgroundColor
//             radius: root.cornerRadius

//             // 阴影效果
//             layer.enabled: true
//             layer.effect: DropShadow {
//                 horizontalOffset: 0
//                 verticalOffset: 2
//                 radius: 8
//                 samples: 17
//                 color: "#40000000"
//             }
//         }

//         Canvas {
//             id: arrow
//             visible: root.showArrow

//             // 动态设置箭头大小
//             width: root.arrowSize * 1.5
//             height: root.arrowSize

//             // 启用抗锯齿
//             antialiasing: true
//             smooth: true

//             // 箭头位置和旋转根据方向自动调整
//             states: [
//                 State {
//                     name: "top"
//                     when: root.actualArrowPosition === "top"
//                     PropertyChanges {
//                         target: arrow
//                         x: (parent.width - width) / 2
//                         y: -height + 2
//                         rotation: 0
//                     }
//                 },
//                 State {
//                     name: "bottom"
//                     when: root.actualArrowPosition === "bottom"
//                     PropertyChanges {
//                         target: arrow
//                         x: (parent.width - width) / 2
//                         y: parent.height - 2
//                         rotation: 180
//                     }
//                 },
//                 State {
//                     name: "left"
//                     when: root.actualArrowPosition === "left"
//                     PropertyChanges {
//                         target: arrow
//                         x: -height + 2
//                         y: (parent.height - width) / 2
//                         width: root.arrowSize
//                         height: root.arrowSize * 1.5
//                         rotation: 270
//                     }
//                 },
//                 State {
//                     name: "right"
//                     when: root.actualArrowPosition === "right"
//                     PropertyChanges {
//                         target: arrow
//                         x: parent.width - 2
//                         y: (parent.height - width) / 2
//                         width: root.arrowSize
//                         height: root.arrowSize * 1.5
//                         rotation: 90
//                     }
//                 }
//             ]

//             // 修复后的绘制方法
//             onPaint: {
//                 var ctx = getContext("2d")
//                 ctx.reset()

//                 // 启用抗锯齿
//                 ctx.antialias = true
//                 ctx.smooth = true

//                 // 设置填充颜色
//                 ctx.fillStyle = root.arrowColor

//                 // 绘制更精确的三角形
//                 ctx.beginPath()

//                 if (root.actualArrowPosition === "left"
//                         || root.actualArrowPosition === "right") {
//                     // 水平箭头 (更精确的坐标)
//                     ctx.moveTo(0, height / 2) // 箭头尖端
//                     ctx.lineTo(width - 0.5, 0.5) // 上角
//                     ctx.lineTo(width - 0.5, height - 0.5) // 下角
//                 } else {
//                     // 垂直箭头 (更精确的坐标)
//                     ctx.moveTo(width / 2, 0) // 箭头尖端
//                     ctx.lineTo(0.5, height - 0.5) // 左角
//                     ctx.lineTo(width - 0.5, height - 0.5) // 右角
//                 }

//                 ctx.closePath()
//                 ctx.fill()

//                 // 添加微妙的边框以增强视觉效果
//                 ctx.strokeStyle = Qt.rgba(0, 0, 0, 0.1)
//                 ctx.lineWidth = 0.5
//                 ctx.stroke()
//             }

//             // 修复：使用 Connections 来监听属性变化
//             Connections {
//                 target: root
//                 function onArrowPositionChanged() {
//                     arrow.requestPaint()
//                 }
//                 function onArrowColorChanged() {
//                     arrow.requestPaint()
//                 }
//                 function onArrowSizeChanged() {
//                     arrow.requestPaint()
//                 }
//             }

//             // 组件完成时绘制
//             Component.onCompleted: requestPaint()

//             // 监听尺寸变化
//             onWidthChanged: requestPaint()
//             onHeightChanged: requestPaint()
//         }

//         // 备用方案：使用 Polygon 形状（如果 Canvas 还有问题）
//         Item {
//             id: alternativeArrow
//             visible: false // 默认使用 Canvas，如需要可以切换

//             // 使用旋转的矩形组合成箭头
//             Rectangle {
//                 width: root.arrowSize
//                 height: root.arrowSize
//                 color: root.arrowColor
//                 rotation: 45
//                 antialiasing: true
//                 smooth: true

//                 anchors.centerIn: parent

//                 // 裁剪成三角形形状
//                 Rectangle {
//                     width: parent.width * 0.7
//                     height: parent.height * 0.7
//                     color: "transparent"
//                     anchors.right: parent.right
//                     anchors.bottom: parent.bottom
//                 }
//             }
//         }
//     }

//     // 平滑的出现/消失动画
//     enter: Transition {
//         NumberAnimation {
//             property: "opacity"
//             from: 0.0
//             to: 1.0
//             duration: 200
//             easing.type: Easing.OutQuad
//         }
//     }

//     exit: Transition {
//         NumberAnimation {
//             property: "opacity"
//             from: 1.0
//             to: 0.0
//             duration: 150
//             easing.type: Easing.InQuad
//         }
//     }
// }
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
    property real arrowSize: 8
    property color arrowColor: backgroundColor

    padding: 8

    // 获取目标控件的函数
    function getTargetItem() {
        // 寻找触发 ToolTip 的控件
        var current = root.parent
        while (current) {
            // 检查是否有 ToolTip 相关的属性
            if (current.hasOwnProperty("ToolTip") || 
                current.objectName === "tooltipTarget" ||
                current === root.parent) {
                return current
            }
            current = current.parent
        }
        return root.parent
    }

    // 计算箭头的实际位置（相对于目标控件中心）
    property real arrowOffset: {
        var targetItem = getTargetItem()
        if (!targetItem) return 0

        try {
            // 使用相对坐标计算，避免使用 mapToGlobal
            var targetCenterX = targetItem.x + targetItem.width / 2
            var targetCenterY = targetItem.y + targetItem.height / 2
            
            // ToolTip 的中心位置（相对于同一父容器）
            var tooltipCenterX = root.x + root.width / 2
            var tooltipCenterY = root.y + root.height / 2
            
            if (actualArrowPosition === "top" || actualArrowPosition === "bottom") {
                // 垂直箭头：计算水平偏移
                var offsetX = targetCenterX - tooltipCenterX
                
                // 限制偏移范围，避免箭头跑到 ToolTip 边界外
                var maxOffset = (root.width - root.arrowSize * 1.5) / 2 - 4
                return Math.max(-maxOffset, Math.min(maxOffset, offsetX))
            } else {
                // 水平箭头：计算垂直偏移
                var offsetY = targetCenterY - tooltipCenterY
                
                // 限制偏移范围
                var maxOffset = (root.height - root.arrowSize * 1.5) / 2 - 4
                return Math.max(-maxOffset, Math.min(maxOffset, offsetY))
            }
        } catch (e) {
            console.log("Arrow offset calculation error:", e)
            return 0
        }
    }

    // 改进的箭头位置计算 - 使用相对位置
    property string actualArrowPosition: {
        var targetItem = getTargetItem()
        if (!targetItem) return "top"

        if (arrowPosition !== "auto") {
            return arrowPosition
        }

        try {
            // 使用相对坐标而不是全局坐标
            var targetCenterX = targetItem.x + targetItem.width / 2
            var targetCenterY = targetItem.y + targetItem.height / 2
            var tooltipCenterX = root.x + root.width / 2
            var tooltipCenterY = root.y + root.height / 2

            // 计算相对位置
            var deltaX = tooltipCenterX - targetCenterX
            var deltaY = tooltipCenterY - targetCenterY
            
            // 根据距离和角度确定箭头方向
            if (Math.abs(deltaX) > Math.abs(deltaY)) {
                // 水平方向距离更大
                return deltaX > 0 ? "left" : "right"
            } else {
                // 垂直方向距离更大
                return deltaY > 0 ? "top" : "bottom"
            }
        } catch (e) {
            console.log("Arrow position calculation error:", e)
            return "top"
        }
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

        // 改进的箭头指示器
        Canvas {
            id: arrow
            visible: root.showArrow

            // 动态设置箭头大小
            width: root.arrowSize * 1.5
            height: root.arrowSize

            // 启用抗锯齿
            antialiasing: true
            smooth: true

            // 箭头位置根据计算的偏移量调整
            states: [
                State {
                    name: "top"
                    when: root.actualArrowPosition === "top"
                    PropertyChanges {
                        target: arrow
                        x: (parent.width - width) / 2 + root.arrowOffset
                        y: -height + 2
                        rotation: 0
                    }
                },
                State {
                    name: "bottom"
                    when: root.actualArrowPosition === "bottom"
                    PropertyChanges {
                        target: arrow
                        x: (parent.width - width) / 2 + root.arrowOffset
                        y: parent.height - 2
                        rotation: 180
                    }
                },
                State {
                    name: "left"
                    when: root.actualArrowPosition === "left"
                    PropertyChanges {
                        target: arrow
                        x: -height + 2
                        y: (parent.height - width) / 2 + root.arrowOffset
                        width: root.arrowSize
                        height: root.arrowSize * 1.5
                        rotation: 270
                    }
                },
                State {
                    name: "right"
                    when: root.actualArrowPosition === "right"
                    PropertyChanges {
                        target: arrow
                        x: parent.width - 2
                        y: (parent.height - width) / 2 + root.arrowOffset
                        width: root.arrowSize
                        height: root.arrowSize * 1.5
                        rotation: 90
                    }
                }
            ]

            // 绘制方法
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()

                // 启用抗锯齿
                ctx.antialias = true
                ctx.smooth = true

                // 设置填充颜色
                ctx.fillStyle = root.arrowColor

                // 绘制精确的三角形
                ctx.beginPath()

                if (root.actualArrowPosition === "left" || root.actualArrowPosition === "right") {
                    // 水平箭头
                    ctx.moveTo(0, height / 2)
                    ctx.lineTo(width - 0.5, 0.5)
                    ctx.lineTo(width - 0.5, height - 0.5)
                } else {
                    // 垂直箭头
                    ctx.moveTo(width / 2, 0)
                    ctx.lineTo(0.5, height - 0.5)
                    ctx.lineTo(width - 0.5, height - 0.5)
                }

                ctx.closePath()
                ctx.fill()

                // 添加边框
                ctx.strokeStyle = Qt.rgba(0, 0, 0, 0.1)
                ctx.lineWidth = 0.5
                ctx.stroke()
            }

            // 监听属性变化，重新绘制
            Connections {
                target: root
                function onArrowPositionChanged() {
                    arrow.requestPaint()
                }
                function onArrowColorChanged() {
                    arrow.requestPaint()
                }
                function onArrowSizeChanged() {
                    arrow.requestPaint()
                }
                function onActualArrowPositionChanged() {
                    arrow.requestPaint()
                }
            }

            // 组件完成时绘制
            Component.onCompleted: requestPaint()

            // 监听尺寸变化
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
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