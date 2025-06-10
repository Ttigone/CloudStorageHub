import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Qt5Compat.GraphicalEffects

Dialog {
    id: fileUploadDialog

    property string targetBucket: ""
    property string targetPath: ""
    property var bucketList: []

    signal uploadRequested(var uploadTasks)
    signal cancelled

    title: "选择上传文件"
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel

    width: 600
    height: 500

    // 1. 将 ListModel 定义在 Dialog 级别，确保全局可访问
    ListModel {
        id: fileListModel
    }

    // 使用纯绑定方式，确保实时居中
    x: parent ? Math.max(0, Math.min((parent.width - width) / 2,
                                     parent.width - width)) : 0
    y: parent ? Math.max(0, Math.min((parent.height - height) / 2,
                                     parent.height - height)) : 0

    // 初始居中
    Component.onCompleted: {
        if (ManagerGlobal && ManagerGlobal.getBucketNames) {
            bucketList = ManagerGlobal.getBucketNames()
        }
        // 强制触发一次位置更新
        Qt.callLater(function () {
            console.log("对话框初始位置:", x, y, "父窗口大小:", parent ? parent.width : 0,
                        parent ? parent.height : 0)
        })
    }

    Overlay.modal: Rectangle {
        color: "#60000000"
    }
    onAccepted: {
        if (fileListModel.count > 0 && targetBucket !== "") {
            var tasks = []
            for (var i = 0; i < fileListModel.count; i++) {
                var item = fileListModel.get(i)
                if (item.selected) {
                    tasks.push({
                                   "localPath": item.filePath,
                                   "fileName": item.fileName,
                                   "bucket": targetBucket,
                                   "remotePath": targetPath,
                                   "fileSize": 0,
                                   "status": "待上传"
                               })
                }
            }
            uploadRequested(tasks)
        }
    }

    onRejected: cancelled()

    // 获取输入的名字
    function getFileName(filePath) {
        var path = filePath.toString()
        if (path.startsWith("file://")) {
            path = path.substring(7)
        }
        return path.split("/").pop().split("\\").pop()
    }

    function openFileDialog() {
        fileDialog.open()
    }

    FileDialog {
        id: fileDialog
        title: "选择要上传的文件"
        fileMode: FileDialog.OpenFiles
        nameFilters: ["所有文件 (*)"]

        onAccepted: {
            // 返回的是 URL 格式
            updateFileList(fileDialog.selectedFiles)
        }
    }

    // 添加确认对话框
    Dialog {
        id: clearConfirmDialog
        title: "确认清空"
        modal: true
        standardButtons: Dialog.Yes | Dialog.No

        anchors.centerIn: parent

        Text {
            text: `确定要清空所有 ${fileListModel.count} 个文件吗？`
            font.pixelSize: 14
            color: "#374151"
        }

        onAccepted: {
            fileListModel.clear()
        }
    }

    function getLocalPath(fileUrl) {
        var path = fileUrl.toString()
        if (path.startsWith("file://")) {
            // 删除前缀
            path = path.substring(7)
        }
        // Windows 系统路径处理
        if (Qt.platform.os === "windows") {
            // Windows 路径可能是 /C:/path/file.txt 格式，需要移除开头的 /
            if (path.startsWith("/") && path.length > 1 && path.charAt(
                        2) === ":") {
                path = path.substring(1)
            }
            // 将 / 替换为 \
            path = path.replace(/\//g, "\\")
        }
        // 解码 URL 编码的字符（如空格、中文等）
        try {
            path = decodeURIComponent(path)
        } catch (e) {
            console.log("路径解码失败:", e, "原始路径:", path)
        }

        return path
    }

    function updateFileList(files) {
        // fileListModel.clear()
        for (var i = 0; i < files.length; i++) {
            var fileUrl = files[i].toString()
            var localPath = getLocalPath(fileUrl)
            var fileName = getFileName(localPath)
            // console.log("原始URL:", fileUrl)
            // console.log("本地路径:", localPath)
            // console.log("文件名:", fileName)
            var fileExists = false
            for (var j = 0; j < fileListModel.count; j++) {
                var existingItem = fileListModel.get(j)
                if (existingItem.filePath === localPath) {
                    fileExists = true
                    console.log("文件已存在，跳过:", fileName)
                    break
                }
            }

            // 只有不存在的文件才添加到列表
            if (!fileExists) {
                console.log("添加新文件:")
                console.log("原始URL:", fileUrl)
                console.log("本地路径:", localPath)
                console.log("文件名:", fileName)

                fileListModel.append({
                                         "fileName": fileName,
                                         "filePath": localPath,
                                         "selected": true
                                     })
            }
        }
    }

    ScrollView {
        anchors.fill: parent
        anchors.margins: 6
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        ScrollBar.horizontal.policy: ScrollBar.AsNeeded

        ColumnLayout {
            width: fileUploadDialog.width - 50
            GroupBox {
                title: "选择文件"
                Layout.fillWidth: true
                Layout.preferredHeight: 90
                Layout.maximumHeight: 90

                background: Rectangle {
                    color: "#FAFAFA"
                    border.color: "#bdbdbd"
                    border.width: 1
                    radius: 6
                }
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8 // 从 10 缩小到 8
                    spacing: 6 // 从 8 缩小到 6

                    // 将按钮和文本放在同一行以节省空间
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Button {
                            text: fileListModel.count > 0 ? "继续添加" : "浏览文件"
                            Layout.preferredWidth: 100 // 从 120 缩小到 100
                            Layout.preferredHeight: 28 // 从 32 缩小到 28

                            background: Rectangle {
                                color: {
                                    if (parent.pressed)
                                        return "#2980B9"
                                    if (parent.hovered)
                                        return "#3498DB"
                                    return fileListModel.count > 0 ? "#27AE60" : "#2980B9"
                                }
                                radius: 6

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 200
                                    }
                                }
                            }

                            contentItem: Text {
                                text: parent.text
                                color: "#FFFFFF"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 12 // 从 13 缩小到 12
                            }

                            onClicked: fileDialog.open()
                        }

                        // 状态文本与按钮在同一行
                        Text {
                            text: {
                                if (fileListModel.count === 0) {
                                    return "请选择要上传的文件"
                                } else {
                                    var selectedCount = getSelectedCount()
                                    return `共 ${fileListModel.count} 个文件，已选择 ${selectedCount} 个`
                                }
                            }
                            color: fileListModel.count > 0 ? "#2E7D32" : "#757575"
                            Layout.fillWidth: true
                            font.pixelSize: 11 // 从 12 缩小到 11
                            wrapMode: Text.WordWrap
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
            GroupBox {
                title: "上传目标"
                Layout.fillWidth: true
                Layout.preferredHeight: 80 // 从 120 大幅缩小到 80
                Layout.maximumHeight: 80 // 添加最大高度限制

                background: Rectangle {
                    color: "#FAFAFA"
                    border.color: "#bdbdbd"
                    border.width: 1
                    radius: 6
                }
                // 使用 RowLayout 而不是 GridLayout 来更紧凑地排列
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8 // 从 10 缩小到 8
                    spacing: 12

                    // 目标桶选择
                    RowLayout {
                        spacing: 6

                        Label {
                            text: "目标桶:"
                            font.pixelSize: 12 // 从 13 缩小到 12
                        }

                        ComboBox {
                            id: bucketCombo
                            Layout.preferredWidth: 150
                            Layout.preferredHeight: 28 // 从 32 缩小到 28
                            model: fileUploadDialog.bucketList
                            currentIndex: -1
                            displayText: currentIndex >= 0 ? model[currentIndex] : "请选择桶"
                            font.pixelSize: 11 // 添加字体大小

                            onCurrentTextChanged: {
                                if (currentIndex >= 0) {
                                    fileUploadDialog.targetBucket = currentText
                                }
                            }
                        }
                    }

                    // 上传路径
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Label {
                            text: "路径:"
                            font.pixelSize: 12 // 从 13 缩小到 12
                        }

                        TextField {
                            id: pathField
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28 // 从 32 缩小到 28
                            placeholderText: "留空=根目录，如: folder1/subfolder/"
                            text: fileUploadDialog.targetPath
                            font.pixelSize: 11 // 添加字体大小

                            onTextChanged: {
                                fileUploadDialog.targetPath = text
                            }
                        }
                    }
                }
            }
            GroupBox {
                title: "文件列表"
                Layout.fillWidth: true
                Layout.fillHeight: true
                // Layout.minimumHeight: 200
                Layout.minimumHeight: 300 // 从 200 增加到 300
                Layout.preferredHeight: 400 // 添加首选高度

                background: Rectangle {
                    color: "#FAFAFA"
                    border.color: "#E0E0E0"
                    border.width: 1
                    radius: 8
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 0

                    // 列表头部
                    Rectangle {
                        Layout.fillWidth: true
                        height: 32
                        color: "#F5F7FA"
                        radius: 6
                        border.color: "#E1E8ED"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            CheckBox {
                                id: selectAllCheckbox
                                text: qsTr("全选")
                                font.pixelSize: 11
                                font.weight: Font.Medium

                                // 使用计算属性来确定是否应该选中
                                property bool shouldBeAllSelected: {
                                    if (fileListModel.count === 0)
                                        return false
                                    return getSelectedCount(
                                                ) === fileListModel.count
                                }

                                // 监听计算属性的变化
                                onShouldBeAllSelectedChanged: {
                                    if (checked !== shouldBeAllSelected) {
                                        checked = shouldBeAllSelected
                                    }
                                }

                                onCheckedChanged: {
                                    // 只有当用户主动操作时才执行全选/取消全选
                                    if (checked !== shouldBeAllSelected) {
                                        for (var i = 0; i < fileListModel.count; i++) {
                                            fileListModel.setProperty(
                                                        i, "selected", checked)
                                        }
                                    }
                                }

                                contentItem: Text {
                                    text: selectAllCheckbox.text
                                    font: selectAllCheckbox.font
                                    color: "#374151"
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: selectAllCheckbox.indicator.width
                                                 + selectAllCheckbox.spacing
                                }

                                indicator: Rectangle {
                                    implicitWidth: 16
                                    implicitHeight: 16
                                    x: selectAllCheckbox.leftPadding
                                    y: parent.height / 2 - height / 2
                                    radius: 3
                                    border.color: selectAllCheckbox.checked ? "#3B82F6" : "#D1D5DB"
                                    border.width: 2
                                    color: selectAllCheckbox.checked ? "#3B82F6" : "#FFFFFF"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✓"
                                        color: "white"
                                        font.pixelSize: 10
                                        visible: selectAllCheckbox.checked
                                    }
                                }
                            }

                            Text {
                                text: "文件名"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: "#6B7280"
                                Layout.fillWidth: true
                            }

                            Text {
                                text: "操作"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: "#6B7280"
                                Layout.preferredWidth: 60
                                horizontalAlignment: Text.AlignCenter
                            }
                        }
                    }

                    // 文件列表视图
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: 200 // 确保最小高度
                        clip: true

                        ScrollBar.vertical.policy: ScrollBar.AsNeeded
                        ScrollBar.horizontal.policy: ScrollBar.AsNeeded

                        ListView {
                            id: fileListView
                            model: fileListModel
                            spacing: 1
                            boundsBehavior: Flickable.StopAtBounds
                            delegate: Rectangle {
                                width: fileListView.width
                                height: 38
                                color: {
                                    if (fileMouseArea.pressed)
                                        return "#E3F2FD"
                                    if (fileMouseArea.containsMouse)
                                        return "#F8FAFC"
                                    return index % 2 === 0 ? "#FFFFFF" : "#FAFBFC"
                                }
                                radius: 4
                                border.color: model.selected ? "#3B82F6" : "#E5E7EB"
                                border.width: model.selected ? 2 : 1

                                // 选中状态指示器
                                Rectangle {
                                    visible: model.selected
                                    width: 3
                                    height: parent.height - 4
                                    anchors {
                                        left: parent.left
                                        leftMargin: 2
                                        verticalCenter: parent.verticalCenter
                                    }
                                    color: "#3B82F6"
                                    radius: 1.5
                                }

                                MouseArea {
                                    id: fileMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        fileListModel.setProperty(
                                                    index, "selected",
                                                    !model.selected)
                                    }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    anchors.topMargin: 4
                                    anchors.bottomMargin: 4
                                    spacing: 8

                                    CheckBox {
                                        id: itemCheckBox

                                        Component.onCompleted: {
                                            checked = model.selected
                                        }

                                        Connections {
                                            target: fileListModel
                                            function onDataChanged() {
                                                if (index < fileListModel.count) {
                                                    var currentSelected = fileListModel.get(
                                                                index).selected
                                                    if (itemCheckBox.checked !== currentSelected) {
                                                        itemCheckBox.checked = currentSelected
                                                    }
                                                }
                                            }
                                        }

                                        onCheckedChanged: {
                                            if (index < fileListModel.count
                                                    && model.selected !== checked) {
                                                fileListModel.setProperty(
                                                            index, "selected",
                                                            checked)
                                            }
                                        }

                                        indicator: Rectangle {
                                            implicitWidth: 14
                                            implicitHeight: 14
                                            x: itemCheckBox.leftPadding
                                            y: itemCheckBox.height / 2 - height / 2
                                            radius: 2
                                            border.color: itemCheckBox.checked ? "#3B82F6" : "#D1D5DB"
                                            border.width: 2
                                            color: itemCheckBox.checked ? "#3B82F6" : "#FFFFFF"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "✓"
                                                color: "white"
                                                font.pixelSize: 9
                                                font.weight: Font.Bold
                                                visible: itemCheckBox.checked
                                            }

                                            Rectangle {
                                                anchors.fill: parent
                                                radius: parent.radius
                                                color: "#3B82F6"
                                                opacity: fileMouseArea.containsMouse
                                                         && !itemCheckBox.checked ? 0.1 : 0

                                                Behavior on opacity {
                                                    NumberAnimation {
                                                        duration: 150
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // 文件图标和信息
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Rectangle {
                                            width: 28
                                            height: 28
                                            radius: 4
                                            color: getFileTypeColor(
                                                       model.fileName)

                                            Text {
                                                anchors.centerIn: parent
                                                text: getFileTypeIcon(
                                                          model.fileName)
                                                font.pixelSize: 12
                                                color: "#FFFFFF"
                                            }

                                            Rectangle {
                                                anchors.fill: parent
                                                radius: parent.radius
                                                gradient: Gradient {
                                                    GradientStop {
                                                        position: 0.0
                                                        color: "#30FFFFFF"
                                                    }
                                                    GradientStop {
                                                        position: 1.0
                                                        color: "#10FFFFFF"
                                                    }
                                                }
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 0
                                            Text {
                                                text: model.fileName
                                                font.pixelSize: 12
                                                font.weight: Font.Medium
                                                color: "#1F2937"
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                            Text {
                                                text: getFileSize(
                                                          model.filePath)
                                                font.pixelSize: 10
                                                color: "#6B7280"
                                                Layout.fillWidth: true
                                            }
                                        }
                                    }
                                    Button {
                                        width: 24
                                        height: 24
                                        flat: true

                                        background: Rectangle {
                                            radius: 12
                                            color: {
                                                if (parent.pressed)
                                                    return "#FEE2E2"
                                                if (parent.hovered)
                                                    return "#FEF2F2"
                                                return "transparent"
                                            }
                                            border.color: parent.hovered ? "#F87171" : "transparent"
                                            border.width: 1

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 150
                                                }
                                            }
                                        }

                                        contentItem: Text {
                                            text: "🗑"
                                            font.pixelSize: 10
                                            color: parent.hovered ? "#EF4444" : "#9CA3AF"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 150
                                                }
                                            }
                                        }

                                        onClicked: {
                                            fileListModel.remove(index)
                                        }

                                        ToolTip.visible: hovered
                                        ToolTip.text: "移除文件"
                                        ToolTip.delay: 500
                                    }
                                }
                            }
                        }
                    }

                    // 底部统计信息
                    Rectangle {
                        Layout.fillWidth: true
                        height: 32
                        color: "#F9FAFB"
                        radius: 4
                        border.color: "#E5E7EB"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12

                            Text {
                                text: `已选择 ${getSelectedCount(
                                          )} / ${fileListModel.count} 个文件`
                                font.pixelSize: 11
                                color: "#6B7280"
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Button {
                                text: "清空列表"
                                flat: true
                                enabled: fileListModel.count > 0
                                Layout.preferredHeight: 24

                                background: Rectangle {
                                    radius: 4
                                    color: {
                                        if (!parent.enabled)
                                            return "transparent"
                                        if (parent.pressed)
                                            return "#FEE2E2"
                                        if (parent.hovered)
                                            return "#FEF2F2"
                                        return "transparent"
                                    }
                                    border.color: parent.hovered
                                                  && parent.enabled ? "#F87171" : "transparent"
                                    border.width: 1
                                }

                                contentItem: Text {
                                    text: parent.text
                                    font.pixelSize: 10
                                    color: parent.enabled ? (parent.hovered ? "#EF4444" : "#9CA3AF") : "#D1D5DB"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                onClicked: {
                                    clearConfirmDialog.open()
                                }
                            }
                        }
                    }

                    // 空状态显示
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: fileListModel.count === 0

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 16

                            Rectangle {
                                width: 80
                                height: 80
                                radius: 40
                                color: "#F3F4F6"
                                Layout.alignment: Qt.AlignHCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: "📁"
                                    font.pixelSize: 32
                                    opacity: 0.5
                                }
                            }

                            Text {
                                text: "暂无选择文件"
                                font.pixelSize: 16
                                font.weight: Font.Medium
                                color: "#9CA3AF"
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: "点击上方按钮选择要上传的文件"
                                font.pixelSize: 13
                                color: "#D1D5DB"
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Button {
                                text: "选择文件"
                                Layout.alignment: Qt.AlignHCenter

                                background: Rectangle {
                                    radius: 8
                                    color: {
                                        if (parent.pressed)
                                            return "#2563EB"
                                        if (parent.hovered)
                                            return "#3B82F6"
                                        return "#60A5FA"
                                    }

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }
                                }

                                contentItem: Text {
                                    text: parent.text
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    color: "#FFFFFF"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                onClicked: openFileDialog()
                            }
                        }
                    }
                }
            }
        }
    }

    // 添加到 FileUpLoadDialog 的函数区域
    function getSelectedCount() {
        var count = 0
        for (var i = 0; i < fileListModel.count; i++) {
            if (fileListModel.get(i).selected) {
                count++
            }
        }
        return count
    }

    function getFileTypeIcon(fileName) {
        if (!fileName)
            return "📄"

        const ext = fileName.split('.').pop().toLowerCase()
        switch (ext) {
        case 'jpg':
        case 'jpeg':
        case 'png':
        case 'gif':
        case 'bmp':
        case 'webp':
            return "🖼"
        case 'mp4':
        case 'avi':
        case 'mov':
        case 'wmv':
        case 'flv':
        case 'mkv':
            return "🎬"
        case 'mp3':
        case 'wav':
        case 'flac':
        case 'm4a':
        case 'aac':
            return "🎵"
        case 'pdf':
            return "📄"
        case 'doc':
        case 'docx':
            return "📝"
        case 'xls':
        case 'xlsx':
        case 'csv':
            return "📊"
        case 'ppt':
        case 'pptx':
            return "📋"
        case 'zip':
        case 'rar':
        case '7z':
        case 'tar':
        case 'gz':
            return "📦"
        case 'txt':
        case 'md':
        case 'log':
            return "📃"
        case 'js':
        case 'ts':
        case 'html':
        case 'css':
        case 'json':
            return "💻"
        case 'exe':
        case 'msi':
        case 'dmg':
            return "⚙️"
        default:
            return "📄"
        }
    }

    function getFileTypeColor(fileName) {
        if (!fileName)
            return "#9CA3AF"

        const ext = fileName.split('.').pop().toLowerCase()
        switch (ext) {
        case 'jpg':
        case 'jpeg':
        case 'png':
        case 'gif':
        case 'bmp':
        case 'webp':
            return "#EC4899" // 粉色 - 图片
        case 'mp4':
        case 'avi':
        case 'mov':
        case 'wmv':
        case 'flv':
        case 'mkv':
            return "#8B5CF6" // 紫色 - 视频
        case 'mp3':
        case 'wav':
        case 'flac':
        case 'm4a':
        case 'aac':
            return "#10B981" // 绿色 - 音频
        case 'pdf':
            return "#EF4444" // 红色 - PDF
        case 'doc':
        case 'docx':
            return "#3B82F6" // 蓝色 - Word
        case 'xls':
        case 'xlsx':
        case 'csv':
            return "#059669" // 绿色 - Excel
        case 'ppt':
        case 'pptx':
            return "#F59E0B" // 橙色 - PowerPoint
        case 'zip':
        case 'rar':
        case '7z':
        case 'tar':
        case 'gz':
            return "#8B5CF6" // 紫色 - 压缩包
        case 'txt':
        case 'md':
        case 'log':
            return "#6B7280" // 灰色 - 文本
        case 'js':
        case 'ts':
        case 'html':
        case 'css':
        case 'json':
            return "#F59E0B" // 橙色 - 代码
        case 'exe':
        case 'msi':
        case 'dmg':
            return "#DC2626" // 深红色 - 可执行文件
        default:
            return "#9CA3AF" // 默认灰色
        }
    }

    function getFileSize(filePath) {
        // 这里可以尝试获取实际文件大小，或返回占位符
        // 由于QML限制，可能需要C++后端支持
        return "获取中..."
    }
}
