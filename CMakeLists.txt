cmake_minimum_required(VERSION 3.21)

# Bake in ROCm defaults so users can just `cmake ..` with no flags.
# Override on the command line if needed: `cmake -DCMAKE_HIP_COMPILER=... ..`
if(NOT DEFINED CMAKE_HIP_COMPILER)
    set(CMAKE_HIP_COMPILER /opt/rocm/bin/amdclang++)
endif()
list(APPEND CMAKE_PREFIX_PATH /opt/rocm)

project(commkit LANGUAGES CXX HIP)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_HIP_STANDARD 17)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

find_package(hip REQUIRED)

set(COMMKIT_ROOT ${CMAKE_CURRENT_SOURCE_DIR} CACHE PATH "commkit root")

add_library(commkit_core STATIC
    src/comm_group.cpp
    src/peer_mem/peer_mem_vmm.cpp
    src/peer_mem/factory.cpp
    src/tcp_store.cpp
)
set_source_files_properties(
    src/comm_group.cpp
    src/peer_mem/peer_mem_vmm.cpp
    src/peer_mem/factory.cpp
    src/tcp_store.cpp
    PROPERTIES LANGUAGE HIP
)
target_include_directories(commkit_core PUBLIC
    ${COMMKIT_ROOT}/include
)
target_link_libraries(commkit_core PUBLIC hip::host)
target_compile_options(commkit_core PRIVATE
    $<$<COMPILE_LANGUAGE:HIP>:-Wno-unused-result>
)

include(${COMMKIT_ROOT}/cmake/CommkitKernel.cmake)

# Aggregate kernel sub-projects.
# - When the top-level CMakeLists is the entry point, walk every kernel dir.
# - When a kernel sub-project bootstrapped us (COMMKIT_ONLY_KERNEL set), only
#   add that one — siblings stay out of the build.
if(DEFINED COMMKIT_ONLY_KERNEL)
    add_subdirectory(${COMMKIT_ROOT}/kernels/${COMMKIT_ONLY_KERNEL}
                     ${CMAKE_CURRENT_BINARY_DIR}/_kernel_${COMMKIT_ONLY_KERNEL})
else()
    file(GLOB kernel_dirs RELATIVE ${COMMKIT_ROOT}/kernels ${COMMKIT_ROOT}/kernels/*)
    foreach(kd ${kernel_dirs})
        if(IS_DIRECTORY ${COMMKIT_ROOT}/kernels/${kd}
           AND EXISTS ${COMMKIT_ROOT}/kernels/${kd}/CMakeLists.txt)
            add_subdirectory(kernels/${kd})
        endif()
    endforeach()
endif()
