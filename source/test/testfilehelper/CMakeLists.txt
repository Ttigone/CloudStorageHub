# enable_testing()
# list(APPEND CMAKE_PREFIX_PATH "G:/1work-other/GTest/install/lib")
# # include_directories(${GTEST_INCLUDE_DIRS})
# include_directories("G:/1work-other/GTest/install/include")
# add_executable(tst_filehelper tst_filehelper.cpp)
# # 链接测试库
# target_link_libraries(tst_filehelper
#         # ${GTEST_BOTH_LIBRARIES}
#         # gtest
#         # gmock
#     )
# # target_link_libraries(${PROJECT_NAME} ${GTEST_LIBRARIES}) # Replace ${PROJECT_NAME} with your target name

# enable_testing()

# # 设置 GTest 安装路径
# set(GTEST_ROOT "G:/1work-other/GTest/install")
# list(APPEND CMAKE_PREFIX_PATH "${GTEST_ROOT}/lib")

# # 查找 GTest 包
# find_package(GTest REQUIRED) # Find the google testing framework on your system

# # 包含头文件目录
# include_directories("${GTEST_ROOT}/include")

# # 添加可执行文件
# add_executable(tst_filehelper tst_filehelper.cpp)

# # # 链接 Google Mock 库
# # target_link_libraries(tst_filehelper
# #     "${GTEST_ROOT}/lib/libgmock.a"
# #     "${GTEST_ROOT}/lib/libgmock_main.a"
# #     "${GTEST_ROOT}/lib/libgtest.a"  # 通常 GMock 依赖于 GTest
# #     "${GTEST_ROOT}/lib/libgtest_main.a"
# # )
# # 如果 find_package 成功找到并配置了导入目标
# target_link_libraries(tst_filehelper
#     GTest::gmock
#     GTest::gmock_main
# )

# enable_testing()

# # 设置 CMake 策略以支持大写的 _ROOT 变量
# if(POLICY CMP0144)
#   cmake_policy(SET CMP0144 NEW)
# endif()

# # 设置 GTest 安装路径
# set(GTEST_ROOT "G:/1work-other/GTest/install")
# # list(APPEND CMAKE_PREFIX_PATH "${GTEST_ROOT}/lib")
# list(APPEND CMAKE_PREFIX_PATH
#   "G:/1work-other/GTest/install/lib"
# )

# # 查找 GTest 包
# find_package(GTest REQUIRED) # Find the google testing framework on your system

# # 包含头文件目录
# # include_directories("${GTEST_ROOT}/include")
# include_directories("G:/1work-other/GTest/install/include")

# # 添加可执行文件
# add_executable(tst_filehelper tst_filehelper.cpp)

# # 对于 MinGW
# target_link_libraries(tst_filehelper
#     "${GTEST_ROOT}/lib/libgmock.a"
#     "${GTEST_ROOT}/lib/libgmock_main.a"
#     "${GTEST_ROOT}/lib/libgtest.a"
#     "${GTEST_ROOT}/lib/libgtest_main.a"
#     -pthread
# )



cmake_minimum_required(VERSION 3.5)

project(filehelperTests)

# set (CMAKE_CXX_STANDARD 14)
set (CMAKE_CXX_STANDARD 17)

# set(GTEST_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/libGoogleTest/googletest/include/")

set(GTEST_INCLUDE_DIR "G:/1work-other/GTest/install/include")

#message( "GTEST_INCLUDE_DIR = ${GTEST_INCLUDE_DIR}" )

#message( "CMAKE_CURRENT_SOURCE_DIR = ${CMAKE_CURRENT_SOURCE_DIR}" )

# include_directories("${GTEST_INCLUDE_DIR}"
#                     "${CMAKE_CURRENT_SOURCE_DIR}/lib/")

include_directories("${GTEST_INCLUDE_DIR}"
  "G:/1work-other/GTest/install/lib"
                  )


# set(GTEST_LIBRARY "${CMAKE_CURRENT_SOURCE_DIR}/libGoogleTest/googletest/libgtest.a")
# set(GTEST_MAIN_LIBRARY "${CMAKE_CURRENT_SOURCE_DIR}/libGoogleTest/googletest/libgtest_main.a")
# message( "GTEST_LIBRARY: ${GTEST_LIBRARY}" )


# add_subdirectory(lib)

# it seems that gtest is built with the shared .so pthreads lib
# find_library(pthreads NAMES libpthread.so FIND_LIBRARY_USE_LIB64_PATHS)
# message( "Using thread lib: ${pthreads}" )

# Locate GTest
find_package(GTest REQUIRED)

# set(CMAKE_PREFIX_PATH "./lib")
# find_library(Calculations NAMES libCalculations.a "./lib/")

# message( "Calculations lib: ${Calculations}" )


add_executable(${PROJECT_NAME} tst_filehelper.cpp)

target_link_libraries(${PROJECT_NAME} ${GTEST_LIBRARY} ${GTEST_MAIN_LIBRARY})
