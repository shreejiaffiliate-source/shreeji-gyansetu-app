import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:provider/provider.dart';
import '../../core/constants/api_endpoints.dart';
import '../providers/auth_provider.dart';
import '../providers/course_provider.dart';
import '../../ui/screens/learning/lesson_player_screen.dart';
import '../models/course_model.dart';

class NotificationService {
  static FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    // Permission request
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important teacher replies.',
      importance: Importance.max,
      playSound: true,
    );

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        if (details.payload != null) {
          final Map<String, dynamic> data = jsonDecode(details.payload!);
          _handleNavigation(data, navigatorKey);
        }
      },
    );

    // 1. Handle background notification click
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNavigation(message.data, navigatorKey);
    });

    // 2. Handle terminated state notification click
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleNavigation(message.data, navigatorKey);
      }
    });

    // 3. LISTEN FOR TOKEN REFRESH: Agar app chalte waqt token badal jaye
    _messaging.onTokenRefresh.listen((newToken) {
      developer.log("🔄 FCM Token Refreshed: $newToken");
      getAndUploadToken();
    });

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      String? title = notification?.title ?? message.data['title'];
      String? body = notification?.body ?? message.data['body'];

      if (title != null) {
        _localNotifications.show(
          id: message.hashCode,
          title: title,
          body: body,
          // NotificationService.dart ke andar jahan .show() kar rahe ho:
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              channelDescription: 'Teacher replies and alerts',
              importance: Importance.max,
              priority: Priority.high, // ✅ Priority High honi chahiye
              ticker: 'ticker',
              fullScreenIntent: true, // ✅ Isse upar pop-up aane ke chances badh jate hain
              icon: '@mipmap/ic_launcher',
            ),
          ),
          payload: jsonEncode(message.data),
        );
        developer.log("🔔 Notification Panel Forced: $title");
      }
    });
  }

  static void _handleNavigation(Map<String, dynamic> data, GlobalKey<NavigatorState> navigatorKey) {
    developer.log("🚀 Handling Notification Click with Data: $data");

    // ✅ Tray se notifications saaf karein aur icon badge hatayein
    _localNotifications.cancelAll();

    final dynamic rawNotifId = data['notification_id'];

    if (data.containsKey('lesson_id') && navigatorKey.currentContext != null) {
      final lessonId = int.tryParse(data['lesson_id'].toString());

      if (lessonId != null) {
        final courseProvider = Provider.of<CourseProvider>(navigatorKey.currentContext!, listen: false);

        // Step 1: Mark as Read locally and on server
        if (rawNotifId != null) {
          final int? notifId = int.tryParse(rawNotifId.toString());
          if (notifId != null) {
            courseProvider.markNotificationRead(notifId);
            developer.log("✅ Marked Notification $notifId as Read");
          }
        }

        // Step 2: Find Lesson and Navigate
        LessonModel? targetLesson = courseProvider.findLessonById(lessonId);

        if (targetLesson != null) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => LessonPlayerScreen(
                lesson: targetLesson,
                openQueries: true,
              ),
            ),
          );
        } else {
          developer.log("⚠️ Lesson ID $lessonId not found, refreshing data...");
          courseProvider.fetchHomeData().then((_) {
            LessonModel? refreshedLesson = courseProvider.findLessonById(lessonId);
            if (refreshedLesson != null) {
              navigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (context) => LessonPlayerScreen(
                    lesson: refreshedLesson,
                    openQueries: true,
                  ),
                ),
              );
            }
          });
        }
      }
    }
  }

  static Future<void> getAndUploadToken() async {
    try {
      String? fcmToken = await _messaging.getToken();
      final String? userToken = AuthProvider.storedToken;

      developer.log("📱 Current FCM Token: $fcmToken");

      if (fcmToken != null && userToken != null) {
        final response = await http.post(
          Uri.parse("${ApiEndpoints.baseUrl}/profile/update-fcm/"),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $userToken',
          },
          body: jsonEncode({'fcm_token': fcmToken}),
        );

        if (response.statusCode == 200) {
          developer.log("✅ FCM Token synced with Server");
        } else {
          developer.log("⚠️ Token sync failed: ${response.statusCode}");
        }
      }
    } catch (e) {
      developer.log("⚠️ Token upload error: $e");
    }
  }
}