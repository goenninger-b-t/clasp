#!/usr/bin/env bash
# build-llvm-aarch64.sh — cross-build LLVM 22.1.7 for the ADI ADSP-SC598 (A55, aarch64).
#
# Produces libLLVM.so + libclang-cpp.so + headers under $PREFIX, for cross-building
# Clasp (Clasp links -lLLVM and -lclang-cpp and includes the llvm/ + clang/ headers).
#
# Cross toolchain: ADI Yocto SDK GCC 13.4 (via toolchains/aarch64-adi.cmake).
# Native tblgen reused from the host llvm-22 install (must be the same 22.1.7).
# Minimal config for a 512 MB target: AArch64 target only, MinSizeRel, no asserts,
# optional external deps (zlib/zstd/xml2/terminfo/libedit) OFF -> fewer target libs.
#
# Usage: build-llvm-aarch64.sh [configure|build|install|all]
set -euo pipefail

ADI_SDK_ROOT=/mnt/nvme2n1/data02/adi-sdk
LLVM_VER=22.1.7
SRC=$ADI_SDK_ROOT/src/llvm-project-$LLVM_VER.src/llvm
BUILD=$ADI_SDK_ROOT/build/llvm-22-aarch64
PREFIX=$ADI_SDK_ROOT/llvm-22-aarch64
TOOLCHAIN=$ADI_SDK_ROOT/toolchains/aarch64-adi.cmake
HOSTBIN=/usr/lib/llvm-22/bin

configure() {
  cmake -G Ninja -S "$SRC" -B "$BUILD" \
    -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" \
    -DCMAKE_BUILD_TYPE=MinSizeRel \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DLLVM_ENABLE_PROJECTS=clang \
    -DLLVM_TARGETS_TO_BUILD=AArch64 \
    -DLLVM_DEFAULT_TARGET_TRIPLE=aarch64-adi_glibc-linux \
    -DLLVM_HOST_TRIPLE=aarch64-adi_glibc-linux \
    -DLLVM_TARGET_ARCH=AArch64 \
    -DLLVM_TABLEGEN="$HOSTBIN/llvm-tblgen" \
    -DCLANG_TABLEGEN="$HOSTBIN/clang-tblgen" \
    -DLLVM_BUILD_LLVM_DYLIB=ON \
    -DLLVM_LINK_LLVM_DYLIB=ON \
    -DCLANG_LINK_CLANG_DYLIB=ON \
    -DLLVM_ENABLE_ASSERTIONS=OFF \
    -DLLVM_ENABLE_RTTI=ON \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DCLANG_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_DOCS=OFF \
    -DLLVM_ENABLE_TERMINFO=OFF \
    -DLLVM_ENABLE_LIBEDIT=OFF \
    -DLLVM_ENABLE_LIBXML2=OFF \
    -DLLVM_ENABLE_ZSTD=OFF \
    -DLLVM_ENABLE_ZLIB=OFF
}

# Build only the two shared libraries we need (no standalone tool binaries).
build() {
  ninja -C "$BUILD" LLVM clang-cpp
}

# Install just the libs + headers (install-* targets build any missing prereqs).
install_libs() {
  ninja -C "$BUILD" install-LLVM install-clang-cpp install-llvm-headers install-clang-headers
}

case "${1:-all}" in
  configure)   configure ;;
  build)       build ;;
  install)     install_libs ;;
  all)         configure && build && install_libs ;;
  *) echo "usage: $0 [configure|build|install|all]" >&2; exit 2 ;;
esac
