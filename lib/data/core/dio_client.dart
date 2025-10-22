import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:izi_kiosco/app/values/env_keys.dart';
import 'package:izi_kiosco/data/utils/business_utils.dart';
import 'package:izi_kiosco/data/utils/token_utils.dart';


class DioClient {
  final Dio _dio = Dio();
  DioClient() {
    _dio.options = BaseOptions(
        baseUrl: dotenv.env[EnvKeys.apiUrl] ?? "");
    _dio.interceptors.add(AppInterceptor(_dio));
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
    String? baseUrl,
    CancelToken? cancelToken,
  }) async {

    Dio dio  = _dio;
    if(baseUrl!=null){

      dio = Dio();
      dio.options = BaseOptions(
          baseUrl: baseUrl);
      dio.interceptors.add(AppInterceptor(dio));
    }

    //error
    var response =
        await dio.get(uri, queryParameters: queryParameters, options: options,cancelToken: cancelToken);
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
      dio.interceptors.add(AppInterceptor(dio));
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
  final Dio dio;
  final int maxRetries = 3;
  AppInterceptor(this.dio);
  @override
  Future onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.headers.containsKey("no-auth")) {
      options.headers.remove("no-auth");
    } else {
      final token = await TokenUtils.getToken();
      final sucursal = await BusinessUtils.getSucursalId();
      options.headers.addAll({"X-Public-Token": "Bearer $token"});
      if(sucursal!=null){
        options.headers.addAll({"Izi-Sucursal": sucursal});
      }
    }
    options.headers.addAll({"Connection": "Keep-Alive",});
    options.extra["retry_count"] = options.extra["retry_count"] ?? 0;
    return handler.next(options);
  }


}
