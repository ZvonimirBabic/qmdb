import 'dart:convert';

import 'package:alice/alice.dart';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get/get.dart' hide FormData, Response;
import 'package:path_provider/path_provider.dart';
import 'package:qmdb/design/constants/app_constants.dart';
import 'package:qmdb/utils/util_constants/qmdb_urls.dart';

import 'logger_service.dart';

enum HttpMethod {
  get,
  post,
  put,
  patch,
  delete,
}

class DioService extends GetxService {
  ///
  /// DEPENDENCIES
  ///

  final logger = Get.find<LoggerService>();

  ///
  /// VARIABLES
  ///

  late final Dio dio;
  late final Alice alice;
  late CacheStore cacheStore;

  ///
  /// INIT
  ///

  Future<DioService> init() async {
    alice = Alice(showNotification: true, navigatorKey: Get.key);
    var cacheDir = await getTemporaryDirectory();
    var cacheStore = HiveCacheStore(
      cacheDir.path,
      hiveBoxName: QMDBAppConstants.hiveCacheBox,
    );
    dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(milliseconds: kDebugMode ? 30000 : 5000),
        baseUrl: QMDBUrls.baseUrl,
      ),
    )
      ..interceptors.add(
        alice.getDioInterceptor(),
      )
      ..interceptors.add(
        AuthInterceptor(),
      )
      ..interceptors.add(
        DioCacheInterceptor(
          options: CacheOptions(
            store: cacheStore,
            maxStale: const Duration(days: 1),
          ),
        ),
      );
    return this;
  }

  Future<Either<DioException, Response>> request({
    required String endpoint,
    required HttpMethod httpMethod,
    Map<String, dynamic>? parameters,
  }) async {
    final jsonData = jsonEncode(parameters);
    Response? response;

    try {
      final options = Options(
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        method: httpMethod.name,
      );
      switch (httpMethod) {
        case HttpMethod.get:
          response = await dio.get(
            endpoint,
            options: options,
            queryParameters: parameters,
          );
          break;

        case HttpMethod.post:
          response = await dio.post(
            endpoint,
            data: jsonData,
            options: options,
          );
          break;

        case HttpMethod.put:
          response = await dio.put(
            endpoint,
            data: jsonData,
            options: options,
          );
          break;

        case HttpMethod.patch:
          response = await dio.patch(
            endpoint,
            data: jsonData,
            options: options,
          );
          break;

        case HttpMethod.delete:
          response = await dio.delete(
            endpoint,
            data: jsonData,
            options: options,
          );
          break;

        default:
          logger
            ..e('DIO SERVICE')
            ..e('--------------------')
            ..e('Error generating response')
            ..e('--------------------\n');
          return Left(
            DioException(
                requestOptions: RequestOptions(), message: 'Default error'),
          );
      }
      return Right(response);
    } on DioException catch (_) {
      return Left(
        DioException(
            requestOptions: response?.requestOptions ?? RequestOptions(),
            message: 'Dio Exception error'),
      );
    } catch (e) {
      return Left(
        DioException(
          requestOptions: response?.requestOptions ?? RequestOptions(),
          message: e.toString(),
        ),
      );
    }
  }
}

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    /// Get token from storage!!!!!
    options.headers.addAll({
      "Authorization": "YOUR-API-KEY-HERE",
    });
    super.onRequest(options, handler);
  }
}
