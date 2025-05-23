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
    width: 360
    height: 480
    title: "登录"
    visible: false
    flags: Qt.Dialog
    modality: Qt.ApplicationModal
    signal loginSuccess

    Component.onCompleted: {
        windowAgent.setup(dialog)
        windowAgent.setWindowAttribute("dark-mode", true)
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
                source: "qrc:/resources/app/example.png"
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
                spacing: 12

                // 标题
                Label {
                    text: "Cloud Storage Hub"
                    font.pixelSize: 22
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 10
                    Layout.bottomMargin: 16
                    color: "#ECECEC"
                }

                // SecretId
                Label {
                    text: qsTr("SecretId")
                    font.pixelSize: 14
                    color: "#CCCCCC"
                }
                // TextField {
                //     id: secretId
                //     placeholderText: qsTr("请输入 API 密钥")
                //     Layout.fillWidth: true
                //     height: 40
                //     selectByMouse: true
                //     color: "#FFFFFF"
                //     placeholderTextColor: "#8A8A8A" // 更亮的灰色，提高对比度

                //     property bool showingHistory: false
                //     // 按下鼠标
                //     Keys.onDownPressed: {
                //         if (!popup.visible
                //                 && configManager.secretIdHistory.length > 0) {
                //             popup.open()
                //         } else {
                //             event.accepted = false
                //         }
                //     }
                //     onActiveFocusChanged: {
                //         if (activeFocus && !text
                //                 && configManager.secretIdHistory.length > 0) {
                //             popup.open()
                //         }
                //     }
                //     // 在用户开始输入时检查历史记录
                //     onTextChanged: {
                //         if (text && !showingHistory
                //                 && configManager.secretIdHistory.length > 0) {
                //             // 如果有匹配项，显示下拉菜单
                //             let foundMatch = false
                //             for (var i = 0; i < configManager.secretIdHistory.length; i++) {
                //                 if (configManager.secretIdHistory[i].startsWith(
                //                             text)) {
                //                     foundMatch = true
                //                     break
                //                 }
                //             }

                //             if (foundMatch && !popup.visible) {
                //                 popup.open()
                //             } else if (!foundMatch && popup.visible) {
                //                 popup.close()
                //             }
                //         }
                //     }
                //     // 历史记录下拉菜单
                //     Popup {
                //         id: popup
                //         y: secretId.height
                //         width: secretId.width - 10
                //         implicitHeight: Math.min(200, contentItem.contentHeight)
                //         padding: 1

                //         closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

                //         // 添加进入/退出动画
                //         enter: Transition {
                //             NumberAnimation {
                //                 property: "opacity"
                //                 from: 0.0
                //                 to: 1.0
                //                 duration: 150
                //                 easing.type: Easing.OutCubic
                //             }
                //             NumberAnimation {
                //                 property: "scale"
                //                 from: 0.95
                //                 to: 1.0
                //                 duration: 150
                //                 easing.type: Easing.OutCubic
                //             }
                //         }

                //         exit: Transition {
                //             NumberAnimation {
                //                 property: "opacity"
                //                 from: 1.0
                //                 to: 0.0
                //                 duration: 100
                //                 easing.type: Easing.InCubic
                //             }
                //             NumberAnimation {
                //                 property: "scale"
                //                 from: 1.0
                //                 to: 0.95
                //                 duration: 100
                //                 easing.type: Easing.InCubic
                //             }
                //         }
                //         // 设定变换原点在顶部中心
                //         transformOrigin: Popup.Top

                //         // 背景
                //         background: Rectangle {
                //             color: "#3E3E42"
                //             border.color: "#555555"
                //             border.width: 1
                //             radius: 6

                //             // 添加阴影效果
                //             layer.enabled: true
                //             layer.effect: DropShadow {
                //                 transparentBorder: true
                //                 horizontalOffset: 0
                //                 verticalOffset: 2
                //                 radius: 8.0
                //                 samples: 17
                //                 color: Qt.rgba(0, 0, 0, 0.5)
                //             }
                //         }
                //         // 显示历史列表视图
                //         contentItem: ListView {
                //             id: historyList
                //             clip: true
                //             implicitHeight: contentHeight
                //             model: {
                //                 if (!secretId.text) {
                //                     return configManager.secretIdHistory
                //                 }
                //                 return configManager.secretIdHistory.filter(
                //                             item => item.toLowerCase().includes(
                //                                 secretId.text.toLowerCase()))
                //             }
                //             delegate: ItemDelegate {
                //                 id: historyItem
                //                 width: historyList.width
                //                 height: 40
                //                 // 高亮动画
                //                 Rectangle {
                //                     id: highlightRect
                //                     anchors.fill: parent
                //                     color: "#4080C0"
                //                     opacity: 0
                //                     radius: 4

                //                     Behavior on opacity {
                //                         NumberAnimation {
                //                             duration: 150
                //                         }
                //                     }
                //                 }
                //                 contentItem: Item {
                //                     anchors.fill: parent
                //                     Rectangle {
                //                         id: iconCircle
                //                         anchors {
                //                             left: parent.left
                //                             leftMargin: 10
                //                             verticalCenter: parent.verticalCenter
                //                         }
                //                         width: 22
                //                         height: 22
                //                         radius: 11
                //                         color: "#3498DB"
                //                         opacity: 0.7

                //                         Text {
                //                             anchors.centerIn: parent
                //                             text: "⟳" // 历史图标
                //                             color: "#FFFFFF"
                //                             font.pixelSize: 14
                //                         }
                //                     }
                //                     // 配置中读取的文本
                //                     Text {
                //                         anchors {
                //                             left: iconCircle.right
                //                             leftMargin: 10
                //                             right: parent.right
                //                             rightMargin: 10
                //                             verticalCenter: parent.verticalCenter
                //                         }
                //                         text: modelData
                //                         color: "#ECECEC"
                //                         font.pixelSize: 13
                //                         elide: Text.ElideRight
                //                     }
                //                     // 删除按钮
                //                     Rectangle {
                //                         anchors {
                //                             right: parent.right
                //                             rightMargin: 8
                //                             verticalCenter: parent.verticalCenter
                //                         }
                //                         width: 20
                //                         height: 20
                //                         radius: 10
                //                         color: deleteMouseArea.containsMouse ? "#e74c3c" : "transparent"
                //                         border.color: deleteMouseArea.containsMouse ? "#c0392b" : "#AAAAAA"
                //                         border.width: 1
                //                         visible: historyItem.hovered
                //                         // 添加动画
                //                         Behavior on color {
                //                             ColorAnimation {
                //                                 duration: 150
                //                             }
                //                         }
                //                         Text {
                //                             anchors.centerIn: parent
                //                             text: "×"
                //                             // color: "#AAAAAA"
                //                             color: deleteMouseArea.containsMouse ? "#FFFFFF" : "#AAAAAA"
                //                             font.pixelSize: 12
                //                             font.bold: true
                //                         }
                //                         // 点击删除按钮
                //                         MouseArea {
                //                             id: deleteMouseArea
                //                             anchors.fill: parent
                //                             hoverEnabled: true
                //                             cursorShape: Qt.PointingHandCursor
                //                             onPressed: {
                //                                 parent.scale = 0.9
                //                                 console.log("press")
                //                             }
                //                             onReleased: {
                //                                 parent.scale = 1.0
                //                                 console.log("delete: ")
                //                                 configManager.removeFromHistory(
                //                                             modelData)
                //                             }
                //                             onClicked: {
                //                                 // 动画效果
                //                                 deleteAnimation.start()
                //                             }
                //                         }
                //                         // 还原动画效果
                //                         Behavior on scale {
                //                             NumberAnimation {
                //                                 duration: 100
                //                             }
                //                         }

                //                         // 删除动画
                //                         SequentialAnimation {
                //                             id: deleteAnimation

                //                             // 1. 红色闪动
                //                             ColorAnimation {
                //                                 target: highlightRect
                //                                 property: "color"
                //                                 to: "#e74c3c"
                //                                 duration: 150
                //                             }

                //                             // 2. 缩放退出
                //                             ParallelAnimation {
                //                                 NumberAnimation {
                //                                     target: historyItem
                //                                     property: "opacity"
                //                                     to: 0
                //                                     duration: 200
                //                                     easing.type: Easing.InQuad
                //                                 }
                //                                 NumberAnimation {
                //                                     target: historyItem
                //                                     property: "height"
                //                                     to: 0
                //                                     duration: 200
                //                                     easing.type: Easing.InQuad
                //                                 }
                //                             }

                //                             // 3. 执行实际删除
                //                             ScriptAction {
                //                                 script: {
                //                                     // 删除此历史项
                //                                     try {
                //                                         configManager.removeFromHistory(
                //                                                     modelData)
                //                                         console.log("删除历史记录: " + modelData)
                //                                     } catch (e) {
                //                                         console.error(
                //                                                     "删除历史记录失败: " + e)
                //                                     }
                //                                 }
                //                             }
                //                         }
                //                     }
                //                 }
                //                 // 悬停效果
                //                 onHoveredChanged: {
                //                     // 透明度改变
                //                     highlightRect.opacity = hovered ? 0.3 : 0
                //                 }
                //                 background: Rectangle {
                //                     color: hovered ? "#505050" : "transparent"
                //                 }
                //                 // 点击效果
                //                 onClicked: {
                //                     highlightRect.opacity = 0.5
                //                     // secretId.showingHistory = true
                //                     // secretId.text = modelData
                //                     // secretId.showingHistory = false
                //                     // 使用函数闭包来修复引用错误
                //                     var textField = secretId // 在当前作用域捕获 secretId 引用

                //                     // 使用捕获的引用
                //                     textField.showingHistory = true
                //                     textField.text = modelData
                //                     textField.showingHistory = false

                //                     // 添加点击动画
                //                     clickAnimation.start()
                //                 }
                //                 SequentialAnimation {
                //                     id: clickAnimation
                //                     PropertyAnimation {
                //                         target: historyItem
                //                         property: "scale"
                //                         from: 1.0
                //                         to: 0.97
                //                         duration: 50
                //                     }
                //                     PropertyAnimation {
                //                         target: historyItem
                //                         property: "scale"
                //                         from: 0.97
                //                         to: 1.0
                //                         duration: 100
                //                     }
                //                     ScriptAction {
                //                         script: popup.close()
                //                     }
                //                 }
                //             }
                //             // 滚动指示器
                //             ScrollIndicator.vertical: ScrollIndicator {
                //                 active: historyList.contentHeight > historyList.height
                //                 contentItem: Rectangle {
                //                     implicitWidth: 4
                //                     implicitHeight: 100
                //                     color: "#777777"
                //                     radius: 2
                //                 }
                //             }
                //         }
                //     }
                //     background: Rectangle {
                //         radius: 4
                //         color: "#3E3E42"
                //         border.color: secretId.focus ? "#3498db" : "#555555"
                //         border.width: 1
                //     }
                // }
                HistoryTextField {
                    id: secretId
                    Layout.fillWidth: true
                    placeholderText: qsTr("请输入 API 密钥")
                    historyModel: configManager.secretIdHistory

                    // 连接删除历史记录信号
                    onRequestRemoveHistory: function (value) {
                        configManager.removeFromHistory(value)
                    }

                    // 添加文本变化处理
    onTextChanged: {
        // 查找与 secretId 匹配的完整配置并自动填充 secretKey
        if (text && configManager && configManager.findMatchingKey) {
            let matchedKey = configManager.findMatchingKey(text);
            if (matchedKey) {
                secretKey.text = matchedKey;
            }
        }
    }
                }

                // SecretKey
                Label {
                    text: qsTr("SecretKey")
                    font.pixelSize: 14
                    color: "#CCCCCC"
                    Layout.topMargin: 8
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
                    Layout.topMargin: 8
                }
                TextField {
                    id: backup
                    placeholderText: qsTr("非必填，添加备注名，用于账号管理")
                    Layout.fillWidth: true
                    height: 40
                    selectByMouse: true
                    color: "#FFFFFF"
                    placeholderTextColor: "#8A8A8A" // 更亮的灰色，提高对比度
                    // 添加历史输入功能
                    property bool showingHistory: false

                    // 监听按键，弹出历史记录
                    Keys.onDownPressed: {
                        if (!remarkPopup.visible
                                && configManager.remarkHistory.length > 0) {
                            remarkPopup.open()
                        } else {
                            event.accepted = false
                        }
                    }

                    onActiveFocusChanged: {
                        if (activeFocus && !text
                                && configManager.remarkHistory.length > 0) {
                            remarkPopup.open()
                        }
                    }

                    // 在用户开始输入时检查历史记录
                    onTextChanged: {
                        if (text && !showingHistory
                                && configManager.remarkHistory.length > 0) {
                            // 如果有匹配项，显示下拉菜单
                            let foundMatch = false
                            for (var i = 0; i < configManager.remarkHistory.length; i++) {
                                if (configManager.remarkHistory[i].startsWith(
                                            text)) {
                                    foundMatch = true
                                    break
                                }
                            }

                            if (foundMatch && !remarkPopup.visible) {
                                remarkPopup.open()
                            } else if (!foundMatch && remarkPopup.visible) {
                                remarkPopup.close()
                            }
                        }
                    }

                    // 历史记录下拉菜单
                    Popup {
                        id: remarkPopup
                        y: backup.height
                        width: backup.width
                        implicitHeight: Math.min(
                                            200,
                                            remarkContentItem.contentHeight)
                        padding: 1
                        background: Rectangle {
                            color: "#3E3E42"
                            border.color: "#555555"
                            border.width: 1
                            radius: 4
                        }

                        contentItem: ListView {
                            id: remarkContentItem
                            clip: true
                            implicitHeight: contentHeight
                            model: {
                                if (!backup.text)
                                    return configManager.remarkHistory
                                return configManager.remarkHistory.filter(
                                            item => item.toLowerCase().includes(
                                                backup.text.toLowerCase()))
                            }
                            delegate: ItemDelegate {
                                width: remarkContentItem.width
                                height: 40

                                contentItem: Text {
                                    text: modelData
                                    color: "#ECECEC"
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }

                                background: Rectangle {
                                    color: hovered ? "#505050" : "transparent"
                                }

                                onClicked: {
                                    backup.showingHistory = true
                                    backup.text = modelData
                                    backup.showingHistory = false
                                    remarkPopup.close()
                                }
                            }

                            ScrollIndicator.vertical: ScrollIndicator {}
                        }
                    }
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
                    Layout.topMargin: 12
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
                    Layout.topMargin: 12
                    Layout.preferredHeight: 46

                    palette {
                        button: "#2980b9"
                        buttonText: "white"
                    }

                    font.pixelSize: 16

                    onClicked: {
                        // 保存配置
                        configManager.secretId = secretId.text
                         configManager.secretKey = secretKey.text; 
                        configManager.remark = backup.text
                        configManager.rememberSession = rememberSession.checked
                        configManager.saveLoginConfig()

                        // 保存到历史记录
                        configManager.addToHistory(secretId.text, backup.text)

                        loginSuccess()
                        dialog.close()

                        // loginSuccess()
                        // dialog.close()
                    }
                }

                // 填充空间
                Item {
                    Layout.fillHeight: true
                    Layout.minimumHeight: 5
                    Layout.maximumHeight: 20
                }

                // 底部版权信息
                Text {
                    text: "© 2025 Cloud Storage Hub"
                    font.pixelSize: 12
                    color: "#7f8c8d"
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 10
                }
            }
        }
    }
}
