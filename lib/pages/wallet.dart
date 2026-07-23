import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery_app/service/database.dart';
import 'package:food_delivery_app/service/shared_pref.dart';
import 'package:food_delivery_app/service/widget_support.dart';

class Wallet extends StatefulWidget {
  const Wallet({super.key});

  @override
  State<Wallet> createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  String? wallet, id, email;
  TextEditingController amountcontroller = TextEditingController();

  getontheload() async {
    id = await SharedpreferenceHelper().getUserId();
    wallet = await SharedpreferenceHelper().getUserWallet();
    email = await SharedpreferenceHelper().getUserEmail();

    if (email != null && email!.isNotEmpty) {
      await fetchLiveWallet();
    }
    setState(() {});
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
    getontheload();
  }

  Future openEdit() => showDialog(
    context: context,
    builder: (context) => AlertDialog(
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Icon(Icons.cancel),
                ),
                const SizedBox(width: 60.0),
                const Text(
                  "Add Money",
                  style: TextStyle(
                    color: Color(0xFF008080),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            const Text("Amount"),
            const SizedBox(height: 10.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black38, width: 2.0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: amountcontroller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Enter Amount",
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (amountcontroller.text.isNotEmpty) {
                    makePayment(amountcontroller.text);
                  }
                },
                child: const Text("Pay"),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  void makePayment(String amount) async {
    int enteredAmount = int.tryParse(amount) ?? 0;
    if (enteredAmount <= 0 || id == null) return;

    int currentBalance = int.tryParse(wallet ?? '0') ?? 0;
    int updatedWallet = currentBalance + enteredAmount;

    // Update Firestore using integer for atomic increments
    await DatabaseMethods().updateUserWallet(enteredAmount, id!);

    // Save absolute updated balance locally
    await SharedpreferenceHelper().saveUserWallet(updatedWallet.toString());

    // Record transaction
    await DatabaseMethods().addUserTransaction({
      "Amount": enteredAmount.toString(),
      "Type": "Credit",
      "Description": "Wallet Top Up",
      "TimeStamp": DateTime.now().toIso8601String(),
    }, id!);

    setState(() {
      wallet = updatedWallet.toString();
    });

    amountcontroller.clear();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text("Successfully added \$$enteredAmount to wallet!"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.only(top: 50.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              elevation: 2.0,
              child: Container(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Center(
                  child: Text(
                    "Wallet",
                    style: AppWidget.HeadlineTextFieldStyle(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30.0),
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 10.0,
              ),
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(color: Color(0xFFF2F2F2)),
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
                        "\$" + (wallet ?? "0"),
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
              child: Text("Add money", style: AppWidget.boldTextFieldStyle()),
            ),
            const SizedBox(height: 10.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () => makePayment("100"),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE9E2E2)),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      "\$100",
                      style: AppWidget.SimpleTextFieldStyle(),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => makePayment("500"),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE9E2E2)),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      "\$500",
                      style: AppWidget.SimpleTextFieldStyle(),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => makePayment("1000"),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE9E2E2)),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      "\$1000",
                      style: AppWidget.SimpleTextFieldStyle(),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => makePayment("2000"),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE9E2E2)),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      "\$2000",
                      style: AppWidget.SimpleTextFieldStyle(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50.0),
            GestureDetector(
              onTap: () {
                openEdit();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20.0),
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: const Color(0xFF008080),
                  borderRadius: BorderRadius.circular(8),
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
      ),
    );
  }
}
