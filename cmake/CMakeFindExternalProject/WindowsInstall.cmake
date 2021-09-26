#[[
文件名: WindowsInstall.cmake
windows下安装程序
因为windows需要复制动态库到指定位置, 因此需要特殊的安装程序
]]

# 找到导入库的.dll和.lib并添加install
function(_wi_install_import_inline target run lib)
    if(WIN32 OR CYGWIN)  # 只有windows需要执行该操作 (包括cygwin也需要处理.dll依赖的问题)
        if (CMAKE_BUILD_TYPE)
            string(TOUPPER ${CMAKE_BUILD_TYPE} _build_type)
        else()
            set(_build_type DEBUG)
        endif()

        get_target_property(imp ${target} IMPORTED_IMPLIB)
        get_target_property(imp_t ${target} IMPORTED_IMPLIB_${_build_type})

        get_target_property(loc ${target} IMPORTED_LOCATION)
        get_target_property(loc_t ${target} IMPORTED_LOCATION_${_build_type})

        if(lib)
            if (imp)
                install(FILES ${imp} DESTINATION ${lib})
            endif()
            if (imp_t)
                install(FILES ${imp_t} DESTINATION ${lib})
            endif()
        endif()

        if(run)
            if (loc)
                install(FILES ${loc} DESTINATION ${run})
            endif()
            if (loc_t)
                install(FILES ${loc_t} DESTINATION ${run})
            endif()
        endif()
    endif()
endfunction()

function(wi_install_import)
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
    foreach(tgt IN LISTS targets) # 不需要 ${}
        _wi_install_import_inline(${tgt} ${runtime} ${library})
    endforeach()
endfunction()

# 找到导入库的.dll和.lib并复制到指定的目录
function(_wi_copy_import_inline target run lib)
    if(WIN32 OR CYGWIN)
        if (CMAKE_BUILD_TYPE)
            string(TOUPPER ${CMAKE_BUILD_TYPE} _build_type)
        else()
            set(_build_type DEBUG)
        endif()

        get_target_property(imp ${target} IMPORTED_IMPLIB)
        get_target_property(imp_t ${target} IMPORTED_IMPLIB_${_build_type})

        get_target_property(loc ${target} IMPORTED_LOCATION)
        get_target_property(loc_t ${target} IMPORTED_LOCATION_${_build_type})

        if(lib)
            if (imp)
                file(COPY ${imp} DESTINATION ${lib} USE_SOURCE_PERMISSIONS)
            endif()
            if (imp_t)
                file(COPY ${imp_t} DESTINATION ${lib} USE_SOURCE_PERMISSIONS)
            endif()
        endif()

        if(run)
            if (loc)
                file(COPY ${loc} DESTINATION ${run} USE_SOURCE_PERMISSIONS)
            endif()
            if (loc_t)
                file(COPY ${loc_t} DESTINATION ${run} USE_SOURCE_PERMISSIONS)
            endif()
        endif()
    endif()
endfunction()

# 添加 target
if (NOT TARGET import_build)
    add_custom_target(import_build ALL COMMENT "Copy import target.")
endif()

macro(set_copy_command target a b)
    add_custom_command(TARGET ${target} POST_BUILD
                       COMMAND "${CMAKE_COMMAND}" "-E" "copy" "${a}" "${b}"
                       COMMENT "Copy ${a}.")
endmacro()

function(_wi_build_import_inline target run lib)
    if(WIN32 OR CYGWIN)
        if (CMAKE_BUILD_TYPE)
            string(TOUPPER ${CMAKE_BUILD_TYPE} _build_type)
        else()
            set(_build_type DEBUG)
        endif()

        get_target_property(imp ${target} IMPORTED_IMPLIB)
        get_target_property(imp_t ${target} IMPORTED_IMPLIB_${_build_type})

        get_target_property(loc ${target} IMPORTED_LOCATION)
        get_target_property(loc_t ${target} IMPORTED_LOCATION_${_build_type})

        if(lib)
            if (imp)
                set_copy_command(import_build ${imp} ${lib})
            endif()

            if (imp_t)
                set_copy_command(import_build ${imp_t} ${lib})
            endif()
        endif()

        if(run)
            if (loc)
                set_copy_command(import_build ${loc} ${run})
            endif()
            if (loc_t)
                set_copy_command(import_build ${loc_t} ${run})
            endif()
        endif()
    endif()
endfunction()

function(wi_copy_import)
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
    foreach(tgt IN LISTS targets)  # 不需要${}
        _wi_copy_import_inline(${tgt} ${runtime} ${library})
    endforeach()
endfunction()

function(wi_build_import)
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
    foreach(tgt IN LISTS targets)  # 不需要${}
        _wi_build_import_inline(${tgt} ${runtime} ${library})
    endforeach()
endfunction()

# 安装install的bin目录(检查.dll并安装到指定位置)
function(wi_install_dll_bin)
    if(WIN32 OR CYGWIN)
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
            file(GLOB _dll  # 遍历所有的.dll
                 FOLLOW_SYMLINKS  # 遍历link
                 LIST_DIRECTORIES FALSE  #  不记录列表
                 CONFIGURE_DEPENDS
                 "${dirs}/*.dll")
            if (_dll)
                install(FILES ${_dll} DESTINATION ${runtime})
            endif()
        endforeach()
    endif()
endfunction()

# 复制bin目录(检查.dll并复制到指定位置)
function(wi_copy_dll_bin)
    if(WIN32 OR CYGWIN)
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
            file(GLOB _dll  # 遍历所有的.dll
                 FOLLOW_SYMLINKS  # 遍历link
                 LIST_DIRECTORIES FALSE  #  不记录列表
                 CONFIGURE_DEPENDS
                 "${dirs}/*.dll")
            if (_dll)
                file(COPY ${_dll} DESTINATION ${runtime} USE_SOURCE_PERMISSIONS)
            endif()
        endforeach()
    endif()
endfunction()

# 检查文件夹是否有exe, 若有则将其当作bin目录处理
function(wi_install_dll_dir)
    if(WIN32 OR CYGWIN)
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
            file(GLOB _exe
                 LIST_DIRECTORIES FALSE  #  不记录列表
                 CONFIGURE_DEPENDS
                 "${dir}/*.exe")
            if (_exe)
                wi_install_dll_bin(RUNTIME ${runtime} DIRS ${dir})
            endif()
        endforeach()
    endif()
endfunction()

# 检查文件夹是否有exe, 若有则将其当作bin目录处理
function(wi_copy_dll_dir)
    if(WIN32 OR CYGWIN)
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
            file(GLOB _exe
                 LIST_DIRECTORIES FALSE  #  不记录列表
                 CONFIGURE_DEPENDS
                 "${dir}/*.exe")
            if (_exe)
                wi_copy_dll_bin(RUNTIME ${runtime} DIRS ${dir})
            endif()
        endforeach()
    endif()
endfunction()

function(wi_find_cygwin1)
    if(CYGWIN)
        find_file(cygwin1_dll "cygwin1.dll" DOC "Find cygwin1.dll on windows.")
        if (NOT cygwin1_dll)
            message(FATAL_ERROR "The cygwin1.dll not found.")
        endif()
        add_library(CYGWIN::cygwin1 SHARED IMPORTED)
        set_target_properties(CYGWIN::cygwin1 PROPERTIES IMPORTED_LOCATION "${cygwin1_dll}")
    endif()
endfunction()
