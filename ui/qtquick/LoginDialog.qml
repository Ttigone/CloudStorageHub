import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls.Basic
import Qt.labs.platform 1.1
import CloudStorageHub 1.0
// import QtGraphicalEffects 1.15  // 添加这行用于DropShadow
import Qt5Compat.GraphicalEffects
import QWindowKit
import "./Component"

Window {
    id: dialog
    property bool showWhenReady: true
    color: darkStyle.windowBackgroundColor
    width: 420
    height: 580
    title: "登录窗口"
    visible: false
    flags: Qt.Dialog
    modality: Qt.ApplicationModal
    signal loginSuccess

    // 添加属性用于存储 TDB 提供的登录名列表
    property var loginNames: []

    Component.onCompleted: {
        windowAgent.setup(dialog)
        windowAgent.setWindowAttribute("dark-mode", true)
        if (dialog.showWhenReady) {
            dialog.visible = true
        }
        // 从数据库获取登录名列表
        loginNames = TtDB.loginNameList
        console.log("从数据库加载了 " + loginNames.length + " 个登录名")
        if (dialog.showWhenReady) {
            dialog.visible = true
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
                    id: closeButton
                    height: parent.height
                    source: "qrc:/resources/window-bar/close.svg"
                    background: Rectangle {
                        color: {
                            if (!closeButton.enabled) {
                                return "gray"
                            }
                            if (closeButton.pressed) {
                                return "#e81123"
                            }
                            if (closeButton.hovered) {
                                return "#e81123"
                            }
                            return "transparent"
                        }
                    }
                    onClicked: dialog.close()
                    Component.onCompleted: windowAgent.setSystemButton(
                                               WindowAgent.Close, closeButton)
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

                // 标题
                Label {
                    text: "Cloud Storage Hub"
                    font.pixelSize: 22
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 5
                    Layout.bottomMargin: 10
                    color: "#ECECEC"
                }
                // 登录名
                Label {
                    text: qsTr("登录名")
                    font.pixelSize: 14
                    color: "#CCCCCC"
                    Layout.topMargin: 4
                }
                // TextField {
                HistoryTextField {
                    // BUG 登录名点击之后(从历史记录中点击 popup), 需要从 db 里面获取对应的记录, 然后显示到 ui 界面上
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
                    historyModel: dialog.loginNames
                    // 连接删除历史记录信号
                    onRequestRemoveHistory: function (value) {// 删除 db 历史记录
                        // configManager.removeFromHistory(value)
                    }
                    // 修改 historyItemSelected 处理逻辑
                    onHistoryItemSelected: function (value) {
                        try {
                            // 从 TDB 获取完整的登录信息
                            // var loginInfo = TtDB.loginInfoByName(value)
                            var loginInfo = TtDB.loginInfoAsMap(value)

                            // 填充各个字段
                            loginName.text = loginInfo.name
                            secretId.text = loginInfo.secret_id
                            secretKey.text = loginInfo.secret_key
                            backup.text = loginInfo.remark

                            console.log("已自动填充用户 " + value + " 的登录信息")
                        } catch (e) {
                            console.error("获取登录信息失败: " + e)
                        }
                    }
                    // 添加文本变化处理
                    onTextChanged: {
                        // 查找与 secretId 匹配的完整配置并自动填充 secretKey
                        // 点击文本历史记录时, text 被填充正确的字符串, 发出一次信号
                        if (text && configManager
                                && configManager.findMatchingKey) {
                            let matchedKey = configManager.findMatchingKey(text)
                            if (matchedKey) {
                                secretKey.text = matchedKey
                            }
                        }
                    }
                }
                // SecretId
                Label {
                    text: qsTr("SecretId")
                    font.pixelSize: 14
                    color: "#CCCCCC"
                }
                // HistoryTextField {
                TextField {
                    id: secretId
                    Layout.fillWidth: true
                    placeholderText: qsTr("请输入 API ID")
                    height: 40
                    selectByMouse: true
                    echoMode: TextInput.Password
                    color: "#FFFFFF"
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

                    palette {
                        button: "#2980b9"
                        buttonText: "white"
                    }

                    font.pixelSize: 16

                    onClicked: {
                        // BUG 数据库操作
                        // TDB
                        // 保存到数据库
                        TtDB.saveLoginInfo(loginName.text, // 登录名
                                           secretId.text, // SecretId
                                           secretKey.text, // SecretKey
                                           backup.text // 备注
                                           )
                        // 保存配置
                        // configManager.secretId = secretId.text
                        // configManager.secretKey = secretKey.text
                        // console.log("保存 key: ", configManager.secretKey)
                        // configManager.remark = backup.text
                        // configManager.rememberSession = rememberSession.checked
                        // configManager.saveLoginConfig()
                        // 发出信号
                        loginSuccess()
                        dialog.close()
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
    }
}
