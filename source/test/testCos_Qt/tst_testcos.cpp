#include <QtTest>

// add necessary includes here
#include "source/config/exceptions.h"
#include "source/data/clouds/CloudsTC.h"
#include "source/helper/filehelper.h"
#include "source/middle/models/cloudmodels.h"
#include <string>

class TestCos : public QObject {
  Q_OBJECT

public:
  TestCos(const std::string id = "default", const std::string key = "default");
  ~TestCos();

private slots:
  void initTestCase();
  void cleanupTestCase();
  void test_bucket();
  void test_isBucketExists();
  void test_getBucketLocation();
  void test_putBucket();
  void test_deleteBucket();
  void test_getObjects();

  void test_getObjects2_data();
  void test_getObjects2();

  void test_getObjectError();

  void test_putObject();
  void test_getObject();

private:
  CloudsTC m_cos;
  QString m_id;
  QString m_key;

  // QString m_bucketName = "test-1324376513";
  QString m_bucketName = "test-1324219408";

  // 上文的文件
  QString m_uploadLocalPath = "./upload.txt";
  QString m_downloadLocalPath = "./download.txt";
  QString m_uploadKey = "测试文件/upload.txt";
};

TestCos::TestCos(const std::string id, const std::string key) {
  // 不会执行测试用例
  qDebug() << id << key;
  // m_cos 构造函函数执行配置信息
  // m_id = QString::fromStdString(id);
  // m_key = QString::fromStdString(key);
  // qDebug() << m_id << m_key;
}

TestCos::~TestCos() {}

void TestCos::initTestCase() {
  // 创建文件
  FileHelper::writeFile(QStringList() << "abc"
                                      << "def",
                        m_uploadLocalPath);
}
void TestCos::cleanupTestCase() {
  QFile::remove(m_uploadLocalPath);   // 结束删除本地文件
  QFile::remove(m_downloadLocalPath); // 结束删除本地文件
}

void TestCos::test_bucket() {
  QList<TtBucket> bs = m_cos.buckets();
  QVERIFY(bs.size() > 0);
  QCOMPARE(bs.size(), 1); // 确实只有一个存储桶
}

void TestCos::test_isBucketExists() {
  bool hasbucket = m_cos.isBucketExists("test-1324219408");
  QVERIFY(hasbucket);
}

void TestCos::test_getBucketLocation() {
  std::string location = m_cos.getBucketLocation("test-1324219408");
  QCOMPARE(location, "ap-guangzhou");
}

void TestCos::test_putBucket() {
  QSKIP("SKIP test_putBucket"); // 使用宏跳过该测试用例
  // 创建存储桶时，必须以-appid为结尾
  QString bucketName = "testcos-1324219408";
  m_cos.putBucket(bucketName.toStdString(), "ap-shanghai");
  bool exists = m_cos.isBucketExists(bucketName.toStdString());
  QVERIFY(exists);
}

void TestCos::test_deleteBucket() {
  QSKIP("SKIP test_deleteBucket");
  QString bucketName = "testcos-1324219408";
  m_cos.deleteBucket(bucketName.toStdString());
  bool exists = m_cos.isBucketExists(bucketName.toStdString());
  QVERIFY(!exists);
}

void TestCos::test_getObjects() {
  QSKIP("SKIP test_getObjects");
  QList<TtObject> objList = m_cos.getObjects(
      m_bucketName.toStdString(), ""); // 开启qDebug会打印最外层的内容
  QCOMPARE(objList.size(), 3);

  objList = m_cos.getObjects(m_bucketName.toStdString(),
                             QString::fromUtf8("测试文件").toStdString());
  QCOMPARE(objList.size(), 1);
}

void TestCos::test_getObjects2_data() {
  QSKIP("SKIP test_getObjects2_data");
  // 准备测试数据
  QTest::addColumn<QString>("dir");
  QTest::addColumn<int>("expected");

  QTest::newRow("root") << "" << 3;
  QTest::newRow("mkdir") << "测试文件" << 1;
}

void TestCos::test_getObjects2() {
  QSKIP("SKIP test_getObjects2");
  // 从 _data 数据表中读取数据, 执行比较
  QFETCH(QString, dir);
  QFETCH(int, expected);
  QList<TtObject> objList =
      m_cos.getObjects(m_bucketName.toStdString(), dir.toStdString());
  QCOMPARE(objList.size(), expected);
}

void TestCos::test_getObjectError() {
  // 捕获预期异常
  QVERIFY_EXCEPTION_THROWN(m_cos.getObjects("file", ""), BaseException);
  // QVERIFY_EXCEPTION_THROWN(m_cos.getObjects("file", ""), QString);
}

void TestCos::test_putObject() {
  m_cos.putObject(m_bucketName.toStdString(),
                  m_uploadKey.toUtf8().toStdString(),
                  m_uploadLocalPath.toStdString(), nullptr);
  QVERIFY(m_cos.isObjectExists(
      m_bucketName.toStdString(),
      QString::fromUtf8("测试文件/upload.txt").toStdString()));
}

void TestCos::test_getObject() {
  m_cos.getObject(m_bucketName.toStdString(),
                  m_uploadKey.toUtf8().toStdString(),
                  m_downloadLocalPath.toStdString(), nullptr);
  QVERIFY(QFile::exists(m_downloadLocalPath));
}

// 调用默认构造参数
QTEST_APPLESS_MAIN(TestCos)

#include "tst_testcos.moc"
