#include "buckets.h"
#include "helper/filehelper.h"

#include <QJsonArray>

ImportBuckets::ImportBuckets()
{

}

QList<TtBucket> ImportBuckets::bucketsFromMock(const QString &path)
{
    QList<TtBucket> res;

    QVariant var = FileHelper::readAllJson(path);
    QJsonArray arr = var.toJsonArray();
    for (int i = 0; i < arr.count(); ++i) {
        QJsonValue v = arr[i];
        TtBucket bucket;
        bucket.name = v["name"].toString();
        bucket.location = v["location"].toString();
        bucket.createDate = v["create_date"].toString();

        res.append(bucket);
        qDebug() << bucket.name << bucket.location << bucket.createDate;
    }

    return res;
}
