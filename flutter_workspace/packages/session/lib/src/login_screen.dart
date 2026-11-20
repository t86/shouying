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
  final FocusNode _accountFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  String? _machineCodeError;
  String? _accountError;
  String? _passwordError;
  bool _obscurePassword = true;
  bool _showKeypad = false;
  bool _keypadTargetsPassword = false;

  @override
  void initState() {
    super.initState();
    _accountFocus.addListener(() {
      if (_accountFocus.hasFocus && _keypadTargetsPassword) {
        setState(() => _keypadTargetsPassword = false);
      }
    });
    _passwordFocus.addListener(() {
      if (_passwordFocus.hasFocus && !_keypadTargetsPassword) {
        setState(() => _keypadTargetsPassword = true);
      }
    });
  }

  @override
  void dispose() {
    _machineCodeController.dispose();
    _accountController.dispose();
    _passwordController.dispose();
    _accountFocus.dispose();
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
    final tier = BookingViewportTier.of(context);
    final wideSplit = !tier.isPhone && MediaQuery.sizeOf(context).width >= 860;

    return Scaffold(
      backgroundColor: BookingTokens.canvasLogin,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              BookingTokens.canvasLogin,
              BookingTokens.surfacePanelDark,
              BookingTokens.canvasPrimary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              ConnectionBanner(phase: widget.connectionPhase),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: tier.isPhone ? 16 : 32,
                      vertical: 20,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: wideSplit ? 920 : 440,
                      ),
                      child: wideSplit
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Expanded(child: _brandPanel(needsMachine)),
                                const SizedBox(width: 36),
                                SizedBox(
                                  width: 440,
                                  child: _loginCard(
                                    context,
                                    loginState: loginState,
                                    isBusy: isBusy,
                                    needsMachine: needsMachine,
                                  ),
                                ),
                              ],
                            )
                          : _loginCard(
                              context,
                              loginState: loginState,
                              isBusy: isBusy,
                              needsMachine: needsMachine,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _brandPanel(bool needsMachine) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: BookingTokens.brandPrimary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: BookingTokens.accentGlowBorder),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.event_seat_rounded,
              size: 16,
              color: BookingTokens.textIceBlue,
            ),
            SizedBox(width: 6),
            Text(
              '门店运营终端',
              style: TextStyle(
                color: BookingTokens.textIceBlue,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Text(
        needsMachine ? '终端设备授权' : '员工工号登录',
        style: const TextStyle(
          color: BookingTokens.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        needsMachine
            ? '当前设备尚未绑定营业终端，请输入授权码完成激活。'
            : '支持实时卡台同步、多日预留排班、开台管理与入客统计，请使用员工工号登录。',
        style: const TextStyle(
          color: BookingTokens.textMuted,
          fontSize: 14,
          height: 1.6,
        ),
      ),
      const SizedBox(height: 24),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: const <Widget>[
          _FeatureChip(
            icon: Icons.bolt_rounded,
            label: '实时房台同步',
            color: BookingTokens.statusReserved,
          ),
          _FeatureChip(
            icon: Icons.calendar_month_rounded,
            label: '多营业日预留',
            color: BookingTokens.statusOpened,
          ),
          _FeatureChip(
            icon: Icons.devices_rounded,
            label: '桌面 / 平板 / 手机自适应',
            color: BookingTokens.brandPrimaryLight,
          ),
        ],
      ),
    ],
  );

  Widget _loginCard(
    BuildContext context, {
    required LoginState loginState,
    required bool isBusy,
    required bool needsMachine,
  }) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: BookingTokens.surfaceLoginCard,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0x6632B9FF)),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x451A89FF),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: BookingTokens.brandPrimary.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: BookingTokens.accentGlowBorder),
              ),
              child: Icon(
                needsMachine ? Icons.verified_user_outlined : Icons.badge_outlined,
                color: BookingTokens.textIceBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                needsMachine ? '终端授权' : '员工登录',
                style: const TextStyle(
                  color: BookingTokens.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (!needsMachine &&
                loginState.stablePhase != LoginPhase.authenticated)
              TextButton.icon(
                onPressed: () => setState(() => _showKeypad = !_showKeypad),
                icon: Icon(
                  _showKeypad ? Icons.keyboard_hide : Icons.dialpad_rounded,
                  size: 16,
                ),
                label: Text(_showKeypad ? '收起键盘' : '数字键盘'),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (needsMachine)
          _machineAuthorizationFields(isBusy)
        else if (loginState.stablePhase == LoginPhase.authenticated)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.check_circle, color: BookingTokens.successGreen),
                SizedBox(width: 8),
                Text(
                  '登录成功',
                  style: TextStyle(
                    color: BookingTokens.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else
          _employeeLoginFields(isBusy),
        if (loginState.phase == LoginPhase.failure &&
            loginState.failure != null) ...<Widget>[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: BookingTokens.dangerRed.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: BookingTokens.dangerRed.withValues(alpha: 0.5),
              ),
            ),
            child: Semantics(
              liveRegion: true,
              child: Text(
                loginState.failure!.safeMessage,
                style: const TextStyle(
                  color: Color(0xFFFF8FA3),
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );

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
        style: const TextStyle(color: BookingTokens.textPrimary),
        textInputAction: TextInputAction.done,
        onSubmitted: isBusy ? null : (_) => _submitMachineCode(),
        decoration: InputDecoration(
          labelText: '终端授权码',
          hintText: '请输入终端授权快捷码',
          prefixIcon: const Icon(Icons.key_outlined),
          errorText: _machineCodeError,
        ),
      ),
      const SizedBox(height: 18),
      SizedBox(
        height: 46,
        child: FilledButton(
          key: LoginScreen.machineSubmitKey,
          style: FilledButton.styleFrom(
            backgroundColor: BookingTokens.brandPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(23),
            ),
          ),
          onPressed: isBusy ? null : _submitMachineCode,
          child: Text(
            isBusy ? '授权中…' : '授权终端',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
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
        focusNode: _accountFocus,
        enabled: !isBusy,
        autocorrect: false,
        enableSuggestions: false,
        style: const TextStyle(color: BookingTokens.textPrimary),
        autofillHints: const <String>[AutofillHints.username],
        textInputAction: TextInputAction.next,
        onSubmitted: isBusy ? null : (_) => _passwordFocus.requestFocus(),
        decoration: InputDecoration(
          labelText: '员工账号',
          hintText: '请输入员工工号',
          prefixIcon: const Icon(Icons.person_outline_rounded),
          errorText: _accountError,
        ),
      ),
      const SizedBox(height: 14),
      TextField(
        key: LoginScreen.passwordFieldKey,
        controller: _passwordController,
        focusNode: _passwordFocus,
        enabled: !isBusy,
        obscureText: _obscurePassword,
        autocorrect: false,
        enableSuggestions: false,
        style: const TextStyle(color: BookingTokens.textPrimary),
        autofillHints: const <String>[AutofillHints.password],
        textInputAction: TextInputAction.done,
        onSubmitted: isBusy ? null : (_) => _submitLogin(),
        decoration: InputDecoration(
          labelText: '密码',
          hintText: '请输入登录密码',
          prefixIcon: const Icon(Icons.lock_outline_rounded),
          suffixIcon: IconButton(
            tooltip: _obscurePassword ? '显示密码' : '隐藏密码',
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 18,
            ),
          ),
          errorText: _passwordError,
        ),
      ),
      if (_showKeypad) ...<Widget>[
        const SizedBox(height: 14),
        _numericKeypad(isBusy),
      ],
      const SizedBox(height: 18),
      SizedBox(
        height: 46,
        child: FilledButton(
          key: LoginScreen.loginSubmitKey,
          style: FilledButton.styleFrom(
            backgroundColor: BookingTokens.brandPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(23),
            ),
          ),
          onPressed: isBusy ? null : _submitLogin,
          child: Text(
            isBusy ? '登录中…' : '登录',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    ],
  );

  Widget _numericKeypad(bool isBusy) {
    const keys = <String>[
      '1', '2', '3',
      '4', '5', '6',
      '7', '8', '9',
      '清空', '0', '回退',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            _keypadTargetsPassword ? '当前输入：密码' : '当前输入：员工工号',
            style: const TextStyle(
              color: BookingTokens.textIceBlue,
              fontSize: 12,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: keys.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            mainAxisExtent: 42,
          ),
          itemBuilder: (context, index) {
            final label = keys[index];
            final isControl = label == '清空' || label == '回退';
            return Material(
              color: isControl
                  ? BookingTokens.brandSecondary
                  : BookingTokens.surfaceHeader,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: isBusy ? null : () => _onKeypadTap(label),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: BookingTokens.tableBorder),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: BookingTokens.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _onKeypadTap(String key) {
    final target = _keypadTargetsPassword
        ? _passwordController
        : _accountController;
    setState(() {
      if (key == '清空') {
        target.clear();
      } else if (key == '回退') {
        final text = target.text;
        if (text.isNotEmpty) {
          target.text = text.substring(0, text.length - 1);
          target.selection = TextSelection.collapsed(offset: target.text.length);
        }
      } else {
        target.text = '${target.text}$key';
        target.selection = TextSelection.collapsed(offset: target.text.length);
      }
    });
  }

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

final class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: BookingTokens.surfaceFooter.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: BookingTokens.tableBorder),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: BookingTokens.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}
