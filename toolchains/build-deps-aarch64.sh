#!/usr/bin/env bash
# Cross-build Clasp's external C/C++ deps for aarch64 (ADI ADSP-SC598):
#   * fmt   (links -lfmt; included by clasp/core/foundation.h everywhere)
#   * GMP   (links -lgmp -lgmpxx; bignum arithmetic)
# Built with the ADI Yocto GCC 13.4 cross toolchain, installed (shared libs +
# headers) into $ADI_SDK_ROOT/deps-aarch64 so the ADI sysroot stays pristine.
# clang/lld then links clasp against these via -I/-L in config-aarch64.sexp.
set -euo pipefail
ROOT=/mnt/nvme2n1/data02/adi-sdk
DEPS=$ROOT/deps-aarch64
TC=$ROOT/toolchains/aarch64-adi.cmake
SDK=$ROOT/adi-distro-glibc/5.0.1
SYSROOT=$SDK/sysroots/cortexa55-adi_glibc-linux
TOOLBIN=$SDK/sysroots/x86_64-adi_glibc_sdk-linux/usr/bin/aarch64-adi_glibc-linux
FVER=9.1.0
GVER=6.3.0

echo "### fmt $FVER (CMake, shared) ###"
tar -C "$ROOT/src" -xf "$ROOT/src/fmt-$FVER.tar.gz"
cmake -G Ninja -S "$ROOT/src/fmt-$FVER" -B "$ROOT/build/fmt-aarch64" \
  -DCMAKE_TOOLCHAIN_FILE="$TC" -DCMAKE_INSTALL_PREFIX="$DEPS" \
  -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DFMT_TEST=OFF -DFMT_DOC=OFF
ninja -C "$ROOT/build/fmt-aarch64" install

echo "### GMP $GVER (autotools, shared, +C++) ###"
tar -C "$ROOT/src" -xf "$ROOT/src/gmp-$GVER.tar.xz"
mkdir -p "$ROOT/build/gmp-aarch64"
cd "$ROOT/build/gmp-aarch64"
"$ROOT/src/gmp-$GVER/configure" --host=aarch64-linux-gnu --prefix="$DEPS" \
  --enable-cxx --enable-shared --disable-static \
  CC="$TOOLBIN/aarch64-adi_glibc-linux-gcc" \
  CXX="$TOOLBIN/aarch64-adi_glibc-linux-g++" \
  CFLAGS="--sysroot=$SYSROOT -mcpu=cortex-a55" \
  CXXFLAGS="--sysroot=$SYSROOT -mcpu=cortex-a55" \
  LDFLAGS="--sysroot=$SYSROOT"
make -j"$(nproc)"
make install
echo "DEPS_BUILD_DONE"
