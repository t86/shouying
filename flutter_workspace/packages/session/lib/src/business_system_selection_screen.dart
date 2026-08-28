import 'package:flutter/material.dart';
import 'package:foundation/foundation.dart';
import 'package:session/src/business_system.dart';
import 'package:session/src/session_models.dart';

typedef BusinessSystemAuthorization = Future<Result<MachineSession>> Function(
  BusinessSystem system,
);

final class BusinessSystemSelectionScreen extends StatefulWidget {
  const BusinessSystemSelectionScreen({required this.authorize, super.key});

  static const Key bookingKey = Key('business-system-booking');
  static const Key orderKey = Key('business-system-order');
  static const Key cashierKey = Key('business-system-cashier');

  final BusinessSystemAuthorization authorize;

  @override
  State<BusinessSystemSelectionScreen> createState() =>
      _BusinessSystemSelectionScreenState();
}

final class _BusinessSystemSelectionScreenState
    extends State<BusinessSystemSelectionScreen> {
  BusinessSystem? _authorizing;
  AppFailure? _failure;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      '选择登录系统',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text('终端授权将按所选系统自动完成'),
                    const SizedBox(height: 24),
                    for (final system in BusinessSystem.values) ...<Widget>[
                      FilledButton(
                        key: _keyFor(system),
                        onPressed: _authorizing == null
                            ? () => _authorize(system)
                            : null,
                        child: Text(
                          _authorizing == system
                              ? '${system.label}授权中…'
                              : system.label,
                        ),
                      ),
                      if (system != BusinessSystem.values.last)
                        const SizedBox(height: 12),
                    ],
                    if (_failure case final failure?) ...<Widget>[
                      const SizedBox(height: 16),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          failure.safeMessage,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _authorize(BusinessSystem system) async {
    if (_authorizing != null) return;
    setState(() {
      _authorizing = system;
      _failure = null;
    });
    final result = await widget.authorize(system);
    if (!mounted) return;
    setState(() {
      _authorizing = null;
      _failure = result.failureOrNull;
    });
  }

  static Key _keyFor(BusinessSystem system) => switch (system) {
    BusinessSystem.booking => BusinessSystemSelectionScreen.bookingKey,
    BusinessSystem.order => BusinessSystemSelectionScreen.orderKey,
    BusinessSystem.cashier => BusinessSystemSelectionScreen.cashierKey,
  };
}
