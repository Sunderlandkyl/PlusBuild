if(VTK_DIR)
  # VTK has been built already
  find_package(VTK REQUIRED)

  if(VTK_VERSION_MAJOR LESS 8)
    message(FATAL_ERROR "VTK 8 or newer is required for Plus. Found VTK ${VTK_VERSION}.")
  endif()

  message(STATUS "Using VTK available at: ${VTK_DIR}")
  plus_copy_libraries_to_runtime_dir("${CMAKE_RUNTIME_OUTPUT_DIRECTORY}" ${VTK_LIBRARIES})

  set(PLUS_VTK_DIR "${VTK_DIR}" CACHE INTERNAL "Path to use as VTK_DIR")

  if(PLUSBUILD_BUILD_PLUSAPP OR PLUSBUILD_BUILD_PLUSLIB_WIDGETS)
    if(NOT TARGET vtkGUISupportQt AND NOT TARGET VTK::GUISupportQt)
      message(SEND_ERROR "VTK has to be built with Qt support enabled in order to build PlusApp.")
    endif()
  endif()

  set(PLUSBUILD_VTK_VERSION ${VTK_VERSION})
  set(PLUSBUILD_VTK_VERSION_MAJOR ${VTK_VERSION_MAJOR})
  set(PLUSBUILD_VTK_VERSION_MINOR ${VTK_VERSION_MINOR})
  set(PLUSBUILD_VTK_VERSION_PATCH ${VTK_VERSION_PATCH})
else()
  set(PLUSBUILD_EXTERNAL_VTK_VERSION "v9.1.0" CACHE STRING "User-selected VTK version to build Plus against")
  set_property(CACHE PLUSBUILD_EXTERNAL_VTK_VERSION PROPERTY STRINGS "v8.2.0" "v9.0.3" "v9.1.0" "v9.2.5")

  if(PLUSBUILD_EXTERNAL_VTK_VERSION STREQUAL "")
    set(PLUSBUILD_EXTERNAL_VTK_VERSION "v9.1.0" CACHE STRING "User-selected VTK version to build Plus against" FORCE)
  endif()

  string(FIND "${PLUSBUILD_EXTERNAL_VTK_VERSION}" "." _is_tag)
  if(_is_tag EQUAL -1)
    # A commit hash rather than a version tag, so the version is unknown.
    set(PLUSBUILD_VTK_VERSION ${PLUSBUILD_EXTERNAL_VTK_VERSION} CACHE INTERNAL "Internal CMake version for VTK.")
  else()
    string(REPLACE "v" "" _version_string "${PLUSBUILD_EXTERNAL_VTK_VERSION}")
    string(REPLACE "." ";" _version_list "${_version_string}")
    list(GET _version_list 0 PLUSBUILD_VTK_VERSION_MAJOR)
    list(GET _version_list 1 PLUSBUILD_VTK_VERSION_MINOR)
    list(GET _version_list 2 PLUSBUILD_VTK_VERSION_PATCH)
    set(PLUSBUILD_VTK_VERSION
      "${PLUSBUILD_VTK_VERSION_MAJOR}.${PLUSBUILD_VTK_VERSION_MINOR}.${PLUSBUILD_VTK_VERSION_PATCH}"
      CACHE INTERNAL "Internal CMake version for VTK.")
  endif()

  set(_vtk_options -DVTK_Group_Rendering:BOOL=ON)
  if(PLUSBUILD_VTK_RENDERING_BACKEND STREQUAL "None")
    set(_vtk_options -DVTK_Group_Rendering:BOOL=OFF)
  endif()

  if(Qt5_FOUND)
    if(PLUSBUILD_VTK_VERSION VERSION_LESS 9.0.0)
      if(Qt5_VERSION VERSION_GREATER_EQUAL 5.15.0)
        message(SEND_ERROR "Qt 5.15 and newer require VTK 9.0.0 or newer.")
      endif()
      list(APPEND _vtk_options -DVTK_Group_Qt:BOOL=ON -DVTK_QT_VERSION:STRING=5)
    else()
      list(APPEND _vtk_options -DVTK_GROUP_ENABLE_Qt:STRING=YES)
    endif()
  endif()

  if(APPLE)
    # VTK's own CMakeLists enables Carbon and disables Cocoa if it has to.
    list(APPEND _vtk_options
      -DVTK_USE_CARBON:BOOL=OFF
      -DVTK_USE_COCOA:BOOL=ON
      -DVTK_USE_X:BOOL=OFF
      )
  endif()

  if(PLUSBUILD_USE_Tesseract)
    list(APPEND _vtk_options -DModule_vtkzlib:INTERNAL=ON)
  endif()

  if(MSVC)
    list(APPEND _vtk_options -DCMAKE_CXX_MP_FLAG:BOOL=ON)
  endif()

  # VTK 9 ignores incoming output directories, so there is no point in setting
  # them. The condition here used to test VTK_VERSION, which is empty in this
  # branch, so they were passed for every version.
  set(_vtk_output_dirs)
  if(PLUSBUILD_VTK_VERSION VERSION_GREATER_EQUAL 9.0.0)
    set(_vtk_output_dirs NO_OUTPUT_DIRS)
  endif()

  set(_vtk_install)
  if(PLUSBUILD_INSTALL_VTK)
    set(_vtk_install
      INSTALL_DIR "${CMAKE_BINARY_DIR}/vtk-int"
      CONFIG_SUBDIR "lib/cmake/vtk-${PLUSBUILD_VTK_VERSION_MAJOR}.${PLUSBUILD_VTK_VERSION_MINOR}")
  endif()

  plus_add_external_project(vtk
    GIT_REPOSITORY "https://github.com/kitware/vtk.git"
    GIT_TAG "${PLUSBUILD_EXTERNAL_VTK_VERSION}"
    SOURCE_DIR "${CMAKE_BINARY_DIR}/vtk"
    DEPENDS ${VTK_DEPENDENCIES}
    ${_vtk_output_dirs}
    ${_vtk_install}
    CMAKE_CACHE_ARGS
      ${ep_qt_args}
      -DBUILD_TESTING:BOOL=OFF
      -DBUILD_EXAMPLES:BOOL=OFF
      -DBUILD_SHARED_LIBS:BOOL=${PLUSBUILD_BUILD_SHARED_LIBS}
      -DVTK_WRAP_PYTHON:BOOL=OFF
      -DVTK_SMP_IMPLEMENTATION_TYPE:STRING=OpenMP
      -DVTK_RENDERING_BACKEND:STRING=${PLUSBUILD_VTK_RENDERING_BACKEND}
      -DCMAKE_DEBUG_POSTFIX:STRING=D
      ${_vtk_options}
    )

  # VTK is spelled in upper case everywhere else in the superbuild.
  set(PLUS_VTK_SRC_DIR "${PLUS_vtk_SRC_DIR}" CACHE INTERNAL "Path to VTK sources")
  set(PLUS_VTK_BIN_DIR "${PLUS_vtk_BIN_DIR}" CACHE INTERNAL "Path to VTK binaries")
  set(PLUS_VTK_INSTALL_DIR "${CMAKE_BINARY_DIR}/vtk-int" CACHE INTERNAL "Path VTK is installed to")
  set(PLUS_VTK_DIR "${PLUS_vtk_DIR}" CACHE INTERNAL "Path to use as VTK_DIR")
endif()
