import 'package:dio/dio.dart';
import '../../config/api_config.dart';
import '../storage/token_storage.dart';

class ApiClient {
  late final Dio dio;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Do not send Authorization header for public authentication routes
          if (!options.path.contains('/api/auth/')) {
            final token = await TokenStorage.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            // Token expired or invalid -> delete stored token
            TokenStorage.deleteToken();
          }
          return handler.next(e);
        },
      ),
    );
  }
}
