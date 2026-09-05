# ============================================================================
# LINTOR GCS custom build overlay (联涛智控)
# Consumed by the root CMakeLists.txt when this directory ("custom" by default)
# exists at the source root. Branding variables live in cmake/CustomOverrides.cmake;
# this file wires up the custom plugin and the resource overrides.
# ============================================================================

message(STATUS "QGC: Adding Brand (custom overlay) plugin")

# ============================================================================
# Custom Android Package Template
# ============================================================================
# The custom android/ directory is merged over the stock android/ directory, so
# only files that are actually replaced (launcher icons) need to be present.

if(ANDROID)
    set(CUSTOM_ANDROID_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android")
    if(IS_DIRECTORY "${CUSTOM_ANDROID_DIR}")
        file(GLOB_RECURSE CUSTOM_ANDROID_FILES
            CONFIGURE_DEPENDS
            LIST_DIRECTORIES FALSE
            "${CUSTOM_ANDROID_DIR}/*"
        )
        if(CUSTOM_ANDROID_FILES)
            message(STATUS "QGC: Custom Android package template found. Overlaying custom files...")
            set(DEFAULT_ANDROID_DIR "${CMAKE_SOURCE_DIR}/android")
            set(FINAL_ANDROID_DIR "${CMAKE_BINARY_DIR}/${QGC_CUSTOM_DIR}/android")
            file(GLOB_RECURSE DEFAULT_ANDROID_FILES
                CONFIGURE_DEPENDS
                LIST_DIRECTORIES FALSE
                "${DEFAULT_ANDROID_DIR}/*"
            )

            # Recreate the merge so removed source files cannot remain stale.
            file(REMOVE_RECURSE "${FINAL_ANDROID_DIR}")
            file(COPY "${DEFAULT_ANDROID_DIR}/" DESTINATION "${FINAL_ANDROID_DIR}")
            file(COPY "${CUSTOM_ANDROID_DIR}/" DESTINATION "${FINAL_ANDROID_DIR}")

            set(QGC_ANDROID_PACKAGE_SOURCE_DIR "${FINAL_ANDROID_DIR}")
            set(QGC_ANDROID_PACKAGE_SOURCE_DIR "${FINAL_ANDROID_DIR}" PARENT_SCOPE)
            message(STATUS "QGC: Android package template path will be set to: ${QGC_ANDROID_PACKAGE_SOURCE_DIR}")
        else()
            message(STATUS "QGC: Custom Android package template empty. Using default.")
        endif()
    else()
        message(STATUS "QGC: No custom Android package template found. Using default.")
    endif()
endif()

# ============================================================================
# Brand Resource Overrides (routed through BrandPlugin's URL interceptor)
# ============================================================================
# The interceptor maps qrc:/<path> to qrc:/Custom<path> when that resource
# exists, so each file must be registered with a QT_RESOURCE_ALIAS that exactly
# matches the stock resource path.

set(BRAND_LOGO_RESOURCES
    "${CMAKE_CURRENT_SOURCE_DIR}/res/images/LintorLogoFull.svg"
    "${CMAKE_CURRENT_SOURCE_DIR}/res/images/LintorLogoWhite.svg"
)
set_source_files_properties("${CMAKE_CURRENT_SOURCE_DIR}/res/images/LintorLogoFull.svg"
    PROPERTIES QT_RESOURCE_ALIAS "QGCLogoFull.svg"
)
set_source_files_properties("${CMAKE_CURRENT_SOURCE_DIR}/res/images/LintorLogoWhite.svg"
    PROPERTIES QT_RESOURCE_ALIAS "QGCLogoWhite.svg"
)
qt_add_resources(${CMAKE_PROJECT_NAME} brand_logo_overrides
    PREFIX "/Custom/res"
    FILES ${BRAND_LOGO_RESOURCES}
)

# Help page QML override: replaces the stock QGC support links with the vendor
# support channels.
set_source_files_properties("${CMAKE_CURRENT_SOURCE_DIR}/src/HelpSettings.qml"
    PROPERTIES QT_RESOURCE_ALIAS "QGroundControl/AppSettings/HelpSettings.qml"
)
qt_add_resources(${CMAKE_PROJECT_NAME} brand_qml_overrides
    PREFIX "/Custom/qml"
    FILES "${CMAKE_CURRENT_SOURCE_DIR}/src/HelpSettings.qml"
)

# ============================================================================
# Direct Resource Overrides
# ============================================================================
# The window icon is loaded straight from C++ (":/res/qgroundcontrol.ico" in
# QGCApplication.cc) and therefore bypasses the URL interceptor. Registering a
# resource at the same path shadows the stock one.

set_source_files_properties("${CMAKE_CURRENT_SOURCE_DIR}/res/icons/lintor.ico"
    PROPERTIES QT_RESOURCE_ALIAS "qgroundcontrol.ico"
)
qt_add_resources(${CMAKE_PROJECT_NAME} brand_direct_overrides
    PREFIX "/res"
    FILES "${CMAKE_CURRENT_SOURCE_DIR}/res/icons/lintor.ico"
)

# ============================================================================
# Custom Plugin Sources
# ============================================================================
# src/CMakeLists.txt compiles CUSTOM_SOURCES into the main app target when
# QGC_CUSTOM_BUILD is on and defines CUSTOMHEADER/CUSTOMCLASS so
# QGCCorePlugin::instance() resolves to BrandPlugin.

set(CUSTOM_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/src/BrandPlugin.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/src/BrandPlugin.h
    PARENT_SCOPE
)

set(CUSTOM_INCLUDE_DIRECTORIES
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    PARENT_SCOPE
)

set(CUSTOM_DEFINITIONS
    QGC_CUSTOM_BUILD
    CUSTOMHEADER="BrandPlugin.h"
    CUSTOMCLASS=BrandPlugin
    PARENT_SCOPE
)

set(CUSTOM_QT_COMPONENTS
    Core
    PARENT_SCOPE
)
