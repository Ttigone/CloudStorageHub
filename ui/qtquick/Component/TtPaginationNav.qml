import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// TtPaginationNav.qml
// 分页导航组件
Rectangle {
    id: root
    // 公开属性
    property int totalRecords: 0 // 总记录数
    property int currentPage: 1 // 当前页数
    property int rowsPerPage: 10 // 每页的数量
    property int totalPages: Math.max(1, Math.ceil(
                                          totalRecords / rowsPerPage)) // 总页数

                                          // 计算当前页面应显示的项目数量
    property int itemsOnCurrentPage: totalRecords > 0 ? Math.min(rowsPerPage, totalRecords - (currentPage - 1) * rowsPerPage) : 0
    // 计算当前页面第一个项目的编号 (基于1的索引)
    property int firstItemNumber: totalRecords > 0 ? (currentPage - 1) * rowsPerPage + 1 : 0
    // 计算当前页面最后一个项目的编号
    property int lastItemNumber: totalRecords > 0 ? Math.min(currentPage * rowsPerPage, totalRecords) : 0

    // 可定制的选项
    property var rowsPerPageOptions: [10, 20, 50, 100] // 页面数量选择
    property color backgroundColor: "#F5F6FA"
    property color textColor: "#333333"
    property color accentColor: "#2980B9"
    property color buttonHoverColor: "#E0E0E0"
    property color buttonDisabledColor: "#CCCCCC"

    signal pageRequested(int page)
    signal rowsPerPageRequested(int rows)

    // 组件尺寸
    width: parent.width
    height: 50
    color: backgroundColor

    // 设置页码的函数
    function setPage(page) {
        if (page >= 1 && page <= totalPages && page !== currentPage) {
            currentPage = page
            pageRequested(currentPage) 
        }
    }

    // 转到上一页
    function previousPage() {
        if (currentPage > 1) {
            setPage(currentPage - 1)
        }
    }

    // 转到下一页
    function nextPage() {
        if (currentPage < totalPages) {
            setPage(currentPage + 1)
        }
    }

    // 主布局
    RowLayout {
        anchors {
            fill: parent
            leftMargin: 20
            rightMargin: 20
        }
        spacing: 10

        // 左侧 - 总记录数显示
        Label {
            // text: "共 " + totalRecords + " 条记录" // 原来的
            text: totalRecords > 0 ?
                  qsTr("显示 %1-%2 共 %3 条").arg(firstItemNumber).arg(lastItemNumber).arg(totalRecords) :
                  qsTr("共 0 条记录")
            font.pixelSize: 14
            color: textColor
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
        }

        // 中间弹性空间
        Item {
            Layout.fillWidth: true
        }

        // 中间 - 每页行数设置
        Row {
            spacing: 10
            Layout.alignment: Qt.AlignCenter

            Label {
                text: qsTr("每页显示：")
                font.pixelSize: 14
                color: textColor
                anchors.verticalCenter: parent.verticalCenter
            }

            ComboBox {
                id: rowsPerPageCombo
                width: 80
                height: 30
                model: rowsPerPageOptions
                currentIndex: rowsPerPageOptions.indexOf(rowsPerPage)

                contentItem: Text {
                    text: rowsPerPageCombo.displayText
                    font.pixelSize: 14
                    color: textColor
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }

                background: Rectangle {
                    radius: 4
                    border.color: "#CCCCCC"
                    border.width: 1
                }

                popup: Popup {
                    y: rowsPerPageCombo.height
                    width: rowsPerPageCombo.width
                    implicitHeight: contentItem.implicitHeight
                    padding: 1

                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: rowsPerPageCombo.popup.visible ? rowsPerPageCombo.delegateModel : null

                        ScrollIndicator.vertical: ScrollIndicator {}
                    }

                    background: Rectangle {
                        color: "#FFFFFF"
                        border.color: "#CCCCCC"
                        radius: 4
                    }
                }

                onActivated: {
                    rowsPerPage = rowsPerPageOptions[currentIndex]
                    // 调整当前页码，确保在有效范围内
                    if (currentPage > totalPages) {
                        setPage(totalPages)
                    }
                    rowsPerPageRequested(rowsPerPage) 
                }
            }
        }
        // 中间弹性空间
        Item {
            Layout.fillWidth: true
        }
        // 右侧 - 页码导航
        Row {
            spacing: 10
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            // 上一页按钮
            Button {
                id: prevButton
                width: 32
                height: 32
                text: "◀"
                enabled: currentPage > 1

                contentItem: Text {
                    text: prevButton.text
                    font.pixelSize: 14
                    color: prevButton.enabled ? accentColor : buttonDisabledColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: 4
                    color: prevButton.hovered
                           && prevButton.enabled ? buttonHoverColor : "transparent"
                    border.color: prevButton.enabled ? accentColor : buttonDisabledColor
                    border.width: 1
                }

                onClicked: previousPage()

                ToolTip.visible: hovered && enabled
                ToolTip.text: qsTr("上一页")
                ToolTip.delay: 500
            }

            // 页码显示
            Label {
                text: currentPage + " / " + totalPages
                font.pixelSize: 14
                color: textColor
                anchors.verticalCenter: parent.verticalCenter
                width: 80
                horizontalAlignment: Text.AlignHCenter
            }
            // 下一页按钮
            Button {
                id: nextButton
                width: 32
                height: 32
                text: "▶"
                enabled: currentPage < totalPages

                contentItem: Text {
                    text: nextButton.text
                    font.pixelSize: 14
                    color: nextButton.enabled ? accentColor : buttonDisabledColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 4
                    color: nextButton.hovered
                           && nextButton.enabled ? buttonHoverColor : "transparent"
                    border.color: nextButton.enabled ? accentColor : buttonDisabledColor
                    border.width: 1
                }

                onClicked: nextPage()

                ToolTip.visible: hovered && enabled
                ToolTip.text: qsTr("下一页")
                ToolTip.delay: 500
            }
        }
    }
}
