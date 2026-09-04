if(OpenIGTLinkIO_DIR)
  # OpenIGTLinkIO has been built already
  find_package(OpenIGTLinkIO REQUIRED PATHS "${OpenIGTLinkIO_DIR}" NO_DEFAULT_PATH)

  message(STATUS "Using OpenIGTLinkIO available at: ${OpenIGTLinkIO_DIR}")
  plus_copy_libraries_to_runtime_dir("${CMAKE_RUNTIME_OUTPUT_DIRECTORY}" ${OpenIGTLinkIO_LIBRARIES})

  set(PLUS_OpenIGTLinkIO_DIR "${OpenIGTLinkIO_DIR}" CACHE INTERNAL "Path to use as OpenIGTLinkIO_DIR")
else()
  set(_igtlio_options)
  if(PLUSBUILD_BUILD_PLUSLIB_WIDGETS AND PLUSBUILD_VTK_VERSION VERSION_GREATER_EQUAL 9.0.0)
    # A Qt-enabled VTK 9 needs Qt5_DIR passed on.
    list(APPEND _igtlio_options -DQt5_DIR:PATH=${Qt5_DIR})
  endif()

  plus_add_external_project(OpenIGTLinkIO
    GIT_REPOSITORY "https://github.com/IGSIO/OpenIGTLinkIO.git"
    GIT_TAG master
    DEPENDS ${OpenIGTLinkIO_DEPENDENCIES}
    CMAKE_CACHE_ARGS
      -DBUILD_EXAMPLES:BOOL=OFF
      -DBUILD_SHARED_LIBS:BOOL=${PLUSBUILD_BUILD_SHARED_LIBS}
      -DBUILD_TESTING:BOOL=OFF
      -DVTK_DIR:PATH=${PLUS_VTK_DIR}
      -DOpenIGTLink_DIR:PATH=${PLUS_OpenIGTLink_DIR}
      -DIGTLIO_USE_GUI:BOOL=OFF
      ${_igtlio_options}
    )
endif()
