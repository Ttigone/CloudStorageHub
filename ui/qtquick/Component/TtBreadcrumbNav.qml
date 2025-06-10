import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    // 公开属性 - 允许外部配置
    property string m_rootName: "" // 根目录名称
    property var m_model: [] // 导航路径模型
    property color backgroundColor: "#F0F2F5"
    property color textColor: "#0066CC"
    property color separatorColor: "#666666"
    property color homeIconColor: "#333333"
    property string homeIcon: "🏠" // 点击时, 显示当前的桶列表
    property bool showHomeIcon: true

    // 信号 将当前点击到项的 string 传递出去
    signal pathItemClicked(string itemId)
    signal pathChanged

    color: backgroundColor
    height: 30

    // 修改 setPath 函数
    function setPath(newPath) {
        // 使用深度比较，避免不必要的更新
        if (JSON.stringify(m_model) !== JSON.stringify(newPath)) {
            // 断开可能的循环
            var temp = newPath
            // 使用 Qt.callLater 延迟发送信号，打破可能的循环
            Qt.callLater(function () {
                m_model = temp
                pathChanged()
            })
        }
    }
    function addPathItem(id, name) {
        console.log("添加路径项: ", id, name)
        // 获取的没有问题
        // 验证输入参数
        // 添加失败
        if (!id || !name) {
            console.error("添加面包屑项失败：id 或 name 为空", id, name)
            return
        }

        const newItem = {
            "id": String(id),
            "name": String(name)
        }

        console.log("创建的新项:", JSON.stringify(newItem))

        // 查找 ID 与传入 ID 参数匹配的项, 如果找到, findIndex 返回该项的索引；如果没找到，则返回 -1
        // const existingIndex = m_model.findIndex(item => item.id === id)
        const existingIndex = m_model.findIndex(item => item
                                                && item.id === newItem.id)
        // 返回 -1, 空
        console.log("查找现有索引:", existingIndex, "当前模型:", JSON.stringify(m_model))

        if (existingIndex >= 0) {
            // 如果存在，截断到此位置
            const newPath = m_model.slice(0, existingIndex + 1)
            console.log("截断路径到现有位置:", JSON.stringify(newPath))
            setPath(newPath)
        } else {
            // 如果不存在，添加到路径末尾
            const newPath = [...m_model, newItem]
            console.log("添加新项到路径末尾:", JSON.stringify(newPath))
            setPath(newPath)
        }
    }
    // 导航到特定层级
    function navigateToLevel(level) {
        if (level >= 0 && level < m_model.length) {
            const newPath = m_model.slice(0, level + 1)
            setPath(newPath)
        }
    }

    function resetToRoot() {
        console.log("重置面包屑导航到根目录")
        // 确保彻底清空现有模型，再创建新模型
        m_model = []
    }

    function clearModel() {
        console.log("完全清除面包屑导航模型")
        // 设置空模型
        setPath([])
        // 发出路径变化信号
        pathChanged()
    }

    function setRootName(rootName) {
        m_rootName = rootName
        resetToRoot()
    }

    function getCurrentPath() {
        // if (m_model.length > 0) {
        //     console.log("返回空")
        //     return ""
        // }
        if (m_model.length === 0) {
            console.log("返回空")
            return ""
        }
        console.log("返回名字: ", m_model[m_model.length - 1].name)
        return m_model[m_model.length - 1].name
    }

    // 布局
    RowLayout {
        anchors {
            fill: parent
            leftMargin: 16
            rightMargin: 16
        }
        spacing: 4

        // 主页/根目录图标
        Rectangle {
            visible: showHomeIcon
            width: 24
            height: 24
            color: "transparent"
            Layout.alignment: Qt.AlignVCenter

            // 根文本图标
            Text {
                anchors.centerIn: parent
                text: homeIcon
                font.pixelSize: 16
                color: homeIconColor
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    // 显示桶列表
                    // 清空存在的列表
                    console.log("点击主页图标，重置到根路径, 显示桶列表")
                    pathItemClicked("root")
                    resetToRoot()
                    // 发出信号, 让外部显示根目录
                    // root.m_model.clear()
                }
            }
        }

        // // 使用 ListView 实现面包屑
        // ListView {
        //     id: breadcrumbList
        //     Layout.fillWidth: true
        //     Layout.preferredHeight: 30
        //     orientation: ListView.Horizontal
        //     model: root.m_model
        //     interactive: true
        //     clip: true
        //     spacing: 4
        //     boundsBehavior: Flickable.StopAtBounds

        //     // 当路径变化时自动滚动到最右侧
        //     onCountChanged: {
        //         positionViewAtEnd()
        //     }

        //     delegate: Row {
        //         spacing: 4
        //         height: breadcrumbList.height

        //         // 分隔符
        //         Text {
        //             text: "/"
        //             font.pixelSize: 14
        //             color: separatorColor
        //             verticalAlignment: Text.AlignVCenter
        //             height: parent.height
        //             // 分隔符的可视化, 索引大于 0, 对应的 id 值为 非 root, 或者不是 all
        //             visible: index > 0 || (modelData.id !== "root"
        //                                    && modelData.id !== "all")
        //         }
        //         Text {
        //             id: pathItemText
        //             // text: modelData.name
        //             font.pixelSize: 14
        //             color: textColor
        //             verticalAlignment: Text.AlignVCenter
        //             height: parent.height
        //             MouseArea {
        //                 anchors.fill: parent
        //                 cursorShape: Qt.PointingHandCursor
        //                 onClicked: {
        //                     console.log("index: ", index)
        //                     root.navigateToLevel(index)
        //                     // 会将当前点击的值发送
        //                     console.log("导航到文件夹:", modelData.name)
        //                     // pathItemClicked(modelData.name)
        //                     pathItemClicked(modelData.id)
        //                 }
        //             }
        //         }
        //     }

        //     // 添加水平滚动条
        //     ScrollBar.horizontal: ScrollBar {
        //         policy: ScrollBar.AsNeeded
        //         interactive: true
        //         height: 8
        //     }
        // }
        // 修改 ListView 配置
        ListView {
            id: breadcrumbList
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            orientation: ListView.Horizontal
            model: root.m_model
            interactive: true
            clip: true
            spacing: 4
            boundsBehavior: Flickable.StopAtBounds

            // 添加调试属性
            property bool debugMode: true

            // 当模型变化时的处理
            onModelChanged: {
                if (debugMode) {
                    console.log("ListView 模型变化:",
                                model ? JSON.stringify(model) : "null")
                    console.log("ListView 项目数量:", count)
                }
            }

            onCountChanged: {
                if (debugMode) {
                    console.log("ListView 项目数量变化:", count)
                }
                positionViewAtEnd()
            }

            // 确保模型正确绑定
            Binding {
                target: breadcrumbList
                property: "model"
                value: root.m_model
                when: root.m_model !== undefined
            }

            delegate: Row {
                spacing: 4
                height: breadcrumbList.height

                // 添加调试信息
                Component.onCompleted: {
                    console.log("Delegate 创建 - 索引:", index, "数据:",
                                JSON.stringify(modelData))
                }

                // 分隔符
                Text {
                    text: "/"
                    font.pixelSize: 14
                    color: separatorColor
                    verticalAlignment: Text.AlignVCenter
                    height: parent.height
                    visible: index > 0
                }

                // 路径项文本
                Text {
                    id: pathItemText
                    text: {
                        if (!modelData) {
                            console.warn("modelData 为空，索引:", index)
                            return "空数据"
                        }
                        if (!modelData.name) {
                            console.warn("modelData.name 为空，数据:",
                                         JSON.stringify(modelData))
                            return "未知项"
                        }
                        return modelData.name
                    }
                    font.pixelSize: 14
                    color: textColor
                    verticalAlignment: Text.AlignVCenter
                    height: parent.height

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onContainsMouseChanged: {
                            pathItemText.font.underline = containsMouse
                        }

                        onClicked: {
                            console.log("点击面包屑项:", index, "数据:",
                                        JSON.stringify(modelData))
                            root.navigateToLevel(index)
                            if (modelData && modelData.id) {
                                pathItemClicked(modelData.id)
                            }
                        }
                    }
                }
            }

            // 添加水平滚动条
            ScrollBar.horizontal: ScrollBar {
                policy: ScrollBar.AsNeeded
                interactive: true
                height: 8
            }
        }
    }

    // 当组件完成加载时，确保有默认的根路径
    Component.onCompleted: {

    }
}
