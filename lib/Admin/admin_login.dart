import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery_app/Admin/home_admin.dart';
import 'package:food_delivery_app/service/widget_support.dart';

class AdminLogIn extends StatefulWidget {
  const AdminLogIn({super.key});

  @override
  State<AdminLogIn> createState() => _AdminLogInState();
}

class _AdminLogInState extends State<AdminLogIn> {
  final TextEditingController usernamecontroller = TextEditingController();
  final TextEditingController passwordcontroller = TextEditingController();

  @override
  void dispose() {
    usernamecontroller.dispose();
    passwordcontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height / 2.5,
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.only(top: 30.0),
                  decoration: const BoxDecoration(
                    color: Color(0xffffefbf),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      Image.asset(
                        "images/pan.png",
                        height: 180,
                        width: 240,
                        fit: BoxFit.fill,
                      ),
                      Image.asset(
                        "images/logo.png",
                        width: 150,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height / 3.2,
                    left: 20.0,
                    right: 20.0,
                  ),
                  child: Material(
                    elevation: 3.0,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20.0),
                          Center(
                            child: Text(
                              "Admin Login",
                              style: AppWidget.HeadlineTextFieldStyle(),
                            ),
                          ),
                          const SizedBox(height: 30.0),
                          Text(
                            "Email / Username",
                            style: AppWidget.SignUpTextFeildStyle(),
                          ),
                          const SizedBox(height: 5.0),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFececf8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextField(
                              controller: usernamecontroller,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Enter Admin Email",
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20.0),
                          Text(
                            "Password",
                            style: AppWidget.SignUpTextFeildStyle(),
                          ),
                          const SizedBox(height: 5.0),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFececf8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextField(
                              controller: passwordcontroller,
                              obscureText: true,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Enter Password",
                                prefixIcon: Icon(Icons.password_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40.0),
                          GestureDetector(
                            onTap: loginAdmin,
                            child: Center(
                              child: Container(
                                width: 200,
                                height: 55,
                                decoration: BoxDecoration(
                                  color: const Color(0xffef2b39),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Center(
                                  child: Text(
                                    "LogIn",
                                    style: AppWidget.boldTextFieldStyle(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> loginAdmin() async {
    final String email = usernamecontroller.text.trim();
    final String password = passwordcontroller.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text("Please enter both email and password"),
        ),
      );
      return;
    }

    try {
      // 1. Authenticate using Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // 2. Check if user document exists in the "Admin" collection using UID
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection("Admin")
          .doc(userCredential.user!.uid)
          .get();

      if (!mounted) return;

      if (adminDoc.exists) {
        // Success: User is an authenticated admin
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeAdmin()),
        );
      } else {
        // User logged in via Firebase Auth but is not registered as an Admin in Firestore
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text("Access Denied: You are not authorized as an Admin."),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String errorMessage = "Login failed";
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        errorMessage = "Invalid email or password.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Incorrect password.";
      } else {
        errorMessage = e.message ?? errorMessage;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(errorMessage),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("An error occurred: $e"),
        ),
      );
    }
  }
}
