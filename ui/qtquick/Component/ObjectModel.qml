import QtQuick 2.15

// 基于 C++ 的 QStandardItemModel 扩展的 QML 模型适配器
QtObject {
    id: modelAdapter
    property var sourceModel: null
    property int rowCount: sourceModel ? sourceModel.rowCount() : 0

    function getRow(row) {
        // 有问题
        if (!sourceModel || row < 0 || row >= sourceModel.rowCount()) {
            return null
        }
        // 每一行属性
        // 构建与 TableModel 兼容的行对象
        // 外部都可以使用 rowData.(type) 访问, 与 C++ 方向一致
        const rowData = {
            "id"// 第 0 列
            : "obj" + row,
            "name"// 第一列
            // 第 1 列名字
            : sourceModel.data(sourceModel.index(row, 0)),
            "size"// 第 2 列
            : sourceModel.data(sourceModel.index(row, 1)),
            "date"// 第 4 列
            : sourceModel.data(sourceModel.index(row, 2))
            // 默认为 false
            // "isFolder": false // 默认值，下面会更新
        }
        // 获取失败

        // 尝试从 UserRole 获取更多数据
        try {
            const userData = sourceModel.data(sourceModel.index(row, 0),
                                              Qt.UserRole)
            if (userData) {
                // 合并用户数据
                for (var key in userData) {
                    console.log("key, data, name------", key,
                                userData[key]) // userData.name 是未定义的
                    // 设置的属性都是正确的
                    rowData[key] = userData[key]
                }
            }
            // // 如果 isFolder 未定义，根据名称判断
            // if (typeof rowData.isFolder === 'undefined') {
            //     const name = rowData.name || ""
            //     // 重复赋值 ???
            //     rowData.isFolder = name.endsWith('/')
            // }
        } catch (e) {
            // bug
            console.error("获取行数据时出错:", e)
            // 保证 isFolder 属性存在
            if (typeof rowData.isFolder === 'undefined') {
                const name = rowData.name || ""
                rowData.isFolder = name.endsWith('/')
            }
        }
        return rowData
    }

    // 连接信号，当源模型变化时更新 rowCount
    function connectSignals() {
        if (sourceModel) {
            sourceModel.rowsInserted.connect(updateRowCount)
            sourceModel.rowsRemoved.connect(updateRowCount)
            sourceModel.modelReset.connect(updateRowCount)
            sourceModel.dataChanged.connect(function () {
                // 发出自定义信号通知数据变化
                dataChanged()
            })
        }
    }

    // 更新行数
    function updateRowCount() {
        rowCount = sourceModel ? sourceModel.rowCount() : 0
    }

    // 自定义信号
    signal dataChanged
}
