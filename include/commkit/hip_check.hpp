#pragma once

#include <cstdio>
#include <cstdlib>
#include <hip/hip_runtime.h>

#define COMMKIT_HIP_CALL(call)                                                  \
    do {                                                                        \
        hipError_t _e = (call);                                                 \
        if (_e != hipSuccess) {                                                 \
            std::fprintf(stderr,                                                \
                         "[commkit] %s:%d HIP error: %s (%d) on `%s`\n",       \
                         __FILE__, __LINE__,                                    \
                         hipGetErrorString(_e), int(_e), #call);               \
            std::abort();                                                       \
        }                                                                       \
    } while (0)

#define COMMKIT_CHECK(cond, ...)                                                \
    do {                                                                        \
        if (!(cond)) {                                                          \
            std::fprintf(stderr, "[commkit] %s:%d check failed: %s\n",         \
                         __FILE__, __LINE__, #cond);                            \
            std::abort();                                                       \
        }                                                                       \
    } while (0)
