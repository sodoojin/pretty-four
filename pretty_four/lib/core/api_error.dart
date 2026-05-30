import 'package:dio/dio.dart';

/// Dio 예외를 사용자에게 보여줄 한국어 메시지로 변환한다.
String apiErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      final msg = data['message'];
      if (msg is List) return msg.join('\n');
      return msg.toString();
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return '서버 응답이 지연되고 있어요. 잠시 후 다시 시도해주세요.';
      case DioExceptionType.connectionError:
        return '서버에 연결할 수 없어요. 네트워크를 확인해주세요.';
      default:
        return '요청 처리 중 오류가 발생했어요.';
    }
  }
  return error.toString();
}
