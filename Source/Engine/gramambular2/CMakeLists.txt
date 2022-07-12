cmake_minimum_required(VERSION 3.6)
project(gramambular2)

set(CMAKE_CXX_STANDARD 17)
set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")

add_library(gramambular2_lib language_model.h reading_grid.h reading_grid.cpp)

# Let CMake fetch Google Test for us.
# https://github.com/google/googletest/tree/main/googletest#incorporating-into-an-existing-cmake-project
include(FetchContent)

FetchContent_Declare(
        googletest
        # Specify the commit you depend on and update it regularly.
        URL https://github.com/google/googletest/archive/609281088cfefc76f9d0ce82e1ff6c30cc3591e5.zip
)
# For Windows: Prevent overriding the parent project's compiler/linker settings
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

# Test target declarations.
add_executable(gramambular2_test reading_grid_test.cpp)
target_include_directories(gramambular2_test PRIVATE "${GMOCK_INCLUDE_DIRS}" "${GTEST_INCLUDE_DIRS}")
target_link_libraries(gramambular2_test gtest_main gramambular2_lib)
include(GoogleTest)
gtest_discover_tests(gramambular2_test)

add_custom_target(
        runGramambular2Test
        COMMAND ${CMAKE_CURRENT_BINARY_DIR}/gramambular2_test
)
add_dependencies(runGramambular2Test gramambular2_test)
