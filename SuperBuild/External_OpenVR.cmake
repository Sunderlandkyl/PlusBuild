if(OpenVR_DIR OR OPENVR_ROOT_DIR)
  # The OpenVR SDK is available already
  find_package(OpenVR REQUIRED)
  message(STATUS "Using OpenVR available at: ${OpenVR_DIR}")
  plus_copy_libraries_to_runtime_dir("${CMAKE_RUNTIME_OUTPUT_DIRECTORY}" OpenVR)

  if(OpenVR_DIR)
    set(PLUS_OVR_DIR "${OpenVR_DIR}" CACHE INTERNAL "Path to the OpenVR SDK")
  else()
    set(PLUS_OVR_DIR "${OPENVR_ROOT_DIR}" CACHE INTERNAL "Path to the OpenVR SDK")
  endif()
else()
  # OpenVR ships prebuilt binaries, so there is nothing to configure or build.
  plus_add_external_project(OpenVR
    GIT_REPOSITORY "https://github.com/ValveSoftware/openvr.git"
    GIT_TAG master
    DEPENDS ${OpenVR_DEPENDENCIES}
    DOWNLOAD_ONLY
    )
  set(PLUS_OVR_DIR "${PLUS_OpenVR_SRC_DIR}" CACHE INTERNAL "Path to the OpenVR SDK" FORCE)
endif()
