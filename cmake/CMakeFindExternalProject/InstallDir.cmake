#[[
文件名: InstallDir.cmake
设置安装路径的程序
]]

function(wi_set_install_dir_quiet)
    if (NOT CMAKE_SIZEOF_VOID_P)  # 如果还未设定CMAKE_SIZEOF_VOID_P, 则现在设定该值
        try_run(run_re com_re ${CMAKE_BINARY_DIR} ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/_void_p_test.c)
        if (com_re)  # 编译正常
            set(CMAKE_SIZEOF_VOID_P ${run_re} CACHE INTERNAL ”“ FORCE)
        endif()
    endif()

    cmake_parse_arguments(i "" "NAMES" "" ${ARGN})

    if (i_NAMES)
        set(_names ${i_NAMES})
    else()
        set(_names ${PROJECT_NAME})
    endif()

    include(GNUInstallDirs)
    set(_lib ${PROJECT_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR})  # 静态库的输出路径/动态库(或者动态库的导入文件)的输出路径
    set(_bin ${PROJECT_BINARY_DIR}/${CMAKE_INSTALL_BINDIR})  # 可执行文件(以及.dll)的输出路径

    # 不能直接访问 PARENT_SCOPE 的参数, 因此设置_lib
    file(MAKE_DIRECTORY ${_lib})
    file(MAKE_DIRECTORY ${_bin})

    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${_lib} PARENT_SCOPE)
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${_lib} PARENT_SCOPE)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${_bin} PARENT_SCOPE)

    if(WIN32 OR CYGWIN)  # cygwin和windows使用相同的文件结构
        set(DEF_INSTALL_CMAKEDIR cmake)
        set(DEF_INSTALL_INCLUDEDIR ${CMAKE_INSTALL_INCLUDEDIR})
        set(DEF_INSTALL_RESOURCEDIR ${CMAKE_INSTALL_DATAROOTDIR})  # 关联文件
    else()
        # unix类系统(Unix, Linux, MacOS, Cygwin等)把cmake文件安装到指定的系统的cmake文件夹中
        set(DEF_INSTALL_CMAKEDIR ${CMAKE_INSTALL_DATAROOTDIR}/cmake/${_names})
        set(DEF_INSTALL_INCLUDEDIR ${CMAKE_INSTALL_INCLUDEDIR}/${_names})
        set(DEF_INSTALL_RESOURCEDIR ${CMAKE_INSTALL_DATAROOTDIR}/${_names})  # 关联文件 CMAKE_INSTALL_DATAROOTDIR指: share
    endif()

    # 设定安装的目录
    set(INSTALL_BINDIR ${CMAKE_INSTALL_BINDIR} CACHE PATH "Installation directory for executables")
    set(INSTALL_LIBDIR ${CMAKE_INSTALL_LIBDIR} CACHE PATH "Installation directory for libraries")
    set(INSTALL_CMAKEDIR ${DEF_INSTALL_CMAKEDIR} CACHE PATH "Installation directory for CMake files")
    set(INSTALL_INCLUDEDIR ${DEF_INSTALL_INCLUDEDIR} CACHE PATH "Installation directory for header files")
    set(INSTALL_RESOURCEDIR ${DEF_INSTALL_RESOURCEDIR} CACHE PATH "Installation directory for resource files")  # 关联文件

    unset(DEF_INSTALL_CMAKEDIR)
    unset(DEF_INSTALL_INCLUDEDIR)
    unset(DEF_INSTALL_RESOURCEDIR)
endfunction()

function(wi_set_install_dir)
    set(_argn ${ARGN})
    wi_set_install_dir_quiet(${_argn})

    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_ARCHIVE_OUTPUT_DIRECTORY} PARENT_SCOPE)  # 静态库的输出路径
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_LIBRARY_OUTPUT_DIRECTORY} PARENT_SCOPE)  # 动态库(或者动态库的导入文件)的输出路径
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY} PARENT_SCOPE)  # 可执行文件(以及.dll)的输出路径

    # 报告构建路径
    foreach(p ARCHIVE LIBRARY RUNTIME)
        message(STATUS "Build ${p} at ${CMAKE_${p}_OUTPUT_DIRECTORY}")
    endforeach()

    # 报告安装路径
    foreach(p LIB BIN INCLUDE RESOURCE CMAKE)
        message(STATUS "Install ${p} at ${CMAKE_INSTALL_PREFIX}/${INSTALL_${p}DIR}")
    endforeach()
endfunction()
