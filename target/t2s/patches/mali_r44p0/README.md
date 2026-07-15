# t2s Mali r44p0 matched-stack port

This device patch selects a complete Mali DDK pair for the Exynos Galaxy S21+
(`t2s`). The default, `T2S_MALI_DDK=r44p0`, combines:

- Samsung's `r44p0-01eac0` Job Manager KMD (UK ABI 11.39), imported at build
  time from the pinned `s5e8835` kernel source.
- Pixel 6 Android 14 `r44p0-01eac0` 32-bit and 64-bit Mali-G78 UMDs and Vulkan
  shims, pinned to build `UQ1A.231205.015`.
- The Android 14 VNDK-SP graphics AIDL and DMA-BUF heap dependencies required
  by that UMD. These versioned libraries are installed under `vendor/lib*` so
  the SP-HAL linker namespace can resolve them; the ROM's newer system copies
  are left untouched.
- The exact 32-bit and 64-bit Pixel vendor `libdrm.so` pair from the same
  `UQ1A.231205.015` factory image. `libdrm` is not present in Google's VNDK v34
  prebuilts or the proprietary-only donor repository, so the first build
  range-downloads the compressed `vendor.img` member, verifies it, extracts
  the two small libraries, and keeps only their checksum-pinned cache files.

The Pixel binary probes for the AIDL allocator service but retains the HIDL
Mapper 4 path used by the G996B vendor. The build checks both imports and
requires the target's `@4.0::IAllocator/default` declaration before accepting
the port. Exynos 2100's allocator implementation, mapper, HWC, device tree,
DVFS, thermal, BTS/QoS, LLC and secure-rendering integration are not replaced.

Every binary is SHA-256 pinned. The device patch also requires the kernel
module's atomic build manifest and checks the installed boot/vendor_boot image
hashes, preventing an r44 UMD from being packaged with an r38 KMD (or vice
versa). A final layout check requires `libdrm.so` and `libdmabufheap.so` to be
real vendor files for both ABIs, verifies their ELF class, SONAME, mode and
SELinux label, then resolves every direct dependency in the installed r44
SP-HAL closure.

Set `T2S_MALI_DDK=r38p1` to use the previous Samsung A54 r38p1 userspace and
FloppyKernel r38p1 KMD (UK ABI 11.35). Offline donor overrides are:

- `T2S_MALI_R44P0_DONOR_DIR` (directory containing `vendor/`)
- `T2S_MALI_R44P0_LIBDRM_DIR` (directory containing the exact factory
  `vendor/lib*/libdrm.so` pair)
- `T2S_MALI_V34_DONOR_DIR` (directory containing `vendor/`)
- `T2S_MALI_R38P1_DONOR_DIR` (directory containing `vendor/`)

r44p0 is an experimental bring-up target, not an overclock and not a guaranteed
performance improvement. Compilation and ABI validation do not replace a real
boot test. Before daily use, verify EGL/Vulkan startup, suspend/resume, camera,
DeX, protected video, thermal throttling and sustained GPU workloads on-device.
