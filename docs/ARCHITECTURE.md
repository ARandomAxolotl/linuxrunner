# How LinuxRunner Works

LinuxRunner hosts ARM64 Linux userspace inside an iOS/iPadOS application. It combines instruction interpretation with a Linux ABI compatibility layer. The normal **LinuxRunner** release scheme disables JIT and does not boot a Linux kernel or use hardware virtualization.

```text
iOS / iPadOS application
  Setup, environments, terminal, files, diagnostics, desktop viewer
        |                                        |
  Pseudo-terminal                         Display / input forwarding
        |                                        |
  ARM64 interpreter + Linux syscall compatibility layer
  Executable loader | processes / threads | memory | filesystem | sockets
        |
  Debian / Arch Linux ARM / Alpine userspace
  Shells, package managers, X11 server, desktops and applications
```

## 1. Load Linux Executables

The runtime's ELF loader maps ARM64 Linux executables and their libraries into guest address spaces, sets up process state and transfers control to the interpreter. Executable availability does not imply that every required instruction or system call is supported.

## 2. Interpret ARM64 Instructions

The Asbestos interpreter decodes guest instructions into cached sequences of precompiled host routines, often called gadgets. Those routines implement guest instruction semantics. The release does not generate executable guest code at runtime. This is interpreted Linux execution, even though the device and guest both use ARM64.

Developer-only execution-engine/bootstrap targets are separate from the release configuration. Their presence in the source does not make JIT or a debugger a normal installation requirement.

## 3. Implement Linux System Calls

A userspace compatibility layer handles Linux calls for files, memory, processes, signals, synchronization, pseudo-terminals, sockets and related facilities. It uses platform operations and runtime bookkeeping rather than a running Linux kernel. Coverage is incomplete; unsupported semantics can prevent a program from working even after it loads.

## 4. Manage Guest Filesystems

Each environment has its own root filesystem and package database. `fakefs` combines real backing files with Linux metadata held in SQLite, including ownership and modes. Import/export and optional security-scoped shared folders connect selected device files to the environment. App Group availability determines whether storage uses that shared container or the application's private fallback.

## 5. Run Linux Processes and Threads

The runtime implements guest process/thread state, address spaces, scheduling interactions, signals and synchronization, including the Linux-facing behavior required by `fork`, `clone` and `execve`. These guest processes remain inside the application and its lifecycle. They do not become independently managed iOS applications or secure containers.

## 6. Integrate a Graphical Desktop

X11 applications connect to Xvfb. The desktop session starts its window manager, panel, file manager and services under the selected Linux account. x11vnc transports the display to the native RFB viewer. Managed launchers supply session-local display authorization and environment variables.

Arch uses Openbox, LXQt Panel and PCManFM-Qt. Debian also offers experimental KDE Plasma. A Wayland desktop/compositor session is not implemented.

## 7. Forward Display and Input

The viewer presents frames with UIKit/Metal and forwards touch, keyboard and pointer events. Window-aware initial sizing and hardware keyboard shortcuts support larger iPad layouts. Viewer scaling and Linux display resolution are separate controls.

Mesa supplies software OpenGL. The experimental guest Metal bridge forwards supported rendering operations to the platform GPU path; Metal presentation of a framebuffer alone is not evidence of Linux GPU API compatibility. Unsupported rendering/workloads can fail, and full API conformance is not claimed.

## Boundaries

A full-system emulator would include machine/boot/kernel behavior. A virtual machine would use a virtualized machine and guest kernel. LinuxRunner instead supplies a userspace Linux ABI and interprets guest instructions within one app. It does not expose general Linux hardware access.

The iOS/iPadOS sandbox is the security boundary. Linux user accounts and permissions do not isolate hostile code from the app or other environments. See [Security](../SECURITY.md), [Compatibility](COMPATIBILITY.md) and [Known limitations](KNOWN_LIMITATIONS.md). Developers can inspect `asbestos/`, `emu/`, `kernel/`, `fs/` and `app/LinuxRunner/` for the implementation.
