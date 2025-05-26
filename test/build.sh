#!/bin/bash

# 检查是否安装了cmake
if ! command -v cmake &> /dev/null; then
    echo "错误: 未找到cmake，请先安装cmake"
    exit 1
fi

# 创建构建目录
mkdir -p build
cd build

# 配置项目
echo "配置项目..."
cmake .. "$@"

# 编译
echo "编译项目..."
cmake --build .

# 检查编译是否成功
if [ -f ./asan_test ]; then
    echo "编译成功!"
    echo ""
    echo "运行测试示例:"
    echo "./asan_test 1  # 测试 Use-After-Free"
    echo "./asan_test 2  # 测试堆缓冲区溢出"
    echo ""
    echo "完整测试列表请参考 README.md"
else
    echo "编译失败!"
fi 