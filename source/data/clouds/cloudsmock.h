#ifndef CLOUDSMOCK_H
#define CLOUDSMOCK_H

#include "baseclouds.h"
#include <QJsonValue>
#include <QJsonObject>

class CloudsMock : public BaseClouds
{
public:
    CloudsMock(const QString &path);

    QList<TtBucket> buckets() override;

private:
    QJsonValue m_mock;
};

#endif // CLOUDSMOCK_H
