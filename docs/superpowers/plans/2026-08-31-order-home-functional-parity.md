# 点单首页功能闭环 Implementation Plan

> For agentic workers: use TDD on public widget/API seams, parallel independent report implementation and region/integration work, then independent code review. Preserve earlier uncommitted migration work; no unrelated repository edits or commits.

**Goal:** Close the approved region-selection gap and deliver one real read-only home-page feature against the existing Web contract, rather than another placeholder.

**Architecture:** Keep authorized card data in LegacyCardTableStore. Add an explicit region overflow chooser using the same visible-region collection as the top bar. A separate minimum-consumption report API/DTO/widget consumes the existing ProtocolClient and a reactive canRead gate. Android/Web roots provide a session/connection-guarded loader; no backend or offline queue changes.

**Tech Stack:** Existing Flutter/Dart packages, ProtocolClient/Dio, flutter_test, Node source-contract checks. No new third-party packages.

## Scope approved by the user

User accepted restoring “其它区域/展开选择” then asked to continue the ordering homepage and prove 1:1 Web functionality. Source truth remains `src/views/Order/newOrderCard.vue`, not old orderCard. This batch does not claim that the whole home page or ordering/payment flow is finished.

## Task 1 — Region selection

Files: `card_table/lib/src/card_table_screen.dart`, new `card_table/lib/src/card_region_selector.dart`, existing `card_table/test/card_table_test.dart` (real parent/selector integration seam).

- [ ] Write a 412px widget test with more than ten authorized regions; click the visible “其它”/all-regions control, select a distant region, assert its cards and region counter appear.
- [ ] Run the test red before code changes. Add a fixed explicit chooser control (not the card-scroll arrows), list all authorized visible regions in source order, preserve 我的卡台/全部, highlight selection and allow close without changes.
- [ ] Test selecting a region clears the prior status filter, returning to 我的卡台 or 全部 works, unknown/deleted/unauthorized regions are not selectable, live metadata changes cannot preserve a stale selectable region, compact/wide layouts have no overflow.
- [ ] Keep the child selector stateless except popup/scroll lifecycle; parent owns filters and current validated snapshot. Reuse the same source-derived region list in both surfaces.

## Task 2 — Minimum-consumption report

Files: new `card_table/lib/src/minimum_consumption_report.dart`, `minimum_consumption_report_screen.dart`, tests of the same names; public exports in `card_table.dart` (parent owns exports).

- [ ] Verify actual routed import `newDrawerMinDetail.vue`. Test `POST /wo/get_seat_zy_csm_list` with no invented query/body, current order client headers, code=1 and data.records decoding. Observe red before implementing.
- [ ] DTO columns exactly: 序号; rn区域; sn卡台名称; o开台时间; sd订位人部门; se订位人; m最低消费; za主营金额; ga差额; p低消进度; t清台时间; mk标签. Preserve supplied amounts/progress/text; do not recompute business values. Missing/null optional cells render blank, missing/null records becomes empty if data is a valid object. Invalid nested/nonfinite/oversized data fails safely; do not echo raw server error bodies or records into logs.
- [ ] `ProtocolMinimumConsumptionReportApi(client: ProtocolClient).load(ClientKind)` returns `Future<Result<List<MinimumConsumptionReportRow>>>`; `typedef MinimumConsumptionLoader = Future<Result<List<MinimumConsumptionReportRow>>> Function()`.
- [ ] `MinimumConsumptionReportScreen(load: loader, canRead: ValueListenable<bool>)` queries on opening, renders a horizontally scrollable 12-column table, loading/empty/error/retry and close. No export button in this order-only surface, matching source.
- [ ] On canRead=false immediately invalidate pending request, clear loaded rows and show unavailable state. False→true must not let a previous request reappear; explicit retry obtains new data. Closing/reopening, overlapping retries and disposal must not apply stale futures. Page itself has no offline cache.

## Task 3 — Root wiring and source equivalence

Files: Android/Web main.dart, their lifecycle tests; card_table_screen.dart; Node `tests/flutterOrderHomeParity.test.js`.

Shared session guard and tests are in new `minimum_consumption_report_loader.dart` / `minimum_consumption_report_loader_test.dart`. Both roots also pass the existing raw connection stream to invalidate already-loaded rows even when UI phase updates coalesce.

- [ ] Add loader to ShellDependencies; default implementation validates active authenticated order client and online phase before request and checks same user identity/session generation/connection afterward.
- [ ] Only the order menu’s 低消进度统计表 dispatches to this screen; other systems retain their pending entry until their extra features (e.g. export) are implemented. Remove “待接入” only for the wired order entry.
- [ ] Parent canRead is true only for order + current identity + complete permission metadata + non-safe-mode + online connection. Invalidate on session/system changes and dispose. Popup/report lifecycle must not expose another user’s rows.
- [ ] Add a source-contract test comparing routed Vue table column labels/field order and API path with Dart definitions, plus app/widget tests that click the real menu, exercise the loader, close and return to the original card/filter state.

## Task 4 — Validation and delivery

- [ ] Run focused red→green tests, full workspace Flutter tests, analyze, Node source-contract tests and boundary verifier; fix reviewer findings before delivery.
- [ ] Build arm64 Android release with existing loopback config, preserve application data on install, refresh Flutter Web development build. Do not guess employee credentials.
- [ ] Record precisely what was verified (source, API fixture, UI, build/launch) and what still needs same-account live verification. Add/update local board tasks, never mark user acceptance on the user’s behalf.

## Public test examples

```dart
expect(captured.uri.path, '/server/wo/get_seat_zy_csm_list');
expect(captured.data, isNull);
expect(rows.single.cells, ['A区', 'A01', '20:00', '一部', '测试员工', '1000', '800', '200', '80%', '', '测试']);
// After a permission/connection change, loaded rows and any older pending response must remain hidden.
```

## Self-review

The batch has no business writes or new permission grants, no export invented for order mode, and no change to the original Web project. Platform runtime verification remains separate from widget tests. Region compatibility and report permissions are tested independently before app integration.
