#!/bin/bash

# 自动辅助脚本，用于从远程机器获取ASAN库并设置本地环境

# 默认参数
REMOTE_HOST=""
REMOTE_USER=""
REMOTE_GCC_VERSION=""
OUTPUT_DIR="./custom_asan"
REMOTE_PASS_FILE=""

# 解析命令行参数
function show_usage {
    echo "用法: $0 -h <远程主机> -u <用户名> [-g <GCC版本>] [-o <输出目录>] [-p <密码文件>]"
    echo "  -h <远程主机>     远程主机IP或域名"
    echo "  -u <用户名>       远程主机用户名"
    echo "  -g <GCC版本>      远程主机GCC版本 (默认: 自动检测)"
    echo "  -o <输出目录>     本地输出目录 (默认: ./custom_asan)"
    echo "  -p <密码文件>     包含SSH密码的文件路径 (可选)"
    echo "  -h                显示此帮助信息"
    exit 1
}

while getopts "h:u:g:o:p:" opt; do
    case ${opt} in
        h)
            REMOTE_HOST=$OPTARG
            ;;
        u)
            REMOTE_USER=$OPTARG
            ;;
        g)
            REMOTE_GCC_VERSION=$OPTARG
            ;;
        o)
            OUTPUT_DIR=$OPTARG
            ;;
        p)
            REMOTE_PASS_FILE=$OPTARG
            ;;
        \?)
            show_usage
            ;;
    esac
done

# 检查必要参数
if [ -z "$REMOTE_HOST" ] || [ -z "$REMOTE_USER" ]; then
    echo "错误: 远程主机和用户名是必需的。"
    show_usage
fi

# 创建输出目录
mkdir -p "$OUTPUT_DIR/lib"
mkdir -p "$OUTPUT_DIR/include"

# 构建SSH命令
SSH_CMD="ssh"
if [ ! -z "$REMOTE_PASS_FILE" ]; then
    if command -v sshpass &> /dev/null; then
        SSH_CMD="sshpass -f $REMOTE_PASS_FILE ssh"
    else
        echo "警告: sshpass 未安装，将不使用密码文件"
    fi
fi

echo "连接到远程主机 ${REMOTE_USER}@${REMOTE_HOST}..."

# 如果没有指定GCC版本，则自动检测
if [ -z "$REMOTE_GCC_VERSION" ]; then
    echo "检测远程GCC版本..."
    REMOTE_GCC_VERSION=$($SSH_CMD ${REMOTE_USER}@${REMOTE_HOST} "gcc --version | head -n 1 | grep -oP '(?<=gcc \(.*\) )[0-9]+\.[0-9]+\.[0-9]+'" 2>/dev/null)
    
    if [ -z "$REMOTE_GCC_VERSION" ]; then
        echo "无法检测远程GCC版本，将尝试查找任何版本的ASAN库"
    else
        echo "检测到远程GCC版本: $REMOTE_GCC_VERSION"
    fi
fi

# 查找远程ASAN库文件
echo "在远程主机上查找ASAN库文件..."
REMOTE_ASAN_LIBS=$($SSH_CMD ${REMOTE_USER}@${REMOTE_HOST} "find /usr/lib* -name \"*asan*.so*\" 2>/dev/null" 2>/dev/null)

if [ -z "$REMOTE_ASAN_LIBS" ]; then
    echo "错误: 在远程主机上未找到ASAN库文件"
    exit 1
fi

echo "找到以下ASAN库:"
echo "$REMOTE_ASAN_LIBS"

# 查找远程ASAN头文件
echo "在远程主机上查找ASAN相关头文件..."
REMOTE_ASAN_HEADERS=$($SSH_CMD ${REMOTE_USER}@${REMOTE_HOST} "find /usr/include /usr/lib/gcc -name \"*sanitizer*.h\" 2>/dev/null" 2>/dev/null)

if [ -z "$REMOTE_ASAN_HEADERS" ]; then
    echo "警告: 在远程主机上未找到ASAN头文件"
else
    echo "找到以下ASAN相关头文件:"
    echo "$REMOTE_ASAN_HEADERS"
fi

# 获取远程机器架构
echo "获取远程机器架构..."
REMOTE_ARCH=$($SSH_CMD ${REMOTE_USER}@${REMOTE_HOST} "uname -m" 2>/dev/null)
echo "远程机器架构: $REMOTE_ARCH"

# 获取本地机器架构
LOCAL_ARCH=$(uname -m)
echo "本地机器架构: $LOCAL_ARCH"

# 检查架构兼容性
if [ "$LOCAL_ARCH" != "$REMOTE_ARCH" ]; then
    echo "警告: 本地架构 ($LOCAL_ARCH) 与远程架构 ($REMOTE_ARCH) 不匹配，这可能导致兼容性问题"
fi

# 复制库文件
echo "复制ASAN库文件到本地..."
for lib in $REMOTE_ASAN_LIBS; do
    lib_name=$(basename "$lib")
    echo "复制 $lib -> $OUTPUT_DIR/lib/$lib_name"
    $SSH_CMD ${REMOTE_USER}@${REMOTE_HOST} "cat $lib" > "$OUTPUT_DIR/lib/$lib_name"
    chmod +x "$OUTPUT_DIR/lib/$lib_name"
done

# 复制头文件
if [ ! -z "$REMOTE_ASAN_HEADERS" ]; then
    echo "复制ASAN头文件到本地..."
    for header in $REMOTE_ASAN_HEADERS; do
        header_dir=$(dirname "$header" | sed 's|^/usr/include/||' | sed 's|^/usr/lib/gcc/[^/]*/[^/]*/include/||')
        mkdir -p "$OUTPUT_DIR/include/$header_dir"
        header_name=$(basename "$header")
        echo "复制 $header -> $OUTPUT_DIR/include/$header_dir/$header_name"
        $SSH_CMD ${REMOTE_USER}@${REMOTE_HOST} "cat $header" > "$OUTPUT_DIR/include/$header_dir/$header_name"
    done
fi

echo "完成!"
echo "ASAN库和头文件已保存到 $OUTPUT_DIR 目录"

# 生成使用说明
cat > "$OUTPUT_DIR/使用说明.md" << EOF
# 自定义ASAN库使用说明

这些文件是从远程机器 ${REMOTE_USER}@${REMOTE_HOST} 复制的ASAN库和头文件。

## 库文件
库文件位于 \`lib\` 目录中。

## 头文件
头文件位于 \`include\` 目录中。

## 使用方法

### 编译时使用这些库

```bash
cd test
mkdir -p build
cd build
cmake .. -DUSE_CUSTOM_ASAN=ON -DCUSTOM_ASAN_LIB_PATH=${OUTPUT_DIR}/lib/libasan.so -DCUSTOM_ASAN_INCLUDE_PATH=${OUTPUT_DIR}/include
cmake --build .
```

### 运行时设置环境变量

```bash
export LD_LIBRARY_PATH=${OUTPUT_DIR}/lib:\$LD_LIBRARY_PATH
./asan_test 1
```

或者使用预加载:

```bash
LD_PRELOAD=${OUTPUT_DIR}/lib/libasan.so ./asan_test 1
```

## 注意事项

- 远程机器架构: ${REMOTE_ARCH}
- 本地机器架构: ${LOCAL_ARCH}
$([ "$LOCAL_ARCH" != "$REMOTE_ARCH" ] && echo "- 警告: 架构不匹配，可能存在兼容性问题")
EOF

echo "已生成使用说明: $OUTPUT_DIR/使用说明.md" 