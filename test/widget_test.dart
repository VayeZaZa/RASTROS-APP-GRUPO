import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rastros_app/main.dart';
import 'package:rastros_app/services/phone_auth_service.dart';

class _FakePhoneAuthService implements PhoneAuthService {
  @override
  Future<void> sendCode(
    String phoneNumber, {
    required ValueChanged<String> onCodeSent,
    required VoidCallback onAutoVerified,
    required ValueChanged<String> onError,
  }) async {
    expect(phoneNumber, '+573001234567');
    onCodeSent('test-verification-id');
  }

  @override
  Future<void> verifyCode({
    required String verificationId,
    required String smsCode,
  }) async {
    expect(verificationId, 'test-verification-id');
    expect(smsCode, '012345');
  }
}

void main() {
  testWidgets('phone login continues through OTP to the home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      RastrosApp(authService: _FakePhoneAuthService()),
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
  });
}
