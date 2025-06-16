// import QtQuick 2.15
// import QtQuick.Controls 2.15
// import QtQuick.Layouts 1.15
// import Qt5Compat.GraphicalEffects

// Rectangle {
//     id: root

//     property string message: "加载中..."
//     property bool active: false

//     opacity: active ? 1.0 : 0.0
//     visible: opacity > 0

//     color: "#99000000"

//     Behavior on opacity {
//         NumberAnimation {
//             duration: 250
//             easing.type: Easing.OutCubic
//         }
//     }

//     MouseArea {
//         anchors.fill: parent
//         // 拦截所有鼠标事件，防止用户点击下层控件
//         enabled: root.active
//         // cursorShape: Qt.SizeAllCursor // 这里似乎失效了, 没有显示
//         onClicked: {
//             // console.log("测试")
//         }
//         onPressed: {

//             // console.log("测试")
//         }
//         onReleased: {

//             // console.log("测试")
//         }
//     }

//     ColumnLayout {
//         anchors.centerIn: parent
//         spacing: 20

//         // 现代化的旋转加载动画
//         Item {
//             Layout.alignment: Qt.AlignHCenter
//             width: 60
//             height: 60

//             Rectangle {
//                 id: spinnerTrack
//                 anchors.fill: parent
//                 radius: width / 2
//                 color: "transparent"
//                 border.width: 4
//                 border.color: "#22FFFFFF"
//             }

//             ConicalGradient {
//                 anchors.fill: parent
//                 angle: 0

//                 gradient: Gradient {
//                     GradientStop {
//                         position: 0.0
//                         color: "#0088FF"
//                     }
//                     GradientStop {
//                         position: 0.5
//                         color: "#80FFFFFF"
//                     }
//                     GradientStop {
//                         position: 1.0
//                         color: "#0088FF"
//                     }
//                 }

//                 Rectangle {
//                     anchors.fill: parent
//                     color: "transparent"
//                     radius: width / 2
//                     border.width: 4
//                     border.color: "transparent"

//                     // 圆形遮罩
//                     layer.enabled: true
//                     layer.effect: OpacityMask {
//                         maskSource: Rectangle {
//                             width: spinnerTrack.width
//                             height: spinnerTrack.height
//                             radius: width / 2
//                         }
//                     }
//                 }

//                 RotationAnimation on rotation {
//                     from: 0
//                     to: 360
//                     duration: 1500
//                     loops: Animation.Infinite
//                     running: root.active
//                 }
//             }
//         }

//         // 加载文本
//         Text {
//             Layout.alignment: Qt.AlignHCenter
//             text: root.message
//             color: "#FFFFFF"
//             font.pixelSize: 16
//             font.weight: Font.Medium
//         }
//     }
// }

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root

    property string message: "加载中..."
    property bool active: false
    property string loadingType: "default" // "default", "buckets", "objects", "upload", "download"
    property real progress: -1 // -1 表示无进度条，0-1 表示具体进度

    // 通过opacity控制显示/隐藏，保持动画连续性
    opacity: active ? 1.0 : 0.0
    visible: opacity > 0

    // 🔥 美化背景 - 添加渐变和模糊效果
    gradient: Gradient {
        GradientStop { position: 0.0; color: "#DD000000" }
        GradientStop { position: 1.0; color: "#AA000000" }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    // 🔥 添加背景粒子效果
    Repeater {
        model: 15
        delegate: Rectangle {
            width: Math.random() * 4 + 2
            height: width
            radius: width / 2
            color: Qt.rgba(1, 1, 1, Math.random() * 0.3 + 0.1)
            
            x: Math.random() * root.width
            y: Math.random() * root.height
            
            opacity: root.active ? 1 : 0
            
            // 浮动动画
            SequentialAnimation on y {
                running: root.active
                loops: Animation.Infinite
                NumberAnimation {
                    from: parent.height + 10
                    to: -10
                    duration: Math.random() * 8000 + 4000
                    easing.type: Easing.InOutSine
                }
                onRunningChanged: {
                    if (running) {
                        parent.x = Math.random() * root.width
                    }
                }
            }
            
            Behavior on opacity {
                NumberAnimation { duration: 500 }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.active
        // 可以添加点击时的涟漪效果
        onClicked: {
            rippleEffect.createRipple(mouse.x, mouse.y)
        }
    }

    // 🔥 点击涟漪效果组件
    Item {
        id: rippleEffect
        anchors.fill: parent
        
        function createRipple(x, y) {
            var ripple = rippleComponent.createObject(rippleEffect, {"startX": x, "startY": y})
        }
        
        Component {
            id: rippleComponent
            Rectangle {
                property real startX: 0
                property real startY: 0
                
                width: 0
                height: 0
                radius: width / 2
                color: "#40FFFFFF"
                x: startX - width / 2
                y: startY - height / 2
                
                Component.onCompleted: rippleAnimation.start()
                
                ParallelAnimation {
                    id: rippleAnimation
                    NumberAnimation {
                        target: parent
                        property: "width"
                        from: 0; to: 200
                        duration: 600
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: parent
                        property: "height" 
                        from: 0; to: 200
                        duration: 600
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: parent
                        property: "opacity"
                        from: 0.6; to: 0
                        duration: 600
                        easing.type: Easing.OutCubic
                    }
                    onFinished: parent.destroy()
                }
            }
        }
    }

    // 🔥 主要内容区域
    Rectangle {
        id: contentArea
        anchors.centerIn: parent
        width: 280
        height: 320
        radius: 20
        color: "#F8F9FA"
        border.color: "#E9ECEF"
        border.width: 1

        // 添加阴影
        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 12
            radius: 32
            samples: 65
            color: "#60000000"
            transparentBorder: true
        }

        // 内容布局
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 24

            // 🔥 智能加载动画 - 根据类型显示不同图标
            Item {
                Layout.alignment: Qt.AlignHCenter
                width: 120
                height: 120

                // 背景圆环
                Rectangle {
                    id: backgroundRing
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border.width: 3
                    border.color: "#E9ECEF"
                }

                // 🔥 主加载动画 - 多层旋转效果
                Item {
                    anchors.fill: parent
                    
                    // 外圈动画
                    ConicalGradient {
                        id: outerGradient
                        anchors.fill: parent
                        angle: 0

                        gradient: Gradient {
                            GradientStop { position: 0.0; color: getLoadingColor() }
                            GradientStop { position: 0.7; color: Qt.rgba(1, 1, 1, 0.1) }
                            GradientStop { position: 1.0; color: getLoadingColor() }
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            radius: width / 2
                            border.width: 4
                            border.color: "transparent"

                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width: outerGradient.width
                                    height: outerGradient.height
                                    radius: width / 2
                                }
                            }
                        }

                        RotationAnimation on rotation {
                            from: 0; to: 360
                            duration: 2000
                            loops: Animation.Infinite
                            running: root.active
                            easing.type: Easing.Linear
                        }
                    }

                    // 内圈反向动画
                    Rectangle {
                        id: innerRing
                        anchors.centerIn: parent
                        width: parent.width * 0.7
                        height: width
                        radius: width / 2
                        color: "transparent"
                        border.width: 3
                        border.color: getLoadingColor()
                        opacity: 0.6

                        // 呼吸效果
                        SequentialAnimation on scale {
                            running: root.active
                            loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 1.1; duration: 1000; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 1.1; to: 1.0; duration: 1000; easing.type: Easing.InOutSine }
                        }

                        RotationAnimation on rotation {
                            from: 360; to: 0
                            duration: 1500
                            loops: Animation.Infinite
                            running: root.active
                            easing.type: Easing.Linear
                        }
                    }

                    // 🔥 中心图标 - 根据加载类型显示
                    Rectangle {
                        anchors.centerIn: parent
                        width: 48
                        height: 48
                        radius: 24
                        color: getLoadingColor()

                        Text {
                            anchors.centerIn: parent
                            text: getLoadingIcon()
                            font.pixelSize: 24
                            color: "#FFFFFF"
                        }

                        // 图标缩放动画
                        SequentialAnimation on scale {
                            running: root.active
                            loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 0.8; duration: 800; easing.type: Easing.InOutQuad }
                            NumberAnimation { from: 0.8; to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
                        }
                    }
                }

                // 🔥 进度条（如果有进度信息）
                Rectangle {
                    visible: root.progress >= 0
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: -16
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width + 20
                    height: 8
                    radius: 4
                    color: "#E9ECEF"

                    Rectangle {
                        height: parent.height
                        width: parent.width * Math.max(0, Math.min(1, root.progress))
                        radius: parent.radius
                        color: getLoadingColor()

                        Behavior on width {
                            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: Math.round(root.progress * 100) + "%"
                        font.pixelSize: 10
                        color: "#6C757D"
                        visible: root.progress > 0.05
                    }
                }
            }

            // 🔥 加载消息文本
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 240
                text: root.message
                color: "#495057"
                font.pixelSize: 16
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap

                // 文字淡入淡出效果
                SequentialAnimation on opacity {
                    running: root.active && root.progress < 0
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 0.7; duration: 1200; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.7; to: 1.0; duration: 1200; easing.type: Easing.InOutSine }
                }
            }

            // 🔥 副标题文本（可选）
            Text {
                id: subMessage
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 220
                text: getSubMessage()
                color: "#868E96"
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                visible: text.length > 0
                opacity: 0.8
            }

            // 🔥 加载点动画
            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8
                visible: root.progress < 0

                Repeater {
                    model: 3
                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: getLoadingColor()

                        SequentialAnimation on scale {
                            running: root.active
                            loops: Animation.Infinite
                            PauseAnimation { duration: index * 200 }
                            NumberAnimation { from: 1.0; to: 1.5; duration: 300; easing.type: Easing.OutCubic }
                            NumberAnimation { from: 1.5; to: 1.0; duration: 300; easing.type: Easing.InCubic }
                            PauseAnimation { duration: (2 - index) * 200 + 400 }
                        }

                        SequentialAnimation on opacity {
                            running: root.active
                            loops: Animation.Infinite
                            PauseAnimation { duration: index * 200 }
                            NumberAnimation { from: 0.5; to: 1.0; duration: 300 }
                            NumberAnimation { from: 1.0; to: 0.5; duration: 300 }
                            PauseAnimation { duration: (2 - index) * 200 + 400 }
                        }
                    }
                }
            }
        }

        // 🔥 入场动画
        scale: root.active ? 1.0 : 0.9
        Behavior on scale {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutBack
                easing.overshoot: 1.2
            }
        }
    }

    // 🔥 工具函数 - 根据加载类型返回颜色
    function getLoadingColor() {
        switch (loadingType) {
            case "buckets": return "#3498DB"      // 蓝色 - 桶加载
            case "objects": return "#2ECC71"      // 绿色 - 对象加载
            case "upload": return "#E74C3C"       // 红色 - 上传
            case "download": return "#F39C12"     // 橙色 - 下载
            default: return "#9B59B6"             // 紫色 - 默认
        }
    }

    // 🔥 工具函数 - 根据加载类型返回图标
    function getLoadingIcon() {
        switch (loadingType) {
            case "buckets": return "🗂️"          // 文件夹图标
            case "objects": return "📄"          // 文档图标
            case "upload": return "⬆️"           // 上传箭头
            case "download": return "⬇️"         // 下载箭头
            default: return "☁️"                 // 云图标
        }
    }

    // 🔥 工具函数 - 根据加载类型返回副消息
    function getSubMessage() {
        if (progress >= 0) {
            return "请稍候，正在处理中..."
        }
        
        switch (loadingType) {
            case "buckets": return "正在获取存储桶列表..."
            case "objects": return "正在加载文件列表..."
            case "upload": return "正在准备上传..."
            case "download": return "正在准备下载..."
            default: return "请稍候片刻..."
        }
    }

    // 🔥 公共方法 - 设置加载状态
    function setLoadingState(type, msg, prog) {
        loadingType = type || "default"
        message = msg || "加载中..."
        progress = prog !== undefined ? prog : -1
    }

    // 🔥 公共方法 - 显示加载
    function show(type, msg, prog) {
        setLoadingState(type, msg, prog)
        active = true
    }

    // 🔥 公共方法 - 隐藏加载
    function hide() {
        active = false
    }
}