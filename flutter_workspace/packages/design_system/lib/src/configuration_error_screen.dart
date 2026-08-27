import 'package:flutter/material.dart';

final class ConfigurationErrorScreen extends StatelessWidget {
  const ConfigurationErrorScreen({required this.missingKeys, super.key});

  final List<String> missingKeys;

  @override
  Widget build(BuildContext context) {
    final keys = missingKeys.toSet().toList()..sort();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Semantics(
                container: true,
                label: '应用配置不可用',
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '应用配置不可用',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        const Text('请联系部署管理员检查以下运行配置：'),
                        const SizedBox(height: 8),
                        for (final key in keys) Text('• $key'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
