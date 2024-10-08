# Copyright 2019 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

set(CMAKE_CXX_STANDARD 17)

get_filename_component(SYCL_COMPILER_NAME ${CMAKE_CXX_COMPILER} NAME_WE)
if (WIN32 AND (SYCL_COMPILER_NAME STREQUAL "icx" OR SYCL_COMPILER_NAME STREQUAL "icpx"))
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /Qoption,link,/DEPENDENTLOADFLAG:0x2000")
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} /Qoption,link,/DEPENDENTLOADFLAG:0x2000")
elseif (WIN32) #MSVC
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /DEPENDENTLOADFLAG:0x2000")
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} /DEPENDENTLOADFLAG:0x2000")
endif()

# Add a relative target path to the HDOSPRAY_RPATH.
function(_add_target_to_rpath CURRENT_RPATH target)
  get_target_property(LIBRARY_FILE ${target} LOCATION)

  get_filename_component(LIBRARY_PATH ${LIBRARY_FILE} DIRECTORY)

  file(RELATIVE_PATH
      LIBRARY_PATH_REL
      "${CMAKE_INSTALL_PREFIX}/plugin/usd"
      ${LIBRARY_PATH}   
  )
  set (HDOSPRAY_RPATH "${CURRENT_RPATH}:$ORIGIN/${LIBRARY_PATH_REL}" PARENT_SCOPE)
endfunction()

option(USE_HOUDINI_USD "use Houdini USD" OFF)

find_package(ospray 3 REQUIRED
  PATHS ${ospray_DIR})
find_package(rkcommon 1 REQUIRED
  PATHS ${rkcommon_DIR})

set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)

if(USE_HOUDINI_USD)
  include(houdini)
else()
	FIND_PACKAGE(pxr CONFIG REQUIRED)
endif()

add_library(hdOSPRay SHARED
    api.h
    config.cpp
    config.h
    discovery.cpp
    parser.cpp
    instancer.cpp
    instancer.h
    mesh.cpp
    mesh.h
    camera.cpp
    camera.h
    basisCurves.cpp
    basisCurves.h
    material.cpp
    material.h
    rendererPlugin.cpp
    rendererPlugin.h
    renderDelegate.cpp
    renderDelegate.h
    renderPass.cpp
    renderPass.h
    renderBuffer.cpp
    renderBuffer.h
    sampler.cpp
    sampler.h
    texture.cpp
    texture.h
    lights/light.cpp
    lights/light.h
    lights/diskLight.cpp
    lights/diskLight.h
    lights/distantLight.cpp
    lights/distantLight.h
    lights/domeLight.cpp
    lights/domeLight.h
    lights/rectLight.cpp
    lights/rectLight.h
    lights/sphereLight.cpp
    lights/sphereLight.h
    lights/cylinderLight.cpp
    lights/cylinderLight.h
    context.h
    renderParam.h
    plugInfo.json
  )

set_property(TARGET hdOSPRay PROPERTY CXX_STANDARD 17)

if(USE_HOUDINI_USD)
  target_link_libraries(hdOSPRay PUBLIC
    ospray::ospray
    ospray::ospray_sdk
    rkcommon::rkcommon
    Houdini
    ${HOUDINI_CUSTOM_TARGETS}
    )
else()
  target_include_directories(hdOSPRay PUBLIC ${PXR_INCLUDE_DIRS})
  target_link_libraries(hdOSPRay PUBLIC
    ospray::ospray
    ospray::ospray_sdk
    rkcommon::rkcommon
    ${PXR_LIBRARIES}
    )
endif()

hdospray_sign_target(hdOSPRay)

target_compile_definitions(hdOSPRay
  PRIVATE
  MFB_PACKAGE_NAME=hdOSPRay
  MFB_ALT_PACKAGE_NAME=hdOSPRay
  NOMINMAX
  HDOSPRAY_EXPORTS
  $<$<CXX_COMPILER_ID:MSVC>:/MP /wd4244 /wd4305 /wd4996>
  )

if (APPLE) # fix boost error with xcode
  add_definitions(-D_LIBCPP_ENABLE_CXX17_REMOVED_UNARY_BINARY_FUNCTION)
endif()

install(TARGETS hdOSPRay DESTINATION plugin/usd)

# plugInfo.json
set(PLUG_INFO_LIBRARY_PATH "../hdOSPRay${CMAKE_SHARED_LIBRARY_SUFFIX}")
set(PLUG_INFO_RESOURCE_PATH "resources")
set(PLUG_INFO_ROOT "..")
configure_file(plugInfo.json plugInfo.json @ONLY)
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/plugInfo.json" DESTINATION plugin/usd/hdOSPRay/resources)

# add ptex module to ospray libraries
option(HDOSPRAY_PLUGIN_PTEX "build hdOSPRay with Ptex support" OFF)
if (HDOSPRAY_PLUGIN_PTEX)
  if (NOT TARGET ospray::ospray_module_ptex)
    message(FATAL_ERROR "hdOSPRayPlugin requires building OSPRay with ptex module")
  endif()

  find_package(ptex CONFIG REQUIRED)
  target_link_libraries(hdOSPRay PUBLIC ospray::ospray_module_ptex)
  target_compile_definitions(hdOSPRay PUBLIC -DHDOSPRAY_PLUGIN_PTEX)
endif()

# add OpenImageDenoise
option(HDOSPRAY_ENABLE_DENOISER "build OSPRay plugin using OpenImageDenoise" ON)
if (HDOSPRAY_ENABLE_DENOISER)
  target_compile_definitions(hdOSPRay PUBLIC -DHDOSPRAY_ENABLE_DENOISER)
endif()

########################################################################
# RPATH
########################################################################

option(HDOSPRAY_SET_REL_RPATH "Adds the relative paths of OSPray and rkcommon to the rpath" ON)

set (HDOSPRAY_RPATH "$ORIGIN")
set (HDOSPRAY_RPATH "${HDOSPRAY_RPATH}:/../../lib")
if(USE_HOUDINI_USD)
else()
  set (HDOSPRAY_RPATH "${HDOSPRAY_RPATH}:${pxr_DIR}/lib")
endif()

if(HDOSPRAY_SET_REL_RPATH)
  _add_target_to_rpath(${HDOSPRAY_RPATH} ospray::ospray)
  _add_target_to_rpath(${HDOSPRAY_RPATH} rkcommon::rkcommon)
endif()

set_target_properties(hdOSPRay PROPERTIES
  PREFIX ""
  INSTALL_RPATH ${HDOSPRAY_RPATH}
  )