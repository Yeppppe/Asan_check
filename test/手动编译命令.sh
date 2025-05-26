#!/bin/bash

# 这个脚本提供直接通过g++编译测试程序的方法，绕过CMake可能的问题
# 它会创建一个带有完整调试符号的可执行文件

# 确保我们在正确的目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 创建build目录（如果不存在）
mkdir -p manual_build
cd manual_build

echo "编译带有调试符号的ASan测试程序..."

# 使用g++直接编译，添加所有必要的调试和ASan选项
g++ -std=c++11 \
    -g3 \
    -gdwarf-4 \
    -O0 \
    -fsanitize=address \
    -fno-omit-frame-pointer \
    -rdynamic \
    -Wall \
    -Wextra \
    -fno-inline \
    -pthread \
    ../main.cpp \
    -o asan_test_manual

# 检查编译是否成功
if [ $? -eq 0 ]; then
    echo "编译成功！"
    
    # 检查是否包含调试符号
    echo "检查调试符号..."
    file ./asan_test_manual
    readelf -S ./asan_test_manual | grep -i debug
    nm --demangle ./asan_test_manual | grep -i "test_use_after_free" | head -3
    
    echo ""
    echo "可以通过以下命令运行测试程序："
    echo "./asan_test_manual 1  # 测试 Use-After-Free"
    echo "./asan_test_manual 2  # 测试堆缓冲区溢出"
    echo ""
    echo "要使用addr2line定位错误，可以执行："
    echo "addr2line -e ./asan_test_manual -f -C -p <偏移地址>"
    echo ""
    echo "要使用gdb调试，可以执行："
    echo "gdb ./asan_test_manual"
else
    echo "编译失败！"
fi 