#include "historymanager.h"
#include "config/global.h"
#include "source/helper/dbsqlite.h"

HistoryManager::HistoryManager(QObject *parent) : QObject(parent) {
  m_db = new DbSqlite();
}

HistoryManager::~HistoryManager() {
  if (m_db) {
    delete m_db;
    m_db = nullptr;
  }
}

bool HistoryManager::initDatabase() {
  try {
    QString dbPath = getDatabasePath();
    // qDebug() << "初始化历史记录数据库:" << dbPath;

    if (m_db) {
      if (!m_db->isConnected() || m_db->databasePath() != dbPath) {
        m_db->connect(dbPath);
      }
      return createTables();
    }
    return false;
  } catch (const QString &error) {
    qWarning() << "初始化历史记录数据库失败:" << error;
    return false;
  } catch (...) {
    qWarning() << "初始化历史记录数据库时发生未知错误";
    return false;
  }
}

bool HistoryManager::addDownloadRecord(const QVariantMap &record) {
  if (!m_db || !m_db->isConnected()) {
    return false;
  }

  try {
    // 插入语句
    QString sql = R"(
      INSERT OR REPLACE INTO download_history
      (job_id, file_name, file_size, bucket_name, object_key, local_path,
       status, start_time, completed_time)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    )";

    QVariantList params;
    params << record.value("jobId").toString()
           << record.value("fileName").toString()
           << record.value("fileSize").toLongLong()
           << record.value("bucketName").toString()
           << record.value("objectKey").toString()
           << record.value("localPath").toString()
           << record.value("status", "completed").toString()
           << record.value("startTime").toLongLong()
           << record.value("completedTime").toLongLong();

    m_db->exec(sql, params);
    // qDebug() << "添加下载记录成功:" << record.value("fileName").toString();

    emit downloadHistoryChanged();
    return true;
  } catch (const QString &error) {
    // BUG 这里出现错误
    qWarning() << "添加下载记录失败:" << error;
    return false;
  }
}

QVariantList HistoryManager::getDownloadHistory(int limit) {
  QVariantList history;
  if (!m_db || !m_db->isConnected()) {
    return history;
  }

  try {
    QString sql = R"(
      SELECT job_id, file_name, file_size, bucket_name, object_key,
             local_path, status, start_time, completed_time, created_at
      FROM download_history
      ORDER BY completed_time DESC, created_at DESC
      LIMIT ?
    )";

    QVariantList params;
    params << limit;

    // QList<RECORD> records = m_db->select(sql.arg(limit));
    QSqlQuery query = m_db->exec(sql, params);

    while (query.next()) {
      QVariantMap historyItem;
      historyItem["jobId"] = query.value("job_id");
      historyItem["fileName"] = query.value("file_name");
      historyItem["fileSize"] = query.value("file_size");
      historyItem["bucketName"] = query.value("bucket_name");
      historyItem["objectKey"] = query.value("object_key");
      historyItem["localPath"] = query.value("local_path");
      historyItem["status"] = query.value("status");
      historyItem["startTime"] = query.value("start_time");
      historyItem["completedTime"] = query.value("completed_time");
      historyItem["createdAt"] = query.value("created_at");

      history.append(historyItem);
    }
    // qDebug() << "获取下载历史成功，记录数:" << history.size();
  } catch (const QString &error) {
    qWarning() << "获取下载历史失败:" << error;
  }

  return history;
}

bool HistoryManager::removeDownloadRecord(const QString &jobId) {
  if (!m_db || !m_db->isConnected()) {
    return false;
  }

  try {
    QString sql = "DELETE FROM download_history WHERE job_id = ?";
    QVariantList params;
    params << jobId;

    m_db->exec(sql, params);
    // qDebug() << "删除下载记录成功:" << jobId;

    emit downloadHistoryChanged();
    return true;
  } catch (const QString &error) {
    qWarning() << "删除下载记录失败:" << error;
    return false;
  }
}

bool HistoryManager::clearDownloadHistory() {
  if (!m_db || !m_db->isConnected()) {
    return false;
  }

  try {
    m_db->exec("DELETE FROM download_history");
    // qDebug() << "清空下载历史成功";

    emit downloadHistoryChanged();
    return true;
  } catch (const QString &error) {
    qWarning() << "清空下载历史失败:" << error;
    return false;
  }
}

QVariantList HistoryManager::getUploadHistory(int limit) {
  QVariantList history;
  if (!m_db || !m_db->isConnected()) {
    return history;
  }

  try {
    // 🔥 同样修复上传历史查询
    QString sql = R"(
      SELECT job_id, file_name, file_size, bucket_name, remote_path,
             local_path, status, start_time, completed_time, created_at
      FROM upload_history
      ORDER BY completed_time DESC, created_at DESC
      LIMIT ?
    )";

    QVariantList params;
    params << limit;

    QSqlQuery query = m_db->exec(sql, params);

    while (query.next()) {
      QVariantMap historyItem;
      historyItem["jobId"] = query.value("job_id");
      historyItem["fileName"] = query.value("file_name");
      historyItem["fileSize"] = query.value("file_size");
      historyItem["bucketName"] = query.value("bucket_name");
      historyItem["remotePath"] = query.value("remote_path");
      historyItem["localPath"] = query.value("local_path");
      historyItem["status"] = query.value("status");
      historyItem["startTime"] = query.value("start_time");
      historyItem["completedTime"] = query.value("completed_time");
      historyItem["createdAt"] = query.value("created_at");

      history.append(historyItem);
    }
    // qDebug() << "获取上传历史成功，记录数:" << history.size();
  } catch (const QString &error) {
    qWarning() << "获取上传历史失败:" << error;
  }

  return history;
}

bool HistoryManager::addUploadRecord(const QVariantMap &record) {
  if (!m_db || !m_db->isConnected()) {
    return false;
  }

  try {
    QString sql = R"(
      INSERT OR REPLACE INTO upload_history
      (job_id, file_name, file_size, bucket_name, remote_path, local_path,
       status, start_time, completed_time)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    )";

    QVariantList params;
    params << record.value("jobId").toString()
           << record.value("fileName").toString()
           << record.value("fileSize").toLongLong()
           << record.value("bucketName").toString()
           << record.value("remotePath").toString()
           << record.value("localPath").toString()
           << record.value("status", "completed").toString()
           << record.value("startTime").toLongLong()
           << record.value("completedTime").toLongLong();

    m_db->exec(sql, params);
    // qDebug() << "添加上传记录成功:" << record.value("fileName").toString();

    emit uploadHistoryChanged();
    return true;
  } catch (const QString &error) {
    qWarning() << "添加上传记录失败:" << error;
    return false;
  }
}

bool HistoryManager::removeUploadRecord(const QString &jobId) {
  if (!m_db || !m_db->isConnected()) {
    return false;
  }

  try {
    QString sql = "DELETE FROM upload_history WHERE job_id = ?";
    QVariantList params;
    params << jobId;

    m_db->exec(sql, params);
    qDebug() << "删除上传记录成功:" << jobId;

    emit uploadHistoryChanged();
    return true;
  } catch (const QString &error) {
    qWarning() << "删除上传记录失败:" << error;
    return false;
  }
}

bool HistoryManager::clearUploadHistory() {
  if (!m_db || !m_db->isConnected()) {
    return false;
  }

  try {
    m_db->exec("DELETE FROM upload_history");
    qDebug() << "清空上传历史成功";

    emit uploadHistoryChanged();
    return true;
  } catch (const QString &error) {
    qWarning() << "清空上传历史失败:" << error;
    return false;
  }
}

bool HistoryManager::addSearchRecord(const QString &query) {
  if (!m_db || !m_db->isConnected() || query.isEmpty()) {
    return false;
  }

  try {
    // 先检查是否已存在
    QString checkSql =
        "SELECT search_count FROM search_history WHERE query = ?";
    QVariantList checkParams;
    checkParams << query;

    QList<RECORD> existingRecords =
        m_db->select(checkSql.replace("?", "'" + query + "'"));

    if (!existingRecords.isEmpty()) {
      // 已存在，更新计数和时间
      int count = existingRecords.first().value("search_count").toInt();
      QString updateSql = R"(
        UPDATE search_history
        SET search_count = ?, last_used = CURRENT_TIMESTAMP
        WHERE query = ?
      )";

      QVariantList updateParams;
      updateParams << (count + 1) << query;

      m_db->exec(updateSql, updateParams);
    } else {
      // 不存在，插入新记录
      QString insertSql = "INSERT INTO search_history (query) VALUES (?)";
      QVariantList insertParams;
      insertParams << query;

      m_db->exec(insertSql, insertParams);
    }

    emit searchHistoryChanged();
    return true;
  } catch (const QString &error) {
    qWarning() << "添加搜索记录失败:" << error;
    return false;
  }
}

QStringList HistoryManager::getSearchHistory(int limit) {
  QStringList history;
  if (!m_db || !m_db->isConnected()) {
    return history;
  }

  try {
    QString sql = R"(
      SELECT query FROM search_history
      ORDER BY search_count DESC, last_used DESC
      LIMIT ?
    )";

    QList<RECORD> records = m_db->select(sql.arg(limit));

    for (const auto &record : records) {
      history.append(record.value("query").toString());
    }
  } catch (const QString &error) {
    qWarning() << "获取搜索历史失败:" << error;
  }

  return history;
}

bool HistoryManager::removeSearchRecord(const QString &query) {
  if (!m_db || !m_db->isConnected()) {
    return false;
  }

  try {
    QString sql = "DELETE FROM search_history WHERE query = ?";
    QVariantList params;
    params << query;

    m_db->exec(sql, params);

    emit searchHistoryChanged();
    return true;
  } catch (const QString &error) {
    qWarning() << "删除搜索记录失败:" << error;
    return false;
  }
}

bool HistoryManager::clearSearchHistory() {
  if (!m_db || !m_db->isConnected()) {
    return false;
  }

  try {
    m_db->exec("DELETE FROM search_history");
    qDebug() << "清空搜索历史成功";

    emit searchHistoryChanged();
    return true;
  } catch (const QString &error) {
    qWarning() << "清空搜索历史失败:" << error;
    return false;
  }
}

// 统计信息方法
int HistoryManager::getDownloadCount() const {
  if (!m_db || !m_db->isConnected()) {
    return 0;
  }

  try {
    QString sql = "SELECT COUNT(*) as count FROM download_history";
    QList<RECORD> records = m_db->select(sql);

    if (!records.isEmpty()) {
      return records.first().value("count").toInt();
    }
  } catch (const QString &error) {
    qWarning() << "获取下载数量失败:" << error;
  }

  return 0;
}

int HistoryManager::getUploadCount() const {
  if (!m_db || !m_db->isConnected()) {
    return 0;
  }

  try {
    QString sql = "SELECT COUNT(*) as count FROM upload_history";
    QList<RECORD> records = m_db->select(sql);

    if (!records.isEmpty()) {
      return records.first().value("count").toInt();
    }
  } catch (const QString &error) {
    qWarning() << "获取上传数量失败:" << error;
  }

  return 0;
}

qint64 HistoryManager::getTotalDownloadSize() const {
  if (!m_db || !m_db->isConnected()) {
    return 0;
  }

  try {
    QString sql = "SELECT SUM(file_size) as total_size FROM download_history";
    QList<RECORD> records = m_db->select(sql);

    if (!records.isEmpty()) {
      return records.first().value("total_size").toLongLong();
    }
  } catch (const QString &error) {
    qWarning() << "获取下载总大小失败:" << error;
  }

  return 0;
}

qint64 HistoryManager::getTotalUploadSize() const {
  if (!m_db || !m_db->isConnected()) {
    return 0;
  }

  try {
    QString sql = "SELECT SUM(file_size) as total_size FROM upload_history";
    QList<RECORD> records = m_db->select(sql);

    if (!records.isEmpty()) {
      return records.first().value("total_size").toLongLong();
    }
  } catch (const QString &error) {
    qWarning() << "获取上传总大小失败:" << error;
  }

  return 0;
}

QString HistoryManager::getDatabasePath() { return GLOBAL::SQLITE::NAME; }

bool HistoryManager::createTables() {
  if (!m_db) {
    return false;
  }

  try {
    // 创建下载历史表
    QString createDownloadTable = R"(
            CREATE TABLE IF NOT EXISTS download_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                job_id TEXT UNIQUE NOT NULL,
                file_name TEXT NOT NULL,
                file_size INTEGER DEFAULT 0,
                bucket_name TEXT,
                object_key TEXT,
                local_path TEXT,
                status TEXT DEFAULT 'completed',
                start_time INTEGER,
                completed_time INTEGER,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        )";
    m_db->exec(createDownloadTable);

    // 创建上传历史表
    QString createUploadTable = R"(
            CREATE TABLE IF NOT EXISTS upload_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                job_id TEXT UNIQUE NOT NULL,
                file_name TEXT NOT NULL,
                file_size INTEGER DEFAULT 0,
                bucket_name TEXT,
                remote_path TEXT,
                local_path TEXT,
                status TEXT DEFAULT 'completed',
                start_time INTEGER,
                completed_time INTEGER,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        )";
    m_db->exec(createUploadTable);

    // 创建搜索历史表
    QString createSearchTable = R"(
            CREATE TABLE IF NOT EXISTS search_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                query TEXT UNIQUE NOT NULL,
                search_count INTEGER DEFAULT 1,
                last_used DATETIME DEFAULT CURRENT_TIMESTAMP,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        )";
    m_db->exec(createSearchTable);

    qDebug() << "历史记录表创建成功";
    return true;
  } catch (const QString &error) {
    qWarning() << "创建历史记录表失败:" << error;
    return false;
  } catch (...) {
    qWarning() << "创建表时发生未知错误";
    return false;
  }
}
