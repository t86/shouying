import 'dart:async';

import 'package:card_table/src/super_admin_loader.dart';
import 'package:card_table/src/super_admin_models.dart';
import 'package:flutter/material.dart';
import 'package:foundation/foundation.dart';

/// S9.P3 终端设备授权注册界面 (/register)
class TerminalRegisterScreen extends StatefulWidget {
  const TerminalRegisterScreen({
    required this.loader,
    required this.onRegisterSuccess,
    this.machineCode = '',
    this.loadMachineCode,
    this.completeRegistration,
    this.onBack,
    super.key,
  });

  final SuperAdminLoader loader;
  final ValueChanged<TerminalRegisterResult> onRegisterSuccess;
  final String machineCode;
  final Future<Result<String>> Function()? loadMachineCode;
  final Future<Result<void>> Function(
    TerminalRegisterResult,
    String,
    bool Function(),
  )?
  completeRegistration;
  final VoidCallback? onBack;

  @override
  State<TerminalRegisterScreen> createState() => _TerminalRegisterScreenState();
}

class _TerminalRegisterScreenState extends State<TerminalRegisterScreen> {
  final TextEditingController _codeCtrl = TextEditingController();
  bool _isLoading = false;
  bool _closed = false;
  int _attempt = 0;
  String? _errorMessage;
  String _loadedMachineCode = '';
  bool _loadingMachine = false;
  TerminalRegisterResult? _registered;
  String get _machineCode =>
      widget.machineCode.isNotEmpty ? widget.machineCode : _loadedMachineCode;
  bool _current(int attempt) => mounted && !_closed && attempt == _attempt;

  @override
  void initState() {
    super.initState();
    if (widget.machineCode.isEmpty && widget.loadMachineCode != null) {
      unawaited(Future<void>.microtask(_loadMachineCode));
    }
  }

  Future<void> _loadMachineCode() async {
    final load = widget.loadMachineCode;
    if (_closed || _loadingMachine || load == null) return;
    final attempt = ++_attempt;
    setState(() {
      _loadingMachine = true;
      _errorMessage = null;
    });
    try {
      final result = await load();
      if (!_current(attempt)) return;
      setState(() {
        _loadedMachineCode = result.valueOrNull ?? '';
        _errorMessage = result.failureOrNull?.safeMessage;
      });
    } on Object {
      if (_current(attempt)) setState(() => _errorMessage = '无法获取本机标识，请重试');
    } finally {
      if (_current(attempt)) setState(() => _loadingMachine = false);
    }
  }

  @override
  void dispose() {
    _closed = true;
    _attempt++;
    _codeCtrl.dispose();
    super.dispose();
  }

  void _onKeyPress(String key) {
    if (_closed || _isLoading) return;
    setState(() {
      _errorMessage = null;
      if (key == 'clear') {
        _codeCtrl.clear();
      } else if (key == 'backspace') {
        final text = _codeCtrl.text;
        if (text.isNotEmpty) {
          _codeCtrl.text = text.substring(0, text.length - 1);
        }
      } else {
        _codeCtrl.text += key;
      }
    });
  }

  Future<void> _submit() async {
    if (_closed || _isLoading || _loadingMachine) return;
    if (_machineCode.trim().isEmpty) {
      setState(() => _errorMessage = '当前设备未提供机器码，不能注册');
      return;
    }
    final code = _codeCtrl.text.trim();
    if (code.isEmpty && _registered == null) {
      setState(() => _errorMessage = '请输入授权快捷码');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _codeCtrl.clear();
    final attempt = ++_attempt;
    final machineCode = _machineCode;
    Result<TerminalRegisterResult> res;
    try {
      res = _registered == null
          ? await widget.loader.registerTerminal(
              authCode: code,
              machineCode: machineCode,
              canDispatch: () =>
                  _current(attempt) && _machineCode == machineCode,
            )
          : Success(_registered!);
    } on Object {
      res = const FailureResult(
        AppFailure(
          kind: FailureKind.unknown,
          code: 'terminal.register_failed',
          safeMessage: '注册失败，请核实终端状态后重试',
        ),
      );
    }

    if (!mounted || _closed || attempt != _attempt) return;

    switch (res) {
      case Success(:final value):
        _registered = value;
        final complete = widget.completeRegistration;
        if (complete != null) {
          Result<void> completion;
          try {
            completion = await complete(
              value,
              machineCode,
              () => _current(attempt) && _machineCode == machineCode,
            );
          } on Object {
            completion = const FailureResult(
              AppFailure(
                kind: FailureKind.unknown,
                code: 'terminal.authorization_failed',
                safeMessage: '注册已成功，后续授权未完成，请重试',
              ),
            );
          }
          if (!_current(attempt)) return;
          if (completion.failureOrNull case final failure?) {
            setState(() {
              _isLoading = false;
              _errorMessage = '注册已成功：${failure.safeMessage}';
            });
            return;
          }
        }
        if (!_current(attempt)) return;
        setState(() => _isLoading = false);
        widget.onRegisterSuccess(value);
      case FailureResult(:final failure):
        setState(() {
          _isLoading = false;
          _errorMessage = failure.safeMessage;
        });
    }
  }

  void _back() {
    _closed = true;
    _attempt++;
    _codeCtrl.clear();
    widget.onBack?.call();
  }

  @override
  void didUpdateWidget(TerminalRegisterScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.loader, widget.loader) ||
        oldWidget.machineCode != widget.machineCode) {
      _attempt++;
      _isLoading = false;
      _codeCtrl.clear();
      _registered = null;
      _loadedMachineCode = '';
      _loadingMachine = false;
      if (widget.machineCode.isEmpty && widget.loadMachineCode != null) {
        unawaited(Future<void>.microtask(_loadMachineCode));
      }
    }
  }

  Widget _buildKeypadButton(
    String label, {
    String? keyId,
    VoidCallback? onTap,
    Color? color,
    Color? textColor,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        key: ValueKey('keypad-${keyId ?? label}'),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              color ?? Theme.of(context).colorScheme.surfaceContainerHighest,
          foregroundColor: textColor ?? Theme.of(context).colorScheme.onSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        onPressed: _isLoading || _closed ? null : onTap,
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope<void>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _closed = true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.phonelink_setup,
                                color: theme.colorScheme.primary,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '终端设备授权注册',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '检测到设备未授权，请输入快捷码',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.onBack != null)
                              IconButton(
                                onPressed: _back,
                                icon: const Icon(Icons.close),
                                tooltip: '返回',
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.perm_device_information,
                                size: 18,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '机器码: ${_loadingMachine
                                      ? '获取中…'
                                      : _machineCode.isEmpty
                                      ? '未获取'
                                      : _machineCode}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _codeCtrl,
                          enabled: !_isLoading && !_closed,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            labelText: '请输入注册快捷码',
                            prefixIcon: const Icon(Icons.pin),
                            border: const OutlineInputBorder(),
                            errorText: _errorMessage,
                          ),
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 20),
                        // 软键盘
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.9,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            for (int i = 1; i <= 9; i++)
                              _buildKeypadButton(
                                '$i',
                                onTap: () => _onKeyPress('$i'),
                              ),
                            _buildKeypadButton(
                              '清空',
                              keyId: 'clear',
                              onTap: () => _onKeyPress('clear'),
                              color: theme.colorScheme.errorContainer
                                  .withValues(alpha: 0.5),
                              textColor: theme.colorScheme.onErrorContainer,
                            ),
                            _buildKeypadButton(
                              '0',
                              onTap: () => _onKeyPress('0'),
                            ),
                            _buildKeypadButton(
                              '⌫',
                              keyId: 'backspace',
                              onTap: () => _onKeyPress('backspace'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: _isLoading || _loadingMachine
                                ? null
                                : _submit,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _registered == null ? '提交注册' : '重试终端授权',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                        if (widget.onBack != null) ...[
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _back,
                            child: const Text('返回登录'),
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
      ),
    );
  }
}
