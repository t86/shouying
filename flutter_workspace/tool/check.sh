#!/bin/sh
set -eu
(set -o pipefail) 2>/dev/null && set -o pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
WORKSPACE_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
REPO_ROOT=$(CDPATH= cd -- "$WORKSPACE_ROOT/.." && pwd)

(
  cd "$WORKSPACE_ROOT"
  fvm dart pub get --enforce-lockfile
)

(
  cd "$REPO_ROOT"
  node --test \
    "$REPO_ROOT/tests/flutterMigrationInventory.test.js" \
    "$REPO_ROOT/tests/flutterWorkspaceStructure.test.js" \
    "$REPO_ROOT/tests/flutterCiChecks.test.js" \
    "$REPO_ROOT/tests/flutterFeasibilityReport.test.js" \
    "$REPO_ROOT/tests/flutterWebDevProxy.test.js"
)

(
  cd "$REPO_ROOT"
  node "$REPO_ROOT/tools/flutter_migration_inventory/validate_ledgers.js"
  node "$REPO_ROOT/tools/flutter_migration_inventory/source_inventory.js"
  node "$REPO_ROOT/tools/flutter_migration_inventory/generate_report.js"
  git diff --exit-code -- \
    migration/flutter/generated/source-inventory.json \
    migration/flutter/generated/coverage.md
)

(
  cd "$WORKSPACE_ROOT"
  node --test "$WORKSPACE_ROOT/tool/verify_boundaries.test.js"
  node "$WORKSPACE_ROOT/tool/verify_boundaries.js" "$WORKSPACE_ROOT"
  fvm dart format --output=none --set-exit-if-changed .
  fvm dart analyze
  # Package assets are bundled relative to each member's pubspec.
  for member in packages/* apps/*; do
    [ -d "$member/test" ] || continue
    (cd "$member" && fvm flutter test --no-pub)
  done
)

BUILD_STATE_BEFORE=$(
  cd "$REPO_ROOT"
  node "$WORKSPACE_ROOT/tool/snapshot_migration_state.js"
)

(
  cd "$WORKSPACE_ROOT/apps/web_app"
  fvm flutter build web --release
)

(
  cd "$WORKSPACE_ROOT/apps/android_app"
  fvm flutter build apk --release
)

BUILD_STATE_AFTER=$(
  cd "$REPO_ROOT"
  node "$WORKSPACE_ROOT/tool/snapshot_migration_state.js"
)

if [ "$BUILD_STATE_BEFORE" != "$BUILD_STATE_AFTER" ]; then
  echo "Build changed scoped migration state." >&2
  exit 1
fi
