/+
+          Copyright 2026 Nikhil
+ Distributed under the Boost Software License, Version 1.0.
+     (See accompanying file LICENSE_1_0.txt or copy at
+           http://www.boost.org/LICENSE_1_0.txt)
+/
/// Static and dynamic D bindings for the NVIDIA CUDA Driver API.
module bindbc.cuda;

public import bindbc.cuda.config;
public import bindbc.cuda.types;

static if(!staticBinding) {
    public import bindbc.cuda.binddynamic;
}
