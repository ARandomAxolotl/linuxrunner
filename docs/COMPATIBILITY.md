# Compatibility

LinuxRunner targets ARM64 Linux userspace on iPhone and iPad. Compatibility depends on the distribution, package version, operation and device resources. A package appearing in the catalog is not a successful test.

## How to Read the Status

**Launch reported** means a program opened; it does not validate all features. **Basic interaction** applies only to the listed actions. **Experimental** means incomplete or variable compatibility. No application below is represented as fully tested across devices and workloads.

The maintainer identifies the latest physical-iPhone Arch/graphical/Telegram tests as **build 897**. The maintainer also confirms physical-iPad testing and Telegram login, messaging and calls on Arch. Exact device model, OS and artifact checksum were not supplied. Earlier screenshots were explicitly confirmed by the maintainer as physical-iPhone captures. They illustrate the experience rather than a full current-build regression test.

## Devices

| Area | Current status |
| --- | --- |
| iPhone | Physical-device use reported by the maintainer, including Arch desktop on build 897. |
| iPad | Device family 2, four orientations, window-aware viewer sizing, keyboard shortcuts and pointer handling are implemented. The maintainer confirms testing on a physical iPad. |
| OS | Deployment target iOS/iPadOS 15.0. Every supported-looking version/model is not automatically qualified. An older iPhone 11/iOS 17 launch-black-screen report remains open. |
| Input | Touch, on-screen keyboard, hardware keyboard and pointer paths exist. iPad support has been physically tested; accessory behavior can vary with the device and platform settings. |

## Distributions and Desktops

| Environment | Status | Limits |
| --- | --- | --- |
| Debian 13 ARM64 | Terminal, `apt` and LinuxRunner Desktop available | Recommended starting point; incomplete Linux ABI coverage. |
| Debian KDE Plasma | Experimental; shown in supplied physical-iPhone captures | Higher memory use; no claim of a full v1.0.1 regression pass. |
| Arch Linux ARM | Terminal/`pacman` integrated; desktop success reported on iPhone build 897 | Rolling packages can change compatibility; signed recovery covers specific supported damage patterns. |
| Arch Openbox + LXQt Panel + PCManFM-Qt | Experimental; basic desktop/graphical launch success reported | Full LXQt session not claimed; preserve first-use launcher trust prompts. |
| Arch Plasma / Wayland | Unavailable | No supported Wayland session integration. |
| Alpine 3.24 ARM64 | Terminal and `apk` available | Desktop path remains experimental; no stable graphical claim. |

## Applications

| Application or group | Evidence | What remains unverified |
| --- | --- | --- |
| Shell and package tools | Available across the three environments; retained regression records cover package/filesystem/terminal operations | All tools and every installation/upgrade scenario on devices. |
| PCManFM-Qt / Arch desktop components | Maintainer reports working Arch desktop and graphical launches on iPhone build 897; retained focused tests cover file-manager navigation, windows and reconnect | Exact device action checklist, long sessions and every file operation. |
| Telegram Desktop | Maintainer-tested on Arch Linux ARM / physical-iPhone build 897: launch, login, sending messages and calls; supplied welcome-screen capture | Results apply to the tested configuration; other package/device combinations can vary. |
| Dolphin / Konsole | Supplied KDE capture shows these applications | Complete v1.0.1 device regression coverage. |
| Firefox | Supplied capture shows a public page | Broad website support, media, extensions and long sessions. |
| Chromium | Available through supported distribution/package paths; experimental | A current build/device feature checklist. |
| Blender | Supplied physical-iPhone capture shows the viewport | Rendering/export workflows, broad workloads and stability. |
| Text editors and other catalog applications | Some focused development checks exist; the catalog distinguishes its evidence | Current physical-device validation for each application. |
| Some Arch GTK/glycin applications | Known write-seal compatibility failures remain | Do not generalize Qt success to GTK compatibility. |

## Graphics, Storage and Networking

Mesa software rendering is the reference path. Metal acceleration supports selected OpenGL operations and remains experimental; full OpenGL/Vulkan compatibility is not claimed. Networking uses platform sockets and restrictions, not direct hardware access. File import/export and shared-folder integration exist; access is limited by selected permissions and the app's storage container.

Linux accounts and permissions are not a sandbox for hostile software. See [Known limitations](KNOWN_LIMITATIONS.md), [Security](../SECURITY.md) and [Troubleshooting](TROUBLESHOOTING.md).
