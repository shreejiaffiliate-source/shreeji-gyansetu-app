import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart'; // 🚀 debugPrint ke liye add kiya

class StorageService {
  final _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  // 🚀 FIXED: Try-Catch lagaya taaki BadPaddingException se app crash na ho
  Future<String?> getToken() async {
    try {
      return await _storage.read(key: 'auth_token');
    } catch (e) {
      debugPrint("Secure Storage Error (Token): $e");
      // Agar data kharab ho gaya hai, toh sab clear kar do
      await _storage.deleteAll();
      return null;
    }
  }

  // User role save karne ke liye
  Future<void> saveUserRole(String role) async {
    await _storage.write(key: 'user_role', value: role);
  }

  // 🚀 FIXED: Yahan bhi Try-Catch zaroori hai safety ke liye
  Future<String?> getUserRole() async {
    try {
      return await _storage.read(key: 'user_role');
    } catch (e) {
      debugPrint("Secure Storage Error (Role): $e");
      await _storage.deleteAll();
      return null;
    }
  }

  // Logout me role bhi delete karna mat bhulna
  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_role');
  }
}