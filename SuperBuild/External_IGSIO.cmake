if(IGSIO_DIR)
  # IGSIO has been built already
  find_package(IGSIO REQUIRED NO_MODULE)
  message(STATUS "Using IGSIO available at: ${IGSIO_DIR}")
  plus_copy_libraries_to_runtime_dir("${CMAKE_RUNTIME_OUTPUT_DIRECTORY}" ${IGSIO_LIBRARIES})

  set(PLUS_IGSIO_DIR "${IGSIO_DIR}" CACHE INTERNAL "Path to use as IGSIO_DIR")
else()
  set(_igsio_options)
  if(PLUSBUILD_BUILD_PLUSLIB_WIDGETS AND PLUSBUILD_VTK_VERSION VERSION_GREATER_EQUAL 9.0.0)
    # A Qt-enabled VTK 9 needs Qt5_DIR passed on.
    list(APPEND _igsio_options -DQt5_DIR:PATH=${Qt5_DIR})
  endif()

  foreach(_dependency vtk itk)
    if(TARGET ${_dependency})
      list(APPEND IGSIO_DEPENDENCIES ${_dependency})
    endif()
  endforeach()

  plus_add_external_project(IGSIO
    GIT_REPOSITORY "https://github.com/IGSIO/IGSIO.git"
    GIT_TAG master
    DEPENDS ${IGSIO_DEPENDENCIES}
    CMAKE_CACHE_ARGS
      -DEXECUTABLE_OUTPUT_PATH:PATH=${CMAKE_RUNTIME_OUTPUT_DIRECTORY}
      -DBUILD_SHARED_LIBS:BOOL=${PLUSBUILD_BUILD_SHARED_LIBS}
      -DBUILD_TESTING:BOOL=OFF
      -DVTK_DIR:PATH=${PLUS_VTK_DIR}
      -DITK_DIR:PATH=${PLUS_ITK_DIR}
      -DIGSIO_ZLIB_INCLUDE_DIR:PATH=${ZLIB_INCLUDE_DIR}
      -DIGSIO_ZLIB_LIBRARY:PATH=${ZLIB_LIBRARY}
      -DIGSIO_SUPERBUILD:BOOL=ON
      -DIGSIO_USE_3DSlicer:BOOL=OFF
      -DIGSIO_BUILD_SEQUENCEIO:BOOL=ON
      -DIGSIO_BUILD_VOLUMERECONSTRUCTION:BOOL=ON
      -DIGSIO_SEQUENCEIO_ENABLE_MKV:BOOL=${PLUS_USE_MKV_IO}
      -DIGSIO_USE_VP9:BOOL=${PLUS_USE_VP9}
      ${_igsio_options}
    )

  # IGSIO is itself a superbuild, so what dependents need is the inner tree.
  set(PLUS_IGSIO_DIR "${PLUS_IGSIO_BIN_DIR}/inner-build" CACHE INTERNAL "Path to use as IGSIO_DIR" FORCE)
endif()
