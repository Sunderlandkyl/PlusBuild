# Sample and test data. Downloaded only; there is nothing to build.
plus_add_external_project(PlusLibData
  GIT_REPOSITORY "${PLUSBUILD_PLUSLIBDATA_GIT_REPOSITORY}"
  GIT_TAG "${PLUSBUILD_PLUSLIBDATA_GIT_REVISION}"
  SOURCE_DIR "${CMAKE_BINARY_DIR}/PlusLibData"
  DOWNLOAD_ONLY
  )
set(PLUSLIB_DATA_DIR "${PLUS_PlusLibData_SRC_DIR}" CACHE PATH "The directory containing PlusLib data" FORCE)
