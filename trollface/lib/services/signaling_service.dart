import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';

class SignalingService {
  static final SignalingService _instance = SignalingService._internal();
  factory SignalingService() => _instance;
  SignalingService._internal();

  WebSocketChannel? _channel;
  final _uuid = const Uuid();
  final _supabase = Supabase.instance.client;
  
  String? _currentCallId;
  String? get currentCallId => _currentCallId;

  final _callStateController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get callState => _callStateController.stream;

  Future<void> connect() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final wsUrl = 'ws://localhost:3000?userId=${user.id}';
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _channel!.stream.listen(
      (message) {
        final data = Map<String, dynamic>.from(message as Map);
        _callStateController.add(data);
      },
      onError: (error) {
        print('WebSocket error: $error');
        _callStateController.add({'type': 'error', 'error': error.toString()});
      },
      onDone: () {
        print('WebSocket connection closed');
        _callStateController.add({'type': 'disconnected'});
      },
    );
  }

  Future<String> startCall() async {
    if (_channel == null) await connect();
    
    _currentCallId = _uuid.v4();
    _channel!.sink.add({
      'type': 'start_call',
      'callId': _currentCallId,
      'userId': _supabase.auth.currentUser?.id,
    });

    return _currentCallId!;
  }

  Future<void> joinCall(String callId) async {
    if (_channel == null) await connect();
    
    _currentCallId = callId;
    _channel!.sink.add({
      'type': 'join_call',
      'callId': callId,
      'userId': _supabase.auth.currentUser?.id,
    });
  }

  Future<void> endCall() async {
    if (_channel == null || _currentCallId == null) return;

    _channel!.sink.add({
      'type': 'end_call',
      'callId': _currentCallId,
      'userId': _supabase.auth.currentUser?.id,
    });

    _currentCallId = null;
  }

  void dispose() {
    _channel?.sink.close();
    _callStateController.close();
  }
} 