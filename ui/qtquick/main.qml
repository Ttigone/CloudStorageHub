import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "./Component"

ApplicationWindow {
    id: mainWindow
    // width: 640
    // height: 480
    width: 1080
    height: 740
    visible: false
    title: "Cloud Storage Hub"

    // 加载主页
    MainPage {
        id: mainPage
        visible: true
        anchors.fill: parent

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
    }
    Component.onCompleted: {
        var component = Qt.createComponent("LoginDialog.qml")
        if (component.status === Component.Ready) {
            var dialog = component.createObject(null)
            dialog.visible = true
            dialog.onLoginSuccess.connect(function () {
                dialog.visible = false
                mainWindow.visible = true // 登录成功后显示主窗口
                mainPage.folderSelected("all") // 默认加载"全部文件"
            })
        } else {
            console.log("登录对话框加载失败: " + component.errorString())
        }
    }
}
