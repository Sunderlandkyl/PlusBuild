# GrabbieLib, the BK ProFocus CameraLink support library. It is not published,
# so the source tree has to be found on the machine.
find_path(PLUS_GRABBIELIB_SOURCE_DIR GrabbieLibInfo.txt
  PATHS
    "../GrabbieLib-1.1.0"
    "../PLTools/BK/ProFocus/GrabbieLib-1.1.0"
    "../../PLTools/BK/ProFocus/GrabbieLib-1.1.0"
    "../trunk/PLTools/BK/ProFocus/GrabbieLib-1.1.0"
    "${CMAKE_CURRENT_BINARY_DIR}/PLTools/BK/ProFocus/GrabbieLib-1.1.0"
  DOC "Path to the BK GrabbieLib source directory."
  )

if(NOT PLUS_GRABBIELIB_SOURCE_DIR)
  message(FATAL_ERROR "PLUS_GRABBIELIB_SOURCE_DIR must be set to enable BK ultrasound scanner support. Please verify configuration or turn off PLUS_USE_BKPROFOCUS_VIDEO.")
endif()

# GrabbieLib ships the finder for the DALSA Sapera framegrabber SDK, so that
# the user can resolve every external dependency in one configure pass.
list(APPEND CMAKE_MODULE_PATH "${PLUS_GRABBIELIB_SOURCE_DIR}")

set(_grabbielib_options)
if(PLUS_USE_BKPROFOCUS_CAMERALINK)
  find_package(DALSASAPERA)
  if(NOT DALSASAPERA_FOUND)
    message(FATAL_ERROR "This project requires the Dalsa Sapera SDK for BK ProFocus support. Please verify configuration or turn off PLUS_USE_BKPROFOCUS_CAMERALINK.")
  endif()
  set(_grabbielib_options
    -DDALSASAPERA_DIR:PATH=${DALSASAPERA_DIR}
    -DDALSASAPERA_LIB_DIR:PATH=${DALSASAPERA_LIB_DIR}
    )
endif()

plus_add_external_project(GrabbieLib
  SOURCE_DIR "${PLUS_GRABBIELIB_SOURCE_DIR}"
  DEPENDS ${GrabbieLib_DEPENDENCIES}
  CMAKE_CACHE_ARGS
    -DGRABBIE_USE_CAMERALINK:BOOL=${PLUS_USE_BKPROFOCUS_CAMERALINK}
    ${_grabbielib_options}
  )

set(PLUS_GRABBIELIB_DIR "${PLUS_GrabbieLib_BIN_DIR}" CACHE INTERNAL "Path to store GrabbieLib binaries")
