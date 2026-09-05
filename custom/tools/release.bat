@echo off
REM ==================================================================
REM LINTOR-GCS one-click build + release script (x64)
REM Usage: custom\tools\release.bat [clean]
REM   (no args) incremental build + package, for daily releases
REM   clean     delete build\Windows then full reconfigure + build + package
REM Output: build\Windows\LINTOR-GCS-installer-AMD64.exe (+ .sha256)
REM ==================================================================
setlocal enabledelayedexpansion

REM ------------------------------------------------------------------
REM Machine-specific paths (only this block needs editing on a new PC)
REM ------------------------------------------------------------------
set "QGC_SOURCE=D:\qgc\qgroundcontrol"
set "QT_ROOT_DIR=D:\qgc\Qt\6.11.1\msvc2022_64"
set "CPM_SOURCE_CACHE=D:\qgc\cpm-cache"
set "VCVARS=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
set "PIP=C:\Users\tian_\AppData\Local\Packages\PythonSoftwareFoundation.Python.3.10_qbz5n2kfra8p0\LocalCache\local-packages\Python310"
set "NSIS_DIR=C:\Program Files (x86)\NSIS"
REM Parallel compile jobs. Each cl.exe with PCH eats ~1.5-2GB RAM; on 16GB
REM machines keep this at 6-8 or the compiler dies with C3859/C1076.
set "BUILD_JOBS=6"
set "CMAKE_BUILD_PARALLEL_LEVEL=%BUILD_JOBS%"

if not exist "%QT_ROOT_DIR%\bin\qmake.exe" (
    echo [ERROR] Qt not found: %QT_ROOT_DIR% - see custom\docs\ section 2
    exit /b 1
)

call "%VCVARS%" >nul
set "PATH=%PIP%\Scripts;%PIP%\site-packages\cmake\data\bin;%NSIS_DIR%;%PATH%"
cd /d "%QGC_SOURCE%"

if "%~1"=="clean" (
    echo [CLEAN] removing build\Windows ...
    rmdir /s /q build\Windows
)

echo.
echo [1/3] CMake configure (first run ~7 min, incremental ~1 min)...
cmake --preset Windows ^
    -DCPM_SOURCE_CACHE="%CPM_SOURCE_CACHE%" ^
    -DQGC_STABLE_BUILD=ON ^
    -DQGC_ENABLE_GST_VIDEOSTREAMING=OFF ^
    -DQGC_BUILD_TESTING=OFF ^
    -DQGC_ENABLE_WERROR=OFF ^
    || goto :fail

echo.
echo [2/3] Build (%BUILD_JOBS% jobs; incremental usually 1-5 min; large source changes 30 min+)...
cmake --build build\Windows || goto :fail

echo.
echo [3/3] Packaging NSIS installer (~3-8 min)...
cmake --build build\Windows --target qgc-package || goto :fail

echo.
echo ==================================================================
echo Release artifacts:
echo   %QGC_SOURCE%\build\Windows\LINTOR-GCS-installer-AMD64.exe
echo   %QGC_SOURCE%\build\Windows\LINTOR-GCS-installer-AMD64.exe.sha256
echo ==================================================================
exit /b 0

:fail
echo.
echo [FAILED] See log above. FAQ: custom\docs\ build guide, section 8.
exit /b 1
