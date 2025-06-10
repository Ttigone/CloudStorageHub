import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Popup {
    id: downloadPanel
    width: 320
    // height: 200
    height: Math.min(parent.height * 0.6, 500)
    padding: 0
    margins: 16
    closePolicy: Popup.NoAutoClose
    // x: parent.width - width - 20
    // y: 80
    property real initialX: parent.width - width - 20
    property real initialY: 80
    // 组件完成时设置初始位置
    Component.onCompleted: {
        x = initialX
        y = initialY
    }
    property var downloadModel: null
    property int activeDownloads: 0
    // 添加拖动相关属性
    property bool isDragging: false
    property point dragStartPos: Qt.point(0, 0)

    background: Rectangle {
        color: "#FFFFFF"
        radius: 8
        border.color: downloadPanel.isDragging ? "#3B82F6" : "#E0E0E0"
        border.width: downloadPanel.isDragging ? 2 : 1
        // 拖动时的视觉反馈
        Behavior on border.color {
            ColorAnimation {
                duration: 150
            }
        }

        Behavior on border.width {
            NumberAnimation {
                duration: 150
            }
        }
        layer.enabled: true
        layer.effect: DropShadow {
            radius: downloadPanel.isDragging ? 20 : 16
            samples: 32
            color: downloadPanel.isDragging ? "#60000000" : "#40000000"
            verticalOffset: 8
            horizontalOffset: 0

            Behavior on radius {
                NumberAnimation {
                    duration: 150
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
        }
    }
    // 进入/退出动画
    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 200
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "scale"
                from: 0.9
                to: 1.0
                duration: 200
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
                duration: 150
            }
            NumberAnimation {
                property: "scale"
                from: 1.0
                to: 0.95
                duration: 150
            }
        }
    }
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        // 可拖拽标题栏
        Rectangle {
            id: titleBar
            Layout.fillWidth: true
            height: 56
            // color: "#F8F9FA"
            color: downloadPanel.isDragging ? "#F1F5F9" : "#F8F9FA"
            radius: 12

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: parent.radius
                color: parent.color
            }
            // 添加拖动区域
            MouseArea {
                id: dragArea
                anchors.fill: parent
                cursorShape: Qt.SizeAllCursor // 显示拖动光标

                property point clickPos: "0,0"

                onPressed: function (mouse) {
                    clickPos = Qt.point(mouse.x, mouse.y)
                }

                onPositionChanged: function (mouse) {
                    // 计算新位置
                    var delta = Qt.point(mouse.x - clickPos.x,
                                         mouse.y - clickPos.y)

                    // 更新面板位置
                    var newX = downloadPanel.x + delta.x
                    var newY = downloadPanel.y + delta.y

                    // 边界检查 - 确保面板不会拖出屏幕
                    var parentWidth = downloadPanel.parent.width
                    var parentHeight = downloadPanel.parent.height

                    // 限制 X 坐标
                    newX = Math.max(0,
                                    Math.min(newX,
                                             parentWidth - downloadPanel.width))

                    // 限制 Y 坐标
                    newY = Math.max(0, Math.min(
                                        newY,
                                        parentHeight - downloadPanel.height))

                    // 应用新位置
                    downloadPanel.x = newX
                    downloadPanel.y = newY
                }
                // 防止拖动区域影响按钮点击
                onClicked: function (mouse) {
                    mouse.accepted = false
                }
                // 防止拖动时触发按钮点击
                propagateComposedEvents: false
            }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 16
                spacing: 12

                // 下载图标
                Rectangle {
                    width: 32
                    height: 32
                    radius: 8
                    color: "#3B82F6"

                    Text {
                        anchors.centerIn: parent
                        text: "⬇"
                        font.pixelSize: 16
                        color: "white"
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "下载管理"
                        font.bold: true
                        font.pixelSize: 16
                        color: "#1F2937"
                    }

                    Text {
                        text: `${activeDownloads} 个任务进行中`
                        font.pixelSize: 12
                        color: "#6B7280"
                    }
                }

                // 最小化按钮
                Button {
                    id: minimizeButton
                    width: 32
                    height: 32
                    flat: true

                    background: Rectangle {
                        color: minimizeButton.hovered ? "#F3F4F6" : "transparent"
                        radius: 6
                    }

                    // background: Rectangle {
                    //     color: parent.hovered ? "#F3F4F6" : "transparent"
                    //     radius: 6
                    // }
                    contentItem: Text {
                        text: "−"
                        font.pixelSize: 18
                        color: "#6B7280"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: downloadPanel.visible = false
                }
                // 关闭按钮
                Button {
                    id: closeButton
                    width: 32
                    height: 32
                    flat: true
                    // background: Rectangle {
                    //     color: parent.hovered ? "#FEE2E2" : "transparent"
                    //     radius: 6
                    // }
                    background: Rectangle {
                        color: closeButton.hovered ? "#FEE2E2" : "transparent"
                        radius: 6
                    }
                    contentItem: Text {
                        text: "×"
                        font.pixelSize: 18
                        color: parent.hovered ? "#DC2626" : "#6B7280"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        // 关闭所有下载任务
                        if (downloadPanel.downloadModel) {
                            downloadPanel.downloadModel.clear()
                        }
                        downloadPanel.visible = false
                    }
                    MouseArea {
                        anchors.fill: parent
                        onPressed: function (mouse) {
                            mouse.accepted = false // 不接受事件，让按钮处理
                        }
                    }
                }
            }
        }
        // 下载列表
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            clip: true

            ListView {
                id: listView
                model: downloadPanel.downloadModel
                spacing: 0
                clip: true
                interactive: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick
                // 确保滚动时悬停状态正确重置
                onContentYChanged: {
                    // 当滚动时，重置所有悬停状态
                    for (var i = 0; i < count; i++) {
                        var item = itemAtIndex(i)
                        if (item && item.isHovered !== undefined) {
                            item.isHovered = false
                        }
                    }
                }
                delegate: Rectangle {
                    id: delegateItem
                    width: listView.width
                    height: 80
                    color: "transparent"

                    property bool isHovered: false

                    // 悬停效果背景
                    Rectangle {
                        id: hoverBackground
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 8
                        color: delegateItem.isHovered ? "#F9FAFB" : "transparent"
                        border.color: delegateItem.isHovered ? "#E5E7EB" : "transparent"
                        border.width: 1
                    }

                    // 简化的鼠标检测区域
                    MouseArea {
                        id: primaryMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton

                        onEntered: {
                            // console.log("鼠标进入项目:", index)
                            delegateItem.isHovered = true
                        }

                        onExited: {
                            // console.log("鼠标离开项目:", index)
                            delegateItem.isHovered = false
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 16
                        spacing: 12

                        // 文件图标
                        Rectangle {
                            width: 40
                            height: 40
                            radius: 8
                            color: "#EFF6FF"

                            Text {
                                anchors.centerIn: parent
                                text: "📄"
                                font.pixelSize: 18
                            }
                        }

                        // 文件信息
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: model.name || "未知文件"
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                color: "#1F2937"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: {
                                        const progress = model.progress || 0
                                        if (progress >= 1.0)
                                            return "已完成"
                                        if (progress > 0)
                                            return `${Math.round(
                                                        progress * 100)}%`
                                        return "准备中"
                                    }
                                    font.pixelSize: 12
                                    color: "#6B7280"
                                }

                                Text {
                                    text: "•"
                                    font.pixelSize: 12
                                    color: "#D1D5DB"
                                }

                                Text {
                                    text: model.size || "未知大小"
                                    font.pixelSize: 12
                                    color: "#6B7280"
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: model.speed || "0 KB/s"
                                    font.pixelSize: 12
                                    color: "#6B7280"
                                }
                            }

                            // 进度条
                            Rectangle {
                                Layout.fillWidth: true
                                height: 4
                                radius: 2
                                color: "#F3F4F6"

                                Rectangle {
                                    width: parent.width * (model.progress || 0)
                                    height: parent.height
                                    radius: parent.radius
                                    color: {
                                        const progress = model.progress || 0
                                        if (progress >= 1.0)
                                            return "#10B981"
                                        if (model.status === "暂停")
                                            return "#F59E0B"
                                        if (model.status === "错误")
                                            return "#EF4444"
                                        return "#3B82F6"
                                    }
                                }
                            }
                        }

                        // 控制按钮
                        RowLayout {
                            spacing: 4
                            // 暂停/继续按钮
                            Button {
                                id: pauseButton
                                width: 32
                                height: 32
                                flat: true
                                visible: (model.progress || 0) < 1.0
                                         && model.status !== "错误"

                                background: Rectangle {
                                    color: pauseButton.hovered ? "#FEF3C7" : "transparent"
                                    radius: 6
                                }
                                contentItem: Text {
                                    text: model.status === "暂停" ? "▶" : "⏸"
                                    font.pixelSize: 12
                                    color: "#D97706"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: {
                                    if (model.status === "暂停") {
                                        downloadPanel.resumeDownload(
                                                    model.jobId)
                                        downloadPanel.downloadModel.setProperty(
                                                    index, "status", "下载中")
                                    } else {
                                        downloadPanel.pauseDownload(model.jobId)
                                        downloadPanel.downloadModel.setProperty(
                                                    index, "status", "暂停")
                                    }
                                }

                                ToolTip.visible: hovered
                                ToolTip.text: model.status === "暂停" ? "继续下载" : "暂停下载"
                            }
                            Item {
                                Layout.fillWidth: true // 占用剩余空间
                                Layout.alignment: Qt.AlignRight
                                Button {
                                    visible: model.needsRetry === true
                                    width: 28
                                    height: 28
                                    anchors {
                                        right: parent.right
                                        rightMargin: 10
                                        verticalCenter: parent.verticalCenter
                                    }
                                    contentItem: Text {
                                        text: "↻"
                                        font.pixelSize: 16
                                        color: "#FFFFFF"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    background: Rectangle {
                                        radius: 14
                                        color: parent.hovered ? "#E74C3C" : "#C0392B"
                                    }
                                    onClicked: {
                                        console.log("手动重试下载:", model.jobId)
                                        retryDownload(model.jobId)
                                    }
                                    ToolTip.visible: hovered
                                    ToolTip.text: "重试下载"
                                    ToolTip.delay: 500
                                }
                            }
                            // 删除按钮
                            Button {
                                id: deleteButton
                                width: 32
                                height: 32
                                flat: true

                                background: Rectangle {
                                    color: deleteButton.hovered ? "#FEE2E2" : "transparent"
                                    radius: 6

                                    // Behavior on color {
                                    //     ColorAnimation {
                                    //         duration: 150
                                    //     }
                                    // }
                                }

                                contentItem: Text {
                                    text: "🗑"
                                    font.pixelSize: 12
                                    color: "#DC2626"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                onClicked: {
                                    downloadPanel.cancelDownload(model.jobId)
                                    downloadPanel.downloadModel.remove(index)
                                }

                                ToolTip.visible: hovered
                                ToolTip.text: "删除任务"
                            }
                        }
                    }
                }
            }
        }
        // 底部操作栏
        Rectangle {
            Layout.fillWidth: true
            height: 48
            color: "#F8FAFC"
            radius: 12

            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: parent.radius
                color: parent.color
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: 12

                Button {
                    text: "全部暂停"
                    flat: true
                    font.pixelSize: 12

                    contentItem: Text {
                        text: parent.text
                        color: "#6B7280"
                        font.pixelSize: parent.font.pixelSize
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        color: parent.hovered ? "#F3F4F6" : "transparent"
                        radius: 6
                    }

                    onClicked: downloadPanel.pauseAllDownloads()
                }

                Rectangle {
                    width: 1
                    height: 16
                    color: "#E5E7EB"
                }

                Button {
                    text: "清空已完成"
                    flat: true
                    font.pixelSize: 12

                    contentItem: Text {
                        text: parent.text
                        color: "#6B7280"
                        font.pixelSize: parent.font.pixelSize
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        color: parent.hovered ? "#F3F4F6" : "transparent"
                        radius: 6
                    }

                    onClicked: downloadPanel.clearCompletedDownloads()
                }
            }
        }
    }

    // 下载控制函数
    function pauseDownload(jobId) {
        console.log("暂停下载:", jobId)
        ManagerGlobal.pauseDownload(jobId)
    }

    function resumeDownload(jobId) {
        console.log("继续下载:", jobId)
        ManagerGlobal.resumeDownload(jobId)
    }

    function cancelDownload(jobId) {
        console.log("取消下载:", jobId)
        ManagerGlobal.cancelDownload(jobId)
    }

    function pauseAllDownloads() {
        console.log("暂停所有下载")
        if (downloadModel) {
            for (var i = 0; i < downloadModel.count; i++) {
                const item = downloadModel.get(i)
                if (item && item.progress < 1 && item.status !== "暂停") {
                    pauseDownload(item.jobId)
                    downloadModel.setProperty(i, "status", "暂停")
                }
            }
        }
    }

    function clearCompletedDownloads() {
        console.log("清空已完成下载")
        if (downloadModel) {
            for (var i = downloadModel.count - 1; i >= 0; i--) {
                const item = downloadModel.get(i)
                if (item && item.progress >= 1) {
                    downloadModel.remove(i)
                }
            }
        }
    }
}
