import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:food_delivery_app/pages/bottomnav.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:food_delivery_app/service/database.dart';
import 'package:food_delivery_app/service/shared_pref.dart';

class NameAddressPage extends StatefulWidget {
  final String phoneNumber;
  final String uid;

  const NameAddressPage({
    super.key,
    required this.phoneNumber,
    required this.uid,
  });

  @override
  State<NameAddressPage> createState() => _NameAddressPageState();
}

class _NameAddressPageState extends State<NameAddressPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  bool isLoading = false;
  bool isFetchingLocation = false;

  // Optimized Reverse Geocoding for real physical devices
  Future<void> _getCurrentLocation() async {
    setState(() => isFetchingLocation = true);

    try {
      // 1. Check if GPS service is enabled on the device
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Location services are disabled. Please enable GPS in device settings.",
              ),
            ),
          );
        }
        return;
      }

      // 2. Handle permissions cleanly
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Location permissions were denied."),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Location permissions permanently denied. Please enable them in device settings.",
              ),
            ),
          );
        }
        return;
      }

      // 3. Fetch Position with high accuracy and a 10-second timeout
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // 4. Reverse Geocoding (Coordinates to readable address)
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        List<String> addressParts = [
          if (place.street != null && place.street!.isNotEmpty) place.street!,
          if (place.subLocality != null && place.subLocality!.isNotEmpty)
            place.subLocality!,
          if (place.locality != null && place.locality!.isNotEmpty)
            place.locality!,
          if (place.administrativeArea != null &&
              place.administrativeArea!.isNotEmpty)
            place.administrativeArea!,
          if (place.postalCode != null && place.postalCode!.isNotEmpty)
            place.postalCode!,
        ];

        String fullAddress = addressParts.join(", ");

        if (mounted) {
          setState(() {
            addressController.text = fullAddress;
          });
        }
      }
    } catch (e) {
      log("Error fetching location: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to fetch location: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => isFetchingLocation = false);
      }
    }
  }

  void saveUserData() async {
    String name = nameController.text.trim();
    String address = addressController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your full name")),
      );
      return;
    }

    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter or select an address")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      Map<String, dynamic> userInfoMap = {
        "Name": name,
        "Address": address,
        "Phone": widget.phoneNumber,
        "Id": widget.uid,
        "Wallet": "0",
      };

      // 1. Save to Firebase
      await DatabaseMethods().addUserDetails(userInfoMap, widget.uid);

      // 2. Save to SharedPreferences
      await SharedpreferenceHelper().saveUserId(widget.uid);
      await SharedpreferenceHelper().saveUserName(name);
      await SharedpreferenceHelper().saveUserAddress(address);

      setState(() => isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile setup complete!")),
        );

        // Clear stack and open Home page
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const BottomNav()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to save data: $e")));
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Setup Profile"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.badge_outlined,
              size: 80,
              color: Color(0xFFEF2B39),
            ),
            const SizedBox(height: 15),
            const Text(
              "User Information",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              "Please provide your name and delivery address to finish registration.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 30),

            // 1. Full Name Input Field
            TextField(
              controller: nameController,
              keyboardType: TextInputType.name,
              decoration: InputDecoration(
                hintText: "John Doe",
                labelText: "Full Name",
                prefixIcon: const Icon(Icons.person, color: Color(0xFFEF2B39)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFEF2B39),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Full Address Input Field & Live GPS Picker Button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: addressController,
                  maxLines: 3,
                  keyboardType: TextInputType.streetAddress,
                  decoration: InputDecoration(
                    hintText: "Type flat no, street, locality & pincode...",
                    labelText: "Full Address",
                    prefixIcon: const Icon(
                      Icons.location_on,
                      color: Color(0xFFEF2B39),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFEF2B39),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Live Location Trigger Button
                TextButton.icon(
                  onPressed: isFetchingLocation ? null : _getCurrentLocation,
                  icon: isFetchingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.my_location,
                          size: 18,
                          color: Color(0xFFEF2B39),
                        ),
                  label: Text(
                    isFetchingLocation
                        ? "Fetching location..."
                        : "Use Current Location",
                    style: const TextStyle(
                      color: Color(0xFFEF2B39),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF2B39),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isLoading ? null : saveUserData,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Complete Profile",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
