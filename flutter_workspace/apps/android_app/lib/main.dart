import 'package:flutter/material.dart';

void main() {
  runApp(const ShouyinAndroidApp());
}

class ShouyinAndroidApp extends StatelessWidget {
  const ShouyinAndroidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: '收银 Android 客户端',
      home: Scaffold(body: Center(child: Text('收银 Android 客户端'))),
    );
  }
}
