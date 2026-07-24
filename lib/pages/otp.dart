import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'bottomnav.dart';
import 'nameaddress.dart';

class OtpPage extends StatefulWidget {
  final String vid;
  final String phoneNumber;
  final int? resendToken;

  const OtpPage({
    super.key,
    required this.vid,
    required this.phoneNumber,
    this.resendToken,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  late String currentVerificationId;
  int? currentResendToken;
  String code = '';
  bool isLoading = false;
  bool isResending = false;

  @override
  void initState() {
    super.initState();
    currentVerificationId = widget.vid;
    currentResendToken = widget.resendToken;
  }

  void resendOTP() async {
    setState(() => isResending = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: widget.phoneNumber,
      forceResendingToken: currentResendToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!mounted) return;
        setState(() => isResending = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Resend Failed: ${e.message}")));
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!mounted) return;
        setState(() {
          currentVerificationId = verificationId;
          currentResendToken = resendToken;
          isResending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("A new OTP has been sent.")),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  void signIn() async {
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter full 6-digit OTP")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: currentVerificationId,
        smsCode: code,
      );

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      User? user = userCredential.user;

      if (user != null && mounted) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!mounted) return;
        setState(() => isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Phone Verified Successfully!")),
        );

        if (userDoc.exists) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const BottomNav()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => NameAddressPage(
                phoneNumber: widget.phoneNumber,
                uid: user.uid,
              ),
            ),
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? "Invalid OTP Code")));
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 55,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Verify OTP"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "OTP Verification",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Enter the OTP sent to ${widget.phoneNumber}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 40),

            Pinput(
              length: 6,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  border: Border.all(color: const Color(0xFFEF2B39), width: 2),
                ),
              ),
              onChanged: (value) => code = value,
            ),
            const SizedBox(height: 25),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Didn't receive the code? "),
                GestureDetector(
                  onTap: isResending ? null : resendOTP,
                  child: Text(
                    isResending ? "Sending..." : "Resend OTP",
                    style: const TextStyle(
                      color: Color(0xFFEF2B39),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
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
                onPressed: isLoading ? null : signIn,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Verify & Continue",
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
