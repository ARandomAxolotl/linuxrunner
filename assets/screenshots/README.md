# Screenshot Handoff

This directory is the existing screenshot collection; do not create a parallel `docs/screenshots` collection. Keep genuine originals. New images can use descriptive subject names here, with subdirectories only if the collection grows enough to need them.

## Selected Presentation

| Order | File | Placement / caption |
| --- | --- | --- |
| Hero | `linuxrunner-dolphin.png` | README introduction — KDE Plasma |
| 1 | `linuxrunner-home.png` | README gallery — LinuxRunner |
| 2 | `linuxrunner-settings.png` | README gallery — Settings |
| 3 | `linuxrunner-firefox.png` | README gallery — Firefox |
| 4 | `linuxrunner-blender-viewport.jpg` | README gallery — Blender |
| 5 | `arch-telegram-iphone.jpg` | README Arch application showcase — Telegram Desktop |

The maintainer explicitly confirmed the supplied images as physical-iPhone captures. They illustrate earlier use; they do not establish a complete v1.0.1 regression result. Captions name the software rather than internal test procedures. The supplied Blender viewport replaces the earlier splash-screen image in the active gallery. Originals are preserved without UI alteration.

The old blurry `linuxrunner-terminal.png` is not used. The replacement terminal capture supplied earlier contains an account identifier, so it is also withheld from this new gallery pending a clean capture. Other legacy images remain as originals and are not active v1.0.1 instructions; exclude unused originals from the final public presentation selection where appropriate.

## Captures Still Needed

The names below are proposed destinations, **not links to files that exist**. The documentation has no broken image placeholders.

| Proposed name | Capture | Intended placement |
| --- | --- | --- |
| `iphone-distributions-v101.png` | Distributions with the unified Set Up Linux action | Getting Started step 3 |
| `setup-choose-linux-v101.png` | Debian, Arch and Alpine choices | Step 5 |
| `setup-install-progress-v101.png` | Current install/progress screen, without personal identifiers | Step 7 |
| `setup-account-v101.png` | Blank account form; no entered credentials | Step 8 |
| `setup-desktop-components-v101.png` | Current Arch desktop components stage | Step 10 |
| `arch-terminal-v101.png` | `cat /etc/os-release`, `uname -m`, `pacman -Q`; nonidentifying prompt | Distribution/terminal showcase |
| `arch-desktop-v101.png` | Openbox, visible LXQt panel and PCManFM-Qt | README Arch showcase |
| `telegram-launch-v101.png` | Optional clearer landscape capture; the supplied `arch-telegram-iphone.jpg` is already integrated without altering its UI | Compatibility/application demonstration |
| `ipad-home-v101.png` | Actual iPad Home in a larger window | LinuxRunner on iPad |
| `ipad-desktop-v101.png` | Actual iPad desktop with input controls and readable windows | LinuxRunner on iPad |
| `debian-terminal-v101.png` | Clear Debian terminal without identifying account data | Terminal showcase |

For each new capture, record app version/build, device model, OS, orientation and what was actually tested in the private readiness record. Confirm that the image comes from that physical device before using it as such. Physical-iPad testing is confirmed by the maintainer; iPad screenshots and model/OS details have not yet been supplied.

Before publication, inspect at full resolution for notifications, messages, account names, emails, tokens and sensitive file paths. Request a clean capture or an explicitly reviewed redaction when necessary. Preserve aspect ratio and readable text; never fabricate application output. Use linked previews with intrinsic aspect ratio and verify GitHub's mobile/desktop rendering after integration. Do not create an empty iPad image section or link a proposed filename before the image arrives.

## 2026-10-27 Integration

The maintainer supplied `arch-telegram-iphone.jpg` and explicitly identified its distribution as Arch Linux ARM. The original full iPhone capture is retained byte-for-byte and contains no visible messages, logged-in account identifier or authentication token. Its on-screen timing is not used as a benchmark. The second supplied image is a layout reference only; its branding and imagery are not LinuxRunner screenshots. README branding uses the existing LinuxRunner icon geometry with a rounded SVG background, as requested. The shipped app icon is unchanged.
