import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery_app/pages/signupwithphone.dart';
import 'package:food_delivery_app/service/auth.dart';
import 'package:food_delivery_app/service/database.dart';
import 'package:food_delivery_app/service/shared_pref.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String? name, email, phone, address, wallet, uid;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    User? currentUser = AuthMethods().getCurrentUser();

    if (currentUser != null) {
      uid = currentUser.uid;
      DocumentSnapshot userDoc = await DatabaseMethods().getUserDetails(uid!);

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          name = data['Name'] ?? "N/A";
          email = data['Email'] ?? "N/A";
          phone = data['Phone'] ?? currentUser.phoneNumber ?? "N/A";
          address = data['Address'] ?? "N/A";
          wallet = data['Wallet']?.toString() ?? "0";
          isLoading = false;
        });

        await SharedpreferenceHelper().saveUserId(uid!);
        await SharedpreferenceHelper().saveUserName(name!);
        await SharedpreferenceHelper().saveUserEmail(email!);
        await SharedpreferenceHelper().saveUserPhone(phone!);
        await SharedpreferenceHelper().saveUserAddress(address!);
        await SharedpreferenceHelper().saveUserWallet(wallet!);
        return;
      }
    }

    name = await SharedpreferenceHelper().getUserName();
    email = await SharedpreferenceHelper().getUserEmail();
    phone = await SharedpreferenceHelper().getUserPhone();
    address = await SharedpreferenceHelper().getUserAddress();
    wallet = await SharedpreferenceHelper().getUserWallet();

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFEF2B39)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 45,
                    backgroundColor: Color(0xFFEF2B39),
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  _buildProfileTile(Icons.person, "Name", name ?? "N/A"),
                  _buildProfileTile(Icons.phone, "Phone", phone ?? "N/A"),
                  _buildProfileTile(Icons.email, "Email", email ?? "N/A"),
                  _buildProfileTile(
                    Icons.location_on,
                    "Address",
                    address ?? "N/A",
                  ),
                  _buildProfileTile(
                    Icons.account_balance_wallet,
                    "Wallet",
                    "\$$wallet",
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
                      onPressed: () async {
                        await AuthMethods().signOut();
                        if (mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignUpWithPhone(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      child: const Text(
                        "Log Out",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileTile(IconData icon, String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFEF2B39)),
        title: Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
