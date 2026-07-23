import 'package:flutter/material.dart';
import 'package:food_delivery_app/service/database.dart';
// Note: Ensure your widget_support.dart package path matches your project setup
import 'package:food_delivery_app/service/widget_support.dart';

class AllOrders extends StatefulWidget {
  const AllOrders({super.key});

  @override
  State<AllOrders> createState() => _AllOrdersState();
}

class _AllOrdersState extends State<AllOrders> {
  getontheload() async {
    orderStream = await DatabaseMethods().getAdminOrders();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getontheload();
  }

  Stream? orderStream;

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
                  return Container(
                    margin: const EdgeInsets.only(
                      left: 20.0,
                      right: 20.0,
                      bottom: 20.0,
                    ),
                    child: Material(
                      elevation: 3.0,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 5.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: Color(0xFFef2b39),
                                ), // Icon
                                const SizedBox(width: 10.0),
                                Text(
                                  ds('Address'),
                                  style: AppWidget.SimpleTextFieldStyle(),
                                ),
                              ],
                            ), // Row
                            const Divider(),
                            Row(
                              children: [
                                Image.asset(
                                  ds('FoodImage'),
                                  height: 120,
                                  width: 120,
                                  fit: BoxFit.cover,
                                ), // Image.asset
                                const SizedBox(width: 20.0),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ds("FoodName"),
                                      style: AppWidget.boldTextFieldStyle(),
                                    ),
                                    const SizedBox(height: 5.0),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.format_list_numbered,
                                          color: Color(0xFFef2b39),
                                        ),
                                        const SizedBox(width: 10.0),
                                        Text(
                                          ds("Quantity"),
                                          style: AppWidget.boldTextFieldStyle(),
                                        ),
                                        const SizedBox(width: 30.0),
                                        const Icon(
                                          Icons.monetization_on,
                                          color: Color(0xFFef2b39),
                                        ),
                                        const SizedBox(width: 10.0),
                                        Text(
                                          "\$" + ds["Total"],
                                          style: AppWidget.boldTextFieldStyle(),
                                        ),
                                      ],
                                    ), // Row
                                    const SizedBox(height: 5.0),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.person,
                                          color: Color(0xffef2b39),
                                        ),
                                        const SizedBox(width: 10.0),
                                        Text(
                                          ds["Name"],
                                          style:
                                              AppWidget.SimpleTextFieldStyle(),
                                        ),
                                      ],
                                    ), // Row
                                    const SizedBox(height: 5.0),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.mail,
                                          color: Color(0xffef2b39),
                                        ),
                                        const SizedBox(width: 10.0),
                                        Text(
                                          ds["Email"],
                                          style:
                                              AppWidget.SimpleTextFieldStyle(),
                                        ),
                                      ],
                                    ), // Row
                                    const SizedBox(height: 5.0),
                                    Text(
                                      ds["Status"] + "!",
                                      style: const TextStyle(
                                        color: Color(0xffef2b39),
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ), // Text
                                    const SizedBox(height: 5.0),
                                    GestureDetector(
                                      onTap: () async {
                                        await DatabaseMethods()
                                            .updateAdminOrder(ds.id);
                                        await DatabaseMethods().updateUserOrder(
                                          ds["Id"],
                                          ds.id,
                                        );
                                      },
                                      child: Container(
                                        width: 100,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ), // BoxDecoration
                                        child: Center(
                                          child: Text(
                                            "Delivered",
                                            style:
                                                AppWidget.whiteTextFieldStyle(),
                                          ),
                                        ),
                                      ),
                                    ), // Container
                                    const SizedBox(height: 10.0),
                                  ],
                                ), // Column
                              ],
                            ), // Row
                          ],
                        ), // Column
                      ), // Container
                    ), // Material
                  ); // Container
                },
              )
            : Container(); // fallback if no data
      },
    ); // StreamBuilder
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
              key: const Key('header_padding'),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xffef2b39),
                        borderRadius: BorderRadius.circular(30),
                      ), // BoxDecoration
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                      ), // Icon
                    ), // Container
                  ), // GestureDetector
                  SizedBox(width: MediaQuery.of(context).size.width / 6),
                  Text(
                    "All Orders",
                    style: AppWidget.HeadlineTextFieldStyle(),
                  ), // Text
                ],
              ), // Row
            ), // Padding
            const SizedBox(height: 20.0),
            Expanded(
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(
                  color: Color(0xFFececf8),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ), // BorderRadius.only
                ), // BoxDecoration
                child: Column(
                  children: [
                    const SizedBox(height: 20.0),
                    Container(
                      height: MediaQuery.of(context).size.height / 1.5,
                      child: allOrders(),
                    ), // SizedBox
                  ],
                ), // Column
              ), // Container
            ), // Expanded
          ],
        ),
      ), // Container
    ); // Scaffold
  }
}
