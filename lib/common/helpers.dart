import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';

DioCacheManager customDioCacheManager =
    DioCacheManager(CacheConfig(baseUrl: WORDPRESS_URL));
Dio customDio = Dio()..interceptors.add(customDioCacheManager.interceptor);

class AppStateNotifier extends ChangeNotifier {
  bool isDarkMode = false;

  getThemeMode() {
    SharedPreferences.getInstance().then((prefs) {
      final key = 'darktheme';
      final value = prefs.getInt(key) ?? 0;
      isDarkMode = value == 1;
    });

    return isDarkMode;
  }

  void updateTheme(bool isDarkMode) {
    this.isDarkMode = isDarkMode;
    notifyListeners();
  }
}

Future<Null> changeToDarkTheme(BuildContext context, bool val) async {
  Provider.of<AppStateNotifier>(context, listen: false).updateTheme(val);
  final prefs = await SharedPreferences.getInstance();
  final key = 'darktheme';
  final value = val ? 1 : 0;
  await prefs.setInt(key, value);
}
