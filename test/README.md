# ASan 测试案例

这个目录包含了用于测试 Address Sanitizer (ASan) 的各种内存错误案例。

## 编译说明

### 使用 CMake 编译

```bash
# 创建构建目录
mkdir -p build
cd build

# 配置项目 (启用 ASan)
cmake ..

# 或者禁用 ASan
# cmake -DUSE_ASAN=OFF ..

# 或者启用 HWASan (仅在支持的平台上)
# cmake -DUSE_HWASAN=ON -DUSE_ASAN=OFF ..

# 使用自定义ASAN库（比如来自其他机器的ASAN版本）
# cmake .. -DUSE_CUSTOM_ASAN=ON -DCUSTOM_ASAN_LIB_PATH=/path/to/libasan.so -DCUSTOM_ASAN_INCLUDE_PATH=/path/to/include

# 编译
cmake --build .
```

## 运行测试

编译完成后，可以运行可执行文件并传入测试编号来测试不同类型的内存错误：

```bash
# 在 build 目录中
./asan_test <测试编号>
```

## 可用测试

1. Use-After-Free (使用已释放的内存)
2. 堆缓冲区溢出 (写入)
3. 堆缓冲区溢出读取循环
4. 重复释放 (Double Free)
5. 空指针解引用
6. 内存泄漏
7. 栈缓冲区溢出
8. 多线程 UAF 循环

## 示例

```bash
# 测试 Use-After-Free
./asan_test 1

# 测试堆缓冲区溢出
./asan_test 2
```

## 环境变量

可以通过设置环境变量来控制 ASan 的行为：

```bash
# 设置 ASan 选项
export ASAN_OPTIONS=detect_leaks=1:halt_on_error=0:verbosity=1

# 运行测试
./asan_test 1
```

## 常用 ASAN_OPTIONS

- `detect_leaks=1` - 启用内存泄漏检测
- `halt_on_error=0` - 发现错误后继续执行
- `verbosity=1` - 增加输出详细程度
- `print_stacktrace=1` - 打印堆栈跟踪
- `malloc_context_size=20` - 设置堆栈跟踪深度

## 使用自定义ASAN库

如果您需要在当前机器上测试其他机器的ASAN版本，请参考 [使用自定义ASAN库.md](使用自定义ASAN库.md) 文件获取详细指南。

## 注意事项

- 某些测试会导致程序崩溃，这是预期行为
- 使用 ASan 会增加内存使用量和运行时开销
- HWASan 仅在特定平台（如 ARM64）上可用
- 使用自定义ASAN库时，请确保库文件与当前环境兼容 