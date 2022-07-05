import 'dart:async';
import 'dart:collection';

import 'package:rxdart/rxdart.dart';
import 'package:stocker/preferences/preferences.dart';

class _StreamContainer<T> {
  late final BehaviorSubject<Stream<T?>> _input;
  late final Stream<T?> output;

  _StreamContainer(Future<T?> seed) {
    _input = BehaviorSubject<Stream<T?>>.seeded(seed.asStream());
    output = _input
        .switchMap(
          (v) => v.asBroadcastStream(),
        )
        .asBroadcastStream()
        .shareValue();
    // very nice memory leak but in rxdart behavior subject works different than in rxjs -
    // after the last subscription is canceled, any later added do not receive value there.
    output.listen((event) {});
  }

  add(T? value) {
    _input.add(Stream.value(value));
  }
}

class WatchablePreferences extends Preferences {
  final Preferences _delegate;
  final Map<String, _StreamContainer<dynamic>> _watched = HashMap();

  WatchablePreferences(this._delegate);

  Stream<T?> watch$<T>(String key) {
    return _watched
        .putIfAbsent(
          key,
          () => _StreamContainer<T>(get<T>(key)),
        )
        .output as Stream<T?>;
  }

  @override
  Future<T?> get<T>(String key) {
    return _delegate.get(key);
  }

  @override
  Future<bool> save(String key, value) {
    return _delegate.save(key, value).then((result) {
      _watched[key]?.add(value);
      return result;
    });
  }
}
