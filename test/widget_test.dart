import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rastros_app/main.dart';
import 'package:rastros_app/services/phone_auth_service.dart';
import 'package:rastros_app/services/user_profile_service.dart';

class _FakePhoneAuthService implements PhoneAuthService {
  var sendCalls = 0;
  var verifyCalls = 0;

  @override
  Future<void> sendCode(
    String phoneNumber, {
    required ValueChanged<String> onCodeSent,
    required Future<void> Function(AuthenticatedPhoneUser user)
    onAutoVerified,
    required ValueChanged<String> onError,
  }) async {
    sendCalls++;
    expect(phoneNumber, '+573001234567');
    onCodeSent('test-verification-id');
  }

  @override
  Future<AuthenticatedPhoneUser> verifyCode({
    required String verificationId,
    required String smsCode,
  }) async {
    verifyCalls++;
    expect(verificationId, 'test-verification-id');
    expect(smsCode, '012345');
    return const AuthenticatedPhoneUser(
      uid: 'test-user-id',
      phoneNumber: '+573001234567',
    );
  }
}

class _FakeUserProfileService implements UserProfileService {
  String? savedUid;
  String? savedPhoneNumber;

  @override
  Future<void> ensureProfile({
    required String uid,
    required String phoneNumber,
  }) async {
    savedUid = uid;
    savedPhoneNumber = phoneNumber;
  }
}

void main() {
  testWidgets('phone login continues through OTP to the home screen', (
    WidgetTester tester,
  ) async {
    final authService = _FakePhoneAuthService();
    final profileService = _FakeUserProfileService();
    await tester.pumpWidget(
      RastrosApp(
        authService: authService,
        profileService: profileService,
      ),
    );

    expect(find.byKey(const Key('login-pets-art')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('phone-input')), '3001234567');
    await tester.tap(find.byKey(const Key('send-code-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Ingresa el código de 6 dígitos\nenviado a tu celular'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('brand-logo')), findsOneWidget);
    expect(find.byKey(const Key('otp-cat-art')), findsOneWidget);

    for (var index = 0; index < 6; index++) {
      await tester.enterText(find.byKey(Key('otp-digit-$index')), '$index');
      await tester.pump();
    }
    await tester.tap(find.byKey(const Key('verify-code-button')));
    await tester.pumpAndSettle();

    expect(find.text('¡Hola, qué alegría verte!'), findsOneWidget);
    expect(find.text('Explorar'), findsOneWidget);
    expect(authService.sendCalls, 1);
    expect(authService.verifyCalls, 1);
    expect(profileService.savedUid, 'test-user-id');
    expect(profileService.savedPhoneNumber, '+573001234567');
  });
}
