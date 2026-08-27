import 'package:flutter/material.dart';
import 'package:foundation/foundation.dart';

final class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({required this.phase, super.key});

  final ConnectionPhase phase;

  @override
  Widget build(BuildContext context) {
    if (phase == ConnectionPhase.online) return const SizedBox.shrink();

    final (message, background, foreground) = switch (phase) {
      ConnectionPhase.blocked => (
        '服务连接不可用，写入操作已暂停',
        const Color(0xFFB3261E),
        Colors.white,
      ),
      ConnectionPhase.reconciling => (
        '正在恢复服务端状态',
        const Color(0xFFFFB300),
        const Color(0xFF2A2100),
      ),
      ConnectionPhase.online => throw StateError('online banner is hidden'),
    };

    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: ColoredBox(
        color: background,
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: ExcludeSemantics(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
