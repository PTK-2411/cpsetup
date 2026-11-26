#!/usr/bin/env bash
set -euo pipefail

# Build an All-in-One USB archive: ./cb/cb-all-os.zip
# Layout inside zip:
#   auto.sh, auto.bat, linux/, win/, mac/
# Usage: bash cb/src/usb/build-all-os-zip.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CB_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUT_ZIP="$CB_DIR/cb-all-os.zip"

if ! command -v zip >/dev/null 2>&1; then
    echo "[CPSetup] Loi: Can cong cu 'zip' de dong goi cb-all-os.zip." >&2
    exit 1
fi

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

mkdir -p "$STAGE/linux" "$STAGE/win" "$STAGE/mac"

# Copy Linux packages
for f in linux64-offline.tar.gz linux64.deb linux32.deb linux64.rpm linux32.rpm linux64.tar.gz linux32.tar.gz; do
    if [ -f "$CB_DIR/$f" ]; then
        cp -f "$CB_DIR/$f" "$STAGE/linux/$f"
    fi
done

# Copy Windows installers
for f in cb-win64.exe cb-win32.exe; do
    if [ -f "$CB_DIR/$f" ]; then
        cp -f "$CB_DIR/$f" "$STAGE/win/$f"
    fi
done

# Copy macOS installers
for f in cb-mac64.dmg mac64.sh macarm64.sh; do
    if [ -f "$CB_DIR/$f" ]; then
        cp -f "$CB_DIR/$f" "$STAGE/mac/$f"
    fi
done

# Create USB auto.sh for Linux & macOS
cat > "$STAGE/auto.sh" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

USB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"
MACHINE="$(uname -m)"

case "$MACHINE" in
    x86_64|amd64) ARCH="64" ;;
    i386|i686)    ARCH="32" ;;
    arm64|aarch64) ARCH="arm64" ;;
    *)
        echo "[CPSetup] Loi: Kien truc '$MACHINE' chua duoc ho tro." >&2
        exit 1
        ;;
esac

run_privileged() {
    if [ "$(id -u)" -eq 0 ]; then "$@"
    elif command -v sudo >/dev/null 2>&1; then sudo "$@"
    else echo "[CPSetup] Can quyen root hoac sudo." >&2; exit 1
    fi
}

if [ "$OS" = "Linux" ]; then
    echo "[CPSetup USB] Phat hien Linux ($ARCH-bit)."
    OFFLINE_TGZ="$USB_DIR/linux/linux${ARCH}-offline.tar.gz"
    if command -v apt-get >/dev/null 2>&1 && [ -f "$OFFLINE_TGZ" ]; then
        TMP_DIR="$(mktemp -d)"
        trap 'rm -rf "$TMP_DIR"' EXIT
        tar -xzf "$OFFLINE_TGZ" -C "$TMP_DIR"
        bash "$TMP_DIR/cpsetup-cb-linux${ARCH}-offline/install-offline.sh"
        exit 0
    fi

    if command -v apt-get >/dev/null 2>&1 && [ -f "$USB_DIR/linux/linux${ARCH}.deb" ]; then
        run_privileged apt-get update
        run_privileged apt-get install -y "$USB_DIR/linux/linux${ARCH}.deb"
        command -v cpsetup-cb-config >/dev/null 2>&1 && cpsetup-cb-config
        echo "[CPSetup] Cai dat hoan tat! Go 'cb' de mo Code::Blocks."
        exit 0
    fi

    if (command -v dnf >/dev/null 2>&1 || command -v rpm >/dev/null 2>&1) && [ -f "$USB_DIR/linux/linux${ARCH}.rpm" ]; then
        if command -v dnf >/dev/null 2>&1; then
            run_privileged dnf install -y "$USB_DIR/linux/linux${ARCH}.rpm"
        else
            run_privileged rpm -Uvh --replacepkgs "$USB_DIR/linux/linux${ARCH}.rpm"
        fi
        command -v cpsetup-cb-config >/dev/null 2>&1 && cpsetup-cb-config
        echo "[CPSetup] Cai dat hoan tat! Go 'cb' de mo Code::Blocks."
        exit 0
    fi

    if [ -f "$USB_DIR/linux/linux${ARCH}.tar.gz" ]; then
        TMP_DIR="$(mktemp -d)"
        trap 'rm -rf "$TMP_DIR"' EXIT
        tar -xzf "$USB_DIR/linux/linux${ARCH}.tar.gz" -C "$TMP_DIR"
        bash "$TMP_DIR/cpsetup-cb-linux${ARCH}/install.sh"
        exit 0
    fi

    echo "[CPSetup] Khong tim thay goi phu hop trong $USB_DIR/linux/." >&2
    exit 1
elif [ "$OS" = "Darwin" ]; then
    echo "[CPSetup USB] Phat hien macOS ($ARCH)."
    if [ -f "$USB_DIR/mac/cb-mac64.dmg" ]; then
        echo "[CPSetup] Dang mo file Code::Blocks DMG offline ($USB_DIR/mac/cb-mac64.dmg)..."
        hdiutil attach "$USB_DIR/mac/cb-mac64.dmg" || open "$USB_DIR/mac/cb-mac64.dmg"
        echo "[CPSetup] Hay keo CodeBlocks.app vao thu muc Applications."
    fi
    if [ "$ARCH" = "arm64" ] && [ -f "$USB_DIR/mac/macarm64.sh" ]; then
        echo "[CPSetup] Neu may co mang va Homebrew, ban co the chay: bash \"$USB_DIR/mac/macarm64.sh\""
    elif [ -f "$USB_DIR/mac/mac64.sh" ]; then
        echo "[CPSetup] Neu may co mang va Homebrew, ban co the chay: bash \"$USB_DIR/mac/mac64.sh\""
    fi
else
    echo "[CPSetup] He dieu hanh '$OS' khong ho tro auto.sh (tren Windows hay chay auto.bat)." >&2
    exit 1
fi
EOF
chmod 0755 "$STAGE/auto.sh"

# Create USB auto.bat for Windows (CRLF)
cat > "$STAGE/auto.bat" << 'EOF'
@echo off
setlocal enabledelayedexpansion

set "ARCH=32"
if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" set "ARCH=64"
if /i "%PROCESSOR_ARCHITEW6432%"=="AMD64" set "ARCH=64"

set "INSTALLER=%~dp0win\cb-win%ARCH%.exe"
echo [CPSetup USB] Phat hien Windows %ARCH%-bit.

if not exist "%INSTALLER%" (
    echo [CPSetup] Loi: Khong tim thay %INSTALLER% trong USB. >&2
    pause
    exit /b 1
)

echo [CPSetup] Dang chay bo cai dat offline: %INSTALLER%
start /wait "" "%INSTALLER%"

where g++ >nul 2>nul && (
    echo [OK] Da tim thay g++ trong PATH.
) || (
    echo [INFO] Neu g++ chua co trong PATH, hay them thu muc MinGW\bin cua Code::Blocks vao PATH.
)

echo [CPSetup] Hoan tat!
pause
endlocal
EOF
sed -i 's/\r$//; s/$/\r/' "$STAGE/auto.bat"

rm -f "$OUT_ZIP"
(
    cd "$STAGE"
    zip -r -q "$OUT_ZIP" auto.sh auto.bat linux win mac
)

echo "[CPSetup] Da tao goi USB All-in-One: $OUT_ZIP"
ls -lh "$OUT_ZIP"
