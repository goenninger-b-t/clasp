;;; Build Clasp in bytecode mode.
;;;
;;; clang (auto-detected llvm-19) defaults to selecting the highest-numbered
;;; GCC toolchain dir (gcc-14), but only gcc-13 has libstdc++ headers installed
;;; (no libstdc++-14-dev). Pin clang to the gcc-13 install for compile AND link
;;; so <cstdint> etc. and -lstdc++ resolve. Remove these flags if
;;; libstdc++-14-dev is later installed.
;;; The flag must cover all four clang-invoking ninja rules: :cc (cflags),
;;; :cxx/:cxx-llvm (cxxflags), :scrape-pp (cppflags), and :link/:link-lib
;;; (ldflags).
;;;
;;; Pin to LLVM 22 (clang/clang++/llvm-ar/etc. are taken from this install's
;;; bindir). This tree supports LLVM 15-20 and 22 (not 21); see
;;; koga +llvm-major-version+.
(:build-mode :bytecode
 ;; --- Cross-compilation SDK root (records-only; koga tolerates but does
 ;;     not yet consume this key — the aarch64 cross-build tooling reads it) ---
 ;; Canonical root under which ALL cross toolchains/SDKs are installed.
 ;; Currently holds the ADI Yocto SDK:
 ;;   <root>/adi-distro-glibc/5.0.1/
 ;;     environment-setup-cortexa55-adi_glibc-linux
 ;;     sysroots/cortexa55-adi_glibc-linux        (target aarch64 sysroot)
 ;;     sysroots/x86_64-adi_glibc_sdk-linux       (host SDK tools)
 ;;   triple aarch64-adi_glibc-linux, GCC 13.4, libstdc++ 6.0.32 (C++20).
 ;; See README.md, "Cross-compilation SDK root".
 :adi-sdk-root "/mnt/nvme2n1/data02/adi-sdk/"
 :llvm-config "/usr/lib/llvm-22/bin/llvm-config"
 :cflags "--gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/13"
 :cxxflags "--gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/13"
 :cppflags "--gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/13"
 :ldflags "--gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/13")
