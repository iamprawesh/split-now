import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;

  static const String _webClientId =
      '427506541821-l23f68re0ujiekvri8flki55fkjnnsa5.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: _webClientId,
    scopes: ['email', 'profile'],
  );

  Future<String?> signInWithGoogle() async {
    await _googleSignIn.signOut();
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    if (googleAuth.idToken == null) {
      throw Exception(
        'idToken is null. Add this SHA-1 to Firebase Console:\n'
        'D5:7A:A7:4C:48:2F:0F:79:BF:30:FC:7C:AC:D6:71:22:BF:7F:B7:E8\n'
        'Then re-download google-services.json.',
      );
    }

    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await _firebaseAuth.signInWithCredential(credential);

    final idToken = await userCredential.user?.getIdToken();
    return idToken;
  }

  Future<String?> signInWithApple() async {
    final appleProvider = fb.AppleAuthProvider();
    final userCredential =
        await _firebaseAuth.signInWithProvider(appleProvider);
    final idToken = await userCredential.user?.getIdToken();
    return idToken;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}
