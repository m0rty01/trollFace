import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:realtime_client/realtime_client.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _notifications = FlutterLocalNotificationsPlugin();
  final _client = Supabase.instance.client;
  final _notificationController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get notificationStream => _notificationController.stream;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notifications.initialize(initSettings);
    _setupRealtimeListeners();
  }

  void _setupRealtimeListeners() {
    _client
        .channel('public:notifications')
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: 'INSERT',
            schema: 'public',
            table: 'notifications',
            filter: 'user_id=eq.${_client.auth.currentUser?.id ?? ''}',
          ),
          (payload, [ref]) {
            if (payload['new'] != null) {
              _showNotification(payload['new'] as Map<String, dynamic>);
            }
          },
        )
        .subscribe();

    _client
        .channel('public:filter_usage')
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: 'INSERT',
            schema: 'public',
            table: 'filter_usage',
          ),
          (payload, [ref]) {
            // Handle new filter usage
            print('New filter usage: ${payload['new']}');
          },
        )
        .subscribe();
  }

  Future<void> _showNotification(Map<String, dynamic> payload) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Channel',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(
      DateTime.now().millisecond,
      payload['title'] ?? 'New Notification',
      payload['body'] ?? '',
      details,
      payload: payload.toString(),
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap
    if (response.payload != null) {
      final payload = Map<String, dynamic>.from(response.payload as Map);
      _notificationController.add(payload);
    }
  }

  Future<void> sendCallNotification({
    required String receiverId,
    required String callId,
    required String callerName,
  }) async {
    await _client.from('notifications').insert({
      'user_id': receiverId,
      'type': 'call',
      'title': 'Incoming Call',
      'body': '$callerName is calling you',
      'data': {
        'call_id': callId,
        'caller_name': callerName,
      },
    });
  }

  Future<void> sendFriendRequestNotification({
    required String receiverId,
    required String senderName,
  }) async {
    await _client.from('notifications').insert({
      'user_id': receiverId,
      'type': 'friend_request',
      'title': 'New Friend Request',
      'body': '$senderName wants to be your friend',
      'data': {
        'sender_name': senderName,
      },
    });
  }

  void dispose() {
    _notificationController.close();
  }
} 