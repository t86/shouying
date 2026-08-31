import 'dart:async';

import 'package:card_table/src/legacy_card_table_store.dart';
import 'package:realtime_sync/realtime_sync.dart';

/// Session-owned card-table data. Late listeners receive a complete snapshot,
/// followed by live events. No event history or offline persistence is kept.
final class CardTableEventFeed {
  LegacyCardTableStore _store = LegacyCardTableStore();
  SyncEnvelope? _lastRejected;
  final _live = StreamController<SyncEnvelope>.broadcast(sync: true);

  late final Stream<SyncEnvelope> events = Stream<SyncEnvelope>.multi((sink) {
    final subscription = _live.stream.listen(
      sink.addSync,
      onError: sink.addErrorSync,
      onDone: sink.closeSync,
    );
    final snapshot = _store.replayEnvelope;
    if (snapshot != null) sink.addSync(snapshot);
    final rejected = _lastRejected;
    if (rejected != null) sink.addSync(rejected);
    sink.onCancel = subscription.cancel;
    sink.onPause = subscription.pause;
    sink.onResume = subscription.resume;
  }, isBroadcast: true);

  void add(SyncEnvelope event) {
    if (_live.isClosed) return;
    if (event.type == SyncEventType.data) {
      final result = _store.applyEnvelope(event);
      // Retain at most one transport-bounded rejection so late listeners can
      // render the same typed failure rather than waiting silently forever.
      _lastRejected = result.failureOrNull == null ? null : event;
    }
    _live.add(event);
  }

  void reset() {
    _store = LegacyCardTableStore();
    _lastRejected = null;
  }

  Future<void> close() async {
    reset();
    await _live.close();
  }
}
