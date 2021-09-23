#[[
文件名: CMakeFindExternalProject.cmake
用于定位一个外部项目
若外部项目不存在则构建该项目
]]

# 保存 CMAKE_CURRENT_LIST_DIR
# 因为 CMake 函数是动态作用域的
set(CMakeFindExternalProject_DIR "${CMAKE_CURRENT_LIST_DIR}" CACHE INTERNAL "CMAKE_CURRENT_LIST_DIR" FORCE)

macro(_cfep_build_found_inline _found)
    set(${name}_CFEP_FOUND ${_found} CACHE INTERNAL "${name} found by CMakeFindExternalProject" FORCE)
    if (${name}_CFEP_FOUND)
        set(${name}_CFEP_BUILD_DIR ${_build_dir} CACHE INTERNAL "${name} install dirs" FORCE)
        set(${name}_CFEP_INSTALL ${_install_dir} CACHE INTERNAL "${name} install dirs" FORCE)
        set(${name}_CFEP_INSTALL_TYPE ${cfp_INSTALL_DIR} CACHE INTERNAL "${name} install dirs type" FORCE)
    else()
        set(${name}_CFEP_BUILD_DIR "" CACHE INTERNAL "${name} install dirs" FORCE)
        set(${name}_CFEP_INSTALL "" CACHE INTERNAL "${name} install dirs" FORCE)
        set(${name}_CFEP_INSTALL_TYPE "" CACHE INTERNAL "${name} install dirs type" FORCE)
    endif()
endmacro()

function(_cfep_build_inline name)
    set(options NOT_INFO FORCE)
    set(oneValueArgs
        BUILD_DIR
        SOURCE_DIR  # 指定源文件的位置, 指定后不可再设定DOWNLOAD_COMMAND
        INSTALL_DIR  # 有三个选择: base, deps, binary
        TIMEOUT)
    set(multiValueArgs
        DOWNLOAD_COMMAND
        CMAKE_ARGS
        BUILD_CMAKE_ARGS
        BUILD_CMAKE_CACHE_ARGS
        BUILD_CMAKE_CACHE_DEFAULT_ARGS)

    cmake_parse_arguments(cfp
                          "${options}"
                          "${oneValueArgs}"
                          "${multiValueArgs}"
                          ${ARGN})
    if (NOT cfp_BUILD_DIR)
        set(_build_dir "${CMAKE_BINARY_DIR}/deps/${name}")
    else()
        set(_build_dir "${CMAKE_BINARY_DIR}/deps/${cfp_BUILD_DIR}")
    endif()

    set(_force ${cfp_FORCE})
    if (cfp_NOT_INFO)
        set(_info false)
    else()
        set(_info true)
    endif()

    set(_cmake_dir ${_build_dir}/cmake.dir)
    set(_binary_dir ${_build_dir}/binary)
    set(_timeout ${cfp_TIMEOUT})

    if (cfp_SOURCE_DIR)
        if(EXISTS ${cfp_SOURCE_DIR})  # 若指定的SOURCE_DIR存在
            if (cfp_DOWNLOAD_COMMAND)  # 若仍有DOWNLOAD_COMMAND
                if (_info)
                    message(WARNING "DOWNLOAD_COMMAND will be ignore.")
                endif()
                unset(cfp_DOWNLOAD_COMMAND)  # 清空cfp_DOWNLOAD_COMMAND
            endif()
            set(_source_dir ${cfp_SOURCE_DIR})
        else()  # 若指定的SOURCE_DIR不存在
            if (_info)
                message(WARNING "SOURCE_DIR will be ignore.")
            endif()
            set(_source_dir ${_build_dir}/source)
        endif()
    else()  # 若没有SOURCE_DIR则按默认_source_dir
        set(_source_dir ${_build_dir}/source)
    endif()

    if (cfp_INSTALL_DIR STREQUAL "base")
        set(_install_dir ${CMAKE_BINARY_DIR}/${name})
    elseif(cfp_INSTALL_DIR STREQUAL "binary")
        set(_install_dir ${CMAKE_BINARY_DIR}/${name})
    else()
        set(_install_dir ${_build_dir}/install)
    endif()

    if (_info)
        message(STATUS "Project ${name} will be build.")
        message(STATUS "Project ${name} source at ${_source_dir}")
        message(STATUS "Project ${name} install to ${_install_dir}")
        message(STATUS "Project ${name} build at ${_binary_dir}")
        message(STATUS "Project ${name} other info at ${_build_dir}")
    endif()

    if(NOT _force)
        if ((${_name}_CFEP_FOUND) AND (EXISTS ${_cmake_dir}))  # 若 _cmake_dir 被删除则重新构建项目
            return()
        endif()
    endif()

    foreach(dir cmake install source binary install)  # 构建目录
        execute_process(
                COMMAND "${CMAKE_COMMAND}" -E make_directory "${_${dir}_dir}"
                RESULT_VARIABLE re)
        if (re)
            if (_info)
                message(WARNING "cmake make directory ${_${dir}_dir} fail(${re}): ${_${dir}_dir}")
            endif()
            _cfep_build_found_inline(FALSE)
            return()
        endif()

        unset(re)
        unset(_stderr)
        unset(_stdout)
    endforeach()

    set(_download ${cfp_DOWNLOAD_COMMAND})

    set(_cmake_args ${cfp_CMAKE_ARGS})
    set(_build_cmake_args
        ${cfp_BUILD_CMAKE_ARGS}
        "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}")

    set(_build_cmake_cache
        ${cfp_BUILD_CMAKE_CACHE_ARGS}
        \"-DCMAKE_INSTALL_PREFIX:PATH=${_install_dir}\")  # ${_install_dir}不需要分号
    set(_build_cmake_default_cache ${BUILD_CMAKE_CACHE_DEFAULT_ARGS})

    set(CEFP_CMAKE_VERSION ${CMAKE_VERSION})
    set(CFEP_NAME ${name})
    set(SHOW_INFO ${_info})

    set(CEFP_BUILD_PREFIX ${_build_dir})
    set(CEFP_SOURCE_DIR ${_source_dir})
    set(CEFP_BINARY_DIR ${_binary_dir})
    set(CEFP_INSTALL_DIR ${_install_dir})

    set(_CEFP_COMMAND
        TIMEOUT ${_timeout}

        ${_download}

        CMAKE_COMMAND \"${CMAKE_COMMAND}\"  # "需要转义, 作为字符串的一部分内容
        CMAKE_GENERATOR \"${CMAKE_GENERATOR}\"
        CMAKE_GENERATOR_PLATFORM \"${CMAKE_GENERATOR_PLATFORM}\"
        CMAKE_GENERATOR_TOOLSET \"${CMAKE_GENERATOR_TOOLSET}\"
        CMAKE_GENERATOR_INSTANCE \"${CMAKE_GENERATOR_INSTANCE}\"

        CMAKE_ARGS ${_build_cmake_args}
        CMAKE_CACHE_ARGS ${_build_cmake_cache}
        CMAKE_CACHE_DEFAULT_ARGS ${_build_cmake_default_cache}
        )

    string(REPLACE ";" " \n" CEFP_COMMAND "${_CEFP_COMMAND}")  # 把;替换为空格
    unset(_CEFP_COMMAND)

    set(config_file TRUE)  # 生成文件
    if ((NOT _force) AND (EXISTS ${_cmake_dir}/CMakeLists.txt))  # 非强制模式, 文件已存在
        if (CFEP_${_cmake_dir}_CMAKE_FILE)  # CFEP_${_cmake_dir}_CMAKE_FILE记录文件的md5值
            file(MD5 ${_cmake_dir}/CMakeLists.txt _md5)  # 计算md5
            if (_md5 STREQUAL CFEP_${_cmake_dir}_CMAKE_FILE)
                set(config_file FALSE)  # 不需要构建文件
            endif()
            unset(_md5)
        endif()
    endif()

    if (config_file)
        configure_file(${CMakeFindExternalProject_DIR}/CMakeLists.txt.in
                       ${_cmake_dir}/CMakeLists.txt
                       @ONLY)
        file(MD5 ${_cmake_dir}/CMakeLists.txt _md5)  # 计算md5
        set(CFEP_${_cmake_dir}_CMAKE_FILE ${_md5} CACHE INTERNAL "md5" FORCE)
        unset(_md5)
    endif()

    unset(CEFP_CMAKE_VERSION)
    unset(CFEP_NAME)
    unset(SHOW_INFO)

    unset(CEFP_BUILD_PREFIX)
    unset(CEFP_SOURCE_DIR)
    unset(CEFP_BINARY_DIR)
    unset(CEFP_INSTALL_DIR)

    unset(CEFP_COMMAND)

    # 定义项目
    if (_info)
        message(STATUS "CMake Config ${name}...(Please Wait)")
    endif()
    execute_process(
                    COMMAND "${CMAKE_COMMAND}" . -B ./build -G ${CMAKE_GENERATOR} ${_cmake_args}
                    WORKING_DIRECTORY "${_cmake_dir}"
                    RESULT_VARIABLE re
                    OUTPUT_VARIABLE _stdout  # stdout的输出内容
                    ERROR_VARIABLE _stderr  # stderr的输出内容
                    OUTPUT_STRIP_TRAILING_WHITESPACE
                    ERROR_STRIP_TRAILING_WHITESPACE
    )

    if(re)
        _cfep_build_found_inline(FALSE)
        if (_info)
            message(WARNING "CMake config ${name} fail(${re}): \n${_stderr}")
        endif()
        return()
    endif()

    unset(re)
    unset(_stderr)
    unset(_stdout)

    # 构建项目
    if (_info)
        message(STATUS "CMake Build ${name}...(Please Wait)")
    endif()
    execute_process(
                    COMMAND "${CMAKE_COMMAND}" --build .
                    WORKING_DIRECTORY "${_cmake_dir}/build"
                    RESULT_VARIABLE re
                    OUTPUT_VARIABLE _stdout  # stdout的输出内容
                    ERROR_VARIABLE _stderr  # stderr的输出内容
                    OUTPUT_STRIP_TRAILING_WHITESPACE
                    ERROR_STRIP_TRAILING_WHITESPACE
    )

    if(re)
        _cfep_build_found_inline(FALSE)
        if (_info)
            message(WARNING "CMake build ${name} fail(${re}): \n${_stderr}")
        endif()
        return()
    endif()

    unset(re)
    unset(_stderr)
    unset(_stdout)
    _cfep_build_found_inline(TRUE)
endfunction()

function(_cfep_check_build_inline name var)
    set(options)
    set(oneValueArgs
        INSTALL_DIR  # 有三个选择: base, deps, binary
        BUILD_DIR)

    cmake_parse_arguments(cfp "" "${oneValueArgs}" "" ${ARGN})
    if (NOT cfp_BUILD_DIR)
        set(_build_dir "${CMAKE_BINARY_DIR}/deps/${name}")
    else()
        set(_build_dir "${CMAKE_BINARY_DIR}/deps/${cfp_BUILD_DIR}")
    endif()

    if (cfp_INSTALL_DIR STREQUAL "base")
        set(_install_dir ${CMAKE_BINARY_DIR}/${name})
    elseif(cfp_INSTALL_DIR STREQUAL "binary")
        set(_install_dir ${CMAKE_BINARY_DIR}/${name})
    else()
        set(_install_dir ${_build_dir}/install)
    endif()

    if (EXISTS ${_install_dir})
        set(${var} ${_install_dir} PARENT_SCOPE)
        _cfep_build_found_inline(TRUE)
    else()
        set(${var} ${var}-NOFOUND PARENT_SCOPE)
        _cfep_build_found_inline(FALSE)
    endif()
endfunction()

# 从url下载程序
function(_cfep_build_url_inline name dir git git_tag url)
    _cfep_build_inline(${name} DOWNLOAD_COMMAND URL ${url} ${ARGN})
    if (${name}_CFEP_FOUND)
        set(${name}_BUILD TRUE PARENT_SCOPE)
    else()
        set(${name}_BUILD FALSE PARENT_SCOPE)
    endif()
endfunction()

# 从git下载程序
function(_cfep_build_git_inline name dir git git_tag url)
    _cfep_build_inline(${name}
                 DOWNLOAD_COMMAND
                 GIT_REPOSITORY ${git}
                 GIT_TAG ${git_tag}
                 GIT_PROGRESS 0
                 GIT_REMOTE_UPDATE_STRATEGY REBASE_CHECKOUT
                 ${ARGN})
    if (${name}_CFEP_FOUND)
        set(${name}_BUILD TRUE PARENT_SCOPE)
    else()
        set(${name}_BUILD FALSE PARENT_SCOPE)
    endif()
endfunction()

# 指定源文件下载程序
function(_cfep_build_dir_inline name dir git git_tag url)
    _cfep_build_inline(${name} SOURCE_DIR ${dir} ${ARGN})
    if (${name}_CFEP_FOUND)
        set(${name}_BUILD TRUE PARENT_SCOPE)
    else()
        set(${name}_BUILD FALSE PARENT_SCOPE)
    endif()
endfunction()

macro(_cfep_found_inline _found)
    set(__found ${_found})
    if (NOT ${__found})
        set(${_name}_FOUND ${_name}-NOTFOUND)
        if (_required)
            message(FATAL_ERROR "Package not found: ${_name}")
        endif()
        if (NOT _quiet)
            message(WARNING "Package not found: ${_name}")
        endif()
    endif()
    unset(__found)
endmacro()

macro(_cfep_first_find_inline name _cmake)
    if (NOT ${name}_MUST_BUILD)  # _MUST_BUILD则先不构建, 而是寻找该库
        find_package(${name} QUIET ${_find_args})  # 尝试搜索
    else()
        set(${name}_MUST_BUILD FALSE CACHE BOOL "" FORCE)
    endif()
    if (NOT ${name}_FOUND)
        _cfep_check_build_inline(${name} re ${_external_args})
        if (re)
            if (_cmake)
                set(${name}_DIR "${re}/${_cmake}" CACHE PATH "" FORCE)
            elseif(WIN32 AND NOT CYGWIN)
                set(${name}_DIR "${re}/cmake" CACHE PATH "" FORCE)
            else()
                set(${name}_DIR "${re}/share/cmake/${name}" CACHE PATH "" FORCE)
            endif()
            find_package(${name} QUIET ${_find_args})  # 尝试搜索
        endif()
    endif()
endmacro()

macro(_cfep_find_xxx_inline name func)
    while (1)  # 宏无法处理return, 所以使用while+break来模拟return
        set(options REQUIRED QUIET MODULE)
        set(oneValueArgs SOURCE_DIR URL GIT GIT_TAG CMAKE_DIR)
        set(multiValueArgs
            PACKAGE
            EXTERNAL)

        cmake_parse_arguments(cfpu
                              "${options}"
                              "${oneValueArgs}"
                              "${multiValueArgs}"
                              ${ARGN})

        set(_name ${name})
        set(_func ${func})

        set(_dir ${cfpu_SOURCE_DIR})
        set(_git ${cfpu_GIT})
        set(_git_tag ${cfpu_GIT_TAG})
        set(_url ${cfpu_URL})

        set(_cmake ${cfpu_CMAKE_DIR})
        set(_find_args ${cfpu_PACKAGE})
        set(_external_args ${cfpu_EXTERNAL})
        set(_required ${cfpu_REQUIRED})
        set(_quiet ${cfpu_QUIET})
        set(_module ${cfpu_MODULE})

        set(_CMAKE_MODULE_PATH_bak ${CMAKE_MODULE_PATH})
        if (_module)
            list(APPEND CMAKE_MODULE_PATH ${_cmake})  # 此时 _cmake 必须是绝对路径
        endif()

        _cfep_first_find_inline("${name}" "${_cmake}")
        if (${name}_FOUND)
            _cfep_found_inline(TRUE)
            break()
        endif()

        cmake_language(CALL "${_func}" "${_name}" "${_dir}" "${_git}" "${_git_tag}" "${_url}" "${_external_args}")
        if (NOT ${name}_BUILD)  # 未构建
            _cfep_found_inline(FALSE)
            break()
        endif()

        set(${name}_ROOT "${${name}_CFEP_INSTALL}" CACHE PATH "" FORCE)
        if (NOT _module)
            if (_cmake)
                set(${name}_DIR "${${name}_CFEP_INSTALL}/${_cmake}" CACHE PATH "" FORCE)
            elseif(WIN32 AND NOT CYGWIN)
                set(${name}_DIR "${${name}_CFEP_INSTALL}/cmake" CACHE PATH "" FORCE)
            else()
                set(${name}_DIR "${${name}_CFEP_INSTALL}/share/cmake/${name}" CACHE PATH "" FORCE)
            endif()
            list(APPEND CMAKE_MODULE_PATH ${${name}_DIR})  #  追加到MODULE_PATH中应对Module模式
        endif()

        find_package(${name} QUIET ${_find_args})  # 最后搜索
        if (${name}_FOUND)
            _cfep_found_inline(TRUE)
            break()
        endif()
        _cfep_found_inline(FALSE)
        break()
    endwhile()

    unset(_name)

    unset(_dir)
    unset(_git)
    unset(_git_tag)
    unset(_url)
    unset(_cmake)
    unset(_find_args)
    unset(_external_args)
    unset(_required)
    unset(_quiet)

    unset(cfpu_SOURCE_DIR)
    unset(cfpu_CMAKE_DIR)
    unset(cfpu_PACKAGE)
    unset(cfpu_EXTERNAL)
    unset(cfpu_REQUIRED)
    unset(cfpu_QUIET)

    set(CMAKE_MODULE_PATH ${_CMAKE_MODULE_PATH_bak})
    unset(_CMAKE_MODULE_PATH_bak)
endmacro()


# 从url下载文件
macro(cfep_find_url name)
    _cfep_find_xxx_inline(${name} _cfep_build_url_inline ${ARGN})
endmacro()

# 从git下载文件
macro(cfep_find_git name)
    _cfep_find_xxx_inline(${name} _cfep_build_git_inline ${ARGN})
endmacro()

# 从dir下载文件
macro(cfep_find_dir name)
    _cfep_find_xxx_inline(${name} _cfep_build_dir_inline "${name}" ${ARGN})
endmacro()


# 安装程序
function(cfep_install name)
    cmake_parse_arguments(ci "NOT_QUIET" "PREFIX" "" ${ARGN})

    if (NOT ci_PREFIX)
        set(prefix ${CMAKE_INSTALL_PREFIX})
    else()
        set(prefix ${ci_PREFIX})
    endif()

    if (NOT ${name}_CFEP_FOUND)
        if (ci_NOT_QUIET)
            message(WARNING "Cannot install ${name}.")
        endif()
        set(${name}_CFEP_INSTALL_SUCCESS FALSE PARENT_SCOPE)
        return()
    endif()

    if (NOT prefix)
        set(prefix ${CMAKE_INSTALL_PREFIX})
    endif()

    install(DIRECTORY "${${name}_CFEP_INSTALL}/"  # /表示把${${name}_CFEP_INSTALL}的内容安装到${prefix}
            DESTINATION ${prefix}
            USE_SOURCE_PERMISSIONS)
    set(${name}_CFEP_INSTALL_SUCCESS TRUE PARENT_SCOPE)
endfunction()

function(cfep_copy_install name)
    cmake_parse_arguments(cci "NOT_QUIET" "DEST" "" ${ARGN})

    if (NOT cci_DEST)
        set(dest ${CMAKE_BINARY_DIR})
    else()
        set(dest ${cci_DEST})
    endif()

    if (NOT ${name}_CFEP_FOUND)
        if (cci_NOT_QUIET)
            message(WARNING "Cannot copy install ${name}.")
        endif()
        set(${name}_CFEP_COPY_SUCCESS FALSE PARENT_SCOPE)
        return()
    endif()

    execute_process(COMMAND "${CMAKE_COMMAND}" -E copy_directory ${${name}_CFEP_INSTALL} ${dest}
                    RESULT_VARIABLE re)
    if(re)
        if (cci_NOT_QUIET)
            message(WARNING "Cannot copy install ${name}.")
        endif()
        set(${name}_CFEP_COPY_SUCCESS TRUE PARENT_SCOPE)
    endif()
endfunction()