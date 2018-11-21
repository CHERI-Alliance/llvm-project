# This file sets up a CMakeCache for a Fuchsia toolchain build.

set(LLVM_TARGETS_TO_BUILD X86;ARM;AArch64 CACHE STRING "")

set(PACKAGE_VENDOR Fuchsia CACHE STRING "")

set(LLVM_INCLUDE_EXAMPLES OFF CACHE BOOL "")
set(LLVM_INCLUDE_TESTS OFF CACHE BOOL "")
set(LLVM_INCLUDE_DOCS OFF CACHE BOOL "")
set(LLVM_ENABLE_BACKTRACES OFF CACHE BOOL "")
set(LLVM_ENABLE_PER_TARGET_RUNTIME_DIR ON CACHE BOOL "")
set(LLVM_ENABLE_TERMINFO OFF CACHE BOOL "")
set(LLVM_ENABLE_ZLIB OFF CACHE BOOL "")
set(CLANG_INCLUDE_TESTS OFF CACHE BOOL "")
set(CLANG_PLUGIN_SUPPORT OFF CACHE BOOL "")

set(LLVM_ENABLE_ASSERTIONS ON CACHE BOOL "")
set(CMAKE_BUILD_TYPE Release CACHE STRING "")

set(BOOTSTRAP_LLVM_ENABLE_LTO ON CACHE BOOL "")
if(NOT APPLE)
  set(BOOTSTRAP_LLVM_ENABLE_LLD ON CACHE BOOL "")
endif()

if(NOT APPLE)
  set(CLANG_DEFAULT_LINKER lld CACHE STRING "")
  set(CLANG_DEFAULT_OBJCOPY llvm-objcopy CACHE STRING "")
endif()
set(CLANG_DEFAULT_CXX_STDLIB libc++ CACHE STRING "")
set(CLANG_DEFAULT_RTLIB compiler-rt CACHE STRING "")

if(APPLE)
  set(COMPILER_RT_ENABLE_IOS OFF CACHE BOOL "")
  set(COMPILER_RT_ENABLE_TVOS OFF CACHE BOOL "")
  set(COMPILER_RT_ENABLE_WATCHOS OFF CACHE BOOL "")
elseif(UNIX)
  set(LIBUNWIND_ENABLE_SHARED OFF CACHE BOOL "")
  set(LIBUNWIND_USE_COMPILER_RT ON CACHE BOOL "")
  set(LIBUNWIND_INSTALL_LIBRARY OFF CACHE BOOL "")
  set(LIBCXXABI_USE_COMPILER_RT ON CACHE BOOL "")
  set(LIBCXXABI_ENABLE_SHARED OFF CACHE BOOL "")
  set(LIBCXXABI_USE_LLVM_UNWINDER ON CACHE BOOL "")
  set(LIBCXXABI_ENABLE_STATIC_UNWINDER ON CACHE BOOL "")
  set(LIBCXXABI_INSTALL_LIBRARY OFF CACHE BOOL "")
  set(LIBCXX_USE_COMPILER_RT ON CACHE BOOL "")
  set(LIBCXX_ENABLE_SHARED OFF CACHE BOOL "")
  set(LIBCXX_ENABLE_STATIC_ABI_LIBRARY ON CACHE BOOL "")
endif()

if(BOOTSTRAP_CMAKE_SYSTEM_NAME)
  set(target "${BOOTSTRAP_CMAKE_CXX_COMPILER_TARGET}")
  if(STAGE2_LINUX_${target}_SYSROOT)
    set(BUILTINS_${target}_CMAKE_SYSTEM_NAME Linux CACHE STRING "")
    set(BUILTINS_${target}_CMAKE_BUILD_TYPE Release CACHE STRING "")
    set(BUILTINS_${target}_CMAKE_SYSROOT ${STAGE2_LINUX_${target}_SYSROOT} CACHE STRING "")
    set(LLVM_BUILTIN_TARGETS "${target}" CACHE STRING "")

    set(RUNTIMES_${target}_CMAKE_SYSTEM_NAME Linux CACHE STRING "")
    set(RUNTIMES_${target}_CMAKE_BUILD_TYPE Release CACHE STRING "")
    set(RUNTIMES_${target}_CMAKE_SYSROOT ${STAGE2_LINUX_${target}_SYSROOT} CACHE STRING "")
    set(RUNTIMES_${target}_LLVM_ENABLE_ASSERTIONS ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBUNWIND_ENABLE_SHARED OFF CACHE BOOL "")
    set(RUNTIMES_${target}_LIBUNWIND_USE_COMPILER_RT ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBUNWIND_INSTALL_LIBRARY OFF CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXXABI_USE_COMPILER_RT ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXXABI_ENABLE_SHARED OFF CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXXABI_USE_LLVM_UNWINDER ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXXABI_ENABLE_STATIC_UNWINDER ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXXABI_INSTALL_LIBRARY OFF CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXX_USE_COMPILER_RT ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXX_ENABLE_SHARED OFF CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXX_ENABLE_STATIC_ABI_LIBRARY ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXX_ABI_VERSION 2 CACHE STRING "")
    set(RUNTIMES_${target}_SANITIZER_CXX_ABI "libc++" CACHE STRING "")
    set(RUNTIMES_${target}_SANITIZER_CXX_ABI_INTREE ON CACHE BOOL "")
    set(RUNTIMES_${target}_COMPILER_RT_USE_BUILTINS_LIBRARY ON CACHE BOOL "")
    set(LLVM_RUNTIME_TARGETS "${target}" CACHE STRING "")
  endif()
endif()

set(CLANG_BOOTSTRAP_TARGETS
  check-all
  check-llvm
  check-clang
  llvm-config
  test-suite
  test-depends
  llvm-test-depends
  clang-test-depends
  distribution
  install-distribution
  install-distribution-stripped
  clang CACHE STRING "")

get_cmake_property(variableNames VARIABLES)
foreach(variableName ${variableNames})
  if(variableName MATCHES "^STAGE2_")
    string(REPLACE "STAGE2_" "" new_name ${variableName})
    list(APPEND EXTRA_ARGS "-D${new_name}=${${variableName}}")
  endif()
endforeach()

# Setup the bootstrap build.
set(CLANG_ENABLE_BOOTSTRAP ON CACHE BOOL "")
set(CLANG_BOOTSTRAP_EXTRA_DEPS
  builtins
  runtimes
  CACHE STRING "")
set(CLANG_BOOTSTRAP_CMAKE_ARGS
  ${EXTRA_ARGS}
  -C ${CMAKE_CURRENT_LIST_DIR}/Fuchsia-stage2.cmake
  CACHE STRING "")
