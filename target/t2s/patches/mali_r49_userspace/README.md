# Mali r49p0 userspace backport

This experimental t2s module is disabled by default. Its r49p0 userspace
expects Job Manager UK ABI 11.45, while FloppyKernel intentionally retains
the r38p1 driver and UK ABI 11.35. Normal releases instead install the matched
Android 13 r38p1 compatibility userspace.

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

The splash failure captured on July 26 came from an older ZIP that contained
the Android 11 r38p0 userspace, not from this r49 module. The r49p0 UMD with
the unchanged r38p1 KMD remains intentionally experimental and must not be
treated as a boot-safe release configuration.
