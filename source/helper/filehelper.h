#ifndef FILEHELPER_H
#define FILEHELPER_H

#include <QVariant>

class FileHelper {
public:
  FileHelper();

  static QString readAllTxt(const QString &filePath);
  static QVariant readAllJson(const QString &filePath);

  ///
  /// @brief joinPath
  /// @param path1
  /// @param path2
  /// @return
  /// 链接路径
  static QString joinPath(const QString &path1, const QString &path2);
  ///
  /// @brief mkPath
  /// @param path
  /// @return
  /// 创建路径
  static bool mkPath(const QString &path);
};

#endif // FILEHELPER_H
