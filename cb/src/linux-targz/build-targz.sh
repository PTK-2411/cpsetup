#!/usr/bin/env bash
set -euo pipefail

# Build portable Linux tar.gz packages (Arch / Manjaro / openSUSE / generic Linux)
# Output: ./cb/linux64.tar.gz and/or ./cb/linux32.tar.gz
# Usage: bash cb/src/linux-targz/build-targz.sh [64|32|all]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="$(cd "$SCRIPT_DIR/../common" && pwd)"
CB_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TARGET="${1:-all}"

build_one() {
    local bits="$1"
    local stage
    stage="$(mktemp -d)"
    trap 'rm -rf "$stage"' RETURN

    local pkg_root="$stage/cpsetup-cb-linux${bits}"
    mkdir -p "$pkg_root/usr/bin" "$pkg_root/usr/share/cpsetup-cb"
    cp "$COMMON_DIR/usr/bin/"* "$pkg_root/usr/bin/"
    cp "$COMMON_DIR/usr/share/cpsetup-cb/default.conf.template" "$pkg_root/usr/share/cpsetup-cb/"

    cat > "$pkg_root/install.sh" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_privileged() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        echo "[CPSetup] Loi: Can quyen root hoac 'sudo' de cai dat." >&2
        exit 1
    fi
}

echo "[CPSetup] Dang kiem tra & cai dat g++, gdb, codeblocks..."
if command -v pacman >/dev/null 2>&1; then
    run_privileged pacman -Sy --needed --noconfirm gcc gdb codeblocks
elif command -v dnf >/dev/null 2>&1; then
    run_privileged dnf install -y gcc-c++ gdb codeblocks
elif command -v zypper >/dev/null 2>&1; then
    run_privileged zypper --non-interactive install gcc-c++ gdb codeblocks
elif command -v apt-get >/dev/null 2>&1; then
    run_privileged apt-get update
    run_privileged apt-get install -y g++ gdb codeblocks build-essential
elif command -v apk >/dev/null 2>&1; then
    run_privileged apk add --no-cache g++ gdb codeblocks
else
    echo "[CPSetup] Canh bao: Khong nhan dien duoc trinh quan ly goi. Hay dam bao da cai g++, gdb, codeblocks."
fi

run_privileged mkdir -p /usr/local/bin /usr/local/share/cpsetup-cb
run_privileged cp "$SCRIPT_DIR/usr/bin/cb" /usr/local/bin/cb
run_privileged cp "$SCRIPT_DIR/usr/bin/cpsetup-cb-config" /usr/local/bin/cpsetup-cb-config
run_privileged cp "$SCRIPT_DIR/usr/bin/cpsetup-cb-check" /usr/local/bin/cpsetup-cb-check
run_privileged cp "$SCRIPT_DIR/usr/share/cpsetup-cb/default.conf.template" /usr/local/share/cpsetup-cb/default.conf.template
run_privileged chmod 0755 /usr/local/bin/cb /usr/local/bin/cpsetup-cb-config /usr/local/bin/cpsetup-cb-check

/usr/local/bin/cpsetup-cb-config
echo "[CPSetup] Cai dat hoan tat! Go 'cb' de mo Code::Blocks (tat terminal khong bi tat IDE)."
EOF

    chmod 0755 "$pkg_root/install.sh" "$pkg_root/usr/bin/"*
    chmod 0644 "$pkg_root/usr/share/cpsetup-cb/default.conf.template"

    local out_tgz="$CB_DIR/linux${bits}.tar.gz"
    tar -czf "$out_tgz" -C "$stage" "cpsetup-cb-linux${bits}"
    echo "[CPSetup] Da build thanh cong: $out_tgz"
}

case "$TARGET" in
    64|32) build_one "$TARGET" ;;
    all)
        build_one 64
        build_one 32
        ;;
    *)
        echo "Usage: $0 [64|32|all]" >&2
        exit 1
        ;;
esac
