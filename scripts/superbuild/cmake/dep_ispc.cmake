## Copyright 2009-2021 Intel Corporation
## SPDX-License-Identifier: Apache-2.0

set(COMPONENT_NAME ispc)

set(COMPONENT_PATH ${INSTALL_DIR_ABSOLUTE})
if (INSTALL_IN_SEPARATE_DIRECTORIES)
  set(COMPONENT_PATH ${INSTALL_DIR_ABSOLUTE}/${COMPONENT_NAME})
endif()

if (APPLE)
  set(ISPC_OSSUFFIX "macOS.tar.gz")
elseif(WIN32)
  set(ISPC_OSSUFFIX "windows.zip")
else()
  set(ISPC_OSSUFFIX "linux.tar.gz")
endif()

set(ISPC_URL "https://github.com/ispc/ispc/releases/download/v${ISPC_VERSION}/ispc-v${ISPC_VERSION}-${ISPC_OSSUFFIX}")

if (ISPC_HASH)
  set(ISPC_URL_HASH URL_HASH SHA256=${ISPC_HASH})
endif()

ExternalProject_Add(${COMPONENT_NAME}
  PREFIX ${COMPONENT_NAME}
  STAMP_DIR ${COMPONENT_NAME}/stamp
  SOURCE_DIR ${COMPONENT_NAME}/src
  BINARY_DIR ${COMPONENT_NAME}
  URL ${ISPC_URL}
  ${ISPC_URL_HASH}
  CONFIGURE_COMMAND ""
  BUILD_COMMAND ""
  INSTALL_COMMAND "${CMAKE_COMMAND}" -E copy_if_different
    <SOURCE_DIR>/bin/ispc${CMAKE_EXECUTABLE_SUFFIX}
    ${COMPONENT_PATH}/bin/ispc${CMAKE_EXECUTABLE_SUFFIX}
  BUILD_ALWAYS OFF
)

set(ISPC_PATH "${COMPONENT_PATH}/bin/ispc${CMAKE_EXECUTABLE_SUFFIX}")


external_install(ispc)