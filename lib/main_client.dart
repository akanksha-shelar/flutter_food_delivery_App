import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app_config.dart';
import 'pages/onboarding.dart'; // Or login.dart / home.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  AppConfig(flavor: Flavor.client, appTitle: 'Food App');

  runApp(
    MaterialApp(
      title: 'Food App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      home: const Onboarding(), // Initial entry screen for Client
    ),
  );
}
