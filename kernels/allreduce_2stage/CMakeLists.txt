cmake_minimum_required(VERSION 3.21)

if(NOT TARGET commkit_core)
    project(allreduce_2stage_standalone LANGUAGES CXX HIP)
    set(COMMKIT_ONLY_KERNEL allreduce_2stage CACHE STRING "" FORCE)
    add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../..
                     ${CMAKE_CURRENT_BINARY_DIR}/_commkit)
    return()
endif()

include(${COMMKIT_ROOT}/cmake/CommkitKernel.cmake)

add_commkit_kernel(test_allreduce_2stage
    SOURCES test.cpp
    HEADERS kernel.cuh
)

add_commkit_kernel(test_allreduce_2stage_tp4
    SOURCES test_tp4.cpp
    HEADERS kernel.cuh
)

add_commkit_kernel(test_allreduce_2stage_tp4_overlap
    SOURCES test_tp4_overlap.cpp
    HEADERS kernel.cuh block_size_256_kernel_tp4.cuh
)

add_commkit_kernel(test_allreduce_2stage_grid16
    SOURCES test_grid16.cpp
    HEADERS kernel.cuh
)

add_commkit_kernel(test_allreduce_2stage_att
    SOURCES test_att.cpp
    HEADERS kernel.cuh
)
