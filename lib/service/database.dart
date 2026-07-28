import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  // --- SEARCH MANAGEMENT ---

  // Fetch all food items from Firestore for client-side substring matching
  Future<QuerySnapshot> getAllFoodItems() async {
    return await FirebaseFirestore.instance.collection("Items").get();
  }

  // Legacy method kept for backward compatibility if referenced elsewhere
  Future<QuerySnapshot> search(String searchQuery) async {
    return await getAllFoodItems();
  }

  // --- USER PROFILE & ACCOUNT MANAGEMENT ---

  // Fetch real-time Stream of all users for Admin
  Future<Stream<QuerySnapshot>> getAllUsers() async {
    return FirebaseFirestore.instance.collection("users").snapshots();
  }

  // Add initial user details on fresh registration
  Future<void> addUserDetails(
    Map<String, dynamic> userInfoMap,
    String id,
  ) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .set(userInfoMap);
  }

  // Get user details by Doc ID / Firebase Auth UID
  Future<DocumentSnapshot> getUserDetails(String id) async {
    return await FirebaseFirestore.instance.collection("users").doc(id).get();
  }

  // Update specific profile fields by User ID
  Future<void> updateUserProfile(
    String id,
    Map<String, dynamic> updateData,
  ) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .update(updateData);
  }

  // Fallback update/upsert user record by phone number when User ID is missing
  Future<void> updateOrInsertUserByPhone({
    required String phone,
    required String name,
    required String address,
    String? email,
  }) async {
    QuerySnapshot query = await FirebaseFirestore.instance
        .collection("users")
        .where("Phone", isEqualTo: phone)
        .get();

    if (query.docs.isNotEmpty) {
      String docId = query.docs.first.id;
      await FirebaseFirestore.instance.collection("users").doc(docId).update({
        "Name": name,
        "Address": address,
        if (email != null && email.isNotEmpty) "Email": email,
      });
    } else {
      await FirebaseFirestore.instance.collection("users").add({
        "Phone": phone,
        "Name": name,
        "Address": address,
        "Email": email ?? "",
        "Wallet": "0",
      });
    }
  }

  // Delete user document from Firestore
  Future<void> deleteUser(String id) async {
    await FirebaseFirestore.instance.collection("users").doc(id).delete();
  }

  // Get user doc query snapshot by Email
  Future<QuerySnapshot> getUserWalletbyemail(String email) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .where("Email", isEqualTo: email)
        .get();
  }

  // --- WALLET MANAGEMENT ---

  // Direct set or increment method for wallet balance
  Future<void> updateUserWallet(dynamic amount, String id) async {
    // If exact final remaining amount string is passed (e.g., "150")
    if (amount is String) {
      await FirebaseFirestore.instance.collection("users").doc(id).update({
        "Wallet": amount,
      });
    } else if (amount is int) {
      // Incremental change (positive to add, negative to subtract)
      await FirebaseFirestore.instance.collection("users").doc(id).update({
        "Wallet": FieldValue.increment(amount),
      });
    }
  }

  // Dedicated method to safely deduct an order amount from user wallet using FieldValue.increment
  Future<void> deductUserWallet(int orderAmount, String userId) async {
    if (orderAmount <= 0) return;

    await FirebaseFirestore.instance.collection("users").doc(userId).update({
      "Wallet": FieldValue.increment(-orderAmount),
    });
  }

  // --- TRANSACTIONS ---

  // Record a transaction in user's sub-collection
  Future<void> addUserTransaction(
    Map<String, dynamic> transactionMap,
    String id,
  ) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .collection("Transactions")
        .add(transactionMap);
  }

  // Get stream of transaction history ordered by newest first
  Stream<QuerySnapshot> getUserTransactions(String id) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .collection("Transactions")
        .orderBy("TimeStamp", descending: true)
        .snapshots();
  }

  // --- ORDER MANAGEMENT ---

  // Fetch real-time Stream of all orders for Admin (AllOrders screen)
  Future<Stream<QuerySnapshot>> getAdminOrders() async {
    return FirebaseFirestore.instance.collection("Orders").snapshots();
  }

  // Mark order as Delivered in top-level Admin collection
  Future<void> updateAdminOrder(String id) async {
    await FirebaseFirestore.instance.collection("Orders").doc(id).update({
      "Status": "Delivered",
    });
  }

  // Mark order as Delivered in the user's specific sub-collection
  Future<void> updateUserOrder(String userId, String orderId) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("Orders")
        .doc(orderId)
        .update({"Status": "Delivered"});
  }

  // Save order to the specific user's sub-collection
  Future<void> addUserOrderDetails(
    Map<String, dynamic> userOrderMap,
    String userId,
    String orderId,
  ) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("Orders")
        .doc(orderId)
        .set(userOrderMap);
  }

  // Save order to top-level collection for Admin dashboard
  Future<void> addAdminOrderDetails(
    Map<String, dynamic> userOrderMap,
    String orderId,
  ) async {
    await FirebaseFirestore.instance
        .collection("Orders")
        .doc(orderId)
        .set(userOrderMap);
  }

  // Fetch real-time Stream of orders for a specific user
  Future<Stream<QuerySnapshot>> getUserOrders(String id) async {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .collection("Orders")
        .snapshots();
  }

  // --- CANCELLATION MANAGEMENT ---

  // Request order cancellation (User side)
  Future<void> requestOrderCancellation(
    String userId,
    String orderDocId,
    Map<String, dynamic> cancelData,
  ) async {
    // 1. Update status in User's Order document
    await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("Orders")
        .doc(orderDocId)
        .update({"Status": "Cancellation Requested"});

    // 2. Update status in Admin Orders collection
    await FirebaseFirestore.instance
        .collection("Orders")
        .doc(orderDocId)
        .update({"Status": "Cancellation Requested"});

    // 3. Create entry in a dedicated Cancellation Requests collection
    await FirebaseFirestore.instance
        .collection("CancellationRequests")
        .doc(orderDocId)
        .set(cancelData);
  }

  // Admin action: Approve or Reject Cancellation
  Future<void> handleCancellationRequest({
    required String orderDocId,
    required String userId,
    required bool approve,
  }) async {
    String newStatus = approve ? "Cancelled" : "On the way";

    // Update User Order document
    await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("Orders")
        .doc(orderDocId)
        .update({"Status": newStatus});

    // Update Admin Order document
    await FirebaseFirestore.instance
        .collection("Orders")
        .doc(orderDocId)
        .update({"Status": newStatus});

    // Update CancellationRequests document
    await FirebaseFirestore.instance
        .collection("CancellationRequests")
        .doc(orderDocId)
        .update({
          "requestStatus": approve ? "Approved" : "Rejected",
          "processedAt": FieldValue.serverTimestamp(),
        });
  }
}
