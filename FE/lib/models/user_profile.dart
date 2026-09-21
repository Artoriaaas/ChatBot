class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final bool isGoogleAuth;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.isGoogleAuth = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
        'isGoogleAuth': isGoogleAuth,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? 'usr_1',
      name: json['name'] as String? ?? 'Nghiên cứu viên',
      email: json['email'] as String? ?? 'user@paperdesk.ai',
      avatarUrl: json['avatarUrl'] as String?,
      isGoogleAuth: json['isGoogleAuth'] as bool? ?? false,
    );
  }
}

