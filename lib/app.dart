import 'package:flutter/material.dart';

class BscaApp extends StatelessWidget {
  const BscaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BSCA Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('BSCA Mobile Flutter App'),
        ),
      ),
    );
  }
}
