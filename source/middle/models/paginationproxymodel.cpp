////filepath:
/// f:\MyProject\CloudStorageHub\source\middle\models\PaginationProxyModel.cpp
#include "PaginationProxyModel.h"
#include <QDebug>

PaginationProxyModel::PaginationProxyModel(QObject *parent)
    : QAbstractProxyModel(parent) {}

void PaginationProxyModel::setSourceModel(QAbstractItemModel *sourceModel) {
  // 断开与旧模型的连接
  if (this->sourceModel()) {
    disconnect(this->sourceModel(), &QAbstractItemModel::dataChanged, this,
               &PaginationProxyModel::handleSourceModelDataChanged);
    disconnect(this->sourceModel(), &QAbstractItemModel::modelReset, this,
               &PaginationProxyModel::handleSourceModelReset);
    disconnect(this->sourceModel(), &QAbstractItemModel::rowsInserted, this,
               &PaginationProxyModel::handleSourceModelRowsInserted);
    disconnect(this->sourceModel(), &QAbstractItemModel::rowsRemoved, this,
               &PaginationProxyModel::handleSourceModelRowsRemoved);
  }

  // 设置新模型
  QAbstractProxyModel::setSourceModel(sourceModel);

  // 连接新模型的信号
  if (sourceModel) {
    connect(sourceModel, &QAbstractItemModel::dataChanged, this,
            &PaginationProxyModel::handleSourceModelDataChanged);
    connect(sourceModel, &QAbstractItemModel::modelReset, this,
            &PaginationProxyModel::handleSourceModelReset);
    connect(sourceModel, &QAbstractItemModel::rowsInserted, this,
            &PaginationProxyModel::handleSourceModelRowsInserted);
    connect(sourceModel, &QAbstractItemModel::rowsRemoved, this,
            &PaginationProxyModel::handleSourceModelRowsRemoved);
  }

  // 更新总记录数
  updateTotalCount();

  // 发出信号
  emit paginationDataChanged();

  // 重置模型
  beginResetModel();
  endResetModel();
}

QModelIndex
PaginationProxyModel::mapToSource(const QModelIndex &proxyIndex) const {
  if (!proxyIndex.isValid() || !sourceModel()) {
    return QModelIndex();
  }
  // 计算源模型中的行
  // int sourceRow = proxyRowToSourceRow(proxyIndex.row());
  // 将代理模型行索引映射到源模型中的行索引
  // 代理模型行 0 应该映射到源模型中 (当前页 - 1) * 每页行数 + 代理行
  int sourceRow = (m_currentPage - 1) * m_rowsPerPage + proxyIndex.row();
  // qDebug() << "source Row" << sourceRow;

  // 如果行超出范围，返回无效索引
  if (sourceRow < 0 || sourceRow >= sourceModel()->rowCount()) {
    return QModelIndex();
  }

  return sourceModel()->index(sourceRow, proxyIndex.column());
}

QModelIndex
PaginationProxyModel::mapFromSource(const QModelIndex &sourceIndex) const {
  if (!sourceIndex.isValid() || !sourceModel())
    return QModelIndex();

  // 计算源模型行在代理中的位置
  int sourceRow = sourceIndex.row();
  int firstRow = (m_currentPage - 1) * m_rowsPerPage;
  int lastRow = qMin(firstRow + m_rowsPerPage - 1, m_totalCount - 1);

  // qDebug() << "MapFromSource";
  // qDebug() << sourceRow << firstRow << lastRow;

  // 如果源行不在当前页范围内，返回无效索引
  if (sourceRow < firstRow || sourceRow > lastRow)
    return QModelIndex();

  // 计算代理行
  int proxyRow = sourceRow - firstRow;
  // qDebug() << proxyRow;

  return index(proxyRow, sourceIndex.column());
}

QVariant PaginationProxyModel::data(const QModelIndex &index, int role) const {
  QModelIndex sourceIndex = mapToSource(index);
  if (!sourceIndex.isValid()) {
    return QVariant();
  }
  return sourceModel()->data(sourceIndex, role);
}

int PaginationProxyModel::rowCount(const QModelIndex &parent) const {
  if (parent.isValid() || !sourceModel()) {
    return 0;
  }

  // 计算当前页显示的行数
  int firstRow = (m_currentPage - 1) * m_rowsPerPage;
  // qDebug() << "First Row:" << firstRow;
  // qDebug() << "Total Count:" << m_totalCount;
  // qDebug() << "Rows Per Page:" << m_rowsPerPage;

  // qDebug() << "计算行数" << qMin(m_rowsPerPage, m_totalCount - firstRow);
  // 返回 20
  return qMin(m_rowsPerPage, m_totalCount - firstRow);
}

int PaginationProxyModel::columnCount(const QModelIndex &parent) const {
  if (!sourceModel())
    return 0;

  return sourceModel()->columnCount(parent);
}

QModelIndex PaginationProxyModel::index(int row, int column,
                                        const QModelIndex &parent) const {
  if (parent.isValid() || !sourceModel() || row < 0 || row >= rowCount() ||
      column < 0 || column >= columnCount())
    return QModelIndex();

  return createIndex(row, column);
}

QModelIndex PaginationProxyModel::parent(const QModelIndex &child) const {
  Q_UNUSED(child);
  return QModelIndex(); // 扁平模型，无父级
}

int PaginationProxyModel::currentPage() const { return m_currentPage; }

int PaginationProxyModel::rowsPerPage() const { return m_rowsPerPage; }

int PaginationProxyModel::totalCount() const { return m_totalCount; }

int PaginationProxyModel::pageCount() const {
  if (m_rowsPerPage <= 0)
    return 1;

  return qMax(1, (m_totalCount + m_rowsPerPage - 1) / m_rowsPerPage);
}

bool PaginationProxyModel::goToPage(int page) {
  if (page < 1 || page > pageCount()) {
    qDebug() << "无效页";
    return false;
  }
  if (m_currentPage != page) {
    beginResetModel();
    m_currentPage = page;
    endResetModel();

    emit currentPageChanged();
    emit paginationDataChanged();
  }
  emit currentPageRowCountChanged();
  return true;
}

QVariantMap PaginationProxyModel::getRow(int row) const {
  QVariantMap result;

  if (!sourceModel() || row < 0 || row >= rowCount())
    return result;

  // 计算源模型中的行索引
  int sourceRow = proxyRowToSourceRow(row);

  // 获取所有列的数据
  for (int col = 0; col < columnCount(); ++col) {
    QModelIndex idx = sourceModel()->index(sourceRow, col);
    QString key;

    // 根据列设置键名
    switch (col) {
    case 0:
      key = "name";
      break;
    case 1:
      key = "size";
      break;
    case 2:
      key = "date";
      break;
    default:
      key = QString("column%1").arg(col);
      break;
    }

    // 添加DisplayRole数据
    result[key] = sourceModel()->data(idx, Qt::DisplayRole);

    // 对于第一列，还要获取UserRole数据
    if (col == 0) {
      QVariant userData = sourceModel()->data(idx, Qt::UserRole);
      if (userData.userType() == QMetaType::QVariantMap) {
        QVariantMap userDataMap = userData.toMap();
        // 合并UserRole中的所有数据
        for (auto it = userDataMap.begin(); it != userDataMap.end(); ++it) {
          result[it.key()] = it.value();
        }
      }
    }
  }

  // 添加行索引用于选择
  result["id"] = QString("obj%1").arg(sourceRow);
  result["sourceRow"] = sourceRow;

  return result;
}

void PaginationProxyModel::updateTotalCount() {
  int oldCount = m_totalCount;
  m_totalCount = sourceModel() ? sourceModel()->rowCount() : 0;

  if (oldCount != m_totalCount) {
    emit totalCountChanged();
    emit pageCountChanged();

    // 如果当前页超出范围，自动调整
    if (m_currentPage > pageCount()) {
      setCurrentPage(pageCount());
    }
  }
}

void PaginationProxyModel::setCurrentPage(int page) {
  if (page < 1)
    page = 1;

  if (page > pageCount())
    page = pageCount();

  if (m_currentPage != page) {
    beginResetModel();
    m_currentPage = page;
    endResetModel();

    emit currentPageChanged();
    emit paginationDataChanged();
  }
}

// void PaginationProxyModel::setRowsPerPage(int count) {
//   // 这里执行了
//   // 切换后没有反应
//   qDebug() << "测试切换每页行数" << count;
//   if (count < 1) {
//     count = 1;
//   }

//   qDebug() << m_rowsPerPage << count;
//   if (m_rowsPerPage != count) {
//     beginResetModel();
//     m_rowsPerPage = count; // 改变
//     endResetModel();

//     // for (int i = 0; i < rowCount(); ++i) {
//     // bool hidden = (i < start || i >= (start + maxLen));
//     // ui->tableView->setRowHidden(i, hidden); // 隐藏非当前页内容
//     // }

//     emit rowsPerPageChanged();
//     emit pageCountChanged();
//     qDebug() << "发射信号"; // 发射

//     // 如果当前页超出范围，自动调整
//     if (m_currentPage > pageCount()) {
//       qDebug() << "超出";
//       setCurrentPage(pageCount());
//     }
//     emit dataChanged();
//   }
// }
////filepath:
/// f:\MyProject\CloudStorageHub\source\middle\models\paginationproxymodel.cpp
void PaginationProxyModel::setRowsPerPage(int count) {
  // qDebug() << "设置每页行数:" << count;
  if (count < 1) {
    count = 1;
  }

  if (m_rowsPerPage != count) {
    // 重要：保存旧值用于调试
    int oldRowsPerPage = m_rowsPerPage;
    int oldPageCount = pageCount();

    // 开始重置模型
    beginResetModel();
    m_rowsPerPage = count;
    endResetModel();

    // 发出标准信号和自定义信号
    emit rowsPerPageChanged();
    emit pageCountChanged();

    // 触发布局变化信号 - 这是标准模型信号
    emit layoutChanged();

    // 触发标准数据变化信号 - 这对某些视图很重要
    emit dataChanged(index(0, 0), index(rowCount() - 1, columnCount() - 1));

    // 触发自定义信号
    // emit dataChanged();
    emit paginationDataChanged();

    // 输出详细的调试信息
    // qDebug() << "每页行数已从" << oldRowsPerPage << "更改为" <<
    // m_rowsPerPage; qDebug() << "总页数从" << oldPageCount << "变为" <<
    // pageCount(); qDebug() << "当前页:" << m_currentPage << "当前页记录数:" <<
    // rowCount();

    // 如果当前页超出范围，自动调整
    if (m_currentPage > pageCount()) {
      qDebug() << "当前页超出范围，调整为" << pageCount();
      setCurrentPage(pageCount());
    }
  } else {
    qDebug() << "每页行数未变化，保持" << count;
  }
  emit currentPageRowCountChanged();
}

void PaginationProxyModel::handleSourceModelDataChanged(
    const QModelIndex &topLeft, const QModelIndex &bottomRight,
    const QVector<int> &roles) {
  Q_UNUSED(roles);
  // qDebug() << "执行改变";

  // 检查是否有变化的行在当前页中
  int firstSourceRow = topLeft.row();
  int lastSourceRow = bottomRight.row();
  int firstPageRow = (m_currentPage - 1) * m_rowsPerPage;
  int lastPageRow = qMin(firstPageRow + m_rowsPerPage - 1, m_totalCount - 1);
  // qDebug() << firstSourceRow << lastPageRow << firstPageRow << lastPageRow;

  // 如果变化的行与当前页有交集，通知视图更新
  if (firstSourceRow <= lastPageRow && lastSourceRow >= firstPageRow) {
    // emit dataChanged();
    emit paginationDataChanged();
  }
}

void PaginationProxyModel::handleSourceModelReset() {
  beginResetModel();
  updateTotalCount();
  endResetModel();

  emit paginationDataChanged();
}

void PaginationProxyModel::handleSourceModelRowsInserted(
    const QModelIndex &parent, int first, int last) {
  Q_UNUSED(parent);
  Q_UNUSED(first);
  Q_UNUSED(last);

  // 更新总数并重置模型
  beginResetModel();
  updateTotalCount();
  endResetModel();

  emit paginationDataChanged();
}

void PaginationProxyModel::handleSourceModelRowsRemoved(
    const QModelIndex &parent, int first, int last) {
  Q_UNUSED(parent);
  Q_UNUSED(first);
  Q_UNUSED(last);

  // 更新总数并重置模型
  beginResetModel();
  updateTotalCount();
  endResetModel();

  emit paginationDataChanged();
}

int PaginationProxyModel::proxyRowToSourceRow(int proxyRow) const {
  return (m_currentPage - 1) * m_rowsPerPage + proxyRow;
}
