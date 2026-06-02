import 'package:datasolids_mobile/core/auth/token_manager.dart';
import 'package:datasolids_mobile/core/storage/secure_storage.dart';
import 'package:datasolids_mobile/features/auth/data/auth_api.dart';
import 'package:datasolids_mobile/features/auth/data/dtos/login_request.dart';
import 'package:datasolids_mobile/features/auth/domain/auth_repository.dart';
import 'package:datasolids_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class _MockAuthApi extends Mock implements AuthApi {}

class _MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  late _MockAuthApi mockApi;
  late _MockSecureStorage mockStorage;

  setUp(() {
    mockApi = _MockAuthApi();
    mockStorage = _MockSecureStorage();
    when(() => mockStorage.writeAccessToken(any())).thenAnswer((_) async {});
    when(() => mockStorage.writeRefreshToken(any())).thenAnswer((_) async {});
    when(() => mockStorage.clearAll()).thenAnswer((_) async {});
    registerFallbackValue(
      const LoginRequest(email: 'x@y.z', password: 'x'),
    );
  });

  testWidgets('shows validation errors for empty submit', (tester) async {
    await tester.pumpWidget(wrap(
      const LoginScreen(),
      overrides: [
        authApiProvider.overrideWithValue(mockApi),
        secureStorageProvider.overrideWithValue(mockStorage),
      ],
    ));

    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Required.'), findsNWidgets(2));
  });

  testWidgets('successful login persists tokens', (tester) async {
    when(() => mockApi.login(any())).thenAnswer(
      (_) async => const AuthResponse(access: 'a.t', refresh: 'r.t'),
    );

    await tester.pumpWidget(wrap(
      const LoginScreen(),
      overrides: [
        authApiProvider.overrideWithValue(mockApi),
        secureStorageProvider.overrideWithValue(mockStorage),
      ],
    ));

    await tester.enterText(
      find.byType(TextFormField).first,
      'patient@example.com',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'StrongPassw0rd!XYZ',
    );
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    verify(() => mockStorage.writeAccessToken('a.t')).called(1);
    verify(() => mockStorage.writeRefreshToken('r.t')).called(1);
  });
}
