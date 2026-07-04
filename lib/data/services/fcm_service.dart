import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'api_service.dart';
import '../../main.dart';
import '../../core/widgets/incoming_call_overlay.dart';
import '../../core/widgets/nyutji_notif.dart';
import '../../features/chat/screens/chat_screen.dart';

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

  // Simpan notif ke Hive saat background
  await _saveNotificationToHive(data, message.notification);

  if (data['type'] == 'INCOMING_CALL') {
    final roomId = data['roomId'] ?? '';
    final callerName = data['callerName'] ?? 'Panggilan Masuk';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentState?.overlay?.context;
      if (context != null) {
        IncomingCallOverlay.show(context, callerName, roomId);
      }
    });
  }
}

/// Simpan notifikasi ke Hive box nyutji_notifications (untuk background handler)
Future<void> _saveNotificationToHive(
  Map<String, dynamic> data,
  RemoteNotification? notification,
) async {
  try {
    if (!Hive.isBoxOpen('nyutji_notifications')) {
      await Hive.openBox('nyutji_notifications');
    }
    final box = Hive.box('nyutji_notifications');
    final rawList = box.get('all_notifications', defaultValue: []) as List;

    final String type = data['type']?.toString() ?? 'info';
    final String notifType = type == 'INCOMING_CALL'
        ? 'call'
        : type == 'NEW_CHAT_MESSAGE'
            ? 'chat'
            : type == 'ORDER_STATUS_UPDATED'
                ? 'order_status'
                : 'info';

    final notifMap = {
      'id': '${DateTime.now().millisecondsSinceEpoch}',
      'type': notifType,
      'title': notification?.title ?? data['title'] ?? 'Notifikasi Nyutji',
      'body': notification?.body ?? data['body'] ?? '',
      'data': {
        if (data['orderNumber'] != null) 'orderNumber': data['orderNumber'].toString(),
        if (data['channel'] != null) 'channel': data['channel'].toString(),
        if (data['roomId'] != null) 'roomId': data['roomId'].toString(),
        if (data['callerName'] != null) 'callerName': data['callerName'].toString(),
      },
      'createdAt': DateTime.now().toIso8601String(),
      'isRead': false,
    };

    rawList.insert(0, notifMap);

    // Batasi max 50 notif
    final trimmed = rawList.take(50).toList();
    await box.put('all_notifications', trimmed);
  } catch (e) {
    debugPrint('[FCM] Gagal simpan notif ke Hive: $e');
  }
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  bool _initialized = false;
  static const bool disableFcm = false; 

  Future<void> initNotifications() async {
    if (_initialized) return;
    if (disableFcm) {
      debugPrint("FCM Initialization disabled temporarily.");
      return;
    }

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
        debugPrint('FCM Foreground message: ${message.data}');
        _handleForegroundMessage(message);
      });

      // App opened from notification listener
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM onMessageOpenedApp: ${message.data}');
        _handleForegroundMessage(message);
      });

      _initialized = true;
      debugPrint("FCM Service initialized successfully.");

      // Upload token ke server jika user aktif
      await uploadTokenToServer();
    } catch (e) {
      debugPrint("Gagal menginisialisasi FCM Service: $e");
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final context = navigatorKey.currentState?.overlay?.context;

    // Simpan ke Hive secara async
    _saveNotificationToHive(data, message.notification);

    if (data['type'] == 'INCOMING_CALL') {
      final roomId = data['roomId'] ?? '';
      final callerName = data['callerName'] ?? 'Panggilan Masuk';

      if (context != null && context.mounted) {
        IncomingCallOverlay.show(context, callerName, roomId);
      }
    } else if (data['type'] == 'NEW_CHAT_MESSAGE') {
      final senderName = data['senderName'] ?? 'Seseorang';
      final msgPreview = data['message'] ?? 'Pesan baru';
      final orderNumber = data['orderNumber'] ?? '';
      final channel = data['channel'] ?? '';

      // Cek apakah user sedang membuka ChatScreen untuk order dan channel ini
      final bool isChatOpen = ChatScreen.activeOrderNumber == orderNumber &&
          ChatScreen.activeChannel == channel;

      if (isChatOpen) {
        // Sedang chatting: mainkan suara "wuikk-wuikk" (bubble pop), jangan tampilkan banner
        _playChatBubbleSound();
      } else {
        // Tidak sedang di room chat ini: tampilkan banner notifikasi
        if (context != null && context.mounted) {
          NyutjiNotif.showInfo(
            context,
            '$senderName: $msgPreview${orderNumber.isNotEmpty ? ' (#$orderNumber)' : ''}',
          );
        }
      }
    } else {
      // Tampilkan banner umum untuk status update dan notifikasi lainnya
      final title = message.notification?.title ?? data['title'];
      final body = message.notification?.body ?? data['body'];
      if (title != null && body != null && context != null && context.mounted) {
        NyutjiNotif.showInfo(context, '$title: $body');
      }
    }
  }

  void _playChatBubbleSound() async {
    try {
      final player = AudioPlayer();
      await player.play(AssetSource('sounds/bubble.mp3'));
    } catch (e) {
      debugPrint("Gagal memutar suara bubble chat: $e");
    }
  }

  Future<void> uploadTokenToServer() async {
    if (disableFcm) return;
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
