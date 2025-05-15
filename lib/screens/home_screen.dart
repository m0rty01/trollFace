import 'package:flutter/material.dart';
import '../services/webrtc_service.dart';
import '../services/supabase_service.dart';
import '../services/call_stats_service.dart';
import '../services/audio_service.dart';
import 'call_screen.dart';

class HomeScreen extends StatelessWidget {
  final SupabaseService supabaseService;
  final WebRTCService webRTCService;
  final CallStatsService callStatsService;
  final AudioService audioService;

  const HomeScreen({
    Key? key,
    required this.supabaseService,
    required this.webRTCService,
    required this.callStatsService,
    required this.audioService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TrollFace'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/call',
                  arguments: {
                    'callId': 'dummy-call-id',
                    'supabaseService': supabaseService,
                    'webRTCService': webRTCService,
                    'callStatsService': callStatsService,
                    'audioService': audioService,
                  },
                );
              },
              child: Text('Start Call'),
            ),
          ],
        ),
      ),
    );
  }
} 