cmake_minimum_required(VERSION 3.21)

# Standalone bootstrap: if invoked directly (not via parent add_subdirectory),
# fall through to the top-level CMakeLists, which will then loop back here.
if(NOT TARGET commkit_core)
    project(demo_standalone LANGUAGES CXX HIP)
    set(COMMKIT_ONLY_KERNEL gfx9/demo CACHE STRING "" FORCE)
    add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../../..
                     ${CMAKE_CURRENT_BINARY_DIR}/_commkit)
    return()
endif()

include(${COMMKIT_ROOT}/cmake/CommkitKernel.cmake)

add_commkit_kernel(test_sync_demo
    SOURCES test.cpp
    HEADERS sync_demo.cuh bench_sync.cuh
)

add_commkit_kernel(test_start_sync
    SOURCES test_start_sync.cpp
    HEADERS start_sync_demo.cuh
)

add_commkit_kernel(test_local_vs_remote
    SOURCES test_local_vs_remote.cpp
    HEADERS local_vs_remote.cuh
)

add_commkit_kernel(test_copy_kernel1
    SOURCES test_copy_kernel1.cpp
    HEADERS copy_kernel1.cuh
)

add_commkit_kernel(test_copy_kernel2
    SOURCES test_copy_kernel2.cpp
    HEADERS copy_kernel2.cuh
)

# Custom target: device-only assembly for the kernel that inlines both
# end_sync_ori and end_sync_. Output: build/.../asm_sync_demo.s
set(_asm_src ${CMAKE_CURRENT_SOURCE_DIR}/asm.cu)
set(_asm_out ${CMAKE_CURRENT_BINARY_DIR}/asm_sync_demo.s)

# Pull include dirs from commkit_core so the standalone amdclang++ invocation
# resolves commkit/* and opus/* the same way the test build does.
get_target_property(_commkit_includes commkit_core INTERFACE_INCLUDE_DIRECTORIES)
set(_inc_flags "")
foreach(d ${_commkit_includes})
    list(APPEND _inc_flags -I${d})
endforeach()
list(APPEND _inc_flags -I${CMAKE_CURRENT_SOURCE_DIR})

add_custom_command(
    OUTPUT ${_asm_out}
    COMMAND ${CMAKE_HIP_COMPILER}
            -x hip --cuda-device-only --offload-arch=gfx942
            -O3 -std=c++17 -S
            ${_inc_flags}
            ${_asm_src}
            -o ${_asm_out}
    DEPENDS ${_asm_src} sync_demo.cuh
    COMMENT "Generating device assembly: ${_asm_out}"
    VERBATIM)

add_custom_target(asm_sync_demo ALL DEPENDS ${_asm_out})

# Same recipe for local_vs_remote_rw_demo. Output: build/.../asm_local_vs_remote.s
set(_asm_lvr_src ${CMAKE_CURRENT_SOURCE_DIR}/asm_local_vs_remote.cu)
set(_asm_lvr_out ${CMAKE_CURRENT_BINARY_DIR}/asm_local_vs_remote.s)

add_custom_command(
    OUTPUT ${_asm_lvr_out}
    COMMAND ${CMAKE_HIP_COMPILER}
            -x hip --cuda-device-only --offload-arch=gfx942
            -O3 -std=c++17 -S
            ${_inc_flags}
            ${_asm_lvr_src}
            -o ${_asm_lvr_out}
    DEPENDS ${_asm_lvr_src} local_vs_remote.cuh
    COMMENT "Generating device assembly: ${_asm_lvr_out}"
    VERBATIM)

add_custom_target(asm_local_vs_remote ALL DEPENDS ${_asm_lvr_out})
