import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery_app/service/widget_support.dart';
import 'package:food_delivery_app/service/database.dart';

class ManageUsers extends StatefulWidget {
  const ManageUsers({super.key});

  @override
  State<ManageUsers> createState() => _ManageUsersState();
}

class _ManageUsersState extends State<ManageUsers> {
  Stream<QuerySnapshot>? userStream;

  void getontheload() {
    // Stream returns synchronously; do not await
    userStream = DatabaseMethods().getAllUsers();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getontheload();
  }

  /// Show a confirmation dialog before deleting a user
  Future<void> _showDeleteConfirmationDialog(
      String docId, String userName) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Delete User"),
          content: Text(
            "Are you sure you want to remove $userName? This action cannot be undone.",
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffef2b39),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await DatabaseMethods().deleteUser(docId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("$userName removed successfully"),
                      backgroundColor: Colors.black87,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget allUsers() {
    return StreamBuilder<QuerySnapshot>(
      stream: userStream,
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        // 1. Handle Error State
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "Error loading users: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // 2. Handle Waiting State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 3. Render Users List
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          return ListView.builder(
            padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot ds = snapshot.data!.docs[index];
              Map<String, dynamic> data =
                  ds.data() as Map<String, dynamic>? ?? {};

              // Safe field retrieval
              String userName = data["Name"] ?? "No Name";
              String userEmail = data["Email"] ?? "No Email";
              String userPhone = data["Phone"] ?? "";
              String userImage = data["Image"] ?? "";
              String docId = ds.id;

              return Container(
                margin: const EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  bottom: 15.0,
                ),
                child: Material(
                  elevation: 3.0,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // User Profile Picture
                        ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: userImage.isNotEmpty
                              ? Image.network(
                                  userImage,
                                  height: 70,
                                  width: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.asset(
                                    "images/boy.jpg",
                                    height: 70,
                                    width: 70,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.account_circle,
                                      size: 70,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : Image.asset(
                                  "images/boy.jpg",
                                  height: 70,
                                  width: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                    Icons.account_circle,
                                    size: 70,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 15.0),

                        // User Information Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    color: Color(0xffef2b39),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6.0),
                                  Expanded(
                                    child: Text(
                                      userName,
                                      style: AppWidget.boldTextFieldStyle(),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4.0),

                              // Email
                              Row(
                                children: [
                                  const Icon(
                                    Icons.mail,
                                    color: Color(0xffef2b39),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6.0),
                                  Expanded(
                                    child: Text(
                                      userEmail,
                                      style: AppWidget.SimpleTextFieldStyle(),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),

                              // Phone (If available)
                              if (userPhone.isNotEmpty) ...[
                                const SizedBox(height: 4.0),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone,
                                      color: Color(0xffef2b39),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6.0),
                                    Expanded(
                                      child: Text(
                                        userPhone,
                                        style: AppWidget.SimpleTextFieldStyle(),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              const SizedBox(height: 10.0),

                              // Remove Button
                              GestureDetector(
                                onTap: () => _showDeleteConfirmationDialog(
                                    docId, userName),
                                child: Container(
                                  height: 32,
                                  width: 90,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Remove",
                                      style: AppWidget.whiteTextFieldStyle(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }

        // Empty state
        return const Center(
          child: Text(
            "No registered users found.",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.only(top: 40.0),
        child: Column(
          children: [
            // Top Bar Navigation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xffef2b39),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    "Current Users",
                    style: AppWidget.HeadlineTextFieldStyle(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),

            // User Cards Container
            Expanded(
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(
                  color: Color(0xFFececf8),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: allUsers(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
