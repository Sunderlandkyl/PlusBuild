# libusb is downloaded prebuilt on Windows and expected from the distribution
# everywhere else (apt install libusb-1.0-0-dev, brew install libusb).
if(WIN32)
  set(LibUSB_SRC "${CMAKE_BINARY_DIR}/Deps/libusb")

  plus_add_external_project(LibUSB
    URL "https://sourceforge.net/projects/libusb/files/libusb-1.0/libusb-1.0.22/libusb-1.0.22.7z/download"
    SOURCE_DIR "${LibUSB_SRC}"
    BINARY_DIR "${LibUSB_SRC}"
    PREFIX "${CMAKE_BINARY_DIR}/Deps/libusb-prefix"
    DOWNLOAD_ONLY
    )

  set(LibUSB_ROOT_DIR "${LibUSB_SRC}")
  set(LibUSB_INCLUDE_DIRS "${LibUSB_SRC}/include")
  set(LibUSB_INCLUDES "${LibUSB_SRC}/include")
  set(LIBUSB_INCLUDE_DIR "${LibUSB_SRC}/include")
  if(MSVC)
    set(LibUSB_LIBRARY_DIR "${LibUSB_SRC}/MS32/dll")
  else()
    set(LibUSB_LIBRARY_DIR "${LibUSB_SRC}/MinGW32/dll")
  endif()
  set(LIBUSB_LIBRARY "${LibUSB_LIBRARY_DIR}/libusb-1.0.lib")
else()
  # Located rather than assumed to be at a fixed path: the previous code
  # required /usr/include/LibUSB-1.0, which is the wrong case and so never
  # existed on a case-sensitive filesystem.
  find_path(LIBUSB_INCLUDE_DIR
    NAMES libusb.h
    PATH_SUFFIXES libusb-1.0
    DOC "Directory containing libusb.h"
    )
  find_library(LIBUSB_LIBRARY NAMES usb-1.0 DOC "The libusb library")
  if(NOT LIBUSB_INCLUDE_DIR OR NOT LIBUSB_LIBRARY)
    message(FATAL_ERROR "libusb is required but was not found. Install it (libusb-1.0-0-dev on Debian and Ubuntu, libusb via Homebrew) or turn off PLUS_USE_INFRARED_SEEK_CAM.")
  endif()

  get_filename_component(LibUSB_ROOT_DIR "${LIBUSB_INCLUDE_DIR}" DIRECTORY)
  set(LibUSB_INCLUDE_DIRS "${LIBUSB_INCLUDE_DIR}")
  set(LibUSB_INCLUDES "${LIBUSB_INCLUDE_DIR}")
  set(LibUSB_LIBS "${LIBUSB_LIBRARY}")
endif()
