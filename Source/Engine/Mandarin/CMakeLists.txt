cmake_minimum_required(VERSION 3.6)
project(Mandarin)

set(CMAKE_CXX_STANDARD 17)
set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")

add_library(MandarinLib Mandarin.h Mandarin.cpp)

if (ENABLE_CLANG_TIDY)
    set_target_properties(MandarinLib PROPERTIES CXX_CLANG_TIDY "${CLANG_TIDY_COMMAND}")
endif ()

if (ENABLE_TEST)
        enable_testing()
        if (CMAKE_VERSION VERSION_GREATER_EQUAL "3.24.0")
                cmake_policy(SET CMP0135 NEW)
        endif()

        # Test target declarations.
        add_executable(MandarinTest MandarinTest.cpp)
        target_link_libraries(MandarinTest GTest::gtest_main MandarinLib)
        include(GoogleTest)
        gtest_discover_tests(MandarinTest)

        add_custom_target(
                runMandarinTest
                COMMAND ${CMAKE_CURRENT_BINARY_DIR}/MandarinTest
        )
        add_dependencies(runMandarinTest MandarinTest)
endif ()
