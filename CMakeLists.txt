# Cmake file for the CBA/COM project.
# It includes both the com-main and the comsa subprojects.

# Minium required version of CMake
cmake_minimum_required (VERSION 2.8.5)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/com-main/cmake_modules)
include(utilities)
include(FindHostOs)
include(versions)

if(NOT DEFINED COM_DEPS_DIR)
  message(FATAL_ERROR "COM_DEPS_DIR should be defined!")
else()
  # Get the absolute path of the COM_DEPS_DIR. This variable must be a full path for cross compilation to work properly.
  get_filename_component(COM_DEPS_DIR "${COM_DEPS_DIR}" ABSOLUTE)
endif ()

if(NOT DEFINED TOOLS_DIR)
  set(TOOLS_DIR ${COM_DEPS_DIR}/tools)
endif ()

if(NOT DEFINED SYSROOT_DIR)
  set(SYSROOT_DIR ${COM_DEPS_DIR}/sysroot)
endif ()

if(NOT DEFINED PREBUILT_DIR)
  set(PREBUILT_DIR ${COM_DEPS_DIR}/pre-built)
endif ()

option(PT "Turn off PT by default" OFF)
option(VALGRIND "Turn off Valgrind by default" OFF)

set(DIST_DIR "${CMAKE_BINARY_DIR}/dist")
file(MAKE_DIRECTORY ${DIST_DIR})

project(CBA_COM)

set(VSFTPD ON) # Always building VSFTP in CBA-environment

if (NOT DEFINED TARGET_ARCHITECTURE)
   set(TARGET_ARCHITECTURE "x86_64")
endif()

if(NOT DEFINED COM_INSTALL_PREFIX)
  set(COM_INSTALL_PREFIX /opt/com)
endif ()

include(BuildComVsftpd.cmake)

include(BuildComSa.cmake)

include(BuildCom.cmake)

add_custom_target(clean-all
    rm -rf ${CMAKE_BINARY_DIR}/*
)
