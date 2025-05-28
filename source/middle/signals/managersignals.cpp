#include "ManagerSignals.h"
#include <QDebug>

ManagerSignals::ManagerSignals(QObject *parent)
    : QObject{parent}
{
    // 进行注册
    // 使一些三方、特殊的类型可以通过信号传递
    qRegisterMetaType<QList<TtBucket> >("QList<TtBucket>");
    qRegisterMetaType<QList<TtObject> >("QList<TtObject>");

}

ManagerSignals::~ManagerSignals()
{

}
