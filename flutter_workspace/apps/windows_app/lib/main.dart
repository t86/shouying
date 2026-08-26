import 'package:flutter/material.dart';

void main() {
  runApp(const ShouyinWindowsApp());
}

class ShouyinWindowsApp extends StatelessWidget {
  const ShouyinWindowsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: '收银 Windows 客户端',
      home: Scaffold(body: Center(child: Text('收银 Windows 客户端'))),
    );
  }
}
