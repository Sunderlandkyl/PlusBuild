# Find the Tobii Interaction SDK
# This module defines
# TobiiInteractionSDK_FOUND - Tobii Interaction SDK has been found
# TobiiInteractionSDK_INCLUDE_DIR -Tobii Interaction SDK headers directory
# TobiiInteractionSDK_BINARY_DIR - Tobii Interaction SDK binary directory
# TobiiInteractionSDK_LIBRARIES - Tobii Interaction SDK libraries
#

SET(TobiiInteractionSDK_DIR "" CACHE STRING "Path to Tobii Interaction SDK directory")

IF (NOT TobiiInteractionSDK_DIR)
  MESSAGE(FATAL_ERROR "Please specify the path to the Tobii Interaction SDK in the variable TobiiInteractionSDK_DIR.")
ENDIF()

# Find include directory
FIND_FILE(_interactionLib_header InteractionLib.h PATHS ${TobiiInteractionSDK_DIR} PATH_SUFFIXES "/include/interaction_lib")
IF(NOT _interactionLib_header)
  MESSAGE(FATAL_ERROR "Failed to find InteractionLib.h. Check TobiiInteractionSDK_DIR.")
ENDIF()
GET_FILENAME_COMPONENT(TobiiInteractionSDK_INCLUDE_DIR "${_interactionLib_header}" DIRECTORY)

# List of libraries in Tobii Interaction SDK
SET(_libs tobii_interaction_lib tobii_stream_engine)
SET(TobiiInteractionSDK_LIBRARIES)

# Find libraries
FOREACH(_lib ${_libs})
  FIND_LIBRARY(_libpath ${_lib} PATHS ${TobiiInteractionSDK_DIR} PATH_SUFFIXES "lib/x64")
  IF(NOT _libpath)
    MESSAGE(FATAL_ERROR "Failed to find ${_lib} library from SDK root. Check TobiiInteractionSDK_DIR.")
  ENDIF()
  SET(TobiiInteractionSDK_LIBRARIES ${TobiiInteractionSDK_LIBRARIES} ${_libpath})
ENDFOREACH()

# Find binaries
FOREACH(_binary ${_libs})
  FIND_FILE(_found_binary ${_binary}${CMAKE_SHARED_LIBRARY_SUFFIX} PATHS ${TobiiInteractionSDK_DIR} PATH_SUFFIXES "lib/x64")
  IF(NOT _found_binary)
    MESSAGE(FATAL_ERROR "Failed to find ${_rtlib}${CMAKE_SHARED_LIBRARY_SUFFIX} runtime library from SDK root. Check TobiiInteractionSDK_DIR.")
  ENDIF()
  GET_FILENAME_COMPONENT(TobiiInteractionSDK_BINARY_DIR "${_found_binary}" DIRECTORY)
ENDFOREACH()

INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(TobiiInteractionSDK DEFAULT_MSG 
  TobiiInteractionSDK_INCLUDE_DIR
  TobiiInteractionSDK_BINARY_DIR
  TobiiInteractionSDK_LIBRARIES
  )
