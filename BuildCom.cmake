# Buildcom

include(ExternalProject)

message(STATUS "COM will be compiled from source.")

# Directory variables
set(COM_SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/com-main")
set(COM_BUILD_DIR "${CMAKE_BINARY_DIR}/com-build")
set(COM_DIST_DIR "${COM_BUILD_DIR}/dist")

set(COM_CMAKE_ARGS)
list(APPEND COM_CMAKE_ARGS "-DCOM_DEVELOPER=on")
list(APPEND COM_CMAKE_ARGS "-DUSE_PREBUILT=off")
list(APPEND COM_CMAKE_ARGS "-DSTRIP_DEBUGINFO=on")
list(APPEND COM_CMAKE_ARGS "-DCBA_PACKAGING=on")
list(APPEND COM_CMAKE_ARGS "-DCOM_DEPS_DIR=${COM_DEPS_DIR}")
list(APPEND COM_CMAKE_ARGS "-DCOM_SA_DIR=${COM_SA_DIR}")
list(APPEND COM_CMAKE_ARGS "-DCOMSA_RPM_FILENAME=${COMSA_RPM_FILENAME}")
list(APPEND COM_CMAKE_ARGS "-DCOM_REENCRYPTOR_RPM_FILENAME=${COM_REENCRYPTOR_RPM_FILENAME}")
list(APPEND COM_CMAKE_ARGS "-DVSFTPD_DIST_DIR=${VSFTPD_DIST_DIR}")
list(APPEND COM_CMAKE_ARGS "-DCOM_VSFTPD_DAEMON_RPM_FILENAME=${COM_VSFTPD_DAEMON_RPM_FILENAME}")
list(APPEND COM_CMAKE_ARGS "-DCOM_VSFTPD_INSTALL_PREFIX=${COM_VSFTPD_INSTALL_PREFIX}")
list(APPEND COM_CMAKE_ARGS "-DPT=${PT}")
list(APPEND COM_CMAKE_ARGS "-DVSFTPD=${VSFTPD}")
list(APPEND COM_CMAKE_ARGS "-DCOM_VERSION=${COM_VERSION}-${COM_RELEASE_VERSION}")
list(APPEND COM_CMAKE_ARGS "-DUT=on")
list(APPEND COM_CMAKE_ARGS "-DVALGRIND=${VALGRIND}")

# Keep COM as it is, and be able to build it without comsa
ExternalProject_Add(com
    PREFIX ${CMAKE_BINARY_DIR}
    SOURCE_DIR ${COM_SRC_DIR}
    BINARY_DIR ${COM_BUILD_DIR}
    CMAKE_ARGS ${COM_CMAKE_ARGS}
    DEPENDS comsa
    DEPENDS comvsftpd
    BUILD_COMMAND $(MAKE)
    INSTALL_COMMAND $(MAKE) install DESTDIR=com_install
)

ExternalProject_Add_Step(com release
    DEPENDEES install
    WORKING_DIRECTORY ${COM_BUILD_DIR}
    COMMAND $(MAKE) release
)

ExternalProject_Add_Step(com build-ft
    DEPENDEES install
    WORKING_DIRECTORY ${COM_BUILD_DIR}
    COMMAND $(MAKE) build-ft
)

add_custom_command(
    TARGET com
    DEPENDS release
    WORKING_DIRECTORY ${COM_DIST_DIR}
    COMMAND cp [Cc][Oo][Mm]*.sdp ${DIST_DIR}/
    COMMAND cp com-*src*.tar.gz ${DIST_DIR}/
    COMMAND cp com-*api*.tar.gz ${DIST_DIR}/
    COMMAND cp com-*spi*.tar.gz ${DIST_DIR}/
    COMMAND cp com-*model*.tar.gz ${DIST_DIR}/
    COMMAND cp com-*yocto*.tar.gz ${DIST_DIR}/
    COMMAND cp com*deployment*.tar.gz ${DIST_DIR}/
    COMMAND cp com-*unittest*.tar.gz ${DIST_DIR}/
    COMMAND cp IDENTITY ${DIST_DIR}/
)
