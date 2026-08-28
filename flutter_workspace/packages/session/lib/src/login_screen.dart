import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation/foundation.dart';
import 'package:session/src/login_view_model.dart';
import 'package:session/src/session_models.dart';

final class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({this.connectionPhase = ConnectionPhase.online, super.key});

  static const Key machineCodeFieldKey = Key('login-machine-code-field');
  static const Key machineSubmitKey = Key('login-machine-submit');
  static const Key machineFieldsKey = Key('login-machine-fields');
  static const Key accountFieldKey = Key('login-account-field');
  static const Key passwordFieldKey = Key('login-password-field');
  static const Key loginSubmitKey = Key('login-submit');
  static const Key employeeFieldsKey = Key('login-employee-fields');

  final ConnectionPhase connectionPhase;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

final class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _machineCodeController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();

  String? _machineCodeError;
  String? _accountError;
  String? _passwordError;

  @override
  void dispose() {
    _machineCodeController.dispose();
    _accountController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginViewModelProvider);
    final isBusy =
        loginState.phase == LoginPhase.authorizingMachine ||
        loginState.phase == LoginPhase.loggingIn;
    final needsMachine = loginState.stablePhase == LoginPhase.idle;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            ConnectionBanner(phase: widget.connectionPhase),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              needsMachine ? '终端授权' : '员工登录',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 20),
                            if (needsMachine)
                              _machineAuthorizationFields(isBusy)
                            else if (loginState.stablePhase ==
                                LoginPhase.authenticated)
                              const Text('登录成功')
                            else
                              _employeeLoginFields(isBusy),
                            if (loginState.phase == LoginPhase.failure &&
                                loginState.failure != null) ...<Widget>[
                              const SizedBox(height: 16),
                              Semantics(
                                liveRegion: true,
                                child: Text(
                                  loginState.failure!.safeMessage,
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
          ],
        ),
      ),
    );
  }

  Widget _machineAuthorizationFields(bool isBusy) => Column(
    key: LoginScreen.machineFieldsKey,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      TextField(
        key: LoginScreen.machineCodeFieldKey,
        controller: _machineCodeController,
        enabled: !isBusy,
        autocorrect: false,
        enableSuggestions: false,
        textInputAction: TextInputAction.done,
        onSubmitted: isBusy ? null : (_) => _submitMachineCode(),
        decoration: InputDecoration(
          labelText: '终端授权码',
          errorText: _machineCodeError,
        ),
      ),
      const SizedBox(height: 16),
      FilledButton(
        key: LoginScreen.machineSubmitKey,
        onPressed: isBusy ? null : _submitMachineCode,
        child: Text(isBusy ? '授权中…' : '授权终端'),
      ),
    ],
  );

  Widget _employeeLoginFields(bool isBusy) => Column(
    key: LoginScreen.employeeFieldsKey,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      TextField(
        key: LoginScreen.accountFieldKey,
        controller: _accountController,
        enabled: !isBusy,
        autocorrect: false,
        enableSuggestions: false,
        autofillHints: const <String>[AutofillHints.username],
        textInputAction: TextInputAction.next,
        onSubmitted: isBusy ? null : (_) => _passwordFocus.requestFocus(),
        decoration: InputDecoration(
          labelText: '员工账号',
          errorText: _accountError,
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        key: LoginScreen.passwordFieldKey,
        controller: _passwordController,
        focusNode: _passwordFocus,
        enabled: !isBusy,
        obscureText: true,
        autocorrect: false,
        enableSuggestions: false,
        autofillHints: const <String>[AutofillHints.password],
        textInputAction: TextInputAction.done,
        onSubmitted: isBusy ? null : (_) => _submitLogin(),
        decoration: InputDecoration(labelText: '密码', errorText: _passwordError),
      ),
      const SizedBox(height: 16),
      FilledButton(
        key: LoginScreen.loginSubmitKey,
        onPressed: isBusy ? null : _submitLogin,
        child: Text(isBusy ? '登录中…' : '登录'),
      ),
    ],
  );

  Future<void> _submitMachineCode() async {
    final code = _machineCodeController.text.trim();
    if (code.isEmpty) {
      setState(() => _machineCodeError = '请输入终端授权码');
      return;
    }
    setState(() => _machineCodeError = null);
    _machineCodeController.clear();
    await ref.read(loginViewModelProvider.notifier).authorizeMachine(code);
  }

  Future<void> _submitLogin() async {
    final account = _accountController.text.trim();
    final password = _passwordController.text;
    final accountError = account.isEmpty ? '请输入员工账号' : null;
    final passwordError = password.trim().isEmpty ? '请输入密码' : null;
    if (accountError != null || passwordError != null) {
      setState(() {
        _accountError = accountError;
        _passwordError = passwordError;
      });
      return;
    }
    setState(() {
      _accountError = null;
      _passwordError = null;
    });
    _passwordController.clear();
    await ref
        .read(loginViewModelProvider.notifier)
        .login(
          account: account,
          password: password,
          type: EmployeeLoginType.account,
        );
  }
}
