import 'package:card_table/src/management_permission_feed.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:realtime_sync/realtime_sync.dart';

SyncEnvelope full(int station) {
  final data = List<Object?>.filled(55, null);
  data[13] = [
    [station, 10, 1],
  ];
  data[41] = [
    [station, 25, 1],
  ];
  data[54] = [
    [1, 0],
  ];
  return SyncEnvelope.parse({'p': 1, 't': '20260920100000', 'd': data})
      .valueOrNull!;
}

void main() {
  test(
    'revision invalidates identity and permission changes, not unrelated data',
    () {
      final feed = ManagementPermissionFeed();
      addTearDown(feed.dispose);
      final initial = feed.revision;
      feed.start('9');
      expect(feed.revision, greaterThan(initial));
      feed.setPhase(ConnectionPhase.online);
      feed.add(full(9));
      final ready = feed.revision;
      feed.add(full(9));
      feed.add(
        SyncEnvelope.parse({
          'p': 1,
          't': '20260920100001',
          'd': {'2': []},
        }).valueOrNull!,
      );
      expect(feed.revision, ready);
      feed.add(
        SyncEnvelope.parse({
          'p': 1,
          't': '20260920100002',
          'd': {
            '41': [
              [9, 25, 0],
            ],
          },
        }).valueOrNull!,
      );
      expect(feed.revision, greaterThan(ready));
      final revoked = feed.revision;
      feed.add(full(9));
      expect(feed.revision, greaterThan(revoked));
      feed.reset();
      final reset = feed.revision;
      feed.reset();
      expect(feed.revision, greaterThan(reset));
    },
  );
  test(
    'session online survives absent or malformed metadata but not reset',
    () {
      final feed = ManagementPermissionFeed();
      addTearDown(feed.dispose);
      feed.setPhase(ConnectionPhase.online);
      expect(feed.value.sessionOnline, isFalse);
      feed.start('9');
      expect(feed.value.sessionOnline, isFalse);
      feed.setPhase(ConnectionPhase.online);
      expect(feed.value.sessionOnline, isTrue);
      expect(feed.value.snapshot.available, isFalse);
      feed.add(
        SyncEnvelope.parse({
          'p': 1,
          't': '20260920100000',
          'd': {
            '13': [
              [9],
            ],
          },
        }).valueOrNull!,
      );
      expect(feed.value.sessionOnline, isTrue);
      expect(feed.value.snapshot.available, isFalse);
      feed.setPhase(ConnectionPhase.reconciling);
      expect(feed.value.sessionOnline, isFalse);
      feed.reset();
      feed.setPhase(ConnectionPhase.online);
      expect(feed.value.sessionOnline, isFalse);
    },
  );
  test('full metadata before online becomes visible only when online', () {
    final feed = ManagementPermissionFeed()..start('9');
    addTearDown(feed.dispose);
    feed.add(full(9));
    expect(feed.value.snapshot.available, false);
    feed.setPhase(ConnectionPhase.online);
    expect(feed.value.snapshot.moduleIds, {25});
    expect(feed.value.safeModeEnabled, false);
  });
  test(
    'reconnect retains full baseline but applies revocation before online',
    () {
      final feed = ManagementPermissionFeed()
        ..start('9')
        ..setPhase(ConnectionPhase.online)
        ..add(full(9));
      addTearDown(feed.dispose);
      expect(feed.value.snapshot.available, true);
      feed.setPhase(ConnectionPhase.blocked);
      expect(feed.value.snapshot.available, false);
      feed.add(
        SyncEnvelope.parse({
          'p': 1,
          't': '20260920100001',
          'd': {
            '41': [
              [9, 25, 0],
            ],
          },
        }).valueOrNull!,
      );
      expect(feed.value.snapshot.available, false);
      feed.setPhase(ConnectionPhase.online);
      expect(feed.value.snapshot.available, true);
      expect(feed.value.snapshot.roleIds, {10});
      expect(feed.value.snapshot.moduleIds, isEmpty);
    },
  );
  test('increment-only reconnect cannot establish a missing full baseline', () {
    final feed = ManagementPermissionFeed()..start('9');
    addTearDown(feed.dispose);
    feed.setPhase(ConnectionPhase.reconciling);
    feed.add(
      SyncEnvelope.parse({
        'p': 1,
        't': '20260920100001',
        'd': {
          '13': [
            [9, 10, 1],
          ],
          '41': [
            [9, 25, 1],
          ],
          '54': [
            [1, 0],
          ],
        },
      }).valueOrNull!,
    );
    feed.setPhase(ConnectionPhase.online);
    expect(feed.value.snapshot.available, false);
  });
  test('bad metadata invalidates retained baseline across reconnection', () {
    final feed = ManagementPermissionFeed()
      ..start('9')
      ..add(full(9))
      ..setPhase(ConnectionPhase.online);
    addTearDown(feed.dispose);
    feed.setPhase(ConnectionPhase.reconciling);
    feed.add(
      SyncEnvelope.parse({
        'p': 1,
        't': '20260920100001',
        'd': {
          '13': [
            [9, 10],
          ],
        },
      }).valueOrNull!,
    );
    feed.add(
      SyncEnvelope.parse({
        'p': 1,
        't': '20260920100002',
        'd': {
          '13': [
            [9, 10, 1],
          ],
          '41': [
            [9, 25, 1],
          ],
        },
      }).valueOrNull!,
    );
    feed.setPhase(ConnectionPhase.online);
    expect(feed.value.snapshot.available, false);
    feed.add(full(9));
    expect(feed.value.snapshot.available, true);
  });
  test(
    'reconnect with no changes restores only the same validated baseline',
    () {
      final feed = ManagementPermissionFeed()
        ..start('9')
        ..add(full(9))
        ..setPhase(ConnectionPhase.online);
      addTearDown(feed.dispose);
      feed.setPhase(ConnectionPhase.reconciling);
      expect(feed.value.snapshot.available, false);
      feed.setPhase(ConnectionPhase.online);
      expect(feed.value.snapshot.moduleIds, {25});
      feed.start('8');
      feed.setPhase(ConnectionPhase.online);
      expect(feed.value.snapshot.available, false);
    },
  );
  test('logout and changed station never retain previous permissions', () {
    final feed = ManagementPermissionFeed()
      ..start('9')
      ..setPhase(ConnectionPhase.online)
      ..add(full(9));
    addTearDown(feed.dispose);
    expect(feed.value.snapshot.available, true);
    feed.reset();
    feed.add(full(9));
    expect(feed.value.snapshot.available, false);
    feed.start('8');
    feed.setPhase(ConnectionPhase.online);
    feed.add(full(9));
    expect(feed.value.snapshot.moduleIds, isEmpty);
  });
}
