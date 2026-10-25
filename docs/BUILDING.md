# Building from source

## Requirements

- Xcode with the iOS SDK and command-line tools selected for that Xcode installation.
- Git, Python 3, Meson, Ninja and CMake on `PATH`.
- Network access for the pinned Alpine root filesystem and any missing source dependencies.

The release uses Xcode 27.1 / iOS SDK 27.1, Meson 1.12.1, Ninja 1.13.2 and CMake 4.4.4. The iOS deployment target is 15.0. Select **LinuxRunner** in `iSH.xcodeproj`; the release configuration is **Release**.

## Clone and initialize dependencies

```sh
git clone https://github.com/mxhm11cr/LinuxRunner.git
cd LinuxRunner
git submodule update --init --recursive --checkout -- deps/libapps deps/libarchive deps/glslang deps/spirv-cross
```

These four submodules provide terminal assets, archive support and the shader compiler. Their exact revisions are pinned in the repository. The inherited `deps/linux` gitlink is retained for source provenance; the active application does not use it and does not require its checkout.

## Build an unsigned IPA

Make sure command-line tools use the full Xcode installation. For Xcode installed in the standard application location:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
scripts/bootstrap-macos.sh
scripts/build-ipa.sh --unsigned
python3 scripts/verify-ipa.py build/releases
```

The output is `build/releases/LinuxRunner.ipa`, with a matching `.xcarchive`, signing-status file and checksums. The unsigned IPA still needs signing before installation. `ARTIFACT_NAME` and `RELEASE_DIR` can override the output name and directory; pass the same `ARTIFACT_NAME` when running the verifier.

The build downloads Alpine 3.24.2 aarch64 and verifies its pinned SHA-256. For a cached copy, set `ROOTFS_CACHE` to the archive's location. The cache is verified identically to a download.

For a signed build, configure your own Apple account and provisioning in Xcode, then run:

```sh
TEAM_ID=YOUR_TEAM_ID scripts/build-ipa.sh
```

The default bundle identifier is `dev.linuxrunner.app`. App Group access to `group.dev.linuxrunner.app` is optional because the application supports private-container storage. Match the signing configuration when installing over an existing copy.

## Guest graphics and support binaries

The repository retains the Linux ARM64 helpers packaged in `app/LinuxRunner/GUISupport.bundle`, their source files, notices and build recipes. The ordinary IPA build packages these retained resources; it does not rebuild every guest helper.

- `scripts/build-shader-compiler.sh` builds the host shader libraries from pinned glslang and SPIRV-Cross. The preparation scripts apply build-local corrections without changing those submodules.
- `scripts/build-guest-mesa-metal.sh` and `scripts/build-guest-gles1.sh` rebuild Linux graphics libraries and probes using `graphics/` and `tests/linuxrunner/gpu/`.
- The GUI bundle includes source and compilation commands for session helpers; see `install.sh`, `install-qt.sh` and `regression.sh`.

Guest helper builds require a disposable Debian ARM64 fixture with GCC and the relevant X11/OpenGL/EGL/GLES development packages, plus `GPU_ROOTFS` and `GPU_EXCHANGE`. Build the command-line runtime first:

```sh
meson setup build/host -Dengine=asbestos -Dguest_arch=arm64 -Djit=false -Djit_emit=false -Dcli_aot=
ninja -C build/host ish
```

Use disposable fixtures for development. `GPU_PACKAGE_ASSETS=1` replaces the packaged guest binaries and regenerates their manifest. Check packaged resource integrity with:

```sh
python3 scripts/generate-gui-support-manifest.py --check
```

Source revisions and license notices are recorded in [SOURCE_ORIGIN.txt](../SOURCE_ORIGIN.txt) and [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).
