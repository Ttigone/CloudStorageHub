////filepath: f:\MyProject\CloudStorageHub\ui\qtquick\Component\PaginationProxyModel.qml
import QtQuick

QtObject {
    id: paginationModel

    // 原始数据源模型
    property var sourceModel: null

    // 分页控制
    property int currentPage: 1
    property int rowsPerPage: 20
    // property int totalCount: sourceModel ? (typeof sourceModel.rowCount
    //                                         === "function" ? sourceModel.rowCount(
    //                                                              ) : 0) : 0
    property int totalCount: updateTotalCount()

    // 代理模型的行数 (当前页的行数)
    property int rowCount: Math.min(
                               rowsPerPage, Math.max(
                                   0,
                                   totalCount - (currentPage - 1) * rowsPerPage))

    // 计算总页数
    property int pageCount: Math.max(1, Math.ceil(totalCount / rowsPerPage))

    // 当源模型或分页参数变化时重新计算
    // onSourceModelChanged: updateTotalCount()
    onCurrentPageChanged: validateCurrentPage()
    onRowsPerPageChanged: validateCurrentPage()

    // 数据更新信号
    signal dataChanged

    // 添加属性来保存连接对象
    property var modelConnections: Connections {
        target: sourceModel // 直接绑定到源模型

        // 连接标准信号
        function onDataChanged() {
            // 出现多次
            // 能够监测到
            console.log("源模型数据已变化")
            console.log("TET: ", getRow(0).isFolder, getRow(0).name)
            updateTotalCount()
            dataChanged()
        }

        function onRowsInserted() {
            console.log("源模型插入了新行")
            updateTotalCount()
            dataChanged()
        }

        function onRowsRemoved() {
            console.log("源模型删除了行")
            updateTotalCount()
            dataChanged()
        }

        function onModelReset() {
            console.log("源模型已重置")
            updateTotalCount()
            dataChanged()
        }

        function onLayoutChanged() {
            console.log("源模型布局已变化")
            updateTotalCount()
            dataChanged()
        }
    }

    // 确保当前页在有效范围内
    function validateCurrentPage() {
        updateTotalCount()
        if (currentPage > pageCount) {
            currentPage = pageCount
        }
        if (currentPage < 1) {
            currentPage = 1
        }
    }

    // 更新总记录数
    function updateTotalCount() {
        var count = 0
        if (sourceModel && typeof sourceModel.rowCount === "function") {
            count = sourceModel.rowCount()
        }

        // 更新属性
        totalCount = count

        // 返回计算结果
        return count
    }

    // 将源模型的行索引转换为代理模型中的行索引
    function sourceToProxyRow(sourceRow) {
        return sourceRow - (currentPage - 1) * rowsPerPage
    }

    // 将代理模型的行索引转换为源模型中的行索引
    function proxyToSourceRow(proxyRow) {
        return proxyRow + (currentPage - 1) * rowsPerPage
    }

    // 通过代理模型索引获取源模型索引
    function index(row, column) {
        if (!sourceModel || row < 0 || row >= rowCount) {
            return null
        }

        const sourceRow = proxyToSourceRow(row)
        return sourceModel.index(sourceRow, column)
    }

    // 通过索引获取数据
    function data(idx, role) {
        if (!idx)
            return null
        return sourceModel.data(idx, role)
    }

    // 获取源模型中当前页的特定行数据
    function getRow(row) {
        if (row < 0 || row >= rowCount) {
            return null
        }

        const sourceRow = proxyToSourceRow(row)
        if (sourceRow < 0 || sourceRow >= totalCount) {
            return null
        }

        // 如果源模型有getRow函数，使用它
        if (sourceModel && typeof sourceModel.getRow === "function") {
            return sourceModel.getRow(sourceRow)
        }

        // 否则尝试手动构建行数据
        try {
            const idx = sourceModel.index(sourceRow, 0)
            if (!idx || !idx.valid)
                return null

            const userData = sourceModel.data(idx, Qt.UserRole)
            const displayData = sourceModel.data(idx, Qt.DisplayRole)

            // return {
            //     id: "obj" + sourceRow,
            //     name: displayData,
            //     ...userData // 展开UserRole中的所有属性
            // }
            // 修改为:
            var result = {
                "id": "obj" + sourceRow,
                "name": displayData
            }

            // 手动复制 userData 中的属性
            if (userData) {
                if (userData.isFolder !== undefined)
                    result.isFolder = userData.isFolder
                if (userData.key !== undefined)
                    result.key = userData.key
                if (userData.size !== undefined)
                    result.size = userData.size
                if (userData.lastModified !== undefined)
                    result.date = userData.lastModified
                // 添加其他可能需要的属性
            }

            return result
        } catch (e) {
            console.error("获取行数据失败:", e)
            return null
        }
    }

    // 上一页
    function previousPage() {
        if (currentPage > 1) {
            currentPage--
            return true
        }
        return false
    }

    // 下一页
    function nextPage() {
        if (currentPage < pageCount) {
            currentPage++
            return true
        }
        return false
    }

    // 跳转到指定页
    function goToPage(page) {
        if (page >= 1 && page <= pageCount) {
            currentPage = page
            dataChanged() // 添加这行，确保发出信号
            return true
        }
        return false
    }

    // 修改源模型变化处理
    onSourceModelChanged: {
        // 更新
        console.log("代理模型源已更新为:", sourceModel)

        // 必须刷新 modelConnections 的 target
        if (modelConnections) {
            modelConnections.target = sourceModel
        }

        // 更新总记录数并通知变化
        updateTotalCount()
        dataChanged()
        // 重置分页状态
        currentPage = 1

        // 输出调试信息
        console.log("分页代理模型源已更新，总记录数:", totalCount)
    }
}
