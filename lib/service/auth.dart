import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_delivery_app/service/shared_pref.dart';

class AuthMethods {
  final FirebaseAuth auth = FirebaseAuth.instance;

  User? getCurrentUser() {
    return auth.currentUser;
  }

  // Wipes local state and signs out active session
  Future<void> signOut() async {
    await SharedpreferenceHelper().clearUser();
    await auth.signOut();
  }

  // Deletes account and clears local state
  Future<void> deleteUser() async {
    final User? user = auth.currentUser;
    await SharedpreferenceHelper().clearUser();
    await user?.delete();
  }
}
