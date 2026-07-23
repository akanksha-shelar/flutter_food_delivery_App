import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery_app/model/burger_model.dart';
import 'package:food_delivery_app/model/category_model.dart';
import 'package:food_delivery_app/model/pizza_model.dart';
import 'package:food_delivery_app/pages/detail_page.dart';
import 'package:food_delivery_app/service/burger_data.dart';
import 'package:food_delivery_app/service/category_data.dart';
import 'package:food_delivery_app/service/pizza_data.dart';
import 'package:food_delivery_app/service/shared_pref.dart';
import 'package:food_delivery_app/service/widget_support.dart';
import 'package:food_delivery_app/service/database.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<CategoryModel> categories = [];
  List<PizzaModel> pizza = [];
  List<BurgerModel> burger = [];
  String track = "0";

  // Dynamic User Profile Details
  String userName = "Loading...";
  String userPhone = "Loading...";
  String userAddress = "Loading...";

  TextEditingController searchcontroller = TextEditingController();
  List queryResultSet = [];
  List tempSearchStore = [];
  bool search = false;

  @override
  void initState() {
    super.initState();
    categories = getCategories();
    pizza = getPizza();
    burger = getBurger();
    _loadUserProfile();
  }

  // Load User details from local storage or Firestore
  Future<void> _loadUserProfile() async {
    String? name = await SharedpreferenceHelper().getUserName();
    String? phone = await SharedpreferenceHelper().getUserPhone();
    String? address = await SharedpreferenceHelper().getUserAddress();

    if (name != null && name.isNotEmpty && phone != null) {
      if (mounted) {
        setState(() {
          userName = name;
          userPhone = phone;
          userAddress = (address != null && address.isNotEmpty)
              ? address
              : "No Address Set";
        });
      }
    } else {
      _fetchUserDataFromFirestore();
    }
  }

  Future<void> _fetchUserDataFromFirestore() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot snapshot = await DatabaseMethods().getUserDetails(
          currentUser.uid,
        );

        if (snapshot.exists) {
          Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
          if (data != null) {
            if (mounted) {
              setState(() {
                userName =
                    data['Name'] ?? "User_${currentUser.uid.substring(0, 5)}";
                userPhone =
                    data['Phone'] ?? currentUser.phoneNumber ?? "No Phone Set";
                userAddress = data['Address'] ?? "No Address Set";
              });
            }
            // Save locally for immediate future loads
            await SharedpreferenceHelper().saveUserName(userName);
            await SharedpreferenceHelper().saveUserPhone(userPhone);
            await SharedpreferenceHelper().saveUserAddress(userAddress);
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading user profile in Home: $e");
    }
  }

  // Optimized Search Logic
  void initiateSearch(String value) {
    String cleanQuery = value.trim();

    if (cleanQuery.isEmpty) {
      setState(() {
        queryResultSet = [];
        tempSearchStore = [];
        search = false;
      });
      return;
    }

    setState(() {
      search = true;
    });

    String capitalizedValue =
        cleanQuery.substring(0, 1).toUpperCase() + cleanQuery.substring(1);

    if (queryResultSet.isEmpty && cleanQuery.length == 1) {
      DatabaseMethods().search(cleanQuery).then((QuerySnapshot docs) {
        queryResultSet = [];
        for (int i = 0; i < docs.docs.length; ++i) {
          queryResultSet.add(docs.docs[i].data());
        }
        _filterSearchResults(capitalizedValue);
      });
    } else {
      _filterSearchResults(capitalizedValue);
    }
  }

  void _filterSearchResults(String query) {
    List newTempStore = [];
    for (var element in queryResultSet) {
      if (element['Name'] != null &&
          element['Name'].toString().toLowerCase().contains(
            query.toLowerCase(),
          )) {
        newTempStore.add(element);
      }
    }
    setState(() {
      tempSearchStore = newTempStore;
    });
  }

  // Display Profile Details Dialog
  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: const Row(
            children: [
              Icon(Icons.person_pin, color: Color(0xffef2b39), size: 30),
              SizedBox(width: 10),
              Text("User Details"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person, color: Color(0xffef2b39)),
                title: const Text("Name"),
                subtitle: Text(userName),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.phone, color: Color(0xffef2b39)),
                title: const Text("Phone Number"),
                subtitle: Text(userPhone),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.location_on,
                  color: Color(0xffef2b39),
                ),
                title: const Text("Address"),
                subtitle: Text(userAddress),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Close",
                style: TextStyle(
                  color: Color(0xffef2b39),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    searchcontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.only(left: 20.0, top: 40.0),
        child: Column(
          children: [
            // Header Row with Logo, Welcome Text, Profile Icon & Name
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      "images/logo.png",
                      height: 80,
                      width: 110,
                      fit: BoxFit.contain,
                    ),
                    Text(
                      "Order your favourite food!",
                      style: AppWidget.SimpleTextFieldStyle(),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: GestureDetector(
                    onTap: _showProfileDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFececf8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xffef2b39),
                            radius: 18,
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30.0),

            // Search Bar
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(left: 10.0),
                    margin: const EdgeInsets.only(right: 20.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFececf8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: searchcontroller,
                      onChanged: (value) {
                        initiateSearch(value);
                      },
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Search food item...",
                        suffixIcon: searchcontroller.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  searchcontroller.clear();
                                  initiateSearch("");
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 10.0),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xffef2b39),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 30.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),

            // Categories List
            SizedBox(
              height: 70,
              child: ListView.builder(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return CategoryTile(
                    categories[index].name!,
                    categories[index].image!,
                    index.toString(),
                  );
                },
              ),
            ),
            const SizedBox(height: 10.0),

            // Dynamic Grid Items or Search View
            Expanded(
              child: search
                  ? Container(
                      margin: const EdgeInsets.only(right: 10.0),
                      child: tempSearchStore.isEmpty
                          ? const Center(child: Text("No items found."))
                          : GridView.builder(
                              padding: EdgeInsets.zero,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.69,
                                    mainAxisSpacing: 20.0,
                                    crossAxisSpacing: 15.0,
                                  ),
                              itemCount: tempSearchStore.length,
                              itemBuilder: (context, index) {
                                var element = tempSearchStore[index];
                                return foodTile(
                                  element['Name'] ?? "",
                                  element['Image'] ?? "images/logo.png",
                                  element['Price']?.toString() ?? "0",
                                  detail: element['Detail'] ?? "",
                                );
                              },
                            ),
                    )
                  : track == "0"
                  ? Container(
                      margin: const EdgeInsets.only(right: 10.0),
                      child: GridView.builder(
                        padding: EdgeInsets.zero,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.69,
                              mainAxisSpacing: 20.0,
                              crossAxisSpacing: 15.0,
                            ),
                        itemCount: pizza.length,
                        itemBuilder: (context, index) {
                          return foodTile(
                            pizza[index].name!,
                            pizza[index].image!,
                            pizza[index].price!,
                          );
                        },
                      ),
                    )
                  : track == "1"
                  ? Container(
                      margin: const EdgeInsets.only(right: 10.0),
                      child: GridView.builder(
                        padding: EdgeInsets.zero,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.69,
                              mainAxisSpacing: 20.0,
                              crossAxisSpacing: 15.0,
                            ),
                        itemCount: burger.length,
                        itemBuilder: (context, index) {
                          return foodTile(
                            burger[index].name!,
                            burger[index].image!,
                            burger[index].price!,
                          );
                        },
                      ),
                    )
                  : Container(),
            ),
          ],
        ),
      ),
    );
  }

  Widget foodTile(
    String name,
    String image,
    String price, {
    String detail = "",
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 20.0),
      padding: const EdgeInsets.only(left: 10.0, top: 10.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black38),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: image.startsWith("http")
                ? Image.network(
                    image,
                    height: 110,
                    width: 150,
                    fit: BoxFit.contain,
                  )
                : Image.asset(
                    image,
                    height: 110,
                    width: 150,
                    fit: BoxFit.contain,
                  ),
          ),
          Text(name, style: AppWidget.boldTextFieldStyle()),
          Text("\$$price", style: AppWidget.priceTextFieldStyle()),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailPage(
                        image: image,
                        name: name,
                        price: price,
                        detail: detail,
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 50,
                  width: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xffef2b39),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 30.0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget CategoryTile(String name, String image, String categoryindex) {
    return GestureDetector(
      onTap: () {
        track = categoryindex;
        search = false;
        searchcontroller.clear();
        setState(() {});
      },
      child: track == categoryindex && !search
          ? Container(
              margin: const EdgeInsets.only(right: 20.0, bottom: 10.0),
              child: Material(
                elevation: 3.0,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                  decoration: BoxDecoration(
                    color: const Color(0xffef2b39),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        image,
                        height: 50,
                        width: 50,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(width: 10.0),
                      Text(name, style: AppWidget.whiteTextFieldStyle()),
                    ],
                  ),
                ),
              ),
            )
          : Container(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              margin: const EdgeInsets.only(right: 20.0, bottom: 10.0),
              decoration: BoxDecoration(
                color: const Color(0xFFececf8),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Image.asset(image, height: 50, width: 50, fit: BoxFit.cover),
                  const SizedBox(width: 10.0),
                  Text(name, style: AppWidget.SimpleTextFieldStyle()),
                ],
              ),
            ),
    );
  }
}
