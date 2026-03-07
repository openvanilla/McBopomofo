cmake_minimum_required(VERSION 3.10)
project(McBopomofoLMLib)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")

add_subdirectory(gramambular2)
add_subdirectory(Mandarin)

add_library(McBopomofoLMLib
        AssociatedPhrasesV2.h
        AssociatedPhrasesV2.cpp
        ByteBlockBackedDictionary.h
        ByteBlockBackedDictionary.cpp
        McBopomofoLM.cpp
        McBopomofoLM.h
        MemoryMappedFile.h
        MemoryMappedFile.cpp
        ParselessPhraseDB.cpp
        ParselessPhraseDB.h
        ParselessLM.cpp
        ParselessLM.h
        PhraseReplacementMap.h
        PhraseReplacementMap.cpp
        UTF8Helper.h
        UTF8Helper.cpp
        UserOverrideModel.h
        UserOverrideModel.cpp
        UserPhrasesLM.h
        UserPhrasesLM.cpp
        VariantAnnotator.h
        VariantAnnotator.cpp)

if (ENABLE_CLANG_TIDY)
    set_target_properties(McBopomofoLMLib PROPERTIES CXX_CLANG_TIDY "${CLANG_TIDY_COMMAND}")
endif ()

if (ENABLE_EXPERIMENTAL_SIMD_SUPPORT_AVX512)
    include(CheckCXXCompilerFlag)
    check_cxx_compiler_flag("-mavx512f" HAS_AVX512F)
    if(HAS_AVX512F)
        message(STATUS "AVX-512 support detected")
        target_compile_options(McBopomofoLMLib PRIVATE -mavx512f -march=native -DENABLE_EXPERIMENTAL_SIMD_SUPPORT_AVX512=1)
    else()
        message(FATAL_ERROR "AVX-512 not supported by the compiler")
    endif()
endif ()

if (ENABLE_TEST)
        enable_testing()
        if (CMAKE_VERSION VERSION_GREATER_EQUAL "3.24.0")
                cmake_policy(SET CMP0135 NEW)
        endif()

        if (NOT GTest_FOUND)
            # Specify release version from https://github.com/google/googletest/releases
            set(GTEST_VERSION "v1.14.0")
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

        # Test target declarations.
        add_executable(McBopomofoLMLibTest
                AssociatedPhrasesV2Test.cpp
                ByteBlockBackedDictionaryTest.cpp
                McBopomofoLMTest.cpp
                MemoryMappedFileTest.cpp
                ParselessLMTest.cpp
                ParselessPhraseDBTest.cpp
                PhraseReplacementMapTest.cpp
                UTF8HelperTest.cpp
                UserOverrideModelTest.cpp
                UserPhrasesLMTest.cpp
                VariantAnnotatorTest.cpp)
        target_link_libraries(McBopomofoLMLibTest GTest::gtest_main McBopomofoLMLib gramambular2_lib)
        include(GoogleTest)
        gtest_discover_tests(McBopomofoLMLibTest)

        add_custom_target(
                runMcBopomofoLMLibTest
                COMMAND ${CMAKE_CURRENT_BINARY_DIR}/McBopomofoLMLibTest
        )
        add_dependencies(runMcBopomofoLMLibTest McBopomofoLMLibTest)

        # Benchmark for ByteBlockBackedDictionary; not enabled by default
        #
        # find_package(benchmark)
        # add_executable(ByteBlockBackedDictionaryBenchmark
        #         ByteBlockBackedDictionaryBenchmark.cpp)
        # target_link_libraries(ByteBlockBackedDictionaryBenchmark McBopomofoLMLib benchmark::benchmark)

        # Stressed benchmark for ParselessLM; not enabled by default
        #
        # find_package(benchmark)
        # add_executable(ParselessLMBenchmark
        #         ParselessLMBenchmark.cpp)
        # target_link_libraries(ParselessLMBenchmark McBopomofoLMLib benchmark::benchmark)
endif ()
