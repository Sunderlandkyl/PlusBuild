# Tesseract needs leptonica to build and the tessdata language files to run.
set(_tesseract_depends)

# --------------------------------------------------------------------------
# leptonica
if(leptonica_DIR)
  find_package(leptonica REQUIRED NO_MODULE)
  set(PLUS_leptonica_DIR "${leptonica_DIR}" CACHE INTERNAL "Path to use as leptonica_DIR")
else()
  set(_leptonica_depends)
  if(TARGET vtk)
    set(_leptonica_depends vtk) # for vtkzlib and vtkpng
  endif()

  plus_add_external_project(leptonica
    GIT_REPOSITORY "https://github.com/PlusToolkit/leptonica.git"
    GIT_TAG master
    DEPENDS ${_leptonica_depends}
    NO_BUILD_ALWAYS
    CMAKE_CACHE_ARGS
      # leptonica declares a minimum CMake version that CMake 4 no longer accepts.
      -DCMAKE_POLICY_VERSION_MINIMUM:STRING=3.5
      -DCMAKE_PREFIX_PATH:STRING=${CMAKE_PREFIX_PATH}
      -DVTK_DIR:PATH=${PLUS_VTK_DIR}
    )
  list(APPEND _tesseract_depends leptonica)
endif()

# --------------------------------------------------------------------------
# tessdata, the trained language files
if(tessdata_DIR)
  if(NOT EXISTS "${tessdata_DIR}")
    message(FATAL_ERROR "The folder named by tessdata_DIR does not exist.")
  endif()
  set(PLUS_tessdata_src_DIR "${tessdata_DIR}" CACHE INTERNAL "Path to the tesseract language data")
else()
  plus_add_external_project(tessdata
    GIT_REPOSITORY "https://github.com/PlusToolkit/tessdata.git"
    GIT_TAG master
    SOURCE_DIR "${CMAKE_BINARY_DIR}/tessdata"
    BINARY_DIR "${CMAKE_BINARY_DIR}/tessdata"
    DOWNLOAD_ONLY
    )
  set(PLUS_tessdata_src_DIR "${PLUS_tessdata_SRC_DIR}" CACHE INTERNAL "Path to the tesseract language data")
  list(APPEND _tesseract_depends tessdata)
endif()

# --------------------------------------------------------------------------
# tesseract
if(tesseract_DIR)
  find_package(tesseract REQUIRED NO_MODULE)
  set(PLUS_tesseract_DIR "${tesseract_DIR}" CACHE INTERNAL "Path to use as tesseract_DIR")
else()
  plus_add_external_project(tesseract
    GIT_REPOSITORY "https://github.com/PlusToolkit/tesseract-ocr-cmake.git"
    GIT_TAG master
    DEPENDS ${_tesseract_depends}
    CMAKE_CACHE_ARGS
      # tesseract declares a minimum CMake version that CMake 4 no longer accepts.
      -DCMAKE_POLICY_VERSION_MINIMUM:STRING=3.5
      -DCMAKE_PREFIX_PATH:STRING=${CMAKE_PREFIX_PATH}
      -DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_BINARY_DIR}/tesseract-bin
      -DLeptonica_DIR:PATH=${PLUS_leptonica_DIR}
      -Dtesseract_DATA_DIR:PATH=${PLUS_tessdata_src_DIR}
    )
endif()
