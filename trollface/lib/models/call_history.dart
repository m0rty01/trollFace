class CallHistory {
  final String id;
  final String callerId;
  final String? receiverId;
  final DateTime startTime;
  final DateTime? endTime;
  final String status; // 'completed', 'missed', 'ongoing'

  CallHistory({
    required this.id,
    required this.callerId,
    this.receiverId,
    required this.startTime,
    this.endTime,
    required this.status,
  });

  factory CallHistory.fromJson(Map<String, dynamic> json) {
    return CallHistory(
      id: json['id'],
      callerId: json['caller_id'],
      receiverId: json['receiver_id'],
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caller_id': callerId,
      'receiver_id': receiverId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'status': status,
    };
  }
} 