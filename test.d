import std.stdio;
import std.math : sin, cos, fabs;
import core.stdc.string : strlen;
import bindbc.cuda;

/// Safely convert a null-terminated C char buffer to a D string.
string fromCString(char[] buf) {
    auto len = strlen(buf.ptr);
    return buf[0 .. len].idup;
}

/++
Runs a single-precision GEMM on the GPU and validates it against a CPU
reference computed here in D.

All three host matrices are ROW-major: A is M x K, B is K x N, C is M x N.
cuBLAS is COLUMN-major, and this is where every fresh cuBLAS binding gets it
wrong, so the convention is spelled out:

A row-major m x n matrix is bit-identical in memory to a column-major n x m
matrix, i.e. the same bytes are the transpose. Rather than transposing the
data, use the identity C^T = B^T * A^T and hand cuBLAS the operands swapped,
with the m/n extents swapped and no transpose flags. cuBLAS then computes
column-major C^T (N x M), which in memory is exactly the row-major C (M x N)
we wanted. No extra copies, no cublasSgeam pass.

Requires an active CUDA context; the caller creates one.
+/
bool runSgemm(int M, int N, int K, cublasHandle_t handle) {
    // Row-major host data. Deliberately asymmetric and non-integral: a
    // symmetric or integer fill can mask a transposed result.
    auto hA = new float[M * K];
    auto hB = new float[K * N];
    auto hC = new float[M * N];

    foreach (i; 0 .. M)
        foreach (j; 0 .. K)
            hA[i * K + j] = cast(float)sin(i * 0.7 + j * 0.31);

    foreach (i; 0 .. K)
        foreach (j; 0 .. N)
            hB[i * N + j] = cast(float)cos(i * 0.23 - j * 0.11);

    // CPU reference: plain row-major triple loop, accumulated in double.
    auto ref_ = new float[M * N];
    foreach (i; 0 .. M) {
        foreach (j; 0 .. N) {
            double acc = 0.0;
            foreach (p; 0 .. K)
                acc += cast(double)hA[i * K + p] * cast(double)hB[p * N + j];
            ref_[i * N + j] = cast(float)acc;
        }
    }

    CUdeviceptr dA, dB, dC;
    if (cuMemAlloc(&dA, hA.length * float.sizeof) != CUresult.CUDA_SUCCESS) return false;
    scope(exit) cuMemFree(dA);
    if (cuMemAlloc(&dB, hB.length * float.sizeof) != CUresult.CUDA_SUCCESS) return false;
    scope(exit) cuMemFree(dB);
    if (cuMemAlloc(&dC, hC.length * float.sizeof) != CUresult.CUDA_SUCCESS) return false;
    scope(exit) cuMemFree(dC);

    if (cuMemcpyHtoD(dA, hA.ptr, hA.length * float.sizeof) != CUresult.CUDA_SUCCESS) return false;
    if (cuMemcpyHtoD(dB, hB.ptr, hB.length * float.sizeof) != CUresult.CUDA_SUCCESS) return false;

    // alpha/beta are host scalars (the default CUBLAS_POINTER_MODE_HOST).
    immutable float alpha = 1.0f;
    immutable float beta  = 0.0f;

    // C = A * B for row-major operands. Note: N and M swapped, B before A.
    auto st = cublasSgemm(handle,
        cublasOperation_t.CUBLAS_OP_N,
        cublasOperation_t.CUBLAS_OP_N,
        N, M, K,
        &alpha,
        cast(const(float)*)dB, N,
        cast(const(float)*)dA, K,
        &beta,
        cast(float*)dC, N);

    if (st != cublasStatus_t.CUBLAS_STATUS_SUCCESS) {
        writefln("    FAIL: cublasSgemm returned %s", cublasStatusString(st));
        return false;
    }

    if (cuCtxSynchronize() != CUresult.CUDA_SUCCESS) return false;
    if (cuMemcpyDtoH(hC.ptr, dC, hC.length * float.sizeof) != CUresult.CUDA_SUCCESS) return false;

    // Mixed absolute/relative tolerance scaled by the magnitude of the result.
    // A pure per-element relative check is wrong for a GEMM: elements whose
    // reference value happens to land near zero are the difference of large
    // partial sums, so their relative error is unbounded even when the result
    // is perfect. The scale that matters is the largest entry of C.
    double maxAbsErr = 0.0, refMaxAbs = 0.0;
    int worst = 0;
    foreach (idx; 0 .. M * N) {
        immutable double d = fabs(cast(double)hC[idx] - cast(double)ref_[idx]);
        if (d > maxAbsErr) { maxAbsErr = d; worst = idx; }
        immutable double a = fabs(cast(double)ref_[idx]);
        if (a > refMaxAbs) refMaxAbs = a;
    }
    // fp32 accumulation over K terms; generous, but a transposed or
    // wrong-dimension result is off by O(refMaxAbs), which is ~1e4x larger.
    immutable double tol = 1e-4 * (1.0 + refMaxAbs);

    writefln("    C[0][0]      gpu=% .6f  cpu=% .6f", hC[0], ref_[0]);
    writefln("    C[%d][%d]    gpu=% .6f  cpu=% .6f",
             M - 1, N - 1, hC[M * N - 1], ref_[M * N - 1]);
    writefln("    worst elem C[%d][%d]  gpu=% .6f  cpu=% .6f",
             worst / N, worst % N, hC[worst], ref_[worst]);
    writefln("    max|C| %.6f   max abs err %.3e   tol %.3e", refMaxAbs, maxAbsErr, tol);

    immutable bool ok = maxAbsErr <= tol;
    writefln("    %d x %d x %d SGEMM vs CPU reference: %s", M, N, K, ok ? "PASS" : "FAIL");
    return ok;
}

void main() { 
    writeln("  BindBC-CUDA Integration Test"); 

    // 1. Load the CUDA Driver API shared library dynamically
    writeln("\nLibrary Loading");
    CUDASupport support = loadCUDA();

    if (support == CUDASupport.noLibrary) {
        writeln("FAIL: CUDA library was not found on your system.");
        writeln("Ensure the NVIDIA driver is installed.");
        return;
    } else if (support == CUDASupport.badLibrary) {
        writeln("FAIL: CUDA library found, but required symbols failed to load.");
        return;
    }

    writefln("Compiled against: %s", cudaSupport);
    writefln("Loaded level:     %s", support);

    // 2. Initialize and query the runtime driver version
    CUresult res = cuInit(0);
    if (res != CUresult.CUDA_SUCCESS) {
        writefln("FAIL: cuInit returned %s", res);
        return;
    }

    int driverVersion = 0;
    res = cuDriverGetVersion(&driverVersion);
    if (res == CUresult.CUDA_SUCCESS) {
        int driverMajor = driverVersion / 1000;
        int driverMinor = (driverVersion % 1000) / 10;
        writefln("  Runtime driver:   CUDA %d.%d  (raw: %d)", driverMajor, driverMinor, driverVersion);
    }

    // 3. Enumerate devices
    writeln("\nDevice Info");
    int deviceCount = 0;
    res = cuDeviceGetCount(&deviceCount);
    if (res != CUresult.CUDA_SUCCESS) {
        writefln("FAIL: cuDeviceGetCount returned %s", res);
        return;
    }
    writefln("  Device count: %d", deviceCount);

    if (deviceCount == 0) {
        writeln("  No CUDA devices available. Exiting.");
        return;
    }

    CUdevice dev;
    res = cuDeviceGet(&dev, 0);
    if (res != CUresult.CUDA_SUCCESS) {
        writefln("FAIL: cuDeviceGet returned %s", res);
        return;
    }

    char[256] nameBuf = '\0';
    res = cuDeviceGetName(nameBuf.ptr, cast(int)nameBuf.length, dev);
    string devName = (res == CUresult.CUDA_SUCCESS) ? fromCString(nameBuf) : "Unknown";
    writefln("Name:             %s", devName);

    int major = 0, minor = 0;
    cuDeviceGetAttribute(&major, CUdevice_attribute.CU_DEVICE_ATTRIBUTE_COMPUTE_CAPABILITY_MAJOR, dev);
    cuDeviceGetAttribute(&minor, CUdevice_attribute.CU_DEVICE_ATTRIBUTE_COMPUTE_CAPABILITY_MINOR, dev);
    writefln("Compute:          %d.%d", major, minor);

    size_t totalMem = 0;
    res = cuDeviceTotalMem(&totalMem, dev);
    if (res == CUresult.CUDA_SUCCESS) {
        writefln("  Memory:           %.2f GB", cast(double)totalMem / (1024.0 * 1024.0 * 1024.0));
    }

    int maxThreads = 0;
    cuDeviceGetAttribute(&maxThreads, CUdevice_attribute.CU_DEVICE_ATTRIBUTE_MAX_THREADS_PER_BLOCK, dev);
    writefln("  Max threads/blk:  %d", maxThreads);

    int smCount = 0;
    cuDeviceGetAttribute(&smCount, CUdevice_attribute.CU_DEVICE_ATTRIBUTE_MULTIPROCESSOR_COUNT, dev);
    writefln("  SM count:         %d", smCount);

    // 4. Context
    writeln("\nContext Test");
    CUcontext context;
    res = cuCtxCreate(&context, 0, dev);
    if (res != CUresult.CUDA_SUCCESS) {
        writefln("FAIL: cuCtxCreate returned %s", res);
        return;
    }
    writeln("  Context created.");
    scope(exit) {
        cuCtxDestroy(context);
        writeln("Context destroyed.");
    }

    // 5. Memory round-trip: Host -> Device -> Host
    writeln("\nMemory Transfer Test");
    enum N = 1024;
    enum byteSize = N * int.sizeof;

    int[N] src;
    foreach (i; 0 .. N) src[i] = cast(int)i;

    CUdeviceptr devPtr;
    res = cuMemAlloc(&devPtr, byteSize);
    if (res != CUresult.CUDA_SUCCESS) {
        writefln("FAIL: cuMemAlloc returned %s", res);
        return;
    }
    scope(exit) {
        cuMemFree(devPtr);
    }
    writefln("Allocated %d bytes on device (0x%X)", byteSize, devPtr);

    res = cuMemcpyHtoD(devPtr, src.ptr, byteSize);
    if (res != CUresult.CUDA_SUCCESS) {
        writefln("FAIL: cuMemcpyHtoD returned %s", res);
        return;
    }

    int[N] dst = 0;
    res = cuMemcpyDtoH(dst.ptr, devPtr, byteSize);
    if (res != CUresult.CUDA_SUCCESS) {
        writefln("FAIL: cuMemcpyDtoH returned %s", res);
        return;
    }

    bool ok = true;
    foreach (i; 0 .. N) {
        if (src[i] != dst[i]) { ok = false; break; }
    }
    writefln("H->D->H round-trip (%d ints): %s", N, ok ? "PASS" : "FAIL");

    // 6. Event timing test
    writeln("\nEvent Timing Test");
    CUevent evStart, evEnd;
    res = cuEventCreate(&evStart, 0);
    if (res != CUresult.CUDA_SUCCESS) {
        writefln("SKIP: cuEventCreate returned %s", res);
    } else {
        res = cuEventCreate(&evEnd, 0);
        if (res == CUresult.CUDA_SUCCESS) {
            cuEventRecord(evStart, CUstream.init);

            // Do another memcpy as a timed workload
            cuMemcpyHtoD(devPtr, src.ptr, byteSize);

            cuEventRecord(evEnd, CUstream.init);
            cuEventSynchronize(evEnd);

            float ms = 0.0f;
            res = cuEventElapsedTime(&ms, evStart, evEnd);
            if (res == CUresult.CUDA_SUCCESS) {
                writefln("  Memcpy %d bytes took %.3f ms", byteSize, ms);
            }

            cuEventDestroy(evEnd);
        }
        cuEventDestroy(evStart);
    }

    // 7. cuBLAS: load, create a handle, run SGEMM on the GPU, validate on CPU
    writeln("\ncuBLAS Test");
    CUDASupport cublasSupport = loadCUBLAS();
    if (cublasSupport == CUDASupport.noLibrary) {
        writeln("  SKIP: cuBLAS library not found (libcublas.so.12).");
    } else if (cublasSupport == CUDASupport.badLibrary) {
        writeln("  FAIL: cuBLAS found, but required symbols failed to load.");
    } else {
        writefln("  Loaded level:     %s", cublasSupport);

        cublasHandle_t handle;
        auto st = cublasCreate(&handle);
        if (st != cublasStatus_t.CUBLAS_STATUS_SUCCESS) {
            writefln("  FAIL: cublasCreate returned %s", cublasStatusString(st));
        } else {
            scope(exit) {
                auto d = cublasDestroy(handle);
                writefln("  Handle destroyed: %s", cublasStatusString(d));
            }

            int cublasVer = 0;
            if (cublasGetVersion(handle, &cublasVer) == cublasStatus_t.CUBLAS_STATUS_SUCCESS)
                writefln("  cuBLAS version:   %d", cublasVer);

            cublasPointerMode_t pm;
            if (cublasGetPointerMode(handle, &pm) == cublasStatus_t.CUBLAS_STATUS_SUCCESS)
                writefln("  Pointer mode:     %s", pm);

            cublasMath_t mm;
            if (cublasGetMathMode(handle, &mm) == cublasStatus_t.CUBLAS_STATUS_SUCCESS)
                writefln("  Math mode:        %s", mm);

            // Square case (the classic smoke size), then a non-square case:
            // a square GEMM cannot catch a swapped m/n, a non-square one can.
            writeln("  Square 64x64x64 (row-major operands, column-major cuBLAS):");
            bool ok1 = runSgemm(64, 64, 64, handle);
            writeln("  Non-square 64x48x32:");
            bool ok2 = runSgemm(64, 48, 32, handle);
            writefln("  cuBLAS SGEMM overall: %s", (ok1 && ok2) ? "PASS" : "FAIL");
        }
    }

    writeln("\nAll tests completed.");
}
