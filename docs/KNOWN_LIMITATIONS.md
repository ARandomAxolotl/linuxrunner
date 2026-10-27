# Known Limitations

## Execution and Platform

LinuxRunner interprets ARM64 Linux userspace. It does not boot a Linux kernel, use hardware virtualization or require JIT in the normal release. x86/x86-64 applications, kernel modules, conventional Linux containers, systemd as init and Wayland sessions are unsupported. Linux system-call coverage is incomplete; an available package may require features the runtime does not implement.

The build targets iOS/iPadOS 15.0 and device families iPhone/iPad. This configuration is not a compatibility certificate for every device or OS. The maintainer confirms iPhone build 897 use and physical-iPad testing. An earlier iPhone 11/iOS 17 app-launch black-screen report is unresolved.

## Desktops and Applications

- Arch's Openbox/LXQt-component desktop is experimental. Current Arch Plasma is unavailable; installing a Wayland package does not provide a working session.
- Debian KDE Plasma is experimental and needs more memory than LinuxRunner Desktop.
- Some Arch GTK/glycin applications still encounter write-seal compatibility failures. Their warning or crash is not evidence that every Qt/X11 program is broken.
- Telegram Desktop login, sending messages and calls have been tested on Arch Linux ARM. Other application/version/device combinations can vary. Browsers, Blender and other demanding programs can be slow, incomplete or crash.
- A repeatedly crashing panel or desktop surface can be left stopped after bounded recovery while other applications continue. Save work before an explicit desktop stop.
- Mesa software rendering is the reference path. Experimental Metal acceleration covers selected OpenGL paths, with incomplete shader/API coverage. No full OpenGL or Vulkan conformance is claimed.
- Alpine is primarily documented as a terminal environment; its desktop path is experimental.

## Lifecycle, Storage and Safety

One Linux runtime is active per app launch. Switching distributions requires a full app relaunch. **Done** retains a live desktop inside the app, but iOS/iPadOS can suspend or terminate LinuxRunner. Keep Screen Awake only prevents foreground idle locking. Saved files persist; running Linux processes do not survive app termination.

Device memory and storage constrain workloads. No universal RAM, performance or installation-time guarantee is provided. Hardware access remains limited by the platform; an accessory input path is not general USB/Bluetooth device passthrough.

App Group and private storage availability follow the app's signature. Changing bundle identity or entitlement/container configuration can hide access to previous environments. Back up files and do not uninstall the app as a repair step.

Linux users and permissions do not isolate hostile programs from the app. Package repair uses real maintainer scripts; a package-metadata checkpoint is not a complete backup or guaranteed rollback. Never bypass package signatures to work around compatibility problems.

See [Compatibility](COMPATIBILITY.md), [Troubleshooting](TROUBLESHOOTING.md) and [Security](../SECURITY.md). Detailed syscall references remain in [SYSCALL_MATRIX.md](SYSCALL_MATRIX.md); their historical entries are not a device-wide test certificate.
