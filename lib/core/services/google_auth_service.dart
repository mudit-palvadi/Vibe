import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:vibe/core/constants.dart';

/// what the app needs from google, it is an interface so the tests can use
/// their own version of it
abstract class GoogleAuth {
  Future<GoogleSignInCredentials?> signIn();

  Future<GoogleSignInCredentials?> silentSignIn();

  Future<void> signOut();
}

/// the google sign in of the app, it opens the browser and comes back to the
/// app through a local address
class GoogleAuthService implements GoogleAuth {
  GoogleAuthService({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? _buildGoogleSignIn();

  final GoogleSignIn _googleSignIn;

  static GoogleSignIn _buildGoogleSignIn() {
    return GoogleSignIn(
      params: GoogleSignInParams(
        clientId: ServerConstant.googleClientId,
        clientSecret: ServerConstant.googleClientSecret,
        scopes: const ['openid', 'email', 'profile'],
        redirectPort: ServerConstant.googleRedirectPort,
      ),
    );
  }

  @override
  Future<GoogleSignInCredentials?> signIn() => _googleSignIn.signIn();

  @override
  Future<GoogleSignInCredentials?> silentSignIn() =>
      _googleSignIn.silentSignIn();

  @override
  Future<void> signOut() => _googleSignIn.signOut();
}
