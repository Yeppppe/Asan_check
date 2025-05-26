# 使用自定义ASAN库测试指南

本文档介绍如何在当前机器上使用另一台机器的ASAN库版本进行测试。

## 准备工作

1. 从另一台机器上获取ASAN库文件和头文件
2. 确认库文件的兼容性（架构、版本等）

## 获取ASAN库文件

根据不同系统，ASAN库文件位置可能不同：

### Linux系统

```bash
# 查找ASAN库文件位置
find /usr/lib* -name "*asan*.so*"

# 常见位置包括：
# - /usr/lib/llvm-xx/lib/clang/xx.x.x/lib/linux/libclang_rt.asan-x86_64.so (Clang)
# - /usr/lib/gcc/x86_64-linux-gnu/xx/libasan.so (GCC)
```

### 找到所需的头文件

```bash
# 查找ASAN头文件
find /usr/include -name "*sanitizer*"
find /usr/lib/gcc -name "*sanitizer*"
```

## 将文件复制到当前机器

将找到的库文件和头文件复制到当前机器的适当位置，例如：

```bash
mkdir -p custom_asan/lib
mkdir -p custom_asan/include
# 复制文件...
```

## 使用自定义ASAN库编译测试程序

修改我们的CMake构建过程以使用自定义ASAN库：

```bash
cd test
mkdir -p build
cd build

# 使用自定义ASAN库编译
cmake .. -DUSE_CUSTOM_ASAN=ON -DCUSTOM_ASAN_LIB_PATH=/path/to/custom_asan/lib/libasan.so -DCUSTOM_ASAN_INCLUDE_PATH=/path/to/custom_asan/include

# 编译
cmake --build .
```

## 运行时环境变量设置

在运行测试程序时，可能需要设置一些环境变量：

```bash
# 设置库搜索路径
export LD_LIBRARY_PATH=/path/to/custom_asan/lib:$LD_LIBRARY_PATH

# 运行测试
./asan_test 1
```

## 故障排除

如果遇到库加载问题，可以尝试以下方法：

1. 检查库依赖：
```bash
ldd ./asan_test
```

2. 使用显式预加载：
```bash
LD_PRELOAD=/path/to/custom_asan/lib/libasan.so ./asan_test 1
```

3. 如果遇到版本不兼容问题，请确保：
   - 编译器版本兼容
   - 库文件的架构与当前机器匹配
   - 运行时库的依赖关系满足

## 通过交叉编译环境测试不同版本

另一种方法是使用Docker或交叉编译工具链：

```bash
# 创建具有特定ASAN版本的Docker容器
docker run -v $(pwd):/work -w /work ubuntu:20.04 bash -c "apt-get update && apt-get install -y gcc g++ cmake && cd test && mkdir -p build && cd build && cmake .. && make && ./asan_test 1"
```

## 其他ASAN版本的尝试方法

1. 使用特定版本的编译器：
```bash
/path/to/specific/gcc -fsanitize=address test/main.cpp -o test_with_specific_asan
```

2. 静态链接ASAN库：
```bash
g++ -fsanitize=address -static-libasan test/main.cpp -o test_with_static_asan
``` 