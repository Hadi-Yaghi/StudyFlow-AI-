import 'package:dio/dio.dart';
import '../storage/token_storage.dart';
class ApiClient {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.0.105:8081'
    )
  )..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options,handler) async{
        final token = await TokenStorage.getToken();
        if(token!=null){
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      }
    )
  );

}
