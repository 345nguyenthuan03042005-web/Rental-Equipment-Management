class Member {
  final String? id;
  final String email;
  final String password;
  final String givenName;
  final String? surname;
  final int role;
  final bool isActive;
  final bool emailVerified;
  Member({
    required this.id,
    required this.email,
    required this.password,
    required this.givenName,
    required this.surname,
    required this.role,
    this.isActive = true,
    this.emailVerified = false,
  });
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'email': email,
      'givenName': givenName,
      'surname': surname,
      'password': password,
      'role': role,
    };
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'],
      email: map['email'],
      password: map['password'] ?? '',
      givenName: map['givenName'],
      surname: map['surname'],
      role: map['role'],
      isActive: map['isActive'] ?? true,
      emailVerified: map['emailVerified'] ?? false,
    );
  }
}
