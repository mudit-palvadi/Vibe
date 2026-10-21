import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:vibe/core/constants.dart';

/// the google sign in of the app, it opens the browser and comes back to the
/// app through a local address
class GoogleAuthService {
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

  Future<GoogleSignInCredentials?> signIn() => _googleSignIn.signIn();

  Future<GoogleSignInCredentials?> silentSignIn() =>
      _googleSignIn.silentSignIn();

  Future<void> signOut() => _googleSignIn.signOut();
}
