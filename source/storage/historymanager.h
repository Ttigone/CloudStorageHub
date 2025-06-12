#ifndef HISTORYMANAGER_H
#define HISTORYMANAGER_H

#include <QObject>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

class DbSqlite;

// 任务完成后立即保存
class HistoryManager : public QObject {
  Q_OBJECT
public:
  explicit HistoryManager(QObject *parent = nullptr);
  ~HistoryManager();

  // 初始化数据库
  bool initDatabase();

    // 下载历史记录操作
  Q_INVOKABLE bool addDownloadRecord(const QVariantMap &record);
  Q_INVOKABLE QVariantList getDownloadHistory(int limit = 100);
  Q_INVOKABLE bool removeDownloadRecord(const QString &jobId);
  Q_INVOKABLE bool clearDownloadHistory();

    // 上传历史记录操作
  Q_INVOKABLE bool addUploadRecord(const QVariantMap &record);
  Q_INVOKABLE QVariantList getUploadHistory(int limit = 100);
  Q_INVOKABLE bool removeUploadRecord(const QString &jobId);
  Q_INVOKABLE bool clearUploadHistory();

  // 搜索历史记录操作
  Q_INVOKABLE bool addSearchRecord(const QString &query);
  Q_INVOKABLE QStringList getSearchHistory(int limit = 20);
  Q_INVOKABLE bool removeSearchRecord(const QString &query);
  Q_INVOKABLE bool clearSearchHistory();

  // 获取统计信息
  Q_INVOKABLE int getDownloadCount() const;
  Q_INVOKABLE int getUploadCount() const;
  Q_INVOKABLE qint64 getTotalDownloadSize() const;
  Q_INVOKABLE qint64 getTotalUploadSize() const;

  signals:
  void downloadHistoryChanged();
  void uploadHistoryChanged();
  void searchHistoryChanged();

private:
  bool createTables();
  QString getDatabasePath();

  DbSqlite *m_db;
};

#endif // HISTORYMANAGER_H
