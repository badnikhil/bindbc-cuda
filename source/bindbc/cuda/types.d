/+
+          Copyright 2026 Nikhil
+ Distributed under the Boost Software License, Version 1.0.
+     (See accompanying file LICENSE_1_0.txt or copy at
+           http://www.boost.org/LICENSE_1_0.txt)
+/
/// D translations of CUDA Driver API types, handles, and enumerations.
module bindbc.cuda.types;

// Opaque handle types

alias CUdevice = int;

/// Device pointer type. The CUDA Driver API defines this as a 64-bit unsigned
/// integer for device memory addresses regardless of host pointer size.
alias CUdeviceptr = ulong;

struct CUctx_st;
alias CUcontext = CUctx_st*;

struct CUmod_st;
alias CUmodule = CUmod_st*;

struct CUfunc_st;
alias CUfunction = CUfunc_st*;

struct CUstream_st;
alias CUstream = CUstream_st*;

struct CUevent_st;
alias CUevent = CUevent_st*;

// Enumerations

enum CUresult {
    CUDA_SUCCESS                              = 0,
    CUDA_ERROR_INVALID_VALUE                  = 1,
    CUDA_ERROR_OUT_OF_MEMORY                  = 2,
    CUDA_ERROR_NOT_INITIALIZED                = 3,
    CUDA_ERROR_DEINITIALIZED                  = 4,
    CUDA_ERROR_PROFILER_DISABLED              = 5,
    CUDA_ERROR_PROFILER_NOT_INITIALIZED       = 6,
    CUDA_ERROR_PROFILER_ALREADY_STARTED       = 7,
    CUDA_ERROR_PROFILER_ALREADY_STOPPED       = 8,
    CUDA_ERROR_NO_DEVICE                      = 100,
    CUDA_ERROR_INVALID_DEVICE                 = 101,
    CUDA_ERROR_INVALID_IMAGE                  = 200,
    CUDA_ERROR_INVALID_CONTEXT                = 201,
    CUDA_ERROR_CONTEXT_ALREADY_CURRENT        = 202,
    CUDA_ERROR_MAP_FAILED                     = 205,
    CUDA_ERROR_UNMAP_FAILED                   = 206,
    CUDA_ERROR_ARRAY_IS_MAPPED                = 207,
    CUDA_ERROR_ALREADY_MAPPED                 = 208,
    CUDA_ERROR_NO_BINARY_FOR_GPU              = 209,
    CUDA_ERROR_ALREADY_ACQUIRED               = 210,
    CUDA_ERROR_NOT_MAPPED                     = 211,
    CUDA_ERROR_NOT_MAPPED_AS_ARRAY            = 212,
    CUDA_ERROR_NOT_MAPPED_AS_POINTER          = 213,
    CUDA_ERROR_ECC_UNCORRECTABLE              = 214,
    CUDA_ERROR_UNSUPPORTED_LIMIT              = 215,
    CUDA_ERROR_CONTEXT_ALREADY_IN_USE         = 216,
    CUDA_ERROR_PEER_ACCESS_UNSUPPORTED        = 217,
    CUDA_ERROR_INVALID_PTX                    = 218,
    CUDA_ERROR_INVALID_GRAPHICS_CONTEXT       = 219,
    CUDA_ERROR_NVLINK_UNCORRECTABLE           = 220,
    CUDA_ERROR_JIT_COMPILER_NOT_FOUND         = 221,
    CUDA_ERROR_INVALID_SOURCE                 = 300,
    CUDA_ERROR_FILE_NOT_FOUND                 = 301,
    CUDA_ERROR_SHARED_OBJECT_SYMBOL_NOT_FOUND = 302,
    CUDA_ERROR_SHARED_OBJECT_INIT_FAILED      = 303,
    CUDA_ERROR_OPERATING_SYSTEM               = 304,
    CUDA_ERROR_INVALID_HANDLE                 = 400,
    CUDA_ERROR_NOT_FOUND                      = 500,
    CUDA_ERROR_NOT_READY                      = 600,
    CUDA_ERROR_ILLEGAL_ADDRESS                = 700,
    CUDA_ERROR_LAUNCH_OUT_OF_RESOURCES        = 701,
    CUDA_ERROR_LAUNCH_TIMEOUT                 = 702,
    CUDA_ERROR_LAUNCH_INCOMPATIBLE_TEXTURING  = 703,
    CUDA_ERROR_PEER_ACCESS_ALREADY_ENABLED    = 704,
    CUDA_ERROR_PEER_ACCESS_NOT_ENABLED        = 705,
    CUDA_ERROR_PRIMARY_CONTEXT_ACTIVE         = 708,
    CUDA_ERROR_CONTEXT_IS_DESTROYED           = 709,
    CUDA_ERROR_ASSERT                         = 710,
    CUDA_ERROR_TOO_MANY_PEERS                 = 711,
    CUDA_ERROR_HOST_MEMORY_ALREADY_REGISTERED = 712,
    CUDA_ERROR_HOST_MEMORY_NOT_REGISTERED     = 713,
    CUDA_ERROR_HARDWARE_STACK_ERROR           = 714,
    CUDA_ERROR_ILLEGAL_INSTRUCTION            = 715,
    CUDA_ERROR_MISALIGNED_ADDRESS             = 716,
    CUDA_ERROR_INVALID_ADDRESS_SPACE          = 717,
    CUDA_ERROR_INVALID_PC                     = 718,
    CUDA_ERROR_LAUNCH_FAILED                  = 719,
    CUDA_ERROR_COOPERATIVE_LAUNCH_TOO_LARGE   = 720,
    CUDA_ERROR_SYSTEM_NOT_READY               = 802,
    CUDA_ERROR_SYSTEM_DRIVER_MISMATCH         = 803,
    CUDA_ERROR_UNKNOWN                        = 999,
}

enum CUdevice_attribute {
    CU_DEVICE_ATTRIBUTE_MAX_THREADS_PER_BLOCK             = 1,
    CU_DEVICE_ATTRIBUTE_MAX_BLOCK_DIM_X                   = 2,
    CU_DEVICE_ATTRIBUTE_MAX_BLOCK_DIM_Y                   = 3,
    CU_DEVICE_ATTRIBUTE_MAX_BLOCK_DIM_Z                   = 4,
    CU_DEVICE_ATTRIBUTE_MAX_GRID_DIM_X                    = 5,
    CU_DEVICE_ATTRIBUTE_MAX_GRID_DIM_Y                    = 6,
    CU_DEVICE_ATTRIBUTE_MAX_GRID_DIM_Z                    = 7,
    CU_DEVICE_ATTRIBUTE_MAX_SHARED_MEMORY_PER_BLOCK       = 8,
    CU_DEVICE_ATTRIBUTE_TOTAL_CONSTANT_MEMORY             = 9,
    CU_DEVICE_ATTRIBUTE_WARP_SIZE                         = 10,
    CU_DEVICE_ATTRIBUTE_MAX_PITCH                         = 11,
    CU_DEVICE_ATTRIBUTE_MAX_REGISTERS_PER_BLOCK           = 12,
    CU_DEVICE_ATTRIBUTE_CLOCK_RATE                        = 13,
    CU_DEVICE_ATTRIBUTE_TEXTURE_ALIGNMENT                 = 14,
    CU_DEVICE_ATTRIBUTE_GPU_OVERLAP                       = 15,
    CU_DEVICE_ATTRIBUTE_MULTIPROCESSOR_COUNT              = 16,
    CU_DEVICE_ATTRIBUTE_KERNEL_EXEC_TIMEOUT               = 17,
    CU_DEVICE_ATTRIBUTE_INTEGRATED                        = 18,
    CU_DEVICE_ATTRIBUTE_CAN_MAP_HOST_MEMORY               = 19,
    CU_DEVICE_ATTRIBUTE_COMPUTE_MODE                      = 20,
    CU_DEVICE_ATTRIBUTE_CONCURRENT_KERNELS                = 31,
    CU_DEVICE_ATTRIBUTE_ECC_ENABLED                       = 32,
    CU_DEVICE_ATTRIBUTE_PCI_BUS_ID                        = 33,
    CU_DEVICE_ATTRIBUTE_PCI_DEVICE_ID                     = 34,
    CU_DEVICE_ATTRIBUTE_TCC_DRIVER                        = 35,
    CU_DEVICE_ATTRIBUTE_MEMORY_CLOCK_RATE                 = 36,
    CU_DEVICE_ATTRIBUTE_GLOBAL_MEMORY_BUS_WIDTH           = 37,
    CU_DEVICE_ATTRIBUTE_L2_CACHE_SIZE                     = 38,
    CU_DEVICE_ATTRIBUTE_MAX_THREADS_PER_MULTIPROCESSOR    = 39,
    CU_DEVICE_ATTRIBUTE_ASYNC_ENGINE_COUNT                = 40,
    CU_DEVICE_ATTRIBUTE_UNIFIED_ADDRESSING                = 41,
    CU_DEVICE_ATTRIBUTE_COMPUTE_CAPABILITY_MAJOR          = 75,
    CU_DEVICE_ATTRIBUTE_COMPUTE_CAPABILITY_MINOR          = 76,
    CU_DEVICE_ATTRIBUTE_MANAGED_MEMORY                    = 83,
    CU_DEVICE_ATTRIBUTE_MULTI_GPU_BOARD                   = 84,
    CU_DEVICE_ATTRIBUTE_COOPERATIVE_LAUNCH                = 95,
    CU_DEVICE_ATTRIBUTE_MAX_SHARED_MEMORY_PER_BLOCK_OPTIN = 97,
}

/// Context creation flags.
enum CUctx_flags {
    CU_CTX_SCHED_AUTO          = 0x00,
    CU_CTX_SCHED_SPIN          = 0x01,
    CU_CTX_SCHED_YIELD         = 0x02,
    CU_CTX_SCHED_BLOCKING_SYNC = 0x04,
    CU_CTX_SCHED_MASK          = 0x07,
    CU_CTX_MAP_HOST            = 0x08,
    CU_CTX_LMEM_RESIZE_TO_MAX  = 0x10,
    CU_CTX_FLAGS_MASK          = 0x1F,
}

/// Memory allocation flags for cuMemHostAlloc.
enum CUmemhostalloc_flags {
    CU_MEMHOSTALLOC_PORTABLE      = 0x01,
    CU_MEMHOSTALLOC_DEVICEMAP     = 0x02,
    CU_MEMHOSTALLOC_WRITECOMBINED = 0x04,
}

/// Event creation flags.
enum CUevent_flags {
    CU_EVENT_DEFAULT        = 0x0,
    CU_EVENT_BLOCKING_SYNC  = 0x1,
    CU_EVENT_DISABLE_TIMING = 0x2,
    CU_EVENT_INTERPROCESS   = 0x4,
}
