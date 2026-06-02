// User profile shape returned by GET /api/v1/auth/me/
// Tolerant of missing optional fields so older backend versions still
// deserialize cleanly.

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    this.firstName = '',
    this.lastName = '',
    this.phone,
    this.role = '',
    this.status = '',
    this.emailVerified = false,
    this.mfaEnabled = false,
    this.dateOfBirth,
    this.gender,
    this.streetAddress,
    this.city,
    this.zipCode,
    this.patientId,
    this.avatarUrl,
    this.dateJoined,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String role;
  final String status;
  final bool emailVerified;
  final bool mfaEnabled;
  final String? dateOfBirth;        // YYYY-MM-DD
  final String? gender;
  final String? streetAddress;
  final String? city;
  final String? zipCode;
  final String? patientId;
  final String? avatarUrl;
  final String? dateJoined;

  String get fullName {
    final f = firstName.trim();
    final l = lastName.trim();
    if (f.isEmpty && l.isEmpty) return email.split('@').first;
    return '$f $l'.trim();
  }

  String get initials {
    final f = firstName.trim();
    final l = lastName.trim();
    if (f.isEmpty && l.isEmpty) {
      final e = email.trim();
      return e.isEmpty ? '?' : e[0].toUpperCase();
    }
    final first = f.isNotEmpty ? f[0] : '';
    final last = l.isNotEmpty ? l[0] : '';
    return ('$first$last').toUpperCase();
  }

  String get roleLabel {
    if (role.isEmpty) return 'Patient Account';
    final pretty = role[0].toUpperCase() + role.substring(1).toLowerCase();
    return 'Standard $pretty Account';
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      phone: json['phone'] as String?,
      role: (json['role'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      emailVerified: json['email_verified'] as bool? ?? false,
      mfaEnabled: json['mfa_enabled'] as bool? ?? false,
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
      streetAddress: json['street_address'] as String?,
      city: json['city'] as String?,
      zipCode: json['zip_code'] as String?,
      patientId: json['patient_id'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      dateJoined: json['date_joined'] as String?,
    );
  }

  Map<String, dynamic> toUpdatePayload({
    String? firstName,
    String? lastName,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? streetAddress,
    String? city,
    String? zipCode,
  }) {
    return {
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (phone != null) 'phone': phone,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      if (gender != null) 'gender': gender,
      if (streetAddress != null) 'street_address': streetAddress,
      if (city != null) 'city': city,
      if (zipCode != null) 'zip_code': zipCode,
    };
  }

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? streetAddress,
    String? city,
    String? zipCode,
  }) {
    return UserProfile(
      id: id,
      email: email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      role: role,
      status: status,
      emailVerified: emailVerified,
      mfaEnabled: mfaEnabled,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      streetAddress: streetAddress ?? this.streetAddress,
      city: city ?? this.city,
      zipCode: zipCode ?? this.zipCode,
      patientId: patientId,
      avatarUrl: avatarUrl,
      dateJoined: dateJoined,
    );
  }
}
