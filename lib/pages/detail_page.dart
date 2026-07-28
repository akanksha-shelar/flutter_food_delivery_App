import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart'; // Added Firebase Auth import
import 'package:flutter/material.dart';
import 'package:food_delivery_app/pages/order.dart';
import 'package:food_delivery_app/pages/wallet.dart';
import 'package:food_delivery_app/service/constant.dart';
import 'package:food_delivery_app/service/database.dart';
import 'package:food_delivery_app/service/shared_pref.dart';
import 'package:food_delivery_app/service/widget_support.dart';
import 'package:random_string/random_string.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class DetailPage extends StatefulWidget {
  final String image, name, detail, price;
  const DetailPage({
    super.key,
    required this.detail,
    required this.image,
    required this.name,
    required this.price,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  int quantity = 1;
  int totalprice = 0;
  bool isLoading = false;
  String? id, name, email, wallet, address, phone;
  final TextEditingController addresscontroller = TextEditingController();

  // Razorpay Instance
  late Razorpay _razorpay;

  // App Theme Colors
  final Color primaryRed = const Color(0xFFEF2B39);
  final Color lightBgColor = const Color(0xFFECECF8);

  getontheload() async {
    // 1. Verify Active Firebase Auth User Session
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      id = firebaseUser.uid;
    } else {
      id = await SharedpreferenceHelper().getUserId();
    }

    name = await SharedpreferenceHelper().getUserName();
    email = await SharedpreferenceHelper().getUserEmail();
    wallet = await SharedpreferenceHelper().getUserWallet();
    address = await SharedpreferenceHelper().getUserAddress();
    phone = await SharedpreferenceHelper().getUserPhone();

    // Fallback: Fetch missing email/phone from Firestore
    if (id != null &&
        (phone == null || phone!.isEmpty || email == null || email!.isEmpty)) {
      try {
        DocumentSnapshot userDoc = await DatabaseMethods().getUserDetails(id!);
        if (userDoc.exists) {
          var data = userDoc.data() as Map<String, dynamic>?;
          if (data != null) {
            phone ??= data["Phone"]?.toString();
            email ??= data["Email"]?.toString();

            if (phone != null && phone!.isNotEmpty) {
              await SharedpreferenceHelper().saveUserPhone(phone!);
            }
            if (email != null && email!.isNotEmpty) {
              await SharedpreferenceHelper().saveUserEmail(email!);
            }
          }
        }
      } catch (e) {
        debugPrint("Error fetching user details from Firestore: $e");
      }
    }

    if (email != null && email!.isNotEmpty) {
      await fetchLiveWallet();
    }
    if (mounted) {
      setState(() {});
    }
  }

  fetchLiveWallet() async {
    if (email != null) {
      try {
        QuerySnapshot snapshot = await DatabaseMethods().getUserWalletbyemail(
          email!,
        );
        if (snapshot.docs.isNotEmpty) {
          var data = snapshot.docs.first.data() as Map<String, dynamic>;
          wallet = data["Wallet"]?.toString() ?? "0";
        }
      } catch (e) {
        debugPrint("Error fetching wallet balance: $e");
      }
    }
  }

  @override
  void initState() {
    super.initState();
    totalprice = int.parse(widget.price);
    getontheload();

    // Initialize Razorpay
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    addresscontroller.dispose();
    _razorpay.clear();
    super.dispose();
  }

  // --- Razorpay Payment Callbacks ---
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    await placeOrder(paymentMethod: "Razorpay (Card/UPI)");
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: primaryRed,
          content: Text(
            "Payment Failed: ${response.message ?? 'Unknown Error'}",
          ),
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.blue,
          content: Text("External Wallet Selected: ${response.walletName}"),
        ),
      );
    }
  }

  void openRazorpayCheckout(String amount) async {
    int enteredAmount = int.tryParse(amount) ?? 0;
    if (enteredAmount <= 0) return;

    if ((phone == null || phone!.isEmpty) && id != null) {
      DocumentSnapshot userDoc = await DatabaseMethods().getUserDetails(id!);
      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>?;
        phone = data?["Phone"]?.toString();
        email ??= data?["Email"]?.toString();
      }
    }

    String cleanPhone = '';
    if (phone != null && phone!.isNotEmpty) {
      String digitsOnly = phone!.replaceAll(RegExp(r'\D'), '');
      if (digitsOnly.length > 10 && digitsOnly.startsWith('91')) {
        cleanPhone = digitsOnly.substring(digitsOnly.length - 10);
      } else {
        cleanPhone = digitsOnly;
      }
    }

    if (cleanPhone.isEmpty) {
      cleanPhone = '9999999999';
    }

    var options = {
      'key': razorpayKey,
      'amount': enteredAmount * 100,
      'name': 'Food Delivery App',
      'description': 'Order Payment for ${widget.name}',
      'timeout': 300,
      'prefill': {
        'contact': cleanPhone,
        'email': (email != null && email!.isNotEmpty)
            ? email
            : 'test@example.com',
      },
      'readonly': {'contact': true, 'email': false},
      'external': {
        'wallets': ['paytm'],
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      debugPrint("Error opening Razorpay checkout: $e");
    }
  }

  // --- Order Placement Function ---
  Future<void> placeOrder({required String paymentMethod}) async {
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      id = firebaseUser.uid;
    } else {
      id ??= await SharedpreferenceHelper().getUserId();
    }

    if (id == null || id!.isEmpty) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Authentication required. Please log in again."),
        ),
      );
      return;
    }

    String orderId = randomAlphaNumeric(10);
    Map<String, dynamic> userOrderMap = {
      "Name": name ?? "Guest",
      "Id": id,
      "Quantity": quantity.toString(),
      "Total": totalprice.toString(),
      "Email": email ?? "",
      "FoodName": widget.name,
      "FoodImage": widget.image,
      "OrderId": orderId,
      "Status": "Pending",
      "PaymentMethod": paymentMethod,
      "Address": address ?? "",
      "TimeStamp": DateTime.now().toIso8601String(),
    };

    try {
      // 1. Save Transaction to User Collection
      await DatabaseMethods().addUserTransaction({
        "Amount": totalprice.toString(),
        "Type": "Debit",
        "Description": "Order Payment (${widget.name}) via $paymentMethod",
        "TimeStamp": DateTime.now().toIso8601String(),
      }, id!);

      // 2. Save Order to User Subcollection
      await DatabaseMethods().addUserOrderDetails(userOrderMap, id!, orderId);

      // 3. Save Order to Admin / Global Collection
      await DatabaseMethods().addAdminOrderDetails(userOrderMap, orderId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Order Placed Successfully using $paymentMethod!",
            style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
        ),
      );

      // Redirect to Order Page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Order()),
      );
    } catch (e) {
      debugPrint("Error placing order in Firebase: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: primaryRed,
          content: Text("Permission Denied or Database Error: $e"),
        ),
      );
    }
  }

  // --- Process Payment and Checkout Logic ---
  Future<void> _processCheckout() async {
    setState(() => isLoading = true);

    await fetchLiveWallet();

    int currentWalletBalance = int.tryParse(wallet ?? '0') ?? 0;

    if (currentWalletBalance >= totalprice) {
      try {
        int newBalance = currentWalletBalance - totalprice;

        // Deduct balance in Firebase
        await DatabaseMethods().updateUserWallet(newBalance.toString(), id!);
        await SharedpreferenceHelper().saveUserWallet(newBalance.toString());

        // Save order in Firebase
        await placeOrder(paymentMethod: "Wallet");
      } catch (e) {
        if (mounted) setState(() => isLoading = false);
        debugPrint("Wallet deduction failed: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: primaryRed,
            content: Text("Wallet transaction failed: $e"),
          ),
        );
      }
    } else {
      if (mounted) setState(() => isLoading = false);
      showInsufficientBalanceDialog(totalprice, currentWalletBalance);
    }
  }

  void showAddressConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Confirm Address",
                style: TextStyle(
                  color: primaryRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await openBox();
                  if (mounted) {
                    showAddressConfirmationDialog();
                  }
                },
                icon: Icon(Icons.edit, size: 16, color: primaryRed),
                label: Text(
                  "Edit",
                  style: TextStyle(
                    color: primaryRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Please confirm your delivery address before placing order:",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: lightBgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on, color: primaryRed, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        (address != null && address!.trim().isNotEmpty)
                            ? address!
                            : "No address provided. Please tap Edit.",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                if (address == null || address!.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Please add a valid delivery address first.",
                      ),
                    ),
                  );
                  return;
                }
                Navigator.pop(context);
                _processCheckout();
              },
              child: const Text(
                "Confirm & Proceed",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void showInsufficientBalanceDialog(int requiredAmount, int currentBalance) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Insufficient Balance",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Your current wallet balance is ₹$currentBalance, but order total is ₹$requiredAmount.",
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 15),
              const Text(
                "How would you like to proceed?",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Wallet()),
                );
              },
              child: Text(
                "Add to Wallet",
                style: TextStyle(
                  color: primaryRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                setState(() => isLoading = true);
                openRazorpayCheckout(requiredAmount.toString());
              },
              child: const Text(
                "Pay with card/UPI",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future openBox() => showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Add Address",
                  style: TextStyle(
                    color: primaryRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.cancel, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            const Text(
              "Delivery Address",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black26, width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: addresscontroller,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Enter full address",
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 10,
                  ),
                ),
                onPressed: () async {
                  if (addresscontroller.text.trim().isNotEmpty) {
                    address = addresscontroller.text.trim();
                    await SharedpreferenceHelper().saveUserAddress(address!);
                    if (id != null) {
                      await DatabaseMethods().updateUserProfile(id!, {
                        "Address": address,
                      });
                    }
                    if (mounted) setState(() {});
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: const Text(
                  "Save",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        margin: const EdgeInsets.only(top: 50.0, left: 20.0, right: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: lightBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_outlined,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 10.0),
            Center(
              child: Image.asset(
                widget.image,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 2.5,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 15.0),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.name, style: AppWidget.boldTextFieldStyle()),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    if (quantity > 1) {
                      quantity--;
                      totalprice = totalprice - int.parse(widget.price);
                      setState(() {});
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: primaryRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.remove, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 15.0),
                Text(
                  quantity.toString(),
                  style: AppWidget.boldTextFieldStyle(),
                ),
                const SizedBox(width: 15.0),
                GestureDetector(
                  onTap: () {
                    quantity++;
                    totalprice = totalprice + int.parse(widget.price);
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: primaryRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            Text(
              widget.detail,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppWidget.SimpleTextFieldStyle(),
            ),
            const SizedBox(height: 30.0),
            Row(
              children: [
                Text("Delivery Time", style: AppWidget.boldTextFieldStyle()),
                const SizedBox(width: 25.0),
                const Icon(Icons.alarm, color: Colors.black54),
                const SizedBox(width: 5.0),
                Text("30 min", style: AppWidget.boldTextFieldStyle()),
              ],
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Price",
                        style: AppWidget.boldTextFieldStyle(),
                      ),
                      Text(
                        "₹$totalprice",
                        style: AppWidget.HeadlineTextFieldStyle(),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: isLoading
                        ? null
                        : () {
                            if (address == null || address!.trim().isEmpty) {
                              openBox();
                            } else {
                              showAddressConfirmationDialog();
                            }
                          },
                    child: Container(
                      width: MediaQuery.of(context).size.width / 1.8,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isLoading ? Colors.grey : primaryRed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "ORDER NOW",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.0,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          if (!isLoading) ...[
                            const SizedBox(width: 15.0),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.shopping_cart_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
