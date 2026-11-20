import 'package:device_bridge_windows/device_bridge_windows.dart';
import 'package:flutter/material.dart';
import 'package:native_client_shell/native_client_shell.dart';

export 'package:native_client_shell/native_client_shell.dart';

void main() => runApp(const ShouyinWindowsApp());

final class ShouyinWindowsApp extends StatelessWidget {
  const ShouyinWindowsApp({
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
    appLabel: '收银 Windows 客户端',
    platformLabel: 'Windows',
    environment: environment,
    dependenciesFactory: dependenciesFactory,
    initialLocation: initialLocation,
    createScanner: (ref) {
      final scanner = WindowsScannerService();
      ref.onDispose(scanner.dispose);
      return scanner;
    },
    createPrinter: WindowsPrinterService.new,
    createTerminalIdentity: WindowsTerminalIdentityService.new,
  );
}
