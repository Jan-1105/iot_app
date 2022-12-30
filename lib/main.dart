import 'package:flutter/material.dart';
import 'package:iot_app/widget/hearing.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT eSense App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HearingPage(title: 'Hörspektrum Test'),
    );
  }
}