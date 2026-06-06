#!/usr/bin/env bash
# Assemble the aarch64 Clasp deploy bundle for the ADSP-SC598 (Cortex-A55),
# optionally stripped to minimize on-flash / resident size.
#
#   make-bundle-aarch64.sh [--strip] [--variant boehm|boehmprecise] [--out DIR]
#
# Build artifacts in build-aarch64/ are left UNSTRIPPED (for debugging); this
# strips only the bundle's own copies. Stripping a shared lib can break symbol
# resolution, so always re-verify the bundle (e.g. under QEMU) after --strip.
set -euo pipefail

ROOT=/mnt/nvme2n1/data02/adi-sdk
REPO=${CLASP_REPO:-/mnt/nfs/goedezp01/goedezp01ds01/data/projects/swdev/clasp}
SDK=$ROOT/adi-distro-glibc/5.0.1
SYSROOT=$SDK/sysroots/cortexa55-adi_glibc-linux
STRIP=$SDK/sysroots/x86_64-adi_glibc_sdk-linux/usr/bin/aarch64-adi_glibc-linux/aarch64-adi_glibc-linux-strip

DO_STRIP=0; STRIP_SET=0; RELEASE=0; VARIANT=boehm; OUT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --release)  RELEASE=1 ;;             # release bundle: strip is the default
    --strip)    DO_STRIP=1; STRIP_SET=1 ;;
    --no-strip) DO_STRIP=0; STRIP_SET=1 ;;
    --variant)  VARIANT=$2; shift ;;
    --out)      OUT=$2; shift ;;
    *) echo "usage: $(basename "$0") [--release] [--strip|--no-strip] [--variant boehm|boehmprecise] [--out DIR]" >&2; exit 2 ;;
  esac; shift
done
# --release implies stripping unless explicitly overridden, and a distinct out dir
[ "$RELEASE" = 1 ] && [ "$STRIP_SET" = 0 ] && DO_STRIP=1
[ -z "$OUT" ] && { [ "$RELEASE" = 1 ] && OUT=$ROOT/clasp-sc598-release || OUT=$ROOT/clasp-sc598-bundle; }
BLD=$REPO/build-aarch64/$VARIANT
[ -f "$BLD/iclasp" ] || { echo "missing $BLD/iclasp — build iclasp-$VARIANT first" >&2; exit 1; }

echo "### assembling bundle: $OUT (variant=$VARIANT, strip=$DO_STRIP) ###"
rm -rf "$OUT"; mkdir -p "$OUT/bin" "$OUT/lib" "$OUT/images"
install -m755 "$BLD/iclasp"               "$OUT/bin/iclasp"
install -m644 "$BLD/lib/libclasp.so"      "$OUT/lib/libclasp.so"
install -m644 "$BLD/lib/images/base.fasl" "$OUT/images/base.fasl"
# core modules (asdf etc.), if built — clasp finds them at SYS:LIB;MODULES; = <root>/lib/modules
if [ -d "$BLD/lib/modules" ]; then
  mkdir -p "$OUT/lib/modules"; cp -a "$BLD"/lib/modules/*.fasl "$OUT/lib/modules/" 2>/dev/null || true
  # The build-tree image resolves SYS: to <CLASP_HOME>/build-aarch64/<variant>/.
  # Make that path point back at the bundle root so SYS:LIB;MODULES; -> lib/modules.
  mkdir -p "$OUT/build-aarch64"; ln -sfn .. "$OUT/build-aarch64/$VARIANT"
  echo "  + $(ls "$OUT/lib/modules" 2>/dev/null | wc -l) modules (+ SYS: compat symlink)"
fi
# cross-built deps (preserve soname symlinks)
cp -a "$ROOT"/llvm-22-aarch64/lib/libLLVM.so.22.1 "$ROOT"/llvm-22-aarch64/lib/libclang-cpp.so.22.1 "$OUT/lib/"
cp -a "$ROOT"/deps-aarch64/lib/libfmt.so* "$ROOT"/deps-aarch64/lib/libgmp.so* "$ROOT"/deps-aarch64/lib/libgmpxx.so* "$OUT/lib/"
# sysroot libs for self-containment (already stripped by Yocto): real file + soname symlink
for soname in libelf.so.1 libstdc++.so.6 libgcc_s.so.1; do
  f=$(find "$SYSROOT" -name "$soname" 2>/dev/null | head -1); [ -n "$f" ] || continue
  real=$(readlink -f "$f"); cp "$real" "$OUT/lib/$(basename "$real")"
  [ "$(basename "$real")" != "$soname" ] && ln -sf "$(basename "$real")" "$OUT/lib/$soname" || true
done

cat > "$OUT/run-clasp.sh" <<'EOF'
#!/bin/sh
# Run cross-compiled Clasp on the ADSP-SC598 (aarch64).
here=$(cd "$(dirname "$0")" && pwd)
export LD_LIBRARY_PATH="$here/lib:${LD_LIBRARY_PATH:-}"
export CLASP_HOME="$here"          # SYS: root -> finds lib/modules (require :asdf)
exec "$here/bin/iclasp" --image "$here/images/base.fasl" "$@"
EOF
chmod +x "$OUT/run-clasp.sh"

cat > "$OUT/README.md" <<'EOF'
# Clasp for the ADSP-SC598 (Arm Cortex-A55, aarch64 Linux)

Cross-compiled Clasp 2.7.0 (bytecode, Boehm GC, LLVM 22.1.7) for the ADI
ADSP-SC598-SOM-EZKIT running ADI Yocto Linux 5.0.1.

Deploy: copy this directory to the board (e.g. /opt/clasp) and run:
    ./run-clasp.sh                                  # REPL
    ./run-clasp.sh --non-interactive --eval '(print (+ 40 2))' --eval '(core:quit 0)'
glibc/loader come from the board's own rootfs; everything else is in ./lib.

Rebuild this bundle with toolchains/make-bundle-aarch64.sh; pass --strip for a
smaller, symbol-stripped bundle (keeps dynamic symbols; re-verify after
stripping). Full cross-compile recipe and design notes: CROSS-COMPILING.md.
EOF

if [ "$DO_STRIP" = 1 ]; then
  echo "### stripping (cross strip; --strip-unneeded keeps .dynsym for runtime linking) ###"
  "$STRIP" "$OUT/bin/iclasp"                                  # executable: full strip
  # our shared libs: drop debug + local symbols, keep dynamic symbols
  for so in libclasp.so libLLVM.so.22.1 libclang-cpp.so.22.1 \
            libfmt.so.9.1.0 libgmp.so.10.5.0 libgmpxx.so.4.7.0; do
    [ -f "$OUT/lib/$so" ] && "$STRIP" --strip-unneeded "$OUT/lib/$so"
  done
  # sysroot libs (libstdc++/libgcc_s/libelf) are already stripped — leave them.
fi

echo "### bundle ready ###"
du -sh "$OUT"; echo "--- lib sizes ---"; ls -lh "$OUT/lib" | awk '$5{printf "  %-26s %s\n",$NF,$5}'
