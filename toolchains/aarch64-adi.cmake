# CMake cross-toolchain file — ADI ADSP-SC598 / Cortex-A55 (aarch64 Linux)
# Uses the ADI Yocto SDK (adi-distro-glibc 5.0.1, GCC 13.4). Raw cross-gcc +
# explicit sysroot (we invoke the compiler directly, not via the env-setup).
set(CMAKE_SYSTEM_NAME      Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

set(ADI_SDK_ROOT       "/mnt/nvme2n1/data02/adi-sdk")
set(ADI_SDK            "${ADI_SDK_ROOT}/adi-distro-glibc/5.0.1")
set(ADI_TARGET_SYSROOT "${ADI_SDK}/sysroots/cortexa55-adi_glibc-linux")
set(ADI_TOOLBIN        "${ADI_SDK}/sysroots/x86_64-adi_glibc_sdk-linux/usr/bin/aarch64-adi_glibc-linux")
set(ADI_TRIPLE         "aarch64-adi_glibc-linux")

set(CMAKE_SYSROOT      "${ADI_TARGET_SYSROOT}")
set(CMAKE_C_COMPILER   "${ADI_TOOLBIN}/${ADI_TRIPLE}-gcc")
set(CMAKE_CXX_COMPILER "${ADI_TOOLBIN}/${ADI_TRIPLE}-g++")
set(CMAKE_AR           "${ADI_TOOLBIN}/${ADI_TRIPLE}-ar"     CACHE FILEPATH "")
set(CMAKE_RANLIB       "${ADI_TOOLBIN}/${ADI_TRIPLE}-ranlib" CACHE FILEPATH "")

# Cortex-A55 tuning (matches the ADI SDK default, incl. crypto extensions).
set(CMAKE_C_FLAGS_INIT   "-mcpu=cortex-a55+crypto")
set(CMAKE_CXX_FLAGS_INIT "-mcpu=cortex-a55+crypto")

# Find libraries/headers in the target sysroot; run programs (tblgen) from host.
set(CMAKE_FIND_ROOT_PATH               "${ADI_TARGET_SYSROOT}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM  NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY  ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE  ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE  ONLY)
