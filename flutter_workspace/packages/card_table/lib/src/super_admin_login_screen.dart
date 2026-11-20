import 'dart:convert';

import 'package:card_table/src/super_admin_loader.dart';
import 'package:card_table/src/super_admin_models.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:foundation/foundation.dart';

/// S9.P2 超级管理员登录界面 (/appinfo)
class SuperAdminLoginScreen extends StatefulWidget {
  const SuperAdminLoginScreen({
    required this.loader,
    required this.onLoginSuccess,
    this.onBack,
    super.key,
  });

  final SuperAdminLoader loader;
  final ValueChanged<SuperAdminLoginResult> onLoginSuccess;
  final VoidCallback? onBack;

  @override
  State<SuperAdminLoginScreen> createState() => _SuperAdminLoginScreenState();
}

class _SuperAdminLoginScreenState extends State<SuperAdminLoginScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _closed = false;
  int _attempt = 0;
  String? _errorMessage;

  @override
  void dispose() {
    _closed = true;
    _attempt++;
    _passwordController.dispose();
    super.dispose();
  }

  void _onKeyPress(String key) {
    if (_closed || _isLoading) return;
    setState(() {
      _errorMessage = null;
      if (key == 'clear') {
        _passwordController.clear();
      } else if (key == 'backspace') {
        final text = _passwordController.text;
        if (text.isNotEmpty) {
          _passwordController.text = text.substring(0, text.length - 1);
        }
      } else {
        _passwordController.text += key;
      }
    });
  }

  Future<void> _submit() async {
    if (_closed || _isLoading) return;
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _errorMessage = '密码不能为空');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final attempt = ++_attempt;
    _passwordController.clear();
    final md5Password = md5
        .convert(utf8.encode(password))
        .toString()
        .toUpperCase();
    Result<SuperAdminLoginResult> res;
    final loader = widget.loader;
    bool current() =>
        mounted &&
        !_closed &&
        attempt == _attempt &&
        identical(loader, widget.loader);
    try {
      res = await loader.login(md5Password: md5Password, canDispatch: current);
    } on Object {
      res = const FailureResult(
        AppFailure(
          kind: FailureKind.unknown,
          code: 'super_admin.login_failed',
          safeMessage: '登录失败，请重试',
        ),
      );
    }

    if (!mounted || _closed || attempt != _attempt) return;

    setState(() => _isLoading = false);

    switch (res) {
      case Success(:final value):
        widget.onLoginSuccess(value);
      case FailureResult(:final failure):
        setState(() => _errorMessage = failure.safeMessage);
    }
  }

  void _back() {
    _closed = true;
    _attempt++;
    _passwordController.clear();
    widget.onBack?.call();
  }

  @override
  void didUpdateWidget(SuperAdminLoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.loader, widget.loader)) {
      _attempt++;
      _isLoading = false;
      _passwordController.clear();
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
      height: 56,
      child: ElevatedButton(
        key: ValueKey('keypad-${keyId ?? label}'),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              color ?? Theme.of(context).colorScheme.surfaceContainerHighest,
          foregroundColor: textColor ?? Theme.of(context).colorScheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        onPressed: _isLoading || _closed ? null : onTap,
        child: Text(
          label,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope<void>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _closed = true;
          _attempt++;
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1E293B),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: theme.colorScheme.surface,
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
                                Icons.admin_panel_settings,
                                color: theme.colorScheme.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '超级管理员登录',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '系统维护与超级权限中心',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
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
                        TextField(
                          controller: _passwordController,
                          enabled: !_isLoading && !_closed,
                          obscureText: true,
                          autofocus: true,
                          style: const TextStyle(
                            fontSize: 18,
                            letterSpacing: 2,
                          ),
                          decoration: InputDecoration(
                            labelText: '请输入超管密码',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                            errorText: _errorMessage,
                          ),
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 24),
                        // 虚拟数字软键盘
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.8,
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
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    '立即登录',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                        if (widget.onBack != null) ...[
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _back,
                            child: const Text('返回收银系统'),
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
