import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foundation/foundation.dart';

typedef ChangePasswordSubmit = Future<Result<void>> Function(
  String oldPassword,
  String newPassword,
);
typedef AuthPasswordEnabled = Future<Result<bool>> Function();
typedef AuthPasswordSubmit = Future<Result<void>> Function({
  required bool enabled,
  required String loginPassword,
  required String authPassword,
});

final class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({
    required this.submit,
    this.onChanged,
    this.requiresRelogin = true,
    this.darkTheme = false,
    super.key,
  });

  static const Key oldKey = Key('change-password-old');
  static const Key newKey = Key('change-password-new');
  static const Key confirmKey = Key('change-password-confirm');

  final ChangePasswordSubmit submit;
  final VoidCallback? onChanged;
  final bool requiresRelogin;
  final bool darkTheme;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

final class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _old = TextEditingController();
  final TextEditingController _next = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _busy = false;

  bool get _canSubmit =>
      _old.text.isNotEmpty &&
      _next.text.isNotEmpty &&
      _next.text == _confirm.text &&
      !_busy;

  @override
  void dispose() {
    _old.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 72),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    if (_old.text.isEmpty) {
      _show('请输入原密码');
      return;
    }
    if (_next.text.isEmpty) {
      _show('请输入新密码');
      return;
    }
    if (_next.text != _confirm.text) {
      _show('两次输入的新密码不一致！');
      return;
    }
    final route = ModalRoute.of(context);
    setState(() => _busy = true);
    Result<void> result;
    try {
      result = await widget.submit(_old.text, _next.text);
    } on Object {
      result = const FailureResult(
        AppFailure(
          kind: FailureKind.unknown,
          code: 'password.submit_failed',
          safeMessage: '密码修改失败，请重试',
        ),
      );
    }
    if (!mounted) return;
    if (route?.isCurrent != true) {
      _old.clear();
      _next.clear();
      _confirm.clear();
      setState(() => _busy = false);
      return;
    }
    if (result.failureOrNull != null) {
      setState(() => _busy = false);
      _show(result.failureOrNull!.safeMessage);
      return;
    }
    _old.clear();
    _next.clear();
    _confirm.clear();
    _show(widget.requiresRelogin ? '修改密码成功，请重新登录' : '成功修改密码');
    if (widget.requiresRelogin) {
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    if (!mounted || route?.isCurrent != true) return;
    final onChanged = widget.onChanged;
    final navigator = Navigator.of(context);
    // Close only our current route before a callback can replace navigation.
    if (navigator.canPop()) navigator.pop();
    onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.darkTheme;
    final theme = isDark
        ? BookingTheme.dark()
        : ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xff3373E8),
            ),
          );
    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: isDark ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '修改密码',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: isDark ? BookingTokens.textPrimary : null,
                ),
              ),
            ),
            if (isDark)
              IconButton(
                tooltip: '关闭',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(
                  Icons.close,
                  color: BookingTokens.textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          key: ChangePasswordScreen.oldKey,
          controller: _old,
          obscureText: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: '原密码',
            hintText: '请输入原密码',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          key: ChangePasswordScreen.newKey,
          controller: _next,
          obscureText: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: '新密码',
            hintText: '请输入新密码',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          key: ChangePasswordScreen.confirmKey,
          controller: _confirm,
          obscureText: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: '确认新密码',
            hintText: '请确认新密码',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => unawaited(_submit()),
        ),
        if (!isDark) const Spacer() else const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('取消'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _canSubmit ? () => unawaited(_submit()) : null,
              child: const Text('确认'),
            ),
          ],
        ),
      ],
    );
    return Theme(
      data: theme,
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.of(context).maybePop(),
          const SingleActivator(LogicalKeyboardKey.enter): () {
            if (_canSubmit) unawaited(_submit());
          },
          const SingleActivator(LogicalKeyboardKey.numpadEnter): () {
            if (_canSubmit) unawaited(_submit());
          },
        },
        child: Scaffold(
          backgroundColor: isDark
              ? BookingTokens.surfaceCanvas
              : const Color(0xffFAFAFC),
          body: SafeArea(
            child: isDark
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: BookingTokens.surfaceDialog,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0x6632B9FF),
                            ),
                            boxShadow: BookingTokens.drawerShadow,
                          ),
                          child: form,
                        ),
                      ),
                    ),
                  )
                : Padding(padding: const EdgeInsets.all(16), child: form),
          ),
        ),
      ),
    );
  }
}

final class AuthPasswordScreen extends StatefulWidget {
  const AuthPasswordScreen({
    required this.loadEnabled,
    required this.submit,
    super.key,
  });

  static const Key loginKey = Key('auth-password-login');
  static const Key authKey = Key('auth-password-auth');
  static const Key confirmKey = Key('auth-password-confirm');

  final AuthPasswordEnabled loadEnabled;
  final AuthPasswordSubmit submit;

  @override
  State<AuthPasswordScreen> createState() => _AuthPasswordScreenState();
}

final class _AuthPasswordScreenState extends State<AuthPasswordScreen> {
  final TextEditingController _login = TextEditingController();
  final TextEditingController _auth = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _enabled = false;
  bool _busy = false;
  bool _loading = true;
  bool _ready = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _login.dispose();
    _auth.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _ready = false;
      _loadError = null;
    });
    try {
      final result = await widget.loadEnabled();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = result.failureOrNull?.safeMessage;
        if (result.valueOrNull case final enabled?) {
          _enabled = enabled;
          _ready = true;
        }
      });
    } on Object {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = '读取授权密码状态失败，请重试';
        });
      }
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (_busy || !_ready) return;
    final owner = ModalRoute.of(context);
    if (_enabled) {
      if (_login.text.isEmpty || _auth.text.isEmpty) {
        _show('登录密码和授权密码不能为空');
        return;
      }
      if (_auth.text != _confirm.text) {
        _show('授权密码与确认授权密码不一致');
        return;
      }
      if (_auth.text == _login.text) {
        _show('授权密码不能与登录密码相同');
        return;
      }
      if (num.tryParse(_login.text)?.isNaN != false) {
        _show('授权密码必须为数字');
        return;
      }
      if (num.tryParse(_auth.text)?.isNaN != false) {
        _show('授权密码必须为数字');
        return;
      }
    }
    setState(() => _busy = true);
    final result = await widget.submit(
      enabled: _enabled,
      loginPassword: _login.text,
      authPassword: _auth.text,
    );
    if (!mounted || owner?.isActive == false) return;
    setState(() => _busy = false);
    if (result.failureOrNull != null) {
      _show(result.failureOrNull!.safeMessage);
      return;
    }
    _show('操作成功！');
    if (owner?.isCurrent == true) {
      owner!.navigator?.maybePop();
    } else if (owner?.isActive == true && !owner!.isFirst) {
      owner.navigator?.removeRoute(owner);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff3373E8)),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xffFAFAFC),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('授权密码', style: TextStyle(fontSize: 24)),
                if (_loading) const LinearProgressIndicator(),
                if (_loadError != null) ...[
                  Text(_loadError!, style: const TextStyle(color: Colors.red)),
                  TextButton(
                    onPressed: _loading ? null : _load,
                    child: const Text('重试'),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(child: Text('开启授权密码')),
                    Switch(
                      value: _enabled,
                      onChanged: _busy || !_ready
                          ? null
                          : (value) => setState(() => _enabled = value),
                    ),
                  ],
                ),
                if (_enabled) ...[
                  const SizedBox(height: 12),
                  TextField(
                    key: AuthPasswordScreen.loginKey,
                    controller: _login,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '登录密码',
                      hintText: '请输入登录密码',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: AuthPasswordScreen.authKey,
                    controller: _auth,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '授权密码',
                      hintText: '请输入授权密码',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: AuthPasswordScreen.confirmKey,
                    controller: _confirm,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '确认授权密码',
                      hintText: '请确认授权密码',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _busy || !_ready
                          ? null
                          : () => unawaited(_submit()),
                      child: const Text('确认'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
