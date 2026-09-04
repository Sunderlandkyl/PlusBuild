if(OvrvisionPro_DIR)
  find_package(OvrvisionPro REQUIRED NO_MODULE)
  message(STATUS "Using OvrvisionPro available at: ${OvrvisionPro_DIR}")
  plus_copy_libraries_to_runtime_dir("${CMAKE_RUNTIME_OUTPUT_DIRECTORY}" OvrvisionPro)

  set(PLUS_OvrvisionPro_DIR "${OvrvisionPro_DIR}" CACHE INTERNAL "Path to use as OvrvisionPro_DIR")
else()
  set(_ovrvision_depends ${OvrvisionPro_DEPENDENCIES})
  if(TARGET OpenCV)
    list(APPEND _ovrvision_depends OpenCV)
  endif()

  # The OvrvisionPro SDK reaches for ippicvmt.lib through #pragma comment(lib),
  # so the directory holding it has to be passed in directly. Only the MSVC
  # builds of OpenCV ship it.
  set(_ovrvision_options)
  if(MSVC)
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
      set(_ippicv_arch intel64)
    else()
      set(_ippicv_arch ia32)
    endif()
    set(_ovrvision_options
      -DPragmaHack_DIR:PATH=${PLUS_OpenCV_src_DIR}/3rdparty/ippicv/unpack/ippicv_win/lib/${_ippicv_arch})
  endif()

  plus_add_external_project(OvrvisionPro
    GIT_REPOSITORY "https://github.com/PLUSToolkit/OvrvisionProCMake.git"
    GIT_TAG master
    DEPENDS ${_ovrvision_depends}
    NO_BUILD_ALWAYS
    CMAKE_CACHE_ARGS
      -DOpenCV_DIR:PATH=${PLUS_OpenCV_DIR}
      ${_ovrvision_options}
    )
endif()
