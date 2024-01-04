import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:izi_kiosco/app/values/env_keys.dart';
import 'package:izi_kiosco/data/utils/token_utils.dart';


class DioClient {
  final Dio _dio = Dio();
  DioClient() {
    _dio.options = BaseOptions(
        baseUrl: dotenv.env[EnvKeys.apiUrl] ?? "");
    _dio.interceptors.add(AppInterceptor());
  }

  Future<Response> postFile({
    required String filePath,
  required String uri,
    Options? options
  })async {
    String fileName = filePath.split('/').last;
    FormData formData = FormData.fromMap({
      fileName:
      await MultipartFile.fromFile(filePath, filename:fileName),
    });
    var response =
        await _dio.post(uri, data: formData, options: options);
    return response;
  }
  Future<Response> getFile({
    required String uri,
    required String filePath
  }) async {
    //error
    var response =
    await _dio.download(uri,filePath);
    return response;
  }
  Future<Response> get({
    required String uri,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? baseUrl
  }) async {

    Dio dio  = _dio;
    if(baseUrl!=null){

      dio = Dio();
      dio.options = BaseOptions(
          baseUrl: baseUrl);
      dio.interceptors.add(AppInterceptor());
    }

    //error
    var response =
        await dio.get(uri, queryParameters: queryParameters, options: options);
    return response;
  }
  Future<Response> post({
    required String uri,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    //error
    var response =
    await _dio.post(uri, queryParameters: queryParameters, options: options,data: body);
    return response;
  }
  Future<Response> put({
    required String uri,
    required Map<String, dynamic> body,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? baseUrl
  }) async {
    //error
    Dio dio  = _dio;
    if(baseUrl!=null){

      dio = Dio();
      dio.options = BaseOptions(
          baseUrl: baseUrl);
      dio.interceptors.add(AppInterceptor());
    }
    var response =
    await dio.put(uri, queryParameters: queryParameters, options: options,data: body);
    return response;
  }
  Future<Response> delete({
    required String uri,
    Options? options,
  }) async {
    //error
    var response =
    await _dio.delete(uri, options: options);
    return response;
  }

}

class AppInterceptor extends InterceptorsWrapper {
  AppInterceptor();
  @override
  Future onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.headers.containsKey("no-auth")) {
      options.headers.remove("no-auth");
    } else {
      final token = await TokenUtils.getToken();
      options.headers.addAll({"Authorization": "Bearer $token"});
    }
    options.headers.addAll({"Connection": "Keep-Alive",});
    return handler.next(options);
  }
}
