# Source-Aligned Flutter Business Entry Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Flutter diagnostic landing flow with the Vue-compatible booking, ordering, and cashier entry flow backed by real terminal authorization, employee login, synchronization, and card-table data.

**Architecture:** Keep protocol/session/realtime modules as the transport foundation. Add a deep `card_table` module that owns legacy dataset normalization and the read-only first business screen. Web development system choice selects a server-side legacy terminal code; the browser receives only the resulting terminal session. Diagnostics remain a secondary route.

**Tech Stack:** Flutter 3.47, Riverpod 3, go_router, Dio, existing protocol/session/realtime modules, Node loopback proxy.

---

### Task 1: Lock the Vue entry contract

**Files:**
- Create: `tests/flutterBusinessEntryContract.test.js`
- Source: `src/views/Register/register.vue`
- Source: `src/views/Thelogin/Thelogin.vue`
- Source: `src/router/{book,order,money}/index.js`
- Source: `src/utils/config/card.js`

- [ ] Assert the three supported choices map to `book/am=2`, `order/am=4`, and `money/am=8`.
- [ ] Assert employee login sends the selected `client_name`.
- [ ] Assert post-login routes are `/cardMachine`, `/orderCard`, and `/moneyCard`.
- [ ] Assert datasets 0, 1, 14, and 18 mean regions, seats, business state, and business day.
- [ ] Run `node --test tests/flutterBusinessEntryContract.test.js`; first run must fail because no Flutter contract exists.

### Task 2: Make development system selection source-aligned

**Files:**
- Modify: `flutter_workspace/tool/web_dev_runner.js`
- Modify: `flutter_workspace/tool/web_dev_proxy.js`
- Modify: `tests/flutterWebDevProxy.test.js`
- Modify: `flutter_workspace/apps/web_app/lib/main.dart`
- Modify: `flutter_workspace/apps/web_app/test/lifecycle_test.dart`

- [ ] Replace the single `money` code resolver with a strict map for `book`, `order`, and `money` read from the Vue registration source.
- [ ] Accept only `loopback-development-{client_name}` placeholders at `/dev-api/server/term/auth`; substitute the matching code server-side.
- [ ] Add a pre-login three-choice screen. Selecting a choice performs real terminal authorization and only then reveals employee login.
- [ ] Keep the terminal code absent from Dart defines, browser JavaScript, logs, errors, and test snapshots.
- [ ] Verify Release and non-loopback environments cannot enable the selector.

### Task 3: Restore legacy post-login route dispatch

**Files:**
- Modify: `flutter_workspace/apps/web_app/lib/main.dart`
- Modify: `flutter_workspace/apps/web_app/test/lifecycle_test.dart`

- [ ] Map `ClientKind.booking/order/cashier` to `/cardMachine`, `/orderCard`, and `/moneyCard`.
- [ ] Redirect authenticated login and selection routes to the selected machine client's route.
- [ ] Keep `/diagnostics` and `/diagnostics/devices` accessible only as explicit auxiliary routes.
- [ ] Preserve a sanitized `returnTo` only for routes owned by the selected client.

### Task 4: Add a bounded full-sync channel

**Files:**
- Modify: `flutter_workspace/packages/realtime_sync/lib/src/sync_api.dart`
- Modify: `flutter_workspace/packages/realtime_sync/lib/src/sync_envelope.dart`
- Modify: `flutter_workspace/packages/realtime_sync/lib/src/realtime_controller.dart`
- Modify: `flutter_workspace/packages/realtime_sync/test/realtime_sync_test.dart`
- Modify: three app dependency implementations and lifecycle fakes.

- [ ] Use a separate sync-only `ProtocolClient` with a 64 MiB raw limit, depth 64, and one million nodes; session calls retain the strict 2 MiB default.
- [ ] Construct reconciliation envelopes from the already validated/frozen `SyncBatch` without applying the 2 MiB WebSocket-message budget.
- [ ] Expose a replaying `realtimeEvents` stream through `ShellDependencies`.
- [ ] Keep live WebSocket messages limited to 2 MiB and 10,000 nodes.

### Task 5: Implement the first card-table business module

**Files:**
- Create: `flutter_workspace/packages/card_table/**`
- Modify: `flutter_workspace/pubspec.yaml`
- Modify: app pubspec files and `pubspec.lock`
- Modify: `tests/flutterWorkspaceStructure.test.js`

- [ ] Define immutable region, table, business-day, snapshot, and failure models.
- [ ] Normalize full datasets 0/1/14/18 with exact Vue field indexes and safe numeric/string conversion.
- [ ] Apply incremental map updates for those datasets by their legacy identity fields.
- [ ] Filter inactive/deleted regions and seats and business statuses 22/33; sort regions by `dsp` and seats consistently.
- [ ] Render responsive region tabs, search, status filters, and read-only table cards for the selected client.
- [ ] Show reconciling, blocked, closed-business-day, empty, and protocol-failure states without inventing data.

### Task 6: Wire and verify the real browser flow

**Files:**
- Modify: `flutter_workspace/apps/web_app/lib/main.dart`
- Modify: Web lifecycle/browser tests and migration evidence.

- [ ] Start the loopback runner and verify each system selection authorizes the matching terminal type.
- [ ] Verify employee login sends the matching `client_name` and lands on the matching legacy route.
- [ ] Verify the first full sync renders real region/table data and no longer reports `protocol.response_too_large`.
- [ ] Run Node tests, workspace format/analyze/tests, Web release, Android release, boundary checks, and evidence hash validation.
- [ ] Commit each green slice separately and perform final Standards and Spec reviews.

## Explicit non-goals for this slice

- Card operations, reservation writes, order editing, payment, refund, and printing are not faked. They remain disabled until their source-aligned use cases are migrated.
- Local persisted employee data is not treated as authorization truth; refresh requires employee login until a compatible server validation contract exists.
- The diagnostic screen is retained for engineering support but is never a post-login default route.
