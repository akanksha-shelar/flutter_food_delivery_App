import 'package:flutter/material.dart';
import 'package:food_delivery_app/service/database.dart';
import 'package:food_delivery_app/service/widget_support.dart';

class AllOrders extends StatefulWidget {
  const AllOrders({super.key});

  @override
  State<AllOrders> createState() => _AllOrdersState();
}

class _AllOrdersState extends State<AllOrders> {
  Stream? orderStream;

  Future<void> getontheload() async {
    orderStream = DatabaseMethods().getAdminOrders();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getontheload();
  }

  Widget allOrders() {
    return StreamBuilder(
      stream: orderStream,
      builder: (context, AsyncSnapshot snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: snapshot.data.docs.length,
                itemBuilder: (context, index) {
                  var ds = snapshot.data.docs[index];
                  Map<String, dynamic> data = ds.data() as Map<String, dynamic>;

                  String status = data["Status"] ?? "Processing";
                  bool isCancellationRequested =
                      status == "Cancellation Requested";

                  return Container(
                    margin: const EdgeInsets.only(
                      left: 20.0,
                      right: 20.0,
                      bottom: 20.0,
                    ),
                    child: Material(
                      elevation: 3.0,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(12.0),
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: Color(0xFFef2b39),
                                ),
                                const SizedBox(width: 10.0),
                                Expanded(
                                  child: Text(
                                    data['Address'] ?? "No Address",
                                    style: AppWidget.SimpleTextFieldStyle(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            Row(
                              children: [
                                Image.asset(
                                  data['FoodImage'] ?? 'images/logo.png',
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                    Icons.fastfood,
                                    size: 50,
                                    color: Color(0xFFef2b39),
                                  ),
                                ),
                                const SizedBox(width: 15.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data["FoodName"] ?? "",
                                        style: AppWidget.boldTextFieldStyle(),
                                      ),
                                      const SizedBox(height: 5.0),
                                      Text(
                                        "Qty: ${data["Quantity"]} | Total: \$${data["Total"]}",
                                      ),
                                      Text("User: ${data["Name"] ?? "User"}"),
                                      const SizedBox(height: 5.0),
                                      // Real-time Status Banner
                                      Text(
                                        "$status!",
                                        style: TextStyle(
                                          color: isCancellationRequested
                                              ? Colors.orange.shade800
                                              : const Color(0xffef2b39),
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 10.0),

                                      // Admin Options for Cancellation Handling
                                      if (isCancellationRequested) ...[
                                        Row(
                                          children: [
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                              ),
                                              onPressed: () async {
                                                await DatabaseMethods()
                                                    .handleCancellationRequest(
                                                  orderDocId: ds.id,
                                                  userId: data["Id"],
                                                  approve: true,
                                                );
                                              },
                                              child: const Text(
                                                "Approve",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8.0),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                              ),
                                              onPressed: () async {
                                                await DatabaseMethods()
                                                    .handleCancellationRequest(
                                                  orderDocId: ds.id,
                                                  userId: data["Id"],
                                                  approve: false,
                                                );
                                              },
                                              child: const Text(
                                                "Reject",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ] else if (status != "Cancelled" &&
                                          status != "Delivered") ...[
                                        GestureDetector(
                                          onTap: () async {
                                            await DatabaseMethods()
                                                .updateAdminOrder(ds.id);
                                            await DatabaseMethods()
                                                .updateUserOrder(
                                              data["Id"],
                                              ds.id,
                                            );
                                          },
                                          child: Container(
                                            width: 100,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Colors.black,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Center(
                                              child: Text(
                                                "Delivered",
                                                style: AppWidget
                                                    .whiteTextFieldStyle(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
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
              )
            : Container();
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
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
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
                  SizedBox(width: MediaQuery.of(context).size.width / 6),
                  Text("All Orders", style: AppWidget.HeadlineTextFieldStyle()),
                ],
              ),
            ),
            const SizedBox(height: 20.0),
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
                child: allOrders(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
