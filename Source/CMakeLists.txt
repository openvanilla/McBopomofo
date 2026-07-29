# Top-level configuration for building McBopomofo's engine.

cmake_minimum_required(VERSION 3.12)
project(McBopomofoCore VERSION 3.0)

option(ENABLE_TEST "Build Test" On)
option(ENABLE_ENGINE_PROFILE "Build the engine profiling workload" Off)

if (CMAKE_VERSION VERSION_GREATER_EQUAL "3.23.0")
    find_package(GTest)
endif()

if (ENABLE_TEST)
        enable_testing()
        if (CMAKE_VERSION VERSION_GREATER_EQUAL "3.24.0")
                cmake_policy(SET CMP0135 NEW)
        endif()

        if (NOT GTest_FOUND)
            # Specify release version from https://github.com/google/googletest/releases
            set(GTEST_VERSION "v1.17.0")
            MESSAGE(STATUS "Fetching GoogleTest ${GTEST_VERSION} from GitHub")
            # Let CMake fetch Google Test for us.
            # https://github.com/google/googletest/tree/main/googletest#incorporating-into-an-existing-cmake-project
            include(FetchContent)

            FetchContent_Declare(
                    googletest
                    URL "https://github.com/google/googletest/archive/refs/tags/${GTEST_VERSION}.zip"
            )
            # For Windows: Prevent overriding the parent project's compiler/linker settings
            set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
            FetchContent_MakeAvailable(googletest)
        endif()
endif ()

add_subdirectory(Engine)
