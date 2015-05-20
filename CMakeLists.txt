cmake_minimum_required (VERSION 2.8.3)

project ("Xournal++" LANGUAGES CXX C)
set (PROJECT_VERSION "1.0.1")
set (PROJECT_PACKAGE "xournalpp")

set (PROJECT_STRING "${PROJECT_NAME} ${PROJECT_VERSION}")
set (PROJECT_URL "https://github.com/xournalpp/xournalpp")

include (FindPkgConfig)
set (CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")

# Git repo info
include (GitRepo)

## Libraries ##

# Boost (we start with boost, because if it'll be built it needs some linker tags)

option (BUILD_BOOST "Build boost libraries into Xournal++" OFF)
if (BUILD_BOOST)

  include (ExternalProject)
  ExternalProject_Add (boost
    SVN_REPOSITORY http://svn.boost.org/svn/boost/branches/release

    CONFIGURE_COMMAND cd "${CMAKE_BINARY_DIR}/boost-prefix/src/boost" && ./bootstrap.sh
      --prefix="${CMAKE_BINARY_DIR}/boost-prefix"

    BUILD_COMMAND cd "${CMAKE_BINARY_DIR}/boost-prefix/src/boost" && ./b2
      --with-filesystem --with-iostreams --with-locale --with-thread --with-system
      "--prefix=${CMAKE_BINARY_DIR}/boost-prefix"
      "--build-dir=${CMAKE_BINARY_DIR}/boost-prefix/src/boost-build"
      "--stagedir=${CMAKE_BINARY_DIR}/boost-prefix"
      threading=multi link=static

    INSTALL_COMMAND echo "Install is not necessary"
  )

  # ICU – needed for boost::locale
  find_package (ICU COMPONENTS uc i18n)

  link_directories ("${CMAKE_BINARY_DIR}/boost-prefix/lib/")
  set (Boost_LIBRARIES
    boost_filesystem
    boost_locale
    boost_iostreams
    boost_thread
    boost_system
    ${ICU_LIBRARIES}
  )
  set (xournalpp_INCLUDE_DIRS ${xournalpp_INCLUDE_DIRS} "${CMAKE_BINARY_DIR}/boost-prefix/src/boost/boost")

else (BUILD_BOOST)

  set (Boost_USE_MULTITHREADED ON)
  find_package (Boost 1.54 REQUIRED COMPONENTS system filesystem locale iostreams thread)
  set (xournalpp_INCLUDE_DIRS ${xournalpp_INCLUDE_DIRS} ${Boost_INCLUDE_DIRS})

endif (BUILD_BOOST)

set (xournalpp_LDFLAGS ${xournalpp_LDFLAGS} ${Boost_LIBRARIES})

# GTK+/Gnome

pkg_check_modules (Gnome REQUIRED "gtk+-2.0 >= 2.18.3" "libglade-2.0 >= 2.6.4" "glib-2.0 >= 2.32.0" "gthread-2.0 >= 2.4.0")
pkg_check_modules (Glibmm REQUIRED "glibmm-2.4 >= 2.24.0")

# Other packages

# librsvg-2.0 is not really needed by Xournal++, but if you don't have it, it crashes while loading the SVG icons
# We also are compiling with libpoppler so we require a number of extra packages
pkg_check_modules (OtherLibs REQUIRED "librsvg-2.0 >= 2.14.0" fontconfig lcms)

find_package (ZLIB REQUIRED)    # zlib
find_package (Threads REQUIRED) # pthreads

set (xournalpp_LDFLAGS ${xournalpp_LDFLAGS}
  ${Gnome_LDFLAGS}
  ${Glibmm_LDFLAGS}
  ${OtherLibs_LDFLAGS}
  ${ZLIB_LIBRARIES}
  ${CMAKE_THREAD_LIBS_INIT}
)
set (xournalpp_INCLUDE_DIRS ${xournalpp_INCLUDE_DIRS}
  ${Gnome_INCLUDE_DIRS}
  ${Glibmm_INCLUDE_DIRS}
  ${OtherLibs_INCLUDE_DIRS}
  ${ZLIB_INCLUDE_DIRS}
)

# JPEG

option (ENABLE_LIBOPENJPEG "Use libopenjpeg instead of builtin jpeg2000 decoder" ON)
if (ENABLE_LIBOPENJPEG)
  find_package (OpenJPEG REQUIRED)
  set (xournalpp_LDFLAGS ${xournalpp_LDFLAGS} ${OPENJPEG_LIBRARIES} -lopenjpeg) # -lopenjpeg added as fallback
  set (xournalpp_INCLUDE_DIRS ${xournalpp_INCLUDE_DIRS} ${OPENJPEG_INCLUDE_DIRS})
endif (ENABLE_LIBOPENJPEG)

find_package (JPEG)
set (xournalpp_LDFLAGS ${xournalpp_LDFLAGS} ${JPEG_LIBRARIES})
set (xournalpp_INCLUDE_DIRS ${xournalpp_INCLUDE_DIRS} ${JPEG_INCLUDE_DIRS})
if (NOT JPEG_FOUND)
  message (WARNING "JPEG loader will not be built (JPEG header file not found)")
endif (NOT JPEG_FOUND)

set (PACKAGE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/share")

## Additional features ##

# CppUnit
option (ENABLE_CPPUNIT "Build CppUnit test instead of xournalpp application" OFF)
if (ENABLE_CPPUNIT)
  pkg_check_modules (CppUnit REQUIRED "cppunit >= 1.13-0")
endif (ENABLE_CPPUNIT)

# Overlay scrollbar
option (ENABLE_OS "Overlay Scrollbar support" OFF)
if (ENABLE_OS)
  pkg_check_modules (os REQUIRED "overlay-scrollbar-0.1 >= 0.1.12")
  set (xournalpp_LDFLAGS ${xournalpp_LDFLAGS} ${os_LDFLAGS})
  set (xournalpp_INCLUDE_DIRS ${xournalpp_INCLUDE_DIRS} ${os_INCLUDE_DIRS})
endif (ENABLE_OS)

# Mathtex
option (ENABLE_MATHTEX "Mathtex support" OFF)

# Unstable features

option (UNSTABLE_LAYERS_SIDEBAR "Layers sidebar (unstable)" OFF)

configure_file (
  src/config-features.h.in
  src/config-features.h
  ESCAPE_QUOTES @ONLY
)

## I18n ##
add_subdirectory (po)

## Configuration headers ##

# Development options
option (DEV_MEMORY_CHECKING "Memory checking" ON)
option (DEV_MEMORY_LEAK_CHECKING "Memory leak checking" ON)
option (DEV_CALL_LOG "Call log" OFF)

# Debug options
option (DEBUG_INPUT "Input debugging, e.g. eraser events etc" OFF)
option (DEBUG_RECOGNIZER "Shape recognizer debug: output score etc" OFF)
option (DEBUG_SHEDULER "Scheduler debug: show jobs etc" OFF)
option (DEBUG_SHOW_ELEMENT_BOUNDS "Draw a surrounding border to all elements" OFF)
option (DEBUG_SHOW_REPAINT_BOUNDS "Draw a border around all repaint rects" OFF)
option (DEBUG_SHOW_PAINT_BOUNDS "Draw a border around all painted rects" OFF)
mark_as_advanced (FORCE
  DEBUG_INPUT DEBUG_RECOGNIZER DEBUG_SHEDULER DEBUG_SHOW_ELEMENT_BOUNDS DEBUG_SHOW_REPAINT_BOUNDS DEBUG_SHOW_PAINT_BOUNDS
)

# Advanced development config
set (DEV_CONFIG_DIR ".xournalpp" CACHE STRING "Xournal++ config dir, relative to user's home dir")
set (DEV_TOOLBAR_CONFIG "toolbar.ini" CACHE STRING "Toolbar config file name")
set (DEV_SETTINGS_XML_FILE "settings.xml" CACHE STRING "Settings file name")
set (DEV_PRINT_CONFIG_FILE "print-config.ini" CACHE STRING "Print config file name")
set (DEV_METADATA_FILE "metadata.ini" CACHE STRING "Metadata file name")
set (DEV_METADATA_MAX_ITEMS 50 CACHE STRING "Maximal amount of metadata elements")
mark_as_advanced (FORCE
  DEV_CONFIG_DIR DEV_TOOLBAR_CONFIG DEV_SETTINGS_XML_FILE DEV_PRINT_CONFIG_FILE DEV_METADATA_FILE DEV_METADATA_MAX_ITEMS
)

configure_file (
  src/config.h.in
  src/config.h
  ESCAPE_QUOTES @ONLY
)

configure_file (
  src/config-debug.h.in
  src/config-debug.h
  ESCAPE_QUOTES @ONLY
)

configure_file (
  src/config-dev.h.in
  src/config-dev.h
  ESCAPE_QUOTES @ONLY
)

## C++11 ##

include(CheckCXXCompilerFlag)
CHECK_CXX_COMPILER_FLAG("-std=c++11" COMPILER_SUPPORTS_CXX11)
CHECK_CXX_COMPILER_FLAG("-std=c++0x" COMPILER_SUPPORTS_CXX0X)
if(COMPILER_SUPPORTS_CXX11)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
elseif(COMPILER_SUPPORTS_CXX0X)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++0x")
else()
        message(STATUS "The compiler ${CMAKE_CXX_COMPILER} has no C++11 support. Please use a different C++ compiler.")
endif()

## Source building ##
add_subdirectory (src)

## Final targets and installing ##

# Install resources
install (DIRECTORY ui
  DESTINATION share/xournalpp
  COMPONENT xournalpp
)

# Uninstall target
configure_file (
  cmake/cmake_uninstall.cmake.in
  cmake/cmake_uninstall.cmake
  IMMEDIATE @ONLY)

add_custom_target (uninstall
  COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake/cmake_uninstall.cmake
  DEPENDS desktop-uninstall

  COMMENT "Uninstall entire xournalpp"
)

# Install desktop target
configure_file (desktop/desktop_install.sh.in desktop/desktop_install.sh @ONLY)

add_custom_target (desktop-install-xournalpp
  COMMAND desktop/desktop_install.sh install

  COMMENT "Install xournalpp desktop files"
)

add_custom_target (desktop-install
  DEPENDS desktop-install-xournalpp desktop-install-thumbnailer
)

# Uninstall desktop target
add_custom_target (desktop-uninstall-xournalpp
  COMMAND desktop/desktop_install.sh uninstall

  COMMENT "Uninstall xournalpp desktop files"
)

add_custom_target (desktop-uninstall
  DEPENDS desktop-uninstall-xournalpp desktop-uninstall-thumbnailer
)

message ("

Configuration:
	Compiler:                  ${CMAKE_CXX_COMPILER}
	Overlay Scrollbar enabled: ${ENABLE_OS}
	Mathtex enabled:           ${ENABLE_MATHTEX}
	CppUnit enabled:           ${ENABLE_CPPUNIT}

Unstable features:
	Layers sidebar:            ${UNSTABLE_LAYERS_SIDEBAR}
")
