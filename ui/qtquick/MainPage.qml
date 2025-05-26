import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material
import QtQml.Models
import Qt.labs.qmlmodels

import "./Component"

Item {
    id: rootItem
    anchors.fill: parent

    property var columnWidths: [30, 270, 150, 150] // 图标、名称、地区、日期
    function getIconForFolder(type) {
        switch (type) {
        case "folder":
            return "📁"
        case "image":
            return "🖼️"
        case "doc":
            return "📄"
        case "video":
            return "🎬"
        case "audio":
            return "🎵"
        case "misc":
            return "📦"
        default:
            return "📁"
        }
    }

    function getFileIcon(file) {
        if (file.isFolder)
            return "📁"
        switch (file.type) {
        case "文档":
            return "📄"
        case "幻灯片":
            return "📊"
        case "图片":
            return "🖼️"
        case "视频":
            return "🎬"
        case "音频":
            return "🎵"
        default:
            return "📄"
        }
    }

    // 在 TableView 中添加排序函数
    function sortByColumn(column, ascending) {
        // 创建临时数组存储所有数据
        let rows = []
        for (var i = 0; i < tableModel.rowCount; i++) {
            rows.push(tableModel.getRow(i))
        }

        // 根据选定的列排序
        rows.sort(function (a, b) {
            let valueA, valueB

            // 根据列选择字段
            if (column === 1) {
                valueA = a.name ? a.name.toLowerCase() : ""
                valueB = b.name ? b.name.toLowerCase() : ""
            } else if (column === 2) {
                valueA = a.zone ? a.zone.toLowerCase() : ""
                valueB = b.zone ? b.zone.toLowerCase() : ""
            } else if (column === 3) {
                // 处理日期排序 - 使用日期格式解析
                valueA = parseDateString(a.date)
                valueB = parseDateString(b.date)
            } else {
                return 0 // 不支持的列
            }

            // 升序/降序比较
            if (ascending) {
                if (valueA < valueB)
                    return -1
                if (valueA > valueB)
                    return 1
                return 0
            } else {
                if (valueA > valueB)
                    return -1
                if (valueA < valueB)
                    return 1
                return 0
            }
        })

        // 清除当前数据并按排序顺序重新添加
        tableModel.clear()
        for (var i = 0; i < rows.length; i++) {
            tableModel.appendRow(rows[i])
        }
    }

    // 添加解析日期字符串的辅助函数
    function parseDateString(dateStr) {
        if (!dateStr)
            return 0

        try {
            // 尝试解析为日期对象
            const date = new Date(dateStr)
            if (isNaN(date.getTime())) {
                // 如果无法解析，返回原始字符串
                return dateStr.toLowerCase()
            }
            // 返回时间戳用于比较
            return date.getTime()
        } catch (e) {
            // 失败情况下返回原始字符串
            return dateStr.toLowerCase()
        }
    }

    // 暴露的属性和信号
    property var folderModel: [] // 文件夹模型数据
    property var fileModel: [] // 文件模型数据

    property int sortColumn: -1 // -1表示未排序，0,1,2,3对应不同列
    property bool sortAscending: true // true为升序，false为降序

    signal uploadRequested
    signal downloadRequested(var selectedItems)
    signal searchRequested(string query)
    signal folderSelected(string folderId)
    signal logoutRequested

    Connections {
        target: instanceBuckets
        function onModelChanged() {
            // 防止在模型未初始化时崩溃
            try {
                // 使用更安全的方式刷新列表
                folderListView.model = folderListView.model // 重新赋值触发更新
                tableView.refreshData() // 直接调用刷新方法
                console.log("存储桶数据已更新，模型包含",
                            instanceBuckets.bucketCount ? instanceBuckets.bucketCount(
                                                              ) : "未知", "项")
            } catch (e) {
                console.error("刷新视图时出错:", e)
            }
        }
    }
    // 添加一个属性来存储当前面包屑路径
    property var breadcrumbPathData: []

    // 修改 folderSelected 信号处理
    onFolderSelected: function (folderId) {
        console.log("选择文件夹:", folderId)

        // 更新面包屑路径
        if (folderId === "all") {
            // 回到根目录
            breadcrumbPathData = [{
                                      "id": "all",
                                      "name": "全部文件"
                                  }]
        } else {
            // 查找当前选中的文件夹对象
            let folderObj = null

            // 从实例存储桶中查找
            if (instanceBuckets && instanceBuckets.model) {
                for (var i = 0; i < instanceBuckets.bucketCount(); i++) {
                    const name = instanceBuckets.getBucketData(i, 0)
                    if (name === folderId) {
                        folderObj = {
                            "id": name,
                            "name": name
                        }
                        break
                    }
                }
            }

            if (folderObj) {
                // 检查面包屑路径中是否已存在此文件夹
                const existingIndex = breadcrumbPathData.findIndex(
                                        item => item.id === folderObj.id)

                if (existingIndex >= 0) {
                    // 如果存在，截断到此位置
                    breadcrumbPathData = breadcrumbPathData.slice(
                                0, existingIndex + 1)
                } else {
                    // 如果不存在，添加到路径末尾
                    breadcrumbPathData.push(folderObj)
                }
            }
        }

        // 更新面包屑组件的数据
        breadcrumbPath.currentPath = breadcrumbPathData

        // 刷新表格显示
        tableView.refreshData()
    }

    // BUG 添加退出登录的按钮
    // 整体布局
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // 顶部工具栏
        Rectangle {
            id: toolbar
            Layout.fillWidth: true
            height: 60
            color: "#2C3E50"

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 16
                    rightMargin: 16
                }
                spacing: 12

                // 搜索框
                TextField {
                    id: searchField
                    Layout.preferredWidth: 300
                    Layout.preferredHeight: 36
                    // 添加以下属性以禁用浮动标签
                    Material.accent: "#2980B9" // 设置强调色
                    Material.foreground: "#333333" // 设置前景色
                    background: Rectangle {
                        color: "#FFFFFF"
                        opacity: 0.9
                        radius: 4
                        border.width: 0
                        // 聚焦状态时的边框
                        Rectangle {
                            visible: searchField.activeFocus
                            anchors.fill: parent
                            color: "transparent"
                            radius: 4
                            border.color: "#2980B9"
                            border.width: 1
                        }
                    }

                    // 使用自定义占位文本，仅在文本框为空时显示
                    Label {
                        visible: !searchField.text && !searchField.activeFocus
                        anchors {
                            left: parent.left
                            leftMargin: 10
                            verticalCenter: parent.verticalCenter
                        }
                        text: "搜索文件..."
                        color: "#999999"
                    }
                    onAccepted: {
                        if (text.length > 0) {
                            searchRequested(text)
                        }
                    }

                    // 搜索图标
                    Label {
                        anchors {
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            rightMargin: 8
                        }
                        text: "🔍"
                        color: "#555555"
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (searchField.text.length > 0) {
                                    searchRequested(searchField.text)
                                }
                            }
                        }
                    }
                }
                // 占位符
                Item {
                    Layout.fillWidth: true
                }

                // 操作按钮组
                Row {
                    spacing: 10

                    // 上传按钮
                    Button {
                        id: uploadButton
                        text: "上传"
                        icon.source: "qrc:/resources/icon/upload.png"
                        icon.color: "transparent"

                        contentItem: RowLayout {
                            spacing: 5
                            Image {
                                source: "qrc:/resources/icon/upload.png"
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                                fillMode: Image.PreserveAspectFit
                            }

                            Text {
                                text: uploadButton.text
                                font.pixelSize: 14
                                color: "#FFFFFF"
                            }
                        }

                        background: Rectangle {
                            color: uploadButton.hovered ? "#3498DB" : "#2980B9"
                            radius: 4
                        }

                        onClicked: uploadRequested()
                    }

                    // 下载按钮
                    Button {
                        id: downloadButton
                        text: "下载"
                        // enabled: tableView.selectionModel.hasSelection
                        enabled: tableView.selectedItems
                                 && tableView.selectedItems.length > 0

                        contentItem: RowLayout {
                            spacing: 5
                            Image {
                                source: "qrc:/resources/icon/download.png"
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                                fillMode: Image.PreserveAspectFit
                            }

                            Text {
                                text: downloadButton.text
                                font.pixelSize: 14
                                color: "#FFFFFF"
                                opacity: downloadButton.enabled ? 1.0 : 0.5
                            }
                        }

                        background: Rectangle {
                            color: downloadButton.enabled ? (downloadButton.hovered ? "#27AE60" : "#2ECC71") : "#7F8C8D"
                            radius: 4
                        }

                        onClicked: {
                            // downloadRequested(
                            //             tableView.selectionModel.selectedItems)
                            // 修改为使用 selectedItems
                            downloadRequested(tableView.selectedItems)
                        }
                    }
                    Button {
                        id: moreButton
                        text: "操作"
                        contentItem: RowLayout {
                            spacing: 5
                            Text {
                                text: moreButton.text
                                font.pixelSize: 14
                                color: "#FFFFFF"
                            }
                            Text {
                                text: "▼"
                                font.pixelSize: 10
                                color: "#FFFFFF"
                            }
                        }

                        background: Rectangle {
                            color: moreButton.hovered ? "#34495E" : "#2C3E50"
                            radius: 4
                            border.color: "#7F8C8D"
                            border.width: 1
                        }

                        onClicked: operationsMenu.popup()

                        // Menu {
                        Menu {
                            id: operationsMenu
                            MenuItem {
                                text: "新建文件夹"
                                onTriggered: console.log("新建文件夹")
                            }
                            MenuItem {
                                text: "重命名"
                                enabled: tableView.selectedItems
                                         && tableView.selectedItems.length === 1
                                onTriggered: console.log("重命名")
                            }
                            MenuItem {
                                text: "删除"
                                enabled: tableView.selectedItems
                                         && tableView.selectedItems.length > 0
                                onTriggered: console.log("删除")
                            }
                            MenuSeparator {}
                            MenuItem {
                                text: "刷新"
                                onTriggered: {
                                    console.log("刷新")
                                    if (instanceBuckets
                                            && typeof instanceBuckets.refreshBuckets
                                            === "function") {
                                        instanceBuckets.refreshBuckets()
                                    } else {
                                        console.error("刷新方法不可用")
                                    }
                                }
                            }
                        }
                    }
                    Button {
                        id: settingsButton
                        width: 40
                        height: 40
                        text: "设置"

                        // 移除背景以使用自定义视觉效果
                        background: Item {
                            anchors.fill: parent // 确保背景填满按钮

                            Rectangle {
                                anchors.centerIn: parent
                                // 使用最小值确保是圆形
                                property real size: Math.min(parent.width,
                                                             parent.height) - 8
                                width: size
                                height: size
                                radius: width / 2
                                color: "#3498DB"
                                opacity: settingsButton.hovered ? 0.2 : 0

                                // 悬停动画
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 150
                                    }
                                }
                            }
                        }
                        // 图标作为主要内容
                        contentItem: Item {
                            anchors.fill: parent
                            // 设置图标 - 使用 FontAwesome 或类似图标字体
                            Text {
                                leftPadding: 1
                                id: settingsIcon
                                anchors.centerIn: parent
                                text: "⚙️" // 使用 Unicode 设置图标
                                font.pixelSize: 20
                                color: "#FFFFFF"

                                // 点击时的动画效果
                                RotationAnimation {
                                    id: rotationAnimation
                                    target: settingsIcon
                                    from: 0
                                    to: 90
                                    duration: 300
                                    running: false
                                }
                            }
                        }
                        // 点击效果
                        onPressed: {
                            rotationAnimation.start()
                        }
                        onClicked: {
                            settingsMenu.popup()
                        }
                        TtMenu {
                            id: settingsMenu
                            animationType: TtMenu.AnimationType.Elegant
                            MenuItem {
                                text: qsTr("账号设置")
                                // icon.source: "qrc:/resources/icon/account.png" // 添加图标
                                onTriggered: {
                                    console.log("账号设置")
                                    // 实现账号设置 功能
                                }
                            }
                            MenuItem {
                                text: qsTr("偏好设置")
                                // icon.source: "qrc:/resources/icon/preferences.png" // 添加图标
                                onTriggered: {
                                    console.log("偏好设置")
                                    // 实现偏好设置功能
                                    var component = Qt.createComponent(
                                                "PreferencesDialog.qml")
                                    if (component.status === Component.Ready) {
                                        var dialog = component.createObject(
                                                    rootItem)
                                        dialog.settingsApplied.connect(
                                                    function () {
                                                        // 这里处理应用设置后的逻辑
                                                        console.log("设置已应用")
                                                    })
                                        dialog.visible = true
                                    } else {
                                        console.error("无法加载偏好设置对话框:",
                                                      component.errorString())
                                    }
                                }
                            }
                            MenuSeparator {}
                            MenuItem {
                                text: qsTr("退出登录")
                                // icon.source: "qrc:/resources/icon/logout.png" // 添加图标
                                onTriggered: {
                                    console.log("退出登录")
                                    rootItem.logoutRequested()
                                }
                            }
                        }

                        // 添加工具提示
                        ToolTip.visible: hovered
                        ToolTip.text: qsTr("设置")
                        ToolTip.delay: 500
                    }
                }
            }
        }

        // 主内容区
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // 分割主内容区
            // SplitView {
            TtSplitView {
                anchors.fill: parent
                // 左侧导航面板
                Rectangle {
                    id: navPanel
                    SplitView.preferredWidth: 200
                    SplitView.minimumWidth: 180
                    SplitView.maximumWidth: 300
                    color: "#2D3436"

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0
                        // 导航标题
                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            color: "#1E272E"
                            Label {
                                anchors {
                                    left: parent.left
                                    leftMargin: 16
                                    verticalCenter: parent.verticalCenter
                                }
                                text: "存储分类"
                                color: "#FFFFFF"
                                font.pixelSize: 16
                                font.bold: true
                            }
                        }
                        // 左侧文件列表
                        ListView {
                            id: folderListView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            // 使用实际的存储桶数据来创建文件夹列表
                            model: {
                                // 创建带图标的文件夹列表
                                let folders = []
                                // 添加"全部文件"固定项
                                folders.push({
                                                 "id": "all",
                                                 "name": "全部文件",
                                                 "icon": "folder"
                                             })
                                // 从模型中获取存储桶名称作为文件夹
                                if (instanceBuckets && instanceBuckets.model) {
                                    for (var i = 0; i < instanceBuckets.model.rowCount(
                                             ); i++) {
                                        const bucketName = instanceBuckets.model.data(
                                                             instanceBuckets.model.index(
                                                                 i, 0))
                                        const location = instanceBuckets.model.data(
                                                           instanceBuckets.model.index(
                                                               i, 1))

                                        folders.push({
                                                         "id": bucketName,
                                                         "name": bucketName,
                                                         "location": location,
                                                         "icon": "folder"
                                                     })
                                    }
                                }
                                return folders
                            }
                            // 在 Component.onCompleted 中添加检查
                            Component.onCompleted: {
                                // 检查 instanceBuckets 是否可用
                                if (!instanceBuckets) {
                                    console.error(
                                                "instanceBuckets 对象不可用，请确保在 main.cpp 中正确注册")
                                } else {
                                    console.log("instanceBuckets 已加载, 存储桶数:",
                                                instanceBuckets.bucketCount ? instanceBuckets.bucketCount() : "方法不可用")
                                }
                            }

                            delegate: ItemDelegate {
                                id: folderItem
                                width: folderListView.width
                                height: 50
                                highlighted: ListView.isCurrentItem

                                background: Rectangle {
                                    color: folderItem.highlighted ? "#34495E" : folderItem.hovered ? "#2C3E50" : "transparent"
                                }

                                RowLayout {
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        leftMargin: 16
                                        rightMargin: 10
                                        verticalCenter: parent.verticalCenter
                                    }
                                    spacing: 12

                                    // 文件夹图标
                                    Rectangle {
                                        width: 24
                                        height: 24
                                        color: "transparent"

                                        Text {
                                            anchors.centerIn: parent
                                            text: getIconForFolder(
                                                      modelData.icon)
                                            font.pixelSize: 18
                                            color: "#3498DB"
                                        }
                                    }

                                    // 文件夹名称
                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                        color: "#ECF0F1"
                                        elide: Text.ElideRight
                                    }
                                }

                                onClicked: {
                                    folderListView.currentIndex = index
                                    rootItem.folderSelected(modelData.id)
                                }

                                // 在 ItemDelegate 中添加
                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.RightButton
                                    propagateComposedEvents: true

                                    onClicked: function (mouse) {
                                        if (mouse.button === Qt.RightButton) {
                                            folderContextMenu.folderData = modelData
                                            folderContextMenu.folderIndex = index
                                            folderContextMenu.popup()
                                        }
                                        mouse.accepted = false
                                    }
                                    // 添加文件夹上下文菜单
                                    TtMenu {
                                        id: folderContextMenu
                                        property var folderData: null
                                        property int folderIndex: -1
                                        MenuItem {
                                            text: qsTr("编辑")
                                            onTriggered: {
                                                console.log("编辑文件夹:",
                                                            folderContextMenu.folderData ? folderContextMenu.folderData.name : "未知")
                                                // 实现文件夹编辑逻辑
                                            }
                                        }

                                        MenuItem {
                                            text: qsTr("删除")
                                            onTriggered: {
                                                console.log("删除文件夹:",
                                                            folderContextMenu.folderData ? folderContextMenu.folderData.name : "未知")
                                                // 实现文件夹删除逻辑
                                            }
                                        }
                                    }
                                }
                            }

                            ScrollIndicator.vertical: ScrollIndicator {}
                        }
                    }
                }
                // 右侧内容区
                Rectangle {
                    id: contentPanel
                    SplitView.fillWidth: true
                    SplitView.preferredWidth: parent.width - navPanel.width // 添加优先宽度
                    color: "#FFFFFF"
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0
                        // 面包屑导航条
                        Rectangle {
                            id: breadcrumbBar
                            Layout.fillWidth: true
                            height: 40
                            color: "#F0F2F5"

                            RowLayout {
                                anchors {
                                    fill: parent
                                    leftMargin: 16
                                    rightMargin: 16
                                }
                                spacing: 4

                                // 主页/根目录图标
                                Rectangle {
                                    width: 24
                                    height: 24
                                    color: "transparent"
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        anchors.centerIn: parent
                                        text: "🏠"
                                        font.pixelSize: 16
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            // 导航到根目录
                                            rootItem.folderSelected("all")
                                        }
                                    }
                                }

                                // 动态生成的面包屑路径
                                Row {
                                    id: breadcrumbPath
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 4

                                    // 绑定到当前文件夹路径
                                    property var currentPath: []

                                    // 使用Repeater动态创建面包屑项
                                    Repeater {
                                        model: breadcrumbPath.currentPath

                                        Row {
                                            spacing: 4

                                            // 分隔符
                                            Text {
                                                text: "/"
                                                font.pixelSize: 14
                                                color: "#666666"
                                                verticalAlignment: Text.AlignVCenter
                                                height: 24
                                                visible: index > 0
                                                         || modelData.id !== "all"
                                            }

                                            // 文件夹名称
                                            Text {
                                                text: modelData.name
                                                font.pixelSize: 14
                                                color: "#0066CC"
                                                verticalAlignment: Text.AlignVCenter
                                                height: 24

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        // 导航到此文件夹
                                                        rootItem.folderSelected(
                                                                    modelData.id)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // 表格标题栏
                        Rectangle {
                            id: headerBar
                            Layout.fillWidth: true
                            height: 40
                            color: "#F5F6FA"
                            Row {
                                anchors {
                                    fill: parent
                                    leftMargin: 16
                                    rightMargin: 16
                                }
                                spacing: 0
                                // 图标列标题
                                Rectangle {
                                    width: rootItem.columnWidths[0]
                                    height: parent.height
                                    color: "transparent"

                                    Label {
                                        anchors.centerIn: parent
                                        text: ""
                                        font.bold: true
                                    }
                                }
                                // 名称列标题
                                Rectangle {
                                    width: rootItem.columnWidths[1]
                                    height: parent.height
                                    color: "transparent"

                                    Label {
                                        anchors {
                                            left: parent.left
                                            leftMargin: 8
                                            verticalCenter: parent.verticalCenter
                                        }
                                        text: "桶名称"
                                        font.bold: true
                                        Layout.preferredWidth: 300
                                    }
                                }
                                // 地区列标题
                                Rectangle {
                                    width: rootItem.columnWidths[2]
                                    height: parent.height
                                    color: "transparent"

                                    Label {
                                        anchors {
                                            left: parent.left
                                            leftMargin: 8
                                            verticalCenter: parent.verticalCenter
                                        }
                                        text: "地区"
                                        font.bold: true
                                        Layout.preferredWidth: 150
                                    }
                                }
                                // 日期列标题
                                Rectangle {
                                    width: rootItem.columnWidths[3]
                                    height: parent.height
                                    // color: "transparent"
                                    color: rootItem.sortColumn == 2 ? "#E3F2FD" : "transparent"

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (rootItem.sortColumn == 3) {
                                                rootItem.sortAscending = !rootItem.sortAscending
                                            } else {
                                                rootItem.sortColumn = 3
                                                rootItem.sortAscending = true
                                            }
                                            sortByColumn(3,
                                                         rootItem.sortAscending)
                                            // rootItem.sortByColumn(3, rootItem.sortAscending)
                                        }
                                    }

                                    RowLayout {
                                        anchors {
                                            left: parent.left
                                            leftMargin: 8
                                            right: parent.right
                                            rightMargin: 8
                                            verticalCenter: parent.verticalCenter
                                        }
                                        spacing: 4

                                        Label {
                                            text: "创建时间"
                                            font.bold: true
                                        }

                                        // 排序指示器
                                        Label {
                                            visible: rootItem.sortColumn == 3
                                            text: rootItem.sortAscending ? "▲" : "▼"
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: "#2980B9"
                                        }

                                        Item {
                                            Layout.fillWidth: true
                                        }
                                    }
                                }
                            }
                        }
                        // 表格视图
                        TableView {
                            id: tableView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            property int editingRow: -1
                            property int editingColumn: -1
                            clip: true
                            // 添加排序函数
                            function sortByColumn(column, ascending) {
                                // 创建临时数组存储所有数据
                                let rows = []
                                for (var i = 0; i < tableModel.rowCount; i++) {
                                    rows.push(tableModel.getRow(i))
                                }

                                // 根据选定的列排序
                                rows.sort(function (a, b) {
                                    let valueA, valueB

                                    // 根据列选择字段
                                    if (column === 1) {
                                        valueA = a.name ? a.name.toLowerCase(
                                                              ) : ""
                                        valueB = b.name ? b.name.toLowerCase(
                                                              ) : ""
                                    } else if (column === 2) {
                                        valueA = a.zone ? a.zone.toLowerCase(
                                                              ) : ""
                                        valueB = b.zone ? b.zone.toLowerCase(
                                                              ) : ""
                                    } else if (column === 3) {
                                        // 处理日期排序 - 使用日期格式解析
                                        valueA = rootItem.parseDateString(
                                                    a.date)
                                        valueB = rootItem.parseDateString(
                                                    b.date)
                                    } else {
                                        return 0 // 不支持的列
                                    }

                                    // 升序/降序比较
                                    if (ascending) {
                                        if (valueA < valueB)
                                            return -1
                                        if (valueA > valueB)
                                            return 1
                                        return 0
                                    } else {
                                        if (valueA > valueB)
                                            return -1
                                        if (valueA < valueB)
                                            return 1
                                        return 0
                                    }
                                })

                                // 清除当前数据并按排序顺序重新添加
                                tableModel.clear()
                                for (var i = 0; i < rows.length; i++) {
                                    tableModel.appendRow(rows[i])
                                }
                            }
                            // 宽度
                            columnWidthProvider: function (column) {
                                return column < rootItem.columnWidths.length ? rootItem.columnWidths[column] : 100
                            }
                            // 行高
                            rowHeightProvider: function (row) {
                                return 50
                            }
                            // 设置模型
                            model: TableModel {
                                id: tableModel
                                // 定义列
                                TableModelColumn {
                                    display: "icon"
                                }
                                TableModelColumn {
                                    display: "name"
                                }
                                TableModelColumn {
                                    display: "zone"
                                }
                                TableModelColumn {
                                    display: "date"
                                }
                            }
                            // 创建刷新数据的函数
                            function refreshData() {
                                // 清除现有数据
                                tableModel.clear()

                                // 获取选中的文件夹ID
                                const selectedFolderId = folderListView.currentItem
                                                       && folderListView.currentItem.modelData ? folderListView.currentItem.modelData.id : "all"
                                if (rootItem.sortColumn !== -1) {
                                    sortByColumn(rootItem.sortColumn,
                                                 rootItem.sortAscending)
                                }

                                // 加载文件数据
                                if (instanceBuckets
                                        && typeof instanceBuckets.bucketCount === "function") {
                                    for (var i = 0; i < instanceBuckets.bucketCount(
                                             ); i++) {
                                        const name = instanceBuckets.getBucketData(
                                                       i, 0)
                                        const location = instanceBuckets.getBucketData(
                                                           i, 1) || "未知"
                                        const date = instanceBuckets.getBucketData(
                                                       i, 2) || "未知"
                                        // 如果是"全部文件"或者匹配当前选中的存储桶
                                        if (selectedFolderId === "all"
                                                || selectedFolderId === name) {
                                            tableModel.appendRow({
                                                                     "icon": "📁",
                                                                     "name": name,
                                                                     "size": "存储桶",
                                                                     "zone": location,
                                                                     "date": date,
                                                                     "id": "file" + i,
                                                                     "isFolder": true
                                                                 })
                                        }
                                        // 如果已经有排序设置，应用排序
                                        if (rootItem.sortColumn !== -1) {
                                            sortByColumn(rootItem.sortColumn,
                                                         rootItem.sortAscending)
                                        }
                                    }
                                }
                            }
                            // 选中项目的列表
                            property var selectedItems: []

                            // 自定义委托
                            delegate: DelegateChooser {
                                role: "column"

                                // 图标列
                                DelegateChoice {
                                    column: 0
                                    delegate: Rectangle {
                                        color: "transparent"
                                        implicitHeight: 50

                                        Text {
                                            anchors.centerIn: parent
                                            text: display
                                            font.pixelSize: 18
                                        }
                                    }
                                }

                                // 名称列
                                DelegateChoice {
                                    column: 1
                                    delegate: Rectangle {
                                        id: nameCell
                                        // property bool isEditing: false
                                        property bool isEditing: tableView.editingRow === row
                                                                 && tableView.editingColumn === 1
                                        color: {
                                            const isSelected = tableView.selectedItems.some(
                                                                 item => item.id
                                                                 === tableModel.getRow(
                                                                     row).id)
                                            return isSelected ? "#E3F2FD" : (row % 2 === 0 ? "#FFFFFF" : "#F8F9FA")
                                        }
                                        implicitHeight: 50
                                        Text {
                                            id: cellText
                                            anchors {
                                                left: parent.left
                                                leftMargin: 8
                                                verticalCenter: parent.verticalCenter
                                            }
                                            text: display
                                            elide: Text.ElideRight
                                            width: parent.width - 16
                                            font.bold: tableModel.getRow(
                                                           row).isFolder
                                            // 添加此条件，在编辑模式下隐藏
                                            visible: !nameCell.isEditing
                                        }
                                        // 编辑框
                                        TextField {
                                            id: editField
                                            anchors {
                                                left: parent.left
                                                leftMargin: 4
                                                right: parent.right
                                                rightMargin: 4
                                                verticalCenter: parent.verticalCenter
                                            }
                                            text: display
                                            visible: nameCell.isEditing
                                            selectByMouse: true
                                            // 添加不透明背景
                                            background: Rectangle {
                                                color: nameCell.color // 使用与单元格相同的背景色
                                                border.color: editField.focus ? "#3498db" : "#DDDDDD"
                                                border.width: 1
                                                radius: 2
                                            }
                                            Component.onCompleted: {
                                                if (nameCell.isEditing) {
                                                    forceActiveFocus()
                                                    selectAll()
                                                }
                                            }
                                            // 修改编辑字段的 onAccepted 处理器
                                            onAccepted: {
                                                // 保存编辑后的值
                                                if (text !== display) {
                                                    // 调用 InstanceBuckets 中的方法更新模型
                                                    if (instanceBuckets
                                                            && typeof instanceBuckets.updateBucketName === "function") {
                                                        if (instanceBuckets.updateBucketName(
                                                                    row,
                                                                    text)) {
                                                            console.log("重命名项目:",
                                                                        display,
                                                                        "为",
                                                                        text,
                                                                        "并更新了模型")
                                                        } else {
                                                            console.error(
                                                                        "重命名失败")
                                                        }
                                                    } else {
                                                        console.error(
                                                                    "updateBucketName 方法不可用")

                                                        // 备用方案：尝试直接更新视图模型
                                                        try {
                                                            const rowData = tableModel.getRow(row)
                                                            rowData.name = text
                                                            tableView.forceLayout()
                                                            console.log("已更新视图模型，但可能未更新底层数据")
                                                        } catch (e) {
                                                            console.error(
                                                                        "更新视图模型失败:",
                                                                        e)
                                                        }
                                                    }
                                                }

                                                // 重置编辑状态
                                                tableView.editingRow = -1
                                                tableView.editingColumn = -1
                                            }

                                            Keys.onEscapePressed: {
                                                // 取消编辑
                                                tableView.editingRow = -1
                                                tableView.editingColumn = -1
                                            }

                                            // 当出现时自动聚焦
                                            onVisibleChanged: {
                                                if (visible) {
                                                    Qt.callLater(function () {
                                                        forceActiveFocus()
                                                        selectAll()
                                                    })
                                                }
                                            }
                                        }
                                        // 工具提示
                                        // ToolTip {
                                        //     id: cellTooltip
                                        //     visible: mouseArea.containsMouse
                                        //     delay: 250
                                        //     timeout: 2500
                                        //     // 使用绝对位置定位
                                        //     x: nameCell.mapToItem(tableView, 0,
                                        //                           0).x
                                        //     y: nameCell.mapToItem(
                                        //            tableView, 0,
                                        //            0).y - cellTooltip.height - 5
                                        //     text: {
                                        //         if (instanceBuckets
                                        //                 && typeof instanceBuckets.getToolTip
                                        //                 === "function") {
                                        //             for (var i = 0; i < instanceBuckets.bucketCount(
                                        //                      ); i++) {
                                        //                 if (instanceBuckets.getBucketData(
                                        //                             i,
                                        //                             0) === display) {
                                        //                     const tipData = instanceBuckets.getToolTip(i, 0)
                                        //                     if (tipData) {
                                        //                         return tipData
                                        //                     }
                                        //                 }
                                        //             }
                                        //         }
                                        //         return display
                                        //     }
                                        // }

                                        // 处理点击事件
                                        MouseArea {
                                            id: mouseArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                                            propagateComposedEvents: !nameCell.isEditing // 编辑时不传播事件

                                            onClicked: function (mouse) {
                                                if (nameCell.isEditing) {
                                                    mouse.accepted = true
                                                    return
                                                }

                                                const rowData = tableModel.getRow(
                                                                  row)

                                                if (mouse.button === Qt.LeftButton) {
                                                    if (mouse.modifiers & Qt.ControlModifier) {
                                                        // Ctrl+点击: 多选
                                                        tableView.toggleSelection(
                                                                    rowData)
                                                    } else {
                                                        // 普通点击: 单选
                                                        tableView.clearSelection()
                                                        tableView.toggleSelection(
                                                                    rowData)
                                                    }
                                                    mouse.accepted = true
                                                } else if (mouse.button === Qt.RightButton) {
                                                    // 右键菜单
                                                    if (!tableView.isItemSelected(
                                                                rowData.id)) {
                                                        tableView.clearSelection()
                                                        tableView.toggleSelection(
                                                                    rowData)
                                                    }

                                                    // 显示上下文菜单
                                                    contextMenu.rowData = rowData
                                                    contextMenu.rowIndex = row
                                                    contextMenu.popup()
                                                    mouse.accepted = true
                                                }
                                            }
                                            onDoubleClicked: function (mouse) {
                                                const rowData = tableModel.getRow(
                                                                  row)

                                                if (!rowData.isFolder) {
                                                    // 对于非文件夹项目，进入编辑状态
                                                    nameCell.isEditing = true

                                                    // 使用 Qt.callLater 确保编辑域获得焦点
                                                    Qt.callLater(function () {
                                                        if (editField) {
                                                            editField.forceActiveFocus()
                                                            editField.selectAll(
                                                                        )
                                                        }
                                                    })

                                                    mouse.accepted = true
                                                } else {
                                                    // BUG 双击执行这里
                                                    // 处理文件夹双击打开
                                                    console.log("打开文件夹:",
                                                                rowData.name)
                                                    // 这里添加打开文件夹的逻辑
                                                    mouse.accepted = true
                                                }
                                            }
                                        }
                                    }
                                }

                                // 其他列 (地区, 日期)
                                DelegateChoice {
                                    delegate: Rectangle {
                                        color: {
                                            const isSelected = tableView.selectedItems.some(
                                                                 item => item.id
                                                                 === tableModel.getRow(
                                                                     row).id)
                                            return isSelected ? "#E3F2FD" : (row % 2 === 0 ? "#FFFFFF" : "#F8F9FA")
                                        }
                                        implicitHeight: 50

                                        Text {
                                            anchors {
                                                left: parent.left
                                                leftMargin: 8
                                                verticalCenter: parent.verticalCenter
                                            }
                                            text: display || ""
                                            color: "#555555"
                                            elide: Text.ElideRight
                                            width: parent.width - 16
                                        }
                                    }
                                }
                            }

                            // 选择处理函数
                            function toggleSelection(item) {
                                const index = selectedItems.findIndex(
                                                i => i.id === item.id)

                                if (index >= 0) {
                                    // 已选中，取消选择
                                    selectedItems.splice(index, 1)
                                } else {
                                    // 未选中，添加选择
                                    selectedItems.push(item)
                                }

                                // 通知视图更新
                                selectedItemsChanged()

                                // 更新下载按钮状态
                                downloadButton.enabled = selectedItems.length > 0
                            }

                            function clearSelection() {
                                selectedItems = []
                                selectedItemsChanged()
                                downloadButton.enabled = false
                            }

                            function isItemSelected(id) {
                                // 只有成功选择
                                console.log("isItemSelected called with id:",
                                            id)
                                return selectedItems.some(
                                            item => item.id === id)
                            }
                            // 上下文菜单
                            TtMenu {
                                id: contextMenu
                                property var rowData: null
                                property int rowIndex: -1

                                // MenuItem {
                                //     text: qsTr("编辑")
                                //     onTriggered: {
                                //         try {
                                //             // 直接使用行索引，而不是试图转换它
                                //             const row = contextMenu.rowIndex
                                //             const column = 1 // 名称列
                                //             // 获取单元格项
                                //             const nameDelegate = tableView.itemAtCell(
                                //                                    column, row)
                                //             if (nameDelegate) {
                                //                 // 查找实际的 Rectangle （nameCell）
                                //                 for (var i = 0; i
                                //                      < nameDelegate.children.length; i++) {
                                //                     const child = nameDelegate.children[i]
                                //                     if (child.isEditing !== undefined) {
                                //                         // 找到了 nameCell
                                //                         child.isEditing = true
                                //                         console.log("开始编辑:",
                                //                                     child.display)

                                //                         // 寻找编辑框并聚焦
                                //                         Qt.callLater(function () {
                                //                             for (var j = 0; j
                                //                                  < child.children.length; j++) {
                                //                                 const grandChild = child.children[j]
                                //                                 if (grandChild.text !== undefined
                                //                                         && typeof grandChild.forceActiveFocus === "function" && typeof grandChild.selectAll === "function") {
                                //                                     // 找到了编辑框
                                //                                     grandChild.forceActiveFocus()
                                //                                     grandChild.selectAll()
                                //                                     break
                                //                                 }
                                //                             }
                                //                         })

                                //                         break
                                //                     }
                                //                 }
                                //             }
                                //         } catch (e) {
                                //             console.error("编辑操作失败:", e)
                                //         }
                                //     }
                                // }
                                MenuItem {
                                    text: qsTr("编辑")
                                    onTriggered: {
                                        // 使用全局属性控制编辑状态，避免 DOM 访问
                                        tableView.editingRow = contextMenu.rowIndex
                                        tableView.editingColumn = 1 // 名称列

                                        // 通知视图更新
                                        tableView.forceLayout()

                                        console.log("开始编辑行:",
                                                    contextMenu.rowIndex)
                                    }
                                }
                                MenuItem {
                                    text: qsTr("删除")
                                    onTriggered: {
                                        console.log("删除项目:",
                                                    contextMenu.rowData ? contextMenu.rowData.name : "未知")
                                        // 实现删除逻辑
                                    }
                                }
                            }
                            // 确保在文件夹选择变化时刷新表格
                            Component.onCompleted: {
                                folderListView.currentIndexChanged.connect(
                                            function () {
                                                refreshData()
                                            })

                                // 初始加载数据
                                refreshData()
                            }

                            // 监听实例存储桶变化
                            Connections {
                                target: instanceBuckets
                                function onModelChanged() {
                                    tableView.refreshData()
                                }
                            }
                            // 4. 添加响应窗口尺寸变化的逻辑
                            Connections {
                                target: contentPanel

                                function onWidthChanged() {
                                    // 更新列宽计算
                                    const availableWidth = contentPanel.width - 32
                                    if (availableWidth > 500) {
                                        rootItem.columnWidths = [30, // 图标列固定宽度
                                                                 Math.max(
                                                                     200,
                                                                     availableWidth
                                                                     * 0.45), // 名称列占比45%
                                                                 Math.max(
                                                                     100,
                                                                     availableWidth
                                                                     * 0.25), // 地区列占比25%
                                                                 Math.max(
                                                                     100,
                                                                     availableWidth
                                                                     * 0.30) // 日期列占比30%
                                                ]
                                        // console.log("Updated column widths:",
                                        // rootItem.columnWidths)
                                        tableView.forceLayout()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // 底部状态栏
        Rectangle {
            Layout.fillWidth: true
            height: 28
            color: "#F5F6FA"

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 16
                    rightMargin: 16
                }

                Label {
                    text: {
                        // 修复错误的模型引用
                        const count = tableModel ? tableModel.rowCount : 0
                        const selected = tableView.selectedItems.length
                        return selected
                                > 0 ? `已选择 ${selected} 个项目，共 ${count} 个项目` : `共 ${count} 个项目`
                    }
                    font.pixelSize: 12
                    color: "#666666"
                }

                Item {
                    Layout.fillWidth: true
                }

                Label {
                    text: "2025 Cloud Storage Hub"
                    font.pixelSize: 12
                    color: "#666666"
                }
            }
        }
    }
}
