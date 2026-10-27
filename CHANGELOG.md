# Changelog

User-visible changes follow the Added / Changed / Fixed structure. Unreleased entries remain drafts until the maintainer approves publication; use the actual publication date when releasing.

## [1.0.1] — 2026-10-27

### Added

- iPad desktop adaptations: window-aware initial display sizing, hardware-keyboard desktop shortcuts and larger viewer-frame support, alongside the shared touch/pointer interface. Tested on a physical iPad.
- Arch Linux ARM installation from signed packages, `pacman` integration and an experimental Openbox desktop with LXQt Panel and PCManFM-Qt.
- Telegram Desktop compatibility on Arch Linux ARM, tested by the maintainer with login, sending messages and calls on build 897.
- A unified **Set Up Linux…** workflow for new installations and configuration of existing environments.
- Arch package-state diagnostics and signed cached-package/ownership recovery through the package-management path and Repair Center.

### Changed

- Arch desktop defaults now use a named PCManFM-Qt profile and dedicated visible LXQt panel configuration while preserving existing user settings.
- Desktop readiness checks require usable component windows and a submitted viewer frame; startup diagnostics retain relevant Qt platform errors.
- IPA packaging now includes an ad-hoc signature and installer-friendly ZIP layout. Apple signing/provisioning is still required for ordinary device installation.
- Installation, distribution, compatibility and troubleshooting documentation now covers iPhone, iPad and all three distributions.

### Fixed

- Arch terminal compatibility for the termios2 operations required by its shell environment.
- Qt desktop/application launch context so managed launches inherit the active user's X11 display and authorization.
- Reopening a live desktop now reuses its existing session/viewer rather than rejecting re-entry.
- Invalid or obsolete Arch package-recovery state, including validated reconciliation of orphaned GCC ownership, without bypassing signature checks.
- Desktop panel/surface failure handling so a repeatedly crashing component does not falsely leave the desktop marked ready or end unrelated applications.
- ARM64 vDSO executable mapping and Linux filesystem/syscall compatibility gaps covered by the retained regression evidence.

### Known Issues

- Arch desktop and Metal acceleration remain experimental. Arch Plasma and Wayland sessions are unavailable; some Arch GTK/glycin applications encounter write-seal compatibility gaps.
- Application compatibility still depends on distribution, package version and device resources.
- Exact tested device/OS and artifact identities should accompany compatibility reports.
- An earlier iPhone 11/iOS 17 app-launch black-screen report remains unresolved.
- Demanding applications can be slow or exceed platform memory limits. Background suspension/termination can stop Linux processes.

## [1.0.0] — 2026-10-25

### Added

- First public release of the iPhone application, with ARM64 Linux instruction interpretation and a Linux userspace compatibility layer.
- Debian and Alpine environments, terminal, Linux accounts, package management and LinuxRunner Desktop.
- Experimental Debian KDE Plasma and Metal graphics support, with application compatibility limitations.
- Installation progress for account tools, desktop components and KDE Plasma, including measured percentages where available, actionable errors and retry.
- Keep Screen Awake During Operations, Settings icons and third-party font/terminal notices.

### Changed

- Account-tool preparation reuses recent package lists, retries outdated lists and checks installed tools before reporting success.
- Public versioning and LinuxRunner branding replaced the earlier internal version/name in user-facing release information.

### Fixed

- An account-tools preparation failure could appear to finish without effect when its installer had not started.

[1.0.1]: https://github.com/mxhm11cr/LinuxRunner/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/mxhm11cr/LinuxRunner/releases/tag/v1.0.0
