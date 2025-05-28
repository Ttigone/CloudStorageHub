cmake_minimum_required(VERSION 3.16)

project(TestCos LANGUAGES CXX)

enable_testing()

find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Test Core5Compat Sql Gui Concurrent)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Test Core5Compat Sql Gui Concurrent)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

file(GLOB HEADERS
    ${CMAKE_SOURCE_DIR}/${CMAKE_SOURCE_DIR}/source/${SUFFIX_HPPHEADER}
    ${CMAKE_SOURCE_DIR}/source/${SUFFIX_IPPHEADER}
    ${CMAKE_SOURCE_DIR}/source/${SUFFIX_INLHEADER}
    ${CMAKE_SOURCE_DIR}/source/${SUFFIX_HHEADER}
    ${CMAKE_SOURCE_DIR}/source/data/import/${SUFFIX_HHEADER}
    ${CMAKE_SOURCE_DIR}/source/data/instance/${SUFFIX_HHEADER}
    ${CMAKE_SOURCE_DIR}/source/data/models/${SUFFIX_HHEADER}
    ${CMAKE_SOURCE_DIR}/source/data/config/${SUFFIX_HHEADER}
    ${CMAKE_SOURCE_DIR}/source/data/clouds/${SUFFIX_HHEADER}
    ${CMAKE_SOURCE_DIR}/source/data/logs/${SUFFIX_HHEADER}
    ${CMAKE_SOURCE_DIR}/source/helper/${SUFFIX_HHEADER}
    ${CMAKE_SOURCE_DIR}/source/storage/${SUFFIX_HHEADER}
    ${CMAKE_SOURCE_DIR}/source/config/${SUFFIX_HHEADER}
    ${CMAKE_SOURCE_DIR}/source/middle/models/${SUFFIX_HHEADER}
    ${CMAKE_SOURCE_DIR}/source/middle/signals/${SUFFIX_HHEADER}
    ${CMAKE_SOURCE_DIR}/source/middle/${SUFFIX_HHEADER}
    ${CMAKE_SOURCE_DIR}/source/plugin/${SUFFIX_HHEADER}
    ${CMAKE_SOURCE_DIR}/source/import/${SUFFIX_HHEADER}
)

file(GLOB
SOURCES
    ${CMAKE_SOURCE_DIR}/source/${SUFFIX_SOURCE}
    ${CMAKE_SOURCE_DIR}/source/data/import/${SUFFIX_SOURCE}
    ${CMAKE_SOURCE_DIR}/source/data/instance/${SUFFIX_SOURCE}
    ${CMAKE_SOURCE_DIR}/source/data/models/${SUFFIX_SOURCE}
    ${CMAKE_SOURCE_DIR}/source/data/config/${SUFFIX_SOURCE}
    ${CMAKE_SOURCE_DIR}/source/data/clouds/${SUFFIX_SOURCE}
    ${CMAKE_SOURCE_DIR}/source/data/logs/${SUFFIX_SOURCE}
    ${CMAKE_SOURCE_DIR}/source/helper/${SUFFIX_SOURCE}
    ${CMAKE_SOURCE_DIR}/source/storage/${SUFFIX_SOURCE}
    ${CMAKE_SOURCE_DIR}/source/config/${SUFFIX_SOURCE}
    ${CMAKE_SOURCE_DIR}/source/middle/models/${SUFFIX_SOURCE}
    ${CMAKE_SOURCE_DIR}/source/middle/signals/${SUFFIX_SOURCE}
    ${CMAKE_SOURCE_DIR}/source/middle/${SUFFIX_SOURCE}
    ${CMAKE_SOURCE_DIR}/source/plugin/${SUFFIX_SOURCE}
    ${CMAKE_SOURCE_DIR}/source/import/${SUFFIX_SOURCE}
)


add_executable(TestCos tst_testcos.cpp
    ${SOURCES}
    ${HEADERS}
)
target_include_directories(TestCos PRIVATE ${CMAKE_SOURCE_DIR})
target_include_directories(TestCos PRIVATE ${CMAKE_SOURCE_DIR}/source)


add_test(NAME TestCos COMMAND TestCos)

target_link_libraries(TestCos PRIVATE
    Qt${QT_VERSION_MAJOR}::Test
    Qt${QT_VERSION_MAJOR}::Core5Compat
    Qt${QT_VERSION_MAJOR}::Sql
    Qt${QT_VERSION_MAJOR}::Gui
    Qt${QT_VERSION_MAJOR}::Concurrent
)
# 以下代码只有 msvc 能链接
target_include_directories(${PROJECT_NAME} PUBLIC ${CMAKE_SOURCE_DIR}/external/cos-cpp-sdk-v5-5.5.17/include)
# target_link_directories(${PROJECT_NAME} PUBLIC ${CMAKE_SOURCE_DIR}/external/cos-cpp-sdk-v5-5.5.17/lib/Debug/)
target_link_directories(${PROJECT_NAME} PUBLIC ${CMAKE_SOURCE_DIR}/external/cos-cpp-sdk-v5-5.5.17/lib/Release/)
target_link_libraries(${PROJECT_NAME} PRIVATE cossdk)

target_include_directories(${PROJECT_NAME} PUBLIC ${CMAKE_SOURCE_DIR}/external/cos-cpp-sdk-v5-5.5.17/third_party/include)
# 然后正常链接所有 Poco 库（不带 d 后缀）
# target_link_libraries(${PROJECT_NAME} PRIVATE
#     "${CMAKE_SOURCE_DIR}/external/cos-cpp-sdk-v5-5.5.17/third_party/lib/x64/poco/PocoFoundationd.lib"
#     "${CMAKE_SOURCE_DIR}/external/cos-cpp-sdk-v5-5.5.17/third_party/lib/x64/poco/PocoJSONd.lib"
#     "${CMAKE_SOURCE_DIR}/external/cos-cpp-sdk-v5-5.5.17/third_party/lib/x64/poco/PocoXMLd.lib"
#     "${CMAKE_SOURCE_DIR}/external/cos-cpp-sdk-v5-5.5.17/third_party/lib/x64/poco/PocoCryptod.lib"
#     "${CMAKE_SOURCE_DIR}/external/cos-cpp-sdk-v5-5.5.17/third_party/lib/x64/poco/PocoNetd.lib"
#     "${CMAKE_SOURCE_DIR}/external/cos-cpp-sdk-v5-5.5.17/third_party/lib/x64/poco/PocoNetSSLd.lib"
#     "${CMAKE_SOURCE_DIR}/external/cos-cpp-sdk-v5-5.5.17/third_party/lib/x64/poco/PocoUtild.lib"
# )
target_link_libraries(${PROJECT_NAME} PRIVATE
    "${CMAKE_SOURCE_DIR}/external/cos-cpp-sdk-v5-5.5.17/third_party/lib/x64/poco/PocoFoundation.lib"
    "${CMAKE_SOURCE_DIR}/external/cos-cpp-sdk-v5-5.5.17/third_party/lib/x64/poco/PocoJSON.lib"
    "${CMAKE_SOURCE_DIR}/external/cos-cpp-sdk-v5-5.5.17/third_party/lib/x64/poco/PocoXML.lib"
    "${CMAKE_SOURCE_DIR}/external/cos-cpp-sdk-v5-5.5.17/third_party/lib/x64/poco/PocoCrypto.lib"
    "${CMAKE_SOURCE_DIR}/external/cos-cpp-sdk-v5-5.5.17/third_party/lib/x64/poco/PocoNet.lib"
    "${CMAKE_SOURCE_DIR}/external/cos-cpp-sdk-v5-5.5.17/third_party/lib/x64/poco/PocoNetSSL.lib"
    "${CMAKE_SOURCE_DIR}/external/cos-cpp-sdk-v5-5.5.17/third_party/lib/x64/poco/PocoUtil.lib"
)

# target_link_libraries(${PROJECT_NAME} PUBLIC
#     "${CMAKE_CURRENT_SOURCE_DIR}/external/cos-cpp-sdk-v5-5.5.17/third_party/lib/x64/poco/PocoFoundation.lib"
#     "${CMAKE_CURRENT_SOURCE_DIR}/external/cos-cpp-sdk-v5-5.5.17/third_party/lib/x64/poco/PocoJSON.lib"
#     "${CMAKE_CURRENT_SOURCE_DIR}/external/cos-cpp-sdk-v5-5.5.17/third_party/lib/x64/poco/PocoXML.lib"
#     "${CMAKE_CURRENT_SOURCE_DIR}/external/cos-cpp-sdk-v5-5.5.17/third_party/lib/x64/poco/PocoCrypto.lib"
#     "${CMAKE_CURRENT_SOURCE_DIR}/external/cos-cpp-sdk-v5-5.5.17/third_party/lib/x64/poco/PocoNet.lib"
#     "${CMAKE_CURRENT_SOURCE_DIR}/external/cos-cpp-sdk-v5-5.5.17/third_party/lib/x64/poco/PocoNetSSL.lib"
#     "${CMAKE_CURRENT_SOURCE_DIR}/external/cos-cpp-sdk-v5-5.5.17/third_party/lib/x64/poco/PocoUtil.lib"
# )
