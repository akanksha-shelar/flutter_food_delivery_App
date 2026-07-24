import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'otp.dart';

class SignUpWithPhone extends StatefulWidget {
  const SignUpWithPhone({super.key});

  @override
  State<SignUpWithPhone> createState() => _SignUpWithPhoneState();
}

class _SignUpWithPhoneState extends State<SignUpWithPhone> {
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

    // Format phone number to E.164 standard (+91 for India)
    String formattedPhone = inputPhone.startsWith('+91')
        ? inputPhone
        : '+91$inputPhone';

    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Automatic sign-in when Android auto-detects SMS
          UserCredential userCredential = await FirebaseAuth.instance
              .signInWithCredential(credential);
          if (mounted && userCredential.user != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Phone Auto-Verified!")),
            );
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
              Icons.phone_android_rounded,
              size: 90,
              color: Color(0xFFEF2B39),
            ),
            const SizedBox(height: 25),
            const Text(
              "Enter your Phone Number",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "We will send a 6-digit verification code to this number via SMS.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 35),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: "9876543210",
                labelText: "Mobile Number",
                prefixIcon: const Icon(Icons.phone, color: Color(0xFFEF2B39)),
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
                  borderSide: const BorderSide(
                    color: Color(0xFFEF2B39),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF2B39),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isLoading ? null : sendOTP,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Send OTP",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
