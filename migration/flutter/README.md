# Flutter migration ledgers

These ledgers are the Stage 0 control plane for the Vue-to-Flutter migration. `capabilities.json`, `protocols.json`, and `permissions.json` are authoritative, machine-readable records. `generated/source-inventory.json` is the deterministic static inventory, and `generated/coverage.md` is a generated review view.

## Capability lifecycle

Capability status advances only with evidence:

`discovered` -> `defined` -> `implemented` -> `protocol-equal` -> `permission-equal` -> `exception-equal` -> `platform-verified` -> `accepted`

Each advancement records the old source reference, Flutter implementation path, relevant automated tests, platform evidence, and (for acceptance) business-owner acceptance. Platform scopes are `required`, `degraded`, `approved`, or `out-of-scope`.

Static inventory records observable routes, APIs, and cues. It does not replace manual business review of workflows, edge cases, device behavior, or acceptance evidence.

Never place passwords, `tk`/`stk`, machine codes, payment codes, member PII, or raw production payloads in a ledger or generated artifact. Use type/shape descriptions and sanitized placeholders.

When a Vue route, API, permission, or key behavior changes, update every affected capability row and regenerate the report.

## Commands

From the repository root:

```sh
node tools/flutter_migration_inventory/validate_ledgers.js
node tools/flutter_migration_inventory/generate_report.js
```

Validation must pass before report generation. The report is deterministic and may be regenerated at any time.
