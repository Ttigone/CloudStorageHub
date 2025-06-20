////filepath: f:\MyProject\CloudStorageHub\ui\qtquick\Component\DownloadListView.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: downloadListView
    clip: true

    property var model: null
    property bool showActiveOnly: false

    signal pauseDownload(string jobId)
    signal resumeDownload(string jobId)
    signal cancelDownload(string jobId)

    ListView {
        id: listView
        model: downloadListView.model
        spacing: 8

        delegate: Rectangle {
            width: listView.width
            // height: 80
            radius: 8
            color: "#FFFFFF"
            border.color: "#E5E7EB"
            border.width: 1

            // 只显示活跃任务（如果设置了过滤）
            visible: !downloadListView.showActiveOnly
                     || (model.progress < 1 && model.status !== "错误"
                         && model.status !== "已完成")
            height: visible ? 80 : 0

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                // 文件图标
                Rectangle {
                    width: 48
                    height: 48
                    radius: 8
                    color: "#EFF6FF"

                    Text {
                        anchors.centerIn: parent
                        text: "📄"
                        font.pixelSize: 24
                    }
                }

                // 文件信息
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: model.name || "未知文件"
                        font.pixelSize: 16
                        font.weight: Font.Medium
                        color: "#1F2937"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Text {
                            text: {
                                const progress = model.progress || 0
                                if (progress >= 1.0)
                                    return "已完成"
                                if (progress > 0)
                                    return `${Math.round(progress * 100)}%`
                                return "准备中"
                            }
                            font.pixelSize: 14
                            color: "#3B82F6"
                            font.weight: Font.Medium
                        }

                        Text {
                            text: model.size || "未知大小"
                            font.pixelSize: 14
                            color: "#6B7280"
                        }

                        Text {
                            text: model.speed || "0 KB/s"
                            font.pixelSize: 14
                            color: "#6B7280"
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Text {
                            text: formatDownloadTime(model.startTime)
                            font.pixelSize: 12
                            color: "#9CA3AF"
                        }
                    }

                    // 进度条
                    Rectangle {
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
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

                            Behavior on width {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }

                // 操作按钮
                RowLayout {
                    spacing: 8

                    Button {
                        width: 36
                        height: 36
                        flat: true
                        visible: (model.progress || 0) < 1.0
                                 && model.status !== "错误"

                        background: Rectangle {
                            color: parent.hovered ? "#FEF3C7" : "transparent"
                            radius: 18
                        }

                        contentItem: Text {
                            text: model.status === "暂停" ? "▶" : "⏸"
                            font.pixelSize: 14
                            color: "#D97706"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            if (model.status === "暂停") {
                                downloadListView.resumeDownload(model.jobId)
                            } else {
                                downloadListView.pauseDownload(model.jobId)
                            }
                        }

                        ToolTip.visible: hovered
                        ToolTip.text: model.status === "暂停" ? "继续下载" : "暂停下载"
                    }

                    Button {
                        width: 36
                        height: 36
                        flat: true

                        background: Rectangle {
                            color: parent.hovered ? "#FEE2E2" : "transparent"
                            radius: 18
                        }

                        contentItem: Text {
                            text: "×"
                            font.pixelSize: 16
                            color: "#DC2626"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: downloadListView.cancelDownload(model.jobId)

                        ToolTip.visible: hovered
                        ToolTip.text: "取消下载"
                    }
                }
            }
        }

        // 空状态
        Label {
            anchors.centerIn: parent
            text: downloadListView.showActiveOnly ? "暂无正在下载的任务" : "暂无下载任务"
            color: "#9CA3AF"
            font.pixelSize: 16
            visible: listView.count === 0
        }
    }

    function formatDownloadTime(timestamp) {
        if (!timestamp)
            return ""

        const now = new Date()
        const time = new Date(timestamp)
        const diff = now.getTime() - time.getTime()

        if (diff < 60000) {
            // 1分钟内
            return "刚刚"
        } else if (diff < 3600000) {
            // 1小时内
            return Math.floor(diff / 60000) + "分钟前"
        } else if (diff < 86400000) {
            // 24小时内
            return Math.floor(diff / 3600000) + "小时前"
        } else {
            return time.toLocaleDateString()
        }
    }
}
