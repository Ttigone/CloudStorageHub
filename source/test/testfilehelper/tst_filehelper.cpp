#include <gmock/gmock-matchers.h>
#include <gtest/gtest.h>

using namespace testing;

// 第一个名称是测试的函数
TEST(none, filehelper) {
  EXPECT_EQ(1, 1);
  ASSERT_THAT(0, Eq(0));
}

// TEST(TestSuite, TestName) {}
