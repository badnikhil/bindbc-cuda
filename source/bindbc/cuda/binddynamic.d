/+
+          Copyright 2026 Nikhil
+ Distributed under the Boost Software License, Version 1.0.
+     (See accompanying file LICENSE_1_0.txt or copy at
+           http://www.boost.org/LICENSE_1_0.txt)
+/
/// Dynamic loading of the CUDA Driver API shared library at runtime.
module bindbc.cuda.binddynamic;

import bindbc.cuda.config;
import bindbc.cuda.types;

static if(!staticBinding):

import bindbc.loader;

// Function pointer aliases — CUDA Driver API (v2 where applicable)

extern(C) @nogc nothrow {
    // Initialization
    alias pcuInit = CUresult function(uint flags);
    alias pcuDriverGetVersion = CUresult function(int* driverVersion);

    // Device management
    alias pcuDeviceGet = CUresult function(CUdevice* device, int ordinal);
    alias pcuDeviceGetCount = CUresult function(int* count);
    alias pcuDeviceGetName = CUresult function(char* name, int len, CUdevice dev);
    alias pcuDeviceTotalMem = CUresult function(size_t* bytes, CUdevice dev);
    alias pcuDeviceGetAttribute = CUresult function(int* pi, CUdevice_attribute attrib, CUdevice dev);

    // Context management (v2 API)
    alias pcuCtxCreate = CUresult function(CUcontext* pctx, uint flags, CUdevice dev);
    alias pcuCtxDestroy = CUresult function(CUcontext ctx);
    alias pcuCtxSetCurrent = CUresult function(CUcontext ctx);
    alias pcuCtxGetCurrent = CUresult function(CUcontext* pctx);
    alias pcuCtxSynchronize = CUresult function();
    alias pcuCtxPushCurrent = CUresult function(CUcontext ctx);
    alias pcuCtxPopCurrent = CUresult function(CUcontext* pctx);
    alias pcuCtxDetach = CUresult function(CUcontext ctx);
    alias pcuCtxSetLimit = CUresult function(int limit, size_t value);
    alias pcuCtxGetLimit = CUresult function(size_t* pvalue, int limit);
    alias pcuCtxSetSharedMemConfig = CUresult function(int config);
    alias pcuCtxGetSharedMemConfig = CUresult function(int* pConfig);
    alias pcuCtxGetApiVersion = CUresult function(CUcontext ctx, uint* ver);
    alias pcuCtxGetStreamPriorityRange = CUresult function(int* leastPriority, int* greatestPriority);

    // Module management
    alias pcuModuleLoad = CUresult function(CUmodule* mod, const(char)* fname);
    alias pcuModuleLoadData = CUresult function(CUmodule* mod, const(void)* image);
    alias pcuModuleUnload = CUresult function(CUmodule hmod);
    alias pcuModuleGetFunction = CUresult function(CUfunction* hfunc, CUmodule hmod, const(char)* name);

    // Memory management (v2 API)
    alias pcuMemAlloc = CUresult function(CUdeviceptr* dptr, size_t bytesize);
    alias pcuMemAllocPitch = CUresult function(CUdeviceptr* dptr, size_t* pPitch, size_t WidthInBytes, size_t Height, uint ElementSizeBytes);
    alias pcuMemFree = CUresult function(CUdeviceptr dptr);
    alias pcuMemcpyHtoD = CUresult function(CUdeviceptr dstDevice, const(void)* srcHost, size_t byteCount);
    alias pcuMemcpyDtoH = CUresult function(void* dstHost, CUdeviceptr srcDevice, size_t byteCount);
    alias pcuMemcpyDtoD = CUresult function(CUdeviceptr dstDevice, CUdeviceptr srcDevice, size_t byteCount);
    alias pcuMemcpy2D = CUresult function(const(CUDA_MEMCPY2D)* pCopy);
    alias pcuMemcpy3D = CUresult function(const(CUDA_MEMCPY3D)* pCopy);
    alias pcuMemsetD8 = CUresult function(CUdeviceptr dstDevice, ubyte uc, size_t n);
    alias pcuMemsetD16 = CUresult function(CUdeviceptr dstDevice, ushort us, size_t n);
    alias pcuMemsetD32 = CUresult function(CUdeviceptr dstDevice, uint ui, size_t n);
    alias pcuMemsetD2D8 = CUresult function(CUdeviceptr dstDevice, size_t dstPitch, ubyte uc, size_t Width, size_t Height);
    alias pcuMemsetD2D16 = CUresult function(CUdeviceptr dstDevice, size_t dstPitch, ushort us, size_t Width, size_t Height);
    alias pcuMemsetD2D32 = CUresult function(CUdeviceptr dstDevice, size_t dstPitch, uint ui, size_t Width, size_t Height);
    alias pcuMemGetAddressRange = CUresult function(CUdeviceptr* pbase, size_t* psize, CUdeviceptr dptr);
    alias pcuMemGetInfo = CUresult function(size_t* free, size_t* total);
    alias pcuMemAllocManaged = CUresult function(CUdeviceptr* dptr, size_t bytesize, uint flags);
    alias pcuMemPrefetchAsync = CUresult function(CUdeviceptr devPtr, size_t count, CUdevice dstDevice, CUstream hStream);

    // Memory management — async (stream-ordered) variants
    alias pcuMemcpyHtoDAsync = CUresult function(CUdeviceptr dstDevice, const(void)* srcHost, size_t byteCount, CUstream hStream);
    alias pcuMemcpyDtoHAsync = CUresult function(void* dstHost, CUdeviceptr srcDevice, size_t byteCount, CUstream hStream);
    alias pcuMemcpyDtoDAsync = CUresult function(CUdeviceptr dstDevice, CUdeviceptr srcDevice, size_t byteCount, CUstream hStream);
    alias pcuMemcpy2DAsync = CUresult function(const(CUDA_MEMCPY2D)* pCopy, CUstream hStream);
    alias pcuMemcpy3DAsync = CUresult function(const(CUDA_MEMCPY3D)* pCopy, CUstream hStream);
    alias pcuMemsetD8Async = CUresult function(CUdeviceptr dstDevice, ubyte uc, size_t n, CUstream hStream);
    alias pcuMemsetD16Async = CUresult function(CUdeviceptr dstDevice, ushort us, size_t n, CUstream hStream);
    alias pcuMemsetD32Async = CUresult function(CUdeviceptr dstDevice, uint ui, size_t n, CUstream hStream);
    alias pcuMemsetD2D8Async = CUresult function(CUdeviceptr dstDevice, size_t dstPitch, ubyte uc, size_t Width, size_t Height, CUstream hStream);
    alias pcuMemsetD2D16Async = CUresult function(CUdeviceptr dstDevice, size_t dstPitch, ushort us, size_t Width, size_t Height, CUstream hStream);
    alias pcuMemsetD2D32Async = CUresult function(CUdeviceptr dstDevice, size_t dstPitch, uint ui, size_t Width, size_t Height, CUstream hStream);

    // Stream management
    alias pcuStreamCreate = CUresult function(CUstream* phStream, uint flags);
    alias pcuStreamDestroy = CUresult function(CUstream hStream);
    alias pcuStreamSynchronize = CUresult function(CUstream hStream);
    alias pcuStreamCreateWithPriority = CUresult function(CUstream* phStream, uint flags, int priority);
    alias pcuStreamGetFlags = CUresult function(CUstream hStream, uint* flags);
    alias pcuStreamGetPriority = CUresult function(CUstream hStream, int* priority);
    alias pcuStreamWaitEvent = CUresult function(CUstream hStream, CUevent hEvent, uint flags);

    // Event management
    alias pcuEventCreate = CUresult function(CUevent* phEvent, uint flags);
    alias pcuEventDestroy = CUresult function(CUevent hEvent);
    alias pcuEventRecord = CUresult function(CUevent hEvent, CUstream hStream);
    alias pcuEventSynchronize = CUresult function(CUevent hEvent);
    alias pcuEventElapsedTime = CUresult function(float* pMilliseconds, CUevent hStart, CUevent hEnd);

    // Execution control
    alias pcuLaunchKernel = CUresult function(
        CUfunction f,
        uint gridDimX, uint gridDimY, uint gridDimZ,
        uint blockDimX, uint blockDimY, uint blockDimZ,
        uint sharedMemBytes, CUstream hStream,
        void** kernelParams, void** extra
    );
}
 
// Global function-pointer variables 

__gshared {
    pcuInit cuInit;
    pcuDriverGetVersion cuDriverGetVersion;

    pcuDeviceGet cuDeviceGet;
    pcuDeviceGetCount cuDeviceGetCount;
    pcuDeviceGetName cuDeviceGetName;
    pcuDeviceTotalMem cuDeviceTotalMem;
    pcuDeviceGetAttribute cuDeviceGetAttribute;

    pcuCtxCreate cuCtxCreate;
    pcuCtxDestroy cuCtxDestroy;
    pcuCtxSetCurrent cuCtxSetCurrent;
    pcuCtxGetCurrent cuCtxGetCurrent;
    pcuCtxSynchronize cuCtxSynchronize;
    pcuCtxPushCurrent cuCtxPushCurrent;
    pcuCtxPopCurrent cuCtxPopCurrent;
    pcuCtxDetach cuCtxDetach;
    pcuCtxSetLimit cuCtxSetLimit;
    pcuCtxGetLimit cuCtxGetLimit;
    pcuCtxSetSharedMemConfig cuCtxSetSharedMemConfig;
    pcuCtxGetSharedMemConfig cuCtxGetSharedMemConfig;
    pcuCtxGetApiVersion cuCtxGetApiVersion;
    pcuCtxGetStreamPriorityRange cuCtxGetStreamPriorityRange;

    pcuModuleLoad cuModuleLoad;
    pcuModuleLoadData cuModuleLoadData;
    pcuModuleUnload cuModuleUnload;
    pcuModuleGetFunction cuModuleGetFunction;

    pcuMemAlloc cuMemAlloc;
    pcuMemAllocPitch cuMemAllocPitch;
    pcuMemFree cuMemFree;
    pcuMemcpyHtoD cuMemcpyHtoD;
    pcuMemcpyDtoH cuMemcpyDtoH;
    pcuMemcpyDtoD cuMemcpyDtoD;
    pcuMemcpy2D cuMemcpy2D;
    pcuMemcpy3D cuMemcpy3D;
    pcuMemsetD8 cuMemsetD8;
    pcuMemsetD16 cuMemsetD16;
    pcuMemsetD32 cuMemsetD32;
    pcuMemsetD2D8 cuMemsetD2D8;
    pcuMemsetD2D16 cuMemsetD2D16;
    pcuMemsetD2D32 cuMemsetD2D32;
    pcuMemGetAddressRange cuMemGetAddressRange;
    pcuMemGetInfo cuMemGetInfo;
    pcuMemAllocManaged cuMemAllocManaged;
    pcuMemPrefetchAsync cuMemPrefetchAsync;

    pcuMemcpyHtoDAsync cuMemcpyHtoDAsync;
    pcuMemcpyDtoHAsync cuMemcpyDtoHAsync;
    pcuMemcpyDtoDAsync cuMemcpyDtoDAsync;
    pcuMemcpy2DAsync cuMemcpy2DAsync;
    pcuMemcpy3DAsync cuMemcpy3DAsync;
    pcuMemsetD8Async cuMemsetD8Async;
    pcuMemsetD16Async cuMemsetD16Async;
    pcuMemsetD32Async cuMemsetD32Async;
    pcuMemsetD2D8Async cuMemsetD2D8Async;
    pcuMemsetD2D16Async cuMemsetD2D16Async;
    pcuMemsetD2D32Async cuMemsetD2D32Async;

    pcuStreamCreate cuStreamCreate;
    pcuStreamDestroy cuStreamDestroy;
    pcuStreamSynchronize cuStreamSynchronize;
    pcuStreamCreateWithPriority cuStreamCreateWithPriority;
    pcuStreamGetFlags cuStreamGetFlags;
    pcuStreamGetPriority cuStreamGetPriority;
    pcuStreamWaitEvent cuStreamWaitEvent;

    pcuEventCreate cuEventCreate;
    pcuEventDestroy cuEventDestroy;
    pcuEventRecord cuEventRecord;
    pcuEventSynchronize cuEventSynchronize;
    pcuEventElapsedTime cuEventElapsedTime;

    pcuLaunchKernel cuLaunchKernel;
}
 
// Loader bookkeeping 

private {
    SharedLib lib;
    CUDASupport loadedVersion;
}

@nogc nothrow:

/// Returns `true` if the CUDA Driver library has been successfully loaded.
bool isCUDALoaded() @safe {
    return lib != invalidHandle;
}

/// Returns the `CUDASupport` version level that was successfully loaded.
CUDASupport loadedCUDAVersion() @safe {
    return loadedVersion;
}

/// Unloads the CUDA Driver shared library from process memory.
void unloadCUDA() {
    if(lib != invalidHandle) {
        lib.unload();
    }
}

/**
This is exposed solely to support optional loader mixins for binding
additional CUDA symbols from downstream code.
*/
void bindCUDASymbol(void** ptr, const(char)* symbolName) {
    assert(lib != invalidHandle,
        "CUDA must be loaded before attempting to bind optional functions.");
    lib.bindSymbol(ptr, symbolName);
}

/**
Loads the CUDA Driver library using platform-specific default names.

Returns:
    The highest `CUDASupport` level whose symbols were all bound, or
    `CUDASupport.noLibrary` / `CUDASupport.badLibrary` on failure.
*/
CUDASupport loadCUDA() {
    version(Windows) {
        const(char)[][1] libNames = ["nvcuda.dll"];
    } else version(OSX) {
        const(char)[][1] libNames = ["libcuda.dylib"];
    } else version(Posix) {
        const(char)[][2] libNames = [
            "libcuda.so.1",
            "libcuda.so",
        ];
    } else static assert(0, "bindbc-cuda is not yet supported on this platform.");

    CUDASupport ret;
    foreach(name; libNames) {
        ret = loadCUDA(name.ptr);
        if(ret != CUDASupport.noLibrary) break;
    }
    return ret;
}

/**
Loads the CUDA Driver library from a caller-supplied path or name.

Params:
    libName = null-terminated path or library name to load.
*/
CUDASupport loadCUDA(const(char)* libName) {
    lib = load(libName);
    if(lib == invalidHandle) {
        return CUDASupport.noLibrary;
    }

    auto errCount = errorCount();
    loadedVersion = CUDASupport.badLibrary;

    // Initialization (no versioned suffix)
    lib.bindSymbol(cast(void**)&cuInit, "cuInit");
    lib.bindSymbol(cast(void**)&cuDriverGetVersion, "cuDriverGetVersion");

    // Device management (no versioned suffix)
    lib.bindSymbol(cast(void**)&cuDeviceGet, "cuDeviceGet");
    lib.bindSymbol(cast(void**)&cuDeviceGetCount, "cuDeviceGetCount");
    lib.bindSymbol(cast(void**)&cuDeviceGetName, "cuDeviceGetName");
    lib.bindSymbol(cast(void**)&cuDeviceTotalMem, "cuDeviceTotalMem_v2");
    lib.bindSymbol(cast(void**)&cuDeviceGetAttribute, "cuDeviceGetAttribute");

    // Context management (v2) 
    lib.bindSymbol(cast(void**)&cuCtxCreate, "cuCtxCreate_v2");
    lib.bindSymbol(cast(void**)&cuCtxDestroy, "cuCtxDestroy_v2");
    lib.bindSymbol(cast(void**)&cuCtxSetCurrent, "cuCtxSetCurrent");
    lib.bindSymbol(cast(void**)&cuCtxGetCurrent, "cuCtxGetCurrent");
    lib.bindSymbol(cast(void**)&cuCtxSynchronize, "cuCtxSynchronize");
    lib.bindSymbol(cast(void**)&cuCtxPushCurrent, "cuCtxPushCurrent_v2");
    lib.bindSymbol(cast(void**)&cuCtxPopCurrent, "cuCtxPopCurrent_v2");
    lib.bindSymbol(cast(void**)&cuCtxDetach, "cuCtxDetach");
    lib.bindSymbol(cast(void**)&cuCtxSetLimit, "cuCtxSetLimit");
    lib.bindSymbol(cast(void**)&cuCtxGetLimit, "cuCtxGetLimit");
    lib.bindSymbol(cast(void**)&cuCtxSetSharedMemConfig, "cuCtxSetSharedMemConfig");
    lib.bindSymbol(cast(void**)&cuCtxGetSharedMemConfig, "cuCtxGetSharedMemConfig");
    lib.bindSymbol(cast(void**)&cuCtxGetApiVersion, "cuCtxGetApiVersion");
    lib.bindSymbol(cast(void**)&cuCtxGetStreamPriorityRange, "cuCtxGetStreamPriorityRange");

    // Module management 
    lib.bindSymbol(cast(void**)&cuModuleLoad, "cuModuleLoad");
    lib.bindSymbol(cast(void**)&cuModuleLoadData, "cuModuleLoadData");
    lib.bindSymbol(cast(void**)&cuModuleUnload, "cuModuleUnload");
    lib.bindSymbol(cast(void**)&cuModuleGetFunction, "cuModuleGetFunction");

    //  Memory management (v2)
    lib.bindSymbol(cast(void**)&cuMemAlloc, "cuMemAlloc_v2");
    lib.bindSymbol(cast(void**)&cuMemAllocPitch, "cuMemAllocPitch_v2");
    lib.bindSymbol(cast(void**)&cuMemFree, "cuMemFree_v2");
    lib.bindSymbol(cast(void**)&cuMemcpyHtoD, "cuMemcpyHtoD_v2");
    lib.bindSymbol(cast(void**)&cuMemcpyDtoH, "cuMemcpyDtoH_v2");
    lib.bindSymbol(cast(void**)&cuMemcpyDtoD, "cuMemcpyDtoD_v2");
    lib.bindSymbol(cast(void**)&cuMemcpy2D, "cuMemcpy2D_v2");
    lib.bindSymbol(cast(void**)&cuMemcpy3D, "cuMemcpy3D_v2");
    lib.bindSymbol(cast(void**)&cuMemsetD8, "cuMemsetD8_v2");
    lib.bindSymbol(cast(void**)&cuMemsetD16, "cuMemsetD16_v2");
    lib.bindSymbol(cast(void**)&cuMemsetD32, "cuMemsetD32_v2");
    lib.bindSymbol(cast(void**)&cuMemsetD2D8, "cuMemsetD2D8_v2");
    lib.bindSymbol(cast(void**)&cuMemsetD2D16, "cuMemsetD2D16_v2");
    lib.bindSymbol(cast(void**)&cuMemsetD2D32, "cuMemsetD2D32_v2");
    lib.bindSymbol(cast(void**)&cuMemGetAddressRange, "cuMemGetAddressRange_v2");
    lib.bindSymbol(cast(void**)&cuMemGetInfo, "cuMemGetInfo_v2");
    lib.bindSymbol(cast(void**)&cuMemAllocManaged, "cuMemAllocManaged");
    lib.bindSymbol(cast(void**)&cuMemPrefetchAsync, "cuMemPrefetchAsync");

    // Memory management — async variants (memcpy async are v2; the memset
    // async entry points post-date the v2 ABI break and have no _v2 suffix)
    lib.bindSymbol(cast(void**)&cuMemcpyHtoDAsync, "cuMemcpyHtoDAsync_v2");
    lib.bindSymbol(cast(void**)&cuMemcpyDtoHAsync, "cuMemcpyDtoHAsync_v2");
    lib.bindSymbol(cast(void**)&cuMemcpyDtoDAsync, "cuMemcpyDtoDAsync_v2");
    lib.bindSymbol(cast(void**)&cuMemcpy2DAsync, "cuMemcpy2DAsync_v2");
    lib.bindSymbol(cast(void**)&cuMemcpy3DAsync, "cuMemcpy3DAsync_v2");
    lib.bindSymbol(cast(void**)&cuMemsetD8Async, "cuMemsetD8Async");
    lib.bindSymbol(cast(void**)&cuMemsetD16Async, "cuMemsetD16Async");
    lib.bindSymbol(cast(void**)&cuMemsetD32Async, "cuMemsetD32Async");
    lib.bindSymbol(cast(void**)&cuMemsetD2D8Async, "cuMemsetD2D8Async");
    lib.bindSymbol(cast(void**)&cuMemsetD2D16Async, "cuMemsetD2D16Async");
    lib.bindSymbol(cast(void**)&cuMemsetD2D32Async, "cuMemsetD2D32Async");

    // Stream management 
    lib.bindSymbol(cast(void**)&cuStreamCreate, "cuStreamCreate");
    lib.bindSymbol(cast(void**)&cuStreamDestroy, "cuStreamDestroy_v2");
    lib.bindSymbol(cast(void**)&cuStreamSynchronize, "cuStreamSynchronize");
    lib.bindSymbol(cast(void**)&cuStreamCreateWithPriority, "cuStreamCreateWithPriority");
    lib.bindSymbol(cast(void**)&cuStreamGetFlags, "cuStreamGetFlags");
    lib.bindSymbol(cast(void**)&cuStreamGetPriority, "cuStreamGetPriority");
    lib.bindSymbol(cast(void**)&cuStreamWaitEvent, "cuStreamWaitEvent");

    // Event management
    lib.bindSymbol(cast(void**)&cuEventCreate, "cuEventCreate");
    lib.bindSymbol(cast(void**)&cuEventDestroy, "cuEventDestroy_v2");
    lib.bindSymbol(cast(void**)&cuEventRecord, "cuEventRecord");
    lib.bindSymbol(cast(void**)&cuEventSynchronize, "cuEventSynchronize");
    lib.bindSymbol(cast(void**)&cuEventElapsedTime, "cuEventElapsedTime");

    // Execution contro 
    lib.bindSymbol(cast(void**)&cuLaunchKernel, "cuLaunchKernel");

    if(errorCount() != errCount) return CUDASupport.badLibrary;

    int driverVersion = 0;
    if (cuDriverGetVersion(&driverVersion) == CUresult.CUDA_SUCCESS) {
        int major = driverVersion / 1000;
        int minor = (driverVersion % 1000) / 10;
        int mapped = major * 100 + minor * 10;
        
        if (mapped >= cudaSupport) {
            loadedVersion = cudaSupport;
        } else {
            loadedVersion = cast(CUDASupport)mapped;
        }
    } else {
        loadedVersion = CUDASupport.cuda100;
    }

    return loadedVersion;
}

// Tests, following the BindBC family convention of inline `unittest` blocks
// run via `dub test` (cf. bindbc-loader's codegen.d — the only tested package
// in the official family).
unittest {
    import core.stdc.stdio : printf;

    // Symbol-load test: the driver library must load and the recently added
    // memory-management entry points must all be bound (non-null).
    CUDASupport support = loadCUDA();
    if(support == CUDASupport.noLibrary){
        printf("SKIP: CUDA driver library not found; skipping load test.\n");
        return;
    }
    assert(support != CUDASupport.badLibrary,
           "CUDA library found, but required symbols failed to load");

    assert(cuMemGetInfo !is null);
    assert(cuMemAllocPitch !is null);
    assert(cuMemcpy2D !is null);
    assert(cuMemcpy3D !is null);
    assert(cuMemsetD8 !is null);
    assert(cuMemsetD16 !is null);
    assert(cuMemsetD32 !is null);
    assert(cuMemsetD2D8 !is null);
    assert(cuMemsetD2D16 !is null);
    assert(cuMemsetD2D32 !is null);
    assert(cuMemcpyHtoDAsync !is null);
    assert(cuMemcpyDtoHAsync !is null);
    assert(cuMemcpyDtoDAsync !is null);
    assert(cuMemcpy2DAsync !is null);
    assert(cuMemcpy3DAsync !is null);
    assert(cuMemsetD8Async !is null);
    assert(cuMemsetD16Async !is null);
    assert(cuMemsetD32Async !is null);
    assert(cuMemsetD2D8Async !is null);
    assert(cuMemsetD2D16Async !is null);
    assert(cuMemsetD2D32Async !is null);
    printf("PASS: loadCUDA() and all new memory-management symbols bound.\n");

    // Guarded smoke test: exercise cuMemGetInfo/cuMemAllocPitch on a real
    // device when one is present; skip gracefully (message, not a failure)
    // on driverless / GPU-less machines so CI without a GPU still passes.
    int devCount = 0;
    if(cuInit(0) != CUresult.CUDA_SUCCESS
       || cuDeviceGetCount(&devCount) != CUresult.CUDA_SUCCESS
       || devCount == 0){
        printf("SKIP: no usable CUDA device; skipping cuMemAllocPitch smoke test.\n");
        return;
    }

    CUdevice dev;
    assert(cuDeviceGet(&dev, 0) == CUresult.CUDA_SUCCESS);
    CUcontext ctx;
    assert(cuCtxCreate(&ctx, 0, dev) == CUresult.CUDA_SUCCESS);
    scope(exit) cuCtxDestroy(ctx);

    size_t freeMem, totalMem;
    assert(cuMemGetInfo(&freeMem, &totalMem) == CUresult.CUDA_SUCCESS);
    assert(totalMem > 0 && freeMem <= totalMem);

    CUdeviceptr p;
    size_t pitch;
    // ElementSizeBytes must be 4, 8 or 16; 33 floats wide forces row padding.
    assert(cuMemAllocPitch(&p, &pitch, 33 * float.sizeof, 7, float.sizeof)
           == CUresult.CUDA_SUCCESS);
    assert(pitch >= 33 * float.sizeof);
    assert(cuMemFree(p) == CUresult.CUDA_SUCCESS);
    printf("PASS: cuMemAllocPitch smoke test on device 0.\n");
}
