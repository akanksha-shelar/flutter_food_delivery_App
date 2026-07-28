import 'package:flutter/material.dart';
import 'package:food_delivery_app/service/database.dart';
import 'package:food_delivery_app/service/shared_pref.dart';
import 'package:food_delivery_app/service/widget_support.dart';

class Order extends StatefulWidget {
  final String? orderId;

  const Order({super.key, this.orderId});

  @override
  State<Order> createState() => _OrderState();
}

class _OrderState extends State<Order> {
  String? id;
  Stream? orderStream;

  final Color primaryRed = const Color(0xFFFA3E4C);
  final Color lightBgColor = const Color(0xFFEFEFF7);

  Future<void> getSharedPref() async {
    id = await SharedpreferenceHelper().getUserId();
  }

  Future<void> getOnLoad() async {
    await getSharedPref();
    if (id != null && id!.isNotEmpty) {
      orderStream = await DatabaseMethods().getUserOrders(id!);
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    getOnLoad();
  }

  // Confirmation dialog before sending cancellation request
  void showCancelConfirmationDialog(
    String orderDocId,
    Map<String, dynamic> orderData,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Cancel Order"),
          content: const Text(
            "Are you sure you want to request cancellation for this order?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text("No", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryRed),
              onPressed: () async {
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                await submitCancellationRequest(orderDocId, orderData);
              },
              child: const Text(
                "Yes, Cancel",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> submitCancellationRequest(
    String orderDocId,
    Map<String, dynamic> orderData,
  ) async {
    if (id == null) return;

    Map<String, dynamic> cancelData = {
      "orderId": orderDocId,
      "userId": id,
      "foodName": orderData["FoodName"] ?? "Food Item",
      "total": orderData["Total"]?.toString() ?? "0",
      "userEmail": orderData["Email"] ?? "",
      "requestStatus": "Pending",
      "requestedAt": DateTime.now().toIso8601String(),
    };

    await DatabaseMethods().requestOrderCancellation(
      id!,
      orderDocId,
      cancelData,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cancellation request submitted successfully!"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Widget allOrders() {
    return StreamBuilder(
      stream: orderStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryRed));
        }

        if (!snapshot.hasData || snapshot.data.docs.isEmpty) {
          return const Center(
            child: Text(
              "No orders placed yet!",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          );
        }

        List docs = snapshot.data.docs;
        if (widget.orderId != null && widget.orderId!.isNotEmpty) {
          docs = docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return data["OrderId"] == widget.orderId ||
                doc.id == widget.orderId;
          }).toList();

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "Order not found!",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            );
          }
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 15.0, bottom: 20.0),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var ds = docs[index];
            Map<String, dynamic> data = ds.data() as Map<String, dynamic>;

            String foodImage = data["FoodImage"] ?? "";
            String foodName = data["FoodName"] ?? "Food Item";
            String address = data["Address"] ?? "No Address Provided";
            String quantity = data["Quantity"]?.toString() ?? "1";
            String total = data["Total"]?.toString() ?? "0";
            String status = data["Status"] ?? "Processing";

            // Status checks for actionable states
            bool isCancellationRequested = status == "Cancellation Requested";
            bool isCancelled = status == "Cancelled";
            bool isDelivered = status == "Delivered";

            // Order is eligible for cancellation if it is not already cancelled, requested, or delivered
            bool isEligibleForCancel =
                !isCancellationRequested && !isCancelled && !isDelivered;

            return Container(
              margin: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                bottom: 15.0,
              ),
              child: Material(
                elevation: 2.0,
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_on_outlined, color: primaryRed),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Text(
                              address,
                              style: AppWidget.SimpleTextFieldStyle(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20, thickness: 1),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: foodImage.startsWith("http")
                                ? Image.network(
                                    foodImage,
                                    height: 90,
                                    width: 90,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                          Icons.fastfood,
                                          size: 50,
                                          color: primaryRed,
                                        ),
                                  )
                                : Image.asset(
                                    foodImage.isNotEmpty
                                        ? foodImage
                                        : "images/logo.png",
                                    height: 90,
                                    width: 90,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                          Icons.fastfood,
                                          size: 50,
                                          color: primaryRed,
                                        ),
                                  ),
                          ),
                          const SizedBox(width: 15.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  foodName,
                                  style: AppWidget.boldTextFieldStyle(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8.0),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.format_list_numbered,
                                      color: primaryRed,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4.0),
                                    Text(
                                      quantity,
                                      style: AppWidget.boldTextFieldStyle(),
                                    ),
                                    const SizedBox(width: 16.0),
                                    Text(
                                      "₹$total",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: primaryRed,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8.0),
                                // Real-Time Dynamic Status
                                Text(
                                  status,
                                  style: TextStyle(
                                    color:
                                        isCancelled || isCancellationRequested
                                        ? Colors.orange.shade800
                                        : primaryRed,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                // Cancel Order Button UI & Actions
                                if (isEligibleForCancel)
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: primaryRed),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () =>
                                        showCancelConfirmationDialog(
                                          ds.id,
                                          data,
                                        ),
                                    child: Text(
                                      "Cancel Order",
                                      style: TextStyle(
                                        color: primaryRed,
                                        fontSize: 12,
                                      ),
                                    ),
                                  )
                                else if (isCancellationRequested)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: const Text(
                                      "Cancellation Pending Admin Approval",
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        margin: const EdgeInsets.only(top: 50.0),
        child: Column(
          children: [
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
                        widget.orderId != null ? "Order Details" : "Orders",
                        style: AppWidget.HeadlineTextFieldStyle(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10.0),
            Expanded(
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: lightBgColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: allOrders(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
