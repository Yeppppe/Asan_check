@echo off
setlocal

REM 检查是否安装了cmake
where cmake >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo 错误: 未找到cmake，请先安装cmake
    exit /b 1
)

REM 创建构建目录
if not exist build mkdir build
cd build

REM 配置项目
echo 配置项目...
cmake .. %*

REM 编译
echo 编译项目...
cmake --build . --config Release

REM 检查编译是否成功
if exist Release\asan_test.exe (
    echo 编译成功!
    echo.
    echo 运行测试示例:
    echo Release\asan_test.exe 1  # 测试 Use-After-Free
    echo Release\asan_test.exe 2  # 测试堆缓冲区溢出
    echo.
    echo 完整测试列表请参考 README.md
) else if exist asan_test.exe (
    echo 编译成功!
    echo.
    echo 运行测试示例:
    echo asan_test.exe 1  # 测试 Use-After-Free
    echo asan_test.exe 2  # 测试堆缓冲区溢出
    echo.
    echo 完整测试列表请参考 README.md
) else (
    echo 编译失败!
)

cd .. 