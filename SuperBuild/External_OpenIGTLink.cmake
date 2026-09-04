if(OpenIGTLink_DIR)
  # OpenIGTLink has been built already
  find_package(OpenIGTLink REQUIRED NO_MODULE)
  if(OpenIGTLink_PROTOCOL_VERSION LESS 3)
    message(FATAL_ERROR "Plus requires a build of OpenIGTLink with v3 support enabled. Please point OpenIGTLink_DIR at an implementation with v3 support.")
  endif()

  message(STATUS "Using OpenIGTLink available at: ${OpenIGTLink_DIR}")
  plus_copy_libraries_to_runtime_dir("${CMAKE_RUNTIME_OUTPUT_DIRECTORY}" ${OpenIGTLink_LIBRARIES})

  set(PLUS_OpenIGTLink_DIR "${OpenIGTLink_DIR}" CACHE INTERNAL "Path to use as OpenIGTLink_DIR")
else()
  plus_add_external_project(OpenIGTLink
    GIT_REPOSITORY "https://github.com/openigtlink/OpenIGTLink.git"
    GIT_TAG master
    DEPENDS ${OpenIGTLink_DEPENDENCIES}
    CMAKE_CACHE_ARGS
      -DBUILD_EXAMPLES:BOOL=OFF
      -DBUILD_SHARED_LIBS:BOOL=${PLUSBUILD_BUILD_SHARED_LIBS}
      -DBUILD_TESTING:BOOL=OFF
      -DOpenIGTLink_SUPERBUILD:BOOL=OFF
      -DOpenIGTLink_PROTOCOL_VERSION_2:BOOL=OFF
      -DOpenIGTLink_PROTOCOL_VERSION_3:BOOL=ON
      -DOpenIGTLink_ENABLE_VIDEOSTREAMING:BOOL=${PLUS_ENABLE_VIDEOSTREAMING}
      -DOpenIGTLink_USE_VP9:BOOL=OFF
    )
endif()
