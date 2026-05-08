/+
+          Copyright 2026 Nikhil
+ Distributed under the Boost Software License, Version 1.0.
+     (See accompanying file LICENSE_1_0.txt or copy at
+           http://www.boost.org/LICENSE_1_0.txt)
+/
/// CUDA Driver API version configuration and static/dynamic binding selection.
module bindbc.cuda.config;

/// Whether to use static binding (link-time) rather than dynamic loading.
enum staticBinding = (){
    version(BindBC_Static)     return true;
    else version(BindCUDA_Static) return true;
    else return false;
}();

/// Enumerates the supported CUDA Driver API versions and load-error states.
enum CUDASupport {
    noLibrary,
    badLibrary,
    cuda100 = 1000,
    cuda101 = 1010,
    cuda102 = 1020,
    cuda110 = 1100,
    cuda111 = 1110,
    cuda112 = 1120,
    cuda118 = 1180,
    cuda120 = 1200,
    cuda122 = 1220,
    cuda124 = 1240,
    cuda130 = 1300,
    cuda132 = 1320,
}

version(CUDA_132) {
    enum cudaSupport = CUDASupport.cuda132;
} else version(CUDA_130) {
    enum cudaSupport = CUDASupport.cuda130;
} else version(CUDA_124) {
    enum cudaSupport = CUDASupport.cuda124;
} else version(CUDA_122) {
    enum cudaSupport = CUDASupport.cuda122;
} else version(CUDA_120) {
    enum cudaSupport = CUDASupport.cuda120;
} else version(CUDA_118) {
    enum cudaSupport = CUDASupport.cuda118;
} else version(CUDA_112) {
    enum cudaSupport = CUDASupport.cuda112;
} else version(CUDA_111) {
    enum cudaSupport = CUDASupport.cuda111;
} else version(CUDA_110) {
    enum cudaSupport = CUDASupport.cuda110;
} else version(CUDA_102) {
    enum cudaSupport = CUDASupport.cuda102;
} else version(CUDA_101) {
    enum cudaSupport = CUDASupport.cuda101;
} else {
    enum cudaSupport = CUDASupport.cuda100;
}
