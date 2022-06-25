import 'dart:collection';

import 'package:stocker/preferences/preferences.dart';

class MockPreferences extends Preferences {
  final Map<String, dynamic> _map = HashMap();

  @override
  Future<T?> get<T>(String key) {
    return Future.value(_map[key]);
  }

  @override
  Future<bool> save(String key, value) {
    _map[key] = value;
    return Future.value(true);
  }
}
