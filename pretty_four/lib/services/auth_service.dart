import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import '../core/api_client.dart';
import '../core/auth_notifier.dart';

class AuthService {
  final AuthNotifier _auth;

  AuthService(this._auth);

  Future<void> signInWithEmail(String email, String password) async {
    final res = await ApiClient.instance.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    await _auth.setToken(res.data['access_token']);
  }

  Future<void> signUpWithEmail(String email, String password) async {
    final res = await ApiClient.instance.post('/auth/register', data: {
      'email': email,
      'password': password,
    });
    await _auth.setToken(res.data['access_token']);
  }

  Future<void> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn();
    final account = await googleSignIn.signIn();
    if (account == null) throw Exception('구글 로그인이 취소됐습니다.');

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) throw Exception('Google ID 토큰을 가져올 수 없습니다.');

    final res = await ApiClient.instance.post('/auth/google/token', data: {
      'idToken': idToken,
    });
    await _auth.setToken(res.data['access_token']);
  }

  Future<void> signInWithKakao() async {
    OAuthToken token;
    if (await isKakaoTalkInstalled()) {
      token = await UserApi.instance.loginWithKakaoTalk();
    } else {
      token = await UserApi.instance.loginWithKakaoAccount();
    }

    final res = await ApiClient.instance.post('/auth/kakao', data: {
      'kakaoAccessToken': token.accessToken,
    });
    await _auth.setToken(res.data['access_token']);
  }

  Future<void> signOut() async {
    await _auth.clearToken();
  }
}
