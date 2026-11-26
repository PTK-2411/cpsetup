# CPSetup (`cpsetup.is-a.dev`)

Bộ cài đặt chuẩn hóa môi trường lập trình thi đấu **C++17** (`-std=c++17 -O2`) cho học sinh luyện thi lập trình thi đấu trên Windows, Linux và macOS.

## Quy ước đường dẫn & tên gói
Mỗi nhánh sử dụng cấu trúc `/<mã ide>/<osbase><bit>.<đuôi>` và `/<mã ide>/auto`:
- Ví dụ: `/cb/linux64.deb`, `/cb/linux32.deb`, `/cb/linux64.rpm`, `/cb/win64.exe`, `/cb/win32.exe`, `/cb/mac64.sh`, `/cb/macarm64.sh`...

```text
cpsetup/
├── cb/                 # Code::Blocks + g++ + gdb + cấu hình C++17
│   ├── auto            # Auto installer cho Linux (deb/rpm/tar.gz) & macOS (Intel/ARM)
│   ├── auto.bat        # Auto installer cho Windows (32/64-bit)
│   ├── mac64.sh        # Installer cho macOS Intel (x86_64)
│   ├── macarm64.sh     # Installer cho macOS Apple Silicon (arm64)
│   └── src/
│       ├── common/     # Script & template dùng chung (cb, cpsetup-cb-config, cpsetup-cb-check)
│       ├── linux-deb/  # Build ./cb/linux64.deb & ./cb/linux32.deb
│       ├── linux-rpm/  # Build ./cb/linux64.rpm & ./cb/linux32.rpm
│       ├── linux-targz/# Build ./cb/linux64.tar.gz & ./cb/linux32.tar.gz
│       └── win/        # Script tải sẵn bộ cài Windows offline
├── cpp/                # Chỉ toolchain g++ / gdb (C++17), không IDE
├── vs/                 # VS Code + toolchain C++17 (dự kiến)
├── rs/                 # Rust CP IDE (định hướng phát triển sau)
├── LICENSE             # MIT License (cho mã nguồn & cấu hình tự viết)
└── README.md
```

## Hướng dẫn cài đặt theo hệ điều hành (Nhánh `/cb` — Code::Blocks + C++17)

### 1. Linux (Ubuntu / Debian, Fedora / RHEL / openSUSE, Arch / Manjaro)
Chạy lệnh tự nhận diện distro và kiến trúc (`32`/`64`-bit):
```bash
curl -fsSL https://cpsetup.is-a.dev/cb/auto | bash
```
*(Nếu chạy trực tiếp từ thư mục repo đã clone về máy: `bash cb/auto --local`)*

Sau khi cài xong:
- Gõ `cb` trong terminal để mở Code::Blocks tách biệt khỏi terminal (tắt terminal không làm tắt IDE), hoặc mở từ menu ứng dụng.
- Gõ `cpsetup-cb-check` để kiểm tra `g++`, `gdb`, `codeblocks` và biên dịch thử C++17.
- Gõ `cpsetup-cb-config` để kiểm tra và tự sửa `~/.config/codeblocks/default.conf` về chuẩn `-std=c++17 -O2 -Wall -Wextra`.

### 2. macOS (Intel `x86_64` & Apple Silicon `arm64`)
Yêu cầu đã cài [Homebrew](https://brew.sh). Chạy lệnh tự nhận diện máy Intel hay Apple Silicon:
```bash
curl -fsSL https://cpsetup.is-a.dev/cb/auto | bash
```
Hoặc chạy trực tiếp theo từng dòng máy:
- **Intel (`x86_64`)**: `curl -fsSL https://cpsetup.is-a.dev/cb/mac64.sh | bash`
- **Apple Silicon (`arm64`)**: `curl -fsSL https://cpsetup.is-a.dev/cb/macarm64.sh | bash`

> **Lưu ý:** Trên macOS, `g++` mặc định là Apple Clang. Bộ cài sẽ cài GNU GCC qua Homebrew (`g++-14` / `g++-15`) để tương thích chuẩn thi đấu.

### 3. Windows (32-bit & 64-bit)
Tải và chạy `cb/auto.bat` trong Command Prompt (`cmd`):
```bat
curl -fSL https://cpsetup.is-a.dev/cb/auto.bat -o cpsetup-cb.bat && cpsetup-cb.bat
```
Script sẽ tự nhận diện `win32` hoặc `win64`, hỗ trợ tải resume (`-C -`) khi mạng chập chờn và kiểm tra lại `g++`, `gdb` sau khi cài đặt.

## Định hướng khi đẩy lên GitHub & `cpsetup.is-a.dev`
- File nặng (`.deb`, `.exe`, `.rpm`, `.tar.gz`) upload lên **GitHub Releases**, không commit vào Git.
- Cấu hình routing tại `cpsetup.is-a.dev/<nhom>/<osbase><bit>.<ext>` trỏ thẳng tới asset tương ứng trên GitHub Releases.
