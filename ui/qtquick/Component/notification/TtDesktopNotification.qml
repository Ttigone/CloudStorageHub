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

    property var onClicked: null
    property var onClosed: null

    property bool _isShowing: false
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
        visible: duration > 0

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
            width: parent.width
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

                onFinished: {
                    if (notification._isShowing) {
                        notification.close()
                    }
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
    function show() {
        _isShowing = true
        
        console.log("🎬 开始显示通知动画，当前位置:", x, y)
        
        // 🔥 不在这里启动入场动画，由管理器控制
        // showAnimation.start()  // 注释掉这行
        
        // 启动进度条动画
        if (duration > 0) {
            console.log("⏱️ 启动进度条动画，持续时间:", duration)
            Qt.callLater(function() {
                if (progressAnimation) {
                    progressAnimation.start()
                    console.log("✅ 进度条动画已启动")
                }
            })
        }
    }
    function startEnterAnimation() {
        showAnimation.start()
    }

    function close() {
        _isShowing = false
        hideAnimation.start()
    }

    // ParallelAnimation {
    //     id: showAnimation

    //     NumberAnimation {
    //         target: notification
    //         property: "x"
    //         from: notification.parent ? notification.parent.width : 400
    //         to: notification._targetY
    //         duration: 400
    //         easing.type: Easing.OutBack
    //         easing.overshoot: 1.2
    //     }

    //     NumberAnimation {
    //         target: notification
    //         property: "opacity"
    //         from: 0
    //         to: 1
    //         duration: 300
    //         easing.type: Easing.OutCubic
    //     }
    // }
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
}
