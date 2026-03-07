import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/notification_banner.dart';
import 'notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../screens/practice/presentation/screens/practice_screen.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // In background, just ensure message is handled; avoid heavy UI ops
}

class PushMessagingService {
  PushMessagingService._();
  static final PushMessagingService instance = PushMessagingService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    await _messaging.setAutoInitEnabled(true);
    await requestPushPermission();
    await getDeviceToken();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? 'New Alert';
      final body = message.notification?.body ?? 'You have a new message';

      debugPrint('FCM: Debug - Message received: $title - $body');

      final context = NotificationService.navigatorKey.currentContext;
      
      if (context != null) {
        // Use the beautiful Top Banner Notification for both Mobile and Web foreground
        NotificationBannerService.show(
          context,
          title: title,
          message: body,
          type: NotificationType.reminder, // You can parse payload to change types dynamically
          onTap: () {
            NotificationService.navigatorKey.currentState
                ?.push(MaterialPageRoute(builder: (_) => const PracticeScreen()));
          },
        );
        debugPrint('FCM: Debug - Notification displayed (Top Banner)');
      } else {
        // Fallback to local notification plugin if context isn't ready (mostly for mobile background transition)
        if (!kIsWeb) {
          NotificationService.instance.showInstantNotification(title, body, payload: 'practice');
          debugPrint('FCM: Debug - Notification displayed (Local Notification Fallback)');
        }
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM: Debug - Notification clicked. Navigating...');
      NotificationService.navigatorKey.currentState
          ?.push(MaterialPageRoute(builder: (_) => const PracticeScreen()));
    });

    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }
  }

  Future<void> requestPushPermission() async {
    debugPrint('FCM: Debug - Requesting permission...');
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
    debugPrint('FCM: Debug - Permission granted: ${settings.authorizationStatus}');

    if (!kIsWeb && Platform.isAndroid) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> getDeviceToken() async {
    try {
      debugPrint('FCM: Debug - Generating token...');
      final vapidKey = dotenv.env['FCM_VAPID_KEY'] ?? '';
      final token = await _messaging.getToken(
        vapidKey: vapidKey.isNotEmpty ? vapidKey : "BLDP4GIxdpH5um7Tng4HlLIVsM78daIneA4ReNeSa7xA0OlaIaHFrlrTIRIT7gyXdiFRya3uDfW96RfBY19Ul9s",
      );
      if (token != null) {
        debugPrint('FCM: Debug - Token generated: $token');
        
        // Ensure token refresh is handled
        _messaging.onTokenRefresh.listen((newToken) async {
          debugPrint('FCM: Debug - Token refreshed: $newToken');
          await _saveTokenToFirestore(newToken);
        });

        await _saveTokenToFirestore(token);
      } else {
        debugPrint('FCM: Debug - Token generated is null');
      }
    } catch (e) {
      debugPrint('FCM: Debug - Error generating FCM token: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fcm_token': token});
      debugPrint('FCM: Debug - Token saved to Firestore for user: ${user.uid}');
    }
  }
}
