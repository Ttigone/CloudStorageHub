import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../Component"

ScrollView {
    id: transferListView
    clip: true

    property var model: null
    property string transferType: "download" // "upload" | "download"
    property bool showActiveOnly: false
    property color accentColor: "#3498DB"

    signal transferPaused(string jobId)
    signal transferResumed(string jobId)
    signal transferCancelled(string jobId)

    ListView {
        id: listView
        model: transferListView.model
        spacing: 8

        delegate: Rectangle {
            width: listView.width
            radius: 8
            color: "#FFFFFF"
            border.color: "#E5E7EB"
            border.width: 1

            // 只显示活跃任务（如果设置了过滤）
            visible: !transferListView.showActiveOnly
                     || (model.progress < 1 && model.status !== "错误"
                         && model.status !== "已完成")
            height: visible ? 100 : 0

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                // 文件图标和进度环
                Item {
                    width: 60
                    height: 60

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: getFileTypeColor(model.name
                                                || model.fileName || "")

                        Text {
                            anchors.centerIn: parent
                            text: getFileTypeIcon(model.name
                                                  || model.fileName || "")
                            font.pixelSize: 24
                            color: "#FFFFFF"
                        }
                    }

                    // 进度环
                    Canvas {
                        anchors.fill: parent
                        anchors.margins: 2
                        visible: model.progress > 0 && model.progress < 1

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)

                            var centerX = width / 2
                            var centerY = height / 2
                            var radius = Math.min(width, height) / 2 - 3
                            var progress = model.progress || 0

                            // 背景圆圈
                            ctx.beginPath()
                            ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI)
                            ctx.lineWidth = 3
                            ctx.strokeStyle = "#E5E7EB"
                            ctx.stroke()

                            // 进度弧
                            if (progress > 0) {
                                ctx.beginPath()
                                ctx.arc(centerX, centerY, radius, -Math.PI / 2,
                                        -Math.PI / 2 + 2 * Math.PI * progress)
                                ctx.lineWidth = 3
                                ctx.strokeStyle = transferListView.accentColor
                                ctx.lineCap = "round"
                                ctx.stroke()
                            }
                        }

                        onProgressChanged: requestPaint()
                        property real progress: model.progress || 0
                        // onProgressChanged: requestPaint()
                    }

                    // 完成状态图标
                    Rectangle {
                        visible: model.progress >= 1.0 || model.status === "已完成"
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -2
                        anchors.rightMargin: -2
                        width: 18
                        height: 18
                        radius: 9
                        color: "#10B981"
                        border.color: "#FFFFFF"
                        border.width: 2

                        Text {
                            anchors.centerIn: parent
                            text: "✓"
                            font.pixelSize: 10
                            font.bold: true
                            color: "white"
                        }
                    }
                }

                // 文件信息
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text {
                        // text: model.name || model.fileName || "未知文件"
                text: {
                    if (transferListView.transferType === "upload") {
                        return model.fileName || "未知文件"
                    } else {
                        return model.name || model.fileName || "未知文件"
                    }
                }
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: "#1F2937"
                        elide: Text.ElideMiddle
                        Layout.fillWidth: true
                    }

                    // 进度条
                    TtProgressBar {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        progress: model.progress || 0
                        status: model.status || ""
                        radius: 3
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        Text {
                            text: formatFileSize(model.size)
                            font.pixelSize: 11
                            color: "#6B7280"
                        }

                        Text {
                            text: model.speed || "0 B/s"
                            font.pixelSize: 11
                            color: "#6B7280"
                        }

                        Text {
                            text: {
                                const progress = model.progress || 0
                                if (progress >= 1.0)
                                    return "已完成"
                                if (progress > 0)
                                    return Math.round(progress * 100) + "%"
                                return model.status || "准备中"
                            }
                            font.pixelSize: 11
                            color: getStatusColor(model.status).text
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Text {
                            text: formatTransferTime(model.startTime)
                            font.pixelSize: 11
                            color: "#9CA3AF"
                        }
                    }
                }

                // 操作按钮
                RowLayout {
                    spacing: 8

                    Button {
                        width: 32
                        height: 32
                        visible: model.progress > 0 && model.progress < 1

                        background: Rectangle {
                            radius: 16
                            color: parent.pressed ? "#F59E0B" : "#FEF3C7"
                            border.color: "#F59E0B"
                            border.width: 1
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
                                transferResumed(model.jobId)
                            } else {
                                transferPaused(model.jobId)
                            }
                        }

                        TtToolTip {
                            text: model.status === "暂停" ? "继续" : "暂停"
                        }
                    }

                    Button {
                        width: 32
                        height: 32

                        background: Rectangle {
                            radius: 16
                            color: parent.pressed ? "#EF4444" : "#FEE2E2"
                            border.color: "#EF4444"
                            border.width: 1
                        }

                        contentItem: Text {
                            text: "✕"
                            font.pixelSize: 12
                            color: "#DC2626"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            transferCancelled(model.jobId)
                        }

                        TtToolTip {
                            text: "取消"
                        }
                    }
                }
            }
        }

        // 空状态显示
Label {
    anchors.centerIn: parent
    text: {
        var typeText = transferListView.transferType === "upload" ? "上传" : "下载"
        if (transferListView.showActiveOnly) {
            return `暂无正在${typeText}的任务`
        } else {
            return `暂无${typeText}任务`
        }
    }
    color: "#9CA3AF"
    font.pixelSize: 16
    visible: !transferListView.model || transferListView.model.count === 0
}
    }

    // 工具函数
    function formatFileSize(bytes) {
        if (!bytes || bytes === "未知大小")
            return "未知大小"

        const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
        if (bytes === 0)
            return '0 B'

        const i = Math.floor(Math.log(bytes) / Math.log(1024))
        return Math.round(bytes / Math.pow(1024,
                                           i) * 100) / 100 + ' ' + sizes[i]
    }

    function formatTransferTime(timestamp) {
        if (!timestamp)
            return ""

        const now = new Date()
        const time = new Date(timestamp)
        const diff = now.getTime() - time.getTime()

        if (diff < 60000) {
            return "刚刚"
        } else if (diff < 3600000) {
            return Math.floor(diff / 60000) + "分钟前"
        } else if (diff < 86400000) {
            return Math.floor(diff / 3600000) + "小时前"
        } else {
            return time.toLocaleDateString()
        }
    }

    function getFileTypeColor(fileName) {
        const ext = fileName.split('.').pop().toLowerCase()
        switch (ext) {
        case 'jpg':
        case 'jpeg':
        case 'png':
        case 'gif':
        case 'bmp':
            return "#E74C3C"
        case 'pdf':
            return "#E74C3C"
        case 'doc':
        case 'docx':
            return "#3498DB"
        case 'xls':
        case 'xlsx':
            return "#27AE60"
        case 'ppt':
        case 'pptx':
            return "#F39C12"
        case 'zip':
        case 'rar':
        case '7z':
            return "#9B59B6"
        case 'mp3':
        case 'wav':
        case 'mp4':
        case 'avi':
            return "#1ABC9C"
        default:
            return "#95A5A6"
        }
    }

    function getFileTypeIcon(fileName) {
        const ext = fileName.split('.').pop().toLowerCase()
        switch (ext) {
        case 'jpg':
        case 'jpeg':
        case 'png':
        case 'gif':
        case 'bmp':
            return "🖼"
        case 'pdf':
            return "📄"
        case 'doc':
        case 'docx':
            return "📝"
        case 'xls':
        case 'xlsx':
            return "📊"
        case 'ppt':
        case 'pptx':
            return "📊"
        case 'zip':
        case 'rar':
        case '7z':
            return "📦"
        case 'mp3':
        case 'wav':
            return "🎵"
        case 'mp4':
        case 'avi':
            return "🎬"
        default:
            return "📄"
        }
    }

    function getStatusColor(status) {
        switch (status) {
        case "已完成":
            return {
                "text": "#059669"
            }
        case "下载中":
        case "上传中":
            return {
                "text": "#2563EB"
            }
        case "暂停":
            return {
                "text": "#D97706"
            }
        case "错误":
        case "超时":
            return {
                "text": "#DC2626"
            }
        default:
            return {
                "text": "#6B7280"
            }
        }
    }
}
