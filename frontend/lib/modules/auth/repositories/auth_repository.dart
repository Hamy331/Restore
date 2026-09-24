import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;

  AuthRepository({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  Future<User?> loginWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        throw Exception('Sai email hoặc mật khẩu.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Định dạng email không hợp lệ.');
      }
      throw Exception(e.message ?? 'Đăng nhập thất bại.');
    } catch (e) {
      throw Exception('Đã xảy ra lỗi hệ thống.');
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }
}
