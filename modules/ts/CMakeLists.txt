set(the_description "The ts module")

if(IOS)
  ocv_module_disable(ts)
endif()

set(OPENCV_MODULE_TYPE STATIC)
set(OPENCV_MODULE_IS_PART_OF_WORLD FALSE)
if(WINRT)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /ZW")
  set(TEST_DATA_PATH $ENV{OPENCV_TEST_DATA_PATH})
  if("${TEST_DATA_PATH}" STREQUAL "")
    message(WARNING "OPENCV_TEST_DATA_PATH environment variable is empty. Please set it to 'opencv_extra/testdata' location to get correct results")
  else()
    string(REPLACE "\\" "\\\\" TEST_DATA_PATH ${TEST_DATA_PATH})
  endif()
  add_definitions("-DOPENCV_TEST_DATA_PATH=\"${TEST_DATA_PATH}\"")
endif()

ocv_warnings_disable(CMAKE_CXX_FLAGS -Wundef)

ocv_add_module(ts opencv_core opencv_imgproc opencv_imgcodecs opencv_videoio)

ocv_glob_module_sources()
ocv_module_include_directories()
ocv_create_module()
