import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app_config.dart';
import 'Admin/admin_login.dart'; // Imports your admin login screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  AppConfig(flavor: Flavor.admin, appTitle: 'Food App - Admin');

  runApp(
    MaterialApp(
      title: 'Food App - Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      home: const AdminLogIn(), // Initial entry screen for Admin
    ),
  );
}
