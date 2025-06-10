import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls.Basic
import Qt.labs.platform 1.1
import Qt5Compat.GraphicalEffects
import QWindowKit
import "./Component"

Window {
    id: dialog
    property bool showWhenReady: true
    property var loginNames: []
    color: darkStyle.windowBackgroundColor
    width: 420
    height: 580
    title: "登录窗口"
    visible: false
    flags: Qt.Dialog
    modality: Qt.ApplicationModal

    signal loginSuccess
    signal cancelled

    Component.onCompleted: {
        windowAgent.setup(dialog)
        windowAgent.setWindowAttribute("dark-mode", true)
        // 从数据库获取登录名列表
        dialog.loginNames = ManagerGlobal.getLoginNameList()
        // 只有用户名
        console.log("从数据库加载了 " + loginNames.length + " 个登录名")

        // ManagerGlobal.getLoginInfoByName()
        if (dialog.showWhenReady) {
            dialog.visible = true
        }
        // 初始化成功后, 链接信号
        ManagerGlobal.connectLoginSignals()

        ManagerGlobal.loginSuccess.connect(function () {
            console.log("qml 接受到成功登录的信号")
        })
    }

    // 在 Window 组件中添加信号连接
    Connections {
        target: ManagerGlobal
        function onLoginSuccess() {
            console.log("登录成功！")
            loginButton.isLogging = false
            loginButton.enabled = true
            // 保存登录信息到数据库
            ManagerGlobal.saveLoginInfo(loginName.text.trim(),
                                        secretId.text.trim(),
                                        secretKey.text.trim(),
                                        backup.text.trim())
            dialog.loginSuccess()
            dialog.close()
        }

        function onLoginFailed(errorMessage) {
            loginButton.isLogging = false
            loginButton.enabled = true

            console.log("登录失败")
            notification.show(errorMessage, "warning", 2000)
        }
    }

    // 获取登录历史列表
    function getLoginHistory() {
        try {
            var nameList = ManagerGlobal.getLoginNameList()
            console.log("获取到的登录历史:", nameList)
            return nameList || []
        } catch (e) {
            console.error("获取登录历史失败:", e)
            return []
        }
    }

    // 根据登录名填充登录信息
    function fillLoginInfo(name) {
        if (!name || name.length === 0) {
            console.warn("登录名为空，无法填充信息")
            return
        }

        try {
            console.log("开始填充登录信息，用户名:", name)
            var loginInfo = ManagerGlobal.getLoginInfoByName(name)

            // 能否获取到信息
            console.log("获取到的登录信息:", JSON.stringify(loginInfo))

            // 只有备足填充
            if (loginInfo && typeof loginInfo === 'object') {
                // 填充 Secret ID
                if (loginInfo.secret_id) {
                    secretId.text = loginInfo.secret_id || ""
                    console.log("填充 Secret ID:", secretId.text)
                }
                // 填充 Secret Key
                if (loginInfo.secret_key) {
                    secretKey.text = loginInfo.secret_key || ""
                    console.log("填充 Secret Key: [已隐藏]")
                }
                // 填充备注
                if (loginInfo.remark) {
                    backup.text = loginInfo.remark || ""
                    console.log("填充备注:", backup.text)
                }
            } else {
                console.warn("未找到用户登录信息:", name)
                showNoDataIndicator()
            }
        } catch (e) {
            console.error("填充登录信息时发生错误:", e)
            showErrorIndicator("加载历史信息失败")
        }
    }
    // 显示无数据指示器
    function showNoDataIndicator() {
        fillIndicator.text = "⚠ 未找到该用户的历史信息"
        fillIndicator.color = "#FF9800"
        fillIndicator.visible = true
        fillIndicatorTimer.restart()
    }
    // 显示错误指示器
    function showErrorIndicator(message) {
        fillIndicator.text = "✗ " + message
        fillIndicator.color = "#F44336"
        fillIndicator.visible = true
        fillIndicatorTimer.restart()
    }
    // 清空所有输入框
    function clearAllFields() {
        loginName.text = ""
        secretId.text = ""
        secretKey.text = ""
        backup.text = ""
        fillIndicator.visible = false
    }

    // 刷新登录历史
    function refreshLoginHistory() {
        if (loginName) {
            loginName.historyModel = getLoginHistory()
        }
    }

    // 自动填充延迟定时器
    Timer {
        id: autoFillTimer
        interval: 500
        repeat: false
        onTriggered: {
            if (loginName.text.length > 0) {
                var historyList = getLoginHistory()
                if (historyList.indexOf(loginName.text) !== -1) {
                    fillLoginInfo(loginName.text)
                }
            }
        }
    }

    WindowAgent {
        id: windowAgent
    }

    QtObject {
        id: darkStyle
        readonly property color windowBackgroundColor: "#1E1E1E"
    }

    // 主容器，确保留出 titleBar 的空间
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
            height: 32
            color: "#2C2C2C" // 给标题栏一个可见的颜色
            z: 100 // 确保标题栏在最上层

            Component.onCompleted: windowAgent.setTitleBar(titleBar)

            Image {
                id: iconButton
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: 10
                }
                width: 18
                height: 18
                mipmap: true
                source: "qrc:/resources/app/storage.png"
                fillMode: Image.PreserveAspectFit
                Component.onCompleted: windowAgent.setSystemButton(
                                           WindowAgent.WindowIcon, iconButton)
            }

            Text {
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: iconButton.right
                    leftMargin: 10
                }
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: dialog.title
                font.pixelSize: 14
                color: "#ECECEC"
            }

            Row {
                anchors {
                    top: parent.top
                    right: parent.right
                }
                height: parent.height

                QWKButton {
                    id: minButton
                    height: parent.height
                    source: "qrc:/resources/window-bar/minimize.svg"
                    onClicked: dialog.showMinimized()
                    Component.onCompleted: windowAgent.setSystemButton(
                                               WindowAgent.Minimize, minButton)
                }

                QWKButton {
                    id: closeDialogButton
                    height: parent.height
                    source: "qrc:/resources/window-bar/close.svg"
                    background: Rectangle {
                        color: {
                            if (!closeDialogButton.enabled) {
                                return "gray"
                            }
                            if (closeDialogButton.pressed) {
                                return "#e81123"
                            }
                            if (closeDialogButton.hovered) {
                                return "#e81123"
                            }
                            return "transparent"
                        }
                    }
                    onClicked: {
                        canceled()
                        dialog.close()
                    }
                    Component.onCompleted: windowAgent.setSystemButton(
                                               WindowAgent.Close,
                                               closeDialogButton)
                }
            }
        }
        // 内容区域 - 注意它从标题栏下方开始
        Rectangle {
            anchors {
                top: titleBar.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            color: "#2D2D30" // 深色背景

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 20
                }
                spacing: 8
                Label {
                    text: "Cloud Storage Hub"
                    font.pixelSize: 22
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 5
                    Layout.bottomMargin: 10
                    color: "#ECECEC"
                }
                Label {
                    text: qsTr("登录名")
                    font.pixelSize: 14
                    color: "#CCCCCC"
                    Layout.topMargin: 4
                }
                HistoryTextField {
                    id: loginName
                    Layout.fillWidth: true
                    placeholderText: qsTr("请输入用户登录名")
                    height: 40
                    selectByMouse: true
                    echoMode: TextInput.Normal
                    color: "#FFFFFF"
                    placeholderTextColor: "#8A8A8A" // 更亮的灰色，提高对比度
                    background: Rectangle {
                        radius: 4
                        color: "#3E3E42"
                        border.color: loginName.focus ? "#3498db" : "#555555"
                        border.width: 1
                    }
                    // 列表作为历史记录模型
                    // 历史记录
                    historyModel: {
                        // 获取是空的
                        console.log("历史记录: ", dialog.loginNames)
                        // return dialog.loginNames
                        return getLoginHistory()
                    }
                    // 连接删除历史记录信号
                    onRequestRemoveHistory: function (value) {// 删除 db 历史记录
                        // configManager.removeFromHistory(value)
                    }
                    // 修改 historyItemSelected 处理逻辑
                    onHistoryItemSelected: function (value) {
                        try {
                            // 选择无效
                            fillLoginInfo(value)
                            // 填充信息
                            console.log("已自动填充用户 " + value + " 的登录信息")
                        } catch (e) {
                            console.error("加载登录信息失败:", e)
                        }
                    }
                    // 添加文本变化处理
                    onTextChanged: {
                        // 是这里不全的
                        // var historyList = getLoginHistory()
                        // if (historyList.indexOf(text) !== -1) {
                        //     // if (loginName.text.length > 0) {
                        //     //     var historyList1 = getLoginHistory()
                        //     //     if (historyList1.indexOf(
                        //     //                 loginName.text) !== -1) {
                        //     //         fillLoginInfo(loginName.text)
                        //     //     }
                        //     // }
                        //     // 延迟填充，避免在用户还在输入时干扰
                        //     autoFillTimer.restart()
                        // }
                    }
                }
                // 在登录名输入框下方添加状态指示器
                Text {
                    id: fillIndicator
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20

                    visible: false
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: "#4CAF50"
                    text: ""

                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter

                    // 自动隐藏定时器
                    Timer {
                        id: fillIndicatorTimer
                        interval: 3000
                        repeat: false
                        onTriggered: {
                            fillIndicator.visible = false
                        }
                    }

                    // 淡入淡出动画
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }

                    opacity: visible ? 1.0 : 0.0
                }
                Label {
                    text: qsTr("SecretId")
                    font.pixelSize: 14
                    color: "#CCCCCC"
                }
                TextField {
                    id: secretId
                    Layout.fillWidth: true
                    placeholderText: qsTr("请输入 API ID")
                    height: 40
                    selectByMouse: true
                    echoMode: TextInput.Normal
                    color: "#FFFFFF"
                    text: ""
                    placeholderTextColor: "#8A8A8A" // 更亮的灰色，提高对比度
                    background: Rectangle {
                        radius: 4
                        color: "#3E3E42"
                        border.color: secretId.focus ? "#3498db" : "#555555"
                        border.width: 1
                    }
                }
                // SecretKey
                Label {
                    text: qsTr("SecretKey")
                    font.pixelSize: 14
                    color: "#CCCCCC"
                    Layout.topMargin: 4
                }
                TextField {
                    id: secretKey
                    placeholderText: qsTr("请输入 API SecretKey")
                    Layout.fillWidth: true
                    height: 40
                    selectByMouse: true
                    echoMode: TextInput.Password
                    color: "#FFFFFF"
                    placeholderTextColor: "#8A8A8A" // 更亮的灰色，提高对比度
                    text: ""
                    background: Rectangle {
                        radius: 4
                        color: "#3E3E42"
                        border.color: secretKey.focus ? "#3498db" : "#555555"
                        border.width: 1
                    }
                }
                // 备注
                Label {
                    text: qsTr("备注")
                    font.pixelSize: 14
                    color: "#CCCCCC"
                    Layout.topMargin: 4
                }
                // 备足不需要对应的 popup
                TextField {
                    id: backup
                    placeholderText: qsTr("非必填，添加备注名，用于账号管理")
                    Layout.fillWidth: true
                    height: 40
                    selectByMouse: true
                    color: "#FFFFFF"
                    placeholderTextColor: "#8A8A8A" // 更亮的灰色，提高对比度
                    background: Rectangle {
                        radius: 4
                        color: "#3E3E42"
                        border.color: backup.focus ? "#3498db" : "#555555"
                        border.width: 1
                    }
                }

                // 记住会话
                CheckBox {
                    id: rememberSession
                    text: qsTr("记住会话")
                    Layout.topMargin: 8
                    // 使用内容项自定义文本颜色
                    contentItem: Text {
                        text: rememberSession.text
                        font: rememberSession.font
                        color: "#CCCCCC"
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: rememberSession.indicator.width + rememberSession.spacing
                    }

                    // 自定义指示器颜色
                    indicator: Rectangle {
                        implicitWidth: 20
                        implicitHeight: 20
                        x: rememberSession.leftPadding
                        y: parent.height / 2 - height / 2
                        radius: 3
                        border.color: rememberSession.checked ? "#3498db" : "#555555"
                        color: rememberSession.checked ? "#3498db" : "#3E3E42"

                        Rectangle {
                            width: 12
                            height: 12
                            anchors.centerIn: parent
                            radius: 2
                            color: "#FFFFFF"
                            visible: rememberSession.checked
                        }
                    }
                }

                // 登录按钮
                Button {
                    id: loginButton
                    text: "登录"
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    Layout.preferredHeight: 40

                    property bool isLogging: false

                    palette {
                        button: "#2980b9"
                        buttonText: "white"
                    }
                    font.pixelSize: 16

                    // 登录状态指示器
                    BusyIndicator {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 20
                        height: 20
                        visible: loginButton.isLogging
                        running: loginButton.isLogging
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (secretId.text.trim() === "") {
                                // console.error("SecretId不能为空")
                                // toastNotification.showToast("SecretId 不能为空")
                                notification.show("SecretId 不能为空")
                                return
                            }
                            if (secretKey.text.trim() === "") {
                                // console.error("SecretKey不能为空")
                                // toastNotification.showToast("SecretKey 不能为空")
                                notification.show("SecretKey 不能为空")
                                return
                            }
                            // 禁用按钮防止重复点击
                            loginButton.isLogging = true
                            loginButton.enabled = false

                            console.log("正在尝试登录:")
                            // 在 LoginDialog.qml 的登录按钮 onClicked 中
                            ManagerGlobal.login(secretId.text, secretKey.text,
                                                loginName.text
                                                || secretId.text, backup.text)
                            // 保存配置
                            // configManager.secretId = secretId.text
                            // configManager.secretKey = secretKey.text
                            // console.log("保存 key: ", configManager.secretKey)
                            // configManager.remark = backup.text
                            // configManager.rememberSession = rememberSession.checked
                            // configManager.saveLoginConfig()
                        }
                    }
                }
                // 填充空间
                Item {
                    Layout.fillHeight: true
                    Layout.minimumHeight: 1 // 减少最小高度
                    Layout.maximumHeight: 9999 // 增加最大高度，让它更灵活
                    Layout.preferredHeight: 10 // 给一个合理的默认高度
                    Layout.fillWidth: true // 确保水平填充
                    Layout.preferredWidth: 5 // 防止宽度计算问题
                }

                // 底部版权信息
                Text {
                    text: "© 2025 Cloud Storage Hub"
                    font.pixelSize: 12
                    color: "#7f8c8d"
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 10
                    Layout.preferredHeight: implicitHeight // 添加这行确保高度计算正确
                    Layout.minimumHeight: implicitHeight // 添加这行确保至少有文本需要的高度
                }
            }
        }
        TtNotification {
            id: notification
            anchors.fill: parent
            onClicked: {
                console.log("通知被点击")
            }

            onClosed: {
                console.log("通知已关闭")
            }
        }
    }
}
