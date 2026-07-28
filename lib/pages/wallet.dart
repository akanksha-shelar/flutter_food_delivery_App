import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery_app/service/constant.dart';
import 'package:food_delivery_app/service/database.dart';
import 'package:food_delivery_app/service/shared_pref.dart';
import 'package:food_delivery_app/service/widget_support.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class Wallet extends StatefulWidget {
  const Wallet({super.key});

  @override
  State<Wallet> createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  String? wallet, id, email, phone;
  TextEditingController amountcontroller = TextEditingController();

  // Razorpay Instance
  late Razorpay _razorpay;

  // Primary Theme Red Color from UI Design
  final Color primaryRed = const Color(0xFFEF2B39);
  final Color lightBgColor = const Color(0xFFECECF8);

  getontheload() async {
    id = await SharedpreferenceHelper().getUserId();
    wallet = await SharedpreferenceHelper().getUserWallet();
    email = await SharedpreferenceHelper().getUserEmail();
    phone = await SharedpreferenceHelper().getUserPhone();

    // Fallback: If phone/email is empty, load directly from Firestore user doc
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

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    getontheload();

    // Initialize Razorpay listeners
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    amountcontroller.dispose();
    _razorpay.clear();
    super.dispose();
  }

  Future<void> openPaymentLink() async {
    if (razorpayPaymentLink.isNotEmpty) {
      final Uri uri = Uri.parse(razorpayPaymentLink);
      try {
        bool launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFFEF2B39),
              content: Text("Could not launch payment link"),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFEF2B39),
              content: Text("Error launching URL: $e"),
            ),
          );
        }
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (amountcontroller.text.isNotEmpty) {
      onPaymentSuccess(amountcontroller.text);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: primaryRed,
        content: Text("Payment Failed: ${response.message ?? 'Unknown Error'}"),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.blue,
        content: Text("External Wallet Selected: ${response.walletName}"),
      ),
    );
  }

  void openRazorpayCheckout(String amount) async {
    int enteredAmount = int.tryParse(amount) ?? 0;
    if (enteredAmount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: primaryRed,
            content: const Text("Please enter a valid amount"),
          ),
        );
      }
      return;
    }

    // Double check phone number from Firestore if local state is null/empty
    if ((phone == null || phone!.isEmpty) && id != null) {
      DocumentSnapshot userDoc = await DatabaseMethods().getUserDetails(id!);
      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>?;
        phone = data?["Phone"]?.toString();
        email ??= data?["Email"]?.toString();
      }
    }

    // Format phone to 10 digits for Indian standard format
    String cleanPhone = '';
    if (phone != null && phone!.isNotEmpty) {
      String digitsOnly = phone!.replaceAll(RegExp(r'\D'), '');
      if (digitsOnly.length > 10 && digitsOnly.startsWith('91')) {
        cleanPhone = digitsOnly.substring(digitsOnly.length - 10);
      } else {
        cleanPhone = digitsOnly;
      }
    }

    debugPrint("Passing contact to Razorpay: $cleanPhone");

    var options = {
      'key': razorpayKey,
      'amount': enteredAmount * 100, // Paise conversion
      'name': 'Food Delivery App',
      'description': 'Wallet Top Up',
      'config_id': paymentconfigid,
      'prefill': {'contact': cleanPhone, 'email': email ?? ''},
      'readonly': {'contact': true, 'email': false},
      'config': {
        'display': {
          'blocks': {
            'custom_methods': {
              'name': 'Pay via Card, Wallet, or UPI',
              'instruments': [
                {'method': 'card'},
                {'method': 'wallet'},
                {'method': 'upi'},
                {'method': 'netbanking'},
              ],
            },
          },
          'sequence': ['block.custom_methods'],
        },
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Error opening Razorpay checkout: $e");
    }
  }

  void onPaymentSuccess(String amount) async {
    int enteredAmount = int.tryParse(amount) ?? 0;
    if (enteredAmount <= 0 || id == null) return;

    int currentBalance = int.tryParse(wallet ?? '0') ?? 0;
    int updatedWallet = currentBalance + enteredAmount;

    await DatabaseMethods().updateUserWallet(updatedWallet.toString(), id!);
    await SharedpreferenceHelper().saveUserWallet(updatedWallet.toString());

    await DatabaseMethods().addUserTransaction({
      "Amount": enteredAmount.toString(),
      "Type": "Credit",
      "Description": "Wallet Top Up",
      "TimeStamp": DateTime.now().toIso8601String(),
    }, id!);

    amountcontroller.clear();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text("Successfully added ₹$enteredAmount to wallet!"),
      ),
    );
  }

  Future openEdit() => showDialog(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Add Money",
                  style: TextStyle(
                    color: Color(0xFFEF2B39),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Icon(Icons.cancel, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            const Text(
              "Amount (₹)",
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
                controller: amountcontroller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Enter Amount in ₹",
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
                onPressed: () {
                  String enteredText = amountcontroller.text.trim();
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                  if (enteredText.isNotEmpty) {
                    openRazorpayCheckout(enteredText);
                  }
                },
                child: const Text(
                  "Pay",
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

  void selectQuickAmount(String amount) {
    amountcontroller.text = amount;
    openRazorpayCheckout(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: id == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .doc(id)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  var data = snapshot.data!.data() as Map<String, dynamic>?;
                  wallet = data?["Wallet"]?.toString() ?? wallet ?? "0";

                  if (data?["Phone"] != null &&
                      (phone == null || phone!.isEmpty)) {
                    phone = data!["Phone"].toString();
                  }
                  if (data?["Email"] != null &&
                      (email == null || email!.isEmpty)) {
                    email = data!["Email"].toString();
                  }
                }

                return Container(
                  margin: const EdgeInsets.only(top: 50.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Back Arrow and Title
                      Material(
                        elevation: 2.0,
                        child: Container(
                          padding: const EdgeInsets.only(
                            bottom: 10.0,
                            left: 10.0,
                            right: 10.0,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: GestureDetector(
                                  onTap: () {
                                    if (Navigator.canPop(context)) {
                                      Navigator.pop(context);
                                    }
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
                              ),
                              Center(
                                child: Text(
                                  "Wallet",
                                  style: AppWidget.HeadlineTextFieldStyle(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30.0),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 15.0,
                          horizontal: 15.0,
                        ),
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(color: lightBgColor),
                        child: Row(
                          children: [
                            Image.asset(
                              "images/wallet.png",
                              height: 60,
                              width: 60,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(width: 20.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Your Wallet",
                                  style: AppWidget.SimpleTextFieldStyle(),
                                ),
                                const SizedBox(height: 5.0),
                                Text(
                                  "₹${wallet ?? "0"}",
                                  style: AppWidget.boldTextFieldStyle(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text(
                          "Add money",
                          style: AppWidget.boldTextFieldStyle(),
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: ["100", "500", "1000", "2000"].map((amt) {
                          return GestureDetector(
                            onTap: () => selectQuickAmount(amt),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: lightBgColor,
                                border: Border.all(
                                  color: const Color(0xFFE9E2E2),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "₹$amt",
                                style: AppWidget.SimpleTextFieldStyle(),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 50.0),
                      GestureDetector(
                        onTap: () => openEdit(),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20.0),
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                            color: primaryRed,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              "Add Money",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.0,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
