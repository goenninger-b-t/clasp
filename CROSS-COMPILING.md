# Cross-Compiling Clasp for the ADSP-SC598 (Arm Cortex-A55, aarch64 Linux)

**Status:** DONE on the host side — a functional aarch64 Clasp is cross-compiled,
its bytecode image built (via QEMU), bundled, and self-contained-tested under
emulation (`(compile ...)`, bignums, 10! all work). Deploy bundle:
`adi-sdk/clasp-sc598-bundle/`. Remaining: copy to the SC598 and verify natively
on the A55 (can't execute aarch64 on the x86 host beyond QEMU). The host build
(x86-64, LLVM 22.1.7, bytecode, boehmprecise) also works. See §9 for the full
recipe and the hard-won gotchas.

This is a **downstream** document. Do not edit upstream files (CLAUDE.md, etc.)
for this effort. Like `config.sexp`, this file and the cross-build config are
local to this checkout.

---

## 1. Target

- Board: **ADI ADSP-SC598-SOM-EZKIT**.
- App core: **one Arm Cortex-A55 @ up to 1.2 GHz** (ARMv8.2-A) → **aarch64**.
  The dual SHARC+ DSP cores are irrelevant — Clasp targets the A55/Linux only.
- RAM: **512 MB DDR3 on a 16-bit bus** — low capacity *and* low bandwidth.
- OS: ADI Yocto Linux ("Linux for ADSP-SC5xx"), **scarthgap 5.0.1**, glibc.

## 2. Decisions & constraints

- **Bytecode-only at runtime is acceptable** (no on-device native/JIT). LLVM's
  code-gen pages then stay cold (cost disk, not resident RAM) — but Clasp still
  **links** LLVM; there is **no no-LLVM build option**.
- 512 MB is tight → build everything **MinSizeRel + stripped**, and build LLVM
  with the **AArch64 target only**. Use the conservative **`boehm`** GC variant
  for first bring-up (simpler than `boehmprecise` on a new arch).
- Feasibility: marginal-but-plausible. Expect it to run but be **slow**.

## 3. ADI SDK (installed)

Root, configurable via `:adi-sdk-root` in `config.sexp`:
`/mnt/nvme2n1/data02/adi-sdk/`

```
/mnt/nvme2n1/data02/adi-sdk/adi-distro-glibc/5.0.1/
  environment-setup-cortexa55-adi_glibc-linux   # source -> $CC $CXX $SDKTARGETSYSROOT
  sysroots/cortexa55-adi_glibc-linux            # TARGET aarch64 sysroot
  sysroots/x86_64-adi_glibc_sdk-linux           # host SDK tools
```
- Triple `aarch64-adi_glibc-linux`; `CROSS_COMPILE=aarch64-adi_glibc-linux-`.
- Toolchain **GCC 13.4.0** (SDK ships GCC, not clang — we use its *sysroot*).
- Target C++ runtime `libstdc++.so.6.0.32` (GCC-13) → **C++20-capable**.
- Default CFLAGS bake `-mcpu=cortex-a55+crypto -mbranch-protection=standard
  -fstack-protector-strong -O2 -D_FORTIFY_SOURCE=2`.

All cross SDKs/toolchains (incl. the LLVM we cross-build) live under this root.

## 4. Why this is tractable (Clasp-internals findings)

- **The self-hosting bootstrap is NOT the blocker in bytecode mode.** The base
  image is built host-side by `cross-clasp` on SBCL — `src/koga/scripts.lisp`
  `compile-bytecode-image` uses the host `$lisp`, not `$clasp`; rule
  `:compile-bytecode-image` in `src/koga/ninja.lisp` is a `lisp-command`.
  `cross-clasp` is bundled at `src/cross-clasp/`. So `base.fasl` is
  architecture-neutral bytecode produced on the x86 host.
- **aarch64 is a supported Clasp arch:** calling convention covers
  `__x86_64__ || __aarch64__` (`include/clasp/core/lispCallingConvention.h`);
  `:ARM64` pushed onto `*features*` (`src/core/corePackage.cc`); arm64 i-cache
  flush handled (`include/clasp/llvmo/code.h`); release notes cite non-Apple
  arm64.
- **Supported LLVM majors: 15–20 and 22 (NOT 21)** — `+llvm-major-version+` in
  `src/koga/units.lisp`, corroborated by C++ `LLVM_VERSION_MAJOR` guards.
- **koga has NO first-class cross support** (no target/sysroot/triple slots).
  We drive it via `:cc :cxx :cflags :cxxflags :cppflags :ldflags :llvm-config`
  plus a wrapper `llvm-config`.

## 5. Host build prerequisites (the x86-64 host that runs the cross-build)

Already encoded in this checkout's `config.sexp` for the working host LLVM-22
build; the same machine quirks affect the cross toolchain:
- clang auto-selects gcc-14 (no libstdc++ headers) → pin to gcc-13 with
  `--gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/13` across
  cflags/cxxflags/cppflags/ldflags.
- Needs `libclang-22-dev` (clang/AST headers) **and** `libclang-cpp22-dev`
  (`libclang-cpp.so`) — not just `llvm-22-dev`/`clang-22`.

## 6. Plan to get Clasp onto the A55

**Phase 1 — Cross-build LLVM 22.1.7 for aarch64 (the long pole).**
Host clang-22 as compiler, `--sysroot=$SDKTARGETSYSROOT`,
`LLVM_TARGETS_TO_BUILD=AArch64`, `CMAKE_BUILD_TYPE=MinSizeRel`, reuse the host
LLVM-22 `*-tblgen` as native tools; build `libLLVM` + `libclang-cpp`. Install to
`/mnt/nvme2n1/data02/adi-sdk/llvm-22-aarch64/`.

**Phase 2 — Wrapper `llvm-config`.** Reports `--version` 22.x (passes koga's
check), `--bindir` = **host** clang-22 bin (the cross-compiler runs on the
host), but `--includedir/--libs/--ldflags/--system-libs` = the **aarch64** LLVM
from Phase 1 (for linking the target binary).

**Phase 3 — Cross `config.sexp`.** `:build-mode :bytecode`, `:llvm-config`
= the wrapper, conservative `boehm` variant, and `:cc/:cxx/:cflags/...` = host
clang-22 with `--target=aarch64-adi_glibc-linux --sysroot=$SDKTARGETSYSROOT
-mcpu=cortex-a55`. Likely a separate `:build-path` so the host build survives.

**Phase 4 — Configure + cross-build the C++ runtime.** `./koga`, then build
`iclasp` / `libclasp.so` for aarch64. The bytecode `base.fasl` comes from
cross-clasp on the host (arch-neutral).

**Phase 5 — Assemble, deploy, test.** Stage `iclasp` + `libclasp.so` +
`base.fasl` + aarch64 `libLLVM`/`libclang-cpp` + deps onto the board/rootfs.
**Test that the host-built `base.fasl` loads on the aarch64 `iclasp`** — the key
unproven assumption.

**Fallback — QEMU-user native build.** If the image doesn't load on target, or
modules (asdf, …) are needed: binfmt + `qemu-aarch64-static`, build "natively"
inside the ADI aarch64 rootfs (koga unmodified; `$clasp` steps run emulated).
Slower, but no koga cross-hacking and an exact glibc match.

## 7. Risks / open items (confidence)

| Item | Confidence |
|---|---|
| Host-built bytecode `base.fasl` loads unmodified on aarch64 | moderate — must test (fallback: QEMU-native) |
| Clasp+LLVM fits in 512 MB, bytecode-only | unknown → tight; mitigate w/ MinSizeRel+strip, AArch64-only LLVM |
| glibc/libstdc++ skew | low — build against the ADI sysroot |
| aarch64-Linux runtime maturity (FFI/GC/fixups) | low-moderate — expect minor arch bugs |

## 8. References

- ADSP-SC596/598 datasheet — https://www.analog.com/media/en/technical-documentation/data-sheets/adsp-sc596-adsp-sc598.pdf
- ADI Yocto meta layer (lnxdsp-adi-meta) — https://github.com/analogdevicesinc/lnxdsp-adi-meta
- Linux for ADSP-SC5xx 5.0.1 docs — https://analogdevicesinc.github.io/lnxdsp-adi-meta/Linux-for-ADSP%E2%80%90SC5xx-5.0.1-Landing-Page.html
- Building the SDK — https://wiki.analog.com/resources/tools-software/linuxdsp/docs/quickstartguide/building-the-sdk

## 9. Progress log & artifacts

All under `$ADI_SDK_ROOT` = `/mnt/nvme2n1/data02/adi-sdk/`.

> **Note — toolchains scripts are vendored in the repo.** The `toolchains/*`
> cross-build scripts (`aarch64-adi.cmake`, `build-llvm-aarch64.sh`,
> `build-deps-aarch64.sh`, `llvm-config-aarch64`, `make-bundle-aarch64.sh`,
> `make-release-bundle.sh`) now live in the checkout at `toolchains/` (the single
> source of truth); the `$ADI_SDK_ROOT/toolchains/` entries are symlinks back to
> them, so the SDK-relative paths below and in `config-aarch64.sexp`
> (`:llvm-config`) still resolve. Those symlinks target the NFS checkout, so they
> only resolve where `/mnt/nfs` is mounted (i.e. this build host).

**Phase 1 — LLVM 22.1.7 aarch64 cross-build: DONE.**
- `toolchains/aarch64-adi.cmake` — CMake cross-toolchain (ADI GCC 13.4,
  `--sysroot` = target sysroot, `-mcpu=cortex-a55+crypto`).
- `toolchains/build-llvm-aarch64.sh` — `configure|build|install|all`. AArch64-only,
  MinSizeRel, no asserts, optional deps (zlib/zstd/xml2/terminfo/libedit) OFF,
  dylibs on; native tblgen reused from host `/usr/lib/llvm-22/bin` (22.1.7).
- `src/llvm-project-22.1.7.src/` — source; `build/llvm-22-aarch64/` — build tree.
- Installed to `llvm-22-aarch64/`: `lib/libLLVM.so.22.1` (66 MB, aarch64),
  `lib/libclang-cpp.so.22.1` (60 MB, aarch64), `include/{llvm,llvm-c,clang,clang-c}`.
  libLLVM NEEDED = librt/libstdc++.so.6/libm/libgcc_s/libc only (all in target
  sysroot). Total 199 MB; `aarch64-...-strip` can shrink the `.so`s for flash.

**Phase 2 — wrapper `llvm-config`: DONE.**
- `toolchains/llvm-config-aarch64` — reports `--version 22.1.7`, `--bindir` = host
  `/usr/lib/llvm-22/bin` (cross-compiler tools), and `--includedir/--ldflags/
  --libs/--system-libs` pointing at the aarch64 install. Validated against koga's
  six queries; `-lLLVM` resolvable; aarch64 `llvm-config.h` confirms target triple.

**Phase 3 — cross `config.sexp`: DONE.** koga always reads the fixed name
`config.sexp`, so host/cross builds swap it: `config-host.sexp` /
`config-aarch64.sexp` + `./select-build.sh host|aarch64` (repo root). The cross
config uses `:build-path "build-aarch64/"` so it never clobbers host `build/`.
The solved clang cross recipe (clang's GCC autodetection fails on the Yocto
layout — vendor `adi_glibc`, gcc bits in `usr/lib/<triple>/<ver>`):
- compile/preprocess: `--target=aarch64-adi_glibc-linux --sysroot=<tgt>
  -mcpu=cortex-a55+crypto`, and for C++ pin libstdc++ with `-nostdinc++ -isystem
  <sysroot>/usr/include/c++/13.4.0{,/aarch64-adi_glibc-linux,/backward}`.
- link: `-fuse-ld=lld` (`:ld :lld`) + `-B`/`-L` at the gcc crt dir
  (`<sysroot>/usr/lib/aarch64-adi_glibc-linux/13.4.0`, has crtbegin.o + libgcc.a).
- clasp REQUIRES clang (it emits LLVM IR for some files), so the link is
  clang-driven; that's why the linker/crt had to be wired explicitly.

**Phase 4 — cross-build the C++ runtime: IN PROGRESS.**
- External dependency closure (clasp links these; not in the ADI sysroot):
  **fmt 9.1.0** and **GMP 6.3.0** cross-built (shared) via
  `toolchains/build-deps-aarch64.sh` → `deps-aarch64/`; **Boost 1.83** headers
  (arch-independent; needed unconditionally by `instance.cc`/`inheritance.cc`/
  `gctools`) staged into `deps-aarch64/include`. Wired via `-isystem
  deps-aarch64/include` + `-L deps-aarch64/lib`. (`elf`/`dl` are in the sysroot;
  Boehm `gc` builds from in-tree `src/bdwgc`.)
- **RTTI gotcha:** clasp's asttooling uses `dynamic_cast`/`typeid` on clang AST
  nodes, so the aarch64 LLVM MUST be built with `LLVM_ENABLE_RTTI=ON` (default
  OFF). The first build lacked it → `iclasp` link failed with `undefined
  reference: typeinfo for clang::Decl`. Host LLVM has `--has-rtti YES`; matched it
  by rebuilding (the `build-llvm-aarch64.sh` configure now sets RTTI=ON).
- Result so far: **522/523** — every clasp C++ TU cross-compiled and
  `libclasp.so` linked; only the final `iclasp` link is pending the
  RTTI-enabled `libclang-cpp`. `iclasp-boehm`'s graph runs no target binary, so
  it cross-compiles fully on the host (the bytecode image/modules, which would
  need the target, are not on this path).
- **DONE (after the RTTI rebuild):** `build-aarch64/boehm/iclasp` (aarch64 PIE) +
  `lib/libclasp.so` (218M, aarch64) link cleanly; NEEDED = our cross
  libLLVM/libclang-cpp/libfmt/libgmp/libgmpxx + sysroot libstdc++/libgcc_s/libelf.

**Phase 5 — bytecode image + deploy: DONE (via QEMU).** Building `base.fasl` is
NOT host-only: `generate-lisp-info` runs `iclasp` to introspect the runtime and
`link-image` runs it again, interleaved with host-SBCL
`compile-bytecode-image`/cross-clasp steps. So koga's image build must run the
target binary on the build host → **QEMU-user emulation** (`qemu-user-static` +
`binfmt-support`; a "link only the final step on the board" shortcut does not fit
koga's interleave). Recipe — with QEMU installed, set:
```
export QEMU_LD_PREFIX=<target sysroot>            # glibc loader/core libs
export LD_LIBRARY_PATH=<sysroot>/lib:<sysroot>/usr/lib:\
  adi-sdk/llvm-22-aarch64/lib:adi-sdk/deps-aarch64/lib:build-aarch64/boehm/lib
ninja -C build-aarch64 boehm/lib/images/base.fasl   # generate-lisp-info(QEMU) ->
                                                    # compile-bytecode-image(SBCL) ->
                                                    # link-image(QEMU) -> base.fasl
```
Result: `base.fasl` (22 MB). Functional test under QEMU passed
(`impl=clasp ver=clasp-boehm-2.7.0-non-cst`, `(+ 40 2)=42`, `(compile ...)` works,
`10!`=3628800).

**Deploy bundle:** built by `toolchains/make-bundle-aarch64.sh [--strip]
[--variant boehm|boehmprecise] [--out DIR]` → `adi-sdk/clasp-sc598-bundle/` =
`bin/iclasp` + `lib/` (libclasp.so + cross libLLVM/libclang-cpp/libfmt/libgmp/
libgmpxx + libelf/libstdc++/libgcc_s) + `images/base.fasl` + `run-clasp.sh` +
`README.md`. Self-contained-tested under QEMU using only `bundle/lib`. Copy to the
SC598 and `./run-clasp.sh`. Final native run is on the board.

**Stripping (size option):** `--strip` strips the bundle's *copies* (build
artifacts stay unstripped for debugging). Uses the cross `strip
--strip-unneeded` on the `.so`s (keeps `.dynsym` for runtime linking) and a full
strip on `iclasp`; sysroot libs are already stripped. Validated under QEMU
(bignums + `compile` work after stripping). Result: **375 MB → 144 MB**
(`libclasp.so` 218→30, `libLLVM` 70→47, `libclang-cpp` 63→43). Always re-verify
after stripping, since stripping a shared lib can break symbol resolution.

**Release bundle (boehmprecise + modules):** `make-bundle-aarch64.sh --release
[--variant boehmprecise]` → stripped `clasp-sc598-release/` (~147 MB). `--release`
implies `--strip` (override with `--no-strip`); default out dir is
`clasp-sc598-release/`.
- **boehmprecise** cross-built (`iclasp-boehmprecise`, 1 QEMU step) and
  GC-stress-validated under QEMU: the precise collector preserved a 2000-element
  retained structure through ~1.6M allocations (`verify=T`, Σi² checksum exact),
  so the committed `clasp_gc.sif` layout is aarch64-correct.
- **Modules** `asdf` + `serve-event` built via QEMU (`modules-boehmprecise`,
  `compile-module` runs the precise `iclasp`), staged in `lib/modules/`.
  `(require :asdf)` loads ASDF 3.3.7.2.
- **SYS: gotcha:** the build-tree image resolves `SYS:` to
  `$CLASP_HOME/build-aarch64/<variant>/`, so the bundle sets `CLASP_HOME` (in
  run-clasp.sh) and adds a `build-aarch64/<variant> -> ..` symlink pointing back
  at the bundle root, making `SYS:LIB;MODULES;` resolve to `lib/modules/`. The
  clean alternative is a cross `ninja install` layout; the symlink is the
  lightweight workaround.

**Snapshot-based deploy — now viable upstream (alternative to image+symlink).**
At the `13f7ab789` base this bundle was built on, aarch64 `save-lisp-and-die
:executable` snapshots were **broken**: `snapshot_save_impl` hardcoded objcopy
`--output-target elf64-x86-64 --binary-architecture i386`, which aarch64 objcopy
rejects, silently emitting an empty object (→ linker "file is empty"). Fixed as
of `origin/main` `161bedf0c` by two commits:
- `9e2867f78` — select the objcopy target/arch by build arch
  (`elf64-littleaarch64` / `aarch64` on ARM64), and turn the previously-ignored
  `system()` failures into `exit(1)` instead of a false success.
- `8988144ad` — `snapshot_load` matches referenced C++ libraries by **basename**
  (SONAME) instead of the save-time absolute-path suffix, so a snapshot whose
  `libLLVM` / `libstdc++` / `libclasp` were relocated into a bundle `lib/` still
  loads ("position-independent" snapshot load).

Together these unlock a **snapshot bundle** (e.g. cando's `scando` /
`scando-zeus-install`) as an alternative to the image+symlink bundle above. The
two mechanisms are **orthogonal**: `8988144ad` fixes only `.so` (C++ library)
resolution; `SYS:LIB;MODULES;` logical-pathname resolution still needs the
`CLASP_HOME` + `build-aarch64/<variant>` symlink from the SYS: gotcha above, so
a snapshot bundle keeps that part. Rebuilding the aarch64 tree at `161bedf0c` is
**inert for the current image bundle** (these fixes live on the snapshot path
only) but is a prerequisite for any snapshot-based deploy.
