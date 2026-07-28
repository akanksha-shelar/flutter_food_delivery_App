import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery_app/pages/otp.dart';

import 'package:food_delivery_app/pages/signupwithphone.dart';
import 'package:food_delivery_app/service/widget_support.dart';

class LoginWithOTP extends StatefulWidget {
  const LoginWithOTP({super.key});

  @override
  State<LoginWithOTP> createState() => _LoginWithOTPState();
}

class _LoginWithOTPState extends State<LoginWithOTP> {
  final TextEditingController phoneController = TextEditingController();
  bool isLoading = false;

  void sendOTP() async {
    String inputPhone = phoneController.text.trim();

    if (inputPhone.isEmpty || inputPhone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid 10-digit phone number"),
        ),
      );
      return;
    }

    String formattedPhone = inputPhone.startsWith('+91')
        ? inputPhone
        : '+91$inputPhone';

    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          UserCredential userCredential = await FirebaseAuth.instance
              .signInWithCredential(credential);

          if (mounted && userCredential.user != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Login Successful!")));
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() => isLoading = false);

          String errorMessage = e.message ?? "Verification Failed";
          if (e.code == 'invalid-phone-number') {
            errorMessage = "The phone number format is invalid.";
          } else if (e.code == 'too-many-requests') {
            errorMessage = "Too many requests. Please try again later.";
          }

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() => isLoading = false);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpPage(
                vid: verificationId,
                phoneNumber: formattedPhone,
                resendToken: resendToken,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Icon(
              Icons.lock_person_rounded,
              size: 90,
              color: Colors.black,
            ),
            const SizedBox(height: 25),
            Text(
              "Log In with Mobile",
              style: AppWidget.HeadlineTextFieldStyle(),
            ),
            const SizedBox(height: 10),
            Text(
              "Enter your registered phone number to receive a 6-digit OTP.",
              textAlign: TextAlign.center,
              style: AppWidget.SimpleTextFieldStyle(),
            ),
            const SizedBox(height: 35),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: "9876543210",
                labelText: "Mobile Number",
                prefixIcon: const Icon(Icons.phone, color: Colors.black),
                prefixText: "+91 ",
                prefixStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isLoading ? null : sendOTP,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("Get OTP", style: AppWidget.whiteTextFieldStyle()),
              ),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account?",
                  style: AppWidget.SimpleTextFieldStyle(),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignUpWithPhone(),
                      ),
                    );
                  },
                  child: Text(
                    " Sign Up",
                    style: AppWidget.boldTextFieldStyle(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
