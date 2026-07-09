cmake_minimum_required(VERSION 3.21)

if(NOT TARGET commkit_core)
    project(reduce_scatter_standalone LANGUAGES CXX HIP)
    set(COMMKIT_ONLY_KERNEL gfx9/reduce_scatter CACHE STRING "" FORCE)
    add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../../..
                     ${CMAKE_CURRENT_BINARY_DIR}/_commkit)
    return()
endif()

include(${COMMKIT_ROOT}/cmake/CommkitKernel.cmake)

add_commkit_kernel(test_reduce_scatter
    SOURCES test.cpp
    HEADERS kernel.cuh
)
