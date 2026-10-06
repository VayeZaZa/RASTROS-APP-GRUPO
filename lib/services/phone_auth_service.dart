import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

abstract interface class PhoneAuthService {
  Future<void> sendCode(
    String phoneNumber, {
    required ValueChanged<String> onCodeSent,
    required VoidCallback onAutoVerified,
    required ValueChanged<String> onError,
  });

  Future<void> verifyCode({
    required String verificationId,
    required String smsCode,
  });
}

class FirebasePhoneAuthService implements PhoneAuthService {
  FirebasePhoneAuthService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  int? _resendToken;

  @override
  Future<void> sendCode(
    String phoneNumber, {
    required ValueChanged<String> onCodeSent,
    required VoidCallback onAutoVerified,
    required ValueChanged<String> onError,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      forceResendingToken: _resendToken,
      verificationCompleted: (credential) async {
        try {
          await _auth.signInWithCredential(credential);
          onAutoVerified();
        } on FirebaseAuthException catch (error) {
          onError(_messageFor(error));
        } catch (error) {
          onError('No se pudo completar la verificación automática: $error');
        }
      },
      verificationFailed: (error) => onError(_messageFor(error)),
      codeSent: (verificationId, resendToken) {
        _resendToken = resendToken;
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  @override
  Future<void> verifyCode({
    required String verificationId,
    required String smsCode,
  }) async {
    await _auth.signInWithCredential(
      PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      ),
    );
  }

  String _messageFor(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-phone-number' => 'El número de celular no es válido.',
      'invalid-verification-code' => 'El código ingresado no es correcto.',
      'session-expired' => 'El código venció. Solicita uno nuevo.',
      'too-many-requests' =>
        'Se solicitaron demasiados códigos. Intenta más tarde.',
      'quota-exceeded' =>
        'Firebase alcanzó el límite de SMS. Intenta más tarde.',
      'operation-not-allowed' =>
        'Activa el inicio de sesión por teléfono en Firebase Authentication.',
      'network-request-failed' =>
        'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
      _ => error.message ?? 'No se pudo completar la verificación.',
    };
  }
}
