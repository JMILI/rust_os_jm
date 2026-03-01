#!/bin/bash
# mdbook 本地服务器启动脚本

echo "🚀 启动 mdbook 本地服务器..."
echo "📖 教程地址：http://localhost:3000"
echo ""
echo "💡 提示："
echo "   - 在 WSL 中，请手动在 Windows 浏览器中打开 http://localhost:3000"
echo "   - 或者使用 Windows 终端，运行: start http://localhost:3000"
echo ""
echo "按 Ctrl+C 停止服务器"
echo ""

cd "$(dirname "$0")"

# 检测是否在 WSL 环境中
if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null ; then
    # WSL 环境：不自动打开浏览器，但提供提示
    echo "检测到 WSL 环境，请手动打开浏览器访问 http://localhost:3000"
    mdbook serve
else
    # 非 WSL 环境：尝试自动打开浏览器
    mdbook serve --open
fi
