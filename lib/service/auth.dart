import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_delivery_app/service/shared_pref.dart';
import 'package:food_delivery_app/service/database.dart';

class AuthMethods {
  final FirebaseAuth auth = FirebaseAuth.instance;

  /// Get the currently authenticated user
  User? getCurrentUser() {
    return auth.currentUser;
  }

  /// Wipes local state and signs out active session
  Future<void> signOut() async {
    await SharedpreferenceHelper().clearUser();
    await auth.signOut();
  }

  /// Deletes user account safely: Cleans up Firestore profile first,
  /// clears local preferences, and handles re-authentication exceptions.
  Future<bool> deleteUser() async {
    try {
      final User? user = auth.currentUser;
      if (user != null) {
        String uid = user.uid;

        // 1. Delete user document from Firestore first
        await DatabaseMethods().deleteUser(uid);

        // 2. Clear local storage preferences
        await SharedpreferenceHelper().clearUser();

        // 3. Delete Firebase Authentication user
        await user.delete();
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // Prompt user to log back in before deleting account
        print("User must re-authenticate before account deletion.");
      }
      return false;
    } catch (e) {
      print("Error deleting user: $e");
      return false;
    }
  }
}
