import 'package:flutter/material.dart';
import 'package:food_delivery_app/service/database.dart';
import 'package:food_delivery_app/service/shared_pref.dart';
import 'package:food_delivery_app/service/widget_support.dart';
import 'package:random_string/random_string.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  String? id, name, email, wallet, address;
  TextEditingController addresscontroller = TextEditingController();

  getontheload() async {
    id = await SharedpreferenceHelper().getUserId();
    name = await SharedpreferenceHelper().getUserName();
    email = await SharedpreferenceHelper().getUserEmail();
    wallet = await SharedpreferenceHelper().getUserWallet();
    address = await SharedpreferenceHelper().getUserAddress();

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
    totalprice = int.parse(widget.price);
    getontheload();
  }

  void makePayment(String amount) {
    // External Gateway Call (e.g., Razorpay / Stripe)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Redirecting to Payment Gateway for \$$amount..."),
      ),
    );
  }

  Future openBox() => showDialog(
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
                  "Add Address",
                  style: TextStyle(
                    color: Color(0xFF008080),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            const Text("Add Delivery Address"),
            const SizedBox(height: 10.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black38, width: 2.0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: addresscontroller,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Enter Address",
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  if (addresscontroller.text.trim().isNotEmpty) {
                    address = addresscontroller.text.trim();
                    await SharedpreferenceHelper().saveUserAddress(address!);
                    if (id != null) {
                      await DatabaseMethods().updateUserProfile(id!, {
                        "Address": address,
                      });
                    }
                    setState(() {});
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: const Text("Save"),
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
      body: Container(
        margin: const EdgeInsets.only(top: 50.0, left: 20.0, right: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: const Icon(
                Icons.arrow_back_ios_new_outlined,
                color: Colors.black,
              ),
            ),
            Image.asset(
              widget.image,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 2.5,
              fit: BoxFit.fill,
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
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.remove, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 20.0),
                Text(
                  quantity.toString(),
                  style: AppWidget.boldTextFieldStyle(),
                ),
                const SizedBox(width: 20.0),
                GestureDetector(
                  onTap: () {
                    quantity++;
                    totalprice = totalprice + int.parse(widget.price);
                    setState(() {});
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
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
              padding: const EdgeInsets.only(bottom: 40.0),
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
                        "\$$totalprice",
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

                      int currentWalletBalance =
                          int.tryParse(wallet ?? '0') ?? 0;

                      if (currentWalletBalance >= totalprice) {
                        int remainingWalletBalance =
                            currentWalletBalance - totalprice;

                        // Deduct wallet balance on Firestore
                        await DatabaseMethods().updateUserWallet(
                          remainingWalletBalance.toString(),
                          id!,
                        );

                        // Save update to local preference
                        await SharedpreferenceHelper().saveUserWallet(
                          remainingWalletBalance.toString(),
                        );

                        // Record transaction history
                        await DatabaseMethods().addUserTransaction({
                          "Amount": totalprice.toString(),
                          "Type": "Debit",
                          "Description": "Order Payment (${widget.name})",
                          "TimeStamp": DateTime.now().toIso8601String(),
                        }, id!);

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
                          "PaymentMethod": "Wallet",
                          "Address": address,
                        };

                        await DatabaseMethods().addUserOrderDetails(
                          userOrderMap,
                          id!,
                          orderId,
                        );
                        await DatabaseMethods().addAdminOrderDetails(
                          userOrderMap,
                          orderId,
                        );

                        setState(() {
                          wallet = remainingWalletBalance.toString();
                        });

                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.green,
                            content: Text(
                              "Order Placed Successfully using Wallet!",
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.orange,
                            content: Text(
                              "Insufficient wallet balance. Redirecting to Payment...",
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );

                        makePayment(totalprice.toString());
                      }
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width / 2,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            "ORDER NOW",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.0,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(width: 30.0),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.shopping_cart_outlined,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10.0),
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
