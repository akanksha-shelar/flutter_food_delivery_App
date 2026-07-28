// lib/main.dart
import 'package:flutter/material.dart';
import 'main_admin.dart' as admin;
import 'main_client.dart' as client;

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => client.main(),
                child: const Text('Run Client App'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => admin.main(),
                child: const Text('Run Admin App'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
