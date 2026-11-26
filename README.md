# CPSetup (`cpsetup.is-a.dev`)

Bộ cài đặt chuẩn hóa môi trường lập trình thi đấu **C++17** (`-std=c++17 -O2`) cho học sinh luyện thi HSG9 và Chuyên Tin trên Windows, Linux và macOS.

## Quy ước đường dẫn & tên gói
Mỗi nhánh sử dụng cấu trúc `/<mã ide>/<osbase><bit>.<đuôi>` và `/<mã ide>/auto`:
- Ví dụ: `/cb/linux64.deb`, `/cb/linux32.deb`, `/cb/linux64.rpm`, `/cb/win64.exe`, `/cb/win32.exe`, `/cb/mac64.sh`...

```text
cpsetup/
├── cb/                 # Code::Blocks + g++ + gdb + cấu hình C++17
│   ├── auto            # Auto installer cho Linux (deb/rpm/tar.gz) & macOS (Intel/ARM)
│   ├── auto.bat        # Auto installer cho Windows (32/64-bit)
│   ├── mac64.sh        # Installer cho macOS Intel (x86_64)
│   ├── macarm64.sh     # Installer cho macOS Apple Silicon (arm64)
│   ├── linux64.deb     # Gói build local (gitignored, đưa lên GitHub Releases)
│   ├── linux32.deb     # (cùng với linux64/32.rpm, linux64/32.tar.gz)
│   └── src/
│       ├── common/     # Script & template dùng chung (cb, cpsetup-cb-config, cpsetup-cb-check)
│       ├── linux-deb/  # Build ./cb/linux64.deb & ./cb/linux32.deb
│       ├── linux-rpm/  # Build ./cb/linux64.rpm & ./cb/linux32.rpm
│       └── linux-targz/# Build ./cb/linux64.tar.gz & ./cb/linux32.tar.gz
├── cpp/                # Chỉ toolchain g++ / gdb (C++17), không IDE
├── vs/                 # VS Code + toolchain C++17 (dự kiến)
├── rs/                 # Rust CP IDE (định hướng phát triển sau)
├── LICENSE             # MIT License (cho mã nguồn & cấu hình tự viết)
└── README.md
```

## Test nhánh `/cb` trên Ubuntu (Local)

Khi chưa gắn tên miền `cpsetup.is-a.dev`, bạn có thể build và test trực tiếp trên máy Ubuntu 64-bit hiện tại:

### 1. Build gói cho các distro Linux
```bash
bash cb/src/linux-deb/build-deb.sh all      # -> ./cb/linux64.deb, ./cb/linux32.deb
bash cb/src/linux-targz/build-targz.sh all  # -> ./cb/linux64.tar.gz, ./cb/linux32.tar.gz
bash cb/src/linux-rpm/build-rpm.sh all      # -> ./cb/linux64.rpm, ./cb/linux32.rpm (cần rpmbuild)
```

### 2. Chạy thử `cb/auto` ở chế độ dry-run (không đụng hệ thống)
```bash
bash cb/auto --local --dry-run
```

### 3. Cài đặt thực tế trên Ubuntu local (lệnh gộp: update -> clear -> install chỉ hiện log bộ cài)
```bash
bash cb/auto --local
```
Hoặc chạy trực tiếp một dòng với file `.deb`:
```bash
sudo apt-get update && clear && sudo apt-get install -y --reinstall -qq ./cb/linux64.deb >/dev/null && cpsetup-cb-config && cpsetup-cb-check
```

Sau khi cài xong, gõ `cb` trong terminal để mở Code::Blocks tách biệt hoàn toàn khỏi terminal (tắt terminal không làm tắt Code::Blocks).

### 4. Kiểm chứng sau cài đặt
```bash
cpsetup-cb-check
```
Nếu cần tạo lại cấu hình Code::Blocks chuẩn `-std=c++17 -O2 -Wall -Wextra` tại `~/.config/codeblocks/default.conf`:
```bash
cpsetup-cb-config
```

## Định hướng khi đẩy lên GitHub & `cpsetup.is-a.dev`
- File nặng (`.deb`, `.exe`, `.rpm`, `.tar.gz`) upload lên **GitHub Releases**, không commit vào Git.
- Cấu hình routing tại `cpsetup.is-a.dev/<nhom>/<osbase><bit>.<ext>` trỏ thẳng tới asset tương ứng trên GitHub Releases.
