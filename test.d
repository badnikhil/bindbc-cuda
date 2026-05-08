import std.stdio;
import core.stdc.string : strlen;
import bindbc.cuda;

/// Safely convert a null-terminated C char buffer to a D string.
string fromCString(char[] buf) {
    auto len = strlen(buf.ptr);
    return buf[0 .. len].idup;
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

    writeln("\nAll tests completed.");
}
