cmake_minimum_required(VERSION 3.21)

# Standalone bootstrap: if invoked directly (not via parent add_subdirectory),
# fall through to the top-level CMakeLists, which will then loop back here.
if(NOT TARGET commkit_core)
    project(allreduce_1stage_standalone LANGUAGES CXX HIP)
    set(COMMKIT_ONLY_KERNEL allreduce_1stage CACHE STRING "" FORCE)
    add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../..
                     ${CMAKE_CURRENT_BINARY_DIR}/_commkit)
    return()
endif()

include(${COMMKIT_ROOT}/cmake/CommkitKernel.cmake)

add_commkit_kernel(test_allreduce_1stage
    SOURCES test.cpp
    HEADERS kernel.cuh
)
