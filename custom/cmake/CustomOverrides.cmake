# ============================================================================
# Custom Build Configuration Overrides — LINTOR GCS branding (联涛智控)
# Loaded by the root CMakeLists.txt before project() when a "custom" overlay
# directory exists at the source root. Use CACHE ... FORCE so the values win
# over the defaults from cmake/CustomOptions.cmake regardless of cache state.
# ============================================================================

# ----------------------------------------------------------------------------
# Application Branding
# ----------------------------------------------------------------------------
# QGC_APP_NAME becomes the CMake project name, the executable name, the window
# title, the QSettings file name and the installer file name. Keep it ASCII and
# free of spaces.
set(QGC_APP_NAME "LINTOR-GCS" CACHE STRING "Application name" FORCE)
set(QGC_APP_DESCRIPTION "LINTOR Ground Control Station" CACHE STRING "Application description" FORCE)
set(QGC_APP_COPYRIGHT "Copyright (c) 2026 LINTOR. All rights reserved." CACHE STRING "Copyright notice" FORCE)
set(QGC_ORG_NAME "LINTOR" CACHE STRING "Organization name" FORCE)
set(QGC_ORG_DOMAIN "lintor.cn" CACHE STRING "Organization domain" FORCE)

# Package identifier: macOS bundle id, Linux desktop file name and the default
# Android application id. Must be a reverse-domain string.
set(QGC_PACKAGE_NAME "cn.lintor.gcs" CACHE STRING "Package identifier" FORCE)
# QGC_ANDROID_PACKAGE_NAME is initialized from QGC_PACKAGE_NAME before this file
# is loaded, so it must be overridden explicitly.
set(QGC_ANDROID_PACKAGE_NAME "cn.lintor.gcs" CACHE STRING "Android package identifier" FORCE)

# ----------------------------------------------------------------------------
# Platform Icons and Installer Graphics
# ----------------------------------------------------------------------------
# Each override only applies when the replacement file exists, so platforms you
# have not rebranded yet keep the stock QGC assets.

# macOS application bundle icon (.icns)
if(EXISTS "${CMAKE_SOURCE_DIR}/${QGC_CUSTOM_DIR}/res/icons/lintor.icns")
    set(QGC_MACOS_ICON_PATH "${CMAKE_SOURCE_DIR}/${QGC_CUSTOM_DIR}/res/icons/lintor.icns" CACHE FILEPATH "macOS Icon Path" FORCE)
endif()

# Linux AppImage icons (256x256 PNG + scalable SVG)
if(EXISTS "${CMAKE_SOURCE_DIR}/${QGC_CUSTOM_DIR}/res/icons/lintor-256.png")
    set(QGC_APPIMAGE_ICON_256_PATH "${CMAKE_SOURCE_DIR}/${QGC_CUSTOM_DIR}/res/icons/lintor-256.png" CACHE FILEPATH "AppImage 256 Icon Path" FORCE)
endif()
if(EXISTS "${CMAKE_SOURCE_DIR}/${QGC_CUSTOM_DIR}/res/icons/LintorAppIcon.svg")
    set(QGC_APPIMAGE_ICON_SCALABLE_PATH "${CMAKE_SOURCE_DIR}/${QGC_CUSTOM_DIR}/res/icons/LintorAppIcon.svg" CACHE FILEPATH "AppImage Icon SVG Path" FORCE)
endif()

# Windows application icon (.ico, also used by the NSIS installer)
if(EXISTS "${CMAKE_SOURCE_DIR}/${QGC_CUSTOM_DIR}/res/icons/lintor.ico")
    set(QGC_WINDOWS_ICON_PATH "${CMAKE_SOURCE_DIR}/${QGC_CUSTOM_DIR}/res/icons/lintor.ico" CACHE FILEPATH "Windows Icon Path" FORCE)
endif()

# Windows NSIS installer header image (150x57 BMP)
if(EXISTS "${CMAKE_SOURCE_DIR}/${QGC_CUSTOM_DIR}/deploy/windows/installheader.bmp")
    set(QGC_WINDOWS_INSTALL_HEADER_PATH "${CMAKE_SOURCE_DIR}/${QGC_CUSTOM_DIR}/deploy/windows/installheader.bmp" CACHE FILEPATH "Windows Install Header Path" FORCE)
endif()
