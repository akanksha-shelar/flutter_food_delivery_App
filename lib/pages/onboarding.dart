import 'package:flutter/material.dart';
//import 'package:food_delivery_app/pages/signup.dart'; // Adjust path if necessary
import 'package:food_delivery_app/pages/signupwithphone.dart';
import 'package:food_delivery_app/service/widget_support.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        margin: const EdgeInsets.only(top: 40.0),
        child: Column(
          children: [
            Image.asset("images/onboard.png"),
            const SizedBox(height: 20.0),
            Text(
              "The Fastest\nFood Delivery",
              textAlign: TextAlign.center,
              style: AppWidget.HeadlineTextFieldStyle(),
            ),
            const SizedBox(height: 20.0),
            Text(
              "Craving something delicious?\n Order now and get your \nfavorites delivered fast!",
              textAlign: TextAlign.center,
              style: AppWidget.SimpleTextFieldStyle(),
            ),
            const SizedBox(height: 30.0),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SignUpWithPhone(),
                  ),
                );
              },
              child: Container(
                height: 60,
                width: MediaQuery.of(context).size.width / 2,
                decoration: BoxDecoration(
                  color: const Color(0xff8c592a),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    "Get Started",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
