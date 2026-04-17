# Helper for kernel sub-projects.
#
# Two ways a sub-project gets built:
#
#   1) From the top-level commkit CMakeLists (add_subdirectory). In that case
#      `commkit_core` already exists as a target, COMMKIT_ROOT is set, and the
#      hip language has been enabled by the parent.
#
#   2) Standalone: `cd kernels/foo && cmake .` In that case we bootstrap by
#      including the parent CMakeLists once, which defines commkit_core for us.

if(NOT TARGET commkit_core)
    # Standalone build path. Find COMMKIT_ROOT (../../) and pull in the parent
    # CMakeLists so commkit_core gets built.
    get_filename_component(_commkit_root "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
    set(COMMKIT_ROOT ${_commkit_root} CACHE PATH "commkit root")
endif()

function(add_commkit_kernel name)
    cmake_parse_arguments(K "" "" "SOURCES;HEADERS" ${ARGN})
    add_executable(${name} ${K_SOURCES})
    set_source_files_properties(${K_SOURCES} PROPERTIES LANGUAGE HIP)
    target_include_directories(${name} PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
    )
    target_link_libraries(${name} PRIVATE commkit_core)

    # Drop run.sh next to the binary so users can `./run.sh 8 ./test_xxx`
    # without hunting for the script.
    add_custom_command(TARGET ${name} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
                ${COMMKIT_ROOT}/scripts/run.sh
                $<TARGET_FILE_DIR:${name}>/run.sh
        VERBATIM)
endfunction()
