// import QtQuick
// import QtQuick.Controls
// import QtQuick.Layouts

// import "./Component"

// ApplicationWindow {
//     id: mainWindow
//     // width: 640
//     // height: 480
//     width: 1080
//     height: 740
//     visible: false
//     title: "Cloud Storage Hub"

//     // 加载主页
//     MainPage {
//         id: mainPage
//         visible: true
//         anchors.fill: parent
//         // 处理信号
//         onUploadRequested: {
//             console.log("上传文件请求")
//             // 这里实现文件上传逻辑
//         }
//         onDownloadRequested: function (selectedItems) {
//             console.log("下载文件请求", JSON.stringify(selectedItems))
//             // 这里实现文件下载逻辑
//         }
//         onSearchRequested: function (query) {
//             console.log("搜索请求:", query)
//             // 这里实现搜索逻辑
//         }
//         onFolderSelected: function (folderId) {
//             console.log("选择文件夹:", folderId)
//             // 这里加载对应文件夹的内容
//         }
//         // 处理退出登录
//         onLogoutRequested: {
//             // mainPage.visible = false
//             mainWindow.visible = false
//             // 清理会话数据
//             // 如果有会话管理，这里可以添加清理代码
//             // 显示登录对话框
//             showLoginDialog()
//         }
//     }
//     Component.onCompleted: {
//         showLoginDialog() // 使用函数代替内联代码
//     }
//     function showLoginDialog() {
//         var component = Qt.createComponent("LoginDialog.qml")
//         if (component.status === Component.Ready) {
//             var dialog = component.createObject(null)
//             dialog.visible = true
//             dialog.onLoginSuccess.connect(function () {
//                 dialog.visible = false
//                 dialog.destroy() // 销毁登录对话框

//                 console.log("展示主窗口")
//                 mainWindow.visible = true // 登录成功后显示主窗口
//                 mainPage.visible = true // 显示主页
//                 mainPage.folderSelected("all") // 默认加载"全部文件"
//             })
//         } else {
//             console.log("登录对话框加载失败: " + component.errorString())
//         }
//     }
// }
import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import Qt.labs.platform 1.1
import QWindowKit 1.0

import "./Component"

Window {
    property bool showWhenReady: true
    id: window
    width: 960
    height: 720
    color: darkStyle.windowBackgroundColor
    // title: qsTr("QWindowKit QtQuick Demo")
    title: qsTr("Cloud Storage Hub")
    Component.onCompleted: {
        windowAgent.setup(window)
        windowAgent.setWindowAttribute("dark-mode", true)
        // if (window.showWhenReady) {
        //     window.visible = true
        // }
        showLoginDialog() // 使用函数代替内联代码
    }

    QtObject {
        id: lightStyle
    }

    QtObject {
        id: darkStyle
        readonly property color windowBackgroundColor: "#1E1E1E"
    }

    WindowAgent {
        id: windowAgent
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: contextMenu.open()
    }

    Rectangle {
        id: titleBar
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: 32
        color: window.active ? "#3C3C3C" : "#505050"
        // color: "transparent"
        // color: "#2D2D2D" // 深灰色背景而非透明
        // 添加底部边框线
        // Rectangle {
        //     anchors {
        //         left: parent.left
        //         right: parent.right
        //         bottom: parent.bottom
        //     }
        //     height: 1
        //     color: "#3498DB" // 蓝色分隔线
        //     opacity: 0.5
        // }
        Component.onCompleted: windowAgent.setTitleBar(titleBar)
        z: 100

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
            text: window.title
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
                onClicked: window.showMinimized()
                Component.onCompleted: windowAgent.setSystemButton(
                                           WindowAgent.Minimize, minButton)
            }

            QWKButton {
                id: maxButton
                height: parent.height
                source: window.visibility === Window.Maximized ? "qrc:/resources/window-bar/restore.svg" : "qrc:/resources/window-bar/maximize.svg"
                onClicked: {
                    if (window.visibility === Window.Maximized) {
                        window.showNormal()
                    } else {
                        window.showMaximized()
                    }
                }
                Component.onCompleted: windowAgent.setSystemButton(
                                           WindowAgent.Maximize, maxButton)
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
                onClicked: window.close()
                Component.onCompleted: windowAgent.setSystemButton(
                                           WindowAgent.Close, closeButton)
            }
        }
    }

    // Label {
    //     id: timeLabel
    //     anchors.centerIn: parent
    //     font {
    //         pointSize: 75
    //         bold: true
    //     }
    //     color: "#FEFEFE"
    //     Component.onCompleted: {
    //         if ($curveRenderingAvailable) {
    //             console.log("Curve rendering for text is available.")
    //             timeLabel.renderType = Text.CurveRendering
    //         }
    //     }
    // }

    // 看不到 titleBar
    // 加载主页
    MainPage {
        id: mainPage
        visible: true
        anchors {
            top: titleBar.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            topMargin: 32
            // centerIn: parent
        }
        // 处理信号
        onUploadRequested: {
            console.log("上传文件请求")
            // 这里实现文件上传逻辑
        }
        onDownloadRequested: function (selectedItems) {
            console.log("下载文件请求", JSON.stringify(selectedItems))
            // 这里实现文件下载逻辑
        }
        onSearchRequested: function (query) {
            console.log("搜索请求:", query)
            // 这里实现搜索逻辑
        }
        onFolderSelected: function (folderId) {
            console.log("选择文件夹:", folderId)
            // 这里加载对应文件夹的内容
        }
        // 处理退出登录
        onLogoutRequested: {
            // mainPage.visible = false
            // mainWindow.visible = false
            window.visible = false
            // 清理会话数据
            // 如果有会话管理，这里可以添加清理代码
            // 显示登录对话框
            showLoginDialog()
        }
    }
    // Component.onCompleted: {
    //     showLoginDialog() // 使用函数代替内联代码
    // }
    function showLoginDialog() {
        var component = Qt.createComponent("LoginDialog.qml")
        if (component.status === Component.Ready) {
            var dialog = component.createObject(null)
            dialog.visible = true
            dialog.onLoginSuccess.connect(function () {
                dialog.visible = false
                dialog.destroy() // 销毁登录对话框

                console.log("展示主窗口")
                if (window.showWhenReady) {
                    window.visible = true
                    mainPage.visible = true // 显示主页
                    mainPage.folderSelected("all") // 默认加载"全部文件"
                }
                // // mainWindow.visible = true // 登录成功后显示主窗口
                // window.visible = true // 登录成功后显示主窗口
                // mainPage.visible = true // 显示主页
                // mainPage.folderSelected("all") // 默认加载"全部文件"
            })
        } else {
            console.log("登录对话框加载失败: " + component.errorString())
        }
    }

    Menu {
        id: contextMenu

        Menu {
            id: themeMenu
            title: qsTr("Theme")

            MenuItemGroup {
                id: themeMenuGroup
                items: themeMenu.items
            }

            MenuItem {
                text: qsTr("Light")
                checkable: true
                onTriggered: windowAgent.setWindowAttribute("dark-mode", false)
            }

            MenuItem {
                text: qsTr("Dark")
                checkable: true
                checked: true
                onTriggered: windowAgent.setWindowAttribute("dark-mode", true)
            }
        }

        Menu {
            id: specialEffectMenu
            title: qsTr("Special effect")

            MenuItemGroup {
                id: specialEffectMenuGroup
                items: specialEffectMenu.items
            }

            MenuItem {
                enabled: Qt.platform.os === "windows"
                text: qsTr("None")
                checkable: true
                checked: true
                onTriggered: {
                    window.color = darkStyle.windowBackgroundColor
                    windowAgent.setWindowAttribute("dwm-blur", false)
                    windowAgent.setWindowAttribute("acrylic-material", false)
                    windowAgent.setWindowAttribute("mica", false)
                    windowAgent.setWindowAttribute("mica-alt", false)
                }
            }

            MenuItem {
                enabled: Qt.platform.os === "windows"
                text: qsTr("DWM blur")
                checkable: true
                onTriggered: {
                    window.color = "transparent"
                    windowAgent.setWindowAttribute("acrylic-material", false)
                    windowAgent.setWindowAttribute("mica", false)
                    windowAgent.setWindowAttribute("mica-alt", false)
                    windowAgent.setWindowAttribute("dwm-blur", true)
                }
            }

            MenuItem {
                enabled: Qt.platform.os === "windows"
                text: qsTr("Acrylic material")
                checkable: true
                onTriggered: {
                    window.color = "transparent"
                    windowAgent.setWindowAttribute("dwm-blur", false)
                    windowAgent.setWindowAttribute("mica", false)
                    windowAgent.setWindowAttribute("mica-alt", false)
                    windowAgent.setWindowAttribute("acrylic-material", true)
                }
            }

            MenuItem {
                enabled: Qt.platform.os === "windows"
                text: qsTr("Mica")
                checkable: true
                onTriggered: {
                    window.color = "transparent"
                    windowAgent.setWindowAttribute("dwm-blur", false)
                    windowAgent.setWindowAttribute("acrylic-material", false)
                    windowAgent.setWindowAttribute("mica-alt", false)
                    windowAgent.setWindowAttribute("mica", true)
                }
            }

            MenuItem {
                enabled: Qt.platform.os === "windows"
                text: qsTr("Mica Alt")
                checkable: true
                onTriggered: {
                    window.color = "transparent"
                    windowAgent.setWindowAttribute("dwm-blur", false)
                    windowAgent.setWindowAttribute("acrylic-material", false)
                    windowAgent.setWindowAttribute("mica", false)
                    windowAgent.setWindowAttribute("mica-alt", true)
                }
            }
        }
    }
}
