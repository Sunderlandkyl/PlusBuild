cmake_minimum_required(VERSION 3.20...4.0)

project(PlusBuild LANGUAGES C CXX)

list(APPEND CMAKE_MODULE_PATH
  "${CMAKE_CURRENT_SOURCE_DIR}/Modules"
  "${CMAKE_CURRENT_SOURCE_DIR}/CMake"
  )

include(PlusBuildMacros)
include(PlusExternalProject)

# CMP0097: an empty GIT_SUBMODULES list means "no submodules", which is how
# PlusLib's optional PlusDoc submodule is controlled.
cmake_policy(SET CMP0097 NEW)

#-----------------------------------------------------------------------------
# C++ standard
#
# Individual features raise this further; see the plus_require_cxx_standard()
# calls below. ITK 5 needs C++17 and is always built, so 17 is the effective
# floor in practice.
#-----------------------------------------------------------------------------
if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 17 CACHE STRING "C++ standard")
endif()
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
message(STATUS "Building against C++${CMAKE_CXX_STANDARD}")

if(PLUS_USE_CLARIUS_OEM)
  # The Clarius OEM device reaches the probe over Bluetooth LE through C++/WinRT.
  plus_require_cxx_standard(17 "the Clarius OEM device")
endif()

#-----------------------------------------------------------------------------
# Where the built libraries end up
#-----------------------------------------------------------------------------
if(NOT CMAKE_RUNTIME_OUTPUT_DIRECTORY)
  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
endif()
if(NOT CMAKE_LIBRARY_OUTPUT_DIRECTORY)
  set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
endif()
if(NOT CMAKE_ARCHIVE_OUTPUT_DIRECTORY)
  set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
endif()

#-----------------------------------------------------------------------------
# Run-time library search path
#
# Everything Plus builds has to keep working once the package is unpacked
# somewhere other than the build machine, so binaries look beside themselves
# and in the sibling lib directory rather than at absolute build paths.
#-----------------------------------------------------------------------------
if(APPLE)
  set(CMAKE_MACOSX_RPATH ON)
  set(PLUSBUILD_INSTALL_RPATH "@executable_path/../lib;@loader_path/../lib;@loader_path")
elseif(UNIX)
  set(PLUSBUILD_INSTALL_RPATH "$ORIGIN/../lib;$ORIGIN")
  # DT_RPATH rather than DT_RUNPATH. A library that carries DT_RUNPATH is
  # resolved from that alone: the loader stops consulting the DT_RPATH of the
  # executable that pulled it in. libvtkIGSIOCommon came out with a DT_RUNPATH
  # naming the build machine's vtk-install directory, so in an unpacked package
  # it looked for libvtkIOImage where nothing was, and would not fall back to
  # the "$ORIGIN/../lib" beside it.
  #
  # The flag goes into the compiler flags as well as the linker flags because
  # the compiler flags are what reaches a nested superbuild. IGSIO forwards
  # CMAKE_C_FLAGS and CMAKE_CXX_FLAGS to its inner build and nothing else, and
  # a compiler driver hands -Wl, options to the linker at link time and ignores
  # them when only compiling.
  foreach(_flags CMAKE_EXE_LINKER_FLAGS CMAKE_SHARED_LINKER_FLAGS CMAKE_MODULE_LINKER_FLAGS
                 CMAKE_C_FLAGS CMAKE_CXX_FLAGS)
    if(NOT "${${_flags}}" MATCHES "disable-new-dtags")
      string(APPEND ${_flags} " -Wl,--disable-new-dtags")
    endif()
  endforeach()
else()
  set(PLUSBUILD_INSTALL_RPATH "")
endif()
set(CMAKE_INSTALL_RPATH "${PLUSBUILD_INSTALL_RPATH}")
set(CMAKE_BUILD_WITH_INSTALL_RPATH OFF)
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH OFF)

#-----------------------------------------------------------------------------
# Build architecture and platform defaults
#-----------------------------------------------------------------------------
set(BUILD_ARCHITECTURE "x64")
if(CMAKE_SIZEOF_VOID_P EQUAL 4)
  set(BUILD_ARCHITECTURE "x86")
endif()

set(ENABLED_BY_DEFAULT_ON_WINDOWS_ONLY OFF)
set(ENABLED_BY_DEFAULT_ON_WINDOWS32_ONLY OFF)
set(ENABLED_BY_DEFAULT_ON_WINDOWS64_ONLY OFF)
if(CMAKE_HOST_WIN32)
  set(ENABLED_BY_DEFAULT_ON_WINDOWS_ONLY ON)
  if(BUILD_ARCHITECTURE MATCHES "x86")
    set(ENABLED_BY_DEFAULT_ON_WINDOWS32_ONLY ON)
  else()
    set(ENABLED_BY_DEFAULT_ON_WINDOWS64_ONLY ON)
  endif()
endif()

# The architecture of the machine doing the building, as opposed to the one
# being built for. This used to be read from Windows-only environment
# variables, so it silently reported x64 everywhere else.
set(HOST_ARCHITECTURE "x64")
if(CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "^(i.86|x86|X86)$")
  set(HOST_ARCHITECTURE "x86")
endif()

#-----------------------------------------------------------------------------
# Superbuild options
#-----------------------------------------------------------------------------
# VTK and ITK are installed rather than used from their build trees so that
# their shared libraries can be collected into a relocatable package. This
# defaulted to ON only for MSVC, which left packaging on Linux and macOS
# pointing at a build tree that has no install layout.
option(PLUSBUILD_INSTALL_VTK "Install VTK into the build tree so that it can be packaged" ON)
option(PLUSBUILD_INSTALL_ITK "Install ITK into the build tree so that it can be packaged" ON)

option(PLUSBUILD_OFFLINE_BUILD "Build Plus without an internet connection. All libraries must be downloaded and updated manually." OFF)
mark_as_advanced(PLUSBUILD_OFFLINE_BUILD)

option(PLUSBUILD_USE_3DSlicer "Instead of building ITK, VTK, OpenIGTLink, etc., get them from a 3D Slicer build tree." OFF)
mark_as_advanced(PLUSBUILD_USE_3DSlicer)
option(PLUSBUILD_USE_OpenIGTLink "Use OpenIGTLink" ON)
option(PLUSBUILD_BUILD_SHARED_LIBS "Build shared libraries instead of statically-linked libraries" ON)
option(PLUSBUILD_BUILD_PLUSAPP "Build PlusApp applications" ON)
option(PLUSBUILD_BUILD_PLUSLIB_WIDGETS "Build PlusLib widgets (required Qt)" ON)
option(PLUSBUILD_BUILD_PlusLib_TOOLS "Build the PlusLib tools (PlusServer, PlusServerRemoteControl...)" ON)
option(PLUSBUILD_BUILD_PLUSMODELCATALOG "Build Plus 3D printable model catalog" OFF)
option(PLUSBUILD_USE_Tesseract "Use OCR in PlusLib for recognizing ultrasound imaging parameters by reading text from grabbed images." OFF)
option(PLUSBUILD_USE_OpenCV "Use OpenCV for optical marker tracking and other features." OFF)
option(PLUSBUILD_USE_aruco "Use aruco for optical marker tracking." OFF)
option(PLUSBUILD_DOWNLOAD_PLUSLIBDATA "Download sample and test data. Required for automatic tests." ON)
option(PLUSBUILD_PLUSLIB_DOCUMENTATION "Clone the PlusDoc submodule in PlusLib" ON)

#-----------------------------------------------------------------------------
# Git, and the developer commit hooks
#-----------------------------------------------------------------------------
if(NOT PLUSBUILD_OFFLINE_BUILD)
  find_package(Git REQUIRED)
endif()

if(Git_FOUND)
  get_filename_component(_git_directory "${GIT_EXECUTABLE}" DIRECTORY)
endif()
set(_x86env "ProgramFiles(x86)")
find_program(BASH_EXECUTABLE bash
  HINTS
    "${_git_directory}"
    "$ENV{ProgramFiles}/Git/bin"
    "$ENV{${_x86env}}/Git/bin"
  )
mark_as_advanced(BASH_EXECUTABLE)
if(BASH_EXECUTABLE AND Git_FOUND AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/.git")
  execute_process(
    COMMAND "${BASH_EXECUTABLE}" -c "cd '${CMAKE_SOURCE_DIR}' && ./Utilities/SetupForDevelopment.sh copyOnly"
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    OUTPUT_VARIABLE _bash_output
    ERROR_VARIABLE _bash_output
    RESULT_VARIABLE _bash_result
    )
  if(NOT _bash_result EQUAL 0)
    message(STATUS "Could not install the development hooks: ${_bash_output}")
  endif()
endif()

#-----------------------------------------------------------------------------
# Documentation
#-----------------------------------------------------------------------------
option(PLUSBUILD_DOCUMENTATION "Build Plus documentation (Doxygen)." OFF)
if(PLUSBUILD_DOCUMENTATION)
  # CMake's Doxygen finder only looks in some obsolete Windows locations for
  # Graphviz. Parentheses are not allowed in a variable name, hence the
  # PROGRAMFILESX86 indirection.
  set(PROGRAMFILESX86 "ProgramFiles(x86)")
  find_program(DOXYGEN_DOT_EXECUTABLE
    NAMES dot
    PATHS
      "$ENV{ProgramFiles}/Graphviz2.38/bin"
      "$ENV{${PROGRAMFILESX86}}/Graphviz2.38/bin"
      "$ENV{ProgramFiles}/Graphviz2.34/bin"
      "$ENV{${PROGRAMFILESX86}}/Graphviz2.34/bin"
    DOC "Graphviz Dot tool for using Doxygen"
    NO_SYSTEM_ENVIRONMENT_PATH
    )
  find_package(Doxygen REQUIRED)

  if(NOT DOXYGEN_DOT_FOUND)
    message(FATAL_ERROR "Documentation: Graphviz dot tool not found (http://www.graphviz.org/Download.php, required by Doxygen for diagram generation). Either specify location of dot or disable PLUSBUILD_DOCUMENTATION.")
  endif()

  option(PLUSBUILD_DOCUMENTATION_SEARCH_SERVER_INDEXED "Search index for documentation is generated by the web server. Provides full-text search but only works on web servers." OFF)
  mark_as_advanced(PLUSBUILD_DOCUMENTATION_SEARCH_SERVER_INDEXED)

  set(PLUSBUILD_DOCUMENTATION_GOOGLE_ANALYTICS_TRACKING_ID "" CACHE STRING "Tracking ID used for reporting documentation usage to Google Analytics. Only usable on web servers. If left empty, Google Analytics will not be included in the documentation HTML.")
  mark_as_advanced(PLUSBUILD_DOCUMENTATION_GOOGLE_ANALYTICS_TRACKING_ID)
endif()

#-----------------------------------------------------------------------------
# Imaging hardware
#-----------------------------------------------------------------------------
option(PLUS_USE_ULTRASONIX_VIDEO "Provide support for the Ultrasonix ultrasound systems" OFF)
if(PLUS_USE_ULTRASONIX_VIDEO)
  set(PLUS_ULTRASONIX_SDK_MAJOR_VERSION 5 CACHE STRING "Set Ultrasonix SDK major version (version: [major].[minor].[patch])")
  set(PLUS_ULTRASONIX_SDK_MINOR_VERSION 7 CACHE STRING "Set Ultrasonix SDK minor version (version: [major].[minor].[patch])")
  set(PLUS_ULTRASONIX_SDK_PATCH_VERSION 4 CACHE STRING "Set Ultrasonix SDK patch version (version: [major].[minor].[patch])")
  option(PLUS_TEST_ULTRASONIX "Enable testing of acquisition from Ultrasonix ultrasound systems. Enable this only if an Ultrasonix device accessible from this computer. " OFF)
  if(PLUS_TEST_ULTRASONIX)
    set(PLUS_TEST_ULTRASONIX_IP_ADDRESS "130.15.7.24" CACHE STRING "IP address of the Ultrasonix scanner that is used during testing")
  endif()
endif()

option(PLUS_USE_BKPROFOCUS_VIDEO "Provide support for BK ProFocus ultrasound systems through the OEM (TCP/IP) interface" OFF)
if(PLUS_USE_BKPROFOCUS_VIDEO)
  option(PLUS_USE_BKPROFOCUS_CAMERALINK "Enable acquisition from BK ProFocus ultrasound systems through CameraLink interface" OFF)
  option(PLUS_TEST_BKPROFOCUS "Enable testing of acquisition from BK ProFocus ultrasound systems. Enable this only if a BK ProFocus device is connected to this computer. " OFF)
endif()
if(PLUS_USE_BKPROFOCUS_CAMERALINK AND NOT PLUS_USE_BKPROFOCUS_VIDEO)
  message(FATAL_ERROR "PLUS_USE_BKPROFOCUS_VIDEO must be enabled if the PLUS_USE_BKPROFOCUS_CAMERALINK option is enabled")
endif()
if(PLUS_USE_BKPROFOCUS_CAMERALINK AND NOT BUILD_ARCHITECTURE MATCHES "x64" AND HOST_ARCHITECTURE MATCHES "x64")
  message(WARNING "BK ProFocus support on a 64-bit OS requires a 64-bit Plus build. Compilation will succeed, but the resulting executables will fail to start.")
endif()

option(PLUS_USE_ICCAPTURING_VIDEO "Provide support for the IC framegrabber device" OFF)
option(PLUS_USE_MMF_VIDEO "Provide support for the Microsoft Media Foundation video digitizers (requires installation of Windows Platform SDK 7.1 or later)" OFF)
if(PLUS_USE_MMF_VIDEO)
  option(PLUS_TEST_MMF_VIDEO "Enable testing of acquisition from MMF video device (webcam). Enable this only if an MMF device is connected to this computer." OFF)
endif()
option(PLUS_USE_EPIPHAN "Provide support for the Epiphan framegrabber device" OFF)
option(PLUS_USE_CAPISTRANO_VIDEO "Provide support for the Capistrano Labs USB ultrasound probes" OFF)
option(PLUS_USE_WINPROBE_VIDEO "Provide support WinProbe ultrasound systems" OFF)
option(PLUS_USE_INTERSON_VIDEO "Provide support for the Interson USB ultrasound probes" OFF)
option(PLUS_USE_INTERSONSDKCXX_VIDEO "Provide support for the Interson SDK 1.X with C++ Wrapper USB ultrasound probes" OFF)
option(PLUS_USE_INTERSONARRAYSDKCXX_VIDEO "Provide support for the Interson Array SDK with C++ Wrapper USB ultrasound probes" OFF)
option(PLUS_USE_TELEMED_VIDEO "Provide support for the Telemed ultrasound probes" OFF)
option(PLUS_USE_AGILENT "Provide support for the Agilent digitizer device" OFF)
if(PLUS_USE_TELEMED_VIDEO)
  option(PLUS_TEST_TELEMED "Enable testing of acquisition from Telemed ultrasound systems. Enable this only if a Telemed device is connected to this computer. " OFF)
endif()
option(PLUS_USE_THORLABS_VIDEO "Provide support for the ThorLabs Compact Spectrometers" OFF)
option(PLUS_USE_OpenCV_VIDEO "Provide support for capturing an OpenCV capture stream" OFF)
option(PLUS_USE_INFRARED_SEEK_CAM "Provide support for capturing an Infrared Seek Camera capture stream" OFF)
option(PLUS_USE_INFRARED_TEQ1_CAM "Provide support for capturing an Infrared Therma Expert Q1 Camera capture stream" OFF)
option(PLUS_USE_INFRARED_TEEV2_CAM "Provide support for capturing an Infrared Therma Expert EV2 Camera capture stream" OFF)
option(PLUS_USE_ULTRAVIOLET_PCOUV_CAM "Provide support for capturing an PCO Ultraviolet Camera capture stream" OFF)
option(PLUS_USE_DAQVIDEOSOURCE "Provide support for capturing an CameraLink Camera using DAQ System USB3-FRM13-B Grabber" OFF)
option(PLUS_USE_PHILIPS_3D_ULTRASOUND "Provide support for the Philips ie33 3D ultrasound probe" OFF)
if(PLUS_USE_PHILIPS_3D_ULTRASOUND)
  option(PLUS_TEST_PHILIPS_3D_ULTRASOUND "Enable testing of acquisition from Philips 3D ultrasound systems. Enable this only if a Philips device is accessible from this computer. " OFF)
  if(PLUS_TEST_PHILIPS_3D_ULTRASOUND)
    set(PLUS_TEST_PHILIPS_3D_ULTRASOUND_IP_ADDRESS "129.100.44.8" CACHE STRING "IP address of the Philips scanner that is used during testing")
  endif()
endif()
option(PLUS_USE_CLARIUS "Provide support for Clarius Ultrasound devices via the Listen API" OFF)
option(PLUS_USE_CLARIUS_OEM "Provide support for Clarius OEM SDK interface to Clarius Ultrasound devices." OFF)
option(PLUS_USE_ANDOR_CAMERA "Provide support for the Andor cameras capture stream" OFF)

#-----------------------------------------------------------------------------
# Tracking hardware
#-----------------------------------------------------------------------------
option(PLUS_USE_OPTITRACK "Provide support for the OptiTrack tracking system" OFF)
option(PLUS_USE_OPTIMET_CONOPROBE "Provide support for the Optimet ConoProbe" OFF)
option(PLUS_USE_NDI "Provide support for the NDI POLARIS and AURORA" OFF)
option(PLUS_USE_NDI_CERTUS "Provide support for the NDI Certus" OFF)

option(PLUS_USE_POLARIS "Provide support for the NDI POLARIS and AURORA" OFF)
mark_as_advanced(PLUS_USE_POLARIS)
option(PLUS_USE_CERTUS "Provide support for the NDI Certus" OFF)
mark_as_advanced(PLUS_USE_CERTUS)
if(PLUS_USE_POLARIS)
  message(STATUS "PLUS_USE_POLARIS has been deprecated. Changing to PLUS_USE_NDI instead.")
  set(PLUS_USE_POLARIS OFF CACHE BOOL "Provide support for the NDI POLARIS and AURORA" FORCE)
  set(PLUS_USE_NDI ON CACHE BOOL "Provide support for the NDI POLARIS and AURORA" FORCE)
endif()
if(PLUS_USE_CERTUS)
  message(STATUS "PLUS_USE_CERTUS has been deprecated. Changing to PLUS_USE_NDI_CERTUS instead.")
  set(PLUS_USE_CERTUS OFF CACHE BOOL "Provide support for the NDI Certus" FORCE)
  set(PLUS_USE_NDI_CERTUS ON CACHE BOOL "Provide support for the NDI Certus" FORCE)
endif()

option(PLUS_USE_MICRONTRACKER "Provide support for the Claron MicronTracker" OFF)
option(PLUS_USE_INTELREALSENSE "Provide support for Intel RealSense cameras" OFF)
option(PLUS_USE_ATRACSYS "Provide support for Atracsys optical trackers" OFF)
option(PLUS_USE_SPINNAKER_VIDEO "Provide support for Point Grey Spinnaker API compatible imaging devices" OFF)
option(PLUS_USE_OPTICAL_MARKER_TRACKER "Provide support of tracking of markers (2D barcodes) in image streams using ArUco and OpenCV." OFF)
option(PLUS_USE_BRACHY_TRACKER "Provide support for the Brachy Steppers" ${ENABLED_BY_DEFAULT_ON_WINDOWS32_ONLY})
option(PLUS_USE_USDIGITALENCODERS_TRACKER "Provide support for multiple USDigital encoders tracking device" ${ENABLED_BY_DEFAULT_ON_WINDOWS32_ONLY})
option(PLUS_USE_Ascension3DG "Provide support for the Ascension 3DG Tracker" ${ENABLED_BY_DEFAULT_ON_WINDOWS32_ONLY})
option(PLUS_USE_Ascension3DGm "Provide support for the Ascension MedSafe Tracker" OFF)
option(PLUS_USE_PHIDGET_SPATIAL_TRACKER "Provide support for the Phidget Spatial accelerometer" OFF)
option(PLUS_USE_3dConnexion_TRACKER "Provide support for the 3dConnexion 3d mouse" OFF)
option(PLUS_USE_STEALTHLINK "Provide support for the Medtronick StealthLink Server" OFF)
option(PLUS_USE_IntuitiveDaVinci "Provide support for the da Vinci Surgical System" OFF)
option(PLUS_USE_OvrvisionPro "Provide support for the OvrvisionPro Stereo Camera" OFF)
if(PLUS_USE_OvrvisionPro)
  option(PLUS_TEST_OvrvisionPro "Enable testing of acquisition of stereo images from the OvrvisionPro" OFF)
endif()
option(PLUS_USE_OPENHAPTICS "Provide support of OpenHaptics devices" OFF)
option(PLUS_USE_WITMOTIONTRACKER "Provide support for the WitMotion IMU Trackers" OFF)
option(PLUS_USE_LEAPMOTION "Provide support for the LeapMotion hand tracker" OFF)
if(PLUS_USE_LEAPMOTION)
  option(PLUS_TEST_LEAPMOTION "Enable testing of LeapMotion device" OFF)
endif()
option(PLUS_USE_BLACKMAGIC_DECKLINK "Provide support for BlackMagic DeckLink capture cards." OFF)
option(PLUS_USE_STEAMVR "Provide support for SteamVR tracking system" OFF)
option(PLUS_USE_PICOSCOPE "Provide support for PicoScope 2xxx series oscilloscopes" OFF)
option(PLUS_USE_GENERIC_SENSOR_TRACKER "Provide support for generic sensor data collection" OFF)
option(PLUS_USE_AZUREKINECT "Provide support for Azure Kinect cameras" OFF)
option(PLUS_USE_REVOPOINT3DCAMERA "Provide support for Revopoint 3D cameras" OFF)

#-----------------------------------------------------------------------------
# Other devices and features
#-----------------------------------------------------------------------------
option(PLUS_USE_TextRecognizer "Enable the text recognizer virtual device" OFF)
option(PLUS_USE_NVIDIA_DVP "Provide support for the NVidia Digital Video Pipeline" OFF)
option(PLUS_USE_MKV_IO "Enable reading/writing MKV files using libwebm." OFF)

if(UNIX AND NOT APPLE)
  option(PLUS_USE_V4L2 "Provide support for video4linux devices" OFF)
endif()

option(PLUS_ENABLE_VIDEOSTREAMING "Provide support for streaming compressed video from Plus" OFF)
option(PLUS_USE_VP9 "Compile OpenIGTLink with VP9 support for compressed video streaming" OFF)
plus_require_feature(PLUS_USE_VP9 PLUS_ENABLE_VIDEOSTREAMING)

set(PLUSBUILD_VTK_RENDERING_BACKEND "OpenGL2" CACHE STRING "Choose the rendering backend. OpenGL2 is only compatible with more recent graphics cards and does not work on embedded systems like Ultrasonix Windows XPe based systems.")
set_property(CACHE PLUSBUILD_VTK_RENDERING_BACKEND PROPERTY STRINGS "None" "OpenGL2")

option(PLUSAPP_TEST_GUI "Enable GUI tests" ON)

option(PLUS_TEST_HIGH_ACCURACY_TIMING "Enable testing of high-accuracy timing. High-accuracy timing may not be available on virtual machines and so testing may be turned off to avoid false alarams." ON)
mark_as_advanced(PLUS_TEST_HIGH_ACCURACY_TIMING)

set(PLUSAPP_PACKAGE_EDITION "" CACHE STRING "Specifies a name that refers to the combination of hardware devices the created install package supports. The name is added to the package filename.")

#-----------------------------------------------------------------------------
# Features that imply other features
#-----------------------------------------------------------------------------
plus_require_feature(PLUS_USE_TextRecognizer PLUSBUILD_USE_Tesseract)
plus_require_feature(PLUS_USE_OvrvisionPro PLUSBUILD_USE_OpenCV)
plus_require_feature(PLUS_USE_OpenCV_VIDEO PLUSBUILD_USE_OpenCV)
plus_require_feature(PLUS_USE_INFRARED_SEEK_CAM PLUSBUILD_USE_OpenCV)
plus_require_feature(PLUS_USE_ANDOR_CAMERA PLUSBUILD_USE_OpenCV)
plus_require_feature(PLUS_USE_CLARIUS PLUSBUILD_USE_OpenCV)
plus_require_feature(PLUS_USE_OPTICAL_MARKER_TRACKER PLUSBUILD_USE_OpenCV)
plus_require_feature(PLUS_USE_OPTICAL_MARKER_TRACKER PLUSBUILD_USE_aruco)

#-----------------------------------------------------------------------------
# Incompatible combinations
#-----------------------------------------------------------------------------
if(NOT PLUS_USE_STEALTHLINK AND NOT CMAKE_CXX_STANDARD MATCHES "^(14|17|20)$")
  message(FATAL_ERROR "CMAKE_CXX_STANDARD must be set to 14, 17 or 20")
endif()

if(MSVC)
  # 1600 = VS 2010, 1800 = VS 2013, 1914 = VS 2017 15.7, the first release
  # Microsoft announced as conforming to C++11/14/17.
  if(PLUS_USE_STEALTHLINK)
    if(NOT MSVC_VERSION MATCHES "^(1800|1600)$")
      message(FATAL_ERROR "SteathLink compatibility requires Visual Studio 2013 or 2010.")
    endif()
  elseif(MSVC_VERSION VERSION_LESS 1914)
    message(FATAL_ERROR "Microsoft Visual C/C++ toolset 141 (VS 15.7) or newer is required!")
  endif()
endif()

if(PLUS_USE_Ascension3DG AND PLUS_USE_Ascension3DGm)
  message(FATAL_ERROR "PLUS_USE_Ascension3DG and PLUS_USE_Ascension3DGm options cannot be enabled at the same time. See more details at https://www.assembla.com/spaces/plus/tickets/851")
endif()

if(PLUS_USE_CLARIUS_OEM AND NOT WIN32)
  message(FATAL_ERROR "The Clarius OEM device is only available on Windows. Use Windows to compile Plus, or set PLUS_USE_CLARIUS_OEM to OFF.")
endif()

if(PLUS_USE_PHILIPS_3D_ULTRASOUND)
  if(NOT CMAKE_HOST_WIN32)
    message(FATAL_ERROR "The Philips SDK is only available for Windows.")
  endif()
  if(PLUS_USE_ULTRASONIX_VIDEO)
    # Ultrasonix ships its own libmmd.dll, which lacks functionality the
    # Philips probe needs.
    message(FATAL_ERROR "Plus cannot enable both the Ultrasonix and Philips devices because of .dll conflicts between their SDK packages.")
  endif()
endif()

#-----------------------------------------------------------------------------
# Which revision of PlusLib, PlusApp and PlusLibData to build
#-----------------------------------------------------------------------------
set(PLUSLIB_GIT_REPOSITORY "https://github.com/PlusToolkit/PlusLib.git" CACHE STRING "Set PlusLib desired git url")
set(PLUSLIB_GIT_REVISION "master" CACHE STRING "Set PlusLib desired git hash (master means latest)")
set(PLUSAPP_GIT_REPOSITORY "https://github.com/PlusToolkit/PlusApp.git" CACHE STRING "Set PlusApp desired git url")
set(PLUSAPP_GIT_REVISION "master" CACHE STRING "Set PlusApp desired git hash (master means latest)")
mark_as_advanced(PLUSLIB_GIT_REPOSITORY PLUSLIB_GIT_REVISION PLUSAPP_GIT_REPOSITORY PLUSAPP_GIT_REVISION)

if(PLUSBUILD_DOWNLOAD_PLUSLIBDATA)
  set(PLUSBUILD_PLUSLIBDATA_GIT_REPOSITORY "https://github.com/PlusToolkit/PlusLibData.git" CACHE STRING "Set PlusLibData desired git url.")
  set(PLUSBUILD_PLUSLIBDATA_GIT_REVISION "master" CACHE STRING "Set PlusLibData desired git hash (master means latest).")
  mark_as_advanced(PLUSBUILD_PLUSLIBDATA_GIT_REPOSITORY PLUSBUILD_PLUSLIBDATA_GIT_REVISION)
endif()

#-----------------------------------------------------------------------------
# Arguments shared by every external project
#-----------------------------------------------------------------------------
plus_external_project_common_args()

#-----------------------------------------------------------------------------
# 3D Slicer, when its build tree supplies VTK, ITK and OpenIGTLink
#-----------------------------------------------------------------------------
if(PLUSBUILD_USE_3DSlicer)
  set(PLUSBUILD_SLICER_BIN_DIRECTORY "PLUSBUILD_SLICER_BIN_DIRECTORY-NOT-FOUND" CACHE PATH "Path to 3D Slicer binary directory")
  if(PLUSBUILD_SLICER_BIN_DIRECTORY STREQUAL "PLUSBUILD_SLICER_BIN_DIRECTORY-NOT-FOUND")
    message(FATAL_ERROR "Cannot use 3D Slicer if PLUSBUILD_SLICER_BIN_DIRECTORY is not defined.")
  endif()

  # The Slicer config file complains if these are set.
  unset(VTK_DIR CACHE)
  unset(ITK_DIR CACHE)

  find_package(Slicer PATHS "${PLUSBUILD_SLICER_BIN_DIRECTORY}" NO_DEFAULT_PATH QUIET)
  if(NOT Slicer_FOUND)
    message(FATAL_ERROR "Unable to find Slicer in ${PLUSBUILD_SLICER_BIN_DIRECTORY}. Please verify configuration.")
  endif()
  set(Slicer_SKIP_EXTENSION_NAME_CHECK TRUE)
  include(${Slicer_USE_FILE})
endif()

#-----------------------------------------------------------------------------
# Qt
#-----------------------------------------------------------------------------
set(ep_qt_args)
# XmlPatterns is deliberately absent: nothing in Plus uses it, and it is a
# separate Qt module that several distributions do not ship.
set(PLUSBUILD_QT_COMPONENTS Core Widgets Designer OpenGL Sql Test Xml Concurrent Network Gui)
if(PLUS_USE_OPTITRACK)
  list(APPEND PLUSBUILD_QT_COMPONENTS Multimedia)
endif()

if(PLUSBUILD_BUILD_PLUSAPP OR PLUSBUILD_BUILD_PLUSLIB_WIDGETS)
  find_package(Qt5 COMPONENTS ${PLUSBUILD_QT_COMPONENTS} QUIET)
  if(NOT Qt5_FOUND)
    message(FATAL_ERROR "This project requires Qt5 for building PlusApp but Qt was not found. Please specify Qt5_DIR or turn off PLUSBUILD_BUILD_PLUSAPP/PLUSBUILD_BUILD_PLUSLIB_WIDGETS options.")
  endif()

  # WebKitWidgets was deprecated in Qt 5.3 and removed in 5.6.
  find_package(Qt5 OPTIONAL_COMPONENTS WebKitWidgets QUIET)
  if(Qt5WebKitWidgets_FOUND)
    list(APPEND PLUSBUILD_QT_COMPONENTS WebKitWidgets)
  endif()

  set(ep_qt_args -DQt5_DIR:PATH=${Qt5_DIR})
  foreach(_component IN LISTS PLUSBUILD_QT_COMPONENTS)
    if(Qt5${_component}_DIR)
      list(APPEND ep_qt_args -DQt5${_component}_DIR:PATH=${Qt5${_component}_DIR})
    endif()
  endforeach()
endif()

#-----------------------------------------------------------------------------
# Dependencies built, downloaded or found by the superbuild
#
# Each External_*.cmake file appends to PlusLib_DEPENDENCIES when it actually
# adds a target, so the list has to exist before the first include.
#-----------------------------------------------------------------------------
set(PlusLib_DEPENDENCIES)

include(SuperBuild/External_VTK.cmake)

set(PLUS_ITK_VERSION 5 CACHE STRING "Set version of ITK to use.")
mark_as_advanced(PLUS_ITK_VERSION)
set_property(CACHE PLUS_ITK_VERSION PROPERTY STRINGS "5" "4")
if(PLUS_USE_STEALTHLINK AND PLUS_ITK_VERSION VERSION_GREATER "4")
  message(STATUS "The StealthLink device only supports up to Visual Studio 2013, so it must use ITK 4. Changing the ITK version to 4.")
  set(PLUS_ITK_VERSION 4 CACHE STRING "Set version of ITK to use." FORCE)
elseif(NOT PLUS_USE_STEALTHLINK AND PLUS_ITK_VERSION MATCHES "4")
  message(STATUS "Only the StealthLink device is still supported with ITK 4. Changing the ITK version to 5.")
  set(PLUS_ITK_VERSION 5 CACHE STRING "Set version of ITK to use." FORCE)
endif()
if(PLUS_ITK_VERSION GREATER_EQUAL 5)
  plus_require_cxx_standard(17 "ITK 5")
endif()

include(SuperBuild/External_ITK.cmake)

if(PLUSBUILD_USE_OpenIGTLink)
  set(OpenIGTLink_DEPENDENCIES)
  include(SuperBuild/External_OpenIGTLink.cmake)

  set(OpenIGTLinkIO_DEPENDENCIES OpenIGTLink)
  if(TARGET vtk)
    list(APPEND OpenIGTLinkIO_DEPENDENCIES vtk)
  endif()
  include(SuperBuild/External_OpenIGTLinkIO.cmake)
endif()

if(PLUS_USE_OPTITRACK)
  if(BUILD_ARCHITECTURE MATCHES "x64")
    set(MOTIVE_VERSION_DEFAULT "3.3.2")
  else()
    set(MOTIVE_VERSION_DEFAULT "1.10.3")
  endif()
  set(MOTIVE_VERSION ${MOTIVE_VERSION_DEFAULT} CACHE STRING "Choose the motive API version.")
  set_property(CACHE MOTIVE_VERSION PROPERTY STRINGS "1.10.3" "2.2.0" "2.3.2" "3.1.2" "3.3.2")
  if(HOST_ARCHITECTURE MATCHES "x86" AND MOTIVE_VERSION VERSION_GREATER "2.1.0")
    message(FATAL_ERROR "MOTIVE_VERSION cannot be greater than 2.1.0 for 32-bit builds")
  endif()

  if(MOTIVE_VERSION VERSION_GREATER_EQUAL "3.1.0")
    plus_require_cxx_standard(17 "OptiTrack Motive 3.1 and newer")
  endif()

  if(MOTIVE_VERSION VERSION_GREATER_EQUAL "3.3.2")
    # From 3.3.2 the API is too large to keep in PLTools, so it is fetched from
    # the PlusLibData data store instead.
    if(MOTIVE_VERSION VERSION_EQUAL "3.3.2")
      set(MOTIVE_API_SHA256 "880a943111ac8836ad266aff78808c5d34d5fa5475e443339215667dbb3fd496")
      set(MOTIVE_API_URL "https://github.com/PlusToolkit/PlusLibData/releases/download/SHA256/${MOTIVE_API_SHA256}")
    else()
      message(FATAL_ERROR "Motive API version ${MOTIVE_VERSION} is not supported.")
    endif()

    set(MOTIVE_API_ZIP "${CMAKE_BINARY_DIR}/MotiveAPI.zip")
    set(MOTIVE_API_UNZIP "${CMAKE_BINARY_DIR}/MotiveAPI")

    set(_download_needed TRUE)
    if(EXISTS "${MOTIVE_API_ZIP}")
      file(SHA256 "${MOTIVE_API_ZIP}" _actual_hash)
      if(_actual_hash STREQUAL "${MOTIVE_API_SHA256}")
        set(_download_needed FALSE)
      else()
        message(STATUS "MotiveAPI.zip SHA256 mismatch, downloading it again")
        file(REMOVE "${MOTIVE_API_ZIP}")
      endif()
    endif()

    if(_download_needed)
      file(DOWNLOAD "${MOTIVE_API_URL}" "${MOTIVE_API_ZIP}" SHOW_PROGRESS
        EXPECTED_HASH SHA256=${MOTIVE_API_SHA256})
      file(REMOVE_RECURSE "${MOTIVE_API_UNZIP}")
      file(ARCHIVE_EXTRACT INPUT "${MOTIVE_API_ZIP}" DESTINATION "${MOTIVE_API_UNZIP}")
    endif()
  endif()
endif()

if(PLUS_USE_NDI)
  include(SuperBuild/External_ndicapi.cmake)
endif()

if(PLUS_USE_BKPROFOCUS_CAMERALINK)
  set(GrabbieLib_DEPENDENCIES)
  include(SuperBuild/External_GrabbieLib.cmake)
endif()

include(SuperBuild/External_IGSIO.cmake)

# OpenCV has to come after VTK.
if(PLUSBUILD_USE_OpenCV)
  include(SuperBuild/External_OpenCV.cmake)
  message(STATUS "If building OpenCV with GPU code enabled, consider setting PLUSBUILD_OpenCV_CUDA_GENERATION as it will significantly reduce build time.")
endif()

if(PLUSBUILD_USE_Tesseract)
  include(SuperBuild/External_Tesseract.cmake)
endif()

if(PLUS_USE_INFRARED_SEEK_CAM)
  include(SuperBuild/External_libusb.cmake)
  include(SuperBuild/External_InfraredSeekCam.cmake)
endif()

if(PLUSBUILD_USE_aruco)
  include(SuperBuild/External_aruco.cmake)
endif()

if(PLUS_USE_OvrvisionPro)
  find_package(OpenGL REQUIRED)
  find_package(OpenCL REQUIRED)
  include(SuperBuild/External_OvrvisionPro.cmake)
endif()

if(PLUS_USE_INTERSONSDKCXX_VIDEO)
  include(SuperBuild/External_IntersonSDKCxx.cmake)
endif()

if(PLUS_USE_INTERSONARRAYSDKCXX_VIDEO)
  include(SuperBuild/External_IntersonArraySDKCxx.cmake)
endif()

if(PLUS_USE_STEAMVR)
  include(SuperBuild/External_OpenVR.cmake)
endif()

if(PLUS_USE_CLARIUS_OEM)
  include(SuperBuild/External_ClariusOEM.cmake)
endif()

#-----------------------------------------------------------------------------
# Build order
#
# PlusLib has to wait for everything the superbuild builds for it. Asking
# whether the target exists is the same question as "did we build this
# ourselves", and unlike the previous per-option conditions it cannot fall out
# of step with the includes above.
#-----------------------------------------------------------------------------
foreach(_dependency vtk itk IGSIO OpenIGTLink OpenIGTLinkIO OpenCV tesseract aruco
                    ndicapi GrabbieLib IntersonSDKCxx IntersonArraySDKCxx
                    OvrvisionPro SeekCameraLib OpenVR ClariusOEM)
  if(TARGET ${_dependency})
    list(APPEND PlusLib_DEPENDENCIES ${_dependency})
  endif()
endforeach()

#-----------------------------------------------------------------------------
# Vendor SDKs
#
# These are found on the machine rather than built. Each one fails with the
# same shape of message when it is missing, and forwards whatever PlusLib
# needs in order to find it again.
#-----------------------------------------------------------------------------
if(PLUS_USE_ATRACSYS)
  set(PLUS_USE_ATRACSYS_DEVICE_TYPE "SET_DEVICE_TYPE" CACHE STRING "Type of Atracsys device to build support for.")
  set_property(CACHE PLUS_USE_ATRACSYS_DEVICE_TYPE PROPERTY STRINGS stk ftk ftksim)
  set(ATRACSYS_DEVICE_TYPE ${PLUS_USE_ATRACSYS_DEVICE_TYPE})
  if(ATRACSYS_DEVICE_TYPE STREQUAL "SET_DEVICE_TYPE")
    message(FATAL_ERROR "Please choose an Atracsys device type to build support for. Options are stk (spryTrack), ftk (fusionTrack), or ftksim (fusionTrack simulator).")
  endif()
endif()

plus_find_sdk(PLUS_USE_OPTIMET_CONOPROBE OPTIMETSMART32SDK MESSAGE "for ConoProbe tracking")
plus_find_sdk(PLUS_USE_NDI_CERTUS NDIOAPI MESSAGE "for Certus tracking")
plus_find_sdk(PLUS_USE_ULTRASONIX_VIDEO ULTRASONIX_SDK MESSAGE "for Ultrasonix video")
plus_find_sdk(PLUS_USE_MICRONTRACKER MicronTracker FOUND_VAR MICRONTRACKER_FOUND MESSAGE "for the MicronTracker tracking device")
plus_find_sdk(PLUS_USE_INTELREALSENSE RSSDK MESSAGE "for the Intel RealSense device")
plus_find_sdk(PLUS_USE_INFRARED_TEQ1_CAM TEQ1SDK MESSAGE "for the Thermal Expert Q1 camera")
plus_find_sdk(PLUS_USE_INFRARED_TEEV2_CAM TEEV2SDK MESSAGE "for the Thermal Expert EV2 camera")
plus_find_sdk(PLUS_USE_ULTRAVIOLET_PCOUV_CAM PCOUVSDK MESSAGE "for the PCO ultraviolet camera")
plus_find_sdk(PLUS_USE_DAQVIDEOSOURCE DAQVIDEOSOURCESDK MESSAGE "for the DAQ System USB3-FRM13-B CameraLink grabber")
plus_find_sdk(PLUS_USE_ATRACSYS AtracsysSDK MESSAGE "for Atracsys optical trackers")
plus_find_sdk(PLUS_USE_SPINNAKER_VIDEO SpinnakerAPI FOUND_VAR SPINNAKER_API_FOUND MESSAGE "for Point Grey imaging devices")
plus_find_sdk(PLUS_USE_PICOSCOPE PicoScopeSDK MESSAGE "for PicoScope oscilloscopes")
plus_find_sdk(PLUS_USE_ICCAPTURING_VIDEO ICCAPTURING MESSAGE "for the Imaging Source USB frame grabber")
plus_find_sdk(PLUS_USE_OPTITRACK MotiveAPI MESSAGE "for OptiTrack devices")
plus_find_sdk(PLUS_USE_OPTITRACK NatNetSDK MESSAGE "for OptiTrack devices")
plus_find_sdk(PLUS_USE_STEALTHLINK STEALTHLINK MESSAGE "for the Medtronic StealthStation")
plus_find_sdk(PLUS_USE_CAPISTRANO_VIDEO CAPISTRANO MESSAGE "for the Capistrano Labs USB ultrasound probes")
plus_find_sdk(PLUS_USE_WINPROBE_VIDEO WinProbeSDK MESSAGE "for WinProbe ultrasound systems")
plus_find_sdk(PLUS_USE_INTERSON_VIDEO INTERSON MESSAGE "for the Interson USB ultrasound probes")
plus_find_sdk(PLUS_USE_IntuitiveDaVinci IntuitiveDaVinci MESSAGE "for the da Vinci Surgical System")
plus_find_sdk(PLUS_USE_TELEMED_VIDEO Telemed FOUND_VAR TELEMED_FOUND MESSAGE "for the Telemed ultrasound probes")
plus_find_sdk(PLUS_USE_THORLABS_VIDEO ThorLabs FOUND_VAR THORLABS_FOUND MESSAGE "for the ThorLabs CCS spectrometers")
plus_find_sdk(PLUS_USE_OPENHAPTICS OpenHaptics FOUND_VAR OPENHAPTICS_FOUND MESSAGE "for the Geomagic Touch devices")
plus_find_sdk(PLUS_USE_BLACKMAGIC_DECKLINK DeckLinkSDK MESSAGE "for DeckLink capture cards")
plus_find_sdk(PLUS_USE_CLARIUS CLARIUS MESSAGE "for the Clarius Listen API")
plus_find_sdk(PLUS_USE_ANDOR_CAMERA ANDOR MESSAGE "for the Andor camera")
plus_find_sdk(PLUS_USE_GENERIC_SENSOR_TRACKER WindowsSensorAPI MESSAGE "for the generic sensor tracker")
plus_find_sdk(PLUS_USE_AZUREKINECT K4A MESSAGE "for the Azure Kinect camera")
plus_find_sdk(PLUS_USE_REVOPOINT3DCAMERA REVOPOINT3DSDK MESSAGE "for Revopoint 3D cameras")
plus_find_sdk(PLUS_USE_V4L2 V4L2 MESSAGE "for video4linux devices")

if(PLUS_USE_NVIDIA_DVP)
  find_package(QuadroSDI REQUIRED)
  find_package(OpenGL REQUIRED)
endif()

if(PLUS_USE_LEAPMOTION)
  find_package(LeapSDK 4.0 REQUIRED
    PATHS
      ../VASSTTools/LeapMotion/LeapSDK/lib/cmake/LeapSDK # Convenience for members of the VASST lab
    )
endif()

if(PLUS_USE_PHILIPS_3D_ULTRASOUND)
  set(PLUS_Philips_MAJOR_VERSION 1 CACHE STRING "Set Philips library major version (version: [major].[minor].[patch])")
  set(PLUS_Philips_MINOR_VERSION 0 CACHE STRING "Set Philips library minor version (version: [major].[minor].[patch])")
  set(PLUS_Philips_PATCH_VERSION 0 CACHE STRING "Set Philips library patch version (version: [major].[minor].[patch])")
  plus_find_sdk(PLUS_USE_PHILIPS_3D_ULTRASOUND Philips FOUND_VAR PHILIPS_FOUND MESSAGE "for the Philips ie33 ultrasound system")
  message(STATUS "To use the Philips devices, register '${CMAKE_CURRENT_BINARY_DIR}/bin/<config>/Stream3d.dll'. On a 32-bit OS run 'regsvr32 Stream3d.dll'. On a 64-bit OS open a command prompt as administrator, change to C:/Windows/SysWow64 and run regsvr32 there.")
endif()

if(PLUS_USE_STEALTHLINK AND UNIX AND NOT APPLE)
  message(WARNING "The StealthLink Linux API was built against the old C++ ABI. Build Plus with -D_GLIBCXX_USE_CXX11_ABI=0 added to CMAKE_CXX_FLAGS.")
endif()

#-----------------------------------------------------------------------------
# A descriptive build name for the dashboard
#
# Previously derived by shelling out to cat /etc/issue.net, sw_vers and
# "clang --version", and by matching the generator name against a list of
# Visual Studio versions that ended at 2022.
#-----------------------------------------------------------------------------
if(MSVC)
  set(COMPILER_NAME "vs${MSVC_TOOLSET_VERSION}")
else()
  string(TOLOWER "${CMAKE_CXX_COMPILER_ID}" _compiler_id)
  set(COMPILER_NAME "${_compiler_id}-${CMAKE_CXX_COMPILER_VERSION}")
endif()

if(WIN32)
  set(SYSTEM_NAME "${CMAKE_SYSTEM_NAME}-${CMAKE_SYSTEM_VERSION}")
elseif(APPLE)
  set(SYSTEM_NAME "macos-${CMAKE_HOST_SYSTEM_VERSION}")
elseif(EXISTS /etc/os-release)
  # ID=ubuntu with VERSION_ID="22.04" becomes ubuntu-22.04.
  file(STRINGS /etc/os-release _os_id REGEX "^ID=")
  file(STRINGS /etc/os-release _os_version REGEX "^VERSION_ID=")
  string(REGEX REPLACE "^ID=\"?([^\"]*)\"?$" "\\1" _os_id "${_os_id}")
  string(REGEX REPLACE "^VERSION_ID=\"?([^\"]*)\"?$" "\\1" _os_version "${_os_version}")
  set(SYSTEM_NAME "${_os_id}-${_os_version}")
else()
  set(SYSTEM_NAME "${CMAKE_SYSTEM_NAME}")
endif()
string(TOLOWER "${SYSTEM_NAME}" SYSTEM_NAME)

set(PLUSBUILD_BUILDNAME_POSTFIX "" CACHE STRING "Postfix that will be appended to the build name on the dashboard. If defined then BUILDNAME variable is always overwritten.")
mark_as_advanced(PLUSBUILD_BUILDNAME_POSTFIX)

set(GENERATED_BUILDNAME "${COMPILER_NAME}${BUILD_ARCHITECTURE}-${SYSTEM_NAME}")
if(PLUSBUILD_BUILDNAME_POSTFIX)
  string(APPEND GENERATED_BUILDNAME "-${PLUSBUILD_BUILDNAME_POSTFIX}")
endif()
set(BUILDNAME "${GENERATED_BUILDNAME}" CACHE STRING "Name of the build on the dashboard. Generated from the build options and PLUSBUILD_BUILDNAME_POSTFIX." FORCE)
mark_as_advanced(BUILDNAME)

#-----------------------------------------------------------------------------
# PlusLib, PlusApp and the model catalog
#-----------------------------------------------------------------------------
include(CTest)

if(PLUSBUILD_DOWNLOAD_PLUSLIBDATA AND NOT PLUSBUILD_OFFLINE_BUILD)
  include(SuperBuild/External_PlusLibData.cmake)
endif()

include(SuperBuild/External_PlusLib.cmake)

if(PLUSBUILD_BUILD_PLUSAPP)
  set(PlusApp_DEPENDENCIES PlusLib)
  include(SuperBuild/External_PlusApp.cmake)
endif()

if(PLUSBUILD_BUILD_PLUSMODELCATALOG)
  set(PlusModelCatalog_DEPENDENCIES PlusLib)
  include(SuperBuild/External_PlusModelCatalog.cmake)
endif()

#-----------------------------------------------------------------------------
# Convenience scripts for an automatic update, build and test cycle
#-----------------------------------------------------------------------------
if(PLUSBUILD_MULTI_CONFIG)
  set(PLUSBUILD_BUILD_CONFIG_ARG "--config Release")
  set(PLUSBUILD_CTEST_CONFIG_ARG "-C Release")
else()
  # A single-configuration build has one configuration, chosen at configure
  # time, so naming one here would at best be redundant and at worst wrong.
  set(PLUSBUILD_BUILD_CONFIG_ARG "")
  set(PLUSBUILD_CTEST_CONFIG_ARG "")
endif()

if(WIN32)
  configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/BuildAndTest.bat.in"
    "${CMAKE_CURRENT_BINARY_DIR}/BuildAndTest.bat"
    )
  string(REPLACE "/" "\\" PLUSBUILD_BIN_DIR_WIN "${CMAKE_BINARY_DIR}")
  configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/PlusBuildAndTest.bat.in"
    "${CMAKE_CURRENT_BINARY_DIR}/PlusBuildAndTest.bat"
    )
else()
  # Configured into a scratch directory first, then copied so that the execute
  # bit can be set.
  configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/BuildAndTest.sh.in"
    "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/BuildAndTest.sh"
    @ONLY
    )
  configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/PlusBuildAndTest.sh.in"
    "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/PlusBuildAndTest.sh"
    )
  foreach(_script BuildAndTest.sh PlusBuildAndTest.sh)
    file(COPY "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/${_script}"
      DESTINATION "${CMAKE_CURRENT_BINARY_DIR}"
      FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
  endforeach()
endif()

#-----------------------------------------------------------------------------
# Options that are not compatible with Visual Studio 2010, which is still
# reachable through PLUS_USE_STEALTHLINK.
#-----------------------------------------------------------------------------
if(MSVC_VERSION EQUAL 1600)
  foreach(_option_name PLUSBUILD_USE_aruco PLUS_USE_USDIGITALENCODERS_TRACKER)
    if(${_option_name})
      message(FATAL_ERROR "Option ${_option_name} is not compatible with Visual Studio 2010. Disable ${_option_name} or use a more recent compiler.")
    endif()
  endforeach()
endif()
