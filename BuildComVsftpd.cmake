#
# COM VSFTP CMake module
#
include(ExternalProject)
set(COM_VSFTPD_INSTALL_PREFIX "/opt/com-vsftpd/")
find_program(RPMBUILD_EXECUTABLE rpmbuild)
message(STATUS "COM-VSFTPD will be compiled from source.")

# Directory variables
set(COM_VSFTPD_ROOT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/com-vsftpd")
set(COM_VSFTPD_BUILD_DIR "${CMAKE_BINARY_DIR}/com-vsftpd-build")
set(COM_VSFTPD_INSTALL_DIR "${COM_VSFTPD_BUILD_DIR}/installation")
set(COM_VSFTPD_TEMPLATES "${COM_VSFTPD_ROOT_DIR}/templates/")
set(COM_VSFTPD_RPM_TOP "${COM_VSFTPD_BUILD_DIR}/rpmtop")
set(COM_VSFTPD_BUILD_ROOT "${COM_VSFTPD_BUILD_DIR}/build_root")
set(COM_VSFTPD_TMP_DIR "${COM_VSFTPD_BUILD_DIR}/tmp")

set(COM_VSFTPD_DAEMON "${COM_VSFTPD_BUILD_DIR}/installation/${COM_VSFTPD_INSTALL_PREFIX}/bin/com-vsftpd")
set(COM_VSFTPD_CONFIG "${COM_VSFTPD_BUILD_DIR}/installation/${COM_VSFTPD_INSTALL_PREFIX}/etc/com-vsftpd.conf")
set(COM_VSFTPD_PAM "${COM_VSFTPD_BUILD_DIR}/installation/${COM_VSFTPD_INSTALL_PREFIX}/etc/pam.d/com-vsftpd")

configure_file(${COM_VSFTPD_ROOT_DIR}/script/start_stop/com-vsftpd.sh.in ${COM_VSFTPD_TMP_DIR}/com-vsftpd.sh @ONLY)
set(COM_VSFTPD_START "${COM_VSFTPD_TMP_DIR}/com-vsftpd.sh")

# Names of rpm
set(COM_VSFTPD_DAEMON_NAME  "com-vsftpd")
set(COM_VSFTPD_SRC_PRODUCT_NUMBER "cay901233")
set(COM_VSFTPD_DAEMON_RPM_FILENAME "${COM_VSFTPD_DAEMON_NAME}${PRODUCT_NUMBER}-${COM_VERSION}-${COM_RELEASE_VERSION}${RPM_RELEASE_TAG_SUFFIX}.${TARGET_ARCHITECTURE}.rpm")
set(COM_VSFTPD_SRC_TAR_FILENAME "${COM_VSFTPD_DAEMON_NAME}-${COM_VERSION}-${COM_RELEASE_VERSION}-src-${COM_VSFTPD_SRC_PRODUCT_NUMBER}.tar")

if (NOT DEFINED VSFTPD_DIST_DIR)
    set(VSFTPD_DIST_DIR "${CMAKE_BINARY_DIR}/com-vsftpd-build/dist")
endif()

if(NOT EXISTS ${VSFTPD_DIST_DIR})
    file(MAKE_DIRECTORY ${VSFTPD_DIST_DIR})
endif()

list(APPEND COM_VSFTPD_BUILDENV "VSFTPD_BUILDDIR=${COM_VSFTPD_BUILD_DIR}")
list(APPEND COM_VSFTPD_BUILDENV "VSFTPD_DESTDIR=${COM_VSFTPD_INSTALL_DIR}")
list(APPEND COM_VSFTPD_BUILDENV "COM_VSFTPD_INSTALL_PREFIX=${COM_VSFTPD_INSTALL_PREFIX}")
list(APPEND COM_VSFTPD_BUILDENV "COMVSFTPD_THUNK=${BUILDWITH_THUNK}")
list(APPEND COM_VSFTPD_RPMENV "COM_VSFTPD_DAEMON=${COM_VSFTPD_DAEMON}")
list(APPEND COM_VSFTPD_RPMENV "COM_VSFTPD_START=${COM_VSFTPD_START}")
list(APPEND COM_VSFTPD_RPMENV "COM_VSFTPD_CONFIG=${COM_VSFTPD_CONFIG}")
list(APPEND COM_VSFTPD_RPMENV "COM_VSFTPD_PAM=${COM_VSFTPD_PAM}")
list(APPEND COM_VSFTPD_RPMENV "COM_VSFTPD_INSTALL_PREFIX=${COM_VSFTPD_INSTALL_PREFIX}")

configure_file(${COM_VSFTPD_ROOT_DIR}/script/rpmspec/com-vsftpd.spec.in ${COM_VSFTPD_RPM_TOP}/com-vsftpd.spec @ONLY)
set(COM_VSFTPD_RPM_SPEC ${COM_VSFTPD_RPM_TOP}/com-vsftpd.spec)

# Build COM_VSFTPD
ExternalProject_Add(comvsftpd
        PREFIX ${COM_VSFTPD_BUILD_DIR}
        SOURCE_DIR "${COM_VSFTPD_ROOT_DIR}/src"
        BINARY_DIR "${COM_VSFTPD_ROOT_DIR}/src"
        CONFIGURE_COMMAND true
        BUILD_COMMAND env ${COM_VSFTPD_BUILDENV} $(MAKE)
        INSTALL_COMMAND env ${COM_VSFTPD_BUILDENV} $(MAKE) install_cba_build
)

# Create the rpm for vsftpd-deamon
add_custom_command(
        TARGET comvsftpd
        COMMENT "Building COM_VSFTPD RPM"
        DEPENDS install
        COMMAND ${COM_VSFTPD_RPMENV} ${RPMBUILD_EXECUTABLE} -bb
            --target ${TARGET_ARCHITECTURE}
            --buildroot=${COM_VSFTPD_BUILD_ROOT}/
            --define "_comvsftpdname ${COM_VSFTPD_DAEMON_NAME}${PRODUCT_NUMBER}"
            --define "_comvsftpdver ${COM_VERSION}"
            --define "_comvsftpdrel ${COM_RELEASE_VERSION}${RPM_RELEASE_TAG_SUFFIX}"
            --define "_topdir ${COM_VSFTPD_RPM_TOP}"
            ${COM_VSFTPD_RPM_SPEC}
        COMMAND cp ${COM_VSFTPD_RPM_TOP}/RPMS/x86_64/${COM_VSFTPD_DAEMON_RPM_FILENAME} ${VSFTPD_DIST_DIR}
)

# Create source package
add_custom_command(
        TARGET comvsftpd
        COMMENT "Create source package of COM_VSFTPD"
        DEPENDS ${COM_VSFTPD_ROOT_DIR}/list-patches
                ${COM_VSFTPD_ROOT_DIR}/README.build
                ${COM_VSFTPD_ROOT_DIR}/src
                ${COM_VSFTPD_ROOT_DIR}/script
        WORKING_DIRECTORY ${COM_VSFTPD_TMP_DIR}
        COMMAND tar -cf ${COM_VSFTPD_SRC_TAR_FILENAME} -C ${COM_VSFTPD_ROOT_DIR} list-patches README.build
        COMMAND tar --append --file=${COM_VSFTPD_SRC_TAR_FILENAME} -C ${COM_VSFTPD_ROOT_DIR} src script
        COMMAND gzip -f ${COM_VSFTPD_SRC_TAR_FILENAME}
)

# Copy files needd for COM to ${DIST_DIR}
add_custom_command(
        TARGET comvsftpd
        COMMENT "Copy related items needed by COM to ${DIST_DIR}"
        DEPENDS ${COM_VSFTPD_TMP_DIR}/${COM_VSFTPD_SRC_TAR_FILENAME}.gz
        COMMAND install -m 0644 ${COM_VSFTPD_TMP_DIR}/${COM_VSFTPD_SRC_TAR_FILENAME}.gz ${DIST_DIR}/
)
