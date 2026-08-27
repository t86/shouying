# Flutter migration ledgers

These ledgers are the Stage 0 control plane for the Vue-to-Flutter migration. `capabilities.json`, `protocols.json`, and `permissions.json` are authoritative, machine-readable records. `generated/source-inventory.json` is the deterministic static inventory, and `generated/coverage.md` is a generated review view.

## Capability lifecycle

Capability status advances only with evidence:

`discovered` -> `defined` -> `implemented` -> `protocol-equal` -> `permission-equal` -> `exception-equal` -> `platform-verified` -> `accepted`

Each advancement records the old source reference, Flutter implementation path, relevant automated tests, platform evidence, and (for acceptance) business-owner acceptance. Platform scopes mean: `required` is supported and release-blocking; `degraded` is supported with documented limitations; `approved` is explicitly accepted as sufficient for that platform; `out-of-scope` is intentionally not delivered on that platform.

Static inventory records observable routes, APIs, and cues. It does not replace manual business review of workflows, edge cases, device behavior, or acceptance evidence.

Never place passwords, `tk`/`stk`, machine codes, payment codes, member PII, or raw production payloads in a ledger or generated artifact. Use type/shape descriptions and sanitized placeholders.

When a Vue route, API, permission, or key behavior changes, update every affected capability row and regenerate the report.

## Commands

From the repository root:

```sh
node tools/flutter_migration_inventory/validate_ledgers.js
node tools/flutter_migration_inventory/source_inventory.js
node tools/flutter_migration_inventory/generate_report.js
```

Validation must pass before report generation. The report is deterministic and may be regenerated at any time.

## Reproducible foundation checks

The Flutter workspace is pinned to Flutter 3.47.0 through `.fvmrc`. Install FVM 4.3.0 and ensure Node.js is available before running the local gates. The scripts locate the repository from their own file path, so the caller's current directory does not matter.

On macOS or Linux:

```sh
/path/to/repository/flutter_workspace/tool/check.sh
```

This validates the lockfile, migration inventory and ledgers, deterministic generated files, package boundaries, formatting, analysis, and all tests before building the Web release and Android release APK. Build outputs are written to `flutter_workspace/apps/web_app/build/web/` and `flutter_workspace/apps/android_app/build/app/outputs/flutter-apk/app-release.apk`.

On a Windows host with Flutter desktop prerequisites installed:

```powershell
& C:\path\to\repository\flutter_workspace\tool\check.ps1
```

The Windows gate performs the same validation sequence and produces `flutter_workspace/apps/windows_app/build/windows/x64/runner/Release/`. Both scripts stop at the first failed command and do not print environment variables.

GitLab CI has four jobs across `validate`, `build`, and `windows`: `migration-ledger`, `flutter-test`, `flutter-web-android`, and `flutter-windows`. Linux jobs use a digest-pinned Flutter 3.44.0 image only as the bootstrap toolchain; FVM installs and verifies the required Flutter 3.47.0 SDK before any job commands run. The Windows job requires a runner tagged `windows` with Dart, Node.js, Visual Studio desktop tooling, and either PowerShell 7 (`pwsh`) or Windows PowerShell available. Pub and FVM downloads are cached, while application build directories are never cached. Platform artifacts expire after seven days.

Ordinary CI deliberately supplies no live backend URLs, credentials, terminal identifiers, or device secrets. Live backend and hardware feasibility evidence belongs only in the separately controlled feasibility-gate process.
