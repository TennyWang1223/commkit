cmake_minimum_required(VERSION 3.21)

if(NOT TARGET commkit_core)
    project(proto_poc_standalone LANGUAGES CXX HIP)
    set(COMMKIT_ONLY_KERNEL gfx9/proto_poc CACHE STRING "" FORCE)
    add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../../..
                     ${CMAKE_CURRENT_BINARY_DIR}/_commkit)
    return()
endif()

include(${COMMKIT_ROOT}/cmake/CommkitKernel.cmake)

add_commkit_kernel(test_ll_allgather
    SOURCES LL_proto_poc.cu
    HEADERS ll_allgather.cuh copy_allgather.cuh
)
