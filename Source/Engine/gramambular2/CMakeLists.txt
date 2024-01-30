cmake_minimum_required(VERSION 3.6)
project(gramambular2)

set(CMAKE_CXX_STANDARD 17)
set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")

add_library(gramambular2_lib language_model.h reading_grid.h reading_grid.cpp)

if (ENABLE_CLANG_TIDY)
    set_target_properties(gramambular2_lib PROPERTIES CXX_CLANG_TIDY "${CLANG_TIDY_COMMAND}")
endif ()

if (ENABLE_TEST)
        enable_testing()
        if (CMAKE_VERSION VERSION_GREATER_EQUAL "3.24.0")
                cmake_policy(SET CMP0135 NEW)
        endif()

        # Test target declarations.
        add_executable(gramambular2_test reading_grid_test.cpp)
        target_include_directories(gramambular2_test PRIVATE "${GMOCK_INCLUDE_DIRS}" "${GTEST_INCLUDE_DIRS}")
        target_link_libraries(gramambular2_test GTest::gtest_main gramambular2_lib)
        include(GoogleTest)
        gtest_discover_tests(gramambular2_test)

        add_custom_target(
                runGramambular2Test
                COMMAND ${CMAKE_CURRENT_BINARY_DIR}/gramambular2_test
        )
        add_dependencies(runGramambular2Test gramambular2_test)
endif ()
