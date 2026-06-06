#!/usr/bin/env bash
# make-release-bundle.sh — assemble a self-contained, distributable RELEASE
# bundle of the cross-compiled aarch64 Clasp for the ADI ADSP-SC598 (Cortex-A55).
#
# Portable across every host we package on: Ubuntu, Fedora, Arch, Rocky, macOS.
# It stages the bundle tree, strips it with a cross-capable stripper, then emits:
#   <out>/                       the staged bin/lib/images tree (deploy this)
#   <out>/VERSION                version / variant / strip / host stamp
#   <out>/MANIFEST.txt           file listing with sizes + symlink targets
#   <out>/SHA256SUMS             per-file checksums (verify: sha256sum -c / shasum -c)
#   <out>.tar.gz                 the release archive (top dir = <out> basename)
#   <out>.tar.gz.sha256          checksum of the archive
#
# This only PACKAGES already-built artifacts; it does NOT cross-compile. Build the
# aarch64 tree first (see CROSS-COMPILING.md): ./select-build.sh aarch64 && ./koga
# && ninja -C build-aarch64 ... plus the QEMU image/module steps.
#
# Usage: make-release-bundle.sh [options]
#   --variant boehm|boehmprecise  GC variant to package        (default: boehmprecise)
#   --out DIR                     staging dir   (default: <sdk>/clasp-sc598-<ver>-aarch64-<variant>)
#   --sdk-root DIR                ADI SDK root  (default: config-aarch64.sexp / $ADI_SDK_ROOT / built-in)
#   --repo DIR                    Clasp checkout(default: $CLASP_REPO / built-in)
#   --sysroot DIR                 target aarch64 sysroot (default: derived from --sdk-root)
#   --strip-tool PATH             explicit cross-capable strip (llvm-strip / *-strip)
#   --no-strip                    keep symbols (default: strip)
#   --strip                       force strip  (the default)
#   --no-archive                  stage the directory only; skip tar + checksums
#   -h, --help                    show this help
#
# macOS note: stripping aarch64 ELF needs llvm-strip (brew install llvm). The ADI
# GNU cross-strip is an x86_64-linux binary and is used only on Linux hosts; if no
# cross-capable stripper is found the bundle is left UNSTRIPPED (with a warning).
set -euo pipefail

# ---- built-in defaults (this host); override via flags/env on other machines ----
DEFAULT_SDK_ROOT=/mnt/nvme2n1/data02/adi-sdk
DEFAULT_REPO=/mnt/nfs/goedezp01/goedezp01ds01/data/projects/swdev/clasp

VARIANT=boehmprecise
OUT=""
SDKROOT=""
REPO=""
SYSROOT=""
STRIP_TOOL=""
DO_STRIP=1
DO_ARCHIVE=1

# ------------------------------- helpers ----------------------------------------
die()  { printf 'error: %s\n'   "$*" >&2; exit 1; }
warn() { printf 'warning: %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

usage() { awk 'NR==1{next} /^set -euo/{exit} {sub(/^# ?/,""); print}' "$0"; }

# portable `readlink -f`: resolve a chain of symlinks to a real absolute path.
resolve_link() {
  local p t d
  p=$1
  while [ -L "$p" ]; do
    t=$(readlink "$p")
    case $t in
      /*) p=$t ;;
      *)  p=$(dirname "$p")/$t ;;
    esac
  done
  d=$(cd "$(dirname "$p")" 2>/dev/null && pwd -P) || return 1
  printf '%s/%s\n' "$d" "$(basename "$p")"
}

# extract a quoted  :key "value"  from a koga config sexp (first match)
sexp_value() {  # $1=key  $2=file
  [ -f "$2" ] || return 1
  sed -n "s/.*$1[[:space:]][[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" "$2" | head -1 || true
}

# choose a sha256 implementation once
if   have sha256sum; then SHA_TOOL=sha256sum
elif have shasum;    then SHA_TOOL=shasum
elif have openssl;   then SHA_TOOL=openssl
else SHA_TOOL=""; fi
sha256_hex() {  # $1=file -> bare hex digest
  case "$SHA_TOOL" in
    sha256sum) sha256sum "$1"        | cut -d' ' -f1 ;;
    shasum)    shasum -a 256 "$1"    | cut -d' ' -f1 ;;
    openssl)   openssl dgst -sha256 "$1" | sed 's/.*[= ] *//' ;;
    *)         echo "NO-SHA256-TOOL" ;;
  esac
}

# pick a stripper that can handle aarch64 ELF on this host
find_strip_tool() {
  if [ -n "$STRIP_TOOL" ]; then printf '%s\n' "$STRIP_TOOL"; return 0; fi
  local c
  for c in llvm-strip llvm-strip-22 llvm-strip-21 llvm-strip-20 llvm-strip-19 llvm-strip-18; do
    if have "$c"; then command -v "$c"; return 0; fi
  done
  for c in /opt/homebrew/opt/llvm/bin/llvm-strip /usr/local/opt/llvm/bin/llvm-strip; do
    [ -x "$c" ] && { printf '%s\n' "$c"; return 0; }
  done
  # ADI GNU cross-strip is an x86_64-linux binary -> Linux hosts only
  if [ "$(uname -s)" = Linux ] && [ -x "$ADI_STRIP" ]; then printf '%s\n' "$ADI_STRIP"; return 0; fi
  return 1
}

# --------------------------------- args -----------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --variant)    VARIANT=${2:?--variant needs an argument}; shift ;;
    --out)        OUT=${2:?--out needs an argument}; shift ;;
    --sdk-root)   SDKROOT=${2:?--sdk-root needs an argument}; shift ;;
    --repo)       REPO=${2:?--repo needs an argument}; shift ;;
    --sysroot)    SYSROOT=${2:?--sysroot needs an argument}; shift ;;
    --strip-tool) STRIP_TOOL=${2:?--strip-tool needs an argument}; shift ;;
    --strip)      DO_STRIP=1 ;;
    --no-strip)   DO_STRIP=0 ;;
    --no-archive) DO_ARCHIVE=0 ;;
    -h|--help)    usage; exit 0 ;;
    *) die "unknown option: $1  (try --help)" ;;
  esac
  shift
done
case "$VARIANT" in boehm|boehmprecise) ;; *) die "bad --variant '$VARIANT' (boehm|boehmprecise)";; esac

# ----------------------------- resolve paths ------------------------------------
REPO=${REPO:-${CLASP_REPO:-$DEFAULT_REPO}}
[ -d "$REPO" ] || die "Clasp checkout not found: $REPO  (set --repo or \$CLASP_REPO)"

if [ -z "$SDKROOT" ]; then
  SDKROOT=${ADI_SDK_ROOT:-}
  [ -z "$SDKROOT" ] && SDKROOT=$(sexp_value ":adi-sdk-root" "$REPO/config-aarch64.sexp" || true)
  [ -z "$SDKROOT" ] && SDKROOT=$(sexp_value ":adi-sdk-root" "$REPO/config.sexp"          || true)
  [ -z "$SDKROOT" ] && SDKROOT=$DEFAULT_SDK_ROOT
fi
SDKROOT=${SDKROOT%/}
[ -d "$SDKROOT" ] || die "ADI SDK root not found: $SDKROOT  (set --sdk-root or \$ADI_SDK_ROOT)"

if [ -z "$SYSROOT" ]; then
  for d in "$SDKROOT"/adi-distro-glibc/*/sysroots/cortexa55-adi_glibc-linux; do
    [ -d "$d" ] && SYSROOT=$d
  done
  [ -n "$SYSROOT" ] || die "target sysroot not found under $SDKROOT/adi-distro-glibc/*/sysroots  (set --sysroot)"
fi
[ -d "$SYSROOT" ] || die "target sysroot not found: $SYSROOT"

SDK=$(dirname "$(dirname "$SYSROOT")")               # .../adi-distro-glibc/<ver>
ADI_STRIP="$SDK/sysroots/x86_64-adi_glibc_sdk-linux/usr/bin/aarch64-adi_glibc-linux/aarch64-adi_glibc-linux-strip"
LLVMLIB="$SDKROOT/llvm-22-aarch64/lib"
DEPSLIB="$SDKROOT/deps-aarch64/lib"
BLD="$REPO/build-aarch64/$VARIANT"

VER=$(sexp_value ":version" "$REPO/version.sexp" || true); [ -n "$VER" ] || VER=unknown
LLVM_VER=$(basename "$LLVMLIB"/libLLVM.so.* 2>/dev/null | sed 's/^libLLVM\.so\.//'); [ -n "$LLVM_VER" ] || LLVM_VER=unknown

[ -n "$OUT" ] || OUT="$SDKROOT/clasp-sc598-$VER-aarch64-$VARIANT"
OUT=${OUT%/}
case "$OUT" in ""|/) die "refusing to use OUT='$OUT'";; esac

# ----------------------------- preflight ----------------------------------------
[ -f "$BLD/iclasp" ]               || die "missing $BLD/iclasp — build iclasp-$VARIANT first (see CROSS-COMPILING.md)"
[ -f "$BLD/lib/libclasp.so" ]      || die "missing $BLD/lib/libclasp.so"
[ -f "$BLD/lib/images/base.fasl" ] || die "missing $BLD/lib/images/base.fasl — run the QEMU bytecode-image build"
[ -d "$LLVMLIB" ]                  || die "missing cross LLVM libs dir: $LLVMLIB"
[ -d "$DEPSLIB" ]                  || die "missing cross deps libs dir: $DEPSLIB"
[ -n "$SHA_TOOL" ] || warn "no sha256 tool (sha256sum/shasum/openssl) — checksums will be skipped"

printf '### staging release bundle ###\n'
printf '  clasp %s  variant=%s  llvm=%s\n' "$VER" "$VARIANT" "$LLVM_VER"
printf '  repo     : %s\n' "$REPO"
printf '  sdk-root : %s\n' "$SDKROOT"
printf '  sysroot  : %s\n' "$SYSROOT"
printf '  out      : %s\n' "$OUT"

# ------------------------------- stage ------------------------------------------
rm -rf "$OUT"
mkdir -p "$OUT/bin" "$OUT/lib" "$OUT/images"

cp "$BLD/iclasp"               "$OUT/bin/iclasp"
cp "$BLD/lib/libclasp.so"      "$OUT/lib/libclasp.so"
cp "$BLD/lib/images/base.fasl" "$OUT/images/base.fasl"

# core modules (asdf, serve-event, ...) if built; clasp finds them at
# SYS:LIB;MODULES; which the build-tree image resolves to
# <CLASP_HOME>/build-aarch64/<variant>/lib/modules. run-clasp.sh sets CLASP_HOME
# to the bundle root and we drop a build-aarch64/<variant> -> .. symlink so the
# logical path lands back on lib/modules.
NMOD=0
if [ -d "$BLD/lib/modules" ]; then
  mkdir -p "$OUT/lib/modules"
  for m in "$BLD"/lib/modules/*.fasl; do
    [ -e "$m" ] || continue
    cp "$m" "$OUT/lib/modules/"; NMOD=$((NMOD+1))
  done
  mkdir -p "$OUT/build-aarch64"; ln -sfn .. "$OUT/build-aarch64/$VARIANT"
fi

# cross-built LLVM: copy the real soname files (DT_NEEDED uses these exact names)
for f in "$LLVMLIB"/libLLVM.so.* "$LLVMLIB"/libclang-cpp.so.*; do
  [ -f "$f" ] || continue
  [ -L "$f" ] && continue
  cp "$f" "$OUT/lib/$(basename "$f")"
done
ls "$OUT/lib"/libLLVM.so.*      >/dev/null 2>&1 || die "no libLLVM.so.* copied from $LLVMLIB"
ls "$OUT/lib"/libclang-cpp.so.* >/dev/null 2>&1 || die "no libclang-cpp.so.* copied from $LLVMLIB"

# cross-built deps: real file + soname symlink (DT_NEEDED uses the soname link).
# cp -RP preserves symlinks portably (GNU and BSD); skip the bare dev .so / .la.
for fam in libfmt libgmp libgmpxx; do
  got=0
  for f in "$DEPSLIB"/$fam.so.*; do
    [ -e "$f" ] || continue
    cp -RP "$f" "$OUT/lib/"; got=1
  done
  [ "$got" = 1 ] || die "missing $fam.so.* in $DEPSLIB"
done

# target sysroot libs for self-containment (already stripped by Yocto):
# resolve the real file, copy it, recreate the soname symlink if needed.
for soname in libelf.so.1 libstdc++.so.6 libgcc_s.so.1; do
  src=$(find "$SYSROOT" -name "$soname" 2>/dev/null | head -1 || true)
  [ -n "$src" ] || die "sysroot lib $soname not found under $SYSROOT"
  real=$(resolve_link "$src") || die "cannot resolve $src"
  base=$(basename "$real")
  cp "$real" "$OUT/lib/$base"
  [ "$base" != "$soname" ] && ln -sf "$base" "$OUT/lib/$soname" || true
done

# normalise modes (real files only; symlinks are skipped by -type f)
find "$OUT/lib" -type f -name '*.so*' -exec chmod 0755 {} +
find "$OUT" -type f -name '*.fasl'    -exec chmod 0644 {} +
chmod 0755 "$OUT/bin/iclasp"

# ---- target launcher (runs on the board; intentionally /bin/sh + literal) ------
cat > "$OUT/run-clasp.sh" <<'EOF'
#!/bin/sh
# Run cross-compiled Clasp on the ADSP-SC598 (aarch64).
here=$(cd "$(dirname "$0")" && pwd)
export LD_LIBRARY_PATH="$here/lib:${LD_LIBRARY_PATH:-}"
export CLASP_HOME="$here"          # SYS: root -> finds lib/modules (require :asdf)
exec "$here/bin/iclasp" --image "$here/images/base.fasl" "$@"
EOF
chmod +x "$OUT/run-clasp.sh"

# --------------------------------- strip ----------------------------------------
STRIPPED=no
if [ "$DO_STRIP" = 1 ]; then
  if STRIP=$(find_strip_tool); then
    printf '### stripping with %s (--strip-unneeded keeps .dynsym) ###\n' "$STRIP"
    "$STRIP" "$OUT/bin/iclasp" || warn "strip failed on iclasp"
    for so in "$OUT"/lib/libclasp.so "$OUT"/lib/libLLVM.so.* "$OUT"/lib/libclang-cpp.so.* \
              "$OUT"/lib/libfmt.so.* "$OUT"/lib/libgmp.so.* "$OUT"/lib/libgmpxx.so.*; do
      [ -e "$so" ] || continue
      [ -L "$so" ] && continue            # leave soname symlinks alone
      "$STRIP" --strip-unneeded "$so" || warn "strip failed on $(basename "$so")"
    done
    STRIPPED=yes
  else
    warn "strip requested but no cross-capable strip found (need llvm-strip; macOS: brew install llvm) — leaving UNSTRIPPED"
    STRIPPED="no (no strip tool)"
  fi
fi

# ----------------------- VERSION / README / MANIFEST ----------------------------
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)
cat > "$OUT/VERSION" <<EOF
clasp-version: $VER
target:        aarch64 (ADI ADSP-SC598 / Cortex-A55), ADI Yocto Linux 5.0.1 (glibc)
gc-variant:    $VARIANT
build-mode:    bytecode
llvm:          $LLVM_VER
modules:       $NMOD
stripped:      $STRIPPED
packaged-on:   $NOW  ($(uname -s) $(uname -m), host=$(uname -n 2>/dev/null || echo unknown))
EOF

cat > "$OUT/README.md" <<EOF
# Clasp $VER for the ADSP-SC598 (Arm Cortex-A55, aarch64 Linux)

Cross-compiled Clasp $VER (bytecode, Boehm GC [$VARIANT], LLVM $LLVM_VER) for the
ADI ADSP-SC598-SOM-EZKIT running ADI Yocto Linux 5.0.1.

## Deploy
Copy this directory to the board (e.g. /opt/clasp) and run:

    ./run-clasp.sh                                  # REPL
    ./run-clasp.sh --non-interactive --eval '(print (+ 40 2))' --eval '(core:quit 0)'

glibc and the dynamic loader come from the board's own rootfs; everything else
(libclasp, libLLVM, libclang-cpp, libfmt, libgmp/gmpxx, libstdc++, libgcc_s,
libelf) is in ./lib. (require :asdf) loads the bundled ASDF.

## Integrity
    sha256sum -c SHA256SUMS        # Linux  (macOS: shasum -c SHA256SUMS)
The archive's own checksum is in <archive>.tar.gz.sha256.

Rebuilt with toolchains/make-release-bundle.sh (re-verify under QEMU after any
strip). Full cross-compile recipe and design notes: CROSS-COMPILING.md.
EOF

# human-readable manifest (files + symlinks)
( cd "$OUT" && find . \( -type f -o -type l \) | LC_ALL=C sort | while IFS= read -r f; do
    rel=${f#./}
    if [ -L "$f" ]; then
      printf 'link  %12s  %s -> %s\n' "-" "$rel" "$(readlink "$f")"
    else
      sz=$(wc -c < "$f" | tr -d ' ')
      printf 'file  %12s  %s\n' "$sz" "$rel"
    fi
  done ) > "$OUT/MANIFEST.txt"

# per-file checksums LAST, so it covers VERSION/README/MANIFEST too (excludes self)
if [ -n "$SHA_TOOL" ]; then
  ( cd "$OUT" && find . -type f ! -name SHA256SUMS | LC_ALL=C sort | while IFS= read -r f; do
      rel=${f#./}
      printf '%s  %s\n' "$(sha256_hex "$rel")" "$rel"
    done ) > "$OUT/SHA256SUMS"
fi

# --------------------------------- archive --------------------------------------
ARCHIVE=""
if [ "$DO_ARCHIVE" = 1 ]; then
  ARCHIVE="$OUT.tar.gz"
  rm -f "$ARCHIVE" "$ARCHIVE.sha256"
  # COPYFILE_DISABLE stops macOS tar from injecting ._ AppleDouble entries
  COPYFILE_DISABLE=1 tar -czf "$ARCHIVE" -C "$(dirname "$OUT")" "$(basename "$OUT")"
  if [ -n "$SHA_TOOL" ]; then
    printf '%s  %s\n' "$(sha256_hex "$ARCHIVE")" "$(basename "$ARCHIVE")" > "$ARCHIVE.sha256"
  fi
fi

# --------------------------------- summary --------------------------------------
printf '\n### release bundle ready ###\n'
printf '  dir      : %s  (%s)\n' "$OUT" "$(du -sh "$OUT" 2>/dev/null | cut -f1)"
if [ -n "$ARCHIVE" ]; then
  printf '  archive  : %s  (%s)\n' "$ARCHIVE" "$(du -h "$ARCHIVE" 2>/dev/null | cut -f1)"
  [ -f "$ARCHIVE.sha256" ] && printf '  checksum : %s\n' "$ARCHIVE.sha256"
fi
printf '  variant  : %s   modules: %s   stripped: %s\n' "$VARIANT" "$NMOD" "$STRIPPED"
printf -- '--- lib ---\n'
ls -lh "$OUT/lib"
