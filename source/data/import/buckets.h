#ifndef DAOBUCKETS_H
#define DAOBUCKETS_H

#include "middle/models/cloudmodels.h"
#include <QList>

class ImportBuckets {
public:
  ImportBuckets();

  /// mock 测试
  QList<TtBucket> setBuckets(const QString &path);
};

#endif // DAOBUCKETS_H
