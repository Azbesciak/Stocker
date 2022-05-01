import 'package:shared_preferences/shared_preferences.dart' as SP;
import 'package:stocker/preferences/preferences.dart';

class NotPrimitiveType implements Exception {
  final type;

  NotPrimitiveType({required this.type});
}

class SharedPreferences extends Preferences {
  final Future<SP.SharedPreferences> _instance =
      SP.SharedPreferences.getInstance();

  @override
  Future<T?> get<T>(String key) async {
    var inst = await _instance;
    return inst.get(key) as T?;
  }

  @override
  Future<bool> save(String key, value) async {
    var inst = await _instance;
    if (value is int) {
      return inst.setInt(key, value);
    } else if (value is bool) {
      return inst.setBool(key, value);
    } else if (value is double) {
      return inst.setDouble(key, value);
    } else if (value is String) {
      return inst.setString(key, value);
    } else {
      throw NotPrimitiveType(type: value.runtimeType);
    }
  }
}
