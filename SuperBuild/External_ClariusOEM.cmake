if(ClariusOEM_DIR)
  find_package(ClariusOEM REQUIRED)
  message(STATUS "Using the Clarius OEM library available at: ${ClariusOEM_DIR}")
  plus_copy_libraries_to_runtime_dir("${CMAKE_RUNTIME_OUTPUT_DIRECTORY}" ${ClariusOEM_BINARY_PATH})

  set(Plus_ClariusOEM_DIR "${ClariusOEM_DIR}" CACHE PATH "Path to the Clarius Solum SDK")
else()
  # Prebuilt headers, import libraries and DLLs; nothing to configure or build.
  plus_add_external_project(ClariusOEM
    URL "https://github.com/clariusdev/solum/releases/download/v12.2.4/solum-12.2.4-windows.x86_64.zip"
    URL_HASH SHA256=c6061fa1f9de145c1179e7d6a8f28c3b918a8dd8ac83d3d2dd1b1c4bd8cef62a
    DOWNLOAD_ONLY
    )
  set(Plus_ClariusOEM_DIR "${PLUS_ClariusOEM_SRC_DIR}" CACHE PATH "Path to the Clarius Solum SDK" FORCE)
endif()
