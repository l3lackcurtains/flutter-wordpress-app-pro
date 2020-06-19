import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';

import 'constants.dart';

DioCacheManager customDioCacheManager =
    DioCacheManager(CacheConfig(baseUrl: WORDPRESS_URL));
Dio customDio = Dio()..interceptors.add(customDioCacheManager.interceptor);
