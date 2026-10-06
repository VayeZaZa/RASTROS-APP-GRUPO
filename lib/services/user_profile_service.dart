import 'package:cloud_firestore/cloud_firestore.dart';

abstract interface class UserProfileService {
  Future<void> ensureProfile({
    required String uid,
    required String phoneNumber,
  });
}

class FirestoreUserProfileService implements UserProfileService {
  FirestoreUserProfileService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<void> ensureProfile({
    required String uid,
    required String phoneNumber,
  }) async {
    final profile = _firestore.collection('usuarios').doc(uid);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(profile);
      if (snapshot.exists) {
        transaction.set(profile, {
          'telefono': phoneNumber,
          'verificado': true,
        }, SetOptions(merge: true));
        return;
      }

      transaction.set(profile, {
        'uid': uid,
        'creadoEn': FieldValue.serverTimestamp(),
        'fotoUrl': '',
        'nombre': '',
        'nombreFundacion': '',
        'rol': 'usuario',
        'telefono': phoneNumber,
        'verificado': true,
      });
    });
  }
}
