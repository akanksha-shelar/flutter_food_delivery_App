import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:food_delivery_app/pages/order.dart'; // Adjust path if necessary
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
  String? id, name, email, wallet, address, phone;
  TextEditingController addresscontroller = TextEditingController();

  // Razorpay Instance
  late Razorpay _razorpay;

  // App Theme Colors
  final Color primaryRed = const Color(0xFFEF2B39);
  final Color lightBgColor = const Color(0xFFECECF8);

  getontheload() async {
    id = await SharedpreferenceHelper().getUserId();
    name = await SharedpreferenceHelper().getUserName();
    email = await SharedpreferenceHelper().getUserEmail();
    wallet = await SharedpreferenceHelper().getUserWallet();
    address = await SharedpreferenceHelper().getUserAddress();
    phone = await SharedpreferenceHelper().getUserPhone();

    // Fallback: Fetch missing email/phone from Firestore
    if (id != null &&
        (phone == null || phone!.isEmpty || email == null || email!.isEmpty)) {
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
      QuerySnapshot snapshot = await DatabaseMethods().getUserWalletbyemail(
        email!,
      );
      if (snapshot.docs.isNotEmpty) {
        var data = snapshot.docs.first.data() as Map<String, dynamic>;
        wallet = data["Wallet"]?.toString() ?? "0";
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
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    placeOrder(paymentMethod: "Razorpay (Card/UPI)");
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: primaryRed,
        content: Text("Payment Failed: ${response.message ?? 'Unknown Error'}"),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.blue,
        content: Text("External Wallet Selected: ${response.walletName}"),
      ),
    );
  }

  void openRazorpayCheckout(String amount) async {
    int enteredAmount = int.tryParse(amount) ?? 0;
    if (enteredAmount <= 0) return;

    // Fetch latest user details if needed
    if ((phone == null || phone!.isEmpty) && id != null) {
      DocumentSnapshot userDoc = await DatabaseMethods().getUserDetails(id!);
      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>?;
        phone = data?["Phone"]?.toString();
        email ??= data?["Email"]?.toString();
      }
    }

    // Clean phone number for Razorpay prefill
    String cleanPhone = '';
    if (phone != null && phone!.isNotEmpty) {
      String digitsOnly = phone!.replaceAll(RegExp(r'\D'), '');
      if (digitsOnly.length > 10 && digitsOnly.startsWith('91')) {
        cleanPhone = digitsOnly.substring(digitsOnly.length - 10);
      } else {
        cleanPhone = digitsOnly;
      }
    }

    var options = {
      'key': razorpayKey,
      'amount': enteredAmount * 100, // Paise conversion
      'name': 'Food Delivery App',
      'description': 'Order Payment for ${widget.name}',
      'timeout': 300,
      'prefill': {'contact': cleanPhone, 'email': email ?? ''},
      'readonly': {'contact': true, 'email': false},
      'external': {
        'wallets': ['paytm'],
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Error opening Razorpay checkout: $e");
    }
  }

  // --- Order Placement Function ---
  Future<void> placeOrder({required String paymentMethod}) async {
    if (id == null) return;

    String orderId = randomAlphaNumeric(10);
    Map<String, dynamic> userOrderMap = {
      "Name": name,
      "Id": id,
      "Quantity": quantity.toString(),
      "Total": totalprice.toString(),
      "Email": email,
      "FoodName": widget.name,
      "FoodImage": widget.image,
      "OrderId": orderId,
      "Status": "Pending",
      "PaymentMethod": paymentMethod,
      "Address": address,
      "TimeStamp": DateTime.now().toIso8601String(),
    };

    // Save transaction history
    await DatabaseMethods().addUserTransaction({
      "Amount": totalprice.toString(),
      "Type": "Debit",
      "Description": "Order Payment (${widget.name}) via $paymentMethod",
      "TimeStamp": DateTime.now().toIso8601String(),
    }, id!);

    // Save Order Details to User and Admin Nodes
    await DatabaseMethods().addUserOrderDetails(userOrderMap, id!, orderId);
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
  }

  // --- Insufficient Balance Dialog ---
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
                    onTap: () async {
                      if (address == null || address!.trim().isEmpty) {
                        openBox();
                        return;
                      }

                      // Fetch latest wallet balance directly from Firestore
                      await fetchLiveWallet();

                      int currentWalletBalance =
                          int.tryParse(wallet ?? '0') ?? 0;

                      if (currentWalletBalance >= totalprice) {
                        // 1. Deduct amount from Firestore using dedicated method
                        await DatabaseMethods().deductUserWallet(
                          totalprice,
                          id!,
                        );

                        // 2. Save new remaining balance locally
                        int newBalance = currentWalletBalance - totalprice;
                        await SharedpreferenceHelper().saveUserWallet(
                          newBalance.toString(),
                        );

                        // 3. Complete order placement
                        await placeOrder(paymentMethod: "Wallet");
                      } else {
                        showInsufficientBalanceDialog(
                          totalprice,
                          currentWalletBalance,
                        );
                      }
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width / 1.8,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: primaryRed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "ORDER NOW",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.0,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
