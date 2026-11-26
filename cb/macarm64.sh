#!/usr/bin/env bash
set -euo pipefail

# CPSetup - Code::Blocks + GNU C++17 Installer for macOS Apple Silicon (arm64)
# Usage: curl -fsSL https://raw.githubusercontent.com/PTK-2411/cpsetup/main/cb/macarm64.sh | bash

if [ "$(uname -s)" != "Darwin" ] || [ "$(uname -m)" != "arm64" ]; then
    echo "[CPSetup] Loi: Script nay danh cho macOS Apple Silicon (arm64). He thong hien tai: $(uname -s) $(uname -m)." >&2
    exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
    echo "[CPSetup] Loi: Chua co Homebrew. Cai Homebrew truoc tai https://brew.sh" >&2
    exit 1
fi

echo "[CPSetup] Dang cai dat GNU GCC (g++) va Code::Blocks qua Homebrew..."
brew list gcc >/dev/null 2>&1 || brew install gcc
brew list --cask codeblocks >/dev/null 2>&1 || brew install --cask codeblocks
echo "[INFO] Luu y: Tren Apple Silicon (arm64), gdb khong ho tro chinh thuc; dung lldb cua Xcode Command Line Tools."

GPP_BIN="$(command -v g++-15 || command -v g++-14 || command -v g++-13 || true)"
if [ -n "$GPP_BIN" ]; then
    echo "[OK] GNU g++ -> $GPP_BIN ($("$GPP_BIN" --version | head -n 1))"
    TMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TMP_DIR"' EXIT
    printf '#include <iostream>\nint main(){ std::cout << "C++17 OK\\n"; }\n' > "$TMP_DIR/test.cpp"
    "$GPP_BIN" -std=c++17 -O2 "$TMP_DIR/test.cpp" -o "$TMP_DIR/test" && "$TMP_DIR/test"
else
    echo "[WARN] Chua tim thay g++-13/14/15. Luu y /usr/bin/g++ tren macOS la Apple Clang."
fi

echo "[CPSetup] Cai dat hoan tat! Hay chon trinh bien dich GNU GCC ($GPP_BIN) trong Code::Blocks."
