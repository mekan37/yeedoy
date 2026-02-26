class GourmetUser {
  GourmetUser({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.followerCount,
    required this.isFollowing,
    required this.bio,
  });

  final String id;
  final String name;
  final String avatarUrl;
  final int followerCount;
  final bool isFollowing;
  final String bio;

  GourmetUser copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    int? followerCount,
    bool? isFollowing,
    String? bio,
  }) {
    return GourmetUser(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      followerCount: followerCount ?? this.followerCount,
      isFollowing: isFollowing ?? this.isFollowing,
      bio: bio ?? this.bio,
    );
  }

  factory GourmetUser.fromMap(Map<String, dynamic> map) {
    return GourmetUser(
      id: (map['id'] ?? map['user_id'] ?? '').toString(),
      name: (map['display_name'] ?? map['name'] ?? 'Gurme').toString(),
      avatarUrl: (map['avatar_url'] ?? map['avatar'] ?? '').toString(),
      followerCount: (map['follower_count'] as num?)?.toInt() ?? 0,
      isFollowing: (map['is_following'] as bool?) ?? false,
      bio: (map['bio'] ?? map['about'] ?? '').toString(),
    );
  }
}
