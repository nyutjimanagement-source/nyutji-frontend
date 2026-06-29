import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import '../../main.dart';
import '../../core/widgets/incoming_call_overlay.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint("Firebase bg init error: $e");
  }
  debugPrint("Handling a background message: ${message.messageId}");
  
  final data = message.data;
  if (data['type'] == 'INCOMING_CALL') {
    final roomId = data['roomId'] ?? '';
    final callerName = data['callerName'] ?? 'Panggilan Masuk';
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        IncomingCallOverlay.show(context, callerName, roomId);
      }
    });
  }
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  bool _initialized = false;

  Future<void> initNotifications() async {
    if (_initialized) return;
    
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      
      final messaging = FirebaseMessaging.instance;
      
      // Request permission untuk push notification
      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Register background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        final data = message.data;
        if (data['type'] == 'INCOMING_CALL') {
          final roomId = data['roomId'] ?? '';
          final callerName = data['callerName'] ?? 'Panggilan Masuk';
          
          final context = navigatorKey.currentContext;
          if (context != null && context.mounted) {
            IncomingCallOverlay.show(context, callerName, roomId);
          }
        }
      });

      // App opened from notification listener
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('A new onMessageOpenedApp event was published!');
        final data = message.data;
        if (data['type'] == 'INCOMING_CALL') {
          final roomId = data['roomId'] ?? '';
          final callerName = data['callerName'] ?? 'Panggilan Masuk';
          
          final context = navigatorKey.currentContext;
          if (context != null && context.mounted) {
            IncomingCallOverlay.show(context, callerName, roomId);
          }
        }
      });

      _initialized = true;
      debugPrint("FCM Service initialized successfully.");
      
      // Upload token ke server jika user aktif
      await uploadTokenToServer();
    } catch (e) {
      debugPrint("Gagal menginisialisasi FCM Service: $e");
    }
  }

  Future<void> uploadTokenToServer() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        debugPrint("FCM Token: $token");
        await ApiService().updateFcmToken(token);
        debugPrint("FCM Token berhasil diunggah ke server.");
      }
    } catch (e) {
      debugPrint("Gagal mengunggah FCM Token ke server: $e");
    }
  }
}
