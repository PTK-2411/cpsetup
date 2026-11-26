@echo off
setlocal enabledelayedexpansion

REM CPSetup - Code::Blocks + C++17 Auto Installer (Windows 32/64-bit)
REM Usage: cb\auto.bat

set "RELEASE_URL=https://github.com/PTK-2411/cpsetup/releases/latest/download"
if not "%CPSETUP_RELEASE_URL%"=="" set "RELEASE_URL=%CPSETUP_RELEASE_URL%"

set "ARCH=32"
if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" set "ARCH=64"
if /i "%PROCESSOR_ARCHITEW6432%"=="AMD64" set "ARCH=64"

set "PKG_NAME=win%ARCH%.exe"
set "ASSET_NAME=cb-%PKG_NAME%"
echo [CPSetup] Phat hien Windows %ARCH%-bit (/cb/%PKG_NAME%).

set "HAS_GPP=0"
where g++ >nul 2>nul && set "HAS_GPP=1"
set "HAS_CB=0"
if exist "C:\Program Files\CodeBlocks\codeblocks.exe" set "HAS_CB=1"
if exist "C:\Program Files (x86)\CodeBlocks\codeblocks.exe" set "HAS_CB=1"

if "%HAS_GPP%"=="1" if "%HAS_CB%"=="1" (
    echo [OK] Da co san g++ va Code::Blocks tren may.
    goto :verify
)

if exist "%~dp0%PKG_NAME%" (
    echo [CPSetup] Dang chay goi cai dat local: %~dp0%PKG_NAME%
    start /wait "" "%~dp0%PKG_NAME%"
    goto :verify
)

echo [CPSetup] Dang tai %RELEASE_URL%/%ASSET_NAME% (ho tro resume khi mang chap chon)...
set "CACHE_DIR=%LOCALAPPDATA%\CPSetup\cache"
if not exist "%CACHE_DIR%" mkdir "%CACHE_DIR%"
set "TMP_EXE=%CACHE_DIR%\%ASSET_NAME%"
curl -fSL -C - --retry 5 --retry-delay 2 "%RELEASE_URL%/%ASSET_NAME%" -o "%TMP_EXE%"
if errorlevel 1 (
    echo [CPSetup] Loi: Tai %ASSET_NAME% chua hoan tat. Chay lai cb\auto.bat de tai tiep phan con lai. >&2
    exit /b 1
)

echo [CPSetup] Dang cai dat %ASSET_NAME%...
start /wait "" "%TMP_EXE%"

:verify
where g++ >nul 2>nul && (
    echo [OK] Tim thay g++:
    g++ --version | findstr /n "^" | findstr "^1:"
) || (
    echo [WARN] Chua thay g++ trong PATH. Hay mo lai CMD hoac kiem tra bien moi truong PATH.
)

where gdb >nul 2>nul && (
    echo [OK] Tim thay gdb trong PATH.
) || (
    echo [INFO] Chua thay gdb trong PATH.
)

echo [CPSetup] Hoan tat.
endlocal
