import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> firebasemessagingBackgroundHandaler(RemoteMessage message) async {
  await NotificationService.instance.setUpFlutterNotification();
  await NotificationService.instance.showNotification(message);
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin localNotification = FlutterLocalNotificationsPlugin();
  bool isFlutterLocalNotificationInitialized = false;

  /// Initialize Firebase Messaging and Local Notifications
  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebasemessagingBackgroundHandaler);
    await _requestPermission();
    await setUpFlutterNotification();
    await _setupMessageHandler();

    final token = await messaging.getToken();
    print('FCM Token: $token');
  }

  /// Request Notification Permission
  Future<void> _requestPermission() async {
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('Permission Status: ${settings.authorizationStatus}');
  }

  /// Set up Flutter Local Notifications
  Future<void> setUpFlutterNotification() async {
    if (isFlutterLocalNotificationInitialized) return;

    // Define a notification channel for Android
    const channel = AndroidNotificationChannel(
      'chat_channel',
      'Chat Notifications',
      description: 'This channel is used for chat notifications',
      importance: Importance.high,
    );

    await localNotification
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: const DarwinInitializationSettings(),
    );

    await localNotification.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    isFlutterLocalNotificationInitialized = true;
  }

  /// Show Notification with Actionable Buttons
  Future<void> showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await localNotification.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'chat_channel',
            'Chat Notifications',
            channelDescription: 'This channel is used for chat notifications',
            importance: Importance.high,
            icon: '@mipmap/ic_launcher',
            actions: [
              AndroidNotificationAction(
                'reply_action',
                'Reply',
                inputs: <AndroidNotificationActionInput>[
                  AndroidNotificationActionInput(
                      allowFreeFormInput: true, // Allows the user to type their response
                      label: 'Type your reply...' // Placeholder text for the input
                  ),
                ],
              ),
              AndroidNotificationAction(
                'mark_read_action',
                'Mark as Read',
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  /// Handle Notification Button Actions
  void _onNotificationResponse(NotificationResponse response) {
    if (response.payload != null) {
      print('Notification payload: ${response.payload}');
      if (response.actionId == 'reply_action' && response.input != null) {
        print('User replied: ${response.input}');
        // Handle reply (e.g., send to server or update UI)
      } else if (response.actionId == 'mark_read_action') {
        print('Mark as Read clicked');
        // Handle mark as read (e.g., update server or local data)
      }
    }
  }

  /// Set Up Handlers for Foreground and Background Notifications
  Future<void> _setupMessageHandler() async {
    FirebaseMessaging.onMessage.listen((message) {
      showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }
  }

  /// Handle Background Notification Messages
  void _handleBackgroundMessage(RemoteMessage message) {
    if (message.data['type'] == 'chat') {
      print('Chat Notification Received: ${message.data}');
      // Navigate to chat screen or handle chat notification
    }
  }
}
