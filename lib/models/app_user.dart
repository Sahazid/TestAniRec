class AppUser {
  final int id;
  final String username;
  final String email;
  final String role;
  final String? profileImagePath;
  final bool isBlocked;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.profileImagePath,
    required this.isBlocked,
    required this.createdAt,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';
}
