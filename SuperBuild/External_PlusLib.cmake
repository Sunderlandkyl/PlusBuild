# --------------------------------------------------------------------------
# PlusLib
#
# Everything below is about telling PlusLib where to find things. The device
# options themselves are not listed here: they are forwarded straight from the
# cache, so adding an option means declaring it in the top-level CMakeLists.txt
# and reading it in PlusLib, rather than also editing a third list here that
# has to be kept in step with the other two.

# plus_add_pluslib_args() rather than a macro appending to a local list: a
# macro substitutes its arguments textually, so its body is parsed a second
# time, and on that second pass the backslashes in a Windows path are read as
# escape sequences and rejected.

if(PLUSBUILD_USE_3DSlicer)
  plus_add_pluslib_args(-DSLICER_BIN_DIRECTORY:PATH=${PLUSBUILD_SLICER_BIN_DIRECTORY})
endif()

if(PLUSBUILD_USE_OpenIGTLink)
  plus_add_pluslib_args(
    -DOpenIGTLink_DIR:PATH=${PLUS_OpenIGTLink_DIR}
    -DOpenIGTLinkIO_DIR:PATH=${PLUS_OpenIGTLinkIO_DIR}
    )
endif()

if(PLUS_USE_TextRecognizer)
  plus_add_pluslib_args(
    -Dtesseract_DIR:PATH=${PLUS_tesseract_DIR}
    -Dtesseract_DATA_DIR:PATH=${PLUS_tessdata_src_DIR}
    )
endif()

if(PLUSBUILD_USE_OpenCV)
  plus_add_pluslib_args(-DOpenCV_DIR:PATH=${PLUS_OpenCV_DIR})
endif()

if(PLUSBUILD_USE_aruco)
  plus_add_pluslib_args(-Daruco_DIR:PATH=${PLUS_aruco_DIR})
endif()

if(PLUS_USE_ATRACSYS)
  plus_add_pluslib_args(
    -DAtracsysSDK_INCLUDE_DIR:PATH=${AtracsysSDK_INCLUDE_DIR}
    -DAtracsysSDK_LIBRARY:PATH=${AtracsysSDK_LIBRARY}
    -DAtracsysSDK_BINARY_DIR:PATH=${AtracsysSDK_BINARY_DIR}
    -DATRACSYS_DEVICE_TYPE:STRING=${ATRACSYS_DEVICE_TYPE}
    )
endif()

if(PLUS_USE_PICOSCOPE)
  plus_add_pluslib_args(
    -DPicoScopeSDK_INCLUDE_DIR:PATH=${PicoScopeSDK_INCLUDE_DIR}
    -DPicoScopeSDK_LIBRARY_DIR:PATH=${PicoScopeSDK_LIBRARY_DIR}
    -DPicoScopeSDK_BINARY_DIR:PATH=${PicoScopeSDK_BINARY_DIR}
    )
endif()

if(PLUS_USE_SPINNAKER_VIDEO)
  plus_add_pluslib_args(
    -DSPINNAKER_API_INCLUDE_DIR:PATH=${SPINNAKER_API_INCLUDE_DIR}
    -DSPINNAKER_API_LIBRARY_DIR:PATH=${SPINNAKER_API_LIBRARY_DIR}
    -DSPINNAKER_API_BINARY_DIR:PATH=${SPINNAKER_API_BINARY_DIR}
    )
endif()

if(PLUS_USE_ULTRASONIX_VIDEO)
  plus_add_pluslib_args(-DULTRASONIX_SDK_DIR:PATH=${ULTRASONIX_SDK_DIR})
endif()

if(PLUS_USE_BKPROFOCUS_VIDEO)
  plus_add_pluslib_args(-DGRABBIELIB_SOURCE_DIR:PATH=${PLUS_GRABBIELIB_SOURCE_DIR})
  if(PLUS_USE_BKPROFOCUS_CAMERALINK)
    plus_add_pluslib_args(-DDALSASAPERA_LIB_DIR:PATH=${DALSASAPERA_LIB_DIR})
  endif()
endif()

if(PLUS_USE_OPTIMET_CONOPROBE)
  plus_add_pluslib_args(
    -DOPTIMETSMART32SDK_INCLUDE_DIR:PATH=${OPTIMETSMART32SDK_INCLUDE_DIR}
    -DOPTIMETSMART32SDK_64BIT_BINARY_DIR:PATH=${OPTIMETSMART32SDK_64BIT_BINARY_DIR}
    -DOPTIMETSMART32SDK_64BIT_LIBRARY:PATH=${OPTIMETSMART32SDK_64BIT_LIBRARY}
    -DOPTIMETSMART32SDK_32BIT_BINARY_DIR:PATH=${OPTIMETSMART32SDK_32BIT_BINARY_DIR}
    -DOPTIMETSMART32SDK_32BIT_LIBRARY:PATH=${OPTIMETSMART32SDK_32BIT_LIBRARY}
    )
endif()

if(PLUS_USE_OPTITRACK)
  plus_add_pluslib_args(
    -DOPTITRACK_MOTIVE_INCLUDE_DIR:PATH=${MotiveAPI_INCLUDE_DIR}
    -DOPTITRACK_MOTIVE_DIR:PATH=${MotiveAPI_DIR}
    -DOPTITRACK_MOTIVE_VERSION:STRING=${MotiveAPI_VERSION}
    -DOPTITRACK_NATNET_INCLUDE_DIR:PATH=${NatNetSDK_INCLUDE_DIR}
    -DOPTITRACK_NATNET_LIBRARY_DIR:PATH=${NatNetSDK_LIBRARY_DIR}
    -DOPTITRACK_NATNET_BINARY_DIR:PATH=${NatNetSDK_BINARY_DIR}
    -DOPTITRACK_MSVC80_OPENMP_DIR:PATH=${MotiveAPI_MSVC80_OpenMP_DIR}
    )
endif()

if(PLUS_USE_STEAMVR)
  plus_add_pluslib_args(
    -DOVR_DIR:PATH=${PLUS_OVR_DIR}
    -DOPENVR_ROOT_DIR:PATH=${PLUS_OVR_DIR}
    )
endif()

if(PLUS_USE_ICCAPTURING_VIDEO)
  plus_add_pluslib_args(
    -DICCAPTURING_INCLUDE_DIR:PATH=${ICCAPTURING_INCLUDE_DIR}
    -DICCAPTURING_TIS_UDSHL_STATIC_LIB:PATH=${ICCAPTURING_TIS_UDSHL_STATIC_LIB}
    -DICCAPTURING_TIS_UDSHL_SHARED_LIB:PATH=${ICCAPTURING_TIS_UDSHL_SHARED_LIB}
    -DICCAPTURING_TIS_UDSHLD_STATIC_LIB:PATH=${ICCAPTURING_TIS_UDSHLD_STATIC_LIB}
    -DICCAPTURING_TIS_UDSHLD_SHARED_LIB:PATH=${ICCAPTURING_TIS_UDSHLD_SHARED_LIB}
    )
endif()

if(PLUS_USE_CAPISTRANO_VIDEO)
  plus_add_pluslib_args(
    -DCAPISTRANO_INCLUDE_DIR:PATH=${CAPISTRANO_INCLUDE_DIR}
    -DCAPISTRANO_LIBRARY_DIR:PATH=${CAPISTRANO_LIBRARY_DIR}
    -DCAPISTRANO_BINARY_DIR:PATH=${CAPISTRANO_BINARY_DIR}
    -DCAPISTRANO_LIBRARY_USBPROBE_NAME:STRING=${CAPISTRANO_LIBRARY_USBPROBE_NAME}
    -DCAPISTRANO_LIBRARY_BMODE_NAME:STRING=${CAPISTRANO_LIBRARY_BMODE_NAME}
    -DCAPISTRANO_BINARY_USBPROBE_NAME:STRING=${CAPISTRANO_BINARY_USBPROBE_NAME}
    -DCAPISTRANO_BINARY_BMODE_NAME:STRING=${CAPISTRANO_BINARY_BMODE_NAME}
    -DCAPISTRANO_SDK_VERSION:STRING=${Capistrano_SDK_VERSION}
    )
endif()

if(PLUS_USE_CLARIUS)
  set(CMAKE_THREAD_PREFER_PTHREAD TRUE)
  set(THREADS_PREFER_PTHREAD_FLAG TRUE)
  find_package(Threads REQUIRED)
  plus_add_pluslib_args(
    -DCLARIUS_INCLUDE_DIR:PATH=${CLARIUS_INCLUDE_DIR}
    -DCLARIUS_DIR:PATH=${CLARIUS_DIR}
    -DCLARIUS_LIB_DIR:PATH=${CLARIUS_LIB_DIR}
    )
endif()

if(PLUS_USE_CLARIUS_OEM)
  plus_add_pluslib_args(
    ${PLUSBUILD_QT_DIR_ARG}
    -DClariusOEM_DIR:PATH=${Plus_ClariusOEM_DIR}
    )
endif()

if(PLUS_USE_ANDOR_CAMERA)
  plus_add_pluslib_args(
    -DANDOR_INCLUDE_DIR:PATH=${ANDOR_INCLUDE_DIR}
    -DANDOR_LIBRARY_DIR:PATH=${ANDOR_LIBRARY_DIR}
    -DANDOR_BINARY_DIR:PATH=${ANDOR_BINARY_DIR}
    -DANDOR_LIBRARY:STRING=${ANDOR_LIBRARY}
    -DANDOR_DLL:STRING=${ANDOR_DLL}
    )
endif()

if(PLUS_USE_WINPROBE_VIDEO)
  plus_add_pluslib_args(-DWINPROBESDK_DIR:PATH=${WINPROBESDK_DIR})
endif()

if(PLUS_USE_INTERSON_VIDEO)
  plus_add_pluslib_args(
    -DINTERSON_INCLUDE_DIR:PATH=${INTERSON_INCLUDE_DIR}
    -DINTERSON_LIBRARY_DIR:PATH=${INTERSON_LIBRARY_DIR}
    -DINTERSON_BINARY_DIR:PATH=${INTERSON_BINARY_DIR}
    -DINTERSON_WIN32_BINARY_DIR:PATH=${INTERSON_WIN32_BINARY_DIR}
    -DINTERSON_WIN64_BINARY_DIR:PATH=${INTERSON_WIN64_BINARY_DIR}
    )
endif()

if(PLUS_USE_INTERSONSDKCXX_VIDEO)
  plus_add_pluslib_args(-DIntersonSDKCxx_DIR:PATH=${PLUS_IntersonSDKCxx_DIR})
endif()

if(PLUS_USE_INTERSONARRAYSDKCXX_VIDEO)
  plus_add_pluslib_args(-DIntersonArraySDKCxx_DIR:PATH=${PLUS_IntersonArraySDKCxx_DIR})
endif()

if(PLUS_USE_STEALTHLINK)
  plus_add_pluslib_args(
    -DSTEALTHLINK_INCLUDE_DIRS:PATH=${STEALTHLINK_INCLUDE_DIRS}
    -DSTEALTHLINK_STEALTHLINK_STATIC_LIBRARY:PATH=${STEALTHLINK_STEALTHLINK_STATIC_LIBRARY}
    )
  if(WIN32)
    plus_add_pluslib_args(
      -DSTEALTHLINK_STEALTHLINK_SHARED_LIBRARY:PATH=${STEALTHLINK_STEALTHLINK_SHARED_LIBRARY}
      -DSTEALTHLINK_STEALTHLINKD_STATIC_LIBRARY:PATH=${STEALTHLINK_STEALTHLINKD_STATIC_LIBRARY}
      -DSTEALTHLINK_STEALTHLINKD_SHARED_LIBRARY:PATH=${STEALTHLINK_STEALTHLINKD_SHARED_LIBRARY}
      )
  endif()
endif()

if(PLUS_USE_NDI)
  plus_add_pluslib_args(-Dndicapi_DIR:PATH=${PLUS_ndicapi_DIR})
endif()

if(PLUS_USE_NDI_CERTUS)
  plus_add_pluslib_args(
    -DNDIOAPI_LIBRARY:PATH=${NDIOAPI_LIBRARY}
    -DNDIOAPI_BINARY_DIR:PATH=${NDIOAPI_BINARY_DIR}
    -DNDIOAPI_INCLUDE_DIR:PATH=${NDIOAPI_INCLUDE_DIR}
    )
endif()

if(PLUS_USE_MICRONTRACKER)
  plus_add_pluslib_args(
    -DMicronTracker_INCLUDE_DIR:PATH=${MicronTracker_INCLUDE_DIR}
    -DMicronTracker_LIBRARY:PATH=${MicronTracker_LIBRARY}
    -DMicronTracker_BINARY_DIR:PATH=${MicronTracker_BINARY_DIR}
    )
endif()

if(PLUS_USE_OPENHAPTICS)
  plus_add_pluslib_args(
    -DOpenHaptics_INCLUDE_DIR:PATH=${OpenHaptics_INCLUDE_DIRS}
    -DHLAPI_HLU_INCLUDE_DIR:PATH=${HLAPI_HLU_INCLUDE_DIR}
    -DHD_LIBRARY_RELEASE:PATH=${HDAPI_LIBRARY_RELEASE}
    -DHL_LIBRARY_RELEASE:PATH=${HLAPI_LIBRARY_RELEASE}
    -DHDU_LIBRARY_RELEASE:PATH=${HDAPI_HDU_LIBRARY_RELEASE}
    -DHLU_LIBRARY_RELEASE:PATH=${HLAPI_HLU_LIBRARY_RELEASE}
    -DHD_LIBRARY_DEBUG:PATH=${HDAPI_LIBRARY_DEBUG}
    -DHL_LIBRARY_DEBUG:PATH=${HLAPI_LIBRARY_DEBUG}
    -DHDU_LIBRARY_DEBUG:PATH=${HDAPI_HDU_LIBRARY_DEBUG}
    -DHLU_LIBRARY_DEBUG:PATH=${HLAPI_HLU_LIBRARY_DEBUG}
    -DOpenHaptics_BINARY_DIR:PATH=${OpenHaptics_BINARY_DIR}
    -DOpenHaptics_UTILITIES_BINARY_DIR:PATH=${OpenHaptics_UTILITIES_BINARY_DIR}
    )
endif()

if(PLUS_USE_BLACKMAGIC_DECKLINK)
  plus_add_pluslib_args(
    -DDeckLinkSDK_INCLUDE_DIR:PATH=${DeckLinkSDK_INCLUDE_DIR}
    -DDeckLinkSDK_PATH:PATH=${DeckLinkSDK_PATH}
    )
endif()

if(PLUS_USE_INFRARED_SEEK_CAM)
  plus_add_pluslib_args(
    -DLIBUSB_INCLUDE_DIR:PATH=${LIBUSB_INCLUDE_DIR}
    -DLIBUSB_LIBRARY:PATH=${LIBUSB_LIBRARY}
    -DSeekCameraLib_DIR:PATH=${PLUS_SeekCameraLib_DIR}
    )
endif()

if(PLUS_USE_INFRARED_TEQ1_CAM)
  plus_add_pluslib_args(
    -DTEQ1_SDK_INCLUDE_DIR:PATH=${TEQ1_SDK_INCLUDE_DIR}
    -DTEQ1_SDK_LIBRARY:PATH=${TEQ1_SDK_LIBRARY}
    -DTEQ1_SDK_BINARY:PATH=${TEQ1_SDK_BINARY}
    -DTEQ1_SDK_DIR:PATH=${TEQ1_SDK_DIR}
    )
endif()

if(PLUS_USE_INFRARED_TEEV2_CAM)
  plus_add_pluslib_args(
    -DTEEV2_SDK_INCLUDE_DIR:PATH=${TEEV2_SDK_INCLUDE_DIR}
    -DTEEV2_SDK_LIBRARY:PATH=${TEEV2_SDK_LIBRARY}
    -DTEEV2_SDK_BINARY:PATH=${TEEV2_SDK_BINARY}
    -DTEEV2_SDK_DIR:PATH=${TEEV2_SDK_DIR}
    )
endif()

if(PLUS_USE_ULTRAVIOLET_PCOUV_CAM)
  plus_add_pluslib_args(
    -DPCOUV_SDK_INCLUDE_DIR:PATH=${PCOUV_SDK_INCLUDE_DIR}
    -DPCOUV_SDK_LIBRARY:PATH=${PCOUV_SDK_LIBRARY}
    -DPCOUV_SDK_BINARY:PATH=${PCOUV_SDK_BINARY}
    -DPCOUV_SDK_DIR:PATH=${PCOUV_SDK_DIR}
    )
endif()

if(PLUS_USE_DAQVIDEOSOURCE)
  plus_add_pluslib_args(
    -DDAQVIDEOSOURCE_SDK_INCLUDE_DIR:PATH=${DAQVIDEOSOURCE_SDK_INCLUDE_DIR}
    -DDAQVIDEOSOURCE_SDK_LIBRARY:PATH=${DAQVIDEOSOURCE_SDK_LIBRARY}
    -DDAQVIDEOSOURCE_SDK_BINARY:PATH=${DAQVIDEOSOURCE_SDK_BINARY}
    -DDAQVIDEOSOURCE_SDK_DIR:PATH=${DAQVIDEOSOURCE_SDK_DIR}
    )
endif()

if(PLUS_USE_INTELREALSENSE)
  plus_add_pluslib_args(
    -DRSSDK_INCLUDE_DIR:PATH=${RSSDK_INCLUDE_DIR}
    -DRSSDK_LIB:PATH=${RSSDK_LIB}
    -DRSSDK_BIN:PATH=${RSSDK_BIN}
    )
endif()

if(PLUS_USE_NVIDIA_DVP)
  plus_add_pluslib_args(
    -DNVIDIA_DVP_INCLUDE_DIR:PATH=${NVIDIA_DVP_INCLUDE_DIR}
    -DNVIDIA_DVP_BINARY_DIR:PATH=${NVIDIA_DVP_BINARY_DIR}
    -DNVIDIA_DVP_LIB_DIR:PATH=${NVIDIA_DVP_LIB_DIR}
    -DQuadroSDI_ROOT_DIR:PATH=${QuadroSDI_ROOT_DIR}
    )
endif()

if(PLUS_USE_OvrvisionPro)
  plus_add_pluslib_args(-DOvrvisionPro_DIR:PATH=${PLUS_OvrvisionPro_DIR})
endif()

if(PLUS_USE_IntuitiveDaVinci)
  plus_add_pluslib_args(
    -DIntuitiveDaVinci_INCLUDE_DIR:PATH=${IntuitiveDaVinci_INCLUDE_DIR}
    -DIntuitiveDaVinci_LIBRARY:PATH=${IntuitiveDaVinci_LIBRARY}
    )
endif()

if(PLUS_USE_MMF_VIDEO OR PLUS_USE_TELEMED_VIDEO)
  # Pick the newest Windows SDK that actually carries headers and libraries.
  find_package(WindowsSDK REQUIRED)
  set(WINDOWS_SDK_ROOT_DIRS ${WINDOWSSDK_PREFERRED_FIRST_DIRS})
  set(WINDOWS_SDK_ROOT_DIR "")
  set(WINDOWS_SDK_INCLUDE_DIRS "")
  set(WINDOWS_SDK_LIBRARY_DIRS "")
  foreach(_dir IN LISTS WINDOWS_SDK_ROOT_DIRS)
    set(WINDOWS_SDK_ROOT_DIR "${_dir}")
    set(WINDOWS_SDK_INCLUDE_DIRS "NOTFOUND")
    set(WINDOWS_SDK_LIBRARY_DIRS "NOTFOUND")
    get_windowssdk_include_dirs("${_dir}" WINDOWS_SDK_INCLUDE_DIRS)
    get_windowssdk_library_dirs("${_dir}" WINDOWS_SDK_LIBRARY_DIRS)
    if(NOT WINDOWS_SDK_INCLUDE_DIRS STREQUAL "NOTFOUND" AND NOT WINDOWS_SDK_LIBRARY_DIRS STREQUAL "NOTFOUND")
      include(TestWindowsSDK)
      if(PLUS_WINDOWS_SDK_IS_COMPATIBLE)
        break()
      endif()
    endif()
  endforeach()

  if(PLUS_WINDOWS_SDK_IS_COMPATIBLE)
    # Passed as a real list. It used to be joined with "|" and taken apart
    # again on the other side, because a command-line argument cannot carry a
    # semicolon. An initial cache file can.
    plus_add_pluslib_args("-DWINDOWS_SDK_INCLUDE_DIRS:STRING=${WINDOWS_SDK_INCLUDE_DIRS}")
  else()
    message(WARNING "The Windows SDKs found at ${WINDOWS_SDK_ROOT_DIRS} are not compatible with Plus")
  endif()
endif()

if(PLUS_USE_MMF_VIDEO AND NOT PLUS_WINDOWS_SDK_IS_COMPATIBLE)
  message(FATAL_ERROR "This project requires the Windows SDK to support the Microsoft Media Foundation imaging devices. Either install a recent Windows SDK or turn off PLUS_USE_MMF_VIDEO.")
endif()

if(PLUS_USE_TELEMED_VIDEO)
  if(NOT PLUS_WINDOWS_SDK_IS_COMPATIBLE)
    message(FATAL_ERROR "This project requires the Windows SDK to support the Telemed ultrasound probes. Either install a recent Windows SDK or turn off PLUS_USE_TELEMED_VIDEO.")
  endif()
  plus_add_pluslib_args(-DTELEMED_INCLUDE_DIR:PATH=${TELEMED_INCLUDE_DIR})
endif()

if(PLUS_USE_THORLABS_VIDEO)
  plus_add_pluslib_args(
    -DTHORLABS_INCLUDE_DIR:PATH=${THORLABS_INCLUDE_DIR}
    -DTHORLABS_LIBRARY_DIR:PATH=${THORLABS_LIBRARY_DIR}
    )
endif()

if(PLUS_USE_PHILIPS_3D_ULTRASOUND)
  plus_add_pluslib_args(
    -DPhilips_BINARY_DIRS:PATH=${Philips_BINARY_DIRS}
    -DPhilips_INCLUDE_DIRS:PATH=${Philips_INCLUDE_DIRS}
    -DPhilips_LIBRARY_DIR:PATH=${Philips_LIBRARY_DIR}
    )
endif()

if(PLUS_USE_MKV_IO)
  plus_add_pluslib_args(-Dlibwebm_DIR:PATH=${PLUS_libwebm_DIR})
endif()

if(PLUS_USE_LEAPMOTION)
  plus_add_pluslib_args(-DLeapSDK_DIR:PATH=${LeapSDK_DIR})
endif()

if(PLUS_USE_AZUREKINECT)
  plus_add_pluslib_args(
    -DK4A_INCLUDE_DIR:PATH=${K4A_INCLUDE_DIR}
    -DK4A_LIBRARY_DIR:PATH=${K4A_LIBRARY_DIR}
    -DK4A_BINARY_DIR:PATH=${K4A_BINARY_DIR}
    -DK4A_LIBRARY:FILEPATH=${K4A_LIBRARY}
    )
endif()

if(PLUS_USE_REVOPOINT3DCAMERA)
  plus_add_pluslib_args(
    -DREVOPOINT3DSDK_INCLUDE_DIR:PATH=${REVOPOINT3DSDK_INCLUDE_DIR}
    -DREVOPOINT3DSDK_BINARY_DIR:PATH=${REVOPOINT3DSDK_BINARY_DIR}
    "-DREVOPOINT3DSDK_LIBRARIES:STRING=${REVOPOINT3DSDK_LIBRARIES}"
    )
endif()

if(PLUSBUILD_DOCUMENTATION)
  plus_add_pluslib_args(
    -DPLUS_DOCUMENTATION_SEARCH_SERVER_INDEXED:BOOL=${PLUSBUILD_DOCUMENTATION_SEARCH_SERVER_INDEXED}
    -DDOXYGEN_DOT_EXECUTABLE:FILEPATH=${DOXYGEN_DOT_EXECUTABLE}
    -DDOXYGEN_EXECUTABLE:FILEPATH=${DOXYGEN_EXECUTABLE}
    )
endif()

if(PLUSBUILD_DOWNLOAD_PLUSLIBDATA AND NOT PLUSBUILD_OFFLINE_BUILD)
  plus_add_pluslib_args(-DPLUSLIB_DATA_DIR:PATH=${PLUSLIB_DATA_DIR})
endif()

if(PLUSBUILD_BUILD_PLUSLIB_WIDGETS)
  plus_add_pluslib_args(${PLUSBUILD_QT_DIR_ARG})
endif()

# --------------------------------------------------------------------------
# Device and test options
#
# Forwarded straight from the cache, so this cannot drift out of step with the
# options declared in the top-level CMakeLists.txt. PLUS_USE_POLARIS and
# PLUS_USE_CERTUS are deprecated spellings PlusLib does not know, and the
# Atracsys device type is passed under its own name above.
plus_get_pluslib_args(_pluslib_sdk_args)

plus_forward_cache_variables(_pluslib_options
  PATTERNS
    "^PLUS_USE_"
    "^PLUS_TEST_"
    "^PLUS_ENABLE_"
    "^PLUS_ULTRASONIX_SDK_"
    "^PLUS_Philips_"
  EXCLUDE
    PLUS_USE_POLARIS
    PLUS_USE_CERTUS
    PLUS_USE_ATRACSYS_DEVICE_TYPE
  )

set(_pluslib_submodules "")
if(PLUSBUILD_PLUSLIB_DOCUMENTATION)
  set(_pluslib_submodules "PlusDoc")
endif()

plus_add_external_project(PlusLib
  GIT_REPOSITORY "${PLUSLIB_GIT_REPOSITORY}"
  GIT_TAG "${PLUSLIB_GIT_REVISION}"
  GIT_SUBMODULES "${_pluslib_submodules}"
  DEPENDS ${PlusLib_DEPENDENCIES}
  CMAKE_CACHE_ARGS
    -DGIT_EXECUTABLE:FILEPATH=${GIT_EXECUTABLE}
    "-DCMAKE_MODULE_PATH:STRING=${CMAKE_MODULE_PATH}"
    -DVTK_DIR:PATH=${PLUS_VTK_DIR}
    -DITK_DIR:PATH=${PLUS_ITK_DIR}
    -DIGSIO_DIR:PATH=${PLUS_IGSIO_DIR}
    -DBUILD_TESTING:BOOL=${BUILD_TESTING}
    -DBUILD_SHARED_LIBS:BOOL=${PLUSBUILD_BUILD_SHARED_LIBS}
    -DBUILD_DOCUMENTATION:BOOL=${PLUSBUILD_DOCUMENTATION}
    -DBUILDNAME:STRING=${BUILDNAME}
    -DPLUS_OFFLINE_BUILD:BOOL=${PLUSBUILD_OFFLINE_BUILD}
    # Spelled differently on the two sides.
    -DPLUS_USE_SLICER:BOOL=${PLUSBUILD_USE_3DSlicer}
    -DPLUS_USE_OpenIGTLink:BOOL=${PLUSBUILD_USE_OpenIGTLink}
    -DPLUS_USE_OpenCV:BOOL=${PLUSBUILD_USE_OpenCV}
    -DPLUS_USE_aruco:BOOL=${PLUSBUILD_USE_aruco}
    -DPLUS_BUILD_WIDGETS:BOOL=${PLUSBUILD_BUILD_PLUSLIB_WIDGETS}
    -DPLUSBUILD_BUILD_PlusLib_TOOLS:BOOL=${PLUSBUILD_BUILD_PlusLib_TOOLS}
    # VTK_SRC_DIR is required to reach the private vtkpng headers used by the
    # BK ProFocus ultrasound device.
    -DVTK_SRC_DIR:PATH=${PLUS_VTK_SRC_DIR}
    ${_pluslib_options}
    ${_pluslib_sdk_args}
  )

set(PLUS_PLUSLIB_DIR "${PLUS_PlusLib_SRC_DIR}" CACHE INTERNAL "Path to store PlusLib contents.")
set(PLUSLIB_DIR "${PLUS_PlusLib_BIN_DIR}" CACHE PATH "The directory containing PlusLib binaries" FORCE)
