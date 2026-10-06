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
    required Future<void> Function(AuthenticatedPhoneUser user) onAutoVerified,
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
  var saveCalls = 0;

  @override
  Future<void> ensureProfile({
    required String uid,
    required String phoneNumber,
  }) async {
    saveCalls++;
    savedUid = uid;
    savedPhoneNumber = phoneNumber;
  }
}

void main() {
  testWidgets('phone login continues through OTP to the home screen', (
    WidgetTester tester,
  ) async {
    final profileService = _FakeUserProfileService();
    await tester.pumpWidget(
      RastrosApp(
        authService: _FakePhoneAuthService(),
        profileService: profileService,
        enablePhoneAuth: true,
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
    expect(profileService.savedUid, 'test-user-id');
    expect(profileService.savedPhoneNumber, '+573001234567');
  });

  testWidgets('tester mode previews OTP and home without Firebase writes', (
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

    await tester.tap(find.byKey(const Key('send-code-button')));
    await tester.pumpAndSettle();

    expect(authService.sendCalls, 0);
    expect(find.text('Continuar como modo tester'), findsOneWidget);

    final testerModeButton = find.byKey(const Key('tester-mode-button'));
    await tester.ensureVisible(testerModeButton);
    await tester.tap(testerModeButton);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('otp-cat-art')), findsOneWidget);
    expect(find.text('Modo tester'), findsNothing);
    expect(find.text('Reenviar código'), findsNothing);
    expect(find.text('Continuar'), findsOneWidget);

    final continueButton = find.byKey(const Key('verify-code-button'));
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.text('¡Hola, qué alegría verte!'), findsOneWidget);
    expect(authService.sendCalls, 0);
    expect(authService.verifyCalls, 0);
    expect(profileService.saveCalls, 0);
  });
}
