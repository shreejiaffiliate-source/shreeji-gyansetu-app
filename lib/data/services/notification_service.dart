import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants/api_endpoints.dart';
import '../providers/auth_provider.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // 1. Request Permission (Required for iOS and Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
    }
  }

  // 2. Fetch the FCM Token and send it to Django
  static Future<void> getAndUploadToken() async {
    String? fcmToken = await _messaging.getToken();

    // Using the static getter we added to AuthProvider earlier
    final String? userToken = AuthProvider.storedToken;

    if (fcmToken != null && userToken != null) {
      print("📲 Attempting to sync FCM Token: $fcmToken");
      try {
        final response = await http.post(
          Uri.parse("${ApiEndpoints.baseUrl}/profile/update-fcm/"),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $userToken',
          },
          body: jsonEncode({'fcm_token': fcmToken}),
        );

        if (response.statusCode == 200) {
          print("FCM Token successfully synced with Django server.");
        } else{
          print("❌ Failed to sync token. Status: ${response.statusCode}, Body: ${response.body}");
        }
      } catch (e) {
        print("⚠️ Connection error while uploading FCM token: $e");
      }
    } else{
      print("ℹ️ Skipping token upload: FCM Token or User Auth Token is null.");
    }
  }
}