import 'package:flutter/material.dart';

void main() {
  runApp(const ShouyinWebApp());
}

class ShouyinWebApp extends StatelessWidget {
  const ShouyinWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: '收银 Web 客户端',
      home: Scaffold(body: Center(child: Text('收银 Web 客户端'))),
    );
  }
}
