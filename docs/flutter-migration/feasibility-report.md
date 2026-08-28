# Flutter Migration Feasibility Report

Date: 2026-08-27

This report records only live platform evidence for the foundation feasibility gates. Automated tests, successful compilation, and shell startup are useful preliminary evidence, but they do not substitute for a live backend, authorized test identities, target deployment, or physical peripherals. The repository intentionally contains no machine code, employee credential, session secret, member/payment data, raw backend payload, printer address, or unredacted runtime export.

Allowed gate outcomes are `pass`, `fail`, and `blocked-by-environment`. A capability advances to `platform-verified` only after every platform and device required by its gate has live evidence.

## Preliminary runtime evidence

- Toolchain: Flutter 3.47.0, Dart 3.13.0, DevTools 2.60.0.
- Web host: macOS 26.5.2 (25F84), Google Chrome 151.0.7922.174. A release build served from a fresh localhost origin rendered `应用配置不可用`; the browser console contained no error. This demonstrates fail-closed startup without injected configuration, not backend or same-origin deployment compatibility.
- Android build: both debug and release APKs were produced. The release build uses the repository's temporary debug signing configuration and is not production-signing evidence.
- Android runtime: the APK installed and launched on an Android 7.0 (API 24) arm64 emulator. The application had a running PID and `MainActivity` was resumed/focused. The app compiles with SDK 37, has minimum SDK 24, and targets SDK 36. This demonstrates install/start compatibility only.
- Windows: no Windows host or Windows CI runner was available for a desktop runtime check.

Build artifacts are local, reproducible outputs and are excluded from source control:

- `flutter_workspace/apps/web_app/build/web/index.html`
- `flutter_workspace/apps/android_app/build/app/outputs/flutter-apk/app-debug.apk`
- `flutter_workspace/apps/android_app/build/app/outputs/flutter-apk/app-release.apk`

## Gate A — terminal authorization, login, and realtime synchronization

| Field | Value |
| --- | --- |
| App commit | `cbae483b63723592252f3989df4e510f4da5e28b` |
| Flutter version | `3.47.0` |
| Platform version | Web: Chrome 151.0.7922.174 on macOS 26.5.2; Android: Android 7.0 / API 24 emulator; Windows: unavailable |
| Test date | `2026-08-27` |
| Result | `blocked-by-environment` |
| Evidence path | `docs/flutter-migration/feasibility-evidence.json` IDs: `WEB-RUNTIME-001`, `ANDROID-RUNTIME-001`, `WINDOWS-ENV-001`, `AUTH-ENV-001` |
| Sanitized error | Required external prerequisites were unavailable: terminal machine code, authorized test employee account, live backend coordination, and a Windows runtime host. No secret or backend payload was captured. |
| Decision | status=defined; capabilities=AUTH-TERM-001,AUTH-LOGIN-001,SYNC-CONNECT-001; action=hold current status until Gate A and Gate C both pass on every required platform |

The available shell evidence cannot verify terminal authorization headers, login response handling, WebSocket authentication, heartbeat, forced disconnect, incremental reconciliation, logout, or the Android camera/HID scan required by this gate.

## Gate B — scanner and receipt-printer compatibility

| Field | Value |
| --- | --- |
| App commit | `cbae483b63723592252f3989df4e510f4da5e28b` |
| Flutter version | `3.47.0` |
| Platform version | Android: Android 7.0 / API 24 emulator; Windows: unavailable |
| Test date | `2026-08-27` |
| Result | `blocked-by-environment` |
| Evidence path | `docs/flutter-migration/feasibility-evidence.json` IDs: `ANDROID-DEBUG-BUILD-001`, `ANDROID-RELEASE-BUILD-001`, `ANDROID-RUNTIME-001`, `WINDOWS-ENV-001`, `DEVICE-ENV-001` |
| Sanitized error | Required hardware was unavailable: a real Windows host, HID scanner, Windows-installed 58mm and 80mm printers, and a standards-compliant LAN ESC/POS printer reachable from Windows and Android. No device address or print payload was captured. |
| Decision | status=defined; capabilities=DEVICE-SCAN-001,DEVICE-PRINT-001; action=hold current status until the Gate B physical-device matrix passes |

No per-store printer model adaptation is accepted as gate evidence. The live rerun must validate the generic system-print and LAN ESC/POS paths against standards-compliant equipment, including Chinese text, QR content, 58mm/80mm layouts, cut behavior where supported, timeouts, and recovery.

## Gate C — Web same-origin release behavior

| Field | Value |
| --- | --- |
| App commit | `cbae483b63723592252f3989df4e510f4da5e28b` |
| Flutter version | `3.47.0` |
| Platform version | Chrome 151.0.7922.174 on macOS 26.5.2; target HTTPS same-origin deployment unavailable |
| Test date | `2026-08-27` |
| Result | `blocked-by-environment` |
| Evidence path | `docs/flutter-migration/feasibility-evidence.json` IDs: `WEB-RELEASE-BUILD-001`, `WEB-RUNTIME-001`, `WEB-DEPLOY-ENV-001` |
| Sanitized error | No HTTPS same-origin deployment under `/shouyin-v2/` was available. The fresh localhost origin proves only fail-closed rendering and is insufficient for target routing, browser integration, or CORS evidence. |
| Decision | status=defined; capabilities=AUTH-TERM-001,AUTH-LOGIN-001,SYNC-CONNECT-001; action=hold current status until Gate A and Gate C both pass in the target deployment |

The rerun must verify refresh and deep links under `/shouyin-v2/`, browser back/forward navigation, Chinese IME, browser print, file download, unchanged CORS behavior, release initial load, the default JavaScript build, and that no COOP/COEP header change is required.

## Capability decision

All five capabilities remain `defined`. No generated coverage status changes are warranted because each live gate is blocked by missing environment evidence.

| Capability | Status | Reason |
| --- | --- | --- |
| `AUTH-TERM-001` | `defined` | Gate A lacks authorized live backend evidence on all required platforms. |
| `AUTH-LOGIN-001` | `defined` | Gate A lacks authorized live backend evidence on all required platforms. |
| `SYNC-CONNECT-001` | `defined` | Gate A lacks live WebSocket and recovery evidence on all required platforms. |
| `DEVICE-SCAN-001` | `defined` | Gate B lacks real Windows/Android scanner evidence. |
| `DEVICE-PRINT-001` | `defined` | Gate B lacks real Windows system-printer and Windows/Android LAN ESC/POS evidence. |

## Residual non-blocking build warnings

- `mobile_scanner` still emits a Kotlin Gradle Plugin future-migration warning; the current validated Android toolchain remains buildable.
- Android release output currently uses the debug signing key. A protected production release keystore must be configured outside source control before distribution.
