#!/bin/bash
set -e

cd "$(dirname "$0")"

killall "Surge Dashboard" 2>/dev/null || true

APP_PATH="/Applications/Surge.app/Contents/Applications/Surge Dashboard.app"
BIN_DIR="$APP_PATH/Contents/MacOS"
TARGET_BIN="$BIN_DIR/Surge Dashboard"
DYLIB_NAME="libfix_dashboard.dylib"

echo "==> 检查 Surge Dashboard 安装路径..."
if [ ! -f "$TARGET_BIN" ]; then
    echo "错误：未在默认路径找到 Surge Dashboard！"
    exit 1
fi

echo "==> 编译热补丁动态库..."
clang -dynamiclib -arch arm64 -isysroot $(xcrun --show-sdk-path) \
  -framework Foundation fix_dashboard.m -o "$DYLIB_NAME"

echo "==> 拷贝动态库进应用目录..."
cp -f "$DYLIB_NAME" "$BIN_DIR/"

echo "==> 检查二进制是否已注入..."
if otool -L "$TARGET_BIN" | grep -q "$DYLIB_NAME"; then
    echo "提示：二进制已包含补丁加载命令，跳过 insert_dylib 注入步骤。"
else
    echo "==> 准备 insert_dylib 注入工具..."
    if ! command -v insert_dylib &> /dev/null; then
        rm -rf /tmp/insert_dylib
        git clone --depth=1 https://github.com/Tyilo/insert_dylib.git /tmp/insert_dylib
        clang /tmp/insert_dylib/insert_dylib/main.c -o /tmp/insert_dylib_bin
        INSERT_BIN="/tmp/insert_dylib_bin"
    else
        INSERT_BIN="insert_dylib"
    fi

    echo "==> 注入 LC_LOAD_DYLIB..."
    "$INSERT_BIN" --inplace --all-yes "@executable_path/$DYLIB_NAME" "$TARGET_BIN"
fi

echo "==> 重新进行深层 ad-hoc 签名..."
codesign -f -s - "$BIN_DIR/$DYLIB_NAME"
codesign --force --deep -s - "$APP_PATH"

echo "==> 搞定！现在可以直接启动 Surge Dashboard 了。"
