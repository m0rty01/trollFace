class Friend {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isOnline;

  Friend({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isOnline = false,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'],
      name: json['name'],
      avatarUrl: json['avatar_url'],
      isOnline: json['is_online'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar_url': avatarUrl,
      'is_online': isOnline,
    };
  }
} 