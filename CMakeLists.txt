#[[
CMakeFindExternalProject的测试程序
目标时通过github访问一个动态库
并且编译该库
]]
cmake_minimum_required(VERSION 3.20)
project(CMakeFindExternalProjectTest C)

message(STATUS "CMAKE_GENERATOR = ${CMAKE_GENERATOR}")

include(cmake/CMakeFindExternalProject/init.cmake)
cfep_find_git(msgTargets GIT "https://gitee.com/SuperHuan0630/cmake-learn.git" GIT_TAG "main"
                       EXTERNAL TIMEOUT 60 INSTALL_DIR base)

if (msgTargets_FOUND)
    # IMPORTED_IMPLIB和IMPORTED_IMPLIB_<CONFIG>属性设定了该导入库的动态库导入文件的路径(例如, windows上的.lib, .dll.a)
    # <CONFIG>一般是DEBUG, RELEASE等, IMPORTED_IMPLIB一般为IMPORTED_IMPLIB_RELEASE
    get_target_property(imp message::msg IMPORTED_IMPLIB)
    get_target_property(imp_debug message::msg IMPORTED_IMPLIB_DEBUG)
    get_target_property(imp_release message::msg IMPORTED_IMPLIB_RELEASE)

    # IMPORTED_LOCATION和IMPORTED_LOCATION_<CONFIG>属性设定了该导入库的动态库运行时文件的路径(例如, windows上的.dll)
    get_target_property(loc message::msg IMPORTED_LOCATION)
    get_target_property(loc_debug message::msg IMPORTED_LOCATION_DEBUG)
    get_target_property(loc_release message::msg IMPORTED_LOCATION_RELEASE)

    message(STATUS "Import lib: ${imp}")
    message(STATUS "Location lib: ${loc}")

    message(STATUS "Import debug lib: ${imp_debug}")
    message(STATUS "Location debug lib: ${loc_debug}")

    message(STATUS "Import release lib: ${imp_release}")
    message(STATUS "Location release lib: ${loc_release}")
else()
    message(STATUS "msgTargets NOT FOUND.")
    message(STATUS "maybe you should set the cache msgTargets_DIR.")  # <报名>_DIR用于find_package在config模式时在何处寻找.cmake文件
endif()
