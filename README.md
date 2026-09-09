# bindbc-cuda

[![DUB Package](https://img.shields.io/dub/v/bindbc-cuda.svg)](https://code.dlang.org/packages/bindbc-cuda)
[![License](https://img.shields.io/badge/license-BSL--1.0-blue.svg)](https://boost.org/LICENSE_1_0.txt)

Static and dynamic D bindings for the NVIDIA CUDA Driver API and cuBLAS,
compatible with `@nogc`, `nothrow`, and `-betterC`.

Facing Problems? Discord - @badnikhil

## Features

- **Dynamic loading** — Load `nvcuda.dll` / `libcuda.so` at runtime via `bindbc-loader`.
- **Static linking** — Link against the CUDA driver library at compile time.
- **BetterC compatible** — Zero D runtime dependency.
- **Versioned symbols** — Binds to the modern `_v2` Driver API entry points.
- **Multi-version support** — Covers CUDA 10.0 through 12.4.
- **cuBLAS** — Handles, streams, pointer/math modes, GEMM (`Sgemm`, `Dgemm`,
  `SgemmStridedBatched`, `GemmEx`), and the Level 1/2/3 routines a tensor
  library needs. Loaded separately via `loadCUBLAS()`.

## Adding to your project

### dub.json

```json
"dependencies": {
    "bindbc-cuda": "~>1.0"
}
```

### dub.sdl

```sdl
dependency "bindbc-cuda" version="~>1.0"
```

### Selecting a CUDA version

Pass the appropriate version identifier to target a specific CUDA release:

```json
"versions": ["CUDA_120"]
```

The default (no version set) targets CUDA 10.0.

### Static binding

To link against the CUDA driver library at compile time instead of loading it
dynamically at runtime:

```json
"subConfigurations": {
    "bindbc-cuda": "static"
}
```

## Configurations

| Configuration | Description |
|---|---|
| `dynamic` | Dynamic binding via `bindbc-loader` (default) |
| `dynamicBC` | Dynamic binding with `-betterC` |
| `static` | Static (link-time) binding |
| `staticBC` | Static binding with `-betterC` |

## Usage

```d
import bindbc.cuda;

void main() {
    auto ret = loadCUDA();

    if(ret == CUDASupport.noLibrary) {
        // CUDA driver library not found on this system.
        return;
    }
    if(ret == CUDASupport.badLibrary) {
        // Library found but one or more symbols failed to bind.
        return;
    }

    // Driver API is ready.
    cuInit(0);

    int count;
    cuDeviceGetCount(&count);

    CUdevice dev;
    cuDeviceGet(&dev, 0);

    char[256] name;
    cuDeviceGetName(name.ptr, cast(int)name.length, dev);
}
```

### cuBLAS

cuBLAS is a separate shared library, so it has its own loader. Call it in
addition to `loadCUDA()`; either may succeed without the other.

```d
if(loadCUBLAS() < CUDASupport.cuda80) return;   // noLibrary / badLibrary

cublasHandle_t handle;
cublasCreate(&handle);
scope(exit) cublasDestroy(handle);
```

**cuBLAS is column-major.** A row-major `m x n` matrix is bit-identical in
memory to a column-major `n x m` one, so row-major operands are handled by
swapping the operands and the `m`/`n` extents — using `C^T = B^T * A^T` —
rather than by transposing:

```d
// Row-major A (M x K), B (K x N), C (M x N); computes C = A * B.
cublasSgemm(handle,
    cublasOperation_t.CUBLAS_OP_N, cublasOperation_t.CUBLAS_OP_N,
    N, M, K,                      // N and M swapped
    &alpha,
    cast(const(float)*)dB, N,     // B passed first
    cast(const(float)*)dA, K,
    &beta,
    cast(float*)dC, N);
```

Matrix and vector arguments are device addresses; `CUdeviceptr` values from
`cuMemAlloc` are passed with a cast, as above. See `test.d` for a complete
SGEMM validated against a CPU reference. `cublasStatusString` renders a
`cublasStatus_t` for reporting.

## Folder structure

```
bindbc-cuda/
├── dub.json
├── README.md
└── source/
    └── bindbc/
        └── cuda/
            ├── package.d       — Public import aggregator
            ├── config.d        — Version selection, staticBinding flag
            ├── types.d         — Opaque handles, enums, flags
            ├── cublas.d        — cuBLAS types and dynamic loading
            └── binddynamic.d   — Dynamic symbol loading via bindbc-loader
```

## License

Distributed under the [Boost Software License, Version 1.0](https://boost.org/LICENSE_1_0.txt).
