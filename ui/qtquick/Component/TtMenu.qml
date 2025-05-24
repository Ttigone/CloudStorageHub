import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts

Menu {
    id: root

    enum AnimationType {
        None,
        // 无动画
        FadeInOut,
        // 淡入淡出
        SlideDown,
        // 向下滑动
        PopUp,
        // 弹出效果
        Scale,
        // 缩放效果
        Elegant
        // 综合效果
    }
    property int animationType: TtMenu.AnimationType.FadeInOut

    // 减少内边距使菜单更紧凑
    topPadding: 6
    bottomPadding: 6
    leftPadding: 1
    rightPadding: 1

    // 添加菜单背景样式
    background: Rectangle {
        implicitWidth: 200
        color: "#FFFFFF"
        radius: 6

        // 添加阴影效果
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: 3
            // radius: 8.0
            radius: 12.0
            samples: 17
            color: "#40000000"
        }

        // 添加精细边框
        Rectangle {
            anchors.fill: parent
            radius: 6
            color: "transparent"
            border.color: "#E0E0E0"
            border.width: 1
        }
    }
    // 定义属性用于动画
    // property real initialScale: 1.0
    transformOrigin: Item.TopLeft

    // 修改组件完成初始化的处理
    Component.onCompleted: {
        if (animationType === TtMenu.AnimationType.Scale
                || animationType === TtMenu.AnimationType.PopUp
                || animationType === TtMenu.AnimationType.Elegant) {
            // 直接使用 scale 属性
            root.scale = 1.0
        }
    }

    // 修改动画类型变化时的处理
    onAnimationTypeChanged: {
        if (animationType === TtMenu.AnimationType.Scale
                || animationType === TtMenu.AnimationType.PopUp
                || animationType === TtMenu.AnimationType.Elegant) {
            // 直接使用 scale 属性
            root.scale = 1.0
        } else {
            root.scale = 1.0
        }
    }

    // 定义属性用于动画
    property real initialScale: 1.0

    // 自定义菜单项样式
    delegate: MenuItem {
        id: menuItem
        implicitHeight: 36

        // 添加动画效果
        opacity: animationType === TtMenu.AnimationType.Elegant ? 0 : 1
        x: animationType === TtMenu.AnimationType.Elegant ? -5 : 0

        Component.onCompleted: {
            if (animationType === TtMenu.AnimationType.Elegant) {
                appearAnimation.start()
            }
        }

        // 出现动画序列
        SequentialAnimation {
            id: appearAnimation

            // 延迟动画 - 基于菜单项索引
            PauseAnimation {
                duration: index * 30 // 序号越大延迟越长
            }

            // 并行运行淡入和移动动画
            ParallelAnimation {
                NumberAnimation {
                    target: menuItem
                    property: "opacity"
                    to: 1.0
                    duration: 80
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: menuItem
                    property: "x"
                    to: 0
                    duration: 100
                    easing.type: Easing.OutCubic
                }
            }
        }

        // 图标和文本的内容组件
        contentItem: RowLayout {
            spacing: 8

            // 图标区域（如果提供了图标）
            Item {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                visible: menuItem.icon.source.toString() !== ""

                Image {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: menuItem.icon.source
                    fillMode: Image.PreserveAspectFit
                    opacity: menuItem.enabled ? 1.0 : 0.5
                    visible: source.toString() !== ""

                    layer.enabled: menuItem.highlighted
                    layer.effect: HueSaturation {
                        saturation: 0
                        lightness: 0.8 // 使图标变亮以适应高亮背景
                    }
                }
            }

            // 菜单项文本
            Text {
                Layout.fillWidth: true
                text: menuItem.text
                font {
                    family: "Segoe UI, Arial, sans-serif"
                    pixelSize: 13
                    weight: Font.Medium
                }
                opacity: menuItem.enabled ? 1.0 : 0.5
                color: menuItem.highlighted ? "#FFFFFF" : "#333333"
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            // 快捷键文本（如果有）
            Text {
                text: menuItem.shortcut || ""
                font {
                    family: "Segoe UI, Arial, sans-serif"
                    pixelSize: 12
                }
                opacity: 0.7
                color: menuItem.highlighted ? "#FFFFFF" : "#666666"
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                visible: text.length > 0
            }

            // 子菜单指示器（如适用）
            Item {
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                visible: menuItem.subMenu

                Text {
                    anchors.centerIn: parent
                    text: "›"
                    font.pixelSize: 14
                    font.bold: true
                    color: menuItem.highlighted ? "#FFFFFF" : "#666666"
                }
            }
        }

        // 菜单项背景
        background: Rectangle {
            implicitWidth: 200
            radius: 4
            color: {
                if (menuItem.highlighted)
                    return "#2980b9"
                return "transparent"
            }

            // 悬停效果
            Rectangle {
                anchors.fill: parent
                radius: 4
                color: menuItem.highlighted ? "transparent" : (menuItem.hovered ? "#F5F5F5" : "transparent")
            }

            // 轻微的过渡动画
            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }
        }
    }

    // 分隔线组件
    component MenuSeparator: Rectangle {
        implicitWidth: 200
        implicitHeight: 1
        color: "#E0E0E0"

        Rectangle {
            width: parent.width - 20
            height: 1
            anchors.centerIn: parent
            color: "#E0E0E0"
        }
    }
    // 根据选择的动画类型应用不同的动画
    enter: {
        switch (animationType) {
        case TtMenu.AnimationType.None:
            return null
        case TtMenu.AnimationType.FadeInOut:
            return fadeInTransition
        case TtMenu.AnimationType.SlideDown:
            return slideDownTransition
        case TtMenu.AnimationType.PopUp:
            return popUpTransition
        case TtMenu.AnimationType.Scale:
            return scaleTransition
        case TtMenu.AnimationType.Elegant:
            return elegantTransition
        default:
            return slideDownTransition
        }
    }
    exit: {
        switch (animationType) {
        case TtMenu.AnimationType.None:
            return null
        case TtMenu.AnimationType.FadeInOut:
            return fadeOutTransition
        case TtMenu.AnimationType.SlideDown:
            return slideUpTransition
        case TtMenu.AnimationType.PopUp:
            return popDownTransition
        case TtMenu.AnimationType.Scale:
            return scaleOutTransition
        case TtMenu.AnimationType.Elegant:
            return elegantOutTransition
        default:
            return fadeOutTransition
        }
    }

    // 添加 onOpened 处理器
    onOpened: {
        if (animationType === TtMenu.AnimationType.Elegant) {
            // 为所有菜单项手动触发动画
            for (var i = 0; i < count; i++) {
                let item = itemAt(i)
                if (item && item.appearAnimation) {
                    item.appearAnimation.start()
                }
            }
        }
    }

    readonly property Transition fadeInTransition: Transition {
        NumberAnimation {
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 200
        }
    }

    readonly property Transition fadeOutTransition: Transition {
        NumberAnimation {
            property: "opacity"
            from: 1.0
            to: 0.0
            duration: 150
        }
    }

    // 2. 向下滑动
    readonly property Transition slideDownTransition: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: 150
            }
            NumberAnimation {
                property: "y"
                from: root.parent ? root.parent.mapFromGlobal(
                                        0, root.y).y - 10 : root.y - 10
                to: root.y
                duration: 150
                easing.type: Easing.OutQuint
            }
        }
    }

    readonly property Transition slideUpTransition: Transition {
        NumberAnimation {
            property: "opacity"
            from: 1.0
            to: 0.0
            duration: 120
        }
    }

    // 3. 弹出效果
    readonly property Transition popUpTransition: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: 180
            }
            NumberAnimation {
                property: "scale"
                from: 0.8
                to: 1.0
                duration: 180
                easing.type: Easing.OutBack
            }
        }
    }

    readonly property Transition popDownTransition: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: 130
            }
            NumberAnimation {
                property: "scale"
                from: 1.0
                to: 0.8
                duration: 130
            }
        }
    }

    // 4. 缩放效果
    readonly property Transition scaleTransition: Transition {
        NumberAnimation {
            property: "scale"
            from: 0.0
            to: 1.0
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    readonly property Transition scaleOutTransition: Transition {
        NumberAnimation {
            property: "scale"
            from: 1.0
            to: 0.0
            duration: 150
            easing.type: Easing.InCubic
        }
    }

    // 5. 综合优雅效果
    readonly property Transition elegantTransition: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: 180
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "scale"
                from: 0.95
                to: 1.0
                duration: 200
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "y"
                from: root.y - 15
                to: root.y
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
    }

    readonly property Transition elegantOutTransition: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: 150
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                property: "scale"
                from: 1.0
                to: 0.97
                duration: 150
                easing.type: Easing.InQuad
            }
        }
    }

    // // 菜单项进入动画
    // readonly property Transition itemsEnterTransition: Transition {
    //     NumberAnimation {
    //         property: "opacity"
    //         from: 0
    //         to: 1.0
    //         duration: 80
    //         easing.type: Easing.OutQuad
    //     }
    //     NumberAnimation {
    //         property: "x"
    //         from: -5
    //         duration: 100
    //         easing.type: Easing.OutCubic
    //     }
    // }
    // 修复菜单项进入动画 - 将动画放在 ParallelAnimation 中
    readonly property Transition itemsEnterTransition: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1.0
                duration: 80
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                property: "x"
                from: -5
                to: 0 // 添加缺少的 to 值
                duration: 100
                easing.type: Easing.OutCubic
            }
        }
    }
}
