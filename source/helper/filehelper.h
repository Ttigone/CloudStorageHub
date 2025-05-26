#ifndef FILEHELPER_H
#define FILEHELPER_H

#include <QVariant>

class FileHelper {
public:
  FileHelper();

  static QString readAllTxt(const QString &filePath);
  static QVariant readAllJson(const QString &filePath);

  /**
   * @brief 读取CSV文件，注意源文件的换行符和编码要正确
   * @param filepath 文件路径
   * @return 以QList<QStringList>类型返回
   */
  static QList<QStringList> readAllCsv(const QString &filepath);

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

  /**
   * @brief 写入文件
   * @param lines 内容
   * @param filePath 路径
   */
  static void writeFile(const QStringList lines, const QString &filePath);
};

#endif // FILEHELPER_H
