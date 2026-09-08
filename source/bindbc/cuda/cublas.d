/+
+          Copyright 2026 Nikhil
+ Distributed under the Boost Software License, Version 1.0.
+     (See accompanying file LICENSE_1_0.txt or copy at
+           http://www.boost.org/LICENSE_1_0.txt)
+/
/++
D bindings for the NVIDIA cuBLAS library.

cuBLAS ships as a separate shared library from the CUDA Driver API, so it has
its own loader: call `loadCUBLAS()` in addition to `loadCUDA()`.

$(B Matrices are column-major.) cuBLAS follows the Fortran BLAS convention.
A row-major `m x n` matrix is bit-identical in memory to a column-major
`n x m` matrix, so row-major operands are handled by swapping them and the
`m`/`n` extents rather than by transposing or copying:

---
// Row-major A (M x K), B (K x N), C (M x N); computes C = A * B.
// Uses the identity C^T = B^T * A^T.
cublasSgemm(handle,
    cublasOperation_t.CUBLAS_OP_N, cublasOperation_t.CUBLAS_OP_N,
    N, M, K,                      // N and M swapped
    &alpha,
    cast(const(float)*)dB, N,     // B passed first
    cast(const(float)*)dA, K,
    &beta,
    cast(float*)dC, N);
---

The matrix and vector arguments are $(B device) addresses. They are declared
here exactly as the C headers declare them (`float*`, `void*`, ...), so
`CUdeviceptr` values from `cuMemAlloc` are passed with a cast.
+/
module bindbc.cuda.cublas;

import bindbc.cuda.config;
import bindbc.cuda.types;

// Version constants (from cublas_api.h)

enum CUBLAS_VER_MAJOR = 12;
enum CUBLAS_VER_MINOR = 0;
enum CUBLAS_VER_PATCH = 2;
enum CUBLAS_VER_BUILD = 224;
enum CUBLAS_VERSION = CUBLAS_VER_MAJOR * 10000 + CUBLAS_VER_MINOR * 100 + CUBLAS_VER_PATCH;

// Opaque handle types

struct cublasContext;
alias cublasHandle_t = cublasContext*;

/// Callback invoked by the cuBLAS logger, if one is installed.
alias cublasLogCallback = extern(C) void function(const(char)* msg) @nogc nothrow;

// Enumerations

/// Status code returned by every cuBLAS entry point.
enum cublasStatus_t {
    CUBLAS_STATUS_SUCCESS          = 0,
    CUBLAS_STATUS_NOT_INITIALIZED  = 1,
    CUBLAS_STATUS_ALLOC_FAILED     = 3,
    CUBLAS_STATUS_INVALID_VALUE    = 7,
    CUBLAS_STATUS_ARCH_MISMATCH    = 8,
    CUBLAS_STATUS_MAPPING_ERROR    = 11,
    CUBLAS_STATUS_EXECUTION_FAILED = 13,
    CUBLAS_STATUS_INTERNAL_ERROR   = 14,
    CUBLAS_STATUS_NOT_SUPPORTED    = 15,
    CUBLAS_STATUS_LICENSE_ERROR    = 16,
}

/// Whether a matrix operand is used as-is, transposed, or conjugate-transposed.
enum cublasOperation_t {
    CUBLAS_OP_N        = 0,
    CUBLAS_OP_T        = 1,
    CUBLAS_OP_C        = 2,
    CUBLAS_OP_HERMITAN = 2,  /// Synonym for CUBLAS_OP_C.
    CUBLAS_OP_CONJG    = 3,  /// Placeholder; not supported by the current library.
}

/// Which triangle of a symmetric/hermitian matrix is referenced.
enum cublasFillMode_t {
    CUBLAS_FILL_MODE_LOWER = 0,
    CUBLAS_FILL_MODE_UPPER = 1,
    CUBLAS_FILL_MODE_FULL  = 2,
}

/// Whether a triangular matrix has a unit diagonal.
enum cublasDiagType_t {
    CUBLAS_DIAG_NON_UNIT = 0,
    CUBLAS_DIAG_UNIT     = 1,
}

/// Which side a triangular/symmetric operand multiplies from.
enum cublasSideMode_t {
    CUBLAS_SIDE_LEFT  = 0,
    CUBLAS_SIDE_RIGHT = 1,
}

/// Whether scalar arguments (alpha/beta) and results live in host or device memory.
enum cublasPointerMode_t {
    CUBLAS_POINTER_MODE_HOST   = 0,
    CUBLAS_POINTER_MODE_DEVICE = 1,
}

/// Whether routines may use atomics, which makes them non-deterministic.
enum cublasAtomicsMode_t {
    CUBLAS_ATOMICS_NOT_ALLOWED = 0,
    CUBLAS_ATOMICS_ALLOWED     = 1,
}

/// Math mode: opts into (or out of) tensor-core acceleration.
enum cublasMath_t {
    CUBLAS_DEFAULT_MATH = 0,
    /// Deprecated; same effect as CUBLAS_COMPUTE_32F_FAST_16F.
    CUBLAS_TENSOR_OP_MATH = 1,
    /// Use the matching _PEDANTIC compute type.
    CUBLAS_PEDANTIC_MATH = 2,
    /// Allow accelerating single-precision routines with TF32 tensor cores.
    CUBLAS_TF32_TENSOR_OP_MATH = 3,
    /// Force reductions to use the accumulator type rather than the output type.
    CUBLAS_MATH_DISALLOW_REDUCED_PRECISION_REDUCTION = 16,
}

/// GEMM algorithm selector. Only the DEFAULT entries are useful on modern
/// hardware; the numbered algorithms are legacy and ignored on Volta and later.
enum cublasGemmAlgo_t {
    CUBLAS_GEMM_DFALT             = -1,
    CUBLAS_GEMM_DEFAULT           = -1,
    CUBLAS_GEMM_ALGO0             = 0,
    CUBLAS_GEMM_ALGO1             = 1,
    CUBLAS_GEMM_ALGO2             = 2,
    CUBLAS_GEMM_ALGO3             = 3,
    CUBLAS_GEMM_ALGO4             = 4,
    CUBLAS_GEMM_ALGO5             = 5,
    CUBLAS_GEMM_ALGO6             = 6,
    CUBLAS_GEMM_ALGO7             = 7,
    CUBLAS_GEMM_ALGO8             = 8,
    CUBLAS_GEMM_ALGO9             = 9,
    CUBLAS_GEMM_ALGO10            = 10,
    CUBLAS_GEMM_ALGO11            = 11,
    CUBLAS_GEMM_ALGO12            = 12,
    CUBLAS_GEMM_ALGO13            = 13,
    CUBLAS_GEMM_ALGO14            = 14,
    CUBLAS_GEMM_ALGO15            = 15,
    CUBLAS_GEMM_ALGO16            = 16,
    CUBLAS_GEMM_ALGO17            = 17,
    CUBLAS_GEMM_ALGO18            = 18,
    CUBLAS_GEMM_ALGO19            = 19,
    CUBLAS_GEMM_ALGO20            = 20,
    CUBLAS_GEMM_ALGO21            = 21,
    CUBLAS_GEMM_ALGO22            = 22,
    CUBLAS_GEMM_ALGO23            = 23,
    CUBLAS_GEMM_DEFAULT_TENSOR_OP = 99,
    CUBLAS_GEMM_DFALT_TENSOR_OP   = 99,
    CUBLAS_GEMM_ALGO0_TENSOR_OP   = 100,
    CUBLAS_GEMM_ALGO1_TENSOR_OP   = 101,
    CUBLAS_GEMM_ALGO2_TENSOR_OP   = 102,
    CUBLAS_GEMM_ALGO3_TENSOR_OP   = 103,
    CUBLAS_GEMM_ALGO4_TENSOR_OP   = 104,
    CUBLAS_GEMM_ALGO5_TENSOR_OP   = 105,
    CUBLAS_GEMM_ALGO6_TENSOR_OP   = 106,
    CUBLAS_GEMM_ALGO7_TENSOR_OP   = 107,
    CUBLAS_GEMM_ALGO8_TENSOR_OP   = 108,
    CUBLAS_GEMM_ALGO9_TENSOR_OP   = 109,
    CUBLAS_GEMM_ALGO10_TENSOR_OP  = 110,
    CUBLAS_GEMM_ALGO11_TENSOR_OP  = 111,
    CUBLAS_GEMM_ALGO12_TENSOR_OP  = 112,
    CUBLAS_GEMM_ALGO13_TENSOR_OP  = 113,
    CUBLAS_GEMM_ALGO14_TENSOR_OP  = 114,
    CUBLAS_GEMM_ALGO15_TENSOR_OP  = 115,
}

/++
Internal compute precision for `cublasGemmEx`.

_PEDANTIC types force standard arithmetic and the exact stated storage format;
_FAST types trade precision for throughput.

Note: CUDA 10.x declared `cublasGemmEx`'s `computeType` parameter as
`cudaDataType` rather than `cublasComputeType_t`. Both are C enums and so the
ABI is identical; only the legal values differ.
+/
enum cublasComputeType_t {
    CUBLAS_COMPUTE_16F           = 64,  /// half, default
    CUBLAS_COMPUTE_16F_PEDANTIC  = 65,  /// half, pedantic
    CUBLAS_COMPUTE_32F           = 68,  /// float, default
    CUBLAS_COMPUTE_32F_PEDANTIC  = 69,  /// float, pedantic
    CUBLAS_COMPUTE_32F_FAST_16F  = 74,  /// float, may down-convert inputs to half or TF32
    CUBLAS_COMPUTE_32F_FAST_16BF = 75,  /// float, may down-convert inputs to bfloat16 or TF32
    CUBLAS_COMPUTE_32F_FAST_TF32 = 77,  /// float, may down-convert inputs to TF32
    CUBLAS_COMPUTE_64F           = 70,  /// double, default
    CUBLAS_COMPUTE_64F_PEDANTIC  = 71,  /// double, pedantic
    CUBLAS_COMPUTE_32I           = 72,  /// signed 32-bit int, default
    CUBLAS_COMPUTE_32I_PEDANTIC  = 73,  /// signed 32-bit int, pedantic
}

/// Element type of an operand passed to the `Ex` entry points
/// (from CUDA's `library_types.h`).
enum cudaDataType {
    CUDA_R_16F     = 2,   /// real half
    CUDA_C_16F     = 6,   /// complex pair of halves
    CUDA_R_16BF    = 14,  /// real bfloat16
    CUDA_C_16BF    = 15,  /// complex pair of bfloat16
    CUDA_R_32F     = 0,   /// real float
    CUDA_C_32F     = 4,   /// complex pair of floats
    CUDA_R_64F     = 1,   /// real double
    CUDA_C_64F     = 5,   /// complex pair of doubles
    CUDA_R_4I      = 16,
    CUDA_C_4I      = 17,
    CUDA_R_4U      = 18,
    CUDA_C_4U      = 19,
    CUDA_R_8I      = 3,
    CUDA_C_8I      = 7,
    CUDA_R_8U      = 8,
    CUDA_C_8U      = 9,
    CUDA_R_16I     = 20,
    CUDA_C_16I     = 21,
    CUDA_R_16U     = 22,
    CUDA_C_16U     = 23,
    CUDA_R_32I     = 10,
    CUDA_C_32I     = 11,
    CUDA_R_32U     = 12,
    CUDA_C_32U     = 13,
    CUDA_R_64I     = 24,
    CUDA_C_64I     = 25,
    CUDA_R_64U     = 26,
    CUDA_C_64U     = 27,
    CUDA_R_8F_E4M3 = 28,  /// real fp8 e4m3
    CUDA_R_8F_E5M2 = 29,  /// real fp8 e5m2
}

/// Retained for source compatibility with the C headers.
alias cublasDataType_t = cudaDataType;

/// Selects which version component `cublasGetProperty` reports.
enum libraryPropertyType {
    MAJOR_VERSION = 0,
    MINOR_VERSION = 1,
    PATCH_LEVEL   = 2,
}

/++
Returns a human-readable name for a `cublasStatus_t`.

Implemented in D rather than by binding cuBLAS's own `cublasGetStatusString`,
which only exists from CUDA 11.4 onwards; this works in every configuration,
including `static`/`staticBC` and `-betterC`, and before the library is loaded.
+/
string cublasStatusString(cublasStatus_t status) @safe @nogc nothrow pure {
    final switch(status) with(cublasStatus_t) {
        case CUBLAS_STATUS_SUCCESS:          return "CUBLAS_STATUS_SUCCESS";
        case CUBLAS_STATUS_NOT_INITIALIZED:  return "CUBLAS_STATUS_NOT_INITIALIZED";
        case CUBLAS_STATUS_ALLOC_FAILED:     return "CUBLAS_STATUS_ALLOC_FAILED";
        case CUBLAS_STATUS_INVALID_VALUE:    return "CUBLAS_STATUS_INVALID_VALUE";
        case CUBLAS_STATUS_ARCH_MISMATCH:    return "CUBLAS_STATUS_ARCH_MISMATCH";
        case CUBLAS_STATUS_MAPPING_ERROR:    return "CUBLAS_STATUS_MAPPING_ERROR";
        case CUBLAS_STATUS_EXECUTION_FAILED: return "CUBLAS_STATUS_EXECUTION_FAILED";
        case CUBLAS_STATUS_INTERNAL_ERROR:   return "CUBLAS_STATUS_INTERNAL_ERROR";
        case CUBLAS_STATUS_NOT_SUPPORTED:    return "CUBLAS_STATUS_NOT_SUPPORTED";
        case CUBLAS_STATUS_LICENSE_ERROR:    return "CUBLAS_STATUS_LICENSE_ERROR";
    }
}

static if(!staticBinding):

import bindbc.loader;

// Function pointer aliases — cuBLAS (v2 where applicable)

extern(C) @nogc nothrow {
    // Handle and library management
    alias pcublasCreate = cublasStatus_t function(cublasHandle_t* handle);
    alias pcublasDestroy = cublasStatus_t function(cublasHandle_t handle);
    alias pcublasGetVersion = cublasStatus_t function(cublasHandle_t handle, int* ver);
    alias pcublasGetProperty = cublasStatus_t function(libraryPropertyType type, int* value);

    // Stream association. cuBLAS declares these as taking the runtime API's
    // cudaStream_t, which is ABI-identical to the driver API's CUstream.
    alias pcublasSetStream = cublasStatus_t function(cublasHandle_t handle, CUstream streamId);
    alias pcublasGetStream = cublasStatus_t function(cublasHandle_t handle, CUstream* streamId);

    // Pointer mode (host vs device scalars)
    alias pcublasSetPointerMode = cublasStatus_t function(cublasHandle_t handle, cublasPointerMode_t mode);
    alias pcublasGetPointerMode = cublasStatus_t function(cublasHandle_t handle, cublasPointerMode_t* mode);

    // Math mode (tensor cores)
    alias pcublasSetMathMode = cublasStatus_t function(cublasHandle_t handle, cublasMath_t mode);
    alias pcublasGetMathMode = cublasStatus_t function(cublasHandle_t handle, cublasMath_t* mode);

    // Level 1 — vector operations
    alias pcublasSaxpy = cublasStatus_t function(cublasHandle_t handle, int n, const(float)* alpha, const(float)* x, int incx, float* y, int incy);
    alias pcublasDaxpy = cublasStatus_t function(cublasHandle_t handle, int n, const(double)* alpha, const(double)* x, int incx, double* y, int incy);
    alias pcublasSscal = cublasStatus_t function(cublasHandle_t handle, int n, const(float)* alpha, float* x, int incx);
    alias pcublasDscal = cublasStatus_t function(cublasHandle_t handle, int n, const(double)* alpha, double* x, int incx);
    alias pcublasSdot = cublasStatus_t function(cublasHandle_t handle, int n, const(float)* x, int incx, const(float)* y, int incy, float* result);
    alias pcublasDdot = cublasStatus_t function(cublasHandle_t handle, int n, const(double)* x, int incx, const(double)* y, int incy, double* result);
    alias pcublasSnrm2 = cublasStatus_t function(cublasHandle_t handle, int n, const(float)* x, int incx, float* result);
    alias pcublasSasum = cublasStatus_t function(cublasHandle_t handle, int n, const(float)* x, int incx, float* result);
    alias pcublasIsamax = cublasStatus_t function(cublasHandle_t handle, int n, const(float)* x, int incx, int* result);

    // Level 2 — matrix-vector operations
    alias pcublasSgemv = cublasStatus_t function(
        cublasHandle_t handle, cublasOperation_t trans,
        int m, int n,
        const(float)* alpha, const(float)* A, int lda,
        const(float)* x, int incx,
        const(float)* beta, float* y, int incy
    );
    alias pcublasDgemv = cublasStatus_t function(
        cublasHandle_t handle, cublasOperation_t trans,
        int m, int n,
        const(double)* alpha, const(double)* A, int lda,
        const(double)* x, int incx,
        const(double)* beta, double* y, int incy
    );

    // Level 3 — matrix-matrix operations
    alias pcublasSgemm = cublasStatus_t function(
        cublasHandle_t handle, cublasOperation_t transa, cublasOperation_t transb,
        int m, int n, int k,
        const(float)* alpha, const(float)* A, int lda,
        const(float)* B, int ldb,
        const(float)* beta, float* C, int ldc
    );
    alias pcublasDgemm = cublasStatus_t function(
        cublasHandle_t handle, cublasOperation_t transa, cublasOperation_t transb,
        int m, int n, int k,
        const(double)* alpha, const(double)* A, int lda,
        const(double)* B, int ldb,
        const(double)* beta, double* C, int ldc
    );
    alias pcublasSgemmStridedBatched = cublasStatus_t function(
        cublasHandle_t handle, cublasOperation_t transa, cublasOperation_t transb,
        int m, int n, int k,
        const(float)* alpha, const(float)* A, int lda, long strideA,
        const(float)* B, int ldb, long strideB,
        const(float)* beta, float* C, int ldc, long strideC,
        int batchCount
    );
    alias pcublasDgemmStridedBatched = cublasStatus_t function(
        cublasHandle_t handle, cublasOperation_t transa, cublasOperation_t transb,
        int m, int n, int k,
        const(double)* alpha, const(double)* A, int lda, long strideA,
        const(double)* B, int ldb, long strideB,
        const(double)* beta, double* C, int ldc, long strideC,
        int batchCount
    );
    alias pcublasGemmEx = cublasStatus_t function(
        cublasHandle_t handle, cublasOperation_t transa, cublasOperation_t transb,
        int m, int n, int k,
        const(void)* alpha, const(void)* A, cudaDataType Atype, int lda,
        const(void)* B, cudaDataType Btype, int ldb,
        const(void)* beta, void* C, cudaDataType Ctype, int ldc,
        cublasComputeType_t computeType, cublasGemmAlgo_t algo
    );

    // Matrix addition / transposition: C = alpha*op(A) + beta*op(B)
    alias pcublasSgeam = cublasStatus_t function(
        cublasHandle_t handle, cublasOperation_t transa, cublasOperation_t transb,
        int m, int n,
        const(float)* alpha, const(float)* A, int lda,
        const(float)* beta, const(float)* B, int ldb,
        float* C, int ldc
    );
    alias pcublasDgeam = cublasStatus_t function(
        cublasHandle_t handle, cublasOperation_t transa, cublasOperation_t transb,
        int m, int n,
        const(double)* alpha, const(double)* A, int lda,
        const(double)* beta, const(double)* B, int ldb,
        double* C, int ldc
    );
}

// Global function-pointer variables

__gshared {
    pcublasCreate cublasCreate;
    pcublasDestroy cublasDestroy;
    pcublasGetVersion cublasGetVersion;
    pcublasGetProperty cublasGetProperty;

    pcublasSetStream cublasSetStream;
    pcublasGetStream cublasGetStream;

    pcublasSetPointerMode cublasSetPointerMode;
    pcublasGetPointerMode cublasGetPointerMode;

    pcublasSetMathMode cublasSetMathMode;
    pcublasGetMathMode cublasGetMathMode;

    pcublasSaxpy cublasSaxpy;
    pcublasDaxpy cublasDaxpy;
    pcublasSscal cublasSscal;
    pcublasDscal cublasDscal;
    pcublasSdot cublasSdot;
    pcublasDdot cublasDdot;
    pcublasSnrm2 cublasSnrm2;
    pcublasSasum cublasSasum;
    pcublasIsamax cublasIsamax;

    pcublasSgemv cublasSgemv;
    pcublasDgemv cublasDgemv;

    pcublasSgemm cublasSgemm;
    pcublasDgemm cublasDgemm;
    pcublasSgemmStridedBatched cublasSgemmStridedBatched;
    pcublasDgemmStridedBatched cublasDgemmStridedBatched;
    pcublasGemmEx cublasGemmEx;

    pcublasSgeam cublasSgeam;
    pcublasDgeam cublasDgeam;
}

// Loader bookkeeping

private {
    SharedLib cublasLib;
    CUDASupport loadedCUBLAS;
}

@nogc nothrow:

/// Returns `true` if the cuBLAS library has been successfully loaded.
bool isCUBLASLoaded() @safe {
    return cublasLib != invalidHandle;
}

/// Returns the `CUDASupport` version level that was successfully loaded.
CUDASupport loadedCUBLASVersion() @safe {
    return loadedCUBLAS;
}

/// Unloads the cuBLAS shared library from process memory.
void unloadCUBLAS() {
    if(cublasLib != invalidHandle) {
        cublasLib.unload();
    }
}

/**
This is exposed solely to support optional loader mixins for binding
additional cuBLAS symbols from downstream code.
*/
void bindCUBLASSymbol(void** ptr, const(char)* symbolName) {
    assert(cublasLib != invalidHandle,
        "cuBLAS must be loaded before attempting to bind optional functions.");
    cublasLib.bindSymbol(ptr, symbolName);
}

/**
Loads the cuBLAS library using platform-specific default names.

cuBLAS is a separate shared library from the CUDA Driver API; this call is
independent of `loadCUDA` and either may succeed without the other.

Returns:
    The `CUDASupport` level matching the loaded cuBLAS toolkit version, or
    `CUDASupport.noLibrary` / `CUDASupport.badLibrary` on failure.
*/
CUDASupport loadCUBLAS() {
    version(Windows) {
        const(char)[][3] libNames = [
            "cublas64_12.dll",
            "cublas64_11.dll",
            "cublas64_10.dll",
        ];
    } else version(OSX) {
        const(char)[][1] libNames = ["libcublas.dylib"];
    } else version(Posix) {
        const(char)[][4] libNames = [
            "libcublas.so.12",
            "libcublas.so.11",
            "libcublas.so.10",
            "libcublas.so",
        ];
    } else static assert(0, "bindbc-cuda is not yet supported on this platform.");

    CUDASupport ret;
    foreach(name; libNames) {
        ret = loadCUBLAS(name.ptr);
        if(ret != CUDASupport.noLibrary) break;
    }
    return ret;
}

/**
Loads the cuBLAS library from a caller-supplied path or name.

Params:
    libName = null-terminated path or library name to load.
*/
CUDASupport loadCUBLAS(const(char)* libName) {
    cublasLib = load(libName);
    if(cublasLib == invalidHandle) {
        return CUDASupport.noLibrary;
    }

    auto errCount = errorCount();
    loadedCUBLAS = CUDASupport.badLibrary;

    // Handle and library management (v2)
    cublasLib.bindSymbol(cast(void**)&cublasCreate, "cublasCreate_v2");
    cublasLib.bindSymbol(cast(void**)&cublasDestroy, "cublasDestroy_v2");
    cublasLib.bindSymbol(cast(void**)&cublasGetVersion, "cublasGetVersion_v2");
    cublasLib.bindSymbol(cast(void**)&cublasGetProperty, "cublasGetProperty");

    // Stream association (v2)
    cublasLib.bindSymbol(cast(void**)&cublasSetStream, "cublasSetStream_v2");
    cublasLib.bindSymbol(cast(void**)&cublasGetStream, "cublasGetStream_v2");

    // Pointer mode (v2)
    cublasLib.bindSymbol(cast(void**)&cublasSetPointerMode, "cublasSetPointerMode_v2");
    cublasLib.bindSymbol(cast(void**)&cublasGetPointerMode, "cublasGetPointerMode_v2");

    // Math mode — added in CUDA 9.0, no _v2 suffix
    cublasLib.bindSymbol(cast(void**)&cublasSetMathMode, "cublasSetMathMode");
    cublasLib.bindSymbol(cast(void**)&cublasGetMathMode, "cublasGetMathMode");

    // Level 1 (v2)
    cublasLib.bindSymbol(cast(void**)&cublasSaxpy, "cublasSaxpy_v2");
    cublasLib.bindSymbol(cast(void**)&cublasDaxpy, "cublasDaxpy_v2");
    cublasLib.bindSymbol(cast(void**)&cublasSscal, "cublasSscal_v2");
    cublasLib.bindSymbol(cast(void**)&cublasDscal, "cublasDscal_v2");
    cublasLib.bindSymbol(cast(void**)&cublasSdot, "cublasSdot_v2");
    cublasLib.bindSymbol(cast(void**)&cublasDdot, "cublasDdot_v2");
    cublasLib.bindSymbol(cast(void**)&cublasSnrm2, "cublasSnrm2_v2");
    cublasLib.bindSymbol(cast(void**)&cublasSasum, "cublasSasum_v2");
    cublasLib.bindSymbol(cast(void**)&cublasIsamax, "cublasIsamax_v2");

    // Level 2 (v2)
    cublasLib.bindSymbol(cast(void**)&cublasSgemv, "cublasSgemv_v2");
    cublasLib.bindSymbol(cast(void**)&cublasDgemv, "cublasDgemv_v2");

    // Level 3 — gemm is v2; the batched and Ex entry points post-date the v2
    // ABI break and have no _v2 suffix
    cublasLib.bindSymbol(cast(void**)&cublasSgemm, "cublasSgemm_v2");
    cublasLib.bindSymbol(cast(void**)&cublasDgemm, "cublasDgemm_v2");
    cublasLib.bindSymbol(cast(void**)&cublasSgemmStridedBatched, "cublasSgemmStridedBatched");
    cublasLib.bindSymbol(cast(void**)&cublasDgemmStridedBatched, "cublasDgemmStridedBatched");
    cublasLib.bindSymbol(cast(void**)&cublasGemmEx, "cublasGemmEx");

    cublasLib.bindSymbol(cast(void**)&cublasSgeam, "cublasSgeam");
    cublasLib.bindSymbol(cast(void**)&cublasDgeam, "cublasDgeam");

    if(errorCount() != errCount) return CUDASupport.badLibrary;

    // cublasGetProperty needs no handle, so the version is reportable before
    // any context exists. cuBLAS ships with the toolkit, so its major.minor is
    // the toolkit version and maps onto the same CUDASupport scale.
    int major = 0, minor = 0;
    if(cublasGetProperty(libraryPropertyType.MAJOR_VERSION, &major) == cublasStatus_t.CUBLAS_STATUS_SUCCESS
       && cublasGetProperty(libraryPropertyType.MINOR_VERSION, &minor) == cublasStatus_t.CUBLAS_STATUS_SUCCESS) {
        int mapped = major * 100 + minor * 10;
        loadedCUBLAS = (mapped >= cudaSupport) ? cudaSupport : cast(CUDASupport)mapped;
    } else {
        loadedCUBLAS = CUDASupport.cuda100;
    }

    return loadedCUBLAS;
}

// Tests, following the same inline-`unittest` convention as binddynamic.d.
// The end-to-end SGEMM validation lives in test.d (the `test` dub
// configuration), which has a CUDA context to run it in.
unittest {
    import core.stdc.stdio : printf;

    CUDASupport support = loadCUBLAS();
    if(support == CUDASupport.noLibrary){
        printf("SKIP: cuBLAS library not found; skipping cuBLAS load test.\n");
        return;
    }
    assert(support != CUDASupport.badLibrary,
           "cuBLAS library found, but required symbols failed to load");

    assert(cublasCreate !is null);
    assert(cublasDestroy !is null);
    assert(cublasGetVersion !is null);
    assert(cublasGetProperty !is null);
    assert(cublasSetStream !is null);
    assert(cublasGetStream !is null);
    assert(cublasSetPointerMode !is null);
    assert(cublasGetPointerMode !is null);
    assert(cublasSetMathMode !is null);
    assert(cublasGetMathMode !is null);
    assert(cublasSgemm !is null);
    assert(cublasDgemm !is null);
    assert(cublasSgemmStridedBatched !is null);
    assert(cublasDgemmStridedBatched !is null);
    assert(cublasGemmEx !is null);
    assert(cublasSaxpy !is null);
    assert(cublasSscal !is null);
    assert(cublasSdot !is null);
    assert(cublasSgeam !is null);
    assert(cublasSgemv !is null);
    assert(cublasSnrm2 !is null);
    assert(cublasIsamax !is null);

    assert(cublasStatusString(cublasStatus_t.CUBLAS_STATUS_SUCCESS) == "CUBLAS_STATUS_SUCCESS");
    assert(cublasStatusString(cublasStatus_t.CUBLAS_STATUS_ARCH_MISMATCH) == "CUBLAS_STATUS_ARCH_MISMATCH");

    printf("PASS: loadCUBLAS() and all cuBLAS symbols bound.\n");
}
