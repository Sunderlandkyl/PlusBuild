# The Interson Array SDK itself is not redistributable and has to be installed.
set(_platform_suffix "Win10 - x64")
if(WIN32 AND CMAKE_SIZEOF_VOID_P EQUAL 4)
  set(_platform_suffix "Win10 - x86")
endif()

find_path(IntersonArraySDK_DIR
  NAMES IntersonArray.dll
  PATHS
    "C:/IntersonArraySDK/Libraries/${_platform_suffix}"
    "../PLTools/Interson/ArraySDK_3.007_2021-11/Libraries/${_platform_suffix}"
    "../../PLTools/Interson/ArraySDK_3.007_2021-11/Libraries/${_platform_suffix}"
  DOC "Path to the Interson Array SDK libraries"
  )
if(NOT IntersonArraySDK_DIR)
  message(FATAL_ERROR "Please set IntersonArraySDK_DIR to the path of the Interson Array SDK.")
endif()

if(IntersonArraySDKCxx_DIR)
  find_package(IntersonArraySDKCxx REQUIRED PATHS "${IntersonArraySDKCxx_DIR}" NO_DEFAULT_PATH)
  message(STATUS "Using IntersonArraySDKCxx available at: ${IntersonArraySDKCxx_DIR}")
  plus_copy_libraries_to_runtime_dir("${CMAKE_RUNTIME_OUTPUT_DIRECTORY}" ${IntersonArraySDKCxx_LIBRARIES})

  set(PLUS_IntersonArraySDKCxx_DIR "${IntersonArraySDKCxx_DIR}" CACHE INTERNAL "Path to use as IntersonArraySDKCxx_DIR")
else()
  plus_add_external_project(IntersonArraySDKCxx
    GIT_REPOSITORY "https://github.com/KitwareMedical/IntersonArraySDKCxx.git"
    GIT_TAG master
    DEPENDS ${IntersonArraySDKCxx_DEPENDENCIES}
    CMAKE_CACHE_ARGS
      -DBUILD_TESTING:BOOL=OFF
      -DIntersonArraySDK_DIR:PATH=${IntersonArraySDK_DIR}
    )
endif()
