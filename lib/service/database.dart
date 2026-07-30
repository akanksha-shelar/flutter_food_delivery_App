import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===========================================================================
  // 1. SEARCH & FOOD ITEMS CATALOG
  // ===========================================================================

  /// Fetch all food items from Firestore for client-side matching
  Future<QuerySnapshot> getAllFoodItems() async {
    return await _firestore.collection("Items").get();
  }

  /// Legacy search fallback method
  Future<QuerySnapshot> search(String searchQuery) async {
    return await getAllFoodItems();
  }

  /// Add new food item to catalog (Admin)
  Future<void> addFoodItem(Map<String, dynamic> itemData, String id) async {
    await _firestore.collection("Items").doc(id).set(itemData);
  }

  /// Update food item details (Admin)
  Future<void> updateFoodItem(
      String id, Map<String, dynamic> updateData) async {
    await _firestore.collection("Items").doc(id).update(updateData);
  }

  /// Delete food item from catalog (Admin)
  Future<void> deleteFoodItem(String id) async {
    await _firestore.collection("Items").doc(id).delete();
  }

  // ===========================================================================
  // 2. USER & ADMIN PROFILE MANAGEMENT
  // ===========================================================================

  /// Stream real-time snapshot of all client users (Admin View)
  Stream<QuerySnapshot> getAllUsers() {
    return _firestore.collection("users").snapshots();
  }

  /// Save new user profile upon registration (Client)
  Future<void> addUserDetails(
      Map<String, dynamic> userInfoMap, String id) async {
    await _firestore.collection("users").doc(id).set(userInfoMap);
  }

  /// Save or update Admin details using Firebase Auth UID (Admin)
  Future<void> addAdminDetails(
      Map<String, dynamic> adminInfoMap, String uid) async {
    await _firestore.collection("Admin").doc(uid).set(adminInfoMap);
  }

  /// Get user profile document by UID
  Future<DocumentSnapshot> getUserDetails(String id) async {
    return await _firestore.collection("users").doc(id).get();
  }

  /// Update user profile details
  Future<void> updateUserProfile(
      String id, Map<String, dynamic> updateData) async {
    await _firestore.collection("users").doc(id).update(updateData);
  }

  /// Update or Insert user record by phone number if UID is missing
  Future<void> updateOrInsertUserByPhone({
    required String phone,
    required String name,
    required String address,
    String? email,
  }) async {
    QuerySnapshot query = await _firestore
        .collection("users")
        .where("Phone", isEqualTo: phone)
        .get();

    if (query.docs.isNotEmpty) {
      String docId = query.docs.first.id;
      await _firestore.collection("users").doc(docId).update({
        "Name": name,
        "Address": address,
        if (email != null && email.isNotEmpty) "Email": email,
      });
    } else {
      await _firestore.collection("users").add({
        "Phone": phone,
        "Name": name,
        "Address": address,
        "Email": email ?? "",
        "Wallet": "0",
      });
    }
  }

  /// Delete user profile document (Admin or Self)
  Future<void> deleteUser(String id) async {
    await _firestore.collection("users").doc(id).delete();
  }

  /// Query user profile by email address
  Future<QuerySnapshot> getUserWalletbyemail(String email) async {
    return await _firestore
        .collection("users")
        .where("Email", isEqualTo: email)
        .get();
  }

  // ===========================================================================
  // 3. WALLET MANAGEMENT
  // ===========================================================================

  /// Update user wallet balance (supports string balance overwrite or integer increments)
  Future<void> updateUserWallet(dynamic amount, String id) async {
    if (amount is String) {
      await _firestore.collection("users").doc(id).update({
        "Wallet": amount,
      });
    } else if (amount is int) {
      await _firestore.collection("users").doc(id).update({
        "Wallet": FieldValue.increment(amount),
      });
    }
  }

  /// Deduct balance safely using FieldValue.increment
  Future<void> deductUserWallet(int orderAmount, String userId) async {
    if (orderAmount <= 0) return;

    await _firestore.collection("users").doc(userId).update({
      "Wallet": FieldValue.increment(-orderAmount),
    });
  }

  // ===========================================================================
  // 4. TRANSACTIONS MANAGEMENT
  // ===========================================================================

  /// Add transaction log entry into user's sub-collection
  Future<void> addUserTransaction(
      Map<String, dynamic> transactionMap, String id) async {
    await _firestore
        .collection("users")
        .doc(id)
        .collection("Transactions")
        .add(transactionMap);
  }

  /// Stream user transaction history ordered by timestamp descending
  Stream<QuerySnapshot> getUserTransactions(String id) {
    return _firestore
        .collection("users")
        .doc(id)
        .collection("Transactions")
        .orderBy("TimeStamp", descending: true)
        .snapshots();
  }

  // ===========================================================================
  // 5. ORDER MANAGEMENT
  // ===========================================================================

  /// Stream all orders from top-level Orders collection (Admin View)
  Stream<QuerySnapshot> getAdminOrders() {
    return _firestore.collection("Orders").snapshots();
  }

  /// Stream all orders across all subcollections via Collection Group
  Stream<QuerySnapshot> getAllUserOrdersSubcollections() {
    return _firestore.collectionGroup("Orders").snapshots();
  }

  /// Update order status to "Delivered" in global collection
  Future<void> updateAdminOrder(String id) async {
    await _firestore.collection("Orders").doc(id).update({
      "Status": "Delivered",
    });
  }

  /// Update order status to "Delivered" in user sub-collection
  Future<void> updateUserOrder(String userId, String orderId) async {
    if (userId.isEmpty) return;
    await _firestore
        .collection("users")
        .doc(userId)
        .collection("Orders")
        .doc(orderId)
        .update({"Status": "Delivered"});
  }

  /// Save new order details under user's sub-collection
  Future<void> addUserOrderDetails(
    Map<String, dynamic> userOrderMap,
    String userId,
    String orderId,
  ) async {
    await _firestore
        .collection("users")
        .doc(userId)
        .collection("Orders")
        .doc(orderId)
        .set(userOrderMap);
  }

  /// Save new order details in top-level collection for global access
  Future<void> addAdminOrderDetails(
    Map<String, dynamic> userOrderMap,
    String orderId,
  ) async {
    await _firestore.collection("Orders").doc(orderId).set(userOrderMap);
  }

  /// Stream orders for a specific user client
  Stream<QuerySnapshot> getUserOrders(String id) {
    return _firestore
        .collection("users")
        .doc(id)
        .collection("Orders")
        .snapshots();
  }

  // ===========================================================================
  // 6. CANCELLATION REQUESTS & ATOMIC REFUNDS (BATCH WRITES)
  // ===========================================================================

  /// Client initiates cancellation request
  Future<void> requestOrderCancellation(
    String userId,
    String orderDocId,
    Map<String, dynamic> cancelData,
  ) async {
    WriteBatch batch = _firestore.batch();

    // 1. Update status in User subcollection
    if (userId.isNotEmpty) {
      DocumentReference userOrderRef = _firestore
          .collection("users")
          .doc(userId)
          .collection("Orders")
          .doc(orderDocId);
      batch.update(userOrderRef, {"Status": "Cancellation Requested"});
    }

    // 2. Update status in global Admin collection
    DocumentReference globalOrderRef =
        _firestore.collection("Orders").doc(orderDocId);
    batch.update(globalOrderRef, {"Status": "Cancellation Requested"});

    // 3. Record entry in CancellationRequests collection
    DocumentReference cancelReqRef =
        _firestore.collection("CancellationRequests").doc(orderDocId);
    batch.set(cancelReqRef, cancelData);

    await batch.commit();
  }

  /// Admin approves or rejects cancellation request atomically
  Future<void> handleCancellationRequest({
    required String orderDocId,
    required String? userId,
    required bool approve,
    int? refundAmount,
  }) async {
    WriteBatch batch = _firestore.batch();
    String newStatus = approve ? "Cancelled" : "Processing";

    // 1. Update Global Order document
    DocumentReference globalOrderRef =
        _firestore.collection("Orders").doc(orderDocId);
    batch.update(globalOrderRef, {"Status": newStatus});

    // 2. Update Cancellation Request Document
    DocumentReference cancelReqRef =
        _firestore.collection("CancellationRequests").doc(orderDocId);
    batch.set(
        cancelReqRef,
        {
          "requestStatus": approve ? "Approved" : "Rejected",
          "processedAt": FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true));

    // 3. Update User Sub-collection & Issue Wallet Refund if applicable
    if (userId != null && userId.isNotEmpty) {
      DocumentReference userOrderRef = _firestore
          .collection("users")
          .doc(userId)
          .collection("Orders")
          .doc(orderDocId);
      batch.update(userOrderRef, {"Status": newStatus});

      if (approve && refundAmount != null && refundAmount > 0) {
        // Update user's wallet
        DocumentReference userRef = _firestore.collection("users").doc(userId);
        batch.update(userRef, {"Wallet": FieldValue.increment(refundAmount)});

        // Add refund transaction log entry
        DocumentReference transRef = _firestore
            .collection("users")
            .doc(userId)
            .collection("Transactions")
            .doc();
        batch.set(transRef, {
          "Amount": refundAmount.toString(),
          "TimeStamp": DateTime.now().millisecondsSinceEpoch.toString(),
          "Type": "Refund for Order #$orderDocId",
        });
      }
    }

    // Commit all operations as a single atomic transaction
    await batch.commit();
  }
}
