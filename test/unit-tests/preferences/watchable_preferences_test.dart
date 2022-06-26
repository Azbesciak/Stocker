import 'package:stocker/preferences/watchable_preferences.dart';
import 'package:test/test.dart';

import '../mock-preferences.dart';

void main() {
  test('ensure null on no value', () async {
    final preferences = _preferences();
    final key = 'ala';
    final stream = preferences.watch$(key);
    final isEmpty = await stream.isEmpty;
    expect(isEmpty, false, reason: 'Stream emit null value without prewrite');
    final value = await stream.first;
    expect(value, null, reason: 'value for missing key should be null');
  });

  test('if value was written earlier, it should be returned on watch',
      () async {
    final preferences = _preferences();
    final key = 'ala';
    final savedValue = '1';
    await preferences.save(key, savedValue);
    final saved = await preferences
        .watch$(key)
        .timeout(
          Duration(seconds: 1),
          onTimeout: (s) => s.close(),
        )
        .toList();
    expect(saved.length, 1, reason: 'should contain exactly one value');
    expect(saved[0], savedValue, reason: 'should save exactly given value');
  });
}

WatchablePreferences _preferences() => WatchablePreferences(MockPreferences());
