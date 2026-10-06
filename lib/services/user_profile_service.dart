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
    final userReference = _firestore.collection('usuarios').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userReference);
      final existingData = snapshot.data();
      final profile = <String, Object?>{
        'uid': uid,
        'telefono': phoneNumber,
        'verificado': true,
      };

      if (existingData == null) {
        profile.addAll({
          'creadoEn': FieldValue.serverTimestamp(),
          'fotoUrl': '',
          'nombre': '',
          'nombreFundacion': '',
          'rol': 'usuario',
        });
      } else {
        if (!existingData.containsKey('creadoEn')) {
          profile['creadoEn'] = FieldValue.serverTimestamp();
        }
        if (!existingData.containsKey('fotoUrl')) profile['fotoUrl'] = '';
        if (!existingData.containsKey('nombre')) profile['nombre'] = '';
        if (!existingData.containsKey('nombreFundacion')) {
          profile['nombreFundacion'] = '';
        }
        if (!existingData.containsKey('rol')) profile['rol'] = 'usuario';
      }

      transaction.set(userReference, profile, SetOptions(merge: true));
    });
  }
}
