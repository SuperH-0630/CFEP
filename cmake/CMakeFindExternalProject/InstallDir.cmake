#[[
文件名: InstallDir.cmake
设置安装路径的程序
]]

macro(WI_set_install_dir_quiet)
    include(GNUInstallDirs)
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY  # 静态库的输出路径
        ${PROJECT_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR})
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY  # 动态库(或者动态库的导入文件)的输出路径
        ${PROJECT_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR})
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY
        ${PROJECT_BINARY_DIR}/${CMAKE_INSTALL_BINDIR})  # 可执行文件(以及.dll)的输出路径

    # 设定安装的目录
    set(INSTALL_LIBDIR ${CMAKE_INSTALL_LIBDIR} CACHE PATH "Installation directory for libraries")
    set(INSTALL_BINDIR ${CMAKE_INSTALL_BINDIR} CACHE PATH "Installation directory for executables")
    set(INSTALL_INCLUDEDIR ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME} CACHE PATH "Installation directory for header files")
    set(INSTALL_RESOURCEDIR resource/${PROJECT_NAME} CACHE PATH "Installation directory for resource files")  # 关联文件

    if(WIN32 AND NOT CYGWIN)
        set(DEF_INSTALL_CMAKEDIR cmake)
    else()
        set(DEF_INSTALL_CMAKEDIR share/cmake/${PROJECT_NAME})  # unix类系统(Unix, Linux, MacOS, Cygwin等)把cmake文件安装到指定的系统的cmake文件夹中
    endif()
    set(INSTALL_CMAKEDIR ${DEF_INSTALL_CMAKEDIR} CACHE PATH "Installation directory for CMake files")
    unset(DEF_INSTALL_CMAKEDIR)
endmacro()

macro(WI_set_install_dir)
    WI_set_install_dir_quiet()

    # 报告安装路径
    foreach(p LIB BIN INCLUDE RESOURCE CMAKE)
        message(STATUS "Installing ${CMAKE_INSTALL_PREFIX}/${INSTALL_${p}DIR}")
    endforeach()
endmacro()