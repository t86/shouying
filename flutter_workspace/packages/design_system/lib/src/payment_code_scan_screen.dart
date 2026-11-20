import 'dart:async';

import 'package:device_bridge_platform_interface/device_bridge_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A single-use payment-code capture route. Codes are returned to the caller,
/// never rendered, logged, persisted, or sent to a payment API here.
final class PaymentCodeScanScreen extends StatefulWidget {
  const PaymentCodeScanScreen({
    required this.scanner,
    required this.canScan,
    super.key,
  });

  final ScannerService scanner;
  final bool Function() canScan;

  @override
  State<PaymentCodeScanScreen> createState() => _PaymentCodeScanScreenState();
}

final class _PaymentCodeScanScreenState extends State<PaymentCodeScanScreen> {
  // Providers may reuse a scanner when a closed route is immediately reopened.
  // A late old camera-open completion must not stop the new route's device.
  static final _owners = Expando<_PaymentCodeScanScreenState>();
  late final ScannerService _scanner = widget.scanner;
  StreamSubscription<String>? _subscription;
  ModalRoute<dynamic>? _route;
  bool _scheduled = false, _done = false, _stopped = false;
  bool _previewRequested = false, _opening = false;
  String? _message;

  CameraScannerService? get _camera {
    final scanner = _scanner;
    return scanner is CameraScannerService ? scanner : null;
  }

  bool get _current {
    if (!mounted || _done) return false;
    final route = _route;
    if (route == null || !route.isCurrent || !route.isActive ||
        route.animation?.status == AnimationStatus.reverse) return false;
    try { return widget.canScan(); } on Object { return false; }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (!identical(route, _route)) {
      _removeRouteListeners();
      _route = route;
      route?.animation?.addStatusListener(_routeChanged);
      route?.secondaryAnimation?.addStatusListener(_routeChanged);
    }
    if (!_scheduled) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  @override
  void didUpdateWidget(covariant PaymentCodeScanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.scanner, _scanner) || !_current) {
      _invalidate('当前扫码操作已失效，请返回后重试');
    }
  }

  void _routeChanged(AnimationStatus _) {
    if (!_current) _invalidate('扫码已停止，请返回后重新打开');
  }

  void _start() {
    if (!_current) {
      _invalidate('当前扫码操作已失效，请返回后重试');
      return;
    }
    final previous = _owners[_scanner];
    if (previous != null && !identical(previous, this)) {
      previous._invalidate('扫码设备已由新页面接管');
    }
    _owners[_scanner] = this;
    try {
      _subscription = _scanner.scans.listen(
        _onCode,
        onError: (Object _, StackTrace __) => _invalidate('扫码设备暂不可用，请返回后重试'),
        onDone: () => _invalidate('扫码设备已断开，请返回后重试'),
      );
      _scanner.start();
      if (!_current) return; // start may synchronously deliver the first HID code.
      final camera = _camera;
      if (camera != null && _scanner.capabilities.camera) {
        setState(() { _previewRequested = true; _opening = true; });
        // Android's controller must be attached to its preview before start.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_current) unawaited(_openCamera(camera));
        });
      }
    } on Object {
      _invalidate('扫码设备暂不可用，请返回后重试');
    }
  }

  Future<void> _openCamera(CameraScannerService camera) async {
    try {
      final result = await camera.openCamera();
      if (!_current) {
        await _closeLateCamera(camera);
        return;
      }
      if (result.failureOrNull case final failure?) {
        await _close(camera);
        if (!_current) return;
        setState(() {
          _opening = false;
          _previewRequested = false;
          _message = failure.code == 'device.camera_permission'
              ? '未获得相机权限，请使用扫码枪或取消'
              : '摄像头不可用，请使用扫码枪或取消';
        });
      } else {
        setState(() => _opening = false);
      }
    } on Object {
      await _closeLateCamera(camera);
      if (_current) setState(() {
        _opening = false; _previewRequested = false;
        _message = '摄像头不可用，请使用扫码枪或取消';
      });
    }
  }

  Future<void> _closeLateCamera(CameraScannerService camera) async {
    if (_owners[_scanner] == null || identical(_owners[_scanner], this)) {
      await _close(camera);
    }
  }

  Future<void> _close(CameraScannerService camera) async {
    try { await camera.closeCamera(); } on Object { /* No device detail or code logging. */ }
  }

  void _onCode(String raw) {
    if (_done) return;
    if (!_current) {
      _invalidate('当前扫码操作已失效，请返回后重试');
      return;
    }
    final code = raw.trim();
    if (code.isEmpty || code.length > 1024 ||
        RegExp(r'[\x00-\x1f\x7f-\x9f\u2028\u2029]').hasMatch(code)) {
      _update(() => _message = '付款码无效，请重新扫码');
      return;
    }
    // Mark first, before stop/cancel/pop can synchronously emit another scan.
    _done = true;
    _shutdown();
    Navigator.of(context).pop<String>(code);
  }

  void _invalidate(String message) {
    if (_done) return;
    _done = true;
    _shutdown();
    _update(() {
      _previewRequested = false; _opening = false; _message = message;
    });
  }

  void _update(VoidCallback update) {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(update);
      });
    } else { setState(update); }
  }

  void _shutdown() {
    if (_stopped) return;
    _stopped = true;
    final subscription = _subscription;
    _subscription = null;
    if (subscription != null) unawaited(subscription.cancel().catchError((Object _) {}));
    if (!identical(_owners[_scanner], this)) return;
    _owners[_scanner] = null;
    try { _scanner.stop(); } on Object { /* Teardown is best effort. */ }
    final camera = _camera;
    if (camera != null) unawaited(_close(camera));
  }

  void _removeRouteListeners() {
    _route?.animation?.removeStatusListener(_routeChanged);
    _route?.secondaryAnimation?.removeStatusListener(_routeChanged);
  }

  @override
  void dispose() {
    _done = true;
    _removeRouteListeners();
    _shutdown();
    super.dispose();
  }

  Widget _preview() {
    try { return _camera!.buildCameraPreview(); } on Object {
      WidgetsBinding.instance.addPostFrameCallback((_) => _invalidate('摄像头预览不可用，请返回后重试'));
      return const Center(child: Text('摄像头预览不可用'));
    }
  }

  @override
  Widget build(BuildContext context) => PopScope<String>(
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) { _done = true; _shutdown(); }
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('扫描付款码')),
      body: Focus(autofocus: true, child: SafeArea(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('请使用扫码枪扫描付款码，扫码枪以回车结束。支持相机的设备也可对准付款码。'),
          const SizedBox(height: 16),
          if (_previewRequested && !_done) Expanded(child: _preview())
          else const Expanded(child: Center(child: Icon(Icons.qr_code_scanner, size: 72))),
          if (_opening) const LinearProgressIndicator(),
          if (_message != null) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(_message!)),
          TextButton(onPressed: () { _done = true; _shutdown(); Navigator.of(context).pop(); }, child: const Text('取消')),
        ]),
      ))),
    ),
  );
}
