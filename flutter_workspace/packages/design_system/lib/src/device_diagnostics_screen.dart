import 'dart:async';
import 'dart:math';

import 'package:device_bridge_platform_interface/device_bridge_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation/foundation.dart';

final scannerServiceProvider = Provider<ScannerService>(
  (ref) => throw StateError('scanner service must be overridden'),
);

final printerServiceProvider = Provider<PrinterService>(
  (ref) => throw StateError('printer service must be overridden'),
);

final class DeviceDiagnosticsScreen extends ConsumerStatefulWidget {
  const DeviceDiagnosticsScreen({
    required this.appVersion,
    required this.platformLabel,
    this.clock,
    this.diagnosticIdFactory,
    super.key,
  });

  static const double wideBreakpoint = 840;
  static const Key wideLayoutKey = Key('device-diagnostics-wide');
  static const Key narrowLayoutKey = Key('device-diagnostics-narrow');
  static const Key openCameraKey = Key('device-camera-open');
  static const Key closeCameraKey = Key('device-camera-close');
  static const Key targetSelectorKey = Key('device-printer-target');
  static const Key lanHostKey = Key('device-lan-host');
  static const Key lanPortKey = Key('device-lan-port');
  static const Key paperSelectorKey = Key('device-paper-width');
  static const Key printButtonKey = Key('device-print-test');

  final String appVersion;
  final String platformLabel;
  final DateTime Function()? clock;
  final String Function()? diagnosticIdFactory;

  @override
  ConsumerState<DeviceDiagnosticsScreen> createState() =>
      _DeviceDiagnosticsScreenState();
}

enum _PrinterTargetChoice { system, lan }

final class _DeviceDiagnosticsScreenState
    extends ConsumerState<DeviceDiagnosticsScreen> {
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController(
    text: '9100',
  );
  StreamSubscription<String>? _scanSubscription;
  StreamSubscription<AppFailure>? _scannerFailureSubscription;
  late ScannerService _scanner;
  String _scannerStatus = '已就绪';
  String _maskedLastScan = '无';
  _PrinterTargetChoice _targetChoice = _PrinterTargetChoice.system;
  ReceiptPaperWidth _paperWidth = ReceiptPaperWidth.mm58;
  bool _printing = false;
  String _printStatus = '未测试';
  AppFailure? _scannerFailure;
  AppFailure? _printerFailure;

  @override
  void initState() {
    super.initState();
    _scanner = ref.read(scannerServiceProvider);
    _scanSubscription = _scanner.scans.listen(
      (value) {
        final masked = _maskScan(value);
        if (mounted) setState(() => _maskedLastScan = masked);
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _scannerStatus = '不可用';
          _scannerFailure = const AppFailure(
            kind: FailureKind.device,
            code: 'device.scanner_unavailable',
            safeMessage: '扫码设备不可用',
          );
        });
      },
    );
    _scanner.start();
    if (_scanner case final CameraScannerService camera) {
      _scannerFailureSubscription = camera.failures.listen((failure) {
        if (!mounted) return;
        setState(() {
          _scannerStatus = '不可用';
          _scannerFailure = failure;
        });
      });
    }
  }

  @override
  void dispose() {
    _scanner.stop();
    unawaited(_scanSubscription?.cancel());
    unawaited(_scannerFailureSubscription?.cancel());
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scannerCard = _scannerSection(context);
    final printerCard = _printerSection(context);
    return Scaffold(
      appBar: AppBar(title: const Text('设备检查')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide =
                constraints.maxWidth >= DeviceDiagnosticsScreen.wideBreakpoint;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: wide
                  ? Row(
                      key: DeviceDiagnosticsScreen.wideLayoutKey,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: scannerCard),
                        const SizedBox(width: 20),
                        Expanded(child: printerCard),
                      ],
                    )
                  : Column(
                      key: DeviceDiagnosticsScreen.narrowLayoutKey,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        scannerCard,
                        const SizedBox(height: 16),
                        printerCard,
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _scannerSection(BuildContext context) {
    final camera = _scanner is CameraScannerService
        ? _scanner as CameraScannerService
        : null;
    final capabilities = _scanner.capabilities;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('扫码器', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _statusRow('状态', _scannerStatus),
            _statusRow(
              '输入方式',
              capabilities.degraded ? '键盘输入（受焦点限制）' : 'HID 全局输入',
            ),
            _statusRow('最近扫码', _maskedLastScan),
            if (camera != null && capabilities.camera) ...<Widget>[
              const SizedBox(height: 12),
              if (!camera.isCameraOpen)
                FilledButton.icon(
                  key: DeviceDiagnosticsScreen.openCameraKey,
                  onPressed: _openCamera,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('打开相机扫码'),
                )
              else ...<Widget>[
                Semantics(
                  label: '相机扫码预览',
                  child: SizedBox(
                    height: 220,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: camera.buildCameraPreview(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: DeviceDiagnosticsScreen.closeCameraKey,
                  onPressed: _closeCamera,
                  icon: const Icon(Icons.close),
                  label: const Text('关闭相机'),
                ),
              ],
            ],
            if (_scannerFailure case final failure?) ...<Widget>[
              const SizedBox(height: 12),
              _failureView(failure),
            ],
          ],
        ),
      ),
    );
  }

  Widget _printerSection(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('打印机', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          DropdownButtonFormField<_PrinterTargetChoice>(
            key: DeviceDiagnosticsScreen.targetSelectorKey,
            initialValue: _targetChoice,
            decoration: const InputDecoration(
              labelText: '打印目标',
              border: OutlineInputBorder(),
            ),
            items: const <DropdownMenuItem<_PrinterTargetChoice>>[
              DropdownMenuItem(
                value: _PrinterTargetChoice.system,
                child: Text('系统打印机'),
              ),
              DropdownMenuItem(
                value: _PrinterTargetChoice.lan,
                child: Text('局域网 ESC/POS'),
              ),
            ],
            onChanged: _printing
                ? null
                : (value) {
                    if (value != null) setState(() => _targetChoice = value);
                  },
          ),
          if (_targetChoice == _PrinterTargetChoice.lan) ...<Widget>[
            const SizedBox(height: 12),
            TextField(
              key: DeviceDiagnosticsScreen.lanHostKey,
              controller: _hostController,
              enabled: !_printing,
              maxLength: 253,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: '主机或 IP',
                hintText: '192.0.2.10',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: DeviceDiagnosticsScreen.lanPortKey,
              controller: _portController,
              enabled: !_printing,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
              decoration: const InputDecoration(
                labelText: '端口',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<ReceiptPaperWidth>(
            key: DeviceDiagnosticsScreen.paperSelectorKey,
            initialValue: _paperWidth,
            decoration: const InputDecoration(
              labelText: '纸宽',
              border: OutlineInputBorder(),
            ),
            items: const <DropdownMenuItem<ReceiptPaperWidth>>[
              DropdownMenuItem(
                value: ReceiptPaperWidth.mm58,
                child: Text('58 mm'),
              ),
              DropdownMenuItem(
                value: ReceiptPaperWidth.mm80,
                child: Text('80 mm'),
              ),
            ],
            onChanged: _printing
                ? null
                : (value) {
                    if (value != null) setState(() => _paperWidth = value);
                  },
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: DeviceDiagnosticsScreen.printButtonKey,
            onPressed: _printing ? null : _printTestReceipt,
            icon: _printing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print),
            label: const Text('打印测试小票'),
          ),
          const SizedBox(height: 12),
          _statusRow('打印状态', _printStatus),
          if (_printerFailure case final failure?) _failureView(failure),
        ],
      ),
    ),
  );

  Future<void> _openCamera() async {
    final camera = _scanner;
    if (camera is! CameraScannerService) return;
    final result = await camera.openCamera();
    if (!mounted) return;
    setState(() {
      _scannerFailure = result.failureOrNull;
      _scannerStatus = result.failureOrNull == null ? '相机已打开' : '不可用';
    });
  }

  Future<void> _closeCamera() async {
    final camera = _scanner;
    if (camera is! CameraScannerService) return;
    await camera.closeCamera();
    if (mounted) setState(() => _scannerStatus = '已就绪');
  }

  Future<void> _printTestReceipt() async {
    PrinterTarget target;
    try {
      target = switch (_targetChoice) {
        _PrinterTargetChoice.system => SystemPrinterTarget(
          paperWidth: _paperWidth,
        ),
        _PrinterTargetChoice.lan => LanEscPosTarget(
          host: _hostController.text,
          port: int.parse(_portController.text),
          paperWidth: _paperWidth,
        ),
      };
    } on Object {
      setState(() {
        _printerFailure = const AppFailure(
          kind: FailureKind.device,
          code: 'device.printer_target_invalid',
          safeMessage: '打印机地址或端口无效',
        );
        _printStatus = '配置无效';
      });
      return;
    }
    setState(() {
      _printing = true;
      _printerFailure = null;
      _printStatus = '打印中';
    });
    Result<void> result;
    try {
      result = await ref
          .read(printerServiceProvider)
          .printTestReceipt(
            TestReceipt(
              appVersion: widget.appVersion,
              platform: widget.platformLabel,
              timestamp: (widget.clock ?? DateTime.now)(),
              diagnosticId: (widget.diagnosticIdFactory ?? _newDiagnosticId)(),
            ),
            target,
          );
    } on Object {
      result = const FailureResult<void>(
        AppFailure(
          kind: FailureKind.device,
          code: 'device.printer_unavailable',
          safeMessage: '打印设备不可用',
        ),
      );
    }
    if (!mounted) return;
    setState(() {
      _printing = false;
      _printerFailure = result.failureOrNull;
      _printStatus = result.failureOrNull == null ? '打印测试成功' : '打印失败';
    });
  }

  Widget _failureView(AppFailure failure) => Semantics(
    liveRegion: true,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(_safeFailureCode(failure.code)),
            Text(_safeFailureMessage(failure.safeMessage)),
          ],
        ),
      ),
    ),
  );

  static Widget _statusRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(width: 88, child: Text(label)),
        Expanded(child: Text(value)),
      ],
    ),
  );

  static String _maskScan(String raw) {
    final length = raw.runes.length;
    if (length <= 4) return '*' * length.clamp(1, 4);
    final characters = raw.runes.map(String.fromCharCode).toList();
    return '${characters[0]}${characters[1]}${'*' * (length - 4)}'
        '${characters[length - 2]}${characters.last}';
  }

  static String _safeFailureCode(String value) =>
      RegExp(r'^[a-z0-9._-]{1,128}$').hasMatch(value)
      ? value
      : 'device.unknown';

  static String _safeFailureMessage(String value) {
    if (value.isEmpty || value.length > 128 || _sensitive.hasMatch(value)) {
      return '设备操作失败';
    }
    return value;
  }

  static String _newDiagnosticId() {
    final random = Random.secure();
    final first = random.nextInt(0x7fffffff).toRadixString(16);
    final second = random.nextInt(0x7fffffff).toRadixString(16);
    return 'diag_${first}_$second';
  }

  static final RegExp _sensitive = RegExp(
    r'token|password|secret|authorization|payment|paycode|付款|支付|密码|令牌',
    caseSensitive: false,
  );
}
