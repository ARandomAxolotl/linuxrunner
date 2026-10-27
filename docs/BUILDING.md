# Building LinuxRunner

Ordinary installation uses the downloadable IPA. This guide is for building the **LinuxRunner** release scheme from source; developer execution-engine experiments use separate targets.

## Requirements

Use macOS with full Xcode and its iOS SDK, plus Git, Python 3, Meson, Ninja, CMake and `ld.lld` on `PATH`. The guest ARM64 vDSO requires LLVM's ELF linker; release builds fail if it cannot be built. System utilities include `curl`, `tar`, `file`, `shasum`, `ditto`, `codesign` and Info-ZIP `zip`.

The current preparation build used Xcode 27.1 / iOS SDK 27.1, Meson 1.12.1, Ninja 1.13.2 and CMake 4.4.4. Other toolchain versions have not been qualified by this task. The deployment target is iOS/iPadOS 15.0.

## Get the Source and Pinned Dependencies

```sh
git clone https://github.com/mxhm11cr/LinuxRunner.git
cd LinuxRunner
git submodule update --init --recursive --checkout -- deps/libapps deps/libarchive deps/glslang deps/spirv-cross
```

These four submodules provide terminal assets, archive support and shader compilation. `deps/linux` is an inherited optional kernel-build gitlink; the application release does not use or boot it. The prerequisite checker examines the four active dependencies rather than requiring that unused checkout.

Select the `v1.0.1` tag when reproducing this release. Keep your own uncommitted work safe before switching revisions.

## Check and Build

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
scripts/bootstrap-macos.sh
scripts/build-ipa.sh --unsigned
python3 scripts/verify-ipa.py build/releases
```

The archive produces `build/releases/LinuxRunner.ipa`, the retained `.xcarchive`/symbols, signing status, SHA-256, source fingerprint and validation reports. `RELEASE_DIR` and `ARTIFACT_NAME` can select a separate output directory/name. When verifying a renamed artifact, use the same `ARTIFACT_NAME`.

The **unsigned** mode creates an ad-hoc signature, not an Apple-provisioned application. A compatible signing/sideloading tool must provide device installation authorization. The build verifies the rootfs checksum, GUI resource manifest, package structure and embedded vDSO. `verify-ipa.py` additionally compares the IPA executable to the retained archive, audits device Mach-O images and matches symbols. Physical-device execution is a separate check.

Alpine 3.24.2 aarch64 is downloaded with a pinned SHA-256. `ROOTFS_CACHE` may point to a cached archive; the same hash verification applies. Normal tools are resolved through `PATH`. An optional `LINUXRUNNER_TOOLCHAIN_ROOT` supports the inherited bundled-toolchain layout; no maintainer-specific directory is required.

## Signing Your Own Build

Configure your own Apple account, certificate and provisioning in Xcode, then run:

```sh
TEAM_ID=YOUR_TEAM_ID scripts/build-ipa.sh
```

Do not commit certificates, private keys or provisioning profiles. The default bundle identifier is `dev.linuxrunner.app`. App Group access to `group.dev.linuxrunner.app` is optional because private-container storage is supported. Keep app identity and container configuration consistent when updating an existing installation.

## Release Configuration

`app/AppARM64.xcconfig` sets version **1.0.1**, build **897**, ARM64 and deployment target **15.0**. `app/iOS.xcconfig` selects device families **1,2**. `app/Info.plist` declares portrait/both landscape orientations for iPhone and all four orientations for iPad. The release uses the Asbestos interpreter, with JIT and dynamic emission disabled. Build numbers alone do not distinguish every development candidate; record the source revision and IPA checksum too.

## Guest Helpers and Developer Runtime

The IPA packages retained Linux ARM64 helper binaries in `app/LinuxRunner/GUISupport.bundle`; ordinary application builds do not rebuild every guest helper. Their sources/compile recipes are mapped in [bundled-guest-source-map.json](../licenses/bundled-guest-source-map.json). Preserve the notices and corresponding source when distributing them.

Graphics helper builds use `scripts/build-guest-mesa-metal.sh` and `scripts/build-guest-gles1.sh` with a disposable Debian ARM64 fixture, the required X11/OpenGL/EGL/GLES development packages, and `GPU_ROOTFS` / `GPU_EXCHANGE`. Only set `GPU_PACKAGE_ASSETS=1` when deliberately replacing packaged resources and regenerating their manifest.

For the command-line runtime:

```sh
meson setup build/host -Dengine=asbestos -Dguest_arch=arm64 -Djit=false -Djit_emit=false -Dcli_aot=
ninja -C build/host ish
python3 scripts/generate-gui-support-manifest.py --check
```

Use disposable fixtures for destructive tests. See [Architecture](ARCHITECTURE.md), [Contributing](../CONTRIBUTING.md) and [Third-party notices](../THIRD_PARTY_NOTICES.md). GitHub automatic source archives omit submodule contents; initialize the pins or use a separately supplied complete source archive.
