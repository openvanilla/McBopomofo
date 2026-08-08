---
description: Build and run C++ engine tests
user-invocable: true
---

# /engine-test

Build and run the full C++ engine unit tests.

## Steps

1. Create the build directory if needed:
   ```bash
   mkdir -p Source/Engine/build
   ```

2. Configure with CMake:
   ```bash
   cd Source/Engine/build && cmake -DENABLE_TEST=ON -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ..
   ```

3. Build:
   ```bash
   cd Source/Engine/build && make -j$(sysctl -n hw.ncpu)
   ```

4. Run tests:
   ```bash
   cd Source/Engine/build && ctest --output-on-failure
   ```

Report test results. If any tests fail, show the failing test names and output.
