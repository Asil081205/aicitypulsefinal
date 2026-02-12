import 'package:flutter/material.dart';

// A simplified version of your app for testing
class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI City Pulse',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('AI CITY PULSE'),
        ),
        body: const Center(
          child: Text('CITY HEALTH INDEX'),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {},
          icon: const Icon(Icons.map),
          label: const Text('View Map'),
        ),
      ),
    );
  }
}