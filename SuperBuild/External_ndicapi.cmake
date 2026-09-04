if(ndicapi_DIR)
  find_package(ndicapi REQUIRED NO_MODULE)
  message(STATUS "Using ndicapi available at: ${ndicapi_DIR}")
  plus_copy_libraries_to_runtime_dir("${CMAKE_RUNTIME_OUTPUT_DIRECTORY}" ndicapi)

  set(PLUS_ndicapi_DIR "${ndicapi_DIR}" CACHE INTERNAL "Path to use as ndicapi_DIR")
else()
  plus_add_external_project(ndicapi
    GIT_REPOSITORY "https://github.com/PlusToolkit/ndicapi.git"
    GIT_TAG master
    )
endif()
