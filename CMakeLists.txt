# Asima Hub: Asima OS's online companion. On any Linux (and later Windows) it shows what Asima OS
# does on the PC, downloads it and writes the USB stick; on Asima OS it also downloads updates and
# hands them to Asima Updater, shows the news and helps send a problem report. It ships as a Flatpak
# (packaging/) and is never part of the Asima OS image.
cmake_minimum_required(VERSION 3.24)
project(asimaos-hub VERSION 0.3.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.8 REQUIRED COMPONENTS Core Gui Quick QuickControls2 Svg DBus Network LinguistTools)
qt_standard_project_setup(REQUIRES 6.8 I18N_SOURCE_LANGUAGE en I18N_TRANSLATED_LANGUAGES bn hi ja)
set(QT_QML_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml)

# Asima UI, the design system the Hub shares with the Asima OS apps (QML module "Asima.Ui"). This
# repository carries a copy in ui/; where the Hub sits next to the OS (../asimaos/apps/ui), that one is used.
set(ASIMAOS_UI_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ui")
if(NOT EXISTS "${ASIMAOS_UI_DIR}/CMakeLists.txt")
    set(ASIMAOS_UI_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../asimaos/apps/ui")
endif()
add_subdirectory("${ASIMAOS_UI_DIR}" asimaos-ui)

# Where the app looks for releases (https://…/feed.json). Empty: the app says it has no release server.
set(ASIMAOS_HUB_FEED "" CACHE STRING "Address (https://) of the Asima Hub release feed")

# The feed's signature is checked with OpenSSL (Ed25519), which the Flatpak runtime has.
find_package(OpenSSL 3 REQUIRED COMPONENTS Crypto)

qt_add_executable(asimaos-hub
    src/main.cpp
    src/feedcheck.h
    src/feedcheck.cpp
    src/hubengine.h
    src/hubengine.cpp
    src/pccheck.h
    src/pccheck.cpp
    src/usbwriter.h
    src/usbwriter.cpp
)
target_compile_definitions(asimaos-hub PRIVATE
    ASIMAOS_HUB_FEED="${ASIMAOS_HUB_FEED}"
    ASIMAOS_HUB_VERSION="${PROJECT_VERSION}")

# The QML type registration (generated) includes the singletons' headers from src/.
target_include_directories(asimaos-hub PRIVATE src)

qt_add_qml_module(asimaos-hub
    URI AsimaHub
    VERSION 1.0
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml/AsimaHub
    QML_FILES
        Main.qml
        UpdatesPage.qml
        NewsPage.qml
        HelpPage.qml
        ReportPage.qml
        GetPage.qml
)

target_link_libraries(asimaos-hub PRIVATE
    Qt6::Gui Qt6::Quick Qt6::QuickControls2 Qt6::Network Qt6::DBus
    OpenSSL::Crypto
    asimaos_ui
    asimaos_uiplugin
)

# Translations: i18n/asimaos_<lang>.ts (the name Asima UI loads), built into the app (":/i18n").
# `cmake --build build --target update_translations` collects new strings.
qt_add_translations(TARGETS asimaos-hub TS_FILE_BASE asimaos TS_FILE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/i18n
                    RESOURCE_PREFIX /i18n)

include(GNUInstallDirs)
install(TARGETS asimaos-hub RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES io.github.asimaos.Hub.desktop DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)
install(FILES io.github.asimaos.Hub.metainfo.xml DESTINATION ${CMAKE_INSTALL_DATADIR}/metainfo)
install(FILES "${ASIMAOS_UI_DIR}/assets/apps/hub.svg"
        DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps RENAME io.github.asimaos.Hub.svg)
