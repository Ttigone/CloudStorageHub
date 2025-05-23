#ifndef CONFIGMANAGER_HPP
#define CONFIGMANAGER_HPP

#include <QObject>
#include <QSettings>
#include <QString>
#include <QStringList>


class ConfigManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString secretId READ secretId WRITE setSecretId NOTIFY secretIdChanged)
    Q_PROPERTY(QString remark READ remark WRITE setRemark NOTIFY remarkChanged)
    Q_PROPERTY(bool rememberSession READ rememberSession WRITE setRememberSession NOTIFY rememberSessionChanged)
    Q_PROPERTY(QStringList secretIdHistory READ secretIdHistory NOTIFY secretIdHistoryChanged)
    Q_PROPERTY(QStringList remarkHistory READ remarkHistory NOTIFY remarkHistoryChanged)

public:
    explicit ConfigManager(QObject* parent = nullptr);
    ~ConfigManager();

    // 属性访问方法
    QString secretId() const;
    void setSecretId(const QString& value);

    QString secretKey() const;
    void setSecretKey(const QString& value);

    QString remark() const;
    void setRemark(const QString& value);

    bool rememberSession() const;
    void setRememberSession(bool value);

    QStringList secretIdHistory() const;
    QStringList remarkHistory() const;

    // QML 调用的方法
    Q_INVOKABLE void saveLoginConfig();
    Q_INVOKABLE void loadLoginConfig();
    Q_INVOKABLE void clearLoginConfig();
    Q_INVOKABLE void addToHistory(const QString& secretId, const QString& remark);
    Q_INVOKABLE void removeFromHistory(const QString& value);
    Q_INVOKABLE QString findMatchingKey(const QString& secretId);

signals:
    void secretIdChanged(const QString& secretId);
    void secretKeyChanged(const QString& secretKey);
    void remarkChanged(const QString& remark);
    void rememberSessionChanged(bool rememberSession);
    void secretIdHistoryChanged();
    void remarkHistoryChanged();

private:
    QSettings m_settings;
    QString m_secretId;
    QString m_secretKey;
    QString m_remark;
    bool m_rememberSession;
    QStringList m_secretIdHistory;
    QStringList m_remarkHistory;

    // 私有方法
    void loadHistoryFromSettings();
    void saveHistoryToSettings();
};

#endif
