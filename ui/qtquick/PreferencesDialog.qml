import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import QtQuick.Dialogs

import "./Component"

Window {
    id: preferencesDialog

    // 属性
    width: 800
    height: 580
    color: "#F5F6FA"
    title: qsTr("偏好设置")
    modality: Qt.ApplicationModal
    flags: Qt.Dialog

    // 用于设置初始值和跟踪是否有更改
    property bool hasUnsavedChanges: false

    // 信号
    signal settingsApplied

    // 属性和默认值
    property string currentTheme: "系统默认"
    property bool autoStartup: false
    property bool showNotifications: true
    property int maxUploadSpeed: 0 // 0表示不限制
    property int maxDownloadSpeed: 0 // 0表示不限制
    property string downloadPath: ""
    property bool autoUpdate: true
    property string language: "简体中文"

    // 覆盖窗口关闭事件
    onClosing: function (close) {
        if (hasUnsavedChanges) {
            close.accepted = false // 阻止默认关闭行为
            unsavedChangesDialog.open()
        }
    }

    // 主布局
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // 标题栏
        Rectangle {
            Layout.fillWidth: true
            height: 50
            color: "#2C3E50"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16

                Label {
                    text: qsTr("偏好设置")
                    font.pixelSize: 18
                    font.bold: true
                    color: "#FFFFFF"
                }
                Item {
                    Layout.fillWidth: true
                }
            }
        }
        TtSplitView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            orientation: Qt.Horizontal

            // 左侧导航
            Rectangle {
                SplitView.preferredWidth: 200
                SplitView.minimumWidth: 180
                SplitView.maximumWidth: 250
                color: "#ECEFF1"

                ListView {
                    id: settingsNav
                    anchors.fill: parent
                    model: [{
                            "name": qsTr("常规"),
                            "icon": "🔧"
                        }, {
                            "name": qsTr("外观"),
                            "icon": "🎨"
                        }, {
                            "name": qsTr("存储"),
                            "icon": "💾"
                        }, {
                            "name": qsTr("网络"),
                            "icon": "🌐"
                        }, {
                            "name": qsTr("更新"),
                            "icon": "↗️"
                        }, {
                            "name": qsTr("关于"),
                            "icon": "ℹ️"
                        }]
                    currentIndex: 0

                    delegate: ItemDelegate {
                        width: parent.width
                        height: 50
                        highlighted: ListView.isCurrentItem

                        background: Rectangle {
                            color: highlighted ? "#2980B9" : (hovered ? "#CFD8DC" : "transparent")
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            spacing: 12

                            Text {
                                text: modelData.icon
                                font.pixelSize: 18
                                color: highlighted ? "#FFFFFF" : "#455A64"
                            }

                            Label {
                                text: modelData.name
                                color: highlighted ? "#FFFFFF" : "#455A64"
                                font.pixelSize: 14
                            }
                        }

                        onClicked: {
                            settingsNav.currentIndex = index
                            settingsStack.currentIndex = index
                        }
                    }
                }
            }

            // 右侧设置内容
            Rectangle {
                SplitView.fillWidth: true
                color: "#FFFFFF"

                StackLayout {
                    id: settingsStack
                    anchors.fill: parent
                    anchors.margins: 20
                    currentIndex: settingsNav.currentIndex

                    // 1. 常规设置页
                    ColumnLayout {
                        spacing: 20

                        Label {
                            text: qsTr("常规设置")
                            font.pixelSize: 18
                            font.bold: true
                            color: "#263238"
                        }

                        Rectangle {
                            height: 1
                            Layout.fillWidth: true
                            color: "#E0E0E0"
                        }

                        // 语言设置
                        ColumnLayout {
                            spacing: 8

                            Label {
                                text: qsTr("语言")
                                font.pixelSize: 14
                                color: "#455A64"
                            }

                            ComboBox {
                                id: languageCombo
                                model: [qsTr("简体中文"), qsTr(
                                        "English"), qsTr("日本語")]
                                Layout.preferredWidth: 250
                                currentIndex: {
                                    if (preferencesDialog.language === "简体中文")
                                        return 0
                                    if (preferencesDialog.language === "English")
                                        return 1
                                    if (preferencesDialog.language === "日本語")
                                        return 2
                                    return 0
                                }
                                onActivated: {
                                    preferencesDialog.hasUnsavedChanges = true
                                    preferencesDialog.language = currentText
                                }
                            }
                        }

                        // 启动设置
                        CheckBox {
                            id: autoStartupCheck
                            text: qsTr("系统启动时自动运行")
                            checked: preferencesDialog.autoStartup
                            onToggled: {
                                preferencesDialog.hasUnsavedChanges = true
                                preferencesDialog.autoStartup = checked
                            }
                        }

                        // 通知设置
                        CheckBox {
                            id: notificationsCheck
                            text: qsTr("显示通知")
                            checked: preferencesDialog.showNotifications
                            onToggled: {
                                preferencesDialog.hasUnsavedChanges = true
                                preferencesDialog.showNotifications = checked
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                        }
                    }

                    // 2. 外观设置页
                    ColumnLayout {
                        spacing: 20

                        Label {
                            text: qsTr("外观设置")
                            font.pixelSize: 18
                            font.bold: true
                            color: "#263238"
                        }

                        Rectangle {
                            height: 1
                            Layout.fillWidth: true
                            color: "#E0E0E0"
                        }

                        // 主题设置
                        ColumnLayout {
                            spacing: 8

                            Label {
                                text: qsTr("主题")
                                font.pixelSize: 14
                                color: "#455A64"
                            }

                            ComboBox {
                                id: themeCombo
                                model: [qsTr("系统默认"), qsTr("浅色"), qsTr("深色")]
                                Layout.preferredWidth: 250
                                currentIndex: {
                                    if (preferencesDialog.currentTheme === "系统默认")
                                        return 0
                                    if (preferencesDialog.currentTheme === "浅色")
                                        return 1
                                    if (preferencesDialog.currentTheme === "深色")
                                        return 2
                                    return 0
                                }
                                onActivated: {
                                    preferencesDialog.hasUnsavedChanges = true
                                    preferencesDialog.currentTheme = currentText
                                }
                            }
                        }

                        // 主题预览
                        Rectangle {
                            Layout.fillWidth: true
                            height: 200
                            color: themeCombo.currentIndex === 2 ? "#263238" : "#F5F6FA"
                            border.color: "#E0E0E0"
                            border.width: 1
                            radius: 4

                            Label {
                                anchors.centerIn: parent
                                text: qsTr("主题预览")
                                color: themeCombo.currentIndex === 2 ? "#FFFFFF" : "#455A64"
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                        }
                    }

                    // 3. 存储设置页
                    ColumnLayout {
                        spacing: 20

                        Label {
                            text: qsTr("存储设置")
                            font.pixelSize: 18
                            font.bold: true
                            color: "#263238"
                        }

                        Rectangle {
                            height: 1
                            Layout.fillWidth: true
                            color: "#E0E0E0"
                        }
                        // 下载路径设置
                        ColumnLayout {
                            spacing: 8

                            Label {
                                text: qsTr("默认下载位置")
                                font.pixelSize: 14
                                color: "#455A64"
                            }

                            RowLayout {
                                TextField {
                                    id: downloadPathField
                                    Layout.preferredWidth: 350
                                    text: preferencesDialog.downloadPath
                                          || getDefaultDownloadDirectory()
                                    readOnly: true
                                    Component.onCompleted: {
                                        if (typeof ManagerGlobal.getDownloadDirectory
                                                === "function") {
                                            let currentPath = ManagerGlobal.getDownloadDirectory()
                                            if (currentPath
                                                    && currentPath !== "") {
                                                text = currentPath
                                                preferencesDialog.downloadPath = currentPath
                                            }
                                        }
                                    }
                                }
                                Button {
                                    text: qsTr("浏览...")
                                    onClicked: {
                                        folderDialog.currentFolder = downloadPathField.text
                                        folderDialog.open()
                                    }
                                }
                            }
                            Text {
                                text: qsTr("提示: 更改下载路径将影响新的下载任务")
                                font.pixelSize: 11
                                color: "#9CA3AF"
                                Layout.topMargin: 4
                            }
                        }

                        // 缓存管理
                        ColumnLayout {
                            spacing: 8

                            Label {
                                text: qsTr("缓存管理")
                                font.pixelSize: 14
                                color: "#455A64"
                            }

                            RowLayout {
                                Label {
                                    text: qsTr("当前缓存大小: 45.3 MB")
                                }

                                Button {
                                    text: qsTr("清除缓存")
                                    onClicked: {
                                        console.log("清除缓存")
                                    }
                                }
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                        }
                    }

                    ScrollView {
                        hoverEnabled: true
                        // 使用自定义滚动条
                        // contentHeight: 200
                        // contentWidth: 500
                        // ScrollBar.vertical: TtScrollBar {
                        //     parent: tableScrollView
                        // }

                        // ScrollBar.horizontal: TtScrollBar {
                        //     parent: tableScrollView
                        //     orientation: Qt.Horizontal
                        // }

                        // 4. 网络设置页
                        ColumnLayout {
                            spacing: 20

                            Label {
                                text: qsTr("网络设置")
                                font.pixelSize: 18
                                font.bold: true
                                color: "#263238"
                            }

                            Rectangle {
                                height: 1
                                Layout.fillWidth: true
                                color: "#E0E0E0"
                            }

                            // 上传速度限制
                            ColumnLayout {
                                spacing: 8

                                Label {
                                    text: qsTr("上传速度限制 (KB/s，0表示不限制)")
                                    font.pixelSize: 14
                                    color: "#455A64"
                                }

                                SpinBox {
                                    id: uploadSpeedSpin
                                    from: 0
                                    to: 10000
                                    stepSize: 50
                                    value: preferencesDialog.maxUploadSpeed
                                    onValueChanged: {
                                        if (value !== preferencesDialog.maxUploadSpeed) {
                                            preferencesDialog.hasUnsavedChanges = true
                                            preferencesDialog.maxUploadSpeed = value
                                        }
                                    }
                                }
                            }

                            // 下载速度限制
                            ColumnLayout {
                                spacing: 8

                                Label {
                                    text: qsTr("下载速度限制 (KB/s，0表示不限制)")
                                    font.pixelSize: 14
                                    color: "#455A64"
                                }

                                SpinBox {
                                    id: downloadSpeedSpin
                                    from: 0
                                    to: 10000
                                    stepSize: 50
                                    value: preferencesDialog.maxDownloadSpeed
                                    onValueChanged: {
                                        if (value !== preferencesDialog.maxDownloadSpeed) {
                                            preferencesDialog.hasUnsavedChanges = true
                                            preferencesDialog.maxDownloadSpeed = value
                                        }
                                    }
                                }
                            }

                            // 代理设置
                            ColumnLayout {
                                spacing: 8

                                Label {
                                    text: qsTr("代理设置")
                                    font.pixelSize: 14
                                    color: "#455A64"
                                }

                                ComboBox {
                                    id: proxyTypeCombo
                                    model: [qsTr("不使用代理"), qsTr("HTTP代理"), qsTr(
                                            "SOCKS5代理")]
                                    Layout.preferredWidth: 250
                                }

                                GridLayout {
                                    columns: 2
                                    enabled: proxyTypeCombo.currentIndex > 0
                                    opacity: enabled ? 1.0 : 0.5

                                    Label {
                                        text: qsTr("服务器:")
                                    }
                                    TextField {
                                        Layout.preferredWidth: 250
                                    }

                                    Label {
                                        text: qsTr("端口:")
                                    }
                                    TextField {
                                        Layout.preferredWidth: 100
                                    }

                                    Label {
                                        text: qsTr("用户名:")
                                    }
                                    TextField {
                                        Layout.preferredWidth: 250
                                    }

                                    Label {
                                        text: qsTr("密码:")
                                    }
                                    TextField {
                                        Layout.preferredWidth: 250
                                        echoMode: TextInput.Password
                                    }
                                }
                            }

                            Item {
                                Layout.fillHeight: true
                                height: 20 // 底部额外空间
                            }
                        }
                    }

                    // 5. 更新设置页
                    ColumnLayout {
                        spacing: 20

                        Label {
                            text: qsTr("更新设置")
                            font.pixelSize: 18
                            font.bold: true
                            color: "#263238"
                        }

                        Rectangle {
                            height: 1
                            Layout.fillWidth: true
                            color: "#E0E0E0"
                        }

                        // 自动更新
                        CheckBox {
                            id: autoUpdateCheck
                            text: qsTr("自动检查更新")
                            checked: preferencesDialog.autoUpdate
                            onToggled: {
                                preferencesDialog.hasUnsavedChanges = true
                                preferencesDialog.autoUpdate = checked
                            }
                        }

                        // 当前版本
                        RowLayout {
                            Label {
                                text: qsTr("当前版本:")
                                font.pixelSize: 14
                                color: "#455A64"
                            }

                            Label {
                                text: "1.0.0"
                                font.pixelSize: 14
                                color: "#455A64"
                            }
                        }

                        // 检查更新按钮
                        Button {
                            text: qsTr("立即检查更新")
                            onClicked: {
                                console.log("检查更新")
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                        }
                    }

                    // 6. 关于页
                    ColumnLayout {
                        spacing: 20

                        Label {
                            text: qsTr("关于")
                            font.pixelSize: 18
                            font.bold: true
                            color: "#263238"
                        }

                        Rectangle {
                            height: 1
                            Layout.fillWidth: true
                            color: "#E0E0E0"
                        }

                        // 应用信息
                        ColumnLayout {
                            spacing: 8

                            Text {
                                text: "Cloud Storage Hub"
                                font.pixelSize: 24
                                font.bold: true
                                color: "#2980B9"
                            }

                            Text {
                                text: qsTr("版本: 1.0.0")
                                font.pixelSize: 14
                                color: "#455A64"
                            }

                            Text {
                                text: qsTr("© 2025 Cloud Storage Hub Team")
                                font.pixelSize: 14
                                color: "#455A64"
                            }

                            Item {
                                height: 20
                            }

                            Text {
                                text: qsTr("Cloud Storage Hub 是一个功能强大的云存储管理工具，支持多种云存储服务，提供统一的文件管理体验。")
                                wrapMode: Text.WordWrap
                                Layout.maximumWidth: parent.width
                                font.pixelSize: 14
                                color: "#455A64"
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                        }
                    }
                }
            }
        }

        // 底部按钮区
        Rectangle {
            Layout.fillWidth: true
            height: 60
            color: "#ECEFF1"

            RowLayout {
                anchors {
                    right: parent.right
                    rightMargin: 16
                    verticalCenter: parent.verticalCenter
                }
                spacing: 10

                Button {
                    text: qsTr("重置")
                    onClicked: {
                        resetSettings()
                    }
                }

                Button {
                    text: qsTr("取消")
                    onClicked: {
                        if (hasUnsavedChanges) {
                            unsavedChangesDialog.open()
                        } else {
                            preferencesDialog.close()
                        }
                    }
                }

                Button {
                    text: qsTr("应用")
                    enabled: hasUnsavedChanges
                    onClicked: {
                        applySettings()
                    }
                }

                Button {
                    text: qsTr("确定")
                    highlighted: true
                    onClicked: {
                        if (hasUnsavedChanges) {
                            applySettings()
                        }
                        preferencesDialog.close()
                    }
                }
            }
        }
    }

    // 未保存更改对话框
    Dialog {
        id: unsavedChangesDialog
        title: qsTr("未保存的更改")
        standardButtons: Dialog.Discard | Dialog.Cancel | Dialog.Save
        modal: true
        x: (preferencesDialog.width - width) / 2
        y: (preferencesDialog.height - height) / 2

        Label {
            text: qsTr("您有未保存的设置更改，是否保存？")
        }

        onAccepted: {
            applySettings()
            preferencesDialog.close()
        }

        onDiscarded: {
            preferencesDialog.close()
        }
    }

    // 应用设置
    function applySettings() {
        console.log("应用设置:")
        console.log("- 主题:", currentTheme)
        console.log("- 语言:", language)
        console.log("- 自动启动:", autoStartup)
        console.log("- 显示通知:", showNotifications)
        console.log("- 最大上传速度:", maxUploadSpeed)
        console.log("- 最大下载速度:", maxDownloadSpeed)
        console.log("- 下载路径:", downloadPath)
        console.log("- 自动更新:", autoUpdate)

        // 发出信号通知设置已应用
        settingsApplied()

        // 重置更改状态
        hasUnsavedChanges = false
    }

    // 重置设置
    function resetSettings() {
        // 将所有设置重置为默认值
        currentTheme = "系统默认"
        autoStartup = false
        showNotifications = true
        maxUploadSpeed = 0
        maxDownloadSpeed = 0
        downloadPath = ""
        autoUpdate = true
        language = "简体中文"

        // 更新 UI 组件以反映默认值
        themeCombo.currentIndex = 0
        autoStartupCheck.checked = false
        notificationsCheck.checked = true
        uploadSpeedSpin.value = 0
        downloadSpeedSpin.value = 0
        downloadPathField.text = qsTr("未设置")
        autoUpdateCheck.checked = true
        languageCombo.currentIndex = 0

        hasUnsavedChanges = true
    }

    FolderDialog {
        id: folderDialog
        title: qsTr("选择下载保存位置")
        // currentFolder:
        onAccepted: {
            let selectedPath = folderDialog.selectedFolder.toString()
            // 移除 file:// 前缀
            if (selectedPath.startsWith("file://")) {
                selectedPath = selectedPath.substring(7)

                // 在 Windows 上去掉第一个斜杠
                if (Qt.platform.os === "windows"
                        && selectedPath.startsWith("/")) {
                    selectedPath = selectedPath.substring(1)
                }
            }

            downloadPathField.text = selectedPath
            preferencesDialog.downloadPath = selectedPath
            preferencesDialog.hasUnsavedChanges = true

            console.log("选择了下载目录:", selectedPath)
        }
    }

    // 添加获取默认下载路径的函数
    function getDefaultDownloadPath() {
        if (typeof ManagerGlobal.getDefaultDownloadDirectory === "function") {
            return ManagerGlobal.getDefaultDownloadDirectory()
        }
        return "./downloads"
    }
}
