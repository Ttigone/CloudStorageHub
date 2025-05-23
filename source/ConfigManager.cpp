#include "ConfigManager.hpp"
#include <QDebug>
#include <QDir>
#include <QStandardPaths>

ConfigManager::ConfigManager(QObject* parent)
    : QObject(parent), m_settings("CloudStorageHub", "LoginConfig"), m_secretId(""), m_secretKey(""), m_remark(""), m_rememberSession(false)
{
    loadLoginConfig();
    loadHistoryFromSettings();
}

ConfigManager::~ConfigManager()
{
    if (m_rememberSession) {
        saveLoginConfig();
    }
    saveHistoryToSettings();
}

QString ConfigManager::secretId() const
{
    return m_secretId;
}

void ConfigManager::setSecretId(const QString& value)
{
    if (m_secretId != value) {
        m_secretId = value;
        emit secretIdChanged(m_secretId);
    }
}

QString ConfigManager::secretKey() const
{
    return m_secretKey;
}

void ConfigManager::setSecretKey(const QString& value)
{
    if (m_secretKey != value) {
        m_secretKey = value;
        emit secretKeyChanged(m_secretKey);
    }
}

QString ConfigManager::remark() const
{
    return m_remark;
}

void ConfigManager::setRemark(const QString& value)
{
    if (m_remark != value) {
        m_remark = value;
        emit remarkChanged(m_remark);
    }
}

bool ConfigManager::rememberSession() const
{
    return m_rememberSession;
}

void ConfigManager::setRememberSession(bool value)
{
    if (m_rememberSession != value) {
        m_rememberSession = value;
        emit rememberSessionChanged(m_rememberSession);
    }
}

void ConfigManager::saveLoginConfig()
{
    // if (m_rememberSession) {
    //     m_settings.setValue("secretId", m_secretId);
    //     m_settings.setValue("remark", m_remark);
    //     m_settings.setValue("rememberSession", m_rememberSession);
    //     m_settings.sync();
    //     qDebug() << "Login configuration saved";
    //     addToHistory(m_secretId, m_remark);
    // } else {
    //     clearLoginConfig();
    // }
    if (m_rememberSession) {
        m_settings.setValue("secretId", m_secretId);
        m_settings.setValue("remark", m_remark);

        // 可以选择是否保存 secretKey
        // 如果用户同意保存，可以这样实现：
        if (!m_secretKey.isEmpty()) {
            // 直接保存当前会话的 secretKey
            m_settings.setValue("secretKey", m_secretKey);

            // 同时为此 ID 单独保存一份 Key
            QString keyName = QString("key_%1").arg(m_secretId);
            m_settings.setValue(keyName, m_secretKey);
        }

        m_settings.setValue("rememberSession", m_rememberSession);
        m_settings.sync();
        qDebug() << "Login configuration saved";

        // 添加到历史
        addToHistory(m_secretId, m_remark);
    } else {
        clearLoginConfig();
    }
}

void ConfigManager::loadLoginConfig()
{
    setSecretId(m_settings.value("secretId", "").toString());
    setSecretKey(m_settings.value("secretKey", "").toString()); // 加载 secretKey
    setRemark(m_settings.value("remark", "").toString());
    setRememberSession(m_settings.value("rememberSession", false).toBool());
    qDebug() << "Login configuration loaded";
}

void ConfigManager::clearLoginConfig()
{
    m_settings.remove("secretId");
    m_settings.remove("secretKey");
    m_settings.remove("remark");
    m_settings.remove("rememberSession");
    m_settings.sync();

    setSecretId("");
    setSecretKey("");
    setRemark("");
    setRememberSession(false);
    qDebug() << "Login configuration cleared";
}

void ConfigManager::addToHistory(const QString& secretId, const QString& remark)
{
    if (!secretId.isEmpty()) {
        // 如果已存在则移除
        m_secretIdHistory.removeAll(secretId);
        // 添加到最前
        m_secretIdHistory.prepend(secretId);
        // 限制历史数量
        while (m_secretIdHistory.size() > 10) {
            m_secretIdHistory.removeLast();
        }
        emit secretIdHistoryChanged();
    }

    if (!remark.isEmpty()) {
        m_remarkHistory.removeAll(remark);
        m_remarkHistory.prepend(remark);
        while (m_remarkHistory.size() > 10) {
            m_remarkHistory.removeLast();
        }
        emit remarkHistoryChanged();
    }

    // 保存历史
    saveHistoryToSettings();
}

void ConfigManager::removeFromHistory(const QString& value)
{
    // 检查是否在 secretId 历史记录中
    if (m_secretIdHistory.contains(value)) {
        m_secretIdHistory.removeAll(value);
        emit secretIdHistoryChanged();
    }

    // 检查是否在 remark 历史记录中
    if (m_remarkHistory.contains(value)) {
        m_remarkHistory.removeAll(value);
        emit remarkHistoryChanged();
    }

    // 保存更新后的历史记录
    saveHistoryToSettings();
    qDebug() << "Removed" << value << "from history";
}

// 实现查找匹配 Key 的方法
QString ConfigManager::findMatchingKey(const QString& secretId)
{
    // 如果是当前保存的 ID，返回对应的 Key
    if (secretId == m_settings.value("secretId", "").toString()) {
        // 如果有保存 secretKey，则返回它
        // 注意：通常不建议保存敏感信息如 SecretKey
        return m_settings.value("secretKey", "").toString();
    }

    // 从最近使用的 ID 记录中查找匹配的 Key
    for (int i = 0; i < m_secretIdHistory.size(); ++i) {
        if (m_secretIdHistory[i] == secretId) {
            // 从设置中查找此 ID 对应的 Key
            QString keyName = QString("key_%1").arg(secretId);
            return m_settings.value(keyName, "").toString();
        }
    }

    return QString();
}

void ConfigManager::loadHistoryFromSettings()
{
    m_secretIdHistory = m_settings.value("secretIdHistory").toStringList();
    m_remarkHistory = m_settings.value("remarkHistory").toStringList();
    qDebug() << "History loaded:" << m_secretIdHistory.size() << "secretIds," << m_remarkHistory.size() << "remarks";
}

void ConfigManager::saveHistoryToSettings()
{
    m_settings.setValue("secretIdHistory", m_secretIdHistory);
    m_settings.setValue("remarkHistory", m_remarkHistory);
    m_settings.sync();
    qDebug() << "History saved";
}

QStringList ConfigManager::secretIdHistory() const
{
    return m_secretIdHistory;
}

QStringList ConfigManager::remarkHistory() const
{
    return m_remarkHistory;
}
