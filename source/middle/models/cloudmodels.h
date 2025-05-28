#ifndef CLOUDMODELS_H
#define CLOUDMODELS_H

#include <QObject>
#include <string>

class BaseObject {
public:
  BaseObject() {}
  virtual ~BaseObject() {}

  // bool ends_with(const std::string &str, const std::string &suffix) const {
  //   if (str.length() < suffix.length())
  //     return false;
  //   return str.rfind(suffix) == (str.length() - suffix.length());
  // }
  QString name;

public:
  bool isValid() const { return !isInvalid(); }
  bool isInvalid() const { return name.isNull() || name.isEmpty(); }
  // virtual bool isInvalid() const { return name.empty(); }
};
Q_DECLARE_METATYPE(BaseObject) // 可以被QVairant使用

class TtBucket : public BaseObject {
public:
  TtBucket() = default;
  QString location;
  QString createDate;
};
Q_DECLARE_METATYPE(TtBucket)

class TtObject : public BaseObject {
public:
  // bug
  bool isDir() const { return isValid() && name.endsWith("/"); }
  bool isFile() const { return isValid() && !name.endsWith("/"); }
  // bool isDir() const { return isValid() && ends_with(name, "/"); }
  // bool isFile() const { return isValid() && !ends_with(name, "/"); }
  QString lastmodified; // 修改时间
  // qulonglong  == unsigned __int64 on Windows
  qulonglong size = 0; // 文件大小
  QString dir;         // 文件目录
  QString key;         //
  // std::string lastmodified; // 修改时间
  // // qulonglong  == unsigned __int64 on Windows
  // qulonglong size = 0; // 文件大小
  // std::string dir;     // 文件目录
  // std::string key;     //
};
Q_DECLARE_METATYPE(TtObject)

#endif // CLOUDMODELS_H
