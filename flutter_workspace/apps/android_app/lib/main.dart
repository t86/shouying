import 'dart:async';

import 'package:device_bridge_android/device_bridge_android.dart';
import 'package:flutter/material.dart';
import 'package:native_client_shell/native_client_shell.dart';
export 'package:native_client_shell/native_client_shell.dart';

void main() => runApp(const ShouyinAndroidApp());

final class ShouyinAndroidApp extends StatelessWidget {
  const ShouyinAndroidApp({
    this.environment,
    this.dependenciesFactory,
    this.initialLocation = '/login',
    super.key,
  });
  final AppRuntimeConfiguration? environment;
  final ShellDependenciesFactory? dependenciesFactory;
  final String initialLocation;
  @override
  Widget build(BuildContext context) => NativeClientApp(
    appLabel: '收银 Android 客户端',
    platformLabel: 'Android',
    environment: environment,
    dependenciesFactory: dependenciesFactory,
    initialLocation: initialLocation,
    createScanner: (ref) {
      final scanner = AndroidScannerService();
      ref.onDispose(() => unawaited(scanner.dispose()));
      return scanner;
    },
    createPrinter: AndroidPrinterService.new,
    createTerminalIdentity: AndroidTerminalIdentityService.new,
  );
}
