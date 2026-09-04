# Plus 3D-printable model catalog
plus_add_external_project(PlusModelCatalog
  GIT_REPOSITORY "https://github.com/PlusToolkit/PlusModelCatalog.git"
  GIT_TAG master
  DEPENDS ${PlusModelCatalog_DEPENDENCIES}
  CMAKE_CACHE_ARGS
    -DPLUSLIB_DIR:PATH=${PLUSLIB_DIR}
    -DGIT_EXECUTABLE:FILEPATH=${GIT_EXECUTABLE}
  )
set(PlusModelCatalog_DIR "${PLUS_PlusModelCatalog_BIN_DIR}" CACHE PATH "The directory containing Plus Model Catalog generated files" FORCE)
