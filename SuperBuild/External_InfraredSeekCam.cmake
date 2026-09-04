if(SeekCameraLib_DIR)
  find_package(SeekCameraLib REQUIRED NO_MODULE)
  message(STATUS "Using SeekCameraLib available at: ${SeekCameraLib_DIR}")
  plus_copy_libraries_to_runtime_dir("${CMAKE_RUNTIME_OUTPUT_DIRECTORY}" ${SeekCameraLib_LIBRARIES})

  set(PLUS_SeekCameraLib_DIR "${SeekCameraLib_DIR}" CACHE INTERNAL "Path to use as SeekCameraLib_DIR")
else()
  set(_seek_depends ${SeekCameraLib_DEPENDENCIES})
  foreach(_dependency LibUSB OpenCV)
    if(TARGET ${_dependency})
      list(APPEND _seek_depends ${_dependency})
    endif()
  endforeach()

  plus_add_external_project(SeekCameraLib
    GIT_REPOSITORY "https://github.com/medtec4susdev/libseek-thermal.git"
    GIT_TAG master
    DEPENDS ${_seek_depends}
    CMAKE_CACHE_ARGS
      -DLibUSB_ROOT_DIR:PATH=${LibUSB_ROOT_DIR}
      -DOpenCV_DIR:PATH=${PLUS_OpenCV_DIR}
      -DBUILD_EXAMPLES:BOOL=OFF
      -DBUILD_SHARED_LIBS:BOOL=${PLUSBUILD_BUILD_SHARED_LIBS}
      -DINSTALL_DLL:BOOL=OFF
      -DWITH_ADDRESS_SANITIZER:BOOL=OFF
      -DWITH_DEBUG_VERBOSITY:BOOL=OFF
    )
endif()
