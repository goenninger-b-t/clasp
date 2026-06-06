;;; Cross-compile Clasp for the ADI ADSP-SC598 (Cortex-A55, aarch64 Linux).
;;;
;;; Activate with:  ./select-build.sh aarch64   (copies this over config.sexp)
;;; then            ./koga  &&  ninja -C build-aarch64 iclasp-boehm
;;; Restore host:   ./select-build.sh host
;;; See CROSS-COMPILING.md.
;;;
;;; Host clang-22 cross-targets aarch64 against the ADI Yocto sysroot. clang's
;;; GCC autodetection fails on the Yocto layout (vendor adi_glibc; gcc bits in
;;; usr/lib/<triple>/<ver>), so:
;;;   * libstdc++ headers are pinned explicitly: -nostdinc++ -isystem ...
;;;   * link uses lld (:ld :lld) with -B/-L at the gcc crt dir (crtbegin/libgcc)
;;;   * LLVM/clang libs come from the cross-built aarch64 LLVM via the wrapper
;;;     llvm-config (toolchains/llvm-config-aarch64).
;;;   * Clasp's other external deps (fmt, GMP/gmpxx linked; Boost headers) are
;;;     cross-built/staged under adi-sdk/deps-aarch64 (see build-deps-aarch64.sh)
;;;     and pulled in via -isystem <deps>/include and -L <deps>/lib.
;;; The bytecode base image is built host-side by cross-clasp (SBCL), so it is
;;; architecture-neutral and needs no on-target execution.
(:build-mode :bytecode
 :build-path "build-aarch64/"
 :adi-sdk-root "/mnt/nvme2n1/data02/adi-sdk/"
 :llvm-config "/mnt/nvme2n1/data02/adi-sdk/toolchains/llvm-config-aarch64"
 :ld :lld
 :cflags "--target=aarch64-adi_glibc-linux --sysroot=/mnt/nvme2n1/data02/adi-sdk/adi-distro-glibc/5.0.1/sysroots/cortexa55-adi_glibc-linux -mcpu=cortex-a55+crypto -isystem /mnt/nvme2n1/data02/adi-sdk/deps-aarch64/include"
 :cxxflags "--target=aarch64-adi_glibc-linux --sysroot=/mnt/nvme2n1/data02/adi-sdk/adi-distro-glibc/5.0.1/sysroots/cortexa55-adi_glibc-linux -mcpu=cortex-a55+crypto -nostdinc++ -isystem /mnt/nvme2n1/data02/adi-sdk/adi-distro-glibc/5.0.1/sysroots/cortexa55-adi_glibc-linux/usr/include/c++/13.4.0 -isystem /mnt/nvme2n1/data02/adi-sdk/adi-distro-glibc/5.0.1/sysroots/cortexa55-adi_glibc-linux/usr/include/c++/13.4.0/aarch64-adi_glibc-linux -isystem /mnt/nvme2n1/data02/adi-sdk/adi-distro-glibc/5.0.1/sysroots/cortexa55-adi_glibc-linux/usr/include/c++/13.4.0/backward -isystem /mnt/nvme2n1/data02/adi-sdk/deps-aarch64/include"
 :cppflags "--target=aarch64-adi_glibc-linux --sysroot=/mnt/nvme2n1/data02/adi-sdk/adi-distro-glibc/5.0.1/sysroots/cortexa55-adi_glibc-linux -mcpu=cortex-a55+crypto -nostdinc++ -isystem /mnt/nvme2n1/data02/adi-sdk/adi-distro-glibc/5.0.1/sysroots/cortexa55-adi_glibc-linux/usr/include/c++/13.4.0 -isystem /mnt/nvme2n1/data02/adi-sdk/adi-distro-glibc/5.0.1/sysroots/cortexa55-adi_glibc-linux/usr/include/c++/13.4.0/aarch64-adi_glibc-linux -isystem /mnt/nvme2n1/data02/adi-sdk/adi-distro-glibc/5.0.1/sysroots/cortexa55-adi_glibc-linux/usr/include/c++/13.4.0/backward -isystem /mnt/nvme2n1/data02/adi-sdk/deps-aarch64/include"
 :ldflags "--target=aarch64-adi_glibc-linux --sysroot=/mnt/nvme2n1/data02/adi-sdk/adi-distro-glibc/5.0.1/sysroots/cortexa55-adi_glibc-linux -B/mnt/nvme2n1/data02/adi-sdk/adi-distro-glibc/5.0.1/sysroots/cortexa55-adi_glibc-linux/usr/lib/aarch64-adi_glibc-linux/13.4.0 -L/mnt/nvme2n1/data02/adi-sdk/adi-distro-glibc/5.0.1/sysroots/cortexa55-adi_glibc-linux/usr/lib/aarch64-adi_glibc-linux/13.4.0 -L/mnt/nvme2n1/data02/adi-sdk/deps-aarch64/lib")
