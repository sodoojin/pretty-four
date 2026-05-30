import 'package:dio/dio.dart';
import 'auth_notifier.dart';

class ApiClient {
  static late final Dio _dio;
  static late final AuthNotifier _auth;

  static void init(String baseUrl, AuthNotifier auth) {
    _auth = auth;
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _auth.token;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await _auth.clearToken();
        }
        handler.next(error);
      },
    ));
  }

  static Dio get instance => _dio;
}
