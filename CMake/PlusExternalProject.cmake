# Helpers shared by the superbuild and every SuperBuild/External_*.cmake file.
#
# The External_*.cmake files were, almost without exception, the same forty
# lines of ExternalProject_Add boilerplate with a different project name. The
# functions here own that boilerplate so that a cross-cutting change (a new
# forwarded variable, RPATH settings, the offline-build shim) is made in one
# place instead of twenty.

include_guard(GLOBAL)
include(ExternalProject)

#-----------------------------------------------------------------------------
# plus_require_cxx_standard(<n> "<reason>")
#
# Raise CMAKE_CXX_STANDARD to at least <n>. Several features need a newer
# standard than the project default; each of them used to carry its own copy
# of this block.
#-----------------------------------------------------------------------------
function(plus_require_cxx_standard standard reason)
  if(CMAKE_CXX_STANDARD LESS standard)
    message(STATUS "C++${standard} is required for ${reason}, raising CMAKE_CXX_STANDARD")
    set(CMAKE_CXX_STANDARD ${standard} CACHE STRING "C++ standard" FORCE)
  endif()
endfunction()

#-----------------------------------------------------------------------------
# plus_require_feature(<option> <required_option>)
#
# Turn <required_option> on when <option> needs it, explaining why.
#-----------------------------------------------------------------------------
function(plus_require_feature option required_option)
  if(${option} AND NOT ${required_option})
    get_property(_doc CACHE ${required_option} PROPERTY HELPSTRING)
    message(STATUS "${option} requires ${required_option}, enabling it")
    set(${required_option} ON CACHE BOOL "${_doc}" FORCE)
  endif()
endfunction()

#-----------------------------------------------------------------------------
# plus_add_pluslib_args(<arg>...)
#
# Queue -D arguments to be forwarded to PlusLib's configure step. The
# External_*.cmake files and plus_find_sdk() append to this as they run;
# External_PlusLib.cmake reads the accumulated list once.
#-----------------------------------------------------------------------------
function(plus_add_pluslib_args)
  set_property(GLOBAL APPEND PROPERTY PLUSBUILD_PLUSLIB_ARGS ${ARGN})
endfunction()

function(plus_get_pluslib_args out_var)
  get_property(_args GLOBAL PROPERTY PLUSBUILD_PLUSLIB_ARGS)
  set(${out_var} "${_args}" PARENT_SCOPE)
endfunction()

#-----------------------------------------------------------------------------
# _plus_cmake_arg(<out_var> <variable name>)
#
# Format one -D<name>:<type>=<value> argument, choosing the type from the
# cache entry when there is one and from the value otherwise.
#-----------------------------------------------------------------------------
function(_plus_cmake_arg out_var name)
  get_property(_type CACHE ${name} PROPERTY TYPE)
  if(NOT _type OR _type STREQUAL "UNINITIALIZED" OR _type STREQUAL "INTERNAL" OR _type STREQUAL "STATIC")
    set(_type "")
  endif()
  if(NOT _type)
    if(IS_DIRECTORY "${${name}}")
      set(_type PATH)
    elseif(EXISTS "${${name}}")
      set(_type FILEPATH)
    else()
      set(_type STRING)
    endif()
  endif()
  set(${out_var} "-D${name}:${_type}=${${name}}" PARENT_SCOPE)
endfunction()

#-----------------------------------------------------------------------------
# plus_forward_cache_variables(<out_var>
#   [PATTERNS <regex>...] [VARIABLES <name>...] [EXCLUDE <name>...])
#
# Collect -D arguments for every cache variable matching one of PATTERNS or
# named in VARIABLES. This replaces the hand-maintained list of ~75
# -DPLUS_USE_* arguments that had to be kept in step with the options
# themselves; adding an option now only means declaring it.
#-----------------------------------------------------------------------------
function(plus_forward_cache_variables out_var)
  cmake_parse_arguments(PARSE_ARGV 1 _fwd "" "" "PATTERNS;VARIABLES;EXCLUDE")

  get_cmake_property(_all_cache_vars CACHE_VARIABLES)
  set(_selected ${_fwd_VARIABLES})
  foreach(_var IN LISTS _all_cache_vars)
    foreach(_pattern IN LISTS _fwd_PATTERNS)
      if(_var MATCHES "${_pattern}")
        list(APPEND _selected ${_var})
        break()
      endif()
    endforeach()
  endforeach()

  if(_fwd_EXCLUDE)
    list(REMOVE_ITEM _selected ${_fwd_EXCLUDE})
  endif()
  list(REMOVE_DUPLICATES _selected)
  list(SORT _selected)

  set(_args)
  foreach(_var IN LISTS _selected)
    if(DEFINED ${_var})
      _plus_cmake_arg(_arg ${_var})
      list(APPEND _args "${_arg}")
    endif()
  endforeach()
  set(${out_var} "${_args}" PARENT_SCOPE)
endfunction()

#-----------------------------------------------------------------------------
# plus_find_sdk(<option> <package>
#   [VERSION <v>] [FOUND_VAR <var>] [MESSAGE "<what it is used for>"]
#   [FORWARD <var>...] [FIND_ARGS <arg>...])
#
# Look for a vendor SDK when its option is on, fail with a consistent message
# when it is missing, and forward the variables PlusLib needs to find it.
#-----------------------------------------------------------------------------
function(plus_find_sdk option package)
  if(NOT ${option})
    return()
  endif()
  cmake_parse_arguments(PARSE_ARGV 2 _sdk "" "VERSION;FOUND_VAR;MESSAGE" "FORWARD;FIND_ARGS")

  find_package(${package} ${_sdk_VERSION} ${_sdk_FIND_ARGS})

  set(_found_var "${_sdk_FOUND_VAR}")
  if(NOT _found_var)
    set(_found_var "${package}_FOUND")
  endif()
  if(NOT ${_found_var})
    set(_purpose "")
    if(_sdk_MESSAGE)
      set(_purpose " ${_sdk_MESSAGE}")
    endif()
    message(FATAL_ERROR
      "This project requires the ${package} SDK${_purpose}. "
      "One of the components is missing. Please verify configuration or "
      "turn off ${option}.")
  endif()

  set(_args)
  foreach(_var IN LISTS _sdk_FORWARD)
    _plus_cmake_arg(_arg ${_var})
    list(APPEND _args "${_arg}")
  endforeach()
  if(_args)
    plus_add_pluslib_args(${_args})
  endif()
endfunction()

#-----------------------------------------------------------------------------
# plus_copy_libraries_to_runtime_dir(<destination> <imported target>...)
#
# Copy the imported location of each target next to the executables. On a
# multi-config generator that means one copy per configuration directory; on a
# single-config generator, one copy of the configuration being built.
#-----------------------------------------------------------------------------
function(plus_copy_libraries_to_runtime_dir destination)
  get_property(_multi_config GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)

  foreach(_lib IN LISTS ARGN)
    if(NOT TARGET ${_lib})
      continue()
    endif()
    get_target_property(_lib_type ${_lib} TYPE)
    if(_lib_type STREQUAL "INTERFACE_LIBRARY")
      continue()
    endif()

    if(_multi_config)
      set(_configs ${CMAKE_CONFIGURATION_TYPES})
    else()
      set(_configs "${CMAKE_BUILD_TYPE}")
      if(NOT _configs)
        set(_configs Release)
      endif()
    endif()

    foreach(_config IN LISTS _configs)
      string(TOUPPER "${_config}" _config_upper)
      get_target_property(_file ${_lib} IMPORTED_LOCATION_${_config_upper})
      if(NOT _file)
        # Fall back to the release build, then to a configuration-less import.
        get_target_property(_file ${_lib} IMPORTED_LOCATION_RELEASE)
      endif()
      if(NOT _file)
        get_target_property(_file ${_lib} IMPORTED_LOCATION)
      endif()
      if(_file AND EXISTS "${_file}")
        if(_multi_config)
          file(COPY "${_file}" DESTINATION "${destination}/${_config}")
        else()
          file(COPY "${_file}" DESTINATION "${destination}")
        endif()
      endif()
    endforeach()
  endforeach()
endfunction()

#-----------------------------------------------------------------------------
# plus_external_project_common_args()
#
# Compute the argument lists shared by every external project. Call once, from
# the top-level CMakeLists.txt, after the compiler and Qt have been found.
#
# Sets in the caller's scope:
#   PLUSBUILD_EP_CACHE_ARGS      -D<var>:<type>=<value> for CMAKE_CACHE_ARGS
#   PLUSBUILD_EP_OUTPUT_DIR_ARGS runtime/library/archive output directories
#   PLUSBUILD_EP_DOWNLOAD_ARGS   the offline-build shim, or nothing
#-----------------------------------------------------------------------------
macro(plus_external_project_common_args)
  get_property(PLUSBUILD_MULTI_CONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)

  # Start from the effective flags. The previous code read CMAKE_C_FLAGS_INIT,
  # which silently dropped anything the user passed on the command line.
  set(ep_common_c_flags "${CMAKE_C_FLAGS}")
  set(ep_common_cxx_flags "${CMAKE_CXX_FLAGS}")

  set(PLUSBUILD_EP_CACHE_ARGS
    -DCMAKE_C_COMPILER:FILEPATH=${CMAKE_C_COMPILER}
    -DCMAKE_CXX_COMPILER:FILEPATH=${CMAKE_CXX_COMPILER}
    -DCMAKE_C_FLAGS:STRING=${ep_common_c_flags}
    -DCMAKE_CXX_FLAGS:STRING=${ep_common_cxx_flags}
    -DCMAKE_EXE_LINKER_FLAGS:STRING=${CMAKE_EXE_LINKER_FLAGS}
    -DCMAKE_SHARED_LINKER_FLAGS:STRING=${CMAKE_SHARED_LINKER_FLAGS}
    -DCMAKE_MODULE_LINKER_FLAGS:STRING=${CMAKE_MODULE_LINKER_FLAGS}
    -DCMAKE_CXX_STANDARD:STRING=${CMAKE_CXX_STANDARD}
    -DCMAKE_CXX_STANDARD_REQUIRED:BOOL=ON
    -DCMAKE_CXX_EXTENSIONS:BOOL=OFF
    # Applies to every architecture, unlike the -fPIC that used to be added
    # only for x86_64 and so was missing on arm64 Linux and Apple silicon.
    -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=ON
    # BUILD_SHARED_LIBS and BUILD_TESTING are deliberately not set here.
    # Not every dependency wants the same answer: tesseract and leptonica are
    # built static on purpose, and PlusLib wants testing on while its
    # dependencies want it off. Each project says what it needs.
    # Keep installed binaries relocatable: look beside the executable and in
    # the sibling lib directory rather than at absolute build paths.
    # Quoted because the value is a list, and an unquoted expansion here would
    # turn each entry after the first into a separate argument.
    -DCMAKE_MACOSX_RPATH:BOOL=ON
    "-DCMAKE_INSTALL_RPATH:STRING=${PLUSBUILD_INSTALL_RPATH}"
    -DCMAKE_BUILD_WITH_INSTALL_RPATH:BOOL=OFF
    -DCMAKE_INSTALL_RPATH_USE_LINK_PATH:BOOL=OFF
    )

  # ExternalProject inherits the generator but not the build tool, so a
  # generator whose program is not on PATH has to be passed on explicitly.
  if(CMAKE_MAKE_PROGRAM)
    list(APPEND PLUSBUILD_EP_CACHE_ARGS
      -DCMAKE_MAKE_PROGRAM:FILEPATH=${CMAKE_MAKE_PROGRAM})
  endif()

  if(APPLE)
    list(APPEND PLUSBUILD_EP_CACHE_ARGS
      "-DCMAKE_OSX_ARCHITECTURES:STRING=${CMAKE_OSX_ARCHITECTURES}"
      "-DCMAKE_OSX_DEPLOYMENT_TARGET:STRING=${CMAKE_OSX_DEPLOYMENT_TARGET}"
      "-DCMAKE_OSX_SYSROOT:PATH=${CMAKE_OSX_SYSROOT}"
      )
  endif()

  if(PLUSBUILD_MULTI_CONFIG)
    list(APPEND PLUSBUILD_EP_CACHE_ARGS
      "-DCMAKE_CONFIGURATION_TYPES:STRING=${CMAKE_CONFIGURATION_TYPES}")
  else()
    list(APPEND PLUSBUILD_EP_CACHE_ARGS
      "-DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}")
  endif()

  set(PLUSBUILD_EP_OUTPUT_DIR_ARGS
    -DCMAKE_RUNTIME_OUTPUT_DIRECTORY:PATH=${CMAKE_RUNTIME_OUTPUT_DIRECTORY}
    -DCMAKE_LIBRARY_OUTPUT_DIRECTORY:PATH=${CMAKE_LIBRARY_OUTPUT_DIRECTORY}
    -DCMAKE_ARCHIVE_OUTPUT_DIRECTORY:PATH=${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}
    )

  if(PLUSBUILD_OFFLINE_BUILD)
    set(PLUSBUILD_EP_DOWNLOAD_ARGS DOWNLOAD_COMMAND "" UPDATE_COMMAND "")
  else()
    set(PLUSBUILD_EP_DOWNLOAD_ARGS)
  endif()

  # The legacy spelling is spliced into ExternalProject_Add quoted, so it can
  # never be empty: an empty argument is silently taken as another value for
  # the preceding keyword, which corrupts PREFIX and makes two steps claim the
  # same output. TIMEOUT is a harmless stand-in, since an online build does not
  # reach the download timeout.
  if(PLUSBUILD_OFFLINE_BUILD)
    set(PLUSBUILD_EXTERNAL_PROJECT_CUSTOM_COMMANDS DOWNLOAD_COMMAND "" UPDATE_COMMAND "")
  else()
    set(PLUSBUILD_EXTERNAL_PROJECT_CUSTOM_COMMANDS TIMEOUT 1000)
  endif()

  # Retained under their historical names: a user's own External_*.cmake may
  # still reference them. These go to ExternalProject_Add as CMAKE_ARGS rather
  # than CMAKE_CACHE_ARGS, where a value containing a semicolon would be split
  # into separate arguments, so drop those entries from the legacy list.
  set(ep_common_args ${PLUSBUILD_EP_CACHE_ARGS})
  list(FILTER ep_common_args EXCLUDE REGEX ";")
endmacro()

#-----------------------------------------------------------------------------
# plus_add_external_project(<name>
#   [GIT_REPOSITORY <url> [GIT_TAG <ref>] [GIT_SUBMODULES <list>]]
#   [URL <url> [URL_HASH <algo=hash>]]
#   [SOURCE_DIR <dir>] [BINARY_DIR <dir>] [PREFIX <dir>]
#   [INSTALL_DIR <dir>] [CONFIG_SUBDIR <relative path>]
#   [DEPENDS <target>...]
#   [CMAKE_CACHE_ARGS <-Dname:TYPE=value>...] [CMAKE_ARGS <arg>...]
#   [C_FLAGS <flags>] [CXX_FLAGS <flags>]
#   [NO_OUTPUT_DIRS] [NO_BUILD_ALWAYS] [DOWNLOAD_ONLY])
#
# Adds an external project with the arguments every one of them shares, and
# defines the three cache variables the rest of the superbuild looks for:
#   PLUS_<name>_SRC_DIR   where the sources were placed
#   PLUS_<name>_BIN_DIR   the build tree
#   PLUS_<name>_DIR       what a dependent should use as <name>_DIR, which is
#                         the build tree unless the project is installed
#
# Arguments are passed through CMAKE_CACHE_ARGS rather than CMAKE_ARGS: it
# keeps semicolon-separated lists intact (so LIST_SEPARATOR is not needed) and
# writes an initial cache file rather than a very long command line, which
# matters for PlusLib's hundred-odd forwarded options on Windows.
#-----------------------------------------------------------------------------
function(plus_add_external_project name)
  set(_options NO_OUTPUT_DIRS NO_BUILD_ALWAYS DOWNLOAD_ONLY)
  set(_one_value GIT_REPOSITORY GIT_TAG URL URL_HASH SOURCE_DIR BINARY_DIR
                 PREFIX INSTALL_DIR CONFIG_SUBDIR C_FLAGS CXX_FLAGS)
  set(_multi_value GIT_SUBMODULES DEPENDS CMAKE_CACHE_ARGS CMAKE_ARGS)
  cmake_parse_arguments(PARSE_ARGV 1 _ep "${_options}" "${_one_value}" "${_multi_value}")

  if(_ep_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "plus_add_external_project(${name}): unexpected arguments: ${_ep_UNPARSED_ARGUMENTS}")
  endif()

  # --- Directory layout -----------------------------------------------------
  set(_source_dir "${_ep_SOURCE_DIR}")
  if(NOT _source_dir)
    set(_source_dir "${CMAKE_BINARY_DIR}/${name}")
  endif()
  set(_binary_dir "${_ep_BINARY_DIR}")
  if(NOT _binary_dir)
    set(_binary_dir "${CMAKE_BINARY_DIR}/${name}-bin")
  endif()
  set(_prefix_dir "${_ep_PREFIX}")
  if(NOT _prefix_dir)
    set(_prefix_dir "${CMAKE_BINARY_DIR}/${name}-prefix")
  endif()

  # --- Where the sources come from -----------------------------------------
  set(_download_args)
  if(_ep_GIT_REPOSITORY)
    set(_git_tag "${_ep_GIT_TAG}")
    if(NOT _git_tag)
      set(_git_tag master)
    endif()
    list(APPEND _download_args GIT_REPOSITORY "${_ep_GIT_REPOSITORY}" GIT_TAG "${_git_tag}")
    if(DEFINED _ep_GIT_SUBMODULES)
      # An empty list means "no submodules" and relies on CMP0097 being NEW.
      list(APPEND _download_args GIT_SUBMODULES "${_ep_GIT_SUBMODULES}")
    endif()
    message(STATUS "${name} repository: ${_ep_GIT_REPOSITORY} (${_git_tag})")
  elseif(_ep_URL)
    list(APPEND _download_args URL "${_ep_URL}")
    if(_ep_URL_HASH)
      list(APPEND _download_args URL_HASH "${_ep_URL_HASH}")
    endif()
    message(STATUS "${name} package: ${_ep_URL}")
  endif()

  # --- Configure/build/install arguments -----------------------------------
  set(_cache_args ${PLUSBUILD_EP_CACHE_ARGS})
  if(_ep_C_FLAGS)
    list(FILTER _cache_args EXCLUDE REGEX "^-DCMAKE_C_FLAGS:")
    list(APPEND _cache_args "-DCMAKE_C_FLAGS:STRING=${ep_common_c_flags} ${_ep_C_FLAGS}")
  endif()
  if(_ep_CXX_FLAGS)
    list(FILTER _cache_args EXCLUDE REGEX "^-DCMAKE_CXX_FLAGS:")
    list(APPEND _cache_args "-DCMAKE_CXX_FLAGS:STRING=${ep_common_cxx_flags} ${_ep_CXX_FLAGS}")
  endif()
  if(NOT _ep_NO_OUTPUT_DIRS)
    list(APPEND _cache_args ${PLUSBUILD_EP_OUTPUT_DIR_ARGS})
  endif()

  # A step is disabled by giving it an empty command, but an empty string
  # cannot travel through a variable: unquoted list expansion drops it, and
  # ExternalProject would then fall back to running the step. Use a command
  # that does nothing instead.
  set(_no_op ${CMAKE_COMMAND} -E true)

  set(_install_dir "${_ep_INSTALL_DIR}")
  if(_install_dir)
    list(APPEND _cache_args "-DCMAKE_INSTALL_PREFIX:PATH=${_install_dir}")
    set(_install_args INSTALL_DIR "${_install_dir}")
  else()
    set(_install_args INSTALL_COMMAND ${_no_op})
  endif()

  list(APPEND _cache_args ${_ep_CMAKE_CACHE_ARGS})

  set(_step_args)
  if(_ep_DOWNLOAD_ONLY)
    set(_step_args CONFIGURE_COMMAND ${_no_op} BUILD_COMMAND ${_no_op})
    set(_install_args INSTALL_COMMAND ${_no_op})
    set(_cache_args "")
  elseif(NOT _ep_NO_BUILD_ALWAYS)
    set(_step_args BUILD_ALWAYS 1)
  endif()

  # ExternalProject writes these into an initial cache file as
  #   set(NAME "VALUE" CACHE TYPE ...)
  # and does not escape the value, so a Windows path is read back with its
  # backslashes taken as escape sequences and rejected. Doubling them here
  # makes the value survive that parse unchanged.
  set(_cmake_cache_args)
  if(_cache_args)
    set(_escaped_cache_args)
    foreach(_arg IN LISTS _cache_args)
      string(REPLACE "\\" "\\\\" _arg "${_arg}")
      list(APPEND _escaped_cache_args "${_arg}")
    endforeach()
    set(_cmake_cache_args CMAKE_CACHE_ARGS ${_escaped_cache_args})
  endif()
  set(_cmake_args)
  if(_ep_CMAKE_ARGS)
    set(_cmake_args CMAKE_ARGS ${_ep_CMAKE_ARGS})
  endif()

  ExternalProject_Add(${name}
    PREFIX "${_prefix_dir}"
    SOURCE_DIR "${_source_dir}"
    BINARY_DIR "${_binary_dir}"
    ${_download_args}
    ${PLUSBUILD_EP_DOWNLOAD_ARGS}
    ${_cmake_cache_args}
    ${_cmake_args}
    ${_step_args}
    ${_install_args}
    DEPENDS ${_ep_DEPENDS}
    )

  # --- Results the rest of the superbuild consumes -------------------------
  set(_result_dir "${_binary_dir}")
  if(_install_dir AND _ep_CONFIG_SUBDIR)
    set(_result_dir "${_install_dir}/${_ep_CONFIG_SUBDIR}")
  elseif(_install_dir)
    set(_result_dir "${_install_dir}")
  endif()

  set(PLUS_${name}_SRC_DIR "${_source_dir}" CACHE INTERNAL "Path to ${name} sources")
  set(PLUS_${name}_BIN_DIR "${_binary_dir}" CACHE INTERNAL "Path to ${name} binaries")
  set(PLUS_${name}_PREFIX_DIR "${_prefix_dir}" CACHE INTERNAL "Path to ${name} prefix data")
  set(PLUS_${name}_DIR "${_result_dir}" CACHE INTERNAL "Path to use as ${name}_DIR")
  if(_install_dir)
    set(PLUS_${name}_INSTALL_DIR "${_install_dir}" CACHE INTERNAL "Path ${name} is installed to")
  endif()
endfunction()
