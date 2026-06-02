class SignupRequest {
  const SignupRequest({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.acceptTerms,
    this.phone,
  });

  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final bool acceptTerms;
  final String? phone;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'accept_terms': acceptTerms,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
      };
}
