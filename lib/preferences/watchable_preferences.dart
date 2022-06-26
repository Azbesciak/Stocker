import 'dart:async';
import 'dart:collection';

import 'package:rxdart/rxdart.dart';
import 'package:stocker/preferences/preferences.dart';

class WatchablePreferences extends Preferences {
  final Preferences _delegate;
  final Map<String, BehaviorSubject<dynamic>> _watched = HashMap();

  WatchablePreferences(this._delegate);

  Stream<T?> watch$<T>(String key) {
    return _watched.putIfAbsent(
      key,
      () => BehaviorSubject()..addStream(get(key).asStream()),
    ) as Stream<T?>;
  }

  @override
  Future<T?> get<T>(String key) {
    return _delegate.get(key);
  }

  @override
  Future<bool> save(String key, value) {
    return _delegate.save(key, value).then((value) {
      _watched[key]?.add(value);
      return value;
    });
  }
}
