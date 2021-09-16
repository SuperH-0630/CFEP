#[[
文件名: WindowsInstall.cmake
windows下安装程序
因为windows需要复制动态库到指定位置, 因此需要特殊的安装程序
]]

# 找到导入库的.dll和.lib并添加install
function(_wi_install_import_inline target run lib)
    if(WIN32)  # 只有windows需要执行该操作
        if (CMAKE_BUILD_TYPE)
            string(TOUPPER ${CMAKE_BUILD_TYPE} _build_type)
        else()
            set(_build_type DEBUG)
        endif()

        get_target_property(imp ${target} IMPORTED_IMPLIB)
        get_target_property(imp_t ${target} IMPORTED_IMPLIB_${_build_type})

        get_target_property(loc target IMPORTED_LOCATION)
        get_target_property(loc_t target IMPORTED_LOCATION_${_build_type})

        if(lib)
            if (imp OR imp_t)
                install(FILE ${imp} ${imp_t} DESTINATION ${lib})
            endif()
        endif()

        if(run)
            if (loc OR loc_t)
                install(FILE ${loc} ${loc_t} DESTINATION ${run})
            endif()
        endif()
    endif()
endfunction()

function(WI_install_import)
    cmake_parse_arguments(ii "" "RUNTIME;LIBRARY" "TARGETS" ${ARGN})
    if (NOT ii_RUNTIME)
        if (INSTALL_BINDIR)
            set(runtime ${INSTALL_BINDIR})
        else()
            set(runtime ${CMAKE_INSTALL_BINDIR})
        endif()
    else()
        set(runtime ${ii_RUNTIME})
    endif()

    if (NOT ii_LIBRARY)
        if (INSTALL_LIBRARY)
            set(library ${INSTALL_LIBRARY})
        else()
            set(library ${CMAKE_INSTALL_LIBDIR})
        endif()
    else()
        set(library ${ii_LIBRARY})
    endif()

    set(targets ${ii_TARGETS})
    foreach(tgt IN LISTS targets)
        _wi_install_import_inline(tgt runtime library)
    endforeach()
endfunction()

# 找到导入库的.dll和.lib并复制到指定的目录
function(_wi_copy_import_inline target run lib)
    if(WIN32)  # 只有windows需要执行该操作
        if (CMAKE_BUILD_TYPE)
            string(TOUPPER ${CMAKE_BUILD_TYPE} _build_type)
        else()
            set(_build_type DEBUG)
        endif()

        get_target_property(imp ${target} IMPORTED_IMPLIB)
        get_target_property(imp_t ${target} IMPORTED_IMPLIB_${_build_type})

        get_target_property(loc target IMPORTED_LOCATION)
        get_target_property(loc_t target IMPORTED_LOCATION_${_build_type})

        if(lib)
            if (imp OR imp_t)
                file(COPY ${imp} ${imp_t} DESTINATION ${lib} USE_SOURCE_PERMISSIONS)
            endif()
        endif()

        if(run)
            if (loc OR loc_t)
                file(COPY ${loc} ${loc_t} DESTINATION ${run} USE_SOURCE_PERMISSIONS)
            endif()
        endif()
    endif()
endfunction()

function(WI_copy_import)
    cmake_parse_arguments(ii "" "RUNTIME;LIBRARY" "TARGETS" ${ARGN})
    if (NOT ii_RUNTIME)
        if (INSTALL_BINDIR)
            set(runtime ${INSTALL_BINDIR})
        else()
            set(runtime ${CMAKE_INSTALL_BINDIR})
        endif()
    else()
        set(runtime ${ii_RUNTIME})
    endif()

    if (NOT ii_LIBRARY)
        if (INSTALL_LIBRARY)
            set(library ${INSTALL_LIBRARY})
        else()
            set(library ${CMAKE_INSTALL_LIBDIR})
        endif()
    else()
        set(library ${ii_LIBRARY})
    endif()

    set(targets ${ii_TARGETS})
    foreach(tgt IN LISTS targets)
        _wi_copy_import_inline(tgt runtime library)
    endforeach()
endfunction()

# 安装install的bin目录(检查.dll并复制到指定位置)
function(WI_install_dll_bin)
    if(WIN32)
        cmake_parse_arguments(ii "" "RUNTIME" "DIRS" ${ARGN})
        if (NOT ii_RUNTIME)
            if (INSTALL_BINDIR)
                set(runtime ${INSTALL_BINDIR})
            else()
                set(runtime ${CMAKE_INSTALL_BINDIR})
            endif()
        else()
            set(runtime ${ii_RUNTIME})
        endif()

        set(dirs ${ii_DIRS})
        foreach(dir IN LISTS dirs)
            file(GLOB_RECURSE _dll  # 遍历所有的.dll
                 LIST_DIRECTORIES FALSE  #
                 CONFIGURE_DEPENDS
                 "${dirs}/*.dll")
            install(FILES ${_dll} DESTINATION ${RUNTIME})
        endforeach()
    endif()
endfunction()
