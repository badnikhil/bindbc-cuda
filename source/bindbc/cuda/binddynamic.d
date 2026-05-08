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

    // Module management
    alias pcuModuleLoad = CUresult function(CUmodule* mod, const(char)* fname);
    alias pcuModuleLoadData = CUresult function(CUmodule* mod, const(void)* image);
    alias pcuModuleUnload = CUresult function(CUmodule hmod);
    alias pcuModuleGetFunction = CUresult function(CUfunction* hfunc, CUmodule hmod, const(char)* name);

    // Memory management (v2 API)
    alias pcuMemAlloc = CUresult function(CUdeviceptr* dptr, size_t bytesize);
    alias pcuMemFree = CUresult function(CUdeviceptr dptr);
    alias pcuMemcpyHtoD = CUresult function(CUdeviceptr dstDevice, const(void)* srcHost, size_t byteCount);
    alias pcuMemcpyDtoH = CUresult function(void* dstHost, CUdeviceptr srcDevice, size_t byteCount);
    alias pcuMemcpyDtoD = CUresult function(CUdeviceptr dstDevice, CUdeviceptr srcDevice, size_t byteCount);
    alias pcuMemsetD8 = CUresult function(CUdeviceptr dstDevice, ubyte uc, size_t n);
    alias pcuMemsetD32 = CUresult function(CUdeviceptr dstDevice, uint ui, size_t n);

    // Stream management
    alias pcuStreamCreate = CUresult function(CUstream* phStream, uint flags);
    alias pcuStreamDestroy = CUresult function(CUstream hStream);
    alias pcuStreamSynchronize = CUresult function(CUstream hStream);

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

    pcuModuleLoad cuModuleLoad;
    pcuModuleLoadData cuModuleLoadData;
    pcuModuleUnload cuModuleUnload;
    pcuModuleGetFunction cuModuleGetFunction;

    pcuMemAlloc cuMemAlloc;
    pcuMemFree cuMemFree;
    pcuMemcpyHtoD cuMemcpyHtoD;
    pcuMemcpyDtoH cuMemcpyDtoH;
    pcuMemcpyDtoD cuMemcpyDtoD;
    pcuMemsetD8 cuMemsetD8;
    pcuMemsetD32 cuMemsetD32;

    pcuStreamCreate cuStreamCreate;
    pcuStreamDestroy cuStreamDestroy;
    pcuStreamSynchronize cuStreamSynchronize;

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

    // Module management 
    lib.bindSymbol(cast(void**)&cuModuleLoad, "cuModuleLoad");
    lib.bindSymbol(cast(void**)&cuModuleLoadData, "cuModuleLoadData");
    lib.bindSymbol(cast(void**)&cuModuleUnload, "cuModuleUnload");
    lib.bindSymbol(cast(void**)&cuModuleGetFunction, "cuModuleGetFunction");

    //  Memory management (v2)
    lib.bindSymbol(cast(void**)&cuMemAlloc, "cuMemAlloc_v2");
    lib.bindSymbol(cast(void**)&cuMemFree, "cuMemFree_v2");
    lib.bindSymbol(cast(void**)&cuMemcpyHtoD, "cuMemcpyHtoD_v2");
    lib.bindSymbol(cast(void**)&cuMemcpyDtoH, "cuMemcpyDtoH_v2");
    lib.bindSymbol(cast(void**)&cuMemcpyDtoD, "cuMemcpyDtoD_v2");
    lib.bindSymbol(cast(void**)&cuMemsetD8, "cuMemsetD8_v2");
    lib.bindSymbol(cast(void**)&cuMemsetD32, "cuMemsetD32_v2");

    // Stream management 
    lib.bindSymbol(cast(void**)&cuStreamCreate, "cuStreamCreate");
    lib.bindSymbol(cast(void**)&cuStreamDestroy, "cuStreamDestroy_v2");
    lib.bindSymbol(cast(void**)&cuStreamSynchronize, "cuStreamSynchronize");

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
