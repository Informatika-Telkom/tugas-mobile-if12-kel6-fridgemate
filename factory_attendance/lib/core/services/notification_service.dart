import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _defaultChannelId = 'attendance_alerts';
  static const String _defaultChannelName = 'Attendance Alerts';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    const channel = AndroidNotificationChannel(
      _defaultChannelId,
      _defaultChannelName,
      description: 'Notifications for attendance updates and reminders',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await _requestPermissions();
    _listenToMessages();
    await _messaging.subscribeToTopic('attendance-reminder');
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  void _listenToMessages() {
    FirebaseMessaging.onMessage.listen((message) {
      showRemoteMessage(message);
    });
  }

  Future<void> syncFcmToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.trim().isEmpty) return;

      await _firestore.collection('users').doc(userId).set({
        'fcmToken': token,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _messaging.onTokenRefresh.listen((newToken) async {
        if (newToken.trim().isEmpty) return;
        await _firestore.collection('users').doc(userId).set({
          'fcmToken': newToken,
          'fcmUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint('Failed to sync FCM token: $e');
    }
  }

  Future<void> showRemoteMessage(RemoteMessage message) async {
    final data = message.data;
    final type = data['type']?.toString();

    final title =
        message.notification?.title ?? _fallbackTitleForType(type ?? '');
    final body =
        message.notification?.body ??
        data['body']?.toString() ??
        _fallbackBodyForType(type ?? '');

    await showLocalNotification(title: title, body: body, payload: data);
  }

  Future<void> showClockInSuccess() async {
    await showLocalNotification(
      title: 'Clock-in berhasil',
      body: 'Absensi masuk kamu sudah tercatat. Selamat bekerja!',
      payload: {'type': 'clock_in_success'},
    );
  }

  Future<void> showGpsFailure(String message) async {
    await showLocalNotification(
      title: 'Absensi gagal',
      body: message,
      payload: {'type': 'gps_failure'},
    );
  }

  Future<void> showFaceDetectionFailure(String message) async {
    await showLocalNotification(
      title: 'Verifikasi wajah gagal',
      body: message,
      payload: {'type': 'face_failure'},
    );
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _defaultChannelId,
      _defaultChannelName,
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await _localNotifications.show(
      id,
      title,
      body,
      details,
      payload: payload == null ? null : jsonEncode(payload),
    );
  }

  String _fallbackTitleForType(String type) {
    switch (type) {
      case 'reminder':
        return 'Reminder absensi';
      case 'clock_in_success':
        return 'Clock-in berhasil';
      case 'gps_failure':
        return 'Absensi gagal';
      case 'face_failure':
        return 'Verifikasi wajah gagal';
      default:
        return 'Notifikasi absensi';
    }
  }

  String _fallbackBodyForType(String type) {
    switch (type) {
      case 'reminder':
        return 'Jangan lupa absensi hari ini.';
      case 'clock_in_success':
        return 'Absensi masuk kamu sudah tercatat.';
      case 'gps_failure':
        return 'Gagal mendapatkan lokasi. Pastikan GPS aktif.';
      case 'face_failure':
        return 'Wajah tidak terdeteksi dengan baik.';
      default:
        return 'Ada update baru terkait absensi.';
    }
  }
}

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.showRemoteMessage(message);
}
