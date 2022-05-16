cmake_minimum_required(VERSION 3.17)
project(Gramambular)

set(CMAKE_CXX_STANDARD 17)

add_library(GramambularLib BlockReadingBuilder.h Gramambular.h Grid.h Grid.cpp KeyValuePair.h LanguageModel.h Node.h NodeAnchor.h Span.h Unigram.h Walker.h)

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
add_executable(GramambularTest GramambularTest.cpp)
target_link_libraries(GramambularTest gtest_main GramambularLib)
include(GoogleTest)
gtest_discover_tests(GramambularTest)

add_custom_target(
        runTest
        COMMAND ${CMAKE_CURRENT_BINARY_DIR}/GramambularTest
)
add_dependencies(runTest GramambularTest)
