# --------------------------------------------------------------------------
# PlusApp
set(_plusapp_args)

if(PLUSBUILD_DOCUMENTATION)
  list(APPEND _plusapp_args
    -DPLUSAPP_DOCUMENTATION_SEARCH_SERVER_INDEXED:BOOL=${PLUSBUILD_DOCUMENTATION_SEARCH_SERVER_INDEXED}
    -DPLUSAPP_DOCUMENTATION_GOOGLE_ANALYTICS_TRACKING_ID:STRING=${PLUSBUILD_DOCUMENTATION_GOOGLE_ANALYTICS_TRACKING_ID}
    -DDOXYGEN_DOT_EXECUTABLE:FILEPATH=${DOXYGEN_DOT_EXECUTABLE}
    -DDOXYGEN_EXECUTABLE:FILEPATH=${DOXYGEN_EXECUTABLE}
    )
endif()

plus_add_external_project(PlusApp
  GIT_REPOSITORY "${PLUSAPP_GIT_REPOSITORY}"
  GIT_TAG "${PLUSAPP_GIT_REVISION}"
  DEPENDS ${PlusApp_DEPENDENCIES}
  CMAKE_CACHE_ARGS
    ${ep_qt_args}
    -DGIT_EXECUTABLE:FILEPATH=${GIT_EXECUTABLE}
    "-DCMAKE_MODULE_PATH:STRING=${CMAKE_MODULE_PATH}"
    -DPlusLib_DIR:PATH=${PLUSLIB_DIR}
    -DBUILD_SHARED_LIBS:BOOL=${PLUSBUILD_BUILD_SHARED_LIBS}
    -DBUILDNAME:STRING=${BUILDNAME}
    -DPLUSAPP_OFFLINE_BUILD:BOOL=${PLUSBUILD_OFFLINE_BUILD}
    -DPLUSAPP_BUILD_DiagnosticTools:BOOL=ON
    -DPLUSAPP_BUILD_fCal:BOOL=ON
    -DPLUSAPP_TEST_GUI:BOOL=${PLUSAPP_TEST_GUI}
    -DBUILD_DOCUMENTATION:BOOL=${PLUSBUILD_DOCUMENTATION}
    -DPLUSAPP_PACKAGE_EDITION:STRING=${PLUSAPP_PACKAGE_EDITION}
    -DPLUSBUILD_DOWNLOAD_PLUSLIBDATA:BOOL=${PLUSBUILD_DOWNLOAD_PLUSLIBDATA}
    -DVTK_DIR:PATH=${PLUS_VTK_DIR}
    -DITK_DIR:PATH=${PLUS_ITK_DIR}
    -DIGSIO_DIR:PATH=${PLUS_IGSIO_DIR}
    ${_plusapp_args}
  )

set(PLUS_PLUSAPP_DIR "${PLUS_PlusApp_SRC_DIR}" CACHE INTERNAL "Path to store PlusApp contents.")
set(PLUSAPP_DIR "${PLUS_PlusApp_BIN_DIR}" CACHE PATH "The directory containing PlusApp binaries" FORCE)

# --------------------------------------------------------------------------
# Put the Qt runtime beside the executables so that the build tree is usable
# without Qt on PATH. Only shared Qt builds need this.
if(TARGET Qt5::Core)
  get_target_property(_qt_lib_type Qt5::Core TYPE)
  if(_qt_lib_type STREQUAL "SHARED_LIBRARY")
    # Close over the module dependencies of the requested components, so that
    # (for example) asking for Widgets also brings Gui and Core.
    set(_components ${PLUSBUILD_QT_COMPONENTS})
    set(_previous_count -1)
    list(LENGTH _components _count)
    while(NOT _count EQUAL _previous_count)
      set(_previous_count ${_count})
      foreach(_component IN LISTS _components)
        list(APPEND _components ${_Qt5${_component}_MODULE_DEPENDENCIES})
      endforeach()
      list(REMOVE_DUPLICATES _components)
      list(LENGTH _components _count)
    endwhile()

    set(_qt_targets)
    foreach(_component IN LISTS _components)
      find_package(Qt5 QUIET COMPONENTS ${_component})
      if(TARGET Qt5::${_component})
        list(APPEND _qt_targets Qt5::${_component})
      endif()
    endforeach()

    plus_copy_libraries_to_runtime_dir("${CMAKE_RUNTIME_OUTPUT_DIRECTORY}" ${_qt_targets})

    # Debug symbols for the debug Qt libraries, so that a debug build can be
    # stepped into. The previous version of this read QT_MOC_EXECUTABLE and
    # PDB_REGEX_PATTERN, neither of which is defined under Qt 5, and so copied
    # the whole Qt bin directory.
    if(MSVC AND PLUSBUILD_MULTI_CONFIG)
      foreach(_target IN LISTS _qt_targets)
        get_target_property(_debug_library ${_target} IMPORTED_LOCATION_DEBUG)
        if(_debug_library)
          string(REPLACE "${CMAKE_SHARED_LIBRARY_SUFFIX}" ".pdb" _debug_pdb "${_debug_library}")
          if(EXISTS "${_debug_pdb}")
            file(COPY "${_debug_pdb}" DESTINATION "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/Debug")
          endif()
        endif()
      endforeach()
    endif()
  endif()
endif()
