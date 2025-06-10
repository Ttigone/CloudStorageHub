import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import QtQuick.Dialogs

import "../Component"
import QWindowKit

Window {
    id: transferWindow
    title: "传输管理器"
    width: 720
    height: 600
    minimumWidth: 560
    minimumHeight: 400

    // 模型属性 - 统一管理上传和下载
    property var uploadModel: null
    property var downloadModel: null
    property var uploadHistoryModel: null
    property var downloadHistoryModel: null

    // 当前选项卡
    property int currentTab: 0 // 0:上传中, 1:上传历史, 2:下载中, 3:下载历史

    // 活动任务计数
    property int activeUploads: 0
    property int activeDownloads: 0

    signal transferPaused(string jobId, string type)
    // type: "upload" | "download"
    signal transferResumed(string jobId, string type)
    signal transferCancelled(string jobId, string type)
    signal transferRetried(string jobId, string type)
    signal historyItemRemoved(string jobId, string type)

    Component.onCompleted: {
        windowAgent.setup(transferWindow)
        windowAgent.setWindowAttribute("dark-mode", true)

        // 初始化模型（如果需要）
        if (!uploadModel) {
            uploadModel = Qt.createQmlObject('import QtQuick; ListModel {}',
                                             transferWindow)
        }
        if (!downloadModel) {
            downloadModel = Qt.createQmlObject('import QtQuick; ListModel {}',
                                               transferWindow)
        }
        if (!uploadHistoryModel) {
            uploadHistoryModel = Qt.createQmlObject(
                        'import QtQuick; ListModel {}', transferWindow)
        }
        if (!downloadHistoryModel) {
            downloadHistoryModel = Qt.createQmlObject(
                        'import QtQuick; ListModel {}', transferWindow)
        }
    }

    WindowAgent {
        id: windowAgent
    }

    QtObject {
        id: darkStyle
        readonly property color windowBackgroundColor: "#1E1E1E"
    }

    // FileDialog {
    //     id: fileLocationDialog
    //     title: "选择文件位置"
    //     fileMode: FileDialog.OpenFile
    //     onAccepted: {
    //         console.log("选择的文件:", selectedFile)
    //         Qt.openUrlExternally(selectedFile)
    //     }
    //     onRejected: {
    //         console.log("取消选择文件")
    //     }
    // }
    Item {
        anchors.fill: parent
        // TitleBar 区域
        Rectangle {
            id: titleBar
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: 50
            color: "#2C3E50"
            z: 100
            Component.onCompleted: windowAgent.setTitleBar(titleBar)

            Rectangle {
                id: dragIndicator
                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                    topMargin: 6
                }
                width: 48
                height: 4
                radius: 2
                color: "#3B82F6"
                opacity: 0.8

                // 改进的渐变效果
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: "#60A5FA"
                    }
                    GradientStop {
                        position: 0.5
                        color: "#3B82F6"
                    }
                    GradientStop {
                        position: 1.0
                        color: "#60A5FA"
                    }
                }

                // 增强的呼吸效果
                SequentialAnimation {
                    running: true
                    loops: Animation.Infinite

                    NumberAnimation {
                        target: dragIndicator
                        property: "opacity"
                        from: 0.3 // 更低的起始透明度
                        to: 1.0
                        duration: 1500 // 更快的动画
                        easing.type: Easing.InOutQuad
                    }

                    NumberAnimation {
                        target: dragIndicator
                        property: "opacity"
                        from: 1.0
                        to: 0.3 // 更低的结束透明度
                        duration: 1500
                        easing.type: Easing.InOutQuad
                    }
                }

                // 添加宽度呼吸效果，让效果更明显
                SequentialAnimation {
                    running: true
                    loops: Animation.Infinite

                    NumberAnimation {
                        target: dragIndicator
                        property: "width"
                        from: 48
                        to: 56 // 稍微变宽
                        duration: 1500
                        easing.type: Easing.InOutQuad
                    }

                    NumberAnimation {
                        target: dragIndicator
                        property: "width"
                        from: 56
                        to: 48
                        duration: 1500
                        easing.type: Easing.InOutQuad
                    }
                }

                // 添加颜色脉动效果
                SequentialAnimation {
                    running: true
                    loops: Animation.Infinite

                    ColorAnimation {
                        target: dragIndicator
                        property: "color"
                        from: "#3B82F6"
                        to: "#60A5FA"
                        duration: 1500
                        easing.type: Easing.InOutQuad
                    }

                    ColorAnimation {
                        target: dragIndicator
                        property: "color"
                        from: "#60A5FA"
                        to: "#3B82F6"
                        duration: 1500
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8

                // 标题文本
                Text {
                    text: "传输管理器"
                    color: "#FFFFFF"
                    font.pixelSize: 18
                    font.bold: true
                }

                // 关键修复：这个 Item 会填充剩余空间，把右侧内容推到右边
                Item {
                    Layout.fillWidth: true
                }

                // 统计信息 - 现在会被推到右边
                Row {
                    spacing: 24
                    Layout.alignment: Qt.AlignVCenter

                    Column {
                        spacing: 2
                        Text {
                            text: "正在上传"
                            color: "#BDC3C7"
                            font.pixelSize: 11
                        }
                        Text {
                            text: activeUploads.toString()
                            color: "#3498DB"
                            font.pixelSize: 16
                            font.bold: true
                        }
                    }

                    Column {
                        spacing: 2
                        Text {
                            text: "正在下载"
                            color: "#BDC3C7"
                            font.pixelSize: 11
                        }
                        Text {
                            text: activeDownloads.toString()
                            color: "#27AE60"
                            font.pixelSize: 16
                            font.bold: true
                        }
                    }
                }
            }
        }
        // 内容区域
        Rectangle {
            anchors {
                top: titleBar.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            color: "#F5F6FA"

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // 选项卡栏
                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    color: "#34495E"

                    Row {
                        anchors.fill: parent

                        TabButton {
                            width: transferWindow.width / 4
                            height: parent.height
                            text: `上传中 (${uploadModel ? uploadModel.count : 0})`
                            checked: currentTab === 0
                            onClicked: currentTab = 0

                            background: Rectangle {
                                color: parent.checked ? "#3498DB" : "transparent"
                                border.color: parent.checked ? "#2980B9" : "transparent"
                                border.width: parent.checked ? 2 : 0
                            }

                            contentItem: Text {
                                text: parent.text
                                color: parent.checked ? "#FFFFFF" : "#BDC3C7"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 14
                                font.bold: parent.checked
                            }
                        }

                        TabButton {
                            width: transferWindow.width / 4
                            height: parent.height
                            text: `上传历史 (${uploadHistoryModel ? uploadHistoryModel.count : 0})`
                            checked: currentTab === 1
                            onClicked: currentTab = 1

                            background: Rectangle {
                                color: parent.checked ? "#3498DB" : "transparent"
                                border.color: parent.checked ? "#2980B9" : "transparent"
                                border.width: parent.checked ? 2 : 0
                            }

                            contentItem: Text {
                                text: parent.text
                                color: parent.checked ? "#FFFFFF" : "#BDC3C7"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 14
                                font.bold: parent.checked
                            }
                        }

                        TabButton {
                            width: transferWindow.width / 4
                            height: parent.height
                            text: `下载中 (${downloadModel ? downloadModel.count : 0})`
                            checked: currentTab === 2
                            onClicked: currentTab = 2

                            background: Rectangle {
                                color: parent.checked ? "#27AE60" : "transparent"
                                border.color: parent.checked ? "#229954" : "transparent"
                                border.width: parent.checked ? 2 : 0
                            }

                            contentItem: Text {
                                text: parent.text
                                color: parent.checked ? "#FFFFFF" : "#BDC3C7"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 14
                                font.bold: parent.checked
                            }
                        }

                        TabButton {
                            width: transferWindow.width / 4
                            height: parent.height
                            text: `下载历史 (${downloadHistoryModel ? downloadHistoryModel.count : 0})`
                            checked: currentTab === 3
                            onClicked: currentTab = 3

                            background: Rectangle {
                                color: parent.checked ? "#27AE60" : "transparent"
                                border.color: parent.checked ? "#229954" : "transparent"
                                border.width: parent.checked ? 2 : 0
                            }

                            contentItem: Text {
                                text: parent.text
                                color: parent.checked ? "#FFFFFF" : "#BDC3C7"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 14
                                font.bold: parent.checked
                            }
                        }
                    }
                }

                // 内容区域
                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: currentTab

                    // 上传中
                    TransferListView {
                        transferType: "upload"
                        model: uploadModel
                        showActiveOnly: true
                        accentColor: "#3498DB"

                        onTransferPaused: function (jobId) {
                            transferWindow.transferPaused(jobId, "upload")
                        }
                        onTransferResumed: function (jobId) {
                            transferWindow.transferResumed(jobId, "upload")
                        }
                        onTransferCancelled: function (jobId) {
                            transferWindow.transferCancelled(jobId, "upload")
                        }
                    }

                    // 上传历史
                    TransferHistoryView {
                        transferType: "upload"
                        model: uploadHistoryModel
                        accentColor: "#3498DB"

                        onTransferRetried: function (jobId) {
                            transferWindow.transferRetried(jobId, "upload")
                        }
                        onHistoryItemRemoved: function (jobId) {
                            transferWindow.historyItemRemoved(jobId, "upload")
                        }
                        // // 信号接收不到
                        // onFileLocationOpened: function (filePath) {
                        //     // console.log("接收:", filePath)
                        //     // 这里可以添加打开文件夹的逻辑
                        // }
                    }

                    // 下载中
                    TransferListView {
                        transferType: "download"
                        model: downloadModel
                        showActiveOnly: true
                        accentColor: "#27AE60"

                        onTransferPaused: function (jobId) {
                            transferWindow.transferPaused(jobId, "download")
                        }
                        onTransferResumed: function (jobId) {
                            transferWindow.transferResumed(jobId, "download")
                        }
                        onTransferCancelled: function (jobId) {
                            transferWindow.transferCancelled(jobId, "download")
                        }
                    }

                    // 下载历史
                    TransferHistoryView {
                        transferType: "download"
                        model: downloadHistoryModel
                        accentColor: "#27AE60"

                        onTransferRetried: function (jobId) {
                            transferWindow.transferRetried(jobId, "download")
                        }
                        onHistoryItemRemoved: function (jobId) {
                            transferWindow.historyItemRemoved(jobId, "download")
                        }
                        // 关键：连接文件位置打开信号
                        onFileLocationOpened: function (localPath) {
                            console.log("TransferWindow 接收到打开文件位置信号:",
                                        localPath)
                            transferWindow.openFileLocation(localPath)
                        }
                    }
                }

                // 底部操作栏
                Rectangle {
                    Layout.fillWidth: true
                    height: 50
                    color: "#ECF0F1"
                    border.color: "#BDC3C7"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12

                        Button {
                            text: "暂停全部"
                            enabled: (currentTab === 0 && activeUploads > 0)
                                     || (currentTab === 2
                                         && activeDownloads > 0)
                            onClicked: pauseAllTransfers()

                            background: Rectangle {
                                color: parent.enabled ? (parent.pressed ? "#E67E22" : "#F39C12") : "#BDC3C7"
                                radius: 4
                            }

                            contentItem: Text {
                                text: parent.text
                                color: parent.enabled ? "#FFFFFF" : "#7F8C8D"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 12
                            }
                        }

                        Button {
                            text: "清理已完成"
                            enabled: currentTab === 1 || currentTab === 3
                            onClicked: clearCompletedTransfers()

                            background: Rectangle {
                                color: parent.enabled ? (parent.pressed ? "#C0392B" : "#E74C3C") : "#BDC3C7"
                                radius: 4
                            }

                            contentItem: Text {
                                text: parent.text
                                color: parent.enabled ? "#FFFFFF" : "#7F8C8D"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 12
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        // Button {
                        //     text: "设置"
                        //     onClicked: openTransferSettings()

                        //     background: Rectangle {
                        //         color: parent.pressed ? "#95A5A6" : "#BDC3C7"
                        //         radius: 4
                        //     }

                        //     contentItem: Text {
                        //         text: parent.text
                        //         color: "#2C3E50"
                        //         horizontalAlignment: Text.AlignHCenter
                        //         verticalAlignment: Text.AlignVCenter
                        //         font.pixelSize: 12
                        //     }
                        // }

                        Button {
                            text: "关闭"
                            onClicked: transferWindow.close()

                            background: Rectangle {
                                color: parent.pressed ? "#7F8C8D" : "#95A5A6"
                                radius: 4
                            }

                            contentItem: Text {
                                text: parent.text
                                color: "#FFFFFF"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 12
                            }
                        }
                    }
                }
            }
        }
    }

    // 工具函数
    function updateActiveUploads() {
        if (!uploadModel)
            return

        var count = 0
        for (var i = 0; i < uploadModel.count; i++) {
            var item = uploadModel.get(i)
            if (item && (item.status === "上传中" || item.status === "准备中")) {
                count++
            }
        }
        activeUploads = count
    }

    function updateActiveDownloads() {
        if (!downloadModel)
            return

        var count = 0
        for (var i = 0; i < downloadModel.count; i++) {
            var item = downloadModel.get(i)
            if (item && (item.status === "下载中" || item.status === "准备下载")) {
                count++
            }
        }
        activeDownloads = count
    }

    function pauseAllTransfers() {
        if (currentTab === 0 && uploadModel) {
            // 暂停所有上传
            for (var i = 0; i < uploadModel.count; i++) {
                var item = uploadModel.get(i)
                if (item && item.status === "上传中") {
                    transferPaused(item.jobId, "upload")
                }
            }
        } else if (currentTab === 2 && downloadModel) {
            // 暂停所有下载
            for (var i = 0; i < downloadModel.count; i++) {
                var item = downloadModel.get(i)
                if (item && item.status === "下载中") {
                    transferPaused(item.jobId, "download")
                }
            }
        }
    }

    function clearCompletedTransfers() {
        if (currentTab === 1 && uploadHistoryModel) {
            // 清理上传历史
            for (var i = uploadHistoryModel.count - 1; i >= 0; i--) {
                var item = uploadHistoryModel.get(i)
                if (item && item.status === "已完成") {
                    uploadHistoryModel.remove(i)
                }
            }
        } else if (currentTab === 3 && downloadHistoryModel) {
            // 清理下载历史
            for (var i = downloadHistoryModel.count - 1; i >= 0; i--) {
                var item = downloadHistoryModel.get(i)
                if (item && item.status === "已完成") {
                    downloadHistoryModel.remove(i)
                }
            }
        }
    }

    function openTransferSettings() {
        // 打开传输设置对话框
        console.log("打开传输设置")
    }

    // function openFileLocation(localPath, fileName) {
    function openFileLocation(localPath) {
        // console.log("打开文件位置:", localPath, fileName)
        console.log("传输窗口：尝试打开文件位置:", localPath)

        if (!localPath || localPath === "") {
            showMessage("文件路径不存在: " + fileName)
            fileLocationDialog.currentFolder = "file:///C:/" // 设置默认目录
            fileLocationDialog.open()
            return false
        }

        // 检查文件是否存在
        if (ManagerGlobal && ManagerGlobal.fileExists === "function") {
            if (!ManagerGlobal.fileExists(localPath)) {
                console.warn("文件不存在:", localPath)
                // showMessage("文件不存在: " + localPath)
                // 打开文件所在目录
                // var folderPath = localPath.substring(0,
                //                                      localPath.lastIndexOf('/'))
                // if (folderPath) {
                //     Qt.openUrlExternally("file:///" + folderPath.replace(/\\/g,
                //                                                          '/'))
                //     showMessage("已打开文件夹: " + folderPath)
                // }
                return false
            }
        } else {
            // 调用的都是这个方法
            var folderPath = localPath.substring(0, localPath.lastIndexOf('/'))
            if (folderPath) {
                Qt.openUrlExternally("file:///" + folderPath)
                // showMessage("已打开文件夹: " + folderPath)
            } else {
                console.warn("openFileLocation 方法不可用")
                // showMessage("无法打开文件位置")
            }
        }
    }

    // 定时更新活动任务计数
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            updateActiveUploads()
            updateActiveDownloads()
        }
    }
}
