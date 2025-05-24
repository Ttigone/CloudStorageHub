#include "ConfigManager.hpp"
#include <QCoreApplication>
#include <QDebug>
#include <QDir>
#include <QStandardPaths>
#include <memory>

ConfigManager::ConfigManager(QObject* parent)
    // : QObject(parent), m_settings("CloudStorageHub", "LoginConfig"),
    // m_secretId(""), m_secretKey(""), m_remark(""), m_rememberSession(false)
    : QObject(parent), m_secretId(""), m_secretKey(""), m_remark(""),
      m_rememberSession(false)
{
    QString appDir = QCoreApplication::applicationDirPath();
    // 创建 settings 子目录
    QDir settingsDir(appDir + "/settings");
    if (!settingsDir.exists()) {
        settingsDir.mkpath(".");
    }

    // 设置 INI 文件的完整路径
    QString iniFilePath = settingsDir.absolutePath() + "/LoginConfig.ini";
    qDebug() << "Using settings file:" << iniFilePath;

    // 使用自定义文件路径初始化 QSettings
    m_settings = std::make_unique<QSettings>(iniFilePath, QSettings::IniFormat);

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

QString ConfigManager::secretId() const { return m_secretId; }

void ConfigManager::setSecretId(const QString& value)
{
    if (m_secretId != value) {
        m_secretId = value;
        emit secretIdChanged(m_secretId);
    }
}

QString ConfigManager::secretKey() const { return m_secretKey; }

void ConfigManager::setSecretKey(const QString& value)
{
    if (m_secretKey != value) {
        m_secretKey = value;
        emit secretKeyChanged(m_secretKey);
    }
}

QString ConfigManager::remark() const { return m_remark; }

void ConfigManager::setRemark(const QString& value)
{
    if (m_remark != value) {
        m_remark = value;
        emit remarkChanged(m_remark);
    }
}

bool ConfigManager::rememberSession() const { return m_rememberSession; }

void ConfigManager::setRememberSession(bool value)
{
    if (m_rememberSession != value) {
        m_rememberSession = value;
        emit rememberSessionChanged(m_rememberSession);
    }
}

void ConfigManager::saveLoginConfig()
{
    if (m_rememberSession) {
        // 获取到了 key
        qDebug() << "保存当前的会话: " << m_secretId << m_secretKey << m_remark;
        // 要勾选保存会话, 才会保存都应的值
        m_settings->setValue("secretId", m_secretId);
        m_settings->setValue("remark", m_remark);
        if (!m_secretKey.isEmpty()) {
            qDebug() << "key 不为空, 保存: " << m_secretKey;
            m_settings->setValue("secretKey", m_secretKey);
            QString keyName = QString("key_%1").arg(m_secretId);
            m_settings->setValue(keyName, m_secretKey);
            qDebug() << "Saved key for ID:" << m_secretId
                     << "with key name:" << keyName;
        }

        m_settings->setValue("rememberSession", m_rememberSession);
        m_settings->sync();
        // qDebug() << "Login configuration saved" << m_secretId << m_remark;
        // 添加到历史
        addToHistory(m_secretId, m_remark);
    } else {
        // 没有保存当前的会话
        clearLoginConfig();
    }
}

void ConfigManager::loadLoginConfig()
{
    setSecretId(m_settings->value("secretId", "").toString());
    setSecretKey(m_settings->value("secretKey", "").toString()); // 加载 secretKey
    setRemark(m_settings->value("remark", "").toString());
    setRememberSession(m_settings->value("rememberSession", false).toBool());
    qDebug() << "Login configuration loaded";
}

void ConfigManager::clearLoginConfig()
{
    m_settings->remove("secretId");
    m_settings->remove("secretKey");
    m_settings->remove("remark");
    m_settings->remove("rememberSession");
    m_settings->sync();

    setSecretId("");
    setSecretKey("");
    setRemark("");
    setRememberSession(false);
    // 这里被执行了
    qDebug() << "Login configuration cleared";
}

void ConfigManager::addToHistory(const QString& secretId,
                                 const QString& remark)
//  const QString& key)
{
    // 添加到内存中
    if (!secretId.isEmpty()) {
        // 如果已存在则移除
        m_secretIdHistory.removeAll(secretId);
        // 添加到最前
        m_secretIdHistory.prepend(secretId);
        // 限制历史数量
        while (m_secretIdHistory.size() > 10) {
            m_secretIdHistory.removeLast();
        }
        // qDebug() << "发射信号";
        emit secretIdHistoryChanged();

        // 确保每次添加历史记录时也保存当前的密钥
        if (!m_secretKey.isEmpty()) {
            QString keyName = QString("key_%1").arg(secretId);
            m_settings->setValue(keyName, m_secretKey);
            qDebug() << "Updated key association for ID:" << secretId;
        }
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
    // 首先尝试直接通过 ID 查找专属键名
    QString keyName = QString("key_%1").arg(secretId);
    QString key = m_settings->value(keyName, "").toString();
    qDebug() << "find key" << key << keyName;
    // key 值输出空
    if (!key.isEmpty()) {
        qDebug() << "Found key for ID" << secretId << "using key association";
        return key;
    }

    // 如果是当前记忆的 ID，返回当前的 Key
    if (secretId == m_settings->value("secretId", "").toString()) {
        key = m_settings->value("secretKey", "").toString();
        if (!key.isEmpty()) {
            qDebug() << "Found key for current ID" << secretId;
            // 同时保存一份关联，方便下次查找
            m_settings->setValue(keyName, key);
            return key;
        }
    }

    qDebug() << "No key found for ID:" << secretId;
    return QString();
    // // 如果是当前保存的 ID，返回对应的 Key
    // if (secretId == m_settings.value("secretId", "").toString()) {
    //     QString key = m_settings.value("secretKey", "").toString();
    //     qDebug() << "Found matching key for current ID:" << secretId << ", key
    //     found:" << !key.isEmpty(); return key;
    // }

    // // 从最近使用的 ID 记录中查找匹配的 Key
    // for (int i = 0; i < m_secretIdHistory.size(); ++i) {
    //     if (m_secretIdHistory[i] == secretId) {
    //         // 从设置中查找此 ID 对应的 Key
    //         QString keyName = QString("key_%1").arg(secretId);
    //         QString key = m_settings.value(keyName, "").toString();
    //         // 找到了 keyName
    //         qDebug() << "Searching for key with name:" << keyName << ", key
    //         found:" << !key.isEmpty();
    //         // return key;
    //         return key;
    //     }
    // }

    // qDebug() << "No key found for ID:" << secretId;
    // return QString();
}

void ConfigManager::loadHistoryFromSettings()
{
    m_secretIdHistory = m_settings->value("secretIdHistory").toStringList();
    m_remarkHistory = m_settings->value("remarkHistory").toStringList();
    qDebug() << "History loaded:" << m_secretIdHistory.size() << "secretIds,"
             << m_remarkHistory.size() << "remarks";
}

void ConfigManager::saveHistoryToSettings()
{
    m_settings->setValue("secretIdHistory", m_secretIdHistory);
    m_settings->setValue("remarkHistory", m_remarkHistory);
    m_settings->sync();
    qDebug() << "History saved";
}

QStringList ConfigManager::secretIdHistory() const { return m_secretIdHistory; }

QStringList ConfigManager::remarkHistory() const { return m_remarkHistory; }
