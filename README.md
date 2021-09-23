# CMakeFindExternalProject
## 简介
CMakeFindExternalProject（下称CFEP）是用于CMake构建系统的依赖管理工具。  
其实现借助CMake内置的ExternalProject模块。  
允许CMake在配置期（而非构建期）安装第三方依赖库。  
同时, 它提供了第三方依赖安装, Windows运行时库安装等工具。

## 功能
**使用注意：**
**以下函数(宏)均允许以小写形式调用**

### 第三方依赖
CMake提供如下函数:
```CEFP_find_xxx```
xxx可以为`url`，`git`，`dir`分别表示从不同的地方下载第三方依赖库。  
并不是所有时候都会下载构建并安装(不是安装到全局目录而是安装到)第三方依赖库，只有通过`find_package`无法定位到库时才会购机第三方库。

#### 从URL下载项目
```
cfep_find_url(<name>
    [REQUIRED]
    [QUIET]
    [URL _url]
    [CMAKE_DIR _dir]
    [PACKAGE ...]
    [EXTERNAL ...]
)
```

- `name` 库名，用于`find_package`。（必须指定）
- `REQUIRED` 参数表示是否强制找到该库。
- `QUITE` 参数表示是否保持安静，即不输出信息。
- `URL` 指定一个`url`链接。（必须指定）
- `CMAKE_DIR` 表示当构建并安装该库后，该库的CMake文件夹和安装目录的相对位置。
若不提供该值，则使用默认值，具体见后文。
- `PACKAGE` 可跟多个参数, 将应用于`find_package`。但不可为`REQUIRED`以及`QUIET`。
- `EXTERNAL` 可跟多个参数, 具体见后文。

该函数的执行效果与`find_package`一样，本质就是调用`find_package`。
可以设定`cache`：`<name>_BUILD`表示必须启用构建, 而不是先`find_package`。
同时, 还会额外定义一下`CACHE`。

- `<name>_CFEP_FOUND` 表示CFEP是否成功构建, 安装第三方依赖库
- `<name>_CFEP_BUILD_DIR` 表示第三方库的构建位置（不代表找到该库）
- `<name>_CFEP_INSTALL` 表示第三方库的安装位置
- `<name>_CFEP_INSTALL_TYPE` 表示第三方库的安装类型，具体见后文

**注意：库被安装后会再次执行find_package, 但库成功安装不代表find_package能成功。**
**同时`<name>_CFEP_FOUND`也只表示库安装成功, `<name>_FOUND`才能代表库定位成功**
**库并不是直接安装在`CMAKE_INSTALL_PREFIX`中**

##### EXTERNAL参数
EXTERNAL支持如下参数：
```
NOT_INFO
FORCE

BUILD_DIR _build_dir
INSTALL_DIR _install
TIMEOUT _time

CMAKE_ARGS ...
BUILD_CMAKE_ARGS ...
BUILD_CMAKE_CACHE_ARGS ...
BUILD_CMAKE_CACHE_DEFAULT_ARGS ...
```
CFEP的原理的构建原理是, 生成一个`CMakeLists.txt`，其中调用`ExternalProject`模块, 最后执行`CMakeLists.txt`。

- `NOT_INFO` 不显示消息
- `FORCE` 强制执行 (当多次执行时, `CMakeLists.txt`不会重复生成, 因此配置步骤的部分内容不会重复执行, 使用该选项将强制`CMakeLists.txt`重新生成)
- `BUILD_DIR` 项目构建的位置 默认是：`CMAKE_BINARY_DIR/deps/<name>`，指定后变为`CMAKE_BINARY_DIR/deps/<_build_dir>`
- `INSTALL_DIR` 项目的安装方式：
    - `base` 或 `binary`：安装到`CMAKE_BINARY_DIR/<name>`
    - 其他：安装到`_build_dir/install`
- `TIMEOUT` 下载超时(不是构建超时)
- `CMAKE_ARGS` 运行`CMakeLists.txt`的CMake命令行参数
- `BUILD_CMAKE_ARGS`传递给`ExternalProject_Add`的`CMAKE_ARGS`参数。已经设定生成器和`CMAKE_BUILD_TYPE`，以及生成器等参数。
- `BUILD_CMAKE_CACHE_ARGS`传递给`ExternalProject_Add`的`CMAKE_CACHE_ARGS`参数。已经设定生成器和`CMAKE_INSTALL_PREFIX`参数。
- `BUILD_CMAKE_CACHE_DEFAULT_ARGS`传递给`ExternalProject_Add`的`CMAKE_CACHE_DEFAULT_ARGS`参数。

在`_build_dir`目录下还包括一些构建日志`log`, 源码`source`等。

##### CMAKE_DIR参数
CFEP安装项目后, 需要找到该项目的`cmake`文件所在路径，供`find_package`使用。
因此，`CMAKE_DIR`参数用于指定`cmake`文件相对于该库的安装路径的位置。
默认值为：
`Windows`: `./cmake`
其他系统: `./shared/cmake/<name>`

#### 从git下载项目
与从`url`下载项目类似, 但没有`URL`参数, 添加如下参数：
```
GIT _git
GIT_TAG _tag
```
* `GIT` git仓库的地址。不建议使用`ssh`。（必须指定）
* `GIT_TAG` git_tag, 可以为hash信息, git标签, git分支名。（必须指定）

其余效果与`url`相似。
`<_build_dir>`目录下`download`文件夹将为空。

#### 从本地文件构建项目
与从`url`下载项目类似，但没有`URL`参数，添加如下参数：
```
SOURCE_DIR _source_dir
```
* `SOURCE_DIR` 指定第三方依赖库的文件夹

其余效果与`url`相似。
`<_build_dir>`目录下`download`文件夹将为空。
`<_build_dir>`目录下将没有`source`文件夹。

### 安装第三方依赖
#### 添加到安装目录
将第三方依赖安装到指定位置(随构建树一起安装)，使用函数:
```
cfep_install(<name>
    [NOT_QUIET]
    [PREFIX _prefix]
)
```

* `name` 即第三方依赖库名字, 同CFEP_find_xxx。
* `NOT_QUIET` 即输出安装信息
* `PREFIX` 即安装位置, 默认为`CMAKE_INSTALL_PREFIX`

注意：该函数执行前需要执行`CFEP_find_xxx`函数。
若`CFEP_find_xxx`未安装第三方依赖, 则此函数被的执行被忽略。

#### 立即复制到指定位置
将第三方依赖安装的内容复制到指定位置(CMake配置时执行)，使用函数:
```
cfep_copy_install(<name>
    [NOT_QUIET]
    [DEST _dest]
)
```

* `name` 即第三方依赖库名字, 同CFEP_find_xxx。
* `NOT_QUIET` 即输出安装信息
* `DEST` 即复制的位置, 默认为`CMAKE_BINARY_DIR`

注意：该函数执行前需要执行`CFEP_find_xxx`函数。
若`CFEP_find_xxx`未安装第三方依赖, 则此函数被的执行被忽略。

### Windows动态库
以下函数尽在`windows`平台生效, 其他平台执行无效果

#### 安装导入库
因为`windows`平台没有`rpath`等机制, 因此需要将第三方导入的库的`.dll`复制到指定位置
使用函数:
```
wi_install_import(
    [RUNTIME _runtime]
    [LIBRARY _library]
    [TARGETS ...]
)
```

* `RUNTIME` 运行时库安装的位置, 默认值为`INSTALL_BINDIR`
* `LIBRARY` 导入库的安装位置，默认值为`INSTALL_LIBDIR`
* `TARGETS` 安装的对象

`wi_install_import`是在构建树安装时才安装导入的库。
使用`wi_copy_import`可以在`CMake`配置时就复制文件到指定位置。
使用方式和`wi_install_import`相同。

#### 安装`.dll`
使用如下函数，可以检索文件夹下的所有`dll`并安装到指定位置：
```
wi_install_dll_bin(
    [RUNTIME _runtime]
    [DIRS ...]
)
```

* `RUNTIME` 运行时库安装的位置, 默认值为`INSTALL_BINDIR`
* `DIRS` 需要检查的目录路径

`wi_install_dll_bin`是在构建树安装时才安装导入的库。
使用`wi_copy_dll_bin`可以在`CMake`配置时就复制文件到指定位置。
使用方式和`wi_install_dll_bin`相同。

#### 检查是否包含`.exe`
使用如下函数，检查一个目录是否包含`.exe`，若包含则将该目录的`.dll`安装到指定位置：
```
wi_install_dll_dir(
    [RUNTIME _runtime]
    [DIRS ...]
)
```

* `RUNTIME` 运行时库安装的位置, 默认值为`INSTALL_BINDIR`
* `DIRS` 需要检查的目录路径

`wi_install_dll_dir`是在构建树安装时才安装导入的库。
使用`wi_copy_dll_dir`可以在`CMake`配置时就复制文件到指定位置。
使用方式和`wi_install_dll_dir`相同。

### 安装程序
#### 设定安装路径
设定标准的`GNU`安装路径, 使用如下函数：
```
wi_set_install_dir
wi_set_install_dir_quiet
```
以上两个函数的区别在于, 后者不会显示任何信息。
注意：该函数必须在`project`指令后执行。

他们将会设定`cache`:
- INSTALL_LIBDIR  库文件的安装路径
- INSTALL_BINDIR  可执行文件的安装路径
- INSTALL_INCLUDEDIR  头文件的安装路径
- INSTALL_RESOURCEDIR  `resource`文件的安装路径
- INSTALL_CMAKEDIR  `cmake`文件的安装路径

同时还会设定构建时动态库和可执行文件的输出位置
- CMAKE_ARCHIVE_OUTPUT_DIRECTORY
- CMAKE_LIBRARY_OUTPUT_DIRECTORY
- CMAKE_RUNTIME_OUTPUT_DIRECTORY

#### 使用安装路径安装
使用如下函数安装对象, 该函数和`install`指令类似, 但是使用了预设的安装路径。
```
wi_install(
    [INSTALL ...]
    [ARCHIVE ...]
    [RUNTIME ...]
    [LIBRARY ...]
    [PUBLIC_HEADER ...]
    [RESOURCE ...]
    [OTHER_TARGET ...]
)
```

* `INSTALL` 参数用于`install`指令
* `ARCHIVE`，`RUNTIME`等和`install`的`ARCHIVE`，`RUNTIME`类似，但`DESTINATION`已经被设定
* `OTHER_TARGET` 则是`install`指令的其他参数

## 使用方式
将项目中的`cmake/CMakeFindExternalProject`文件夹放置在项目指定位置, 在`cmake`中执行：
```
include(<CMakeFindExternalProject文件夹位置>/init.cmake)
```
### 文件介绍
* `CMakeFindExternalProject.cmake`文件包含的是第三方依赖管理的程序
依赖于`CMakeLists.txt.in`文件
* `WindowsInstall.cmake`是`.dll`安装程序
* `InstallDir.cmake`是安装路径设置程序以及安装程序
依赖于`_void_p_test.c`文件，该程序用于检查一个`void`指针的大小。

## 声明
### 开源协议
本程序是在`HUAN LICENSE`下发布的。
