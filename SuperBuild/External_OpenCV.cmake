set(PLUSBUILD_OpenCV_VERSION "4.5.5" CACHE STRING "Set OpenCV version (version: [major].[minor].[patch])")

if(OpenCV_DIR)
  find_package(OpenCV ${PLUSBUILD_OpenCV_VERSION} REQUIRED NO_MODULE)
  message(STATUS "Using OpenCV available at: ${OpenCV_DIR}")
  plus_copy_libraries_to_runtime_dir("${CMAKE_RUNTIME_OUTPUT_DIRECTORY}" ${OpenCV_LIBS})

  set(PLUS_OpenCV_DIR "${OpenCV_DIR}" CACHE INTERNAL "Path to use as OpenCV_DIR")

  # Other external projects name OpenCV as a dependency, so the target has to
  # exist even when OpenCV is not built here.
  add_custom_target(OpenCV)
else()
  set(_opencv_options)

  find_package(CUDA QUIET)
  if(CUDA_FOUND)
    # 32-bit CUDA was dropped after 6.5.
    if(CMAKE_SIZEOF_VOID_P EQUAL 4 AND CUDA_VERSION VERSION_GREATER "6.5")
      list(APPEND _opencv_options -DWITH_CUDA:BOOL=OFF)
    else()
      list(APPEND _opencv_options
        -DWITH_CUDA:BOOL=ON
        -DCUDA_TOOLKIT_ROOT_DIR:PATH=${CUDA_TOOLKIT_ROOT_DIR})
    endif()

    set(_generations "Fermi" "Kepler" "Maxwell")
    if(CUDA_VERSION VERSION_GREATER_EQUAL 8.0.0)
      list(APPEND _generations "Pascal" "Volta")
    endif()
    if(CUDA_VERSION VERSION_GREATER_EQUAL 10.0.0)
      list(APPEND _generations "Turing")
    endif()
    if(NOT CMAKE_CROSSCOMPILING)
      list(APPEND _generations "Auto")
    endif()

    set(PLUSBUILD_OpenCV_CUDA_GENERATION "" CACHE STRING "Build CUDA device code only for specific GPU architecture. Leave empty to build for all architectures.")
    set_property(CACHE PLUSBUILD_OpenCV_CUDA_GENERATION PROPERTY STRINGS "" ${_generations})

    if(PLUSBUILD_OpenCV_CUDA_GENERATION AND NOT PLUSBUILD_OpenCV_CUDA_GENERATION IN_LIST _generations)
      string(REPLACE ";" ", " _generations "${_generations}")
      message(FATAL_ERROR "Only the CUDA ${_generations} generations are supported.")
    endif()
    list(APPEND _opencv_options -DCUDA_GENERATION:STRING=${PLUSBUILD_OpenCV_CUDA_GENERATION})
  else()
    list(APPEND _opencv_options -DWITH_CUDA:BOOL=OFF)
  endif()

  if(Qt5_FOUND)
    list(APPEND _opencv_options -DWITH_QT:BOOL=ON -DQt5_DIR:PATH=${Qt5_DIR})
  endif()

  if(MSVC)
    list(APPEND _opencv_options -DWITH_MSMF:BOOL=ON)
  endif()

  if(NOT PLUSBUILD_BUILD_SHARED_LIBS)
    list(APPEND _opencv_options -DBUILD_WITH_STATIC_CRT:BOOL=OFF)
  endif()

  set(_opencv_depends)
  if(TARGET vtk)
    set(_opencv_depends vtk)
  endif()

  plus_add_external_project(OpenCV
    GIT_REPOSITORY "https://github.com/opencv/opencv.git"
    GIT_TAG "${PLUSBUILD_OpenCV_VERSION}"
    DEPENDS ${_opencv_depends}
    CMAKE_CACHE_ARGS
      ${ep_qt_args}
      -DEXECUTABLE_OUTPUT_PATH:PATH=${CMAKE_RUNTIME_OUTPUT_DIRECTORY}
      # Install into the prefix directly, not under arch/compiler subdirectories.
      -DOpenCV_INSTALL_BINARIES_PREFIX:STRING=
      -DOPENCV_INSTALL_BINARIES_PREFIX:STRING=
      -DVTK_DIR:PATH=${PLUS_VTK_DIR}
      -DWITH_VTK:BOOL=ON
      -DBUILD_TESTS:BOOL=OFF
      -DBUILD_PERF_TESTS:BOOL=OFF
      -DBUILD_DOCS:BOOL=OFF
      ${_opencv_options}
    )

  # Referred to in lower case by OvrvisionPro's pragma workaround.
  set(PLUS_OpenCV_src_DIR "${PLUS_OpenCV_SRC_DIR}" CACHE INTERNAL "Path to OpenCV sources")
endif()
