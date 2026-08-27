import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:foundation/foundation.dart';

final class DiagnosticPanel extends StatelessWidget {
  const DiagnosticPanel({
    required this.appVersion,
    required this.platformLabel,
    required this.phase,
    required this.apiBase,
    required this.onlineBase,
    required this.websocketBase,
    this.machineId,
    this.machineName,
    this.userId,
    this.userName,
    this.lastFailure,
    this.onWriteCommand,
    super.key,
  });

  static const double wideBreakpoint = 900;
  static const Key wideLayoutKey = Key('diagnostic-wide-layout');
  static const Key narrowLayoutKey = Key('diagnostic-narrow-layout');
  static const Key writeCommandKey = Key('diagnostic-write-command');

  final String appVersion;
  final String platformLabel;
  final ConnectionPhase phase;
  final String? machineId;
  final String? machineName;
  final String? userId;
  final String? userName;
  final Uri apiBase;
  final Uri onlineBase;
  final Uri websocketBase;
  final AppFailure? lastFailure;
  final VoidCallback? onWriteCommand;

  @override
  Widget build(BuildContext context) {
    final environment = _DiagnosticSection(
      title: '运行环境',
      rows: <(String, String)>[
        ('应用版本', _safeValue(appVersion)),
        ('平台', _safeValue(platformLabel)),
        ('连接阶段', phase.name),
        ('API', _safeEndpoint(apiBase)),
        ('在线服务', _safeEndpoint(onlineBase)),
        ('实时服务', _safeEndpoint(websocketBase)),
      ],
    );
    final session = _DiagnosticSection(
      title: '会话',
      rows: <(String, String)>[
        ('终端 ID', _safeValue(machineId)),
        ('终端名称', _safeValue(machineName)),
        ('员工 ID', _safeValue(userId)),
        ('员工名称', _safeValue(userName)),
      ],
    );
    final failure = lastFailure;
    final status = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _DiagnosticSection(
          title: '最近状态',
          rows: <(String, String)>[
            ('失败代码', _safeFailureCode(failure?.code)),
            ('安全消息', _safeFailureMessage(failure?.safeMessage)),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: writeCommandKey,
          onPressed: phase.allowsWrites ? onWriteCommand : null,
          child: const Text('执行写入检查'),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final children = <Widget>[environment, session, status];
        if (constraints.maxWidth >= wideBreakpoint) {
          return SingleChildScrollView(
            child: Row(
              key: wideLayoutKey,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: environment),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      session,
                      const SizedBox(height: 20),
                      status,
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          child: Column(
            key: narrowLayoutKey,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (var index = 0; index < children.length; index++) ...<Widget>[
                children[index],
                if (index != children.length - 1) const SizedBox(height: 16),
              ],
            ],
          ),
        );
      },
    );
  }

  static String _safeEndpoint(Uri endpoint) {
    if (!endpoint.hasScheme || endpoint.host.isEmpty) return '不可用';
    return Uri(
      scheme: endpoint.scheme,
      host: endpoint.host,
      port: endpoint.hasPort ? endpoint.port : null,
      path: endpoint.path,
    ).toString();
  }

  static String _safeFailureCode(String? value) {
    if (value == null || !RegExp(r'^[a-z0-9._-]{1,128}$').hasMatch(value)) {
      return '无';
    }
    return value;
  }

  static String _safeFailureMessage(String? value) {
    if (value == null || value.isEmpty) return '无';
    if (_sensitiveMarker.hasMatch(value)) return '诊断信息已隐藏';
    final redacted = Redactor.redact(value);
    try {
      final decoded = jsonDecode(redacted);
      if (decoded is String && decoded.length <= 256) return decoded;
    } on FormatException {
      // Fall through to the fixed safe value.
    }
    return '诊断信息已隐藏';
  }

  static String _safeValue(String? value) {
    if (value == null || value.trim().isEmpty) return '无';
    if (value.length > 256 || _sensitiveMarker.hasMatch(value)) {
      return '诊断信息已隐藏';
    }
    final redacted = Redactor.redact(value);
    try {
      final decoded = jsonDecode(redacted);
      if (decoded is String) return decoded;
    } on FormatException {
      // Fall through to the fixed safe value.
    }
    return '诊断信息已隐藏';
  }

  static final RegExp _sensitiveMarker = RegExp(
    r'\b(?:tk|stk|token|password|passwd|secret|authorization|request\s*body)\b|请求体|密码|凭据|令牌',
    caseSensitive: false,
  );
}

final class _DiagnosticSection extends StatelessWidget {
  const _DiagnosticSection({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(width: 88, child: Text(label)),
                  Expanded(child: SelectableText(value)),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
