# Install LinuxRunner

Installing LinuxRunner and installing Linux inside it are separate steps. Start with the IPA; then follow [Set Up Linux](GETTING_STARTED.md).

## Requirements

- An ARM64 iPhone or iPad. The application deployment target is iOS/iPadOS 15.0; this is not a promise that every model or OS version has been qualified.
- Storage for your distributions and applications, plus a network connection for downloaded packages. The setup screen shows available space and installation estimates.
- A compatible IPA signing/sideloading method. LinuxRunner's normal release requires no jailbreak or JIT.

The maintainer has tested build 897 on a physical iPhone and confirms physical-iPad testing. An earlier iPhone 11/iOS 17 launch-black-screen report remains unresolved.

## Download, Sign and Open

1. Open [GitHub Releases](https://github.com/mxhm11cr/LinuxRunner/releases/latest) and download the IPA from **Assets**.
2. Compare its file size and SHA-256 with the published release values before signing it.
3. Install it with your preferred compatible tool, such as [Sideloadly](https://sideloadly.io/) or [AltStore Classic](https://altstore.io/).
4. Open LinuxRunner and follow [Getting Started — Installing Linux in LinuxRunner](GETTING_STARTED.md).

The v1.0.1 build script's **unsigned** mode means *no Apple signing identity/provisioning*. It adds an ad-hoc code signature and a standard ZIP layout for tools to replace or process. An ad-hoc signature alone does not authorize ordinary installation on a physical device. Signing requirements, refresh periods and tool compatibility depend on the method and account. No sideloading service is guaranteed to work.

App Group access is optional. The app uses `group.dev.linuxrunner.app` when that entitlement is provided and private application storage otherwise. No JIT entitlement is required by the normal **LinuxRunner** scheme. Do not confuse optional developer execution-engine experiments with ordinary release requirements.

## Verify a Download

Use the actual downloaded filename and checksum published for that release:

```sh
shasum -a 256 "$IPA_FILE"
```

Here `IPA_FILE` is a local variable containing your downloaded IPA's path. On Windows PowerShell, use `Get-FileHash -Algorithm SHA256` with that file. Signing changes the file, so compare the original download first.

With the matching source checkout and Python 3, you can also inspect its package structure:

```sh
python3 scripts/validate-ipa.py "$IPA_FILE" --expect-sha256 "$PUBLISHED_SHA256"
```

These checks detect archive/hash problems; they do not establish acceptance by every installer or device.

## Updating Without Losing Environments

Back up important Linux files, retain your earlier IPA and keep the same bundle identifier and App Group configuration. Changing how the app is signed can change which storage container it can access. Do not delete the app to investigate missing environments. Reinstalling over the same app identity may preserve data, but a different identity or provisioning/container change can prevent access to it.

If an installer reports an invalid ZIP/IPA or cannot find the end-of-central-directory record, verify the download before changing signing tools. [Troubleshooting](TROUBLESHOOTING.md#the-installer-says-the-ipa-is-invalid)
