#!/bin/bash
# os_01 项目构建脚本

echo "🔨 编译 os_01 项目..."
echo ""

cd "$(dirname "$0")"

# 检测操作系统
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "检测到 Linux 系统，使用 Linux 编译选项"
    cargo rustc -- -Clink-arg=-nostartfiles
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "检测到 macOS 系统，使用 macOS 编译选项"
    cargo rustc -- -Clink-arg=-nostdlib -Clink-arg=-Wl,-e,__start
else
    echo "未知操作系统，尝试使用 Linux 编译选项"
    cargo rustc -- -Clink-arg=-nostartfiles
fi

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 编译成功！"
    echo "📦 二进制文件位置:"
    if [ -f "target/debug/os_01" ]; then
        ls -lh target/debug/os_01
    elif [ -f "target/debug/os_01.exe" ]; then
        ls -lh target/debug/os_01.exe
    fi
else
    echo ""
    echo "❌ 编译失败，请检查错误信息"
    exit 1
fi
