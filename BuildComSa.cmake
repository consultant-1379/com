#
# COM SA CMake module
#

#include(utilities)
include(ExternalProject)
find_program(RPMBUILD_EXECUTABLE rpmbuild)

message(STATUS "'COM SA' will be compiled and installed from bundled source.")

if (NOT DEFINED TARGET_ARCHITECTURE)
    set(TARGET_ARCHITECTURE "x86_64")
endif()

set(COMSA_SRC_PRODUCT_NUMBER "cay901203")
set(COMSA_YOCTO_PRODUCT_NUMBER "cay901202")
set(COMSA_FILENAME "com-comsa${PRODUCT_NUMBER}-${COM_VERSION}-${COM_RELEASE_VERSION}${RPM_RELEASE_TAG_SUFFIX}.${TARGET_ARCHITECTURE}")
set(COMSA_RPM_FILENAME "${COMSA_FILENAME}.rpm")
set(COMSA_SRC_TAR_FILENAME "com-comsa-${COM_VERSION}-${COM_RELEASE_VERSION}-src-${COMSA_SRC_PRODUCT_NUMBER}.tar")
set(COMSA_YOCTO_TAR_FILENAME "com-comsa-${COM_VERSION}-${COM_RELEASE_VERSION}-yocto-${COMSA_YOCTO_PRODUCT_NUMBER}.tar")

set(COM_REENCRYPTOR_FILENAME "com-reencrypt-participant${PRODUCT_NUMBER}-${COM_VERSION}-${COM_RELEASE_VERSION}${RPM_RELEASE_TAG_SUFFIX}.${TARGET_ARCHITECTURE}")
set(COM_REENCRYPTOR_RPM_FILENAME "${COM_REENCRYPTOR_FILENAME}.rpm")

# Directory variables
set(COMSA_ROOT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/comsa-source")
set(COMSA_BUILD_DIR "${CMAKE_BINARY_DIR}/comsa-build")
set(COMSA_INSTALLDIR "${COMSA_BUILD_DIR}/installation")
set(COMSA_SDP_SPECIFIC "${COMSA_ROOT_DIR}/src/com_specific/sdp")
set(COM_REENCRYPTION_UTILS "${COMSA_ROOT_DIR}/src/com_specific/com_reencryptor/utils")
set(COMSA_RPM_TOP "${COMSA_BUILD_DIR}/rpmtop")
set(COMSA_TEMPLATE_DIR "${COMSA_ROOT_DIR}/deployment_templates")
set(COMSA_TMP_DIR "${COMSA_BUILD_DIR}/tmp")

if (NOT DEFINED COM_SA_DIR)
    set(COM_SA_DIR "${COMSA_BUILD_DIR}/dist")
endif()

# File variables
set(COMSA_RPM_SPEC "${COMSA_SDP_SPECIFIC}/com_sa.spec")
set(COM_SA_SO "${COMSA_BUILD_DIR}/coremw-com-sa.so")
set(PMT_SA_SO "${COMSA_BUILD_DIR}/coremw-pmt-sa.so")
set(TRACE_PROBE_SO "${COMSA_BUILD_DIR}/comsa_tp.so")
set(COMSA_TMP_RPM "${COMSA_RPM_TOP}/RPMS/${TARGET_ARCHITECTURE}/${COMSA_RPM_FILENAME}")
set(COMSA_RPM "${COM_SA_DIR}/${COMSA_RPM_FILENAME}")
set(COM_REENCRYPTOR_RPM_SPEC "${COM_REENCRYPTION_UTILS}/com_reencrypt_participant.spec")
set(COM_REENCRYPT_PARTCIPANT "${COMSA_BUILD_DIR}/com-reencrypt-participant")
set(COM_REENCRYPTOR_TMP_RPM "${COMSA_RPM_TOP}/RPMS/${TARGET_ARCHITECTURE}/${COM_REENCRYPTOR_RPM_FILENAME}")
set(COM_REENCRYPTOR_RPM "${COM_SA_DIR}/${COM_REENCRYPTOR_RPM_FILENAME}")

# SUGaR Recommendations
set(CBA_SHARE_DIR "/usr/share/ericsson/cba")
set(RECOMMENDS_UID_TAG "${CBA_SHARE_DIR}/id-mapping/uid.map.defs")
set(RECOMMENDS_GID_TAG "${CBA_SHARE_DIR}/id-mapping/gid.map.defs")

set(COMSA_BUILDENV)

# Compilers
set(CMW_TOOLS "${COMSA_ROOT_DIR}/coremw-tools")
set(DX_SYSROOT_X86_64 "${CMW_TOOLS}/lotc4.0_api")
list(APPEND COMSA_BUILDENV "CC=${CMAKE_C_COMPILER}")
list(APPEND COMSA_BUILDENV "CXX=${CMAKE_CXX_COMPILER}")

# Compiler settings
list(APPEND COMSA_BUILDENV "DX_SYSROOT_X86_64=${DX_SYSROOT_X86_64}")
list(APPEND COMSA_BUILDENV "CFLAGS=-I${DX_SYSROOT_X86_64}/usr/include")
list(APPEND COMSA_BUILDENV "CXXFLAGS=-I${DX_SYSROOT_X86_64}/usr/include")
list(APPEND COMSA_BUILDENV "LDFLAGS=-L${DX_SYSROOT_X86_64}/lib")
list(APPEND COMSA_BUILDENV "LSBCC_SHAREDLIBS=lttng-ust:lttng-ust-fork")
list(APPEND COMSA_BUILDENV "LSB_SHAREDLIBPATH=${COMSA_ROOT_DIR}/dependencies/core_mw_api/lib/x86_64-suse-linux")
list(APPEND COMSA_BUILDENV "LD_LIBPATH=${DX_SYSROOT_X86_64}/usr/lib64")

# Environment variables needed to build
list(APPEND COMSA_BUILDENV "SA_VERSION=P1A000")
list(APPEND COMSA_BUILDENV "CURRENT_GIT_BRANCH=${COM_RELEASE_VERSION}")
list(APPEND COMSA_BUILDENV "ARCHITECTURE=${TARGET_ARCHITECTURE}")
list(APPEND COMSA_BUILDENV "COMSA_DEV_DIR=${COMSA_ROOT_DIR}")
list(APPEND COMSA_BUILDENV "COM_SA_RESULT=${COMSA_BUILD_DIR}")
list(APPEND COMSA_BUILDENV "COMSA_RELEASE=${COMSA_BUILD_DIR}/tmp")
list(APPEND COMSA_BUILDENV "COMSA_THUNK=${BUILDWITH_THUNK}")
#Environment variables needed to create rpm
set(COMSA_RPMENV)
list(APPEND COMSA_RPMENV "COM_SA_SO=${COM_SA_SO}")
list(APPEND COMSA_RPMENV "PMT_SA_SO=${PMT_SA_SO}")
list(APPEND COMSA_RPMENV "TRACE_PROBE_SO=${TRACE_PROBE_SO}")
list(APPEND COMSA_RPMENV "SDPSRC=${COMSA_SDP_SPECIFIC}")
list(APPEND COMSA_RPMENV "RECOMMENDS_UID_TAG=${RECOMMENDS_UID_TAG}")
list(APPEND COMSA_RPMENV "RECOMMENDS_GID_TAG=${RECOMMENDS_GID_TAG}")

#Environment variables needed to create COM reencryptor rpm
set(COM_REENCRYPTOR_RPMENV)
list(APPEND COM_REENCRYPTOR_RPMENV "COM_REENCRYPT_PARTCIPANT=${COM_REENCRYPT_PARTCIPANT}")
list(APPEND COM_REENCRYPTOR_RPMENV "COM_REENCRYPTOR_RPM_SPEC=${COM_REENCRYPTOR_RPM_SPEC}")
list(APPEND COM_REENCRYPTOR_RPMENV "REENCRYPTION_UTILS=${COM_REENCRYPTION_UTILS}")

if(NOT EXISTS ${COM_SA_DIR})
    file(MAKE_DIRECTORY ${COM_SA_DIR})
endif()

# Package identities
if (${HOST_OS} MATCHES "sle.*")
    set(HOSTOS "sle")
endif ()

# Build COMSA
ExternalProject_Add(comsa
        PREFIX ${COMSA_BUILD_DIR}
        SOURCE_DIR ${COMSA_ROOT_DIR}
        BINARY_DIR "${COMSA_ROOT_DIR}/src"
        CONFIGURE_COMMAND true
        BUILD_COMMAND env ${COMSA_BUILDENV} $(MAKE)
        INSTALL_COMMAND true
)

# Create the rpm
add_custom_command(
        TARGET comsa
        COMMENT "Building COMSA RPM"
        DEPENDS install
        COMMAND ${COMSA_RPMENV} ${RPMBUILD_EXECUTABLE} -bb
            --target ${TARGET_ARCHITECTURE}
            --buildroot=${COMSA_BUILD_DIR}/buildroot
            --define "_comsaname com-comsa${PRODUCT_NUMBER}"
            --define "_comname com${PRODUCT_NUMBER}"
            --define "_mafname com-maf${PRODUCT_NUMBER}"
            --define "_comsaver ${COM_VERSION}"
            --define "_comsarel ${COM_RELEASE_VERSION}${RPM_RELEASE_TAG_SUFFIX}"
            --define "_topdir ${COMSA_RPM_TOP}"
            --define "__disable_pmt_sa NO"
            --define "_hostos ${HOSTOS}"
            ${COMSA_RPM_SPEC}
)

# Create the Com Reencrypt Participant rpm
add_custom_command(
        TARGET comsa
        COMMENT "Building COM REENCRYPT PARTICIPANT RPM"
        DEPENDS install
        COMMAND ${COM_REENCRYPTOR_RPMENV} ${RPMBUILD_EXECUTABLE} -bb
            --target ${TARGET_ARCHITECTURE}
            --buildroot=${COMSA_BUILD_DIR}/buildroot/reencryptor
            --define "_reencryptparticipantname com-reencrypt-participant${PRODUCT_NUMBER}"
            --define "_comsaname com-comsa${PRODUCT_NUMBER}"
            --define "_comsaver ${COM_VERSION}"
            --define "_comsarel ${COM_RELEASE_VERSION}${RPM_RELEASE_TAG_SUFFIX}"
            --define "_topdir ${COMSA_RPM_TOP}"
            ${COM_REENCRYPTOR_RPM_SPEC}
)

# Create source package
add_custom_command(
        TARGET comsa
        COMMENT "Create source package of COMSA"
        DEPENDS ${COMSA_ROOT_DIR}/src
                ${COMSA_ROOT_DIR}/dependencies
                ${COMSA_ROOT_DIR}/abs/README
        WORKING_DIRECTORY ${COMSA_TMP_DIR}
        COMMAND tar -cf ${COMSA_SRC_TAR_FILENAME} -C ${COMSA_ROOT_DIR}/abs README
        COMMAND tar --append --file=${COMSA_SRC_TAR_FILENAME} -C ${COMSA_ROOT_DIR} src dependencies
        COMMAND gzip -f ${COMSA_SRC_TAR_FILENAME}
)

# Create yocto package
add_custom_command(
        TARGET comsa
        COMMENT "Create yocto package of COMSA"
        DEPENDS ${COMSA_ROOT_DIR}/abs/meta-comsa
                ${COMSA_ROOT_DIR}/abs/README
        WORKING_DIRECTORY ${COMSA_TMP_DIR}
        COMMAND tar -czf ${COMSA_YOCTO_TAR_FILENAME}.gz -C ${COMSA_ROOT_DIR}/abs README meta-comsa
)

# Copy the rpm and other related files needed for COM
add_custom_command(
        TARGET comsa
        COMMENT "Copy related items needed by COM to ${COM_SA_DIR}"
        DEPENDS ${COM_TPM_RPM}
                ${COMSA_TMP_DIR}/${COMSA_SRC_TAR_FILENAME}.gz
                ${COMSA_TMP_DIR}/${COMSA_YOCTO_TAR_FILENAME}.gz
                ${COMSA_SDP_SPECIFIC}/com_sa_trace.conf
                ${COMSA_SDP_SPECIFIC}/comsa.cfg
                ${COMSA_SDP_SPECIFIC}/comsa_mdf_consumer
                ${COMSA_TEMPLATE_DIR}/UBFU/comsa_bfu
        COMMAND install -m 0644 ${COMSA_TMP_RPM} ${COM_SA_DIR}
        COMMAND install -m 0644 ${COM_REENCRYPTOR_TMP_RPM} ${COM_SA_DIR}
        COMMAND install -m 0644 ${COMSA_TMP_DIR}/${COMSA_SRC_TAR_FILENAME}.gz ${DIST_DIR}/
        COMMAND install -m 0644 ${COMSA_TMP_DIR}/${COMSA_YOCTO_TAR_FILENAME}.gz ${DIST_DIR}/
        COMMAND install -m 0644 ${COMSA_SDP_SPECIFIC}/com_sa_trace.conf ${COM_SA_DIR}
        COMMAND install -m 0644 ${COMSA_SDP_SPECIFIC}/comsa.cfg ${COM_SA_DIR}
        COMMAND install -m 0644 ${COMSA_SDP_SPECIFIC}/com_sa_log.cfg ${COM_SA_DIR}
        COMMAND install -m 0644 ${COMSA_SDP_SPECIFIC}/coremw-com-sa.cfg ${COM_SA_DIR}
        COMMAND install -m 0755 ${COMSA_SDP_SPECIFIC}/comsa_mdf_consumer ${COM_SA_DIR}
        COMMAND install -m 0755 ${COMSA_SDP_SPECIFIC}/comsa_remove_single ${COM_SA_DIR}
        COMMAND install -m 0755 ${COMSA_SDP_SPECIFIC}/comsa_bfu ${COM_SA_DIR}
)
