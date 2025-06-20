#include "storage/TtDb.h"
#include <QDateTime>

TtDB::TtDB(QObject* parent) : QObject{parent} {}

TtDB::~TtDB() { qDebug() << __FUNCTION__; }

void TtDB::init()
{
    // // BUG 数据库是链接的, 但是没有数据库文件
    // qDebug() << "connected";
    // m_loginInfo.connect();
    // // 链接
    // m_loginInfo.createTable();
    // // 初始时查询数据库数据
    // m_loginInfoList = m_loginInfo.select();
        try {
        m_loginInfo.connect();
        qDebug() << "数据库连接成功";
        
        m_loginInfo.createTable();
        qDebug() << "数据表创建成功";
        
        // 初始时查询数据库数据
        m_loginInfoList = m_loginInfo.select();
        qDebug() << "初始数据加载成功，记录数：" << m_loginInfoList.size();
    } catch (const QString &error) {
        qCritical() << "数据库初始化失败：" << error;
        throw;
    }
}

void TtDB::saveLoginInfo(const QString& name, const QString& id,
                         const QString& key, const QString& remark)
{
    qDebug() << "test";
    LoginInfo info;
    info.name = (name == "" ? id : name);
    info.secret_id = id.trimmed(); // 去除空格
    info.secret_key = key.trimmed();
    info.remark = remark.trimmed();
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
    // info.timestamp = QDateTime::currentDateTimeUtc().toSecsSinceEpoch();
    info.timestamp = QDateTime::currentSecsSinceEpoch();
#else
    info.timestamp = QDateTime::currentDateTimeUtc().toTime_t();
#endif

    if (m_loginInfo.exists(info.secret_id)) {
        m_loginInfo.update(info);
        // secret_id 与 index 映射
        // 如果删除了对应的某条记录, 链表自动更新每条记录的位置
        // 获取的 index 不受到更新的影响, 因为是通过独特的 secret_id 获取 index
        m_loginInfoList[indexOfLoginInfo(info.secret_id)] = info;
    } else {
        m_loginInfo.insert(info);
        m_loginInfoList.append(info);
    }
    qDebug() << "保存数据成功";
}

void TtDB::removeLoginInfo(const QString& id)
{
    if (m_loginInfo.exists(id)) {
        m_loginInfo.remove(id);
        m_loginInfoList.removeAt(indexOfLoginInfo(id));
    }
}

int TtDB::indexOfLoginInfo(const QString& secretId)
{
    for (int i = 0; i < m_loginInfoList.size(); ++i) {
        if (m_loginInfoList[i].secret_id == secretId) {
            return i;
        }
    }
    throw QString::fromLocal8Bit("获取登录信息索引失败 %1").arg(secretId);
}

QStringList TtDB::loginNameList()
{
    QStringList words;
    for (int i = 0; i < m_loginInfoList.size(); ++i) {
        words.append(m_loginInfoList[i].name);
    }
    return words;
}

LoginInfo TtDB::loginInfoByName(const QString& name)
{
    for (int i = 0; i < m_loginInfoList.size(); ++i) {
        if (m_loginInfoList[i].name == name) {
            return m_loginInfoList[i];
        }
    }
    throw QString::fromLocal8Bit("通过名称查找登录信息失败 %1").arg(name);
}

QVariantMap TtDB::loginInfoAsMap(const QString& name)
{
    QVariantMap result;
    try {
        LoginInfo info = loginInfoByName(name);
        result["name"] = info.name;
        result["secret_id"] = info.secret_id;
        result["secret_key"] = info.secret_key;
        result["remark"] = info.remark;
    } catch (const QString& error) {
        qDebug() << "Error getting login info:" << error;
    }
    return result;
}
