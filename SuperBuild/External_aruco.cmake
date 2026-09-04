if(aruco_DIR)
  find_package(aruco 2.0.19 REQUIRED NO_MODULE)
  message(STATUS "Using aruco available at: ${aruco_DIR}")
  plus_copy_libraries_to_runtime_dir("${CMAKE_RUNTIME_OUTPUT_DIRECTORY}" ${aruco_LIBS})

  set(PLUS_aruco_DIR "${aruco_DIR}" CACHE INTERNAL "Path to use as aruco_DIR")
else()
  set(_aruco_depends)
  if(TARGET OpenCV)
    set(_aruco_depends OpenCV)
  endif()

  plus_add_external_project(aruco
    GIT_REPOSITORY "https://github.com/PlusToolkit/aruco.git"
    GIT_TAG master
    DEPENDS ${_aruco_depends}
    CMAKE_CACHE_ARGS
      # aruco declares a minimum CMake version that CMake 4 no longer accepts.
      -DCMAKE_POLICY_VERSION_MINIMUM:STRING=3.5
      -DOpenCV_DIR:PATH=${PLUS_OpenCV_DIR}
      -DOpenCV_INSTALL_BINARIES_PREFIX:STRING= # Install into the prefix directly, not under arch/compiler
      -DUSE_OWN_EIGEN3:BOOL=OFF
      -DBUILD_TESTS:BOOL=OFF
      -DBUILD_PERF_TESTS:BOOL=OFF
    )
endif()
