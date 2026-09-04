if(ITK_DIR)
  # ITK has been built already
  find_package(ITK 5.4 REQUIRED PATHS "${ITK_DIR}" NO_DEFAULT_PATH)

  message(STATUS "Using ITK available at: ${ITK_DIR}")
  plus_copy_libraries_to_runtime_dir("${CMAKE_RUNTIME_OUTPUT_DIRECTORY}" ${ITK_LIBRARIES})

  set(PLUS_ITK_DIR "${ITK_DIR}" CACHE INTERNAL "Path to use as ITK_DIR")
else()
  set(PLUS_ITK_VERSION_MAJOR 5)
  set(PLUS_ITK_VERSION_MINOR 4)
  set(PLUS_ITK_VERSION_PATCH 4)
  if(PLUS_ITK_VERSION EQUAL 4)
    message(WARNING "ITK 4.12.0 is not recommended. Use it only to build Plus with support for devices that require Visual Studio 2013.")
    set(PLUS_ITK_VERSION_MAJOR 4)
    set(PLUS_ITK_VERSION_MINOR 12)
    set(PLUS_ITK_VERSION_PATCH 0)
  endif()
  set(PLUS_ITK_VERSION_STRING "v${PLUS_ITK_VERSION_MAJOR}.${PLUS_ITK_VERSION_MINOR}.${PLUS_ITK_VERSION_PATCH}")

  option(PLUS_ITK_USE_SYSTEM_PNG "Use system PNG library for ITK" OFF)
  mark_as_advanced(PLUS_ITK_USE_SYSTEM_PNG)

  set(_itk_options)
  if(PLUS_ITK_USE_SYSTEM_PNG)
    list(APPEND _itk_options -DITK_USE_SYSTEM_PNG:BOOL=ON)
  endif()

  set(_itk_cxx_flags)
  if(MSVC)
    set(_itk_cxx_flags "/MP")
  endif()

  set(_itk_install)
  if(PLUSBUILD_INSTALL_ITK)
    set(_itk_install
      INSTALL_DIR "${CMAKE_BINARY_DIR}/itk-int"
      CONFIG_SUBDIR "lib/cmake/ITK-${PLUS_ITK_VERSION_MAJOR}.${PLUS_ITK_VERSION_MINOR}")
  endif()

  plus_add_external_project(itk
    GIT_REPOSITORY "https://github.com/InsightSoftwareConsortium/ITK"
    GIT_TAG "${PLUS_ITK_VERSION_STRING}"
    DEPENDS ${ITK_DEPENDENCIES}
    CXX_FLAGS "${_itk_cxx_flags}"
    ${_itk_install}
    CMAKE_CACHE_ARGS
      -DBUILD_TESTING:BOOL=OFF
      -DBUILD_EXAMPLES:BOOL=OFF
      -DITK_LEGACY_REMOVE:BOOL=OFF
      -DKWSYS_USE_MD5:BOOL=ON
      -DITK_USE_REVIEW:BOOL=ON
      # Leave the instruction set at the compiler default so that the result
      # still runs on older CPUs.
      -DITK_CXX_OPTIMIZATION_FLAGS:STRING=
      -DITK_C_OPTIMIZATION_FLAGS:STRING=
      -DCMAKE_DEBUG_POSTFIX:STRING=D
      ${_itk_options}
    )

  # ITK is spelled in upper case everywhere else in the superbuild.
  set(PLUS_ITK_SRC_DIR "${PLUS_itk_SRC_DIR}" CACHE INTERNAL "Path to ITK sources")
  set(PLUS_ITK_BIN_DIR "${PLUS_itk_BIN_DIR}" CACHE INTERNAL "Path to ITK binaries")
  set(PLUS_ITK_INSTALL_DIR "${CMAKE_BINARY_DIR}/itk-int" CACHE INTERNAL "Path ITK is installed to")
  set(PLUS_ITK_DIR "${PLUS_itk_DIR}" CACHE INTERNAL "Path to use as ITK_DIR")
endif()
