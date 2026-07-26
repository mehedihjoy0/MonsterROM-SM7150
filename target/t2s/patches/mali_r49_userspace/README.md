# Mali r49p0 userspace backport

This experimental t2s module is disabled by default. On-device testing with
the Fold8 One UI 9 source and Exynos2100 vendor stopped at the Samsung splash
before ADB became available, so normal releases retain the target's proven
Mali userspace.

Set `T2S_ENABLE_EXPERIMENTAL_MALI_R49=1` in the build environment to opt in.
Do not distribute an opted-in build without an explicit experimental warning.

When enabled, the module replaces only the 32-bit and 64-bit Mali UMD and
Vulkan shim. It does not patch, replace, or select a kernel driver.

The source files come from the pinned Pixel 6 AP41.240726.009 vendor image.
Their Android 15 runtime closure is rewritten to private `libmali_r49_*`
SONAMEs, preventing it from overriding One UI 9's global `libdrm`,
`libdmabufheap`, or graphics NDK libraries.

The module verifies all donor and generated hashes, ELF classes, SONAMEs,
dependencies, filesystem metadata, and SELinux labels. It also hashes
`boot.img` and `vendor_boot.img` before and after installation and aborts if
either kernel artifact changes.

The r49p0 UMD with the unchanged r38p1 KMD is intentionally experimental and
must be validated on-device for GPU UAPI negotiation and rendering stability.
