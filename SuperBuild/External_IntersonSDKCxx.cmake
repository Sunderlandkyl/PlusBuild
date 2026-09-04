# The Interson SDK itself is not redistributable and has to be installed.
find_path(IntersonSDK_DIR
  NAMES Libraries/Interson.dll
  PATHS C:/IntersonSDK
  DOC "Path to the Interson SDK"
  )
if(NOT IntersonSDK_DIR)
  message(FATAL_ERROR "Please set IntersonSDK_DIR to the path of the Interson SDK.")
endif()

if(IntersonSDKCxx_DIR)
  find_package(IntersonSDKCxx REQUIRED PATHS "${IntersonSDKCxx_DIR}" NO_DEFAULT_PATH)
  message(STATUS "Using IntersonSDKCxx available at: ${IntersonSDKCxx_DIR}")
  plus_copy_libraries_to_runtime_dir("${CMAKE_RUNTIME_OUTPUT_DIRECTORY}" ${IntersonSDKCxx_LIBRARIES})

  set(PLUS_IntersonSDKCxx_DIR "${IntersonSDKCxx_DIR}" CACHE INTERNAL "Path to use as IntersonSDKCxx_DIR")
else()
  plus_add_external_project(IntersonSDKCxx
    GIT_REPOSITORY "https://github.com/KitwareMedical/IntersonSDKCxx.git"
    GIT_TAG "819d620052be7e9b232e12d8946793c15cfbf5a3"
    DEPENDS ${IntersonSDKCxx_DEPENDENCIES}
    CMAKE_CACHE_ARGS
      -DBUILD_TESTING:BOOL=OFF
      -DBUILD_SHARED_LIBS:BOOL=${PLUSBUILD_BUILD_SHARED_LIBS}
    )
endif()
