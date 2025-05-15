import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final _client = Supabase.instance.client;
  RealtimeChannel? _channel;

  void startListening() {
    _channel = _client.channel('public:filter_usage')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'filter_usage',
        callback: (payload) {
          // Handle new filter usage
          print('New filter usage: $payload');
        },
      )
      ..subscribe();
  }

  void stopListening() {
    _channel?.unsubscribe();
    _channel = null;
  }
} 