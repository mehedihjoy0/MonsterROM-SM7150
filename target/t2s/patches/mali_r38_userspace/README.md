# Mali r38p1 One UI 9 compatibility userspace

The target Galaxy S21+ firmware ships an Android 11 Mali r38p0 userspace.
Android 17's EGL loader sees `ro.hardware.egl=mali`, but cannot load that old
binary and SurfaceFlinger aborts before the boot animation can start.

This module keeps FloppyKernel's native Mali r38p1 kernel driver and installs
the matching Android 13 r38p1 Mali-G78 userspace from a pinned Galaxy A54
firmware dump. It replaces only the EGL UMD, Vulkan shim, and Samsung
`mali_symlink.so` compatibility shim.

The build verifies:

- the kernel release and Job Manager UK ABI through a freshly generated build
  manifest;
- every donor file by SHA-256;
- ELF class, Mali release, G78 support, exports, dependencies, and shim
  runpaths;
- installed filesystem metadata and SELinux labels; and
- that `boot.img` and `vendor_boot.img` remain byte-for-byte unchanged.

The experimental r49 userspace module runs later in module order and can still
replace this baseline only when explicitly enabled.
