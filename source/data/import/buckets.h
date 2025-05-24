#ifndef DAOBUCKETS_H
#define DAOBUCKETS_H

#include "data/models/TtBucket.h"
#include <QList>

class ImportBuckets
{
public:
    ImportBuckets();

    ///
    /// @brief bucketsFromMock
    /// @param path 解析的 json 文件
    /// @return
    /// mock 测试
    QList<TtBucket> bucketsFromMock(const QString& path);
};

#endif // DAOBUCKETS_H
