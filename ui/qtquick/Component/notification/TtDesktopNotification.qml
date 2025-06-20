import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects

Rectangle {
    id: notification

    property string title: "通知"
    property string message: "这是一条通知消息"
    property string type: "info" // "success", "warning", "error", "info"
    property int duration: 10000// 显示时长(毫秒)，0表示不自动关闭
    property bool showCloseButton: true
    property bool showIcon: true
    property bool clickable: false

    property bool showProgress: true
    property bool autoClose: true
    property bool progressStarted: false

    property var onClicked: null
    property var onClosed: null

    // property bool _isShowing: false
    property bool _isShowing: true
    property real _targetY: 0

    width: 240
    height: Math.max(60, contentColumn.implicitHeight + 20)
    radius: 12

    color: getBackgroundColor()
    border.width: 1
    border.color: getBorderColor()

    layer.enabled: true
    layer.effect: DropShadow {
        horizontalOffset: 0
        verticalOffset: 4
        radius: 16
        samples: 33
        color: "#40000000"
        transparentBorder: true
    }

    RowLayout {
        id: contentRow
        anchors.fill: parent
        anchors.margins: 8
        anchors.bottomMargin: duration > 0 ? 11 : 8 // 进度条高度
        spacing: 6

        Rectangle {
            id: iconContainer
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            Layout.alignment: Qt.AlignTop
            radius: 14
            color: getIconBackgroundColor()
            visible: showIcon

            Text {
                id: iconText
                anchors.centerIn: parent
                text: getIcon()
                font.pixelSize: 18
                color: getIconColor()
            }

            SequentialAnimation on scale {
                running: notification._isShowing && type === "success"
                loops: 1
                NumberAnimation {
                    from: 1.0
                    to: 1.2
                    duration: 200
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    from: 1.2
                    to: 1.0
                    duration: 200
                    easing.type: Easing.InCubic
                }
            }
        }

        ColumnLayout {
            id: contentColumn
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            // 标题
            Text {
                id: titleText
                Layout.fillWidth: true
                text: notification.title
                font.pixelSize: 15
                font.weight: Font.DemiBold
                color: getTitleColor()
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            // 消息内容
            Text {
                id: messageText
                Layout.fillWidth: true
                text: notification.message
                font.pixelSize: 13
                color: getMessageColor()
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
                lineHeight: 1.4
            }
        }

        Button {
            id: closeButton
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignTop
            visible: showCloseButton

            background: Rectangle {
                radius: 12
                color: parent.hovered ? "#20000000" : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }

            contentItem: Text {
                text: "✕"
                font.pixelSize: 12
                color: getCloseButtonColor()
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked: notification.close()

            onPressed: scale = 0.9
            onReleased: scale = 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: 100
                }
            }
        }
    }
    // Rectangle {
    //     id: progressBar
    //     anchors.left: parent.left
    //     anchors.right: parent.right
    //     anchors.bottom: parent.bottom
    //     anchors.leftMargin: 8
    //     anchors.rightMargin: 8
    //     anchors.bottomMargin: 6
    //     height: 2
    //     color: "transparent"
    //     // visible: duration > 0
    //     visible: duration > 0 && showProgress

    //     Rectangle {
    //         id: progressBackground
    //         anchors.fill: parent
    //         color: getProgressBarColor()
    //         radius: parent.height / 2
    //         opacity: 0.4
    //     }

    //     Rectangle {
    //         id: progressFill
    //         anchors.left: parent.left
    //         anchors.top: parent.top
    //         anchors.bottom: parent.bottom
    //         width: parent.width
    //         color: getAccentColor()
    //         radius: parent.height / 2

    //         gradient: Gradient {
    //             GradientStop {
    //                 position: 0.0
    //                 color: Qt.lighter(getAccentColor(), 1.1)
    //             }
    //             GradientStop {
    //                 position: 1.0
    //                 color: getAccentColor()
    //             }
    //         }

    //         NumberAnimation on width {
    //             id: progressAnimation
    //             from: progressBar.width
    //             to: 0
    //             duration: notification.duration
    //             running: false
    //             easing.type: Easing.Linear 

    //             onFinished: {
    //                 if (notification._isShowing && notification.autoClose) {
    //                     notification.close()
    //                 }
    //             }
    //         }
    //     }
    // }

  Rectangle {
        id: progressBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.bottomMargin: 6
        height: 2
        color: "transparent"
        // 🔥 修复可见性条件
        visible: showProgress && duration > 0 && autoClose

        // 🔥 调试进度条可见性
        onVisibleChanged: {
            console.log("📊 进度条可见性变化:", visible, "条件: showProgress=", showProgress, "duration=", duration, "autoClose=", autoClose)
        }

        Rectangle {
            id: progressBackground
            anchors.fill: parent
            color: getProgressBarColor()
            radius: parent.height / 2
            opacity: 0.4
        }

        Rectangle {
            id: progressFill
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width // 🔥 初始宽度为满格
            color: getAccentColor()
            radius: parent.height / 2

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.lighter(getAccentColor(), 1.1)
                }
                GradientStop {
                    position: 1.0
                    color: getAccentColor()
                }
            }

            NumberAnimation on width {
                id: progressAnimation
                from: progressBar.width
                to: 0
                duration: notification.duration
                running: false
                easing.type: Easing.Linear

                onFinished: {
                    console.log("🏁 进度条动画完成，标题:", notification.title)
                    if (notification._isShowing && notification.autoClose) {
                        notification.close()
                    }
                }

                onRunningChanged: {
                    console.log("🎮 进度条动画运行状态变化:", running, "通知:", notification.title)
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: clickable
        cursorShape: clickable ? Qt.PointingHandCursor : Qt.ArrowCursor

        onClicked: {
            if (notification.onClicked) {
                notification.onClicked()
            }
        }

        onEntered: {
            if (clickable) {
                notification.scale = 1.02
            }
        }

        onExited: {
            if (clickable) {
                notification.scale = 1.0
            }
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

// function show() {
//     _isShowing = true
//     console.log("🎬 开始显示通知动画，当前位置:", x, y)
//     // 启动进度条动画
//     if (duration > 0) {
//         console.log("⏱️ 启动进度条动画，持续时间:", duration)
//         Qt.callLater(function() {
//             if (progressAnimation) {
//                 progressAnimation.start()
//                 console.log("✅ 进度条动画已启动")
//             }
//         })
//     }
// }
    //     function show() {
    //     _isShowing = true
    //     console.log("🎬 开始显示通知:", title, "持续时间:", duration, "显示进度条:", showProgress)
        
    //     // 🔥 关键修复：确保进度条动画正确启动
    //     if (duration > 0 && showProgress && !progressStarted && autoClose) {
    //         console.log("⏱️ 准备启动进度条动画")
    //         progressStarted = true
            
    //         // 🔥 延迟启动，确保UI完全渲染和可见
    //         Qt.callLater(function() {
    //             if (notification._isShowing && progressAnimation && notification.visible) {
    //                 console.log("✅ 正在启动进度条动画，从", progressFill.width, "到 0，持续时间:", duration)
                    
    //                 // 确保进度条可见且有正确的初始状态
    //                 progressBar.visible = true
    //                 progressFill.width = progressBar.width
                    
    //                 // 启动动画
    //                 progressAnimation.start()
                    
    //                 console.log("🔄 进度条动画已启动，运行状态:", progressAnimation.running)
    //             } else {
    //                 console.warn("⚠️ 无法启动进度条动画 - 条件检查失败")
    //                 console.warn("_isShowing:", notification._isShowing)
    //                 console.warn("progressAnimation存在:", !!progressAnimation)
    //                 console.warn("visible:", notification.visible)
    //             }
    //         })
    //     } else {
    //         console.log("🚫 跳过进度条动画 - duration:", duration, "showProgress:", showProgress, "progressStarted:", progressStarted, "autoClose:", autoClose)
    //     }
    // }
    function show() {
        _isShowing = true
        console.log("🎬 开始显示通知:", title, "持续时间:", duration, "显示进度条:", showProgress, "自动关闭:", autoClose)
        
        // 🔥 强制更新进度条可见性
        if (showProgress && duration > 0 && autoClose) {
            progressBar.visible = true
            console.log("✅ 强制设置进度条可见")
        }
        
        // 🔥 启动进度条动画
        if (duration > 0 && showProgress && !progressStarted && autoClose) {
            console.log("⏱️ 准备启动进度条动画")
            progressStarted = true
            
            Qt.callLater(function() {
                if (notification._isShowing && progressAnimation && notification.visible) {
                    console.log("✅ 正在启动进度条动画，从", progressFill.width, "到 0，持续时间:", duration)
                    
                    // 确保进度条初始状态正确
                    progressFill.width = progressBar.width
                    
                    // 启动动画
                    progressAnimation.start()
                    
                    console.log("🔄 进度条动画已启动，运行状态:", progressAnimation.running)
                } else {
                    console.warn("⚠️ 无法启动进度条动画 - 条件检查失败")
                }
            })
        } else {
            console.log("🚫 跳过进度条动画 - duration:", duration, "showProgress:", showProgress, "progressStarted:", progressStarted, "autoClose:", autoClose)
        }
    }
     function stopProgress() {
        if (progressAnimation.running) {
            progressAnimation.stop()
            console.log("⏹️ 进度条动画已停止")
        }
        progressStarted = false
    }
    function startEnterAnimation() {
        showAnimation.start()
    }

    // function close() {
    //     _isShowing = false
    //     hideAnimation.start()
    // }
        function close() {
        console.log("🔴 关闭通知:", title)
        _isShowing = false
        stopProgress()  // 停止进度条
        hideAnimation.start()
    }
        function pauseProgress() {
        if (progressAnimation.running) {
            progressAnimation.pause()
            console.log("⏸️ 进度条已暂停")
        }
    }
        function resumeProgress() {
        if (progressAnimation.paused) {
            progressAnimation.resume()
            console.log("▶️ 进度条已恢复")
        }
    }


    ParallelAnimation {
        id: showAnimation

        NumberAnimation {
            target: notification
            property: "opacity"
            from: 0
            to: 1
            duration: 200
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: notification
            property: "scale"
            from: 0.95
            to: 1.0
            duration: 200
            easing.type: Easing.OutCubic
        }
    }


    ParallelAnimation {
        id: hideAnimation

        NumberAnimation {
            target: notification
            property: "x"
            to: notification.parent ? notification.parent.width : 400
            duration: 300
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: notification
            property: "opacity"
            to: 0
            duration: 300
            easing.type: Easing.InCubic
        }

        onFinished: {
            if (notification.onClosed) {
                notification.onClosed()
            }
            notification.destroy()
        }
    }

    function getBackgroundColor() {
        switch (type) {
        case "success":
            return "#F0F9FF"
        case "warning":
            return "#FFFBEB"
        case "error":
            return "#FEF2F2"
        default:
            return "#F8FAFC"
        }
    }

    function getBorderColor() {
        switch (type) {
        case "success":
            return "#86EFAC"
        case "warning":
            return "#FCD34D"
        case "error":
            return "#FCA5A5"
        default:
            return "#CBD5E1"
        }
    }

    function getAccentColor() {
        switch (type) {
        case "success":
            return "#10B981"
        case "warning":
            return "#F59E0B"
        case "error":
            return "#EF4444"
        default:
            return "#3B82F6"
        }
    }

    function getIcon() {
        switch (type) {
        case "success":
            return "✓"
        case "warning":
            return "⚠"
        case "error":
            return "✕"
        default:
            return "ℹ"
        }
    }

    function getIconBackgroundColor() {
        switch (type) {
        case "success":
            return "#DCFCE7"
        case "warning":
            return "#FEF3C7"
        case "error":
            return "#FEE2E2"
        default:
            return "#DBEAFE"
        }
    }

    function getIconColor() {
        switch (type) {
        case "success":
            return "#059669"
        case "warning":
            return "#D97706"
        case "error":
            return "#DC2626"
        default:
            return "#2563EB"
        }
    }

    function getTitleColor() {
        switch (type) {
        case "success":
            return "#064E3B"
        case "warning":
            return "#92400E"
        case "error":
            return "#991B1B"
        default:
            return "#1E293B"
        }
    }

    function getMessageColor() {
        switch (type) {
        case "success":
            return "#065F46"
        case "warning":
            return "#A16207"
        case "error":
            return "#B91C1C"
        default:
            return "#475569"
        }
    }

    function getCloseButtonColor() {
        switch (type) {
        case "success":
            return "#059669"
        case "warning":
            return "#D97706"
        case "error":
            return "#DC2626"
        default:
            return "#64748B"
        }
    }

    function getProgressBarColor() {
        return "#E2E8F0"
    }
     Component.onCompleted: {
        console.log("📱 通知组件创建完成:", title)
        console.log("  - 持续时间:", duration)
        console.log("  - 显示进度条:", showProgress)
        console.log("  - 自动关闭:", autoClose)
        console.log("  - 进度条可见:", progressBar.visible)
    }
}

