// import QtQuick
// import QtQuick.Controls
// import QtQuick.Layouts       

//         Rectangle {
//             id: toastNotification
//             anchors.horizontalCenter: parent.horizontalCenter
//             anchors.top: parent.top
//             anchors.topMargin: 80

//             width: Math.min(parent.width - 40, 250)
//             height: 120
//             radius: 16 // Material Design 推荐圆角
//             visible: false
//             z: 1000
//             // 在 Rectangle 中添加类型属性
//             property string notificationType: "info" // "success", "warning", "info", "error"

//             // 动态颜色配置
//             QtObject {
//                 id: materialColors
//                 property var colors: ({
//                                           "error": {
//                                               "primary": "#FF5252",
//                                               "surface": "#2D1B1B",
//                                               "onSurface"// 深红色背景，而不是纯黑
//                                               : "#FFFFFF"
//                                           },
//                                           "success": {
//                                               "primary": "#4CAF50",
//                                               "surface": "#1B2D1B",
//                                               "onSurface"// 深绿色背景
//                                               : "#FFFFFF"
//                                           },
//                                           "warning": {
//                                               "primary": "#FF9800",
//                                               "surface": "#2D251B",
//                                               "onSurface"// 深橙色背景
//                                               : "#FFFFFF"
//                                           },
//                                           "info": {
//                                               "primary": "#2196F3",
//                                               "surface": "#1B252D",
//                                               "onSurface"// 深蓝色背景
//                                               : "#FFFFFF"
//                                           }
//                                       })
//                 function getColor(type, variant) {
//                     return colors[type] ? colors[type][variant] : colors["error"][variant]
//                 }
//             }

//             // 使用动态背景颜色，不再是纯黑色
//             color: materialColors.getColor(notificationType, "surface")
//             // 修改颜色引用
//             border.color: materialColors.getColor(notificationType, "primary")
//             // Material Design 边框
//             border.width: 1

//             // Material Design 阴影效果
//             layer.enabled: true
//             layer.effect: DropShadow {
//                 horizontalOffset: 0
//                 verticalOffset: 8
//                 radius: 24
//                 samples: 49
//                 color: "#40000000"
//                 cached: true
//             }

//             // Material Design 表面覆盖层
//             Rectangle {
//                 anchors.fill: parent
//                 radius: parent.radius
//                 color: "#FFFFFF"
//                 opacity: 0.03 // Material Design 表面覆盖
//                 z: -1
//             }

//             property alias message: toastText.text

//             // Material Motion 进入动画
//             ParallelAnimation {
//                 id: showToastAnimation

//                 // 位移动画 - Material Motion Easing
//                 NumberAnimation {
//                     target: toastNotification
//                     property: "anchors.topMargin"
//                     from: -200
//                     to: 80
//                     duration: 500
//                     easing.type: Easing.OutCubic // Material Motion 标准缓动
//                 }

//                 // 透明度动画
//                 NumberAnimation {
//                     target: toastNotification
//                     property: "opacity"
//                     from: 0
//                     to: 1
//                     duration: 300
//                     easing.type: Easing.OutCubic
//                 }

//                 // 缩放动画 - Material 风格
//                 NumberAnimation {
//                     target: toastNotification
//                     property: "scale"
//                     from: 0.9
//                     to: 1.0
//                     duration: 400
//                     easing.type: Easing.OutCubic
//                 }
//             }

//             // Material Motion 退出动画
//             ParallelAnimation {
//                 id: hideToastAnimation

//                 NumberAnimation {
//                     target: toastNotification
//                     property: "anchors.topMargin"
//                     from: 80
//                     to: -200
//                     duration: 300
//                     easing.type: Easing.InCubic // Material Motion 退出缓动
//                 }

//                 NumberAnimation {
//                     target: toastNotification
//                     property: "opacity"
//                     from: 1
//                     to: 0
//                     duration: 250
//                     easing.type: Easing.InCubic
//                 }

//                 NumberAnimation {
//                     target: toastNotification
//                     property: "scale"
//                     from: 1.0
//                     to: 0.95
//                     duration: 250
//                     easing.type: Easing.InCubic
//                 }

//                 onFinished: {
//                     toastNotification.visible = false
//                     toastNotification.scale = 1.0
//                 }
//             }

//             RowLayout {
//                 anchors.fill: parent
//                 anchors.margins: 20
//                 // spacing: 16

//                 // Material Design 图标
//                 Rectangle {
//                     id: errorIcon
//                     width: 28
//                     height: 28
//                     radius: 14
//                     Layout.alignment: Qt.AlignTop
//                     Layout.topMargin: 2

//                     // Material Design 错误色
//                     // 使用动态颜色
//                     color: materialColors.getColor(
//                                toastNotification.notificationType, "primary")

//                     // Material Design 图标阴影
//                     layer.enabled: true
//                     layer.effect: DropShadow {
//                         horizontalOffset: 0
//                         verticalOffset: 2
//                         radius: 4
//                         samples: 9
//                         // color: "#40FF5252"
//                         color: "#40" + materialColors.getColor(
//                                    toastNotification.notificationType,
//                                    "primary").substring(1)
//                     }
//                     // 修改图标
//                     Text {
//                         anchors.centerIn: parent
//                         text: {
//                             switch (toastNotification.notificationType) {
//                             case "success":
//                                 return "✓"
//                             case "warning":
//                                 return "⚠"
//                             case "info":
//                                 return "ℹ"
//                             case "error":
//                             default:
//                                 return "!"
//                             }
//                         }
//                         color: materialColors.getColor(
//                                    toastNotification.notificationType,
//                                    "onSurface")
//                         font.pixelSize: 20
//                         font.weight: Font.Medium
//                     }

//                     // Material Design 波纹效果
//                     Rectangle {
//                         id: ripple
//                         anchors.centerIn: parent
//                         width: 0
//                         height: 0
//                         radius: width / 2
//                         color: "#40FFFFFF"
//                         visible: false

//                         NumberAnimation {
//                             id: rippleAnimation
//                             target: ripple
//                             property: "width"
//                             from: 0
//                             to: errorIcon.width * 2
//                             duration: 600
//                             easing.type: Easing.OutCubic

//                             onStarted: {
//                                 ripple.height = ripple.width
//                                 ripple.visible = true
//                             }
//                             onFinished: {
//                                 ripple.visible = false
//                                 ripple.width = 0
//                                 ripple.height = 0
//                             }
//                         }
//                     }
//                 }

//                 // Material Design 文本区域
//                 Column {
//                     Layout.fillWidth: true
//                     Layout.fillHeight: true
//                     // spacing: 8
//                     spacing: 4

//                     // Material Design 标题文本
//                     Text {
//                         // text: "操作失败"
//                         text: {
//                             switch (toastNotification.notificationType) {
//                             case "success":
//                                 return qsTr("操作成功")
//                             case "warning":
//                                 return qsTr("注意")
//                             case "info":
//                                 return qsTr("提示")
//                             case "error":
//                             default:
//                                 return qsTr("操作失败")
//                             }
//                         }
//                         color: "#FFFFFF"
//                         // font.pixelSize: 16
//                         font.pixelSize: 13
//                         font.weight: Font.Medium // Material Design 字重
//                         font.family: "Roboto" // Material Design 字体
//                         width: parent.width

//                         // Material Design 文本淡入
//                         NumberAnimation on opacity {
//                             running: toastNotification.visible
//                             from: 0
//                             to: 1
//                             duration: 400
//                             easing.type: Easing.OutCubic
//                         }
//                     }

//                     // Material Design 分隔线
//                     Rectangle {
//                         width: parent.width
//                         height: 1
//                         // color: "#1FFFFFFF" // Material Design 分隔线颜色
//                         color: materialColors.getColor(
//                                    toastNotification.notificationType,
//                                    "primary")
//                         opacity: 0.3

//                         // 分隔线动画
//                         NumberAnimation on opacity {
//                             running: toastNotification.visible
//                             from: 0
//                             to: 1
//                             duration: 500
//                             easing.type: Easing.OutCubic
//                         }
//                     }

//                     // Material Design 滚动区域
//                     ScrollView {
//                         id: textScrollView
//                         width: parent.width
//                         // height: parent.height - 50 // 为标题和分隔线留出空间
//                         height: parent.height - 30 // 为标题和分隔线留出空间
//                         clip: true

//                         // Material Design 滚动条配置
//                         ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
//                         ScrollBar.vertical.policy: ScrollBar.AsNeeded

//                         // Material Design 正文文本
//                         Text {
//                             id: toastText
//                             text: ""
//                             color: "#E0E0E0" // Material Design 次要文本颜色
//                             // font.pixelSize: 14
//                             font.pixelSize: 13
//                             font.weight: Font.Normal
//                             font.family: "Roboto"
//                             wrapMode: Text.WordWrap
//                             width: textScrollView.width - 8
//                             lineHeight: 1.5 // Material Design 行高

//                             // Material Design 文本动画
//                             NumberAnimation on opacity {
//                                 running: toastNotification.visible
//                                 from: 0
//                                 to: 1
//                                 duration: 600
//                                 easing.type: Easing.OutCubic
//                             }
//                         }
//                     }

//                     // Material Design 时间戳
//                     Text {
//                         id: timestampText
//                         text: Qt.formatDateTime(new Date(), "hh:mm")
//                         color: "#757575" // Material Design 禁用文本颜色
//                         font.pixelSize: 12
//                         font.weight: Font.Normal
//                         font.family: "Roboto"
//                         opacity: 0.7
//                         width: parent.width
//                     }
//                 }

//                 // Material Design 操作按钮
//                 Rectangle {
//                     id: closeButton
//                     // width: 36
//                     // height: 36
//                     width: 28
//                     height: 28
//                     radius: 14
//                     Layout.alignment: Qt.AlignTop
//                     Layout.topMargin: 2

//                     color: closeButtonArea.pressed ? "#1FFFFFFF" : closeButtonArea.containsMouse ? "#0DFFFFFF" : "transparent"

//                     // Material Design 波纹效果
//                     Rectangle {
//                         id: closeRipple
//                         anchors.centerIn: parent
//                         width: 0
//                         height: 0
//                         radius: width / 2
//                         color: "#40FFFFFF"
//                         visible: false

//                         NumberAnimation {
//                             id: closeRippleAnimation
//                             target: closeRipple
//                             property: "width"
//                             from: 0
//                             to: closeButton.width * 1.5
//                             duration: 300
//                             easing.type: Easing.OutCubic

//                             onStarted: {
//                                 closeRipple.height = closeRipple.width
//                                 closeRipple.visible = true
//                             }
//                             onFinished: {
//                                 closeRipple.visible = false
//                                 closeRipple.width = 0
//                                 closeRipple.height = 0
//                             }
//                         }
//                     }
//                     // Material Design 悬停效果
//                     MouseArea {
//                         id: closeButtonArea
//                         anchors.fill: parent
//                         hoverEnabled: true
//                         cursorShape: Qt.PointingHandCursor

//                         onClicked: {
//                             closeRippleAnimation.start()
//                             toastNotification.hideToast()
//                         }
//                     }

//                     Behavior on color {
//                         ColorAnimation {
//                             duration: 200
//                             easing.type: Easing.OutCubic
//                         }
//                     }

//                     Text {
//                         anchors.centerIn: parent
//                         text: "✕" // 或者使用 Material Icons: "\ue5cd"
//                         color: "#FFFFFF"
//                         // font.pixelSize: 16
//                         font.pixelSize: 13
//                         font.weight: Font.Medium
//                         font.family: "Material Icons"

//                         Behavior on color {
//                             ColorAnimation {
//                                 duration: 200
//                                 easing.type: Easing.OutCubic
//                             }
//                         }
//                     }
//                     scale: closeButtonArea.pressed ? 0.95 : 1.0

//                     Behavior on scale {
//                         NumberAnimation {
//                             duration: 100
//                             easing.type: Easing.OutCubic
//                         }
//                     }
//                 }
//             }
//             // 底部进度条
//             Item {
//                 id: progressContainer
//                 anchors.bottom: parent.bottom
//                 anchors.left: parent.left
//                 anchors.right: parent.right
//                 // height: 8
//                 height: 6

//                 // 进度条背景
//                 Rectangle {
//                     anchors.fill: parent
//                     color: "transparent"

//                     // 使用 Canvas 绘制完美的底部圆角
//                     Canvas {
//                         id: progressCanvas
//                         anchors.fill: parent

//                         property real fillWidth: 0

//                         onPaint: {
//                             var ctx = getContext("2d")
//                             ctx.clearRect(0, 0, width, height)

//                             var radius = toastNotification.radius
//                             var containerWidth = width
//                             var containerHeight = height

//                             // 绘制背景（半透明）
//                             ctx.fillStyle = "#20FFFFFF"
//                             ctx.beginPath()
//                             ctx.moveTo(0, 0)
//                             ctx.lineTo(containerWidth, 0)
//                             ctx.lineTo(containerWidth, containerHeight - radius)
//                             ctx.arcTo(containerWidth, containerHeight,
//                                       containerWidth - radius,
//                                       containerHeight, radius)
//                             ctx.lineTo(radius, containerHeight)
//                             ctx.arcTo(0, containerHeight, 0,
//                                       containerHeight - radius, radius)
//                             ctx.lineTo(0, 0)
//                             ctx.fill()

//                             // 绘制进度填充
//                             if (fillWidth > 0) {
//                                 ctx.fillStyle = materialColors.getColor(
//                                             toastNotification.notificationType,
//                                             "primary")
//                                 ctx.beginPath()
//                                 ctx.moveTo(0, 0)
//                                 ctx.lineTo(Math.min(fillWidth,
//                                                     containerWidth), 0)

//                                 if (fillWidth >= containerWidth - radius) {
//                                     // 如果填充超过了右边圆角的起始点
//                                     ctx.lineTo(containerWidth,
//                                                containerHeight - radius)
//                                     ctx.arcTo(containerWidth, containerHeight,
//                                               containerWidth - radius,
//                                               containerHeight, radius)
//                                 } else {
//                                     ctx.lineTo(fillWidth, containerHeight)
//                                 }

//                                 if (fillWidth > radius) {
//                                     // 如果填充超过了左边圆角
//                                     ctx.lineTo(radius, containerHeight)
//                                     ctx.arcTo(0, containerHeight, 0,
//                                               containerHeight - radius, radius)
//                                 } else {
//                                     ctx.lineTo(0, containerHeight)
//                                 }

//                                 ctx.lineTo(0, 0)
//                                 ctx.fill()
//                             }
//                         }

//                         NumberAnimation {
//                             id: progressAnimation
//                             target: progressCanvas
//                             property: "fillWidth"
//                             from: 0
//                             to: progressContainer.width
//                             duration: toastTimer.interval
//                             running: toastTimer.running
//                             easing.type: Easing.Linear

//                             onRunningChanged: progressCanvas.requestPaint()
//                         }

//                         onFillWidthChanged: requestPaint()
//                     }
//                 }
//             }

//             Timer {
//                 id: toastTimer
//                 interval: 3000
//                 running: false
//                 repeat: false
//                 onTriggered: toastNotification.hideToast()
//             }

//             function showToast(message, type = "info") {
//                 notificationType = type
//                 toastText.text = message
//                 toastNotification.visible = true
//                 showToastAnimation.start()
//                 toastTimer.restart()
//                 progressAnimation.restart()
//                 textScrollView.ScrollBar.vertical.position = 0
//                 rippleAnimation.start()
//             }

//             function hideToast() {
//                 hideToastAnimation.start()
//                 toastTimer.stop()
//                 progressAnimation.stop()
//             }

//             // Material Design 交互区域
//             MouseArea {
//                 anchors.fill: parent
//                 anchors.rightMargin: 44 // 排除关闭按钮
//                 // anchors.leftMargin: 60 // 排除图标区域
//                 anchors.leftMargin: 30 // 排除图标区域
//                 // anchors.topMargin: 40 // 排除标题区域
//                 anchors.topMargin: 28 // 排除标题区域
//                 anchors.bottomMargin: textScrollView.height + 30

//                 // onClicked: hideToast()
//                 onClicked: toastNotification
//                 cursorShape: Qt.PointingHandCursor
//             }

//             // Material Design 键盘交互
//             Keys.onEscapePressed: hideToast()
//             Keys.onReturnPressed: hideToast()
//             focus: visible
//         }

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Item {
    id: root
    
    // 公开的属性
    property alias message: notificationRect.message
    property alias notificationType: notificationRect.notificationType
    property int duration: 3000
    property bool autoHide: true
    property real topMargin: 80
    
    // 公开的信号
    signal clicked()
    signal closed()
    signal aboutToShow()
    signal aboutToHide()
    
    // 公开的方法
    function show(msg, type = "info", autoHideAfter = 3000) {
        // 都没有输出执行
        console.log("Showing notification:", msg, "Type:", type)
        notificationRect.showToast(msg, type)
        if (autoHide && autoHideAfter > 0) {
            hideTimer.interval = autoHideAfter
            hideTimer.start()
        }
        aboutToShow()
    }
    
    function hide() {
        notificationRect.hideToast()
        hideTimer.stop()
        aboutToHide()
    }
    
    function showSuccess(msg, duration = 3000) {
        show(msg, "success", duration)
    }
    
    function showError(msg, duration = 5000) {
        show(msg, "error", duration)
    }
    
    function showWarning(msg, duration = 4000) {
        show(msg, "warning", duration)
    }
    
    function showInfo(msg, duration = 3000) {
        show(msg, "info", duration)
    }
    
    // 内部定时器
    Timer {
        id: hideTimer
        interval: root.duration
        running: false
        repeat: false
        onTriggered: root.hide()
    }
    
    // 主通知矩形
    Rectangle {
        id: notificationRect
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.topMargin

        width: Math.min(parent.width - 40, 350)
        height: 120
        radius: 16
        visible: false
        z: 1000
        
        property string notificationType: "info"
        property alias message: toastText.text

        // 动态颜色配置
        QtObject {
            id: materialColors
            property var colors: ({
                "error": {
                    "primary": "#FF5252",
                    "surface": "#2D1B1B",
                    "onSurface": "#FFFFFF"
                },
                "success": {
                    "primary": "#4CAF50",
                    "surface": "#1B2D1B",
                    "onSurface": "#FFFFFF"
                },
                "warning": {
                    "primary": "#FF9800",
                    "surface": "#2D251B",
                    "onSurface": "#FFFFFF"
                },
                "info": {
                    "primary": "#2196F3",
                    "surface": "#1B252D",
                    "onSurface": "#FFFFFF"
                }
            })
            
            function getColor(type, variant) {
                return colors[type] ? colors[type][variant] : colors["info"][variant]
            }
        }

        color: materialColors.getColor(notificationType, "surface")
        border.color: materialColors.getColor(notificationType, "primary")
        border.width: 1

        // 阴影效果
        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 8
            radius: 24
            samples: 49
            color: "#40000000"
            cached: true
        }

        // 进入动画
        ParallelAnimation {
            id: showAnimation
            
            NumberAnimation {
                target: notificationRect
                property: "anchors.topMargin"
                from: -200
                to: root.topMargin
                duration: 500
                easing.type: Easing.OutCubic
            }
            
            NumberAnimation {
                target: notificationRect
                property: "opacity"
                from: 0
                to: 1
                duration: 300
                easing.type: Easing.OutCubic
            }
            
            NumberAnimation {
                target: notificationRect
                property: "scale"
                from: 0.9
                to: 1.0
                duration: 400
                easing.type: Easing.OutCubic
            }
        }

        // 退出动画
        ParallelAnimation {
            id: hideAnimation
            
            NumberAnimation {
                target: notificationRect
                property: "anchors.topMargin"
                from: root.topMargin
                to: -200
                duration: 300
                easing.type: Easing.InCubic
            }
            
            NumberAnimation {
                target: notificationRect
                property: "opacity"
                from: 1
                to: 0
                duration: 250
                easing.type: Easing.InCubic
            }
            
            NumberAnimation {
                target: notificationRect
                property: "scale"
                from: 1.0
                to: 0.95
                duration: 250
                easing.type: Easing.InCubic
            }
            
            onFinished: {
                notificationRect.visible = false
                notificationRect.scale = 1.0
                root.closed()
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            // 图标
            Rectangle {
                id: iconRect
                width: 28
                height: 28
                radius: 14
                Layout.alignment: Qt.AlignTop
                Layout.topMargin: 2
                
                color: materialColors.getColor(notificationRect.notificationType, "primary")
                
                Text {
                    anchors.centerIn: parent
                    text: {
                        switch (notificationRect.notificationType) {
                        case "success": return "✓"
                        case "warning": return "⚠"
                        case "info": return "ℹ"
                        case "error":
                        default: return "!"
                        }
                    }
                    color: materialColors.getColor(notificationRect.notificationType, "onSurface")
                    font.pixelSize: 16
                    font.weight: Font.Medium
                }
            }

            // 文本区域
            Column {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 4

                Text {
                    text: {
                        switch (notificationRect.notificationType) {
                        case "success": return qsTr("操作成功")
                        case "warning": return qsTr("注意")
                        case "info": return qsTr("提示")
                        case "error":
                        default: return qsTr("操作失败")
                        }
                    }
                    color: "#FFFFFF"
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    width: parent.width
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: materialColors.getColor(notificationRect.notificationType, "primary")
                    opacity: 0.3
                }

                ScrollView {
                    width: parent.width
                    height: parent.height - 30
                    clip: true
                    
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    Text {
                        id: toastText
                        text: ""
                        color: "#E0E0E0"
                        font.pixelSize: 13
                        font.weight: Font.Normal
                        wrapMode: Text.WordWrap
                        width: parent.width - 8
                        lineHeight: 1.5
                    }
                }
            }

            // 关闭按钮
            Rectangle {
                id: closeButton
                width: 28
                height: 28
                radius: 14
                Layout.alignment: Qt.AlignTop
                Layout.topMargin: 2
                
                color: closeArea.pressed ? "#1FFFFFFF" : 
                       closeArea.containsMouse ? "#0DFFFFFF" : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: "#FFFFFF"
                    font.pixelSize: 14
                    font.weight: Font.Medium
                }

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.hide()
                }
                
                Behavior on color {
                    ColorAnimation { duration: 200 }
                }
            }
        }

        // 进度条
        Rectangle {
            id: progressBar
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 4
            color: "transparent"
            
            Rectangle {
                id: progressFill
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 0
                color: materialColors.getColor(notificationRect.notificationType, "primary")
                
                NumberAnimation {
                    id: progressAnimation
                    target: progressFill
                    property: "width"
                    from: 0
                    to: progressBar.width
                    duration: hideTimer.interval
                    running: hideTimer.running
                    easing.type: Easing.Linear
                }
            }
        }

        // 点击区域
        MouseArea {
            anchors.fill: parent
            anchors.rightMargin: 50
            onClicked: root.clicked()
        }

        // 公开的方法
        function showToast(message, type) {
            notificationType = type
            toastText.text = message
            visible = true
            showAnimation.start()
            progressAnimation.restart()
        }

        function hideToast() {
            hideAnimation.start()
            hideTimer.stop()
            progressAnimation.stop()
        }
    }
}