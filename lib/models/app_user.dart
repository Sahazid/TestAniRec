class AppUser {
  final int id;
  final String email;
  final String role;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';
}
