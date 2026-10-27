# LinuxRunner User Guide

Start with [Getting Started — Installing Linux in LinuxRunner](GETTING_STARTED.md) for the complete installation, account, terminal, desktop and application walkthrough. This page is a reference to the app's main controls; [Compatibility](COMPATIBILITY.md) records the limits of current test evidence.

## Main Tabs

| Tab | Controls |
| --- | --- |
| Home | Runtime status; Start Linux Runtime when needed; Open Desktop or Resume Desktop; Applications, App Manager, Terminal and Files. |
| Distributions | Installed environments; Set Up Linux…; environment details with Use on Next Launch for inactive environments. Switching requires a full relaunch. |
| Sessions | Desktop status, active account, Resume Desktop, Stop Desktop and Open Terminal. |
| Settings | Appearance, foreground screen-awake preference, graphics/input, shared files, Linux accounts, diagnostics and About LinuxRunner. |

The unified setup workflow can configure an existing environment or install another one. It does not require recreating an existing root filesystem to repair packages.

## Settings Reference

- **Appearance:** choose the native theme.
- **General:** Keep Screen Awake During Operations prevents idle locking during foreground operations; it does not prevent background suspension.
- **Desktop & Input:** Graphics, Desktop Environment, Audio, Display and Gestures, Application Launcher. Use Software (Mesa) as the reference when reporting experimental Metal problems.
- **Files & Devices:** Shared iPhone Folders and Devices. Some labels still say iPhone on iPad. Shared folders grant Linux programs access to the selected data; review permissions before adding them.
- **Environment:** Linux Users, Storage Management and Import File. Linux Users selects the default login, creates accounts and changes passwords. Stop/restart a desktop after changing its account.
- **Advanced:** Terminal & Keyboard, Export Open Desktop Report and Developer Mode. Optional execution-engine experiments are separate from normal release requirements.
- **About:** app version/build, source identity and Notices & Credits.

## Files and Applications

**Home → Files** is the exchange-folder view, not an unrestricted browser of every rootfs path. Its current shared Linux path is `/home/mobile/Downloads`; the screen offers file import and tap-to-export. **Settings → Shared iPhone Folders** manages separately selected folders and their access checks.

**Home → App Manager** provides the active environment's package operations and Repair Center. Applications discovered from desktop entries appear in the application launcher; discovery does not guarantee compatibility. [Package examples](GETTING_STARTED.md#12-install-and-launch-applications)

## Sessions and Help

**Done** closes the viewer while retaining a live desktop. **Stop Desktop** closes that session's applications; save documents first. App termination ends Linux processes even if the viewer had been detached. [Desktop controls](GETTING_STARTED.md#11-launch-and-use-the-desktop)

For a failed install, missing panel, black desktop, crash, input issue or signing/storage change, follow [Troubleshooting](TROUBLESHOOTING.md). Review diagnostic exports for personal information before attaching them to an issue.
